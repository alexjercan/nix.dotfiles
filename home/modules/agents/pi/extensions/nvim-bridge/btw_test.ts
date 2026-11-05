import assert from "node:assert/strict";
import { test } from "node:test";
import { setImmediate } from "node:timers/promises";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { createBtw, registerBtwCommand, type AnswerBtw } from "./btw.ts";

test("BTW uses isolated read-only resources and persists a UI-only answer", async () => {
  const entries: Array<{ type: string; data: unknown }> = [];
  let renderer: Function;
  let options: Record<string, any>;
  let resources: Record<string, any>;
  let disposed = false;
  let prompt = "";
  const branch = [{ type: "message", message: { role: "user", content: "Main task" } }];
  const pi = {
    registerEntryRenderer(_type: string, render: Function) { renderer = render; },
    appendEntry(type: string, data: unknown) { entries.push({ type, data }); },
    sendUserMessage() { assert.fail("BTW must never send a main conversation message"); },
  };
  class Text {
    text: string;
    constructor(text: string) { this.text = text; }
  }
  const sdk = {
    getAgentDir: () => "/agent",
    buildSessionContext(snapshot: unknown) {
      assert.deepEqual(snapshot, branch);
      assert.notEqual(snapshot, branch, "Snapshot must be a copy");
      return { messages: [] };
    },
    convertToLlm: () => [],
    serializeConversation: () => "Main task snapshot",
    SettingsManager: { inMemory: () => ({}) },
    SessionManager: { inMemory: (cwd: string) => ({ cwd, isolated: true }) },
    DefaultResourceLoader: class {
      constructor(config: Record<string, unknown>) { resources = config; }
      async reload() {}
    },
    async createAgentSession(config: Record<string, any>) {
      options = config;
      return { session: {
        async prompt(text: string) { prompt = text; },
        messages: [{ role: "assistant", stopReason: "stop" }],
        getLastAssistantText: () => "The answer.",
        dispose() { disposed = true; },
      } };
    },
  };
  const answer = createBtw(pi as never, sdk as never, Text as never);
  const ctx = { cwd: "/project", model: { id: "model" }, sessionManager: { getBranch: () => branch } };
  assert.equal(await answer("Why?\n\n/project/code.ts:4", ctx as never, new AbortController().signal), "The answer.");
  assert.deepEqual(options!.tools, ["read", "grep", "find", "ls"]);
  assert.deepEqual(options!.sessionManager, { cwd: "/project", isolated: true });
  assert.equal(options!.model, ctx.model);
  for (const key of ["noExtensions", "noSkills", "noPromptTemplates", "noThemes", "noContextFiles"]) {
    assert.equal(resources![key], true, key);
  }
  assert.match(resources!.systemPromptOverride(), /Do not continue its task or make changes/);
  assert.match(prompt, /Main task snapshot/);
  assert.match(prompt, /Why\?/);
  assert.equal(disposed, true);
  assert.deepEqual(entries, [{ type: "nvim-btw", data: { question: "Why?\n\n/project/code.ts:4", answer: "The answer." } }]);
  const card = renderer!({ data: entries[0].data }, { expanded: true }, { fg: (_: string, text: string) => text });
  assert.match(card.text, /Why\?/);
  assert.match(card.text, /The answer\./);
});

test("BTW aborts and disposes side work without writing into a replacement session", async () => {
  const controller = new AbortController();
  let aborted = false;
  let disposed = false;
  const answer = createBtw({ registerEntryRenderer() {}, appendEntry() { assert.fail("Cancelled work must not append"); } } as never, {
    getAgentDir: () => "/agent",
    buildSessionContext: () => ({ messages: [] }), convertToLlm: () => [], serializeConversation: () => "",
    SettingsManager: { inMemory: () => ({}) }, SessionManager: { inMemory: () => ({}) },
    DefaultResourceLoader: class { async reload() {} },
    async createAgentSession() {
      return { session: {
        async prompt() { controller.abort(); },
        async abort() { aborted = true; },
        dispose() { disposed = true; },
      } };
    },
  } as never, class {} as never);
  await assert.rejects(answer("Why?", {
    cwd: "/project", model: {}, sessionManager: { getBranch: () => [] },
  } as never, controller.signal), /abort/i);
  assert.equal(aborted, true);
  assert.equal(disposed, true);
});

test("BTW model errors are kept as UI-only records and are not treated as answers", async () => {
  const records: unknown[] = [];
  let disposed = false;
  const answer = createBtw({ registerEntryRenderer() {}, appendEntry(_type: string, data: unknown) { records.push(data); } } as never, {
    getAgentDir: () => "/agent",
    buildSessionContext: () => ({ messages: [] }), convertToLlm: () => [], serializeConversation: () => "",
    SettingsManager: { inMemory: () => ({}) }, SessionManager: { inMemory: () => ({}) },
    DefaultResourceLoader: class { async reload() {} },
    async createAgentSession() {
      return { session: {
        async prompt() {},
        messages: [{ role: "assistant", stopReason: "error", errorMessage: "Rate limited" }],
        dispose() { disposed = true; },
      } };
    },
  } as never, class {} as never);
  await assert.rejects(answer("Why?", {
    cwd: "/project", model: {}, sessionManager: { getBranch: () => [] },
  } as never, new AbortController().signal), /Rate limited/);
  assert.deepEqual(records, [{ question: "Why?", error: "Error: Rate limited" }]);
  assert.equal(disposed, true);
});

