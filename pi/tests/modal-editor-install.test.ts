import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  existsSync,
  lstatSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readlinkSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const extensionSource = join(repoRoot, "pi/extensions/modal-editor.ts");
const stateSource = join(repoRoot, "pi/lib/modal-editor-state.ts");

function runInstaller(home: string) {
  return spawnSync(
    "sh",
    [
      "-c",
      '. "$CONFIG_ROOT/.scripts/install/lib.sh"; . "$CONFIG_ROOT/pi/.scripts/install.sh"; install_pi_modal_editor',
    ],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: { ...process.env, CONFIG_ROOT: repoRoot, HOME: home },
    },
  );
}

test("installer creates idempotent modal-editor symlinks", (testContext) => {
  const home = mkdtempSync(join(tmpdir(), "pi-modal-editor-"));
  testContext.after(() => rmSync(home, { recursive: true, force: true }));

  const extensionTarget = join(home, ".pi/agent/extensions/modal-editor.ts");
  const stateTarget = join(home, ".pi/agent/lib/modal-editor-state.ts");

  const first = runInstaller(home);
  assert.equal(first.status, 0, first.stderr);
  assert.equal(lstatSync(extensionTarget).isSymbolicLink(), true);
  assert.equal(readlinkSync(extensionTarget), extensionSource);
  assert.equal(lstatSync(stateTarget).isSymbolicLink(), true);
  assert.equal(readlinkSync(stateTarget), stateSource);

  const second = runInstaller(home);
  assert.equal(second.status, 0, second.stderr);
  assert.equal(readlinkSync(extensionTarget), extensionSource);
  assert.equal(readlinkSync(stateTarget), stateSource);
});

test("installer leaves no partial install when the state target conflicts", (testContext) => {
  const home = mkdtempSync(join(tmpdir(), "pi-modal-editor-conflict-"));
  testContext.after(() => rmSync(home, { recursive: true, force: true }));

  const extensionTarget = join(home, ".pi/agent/extensions/modal-editor.ts");
  const stateTarget = join(home, ".pi/agent/lib/modal-editor-state.ts");
  mkdirSync(dirname(stateTarget), { recursive: true });
  writeFileSync(stateTarget, "keep me");

  const result = runInstaller(home);

  assert.notEqual(result.status, 0);
  assert.equal(existsSync(extensionTarget), false);
  assert.equal(readFileSync(stateTarget, "utf8"), "keep me");
});
