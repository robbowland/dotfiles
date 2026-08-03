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
  formatPullRequest,
  formatTask,
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
  const statuses: Array<string | undefined> = [];
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
          assert.equal(color, "accent");
          return text;
        },
      },
      setStatus(id, value) {
        assert.equal(id, "work-context");
        statuses.push(value);
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

  return { context, event, notifications, runContext: contextCommand, statuses };
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
  assert.equal(formatTask(" Fix flaky auth test "), "Task · Fix flaky auth test");

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

  assert.equal(harness.statuses.at(-1), "Task · Fix flaky auth test");
  assert.deepEqual(harness.notifications.at(-1), {
    message: "Context: Task · Fix flaky auth test",
    level: "info",
  });
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

  assert.deepEqual(harness.statuses, [undefined, "Task · Manual task"]);
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
