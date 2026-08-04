import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  lstatSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readlinkSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { setImmediate } from "node:timers/promises";
import test from "node:test";

import contextStatusExtension, {
  MCP_STATUS_EVENT,
  formatMcpStatus,
  formatPullRequest,
  formatTask,
  parseMcpStatusSnapshot,
  parsePullRequest,
} from "../extensions/context-status.ts";

type ExecResult = {
  code: number;
  stdout: string;
  stderr: string;
};

type TestContext = {
  cwd: string;
  hasUI: boolean;
  ui: {
    theme: { fg: (color: string, text: string) => string };
    setStatus: (id: string, value: string | undefined) => void;
    notify: (message: string, level: string) => void;
  };
};

type EventHandler = (event: unknown, context: TestContext) => unknown;
type CommandHandler = (args: string, context: TestContext) => Promise<void> | void;
type Exec = (command: string, args: string[], options: { cwd: string; timeout: number }) => Promise<ExecResult>;
type SharedEventHandler = (data: unknown) => void;

type StatusUpdate = {
  readonly id: string;
  readonly value: string | undefined;
};

type ThemeCall = {
  readonly color: string;
  readonly text: string;
};

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const extensionSource = join(repoRoot, "pi/extensions/context-status.ts");

function runInstaller(home: string) {
  return spawnSync(
    "sh",
    [
      "-c",
      '. "$CONFIG_ROOT/.scripts/install/lib.sh"; . "$CONFIG_ROOT/pi/.scripts/install.sh"; install_pi_context_status',
    ],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: { ...process.env, CONFIG_ROOT: repoRoot, HOME: home },
    },
  );
}

function temporaryHome(testContext: { after: (callback: () => void) => void }): string {
  const home = mkdtempSync(join(tmpdir(), "pi-context-status-"));
  testContext.after(() => rmSync(home, { recursive: true, force: true }));
  return home;
}

function createHarness(exec: Exec = async () => ({ code: 1, stdout: "", stderr: "no pull request" })) {
  const events = new Map<string, EventHandler>();
  const sharedEvents = new Map<string, SharedEventHandler>();
  const statuses: Array<string | undefined> = [];
  const statusUpdates: StatusUpdate[] = [];
  const themeCalls: ThemeCall[] = [];
  const notifications: Array<{ message: string; level: string }> = [];
  let contextCommand: CommandHandler | undefined;

  const pi = {
    on(name: string, handler: EventHandler) {
      events.set(name, handler);
    },
    registerCommand(name: string, definition: { handler: CommandHandler }) {
      assert.equal(name, "context");
      contextCommand = definition.handler;
    },
    exec,
    events: {
      emit(channel: string, data: unknown) {
        sharedEvents.get(channel)?.(data);
      },
      on(channel: string, handler: SharedEventHandler) {
        sharedEvents.set(channel, handler);
        return () => {
          if (sharedEvents.get(channel) === handler) sharedEvents.delete(channel);
        };
      },
    },
  };

  // The harness deliberately implements only the methods used during extension registration.
  contextStatusExtension(pi as never);
  assert.ok(contextCommand);

  const context: TestContext = {
    cwd: "/repo",
    hasUI: true,
    ui: {
      theme: {
        fg(color, text) {
          themeCalls.push({ color, text });
          return text;
        },
      },
      setStatus(id, value) {
        statusUpdates.push({ id, value });
        if (id === "context") statuses.push(value);
      },
      notify(message, level) {
        notifications.push({ message, level });
      },
    },
  };

  function event(name: string): EventHandler {
    const handler = events.get(name);
    assert.ok(handler, `missing ${name} handler`);
    return handler;
  }

  function emitShared(channel: string, data: unknown): void {
    pi.events.emit(channel, data);
  }

  return {
    context,
    emitShared,
    event,
    notifications,
    runContext: contextCommand,
    statuses,
    statusUpdates,
    themeCalls,
  };
}

async function settle(): Promise<void> {
  await setImmediate();
}

test("parses and formats pull-request context", () => {
  assert.deepEqual(parsePullRequest('{"number":123,"title":" Fix auth "}'), {
    number: 123,
    title: "Fix auth",
  });
  assert.equal(formatPullRequest({ number: 123, title: "Fix auth" }), "PR #123 · Fix auth");
});

test("rejects malformed pull-request output", () => {
  assert.equal(parsePullRequest("not json"), undefined);
  assert.equal(parsePullRequest('{"number":0,"title":"Fix auth"}'), undefined);
  assert.equal(parsePullRequest('{"number":123,"title":"   "}'), undefined);
});

