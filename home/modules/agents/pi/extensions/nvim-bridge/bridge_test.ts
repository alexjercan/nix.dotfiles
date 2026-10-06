import assert from "node:assert/strict";
import { execFileSync, spawn } from "node:child_process";
import { connect } from "node:net";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import bridge from "./bridge.ts";

function tmux(...args: string[]) {
  return execFileSync("tmux", args, { encoding: "utf8" }).trim();
}

function readLine(socket: ReturnType<typeof connect>): Promise<Record<string, unknown>> {
  return new Promise((resolve, reject) => {
    let text = "";
    socket.on("data", (chunk: Buffer) => {
      text += chunk.toString();
      const newline = text.indexOf("\n");
      if (newline >= 0) resolve(JSON.parse(text.slice(0, newline)));
    });
    socket.once("error", reject);
  });
}

test("routes user messages through the registered Pi pane and reports completion", async () => {
  const session = `pi-nvim-test-${process.pid}`;
  const oldPane = process.env.TMUX_PANE;
  const handlers = new Map<string, (event: unknown, ctx?: unknown) => unknown>();
  const calls: Array<{ message: string; options: unknown }> = [];
  const statuses: Array<{ key: string; text: string | undefined }> = [];
  let idle = true;
  const pi = {
    on(name: string, handler: (event: unknown, ctx?: unknown) => unknown) {
      handlers.set(name, handler);
    },
    sendUserMessage(message: string, options: unknown) {
      calls.push({ message, options });
    },
  };
  tmux("new-session", "-d", "-s", session);
  tmux("new-window", "-d", "-t", `=${session}:2`);
  const nvimPane = tmux("display-message", "-p", "-t", `=${session}:1`, "#{pane_id}");
  const pane = tmux("display-message", "-p", "-t", `=${session}:2`, "#{pane_id}");
  process.env.TMUX_PANE = pane;
  const ctx = {
    mode: "tui",
    isIdle: () => idle,
    ui: { setStatus: (key: string, text: string | undefined) => statuses.push({ key, text }) },
  };

  try {
    bridge(pi as never);
    await handlers.get("session_start")!({}, ctx);
    const path = tmux("show-options", "-p", "-v", "-t", pane, "@pi_nvim_socket");
    assert.ok(existsSync(path));
    assert.deepEqual(statuses.at(-1), { key: "nvim-bridge", text: "nvim-bridge: on" });

    const first = connect(path);
    first.write(JSON.stringify({ id: "1", message: "Check file\n\n/tmp/code.lua:4" }) + "\n");
    assert.deepEqual(await readLine(first), { id: "1", status: "running" });
    assert.deepEqual(calls[0], { message: "Check file\n\n/tmp/code.lua:4", options: undefined });
    const completed = readLine(first);
    handlers.get("agent_settled")!({});
    assert.deepEqual(await completed, { status: "done" });
    first.destroy();

    idle = false;
    const second = connect(path);
    second.write(JSON.stringify({ id: "2", message: "Next prompt" }) + "\n");
    assert.deepEqual(await readLine(second), { id: "2", status: "queued" });
    assert.deepEqual(calls[1], { message: "Next prompt", options: { deliverAs: "followUp" } });
    const started = readLine(second);
    handlers.get("before_agent_start")!({ prompt: "Next prompt" });
    assert.deepEqual(await started, { id: "2", status: "running" });
    const queuedDone = readLine(second);
    handlers.get("agent_settled")!({});
    assert.deepEqual(await queuedDone, { status: "done" });
    second.destroy();

    idle = true;
    const temp = mkdtempSync(join(tmpdir(), "pi-nvim-bridge-test-"));
    const script = join(temp, "test.lua");
    writeFileSync(script, `
      package.preload.pi_nvim_bridge = function()
        return dofile(${JSON.stringify(resolve("home/modules/neovim/plugins/pi-bridge.lua"))})
      end
      vim.notify = function(message)
        if message == "Pi finished" then vim.g.pi_finished = true end
      end
      require("pi_nvim_bridge").send("Review\\n\\n/tmp/example.lua:4")
      assert(vim.wait(3000, function() return vim.g.pi_finished == true end), "Pi did not finish")
    `);
    try {
      const result = new Promise<{ code: number | null; output: string }>((resolveExit) => {
        const child = spawn("nvim", ["--headless", "-u", "NONE", "-c", `luafile ${script}`, "-c", "qa!"], {
          env: { ...process.env, TMUX_PANE: nvimPane },
        });
        let output = "";
        child.stdout.on("data", (data: Buffer) => { output += data.toString(); });
        child.stderr.on("data", (data: Buffer) => { output += data.toString(); });
        child.on("exit", (code) => resolveExit({ code, output }));
      });
      for (let tries = 0; calls.length < 3 && tries < 300; tries++) {
        await new Promise((resolveDelay) => setTimeout(resolveDelay, 10));
      }
      if (calls.length !== 3) assert.fail((await result).output);
      assert.equal(calls[2].message, "Review\n\n/tmp/example.lua:4");
      handlers.get("agent_settled")!({});
      const { code, output } = await result;
      assert.equal(code, 0, output);
      assert.doesNotMatch(output, /E5113|Pi did not finish|Error in command line/);
    } finally {
      rmSync(temp, { recursive: true, force: true });
    }

    await handlers.get("session_shutdown")!({}, ctx);
    assert.equal(existsSync(path), false);
    assert.deepEqual(statuses.at(-1), { key: "nvim-bridge", text: undefined });
  } finally {
    await handlers.get("session_shutdown")?.({}, ctx);
    tmux("kill-session", "-t", `=${session}`);
    if (oldPane === undefined) delete process.env.TMUX_PANE;
    else process.env.TMUX_PANE = oldPane;
  }
});
