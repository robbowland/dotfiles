import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const MAX_STATUS_LENGTH = 72;
const MCP_STATUS_ID = "mcp";
const STATUS_ID = "context";

export const MCP_STATUS_EVENT = "pi-mcp-adapter/status/v1";

export type PullRequest = {
  readonly number: number;
  readonly title: string;
};

export type McpStatusSnapshot = {
  readonly version: 1;
  readonly servers: readonly unknown[];
  readonly connectedCount: number;
  readonly disabledCount: number;
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

export function parseMcpStatusSnapshot(value: unknown): McpStatusSnapshot | undefined {
  if (typeof value !== "object" || value === null) return undefined;

  const version = Reflect.get(value, "version");
  const servers = Reflect.get(value, "servers");
  const connectedCount = Reflect.get(value, "connectedCount");
  const disabledCount = Reflect.get(value, "disabledCount");
  if (version !== 1 || !Array.isArray(servers)) return undefined;
  if (
    typeof connectedCount !== "number"
    || !Number.isInteger(connectedCount)
    || connectedCount < 0
  ) return undefined;
  if (
    typeof disabledCount !== "number"
    || !Number.isInteger(disabledCount)
    || disabledCount < 0
  ) return undefined;

  const enabledCount = servers.length - disabledCount;
  if (enabledCount < 0 || connectedCount > enabledCount) return undefined;

  return { version, servers, connectedCount, disabledCount };
}

export function formatPullRequest(pullRequest: PullRequest): string {
  return truncateStatus(`PR #${pullRequest.number} · ${pullRequest.title}`);
}

export function formatTask(text: string): string {
  return truncateStatus(`Task · ${text.trim()}`);
}

export function formatMcpStatus(snapshot: McpStatusSnapshot): string | undefined {
  if (snapshot.servers.length === 0) return undefined;

  const enabledCount = snapshot.servers.length - snapshot.disabledCount;
  let status = `MCP: ${enabledCount} ${enabledCount === 1 ? "server" : "servers"} enabled`;
  if (snapshot.connectedCount > 0) status += ` (${snapshot.connectedCount} connected)`;
  if (snapshot.disabledCount > 0) status += ` (${snapshot.disabledCount} disabled)`;
  return status;
}

export default function contextStatusExtension(pi: ExtensionAPI): void {
  let active = true;
  let activeContext: ExtensionContext | undefined;
  let currentContext: string | undefined;
  let hasMcpStatus = false;
  let latestMcpStatus: string | undefined;
  let lookupGeneration = 0;
  let manualContext: string | undefined;
  let mcpGeneration = 0;

  function updateStatus(context: ExtensionContext, value: string | undefined): void {
    currentContext = value;
    context.ui.setStatus(
      STATUS_ID,
      value === undefined ? undefined : context.ui.theme.fg("dim", value),
    );
  }

  function queueMcpStatusUpdate(): void {
    const context = activeContext;
    if (!active || context === undefined || !hasMcpStatus) return;

    const generation = ++mcpGeneration;
    const value = latestMcpStatus;
    queueMicrotask(() => {
      if (!active || generation !== mcpGeneration || activeContext !== context) return;
      context.ui.setStatus(
        MCP_STATUS_ID,
        value === undefined ? undefined : context.ui.theme.fg("dim", value),
      );
    });
  }

  const unsubscribeMcpStatus = pi.events.on(MCP_STATUS_EVENT, (data) => {
    const snapshot = parseMcpStatusSnapshot(data);
    if (snapshot === undefined) return;

    hasMcpStatus = true;
    latestMcpStatus = formatMcpStatus(snapshot);
    queueMcpStatusUpdate();
  });

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
    activeContext = context;
    currentContext = undefined;
    manualContext = undefined;
    lookupGeneration += 1;
    updateStatus(context, undefined);
    queueMcpStatusUpdate();
    if (context.hasUI) void refreshPullRequest(context, false);
  });

  pi.on("session_shutdown", () => {
    active = false;
    activeContext = undefined;
    lookupGeneration += 1;
    mcpGeneration += 1;
    unsubscribeMcpStatus();
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