test("formats and truncates manual tasks", () => {
  assert.equal(formatTask(" Fix flaky auth test "), "CTX: Fix flaky auth test");

  const longTask = formatTask("x".repeat(100));
  assert.equal([...longTask].length, 72);
  assert.match(longTask, /…$/);
});

test("detects the branch pull request at session start", async () => {
  const harness = createHarness(async (command, args, options) => {
    assert.equal(command, "gh");
    assert.deepEqual(args, ["pr", "view", "--json", "number,title"]);
    assert.deepEqual(options, { cwd: "/repo", timeout: 3000 });
    return { code: 0, stdout: '{"number":123,"title":"Fix auth"}', stderr: "" };
  });

  harness.event("session_start")({}, harness.context);
  await settle();

  assert.equal(harness.statuses.at(-1), "PR #123 · Fix auth");
  assert.deepEqual(harness.notifications, []);
});

test("keeps expected startup absence silent", async () => {
  const harness = createHarness(async () => {
    throw new Error("gh is unavailable");
  });

  harness.event("session_start")({}, harness.context);
  await settle();

  assert.deepEqual(harness.statuses, [undefined]);
  assert.deepEqual(harness.notifications, []);
});

test("skips automatic detection without a UI", async () => {
  let calls = 0;
  const harness = createHarness(async () => {
    calls += 1;
    return { code: 0, stdout: '{"number":123,"title":"Fix auth"}', stderr: "" };
  });
  harness.context.hasUI = false;

  harness.event("session_start")({}, harness.context);
  await settle();

  assert.equal(calls, 0);
  assert.deepEqual(harness.statuses, [undefined]);
});

test("sets and reports a manual context", async () => {
  const harness = createHarness();

  await harness.runContext("  Fix flaky auth test  ", harness.context);
  await harness.runContext("", harness.context);

  assert.equal(harness.statuses.at(-1), "CTX: Fix flaky auth test");
  assert.deepEqual(harness.notifications.at(-1), {
    message: "Context: CTX: Fix flaky auth test",
    level: "info",
  });
  assert.deepEqual(harness.statusUpdates.at(-1), {
    id: "context",
    value: "CTX: Fix flaky auth test",
  });
  assert.deepEqual(harness.themeCalls.at(-1), {
    color: "dim",
    text: "CTX: Fix flaky auth test",
  });
  assert.equal("context".localeCompare("mcp") < 0, true);
});

test("buffers and dims a singular MCP summary with a leading separator", async () => {
  const harness = createHarness();

  harness.emitShared(MCP_STATUS_EVENT, {
    version: 1,
    servers: [{}],
    connectedCount: 1,
    disabledCount: 0,
  });
  harness.event("session_start")({}, harness.context);
  await settle();

  assert.deepEqual(harness.statusUpdates.at(-1), {
    id: "mcp",
    value: " MCP: 1 server enabled (1 connected)",
  });
  assert.deepEqual(harness.themeCalls.at(-1), {
    color: "dim",
    text: " MCP: 1 server enabled (1 connected)",
  });
  assert.equal(
    `${formatTask("doing some tests")} ${harness.statusUpdates.at(-1)?.value}`,
    "CTX: doing some tests  MCP: 1 server enabled (1 connected)",
  );
});

test("formats connected and disabled MCP server counts", async () => {
  const harness = createHarness();
  harness.event("session_start")({}, harness.context);

  harness.emitShared(MCP_STATUS_EVENT, {
    version: 1,
    servers: [{}, {}, {}],
    connectedCount: 1,
    disabledCount: 1,
  });
  await settle();

  assert.equal(
    harness.statusUpdates.at(-1)?.value,
    " MCP: 2 servers enabled (1 connected) (1 disabled)",
  );
});

test("ignores invalid MCP snapshots and clears a valid empty snapshot", async () => {
  const harness = createHarness();
  harness.event("session_start")({}, harness.context);

  harness.context.ui.setStatus("mcp", "adapter output");
  const beforeInvalid = harness.statusUpdates.length;
  harness.emitShared(MCP_STATUS_EVENT, { version: 2, servers: [] });
  harness.emitShared(MCP_STATUS_EVENT, {
    version: 1,
    servers: [{}],
    connectedCount: 2,
    disabledCount: 0,
  });
  await settle();
  assert.equal(harness.statusUpdates.length, beforeInvalid);

  harness.emitShared(MCP_STATUS_EVENT, {
    version: 1,
    servers: [],
    connectedCount: 0,
    disabledCount: 0,
  });
  await settle();
  assert.deepEqual(harness.statusUpdates.at(-1), { id: "mcp", value: undefined });
});