function commandHarness(answer: AnswerBtw) {
  let command: Parameters<ExtensionAPI["registerCommand"]>[1];
  let shutdown: (event: unknown, ctx: ExtensionCommandContext) => Promise<void>;
  const notices: string[] = [];
  const statuses: Array<string | undefined> = [];
  const ctx = {
    mode: "tui",
    isIdle: () => false,
    ui: {
      notify: (text: string) => notices.push(text),
      setStatus: (_key: string, text: string | undefined) => statuses.push(text),
    },
  } as unknown as ExtensionCommandContext;
  registerBtwCommand({
    registerCommand(name: string, options: typeof command) {
      assert.equal(name, "btw");
      command = options;
    },
    on(name: string, handler: typeof shutdown) {
      assert.equal(name, "session_shutdown");
      shutdown = handler;
    },
    sendUserMessage() { assert.fail("Command must not steer the main agent"); },
    sendMessage() { assert.fail("Command must not add model context"); },
  } as never, answer);
  return {
    ctx, notices, statuses,
    run: (args: string) => command!.handler(args, ctx),
    shutdown: () => shutdown!({}, ctx),
  };
}

test("/btw starts the shared service while busy and returns before the answer", async () => {
  let resolveAnswer: (text: string) => void;
  let received: string | undefined;
  const harness = commandHarness(async (question, ctx, signal) => {
    received = question;
    assert.equal(ctx, harness.ctx);
    assert.equal(signal.aborted, false);
    return new Promise<string>((resolve) => { resolveAnswer = resolve; });
  });
  try {
    await harness.run("  Why is this read-only?  ");
    assert.equal(received, "Why is this read-only?");
    assert.deepEqual(harness.statuses, ["btw:1 running"]);
    resolveAnswer!("An isolated answer.");
    await setImmediate();
    assert.deepEqual(harness.statuses, ["btw:1 running", undefined]);
    assert.deepEqual(harness.notices, []);
  } finally {
    await harness.shutdown();
  }
});

test("/btw validates input, limits concurrency, and cancels on session shutdown", async () => {
  const signals: AbortSignal[] = [];
  const harness = commandHarness(async (_question, _ctx, signal) => {
    signals.push(signal);
    return new Promise<string>((_resolve, reject) => {
      signal.addEventListener("abort", () => reject(new Error("Cancelled")), { once: true });
    });
  });
  try {
    await harness.run("  ");
    await harness.run("x".repeat(64 * 1024 + 1));
    assert.equal(signals.length, 0);
    assert.match(harness.notices[0], /Usage: \/btw/);
    assert.match(harness.notices[1], /too long/);
    for (let i = 0; i < 4; i++) await harness.run(`Question ${i}`);
    assert.equal(signals.length, 3);
    assert.match(harness.notices.at(-1)!, /Too many/);
    await harness.shutdown();
    assert.ok(signals.every((signal) => signal.aborted));
    const statusCount = harness.statuses.length;
    const noticeCount = harness.notices.length;
    await setImmediate();
    assert.equal(harness.statuses.at(-1), undefined);
    assert.equal(harness.statuses.length, statusCount, "Old context must not update after shutdown");
    assert.equal(harness.notices.length, noticeCount);
  } finally {
    await harness.shutdown();
  }
});

test("/btw reports model failures and clears its progress status", async () => {
  const harness = commandHarness(async () => { throw new Error("Rate limited"); });
  try {
    await harness.run("Why?");
    await setImmediate();
    assert.deepEqual(harness.notices, ["Error: Rate limited"]);
    assert.equal(harness.statuses.at(-1), undefined);
  } finally {
    await harness.shutdown();
  }
});

test("/btw times out side work after two minutes", async (t) => {
  t.mock.timers.enable({ apis: ["setTimeout"] });
  let signal: AbortSignal;
  const harness = commandHarness(async (_question, _ctx, questionSignal) => {
    signal = questionSignal;
    return new Promise<string>((_resolve, reject) => {
      signal.addEventListener("abort", () => reject(signal.reason), { once: true });
    });
  });
  try {
    await harness.run("Why?");
    t.mock.timers.tick(120000);
    await setImmediate();
    assert.equal(signal!.aborted, true);
    assert.deepEqual(harness.notices, ["BTW question timed out"]);
    assert.equal(harness.statuses.at(-1), undefined);
  } finally {
    await harness.shutdown();
  }
});
