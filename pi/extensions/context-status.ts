import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const MAX_STATUS_LENGTH = 72;
const STATUS_ID = "work-context";

export type PullRequest = {
  readonly number: number;
  readonly title: string;
};

function truncateStatus(text: string): string {
  const characters = [...text];
  if (characters.length <= MAX_STATUS_LENGTH) return text;
  return `${characters.slice(0, MAX_STATUS_LENGTH - 1).join("")}…`;
}

export function parsePullRequest(output: string): PullRequest | undefined {
  let value: unknown;
  try {
    value = JSON.parse(output);
  } catch {
    return undefined;
  }

  if (typeof value !== "object" || value === null) return undefined;

  const number = Reflect.get(value, "number");
  const title = Reflect.get(value, "title");
  if (typeof number !== "number" || !Number.isInteger(number) || number <= 0) return undefined;
  if (typeof title !== "string" || title.trim().length === 0) return undefined;

  return { number, title: title.trim() };
}

export function formatPullRequest(pullRequest: PullRequest): string {
  return truncateStatus(`PR #${pullRequest.number} · ${pullRequest.title}`);
}

export function formatTask(text: string): string {
  return truncateStatus(`Task · ${text.trim()}`);
}

export default function contextStatusExtension(pi: ExtensionAPI): void {
  let active = true;
  let currentContext: string | undefined;
  let lookupGeneration = 0;
  let manualContext: string | undefined;

  function updateStatus(context: ExtensionContext, value: string | undefined): void {
    currentContext = value;
    context.ui.setStatus(
      STATUS_ID,
      value === undefined ? undefined : context.ui.theme.fg("accent", value),
    );
  }

  async function refreshPullRequest(context: ExtensionContext, notify: boolean): Promise<void> {
    const generation = ++lookupGeneration;
    let pullRequest: PullRequest | undefined;

    try {
      const result = await pi.exec(
        "gh",
        ["pr", "view", "--json", "number,title"],
        { cwd: context.cwd, timeout: 3000 },
      );
      if (result.code === 0) pullRequest = parsePullRequest(result.stdout);
    } catch {
      pullRequest = undefined;
    }

    if (!active || generation !== lookupGeneration || manualContext !== undefined) return;

    if (pullRequest === undefined) {
      if (notify || currentContext !== undefined) updateStatus(context, undefined);
      if (notify) context.ui.notify("No pull request found for the current branch.", "info");
      return;
    }

    const value = formatPullRequest(pullRequest);
    updateStatus(context, value);
    if (notify) context.ui.notify(`Context: ${value}`, "info");
  }

  pi.on("session_start", (_event, context) => {
    active = true;
    currentContext = undefined;
    manualContext = undefined;
    lookupGeneration += 1;
    updateStatus(context, undefined);
    if (context.hasUI) void refreshPullRequest(context, false);
  });

  pi.on("session_shutdown", () => {
    active = false;
    lookupGeneration += 1;
  });

  pi.registerCommand("context", {
    description: "Show or set session-local work context",
    handler: async (args, context) => {
      const input = args.trim();

      if (input.length === 0) {
        const message = currentContext === undefined
          ? "No work context. Use /context <task> or /context auto."
          : `Context: ${currentContext}`;
        context.ui.notify(message, "info");
        return;
      }

      if (input === "auto") {
        manualContext = undefined;
        await refreshPullRequest(context, true);
        return;
      }

      lookupGeneration += 1;
      manualContext = formatTask(input);
      updateStatus(context, manualContext);
      context.ui.notify(`Context: ${manualContext}`, "info");
    },
  });
}