test("shutdown prevents a queued MCP status update", async () => {
  const harness = createHarness();
  harness.event("session_start")({}, harness.context);

  harness.emitShared(MCP_STATUS_EVENT, {
    version: 1,
    servers: [{}],
    connectedCount: 0,
    disabledCount: 0,
  });
  harness.event("session_shutdown")({}, harness.context);
  await settle();

  assert.equal(harness.statusUpdates.some(({ id }) => id === "mcp"), false);
});

test("parses and formats MCP snapshots independently", () => {
  const snapshot = parseMcpStatusSnapshot({
    version: 1,
    servers: [{}, {}],
    connectedCount: 0,
    disabledCount: 1,
  });

  assert.ok(snapshot);
  assert.deepEqual(snapshot, {
    version: 1,
    servers: [{}, {}],
    connectedCount: 0,
    disabledCount: 1,
  });
  assert.equal(formatMcpStatus(snapshot), "MCP: 1 server enabled (1 disabled)");
  assert.equal(parseMcpStatusSnapshot(null), undefined);
});

test("returns to automatic context on command", async () => {
  const harness = createHarness(async () => ({
    code: 0,
    stdout: '{"number":456,"title":"Refresh context"}',
    stderr: "",
  }));

  await harness.runContext("Manual task", harness.context);
  await harness.runContext("auto", harness.context);

  assert.equal(harness.statuses.at(-1), "PR #456 · Refresh context");
  assert.deepEqual(harness.notifications.at(-1), {
    message: "Context: PR #456 · Refresh context",
    level: "info",
  });
});

test("reports explicit automatic absence", async () => {
  const harness = createHarness();

  await harness.runContext("Manual task", harness.context);
  await harness.runContext("auto", harness.context);

  assert.equal(harness.statuses.at(-1), undefined);
  assert.deepEqual(harness.notifications.at(-1), {
    message: "No pull request found for the current branch.",
    level: "info",
  });
});

test("manual context wins over a pending automatic lookup", async () => {
  let resolveExec: ((result: ExecResult) => void) | undefined;
  const pending = new Promise<ExecResult>((resolve) => {
    resolveExec = resolve;
  });
  const harness = createHarness(async () => pending);

  harness.event("session_start")({}, harness.context);
  await harness.runContext("Manual task", harness.context);
  resolveExec?.({ code: 0, stdout: '{"number":789,"title":"Late result"}', stderr: "" });
  await settle();

  assert.deepEqual(harness.statuses, [undefined, "CTX: Manual task"]);
});

test("shutdown prevents a late lookup update", async () => {
  let resolveExec: ((result: ExecResult) => void) | undefined;
  const pending = new Promise<ExecResult>((resolve) => {
    resolveExec = resolve;
  });
  const harness = createHarness(async () => pending);

  harness.event("session_start")({}, harness.context);
  harness.event("session_shutdown")({}, harness.context);
  resolveExec?.({ code: 0, stdout: '{"number":789,"title":"Late result"}', stderr: "" });
  await settle();

  assert.deepEqual(harness.statuses, [undefined]);
});

test("installer creates an idempotent extension symlink", (testContext) => {
  const home = temporaryHome(testContext);
  const target = join(home, ".pi/agent/extensions/context-status.ts");

  const first = runInstaller(home);
  assert.equal(first.status, 0, first.stderr);
  assert.equal(lstatSync(target).isSymbolicLink(), true);
  assert.equal(readlinkSync(target), extensionSource);

  const second = runInstaller(home);
  assert.equal(second.status, 0, second.stderr);
  assert.equal(readlinkSync(target), extensionSource);
});

test("installer preserves an unrelated destination file", (testContext) => {
  const home = temporaryHome(testContext);
  const target = join(home, ".pi/agent/extensions/context-status.ts");
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, "keep me");

  const result = runInstaller(home);

  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Refusing to replace/);
  assert.equal(readFileSync(target, "utf8"), "keep me");
});

test("installer preserves an unrelated destination symlink", (testContext) => {
  const home = temporaryHome(testContext);
  const target = join(home, ".pi/agent/extensions/context-status.ts");
  const other = join(home, "other-extension.ts");
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(other, "export default function () {}\n");
  symlinkSync(other, target);

  const result = runInstaller(home);

  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Refusing to replace/);
  assert.equal(readlinkSync(target), other);
});
