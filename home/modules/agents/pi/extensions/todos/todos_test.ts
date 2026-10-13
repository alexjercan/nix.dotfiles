// Runs the todos extension against a minimal fake Pi runtime.
// Run with: npm test
import assert from "node:assert/strict";
import { test } from "node:test";

import extension, { type Ledger } from "./todos.ts";

type Handler = (event: unknown, ctx: unknown) => unknown;
type Entry = { id: string; type: string; customType?: string; data?: unknown };
type ToolResult = { content: { text: string }[]; details?: { summary: string } };
type Rendered = { render(width: number): string[] };
type Tool = {
	description: string;
	promptGuidelines: string[];
	parameters: { required?: string[]; properties: Record<string, { enum?: string[]; minimum?: number }> };
	execute: (id: string, params: unknown, signal: undefined, onUpdate: undefined, ctx: unknown) => Promise<ToolResult>;
	renderCall: (args: Record<string, unknown>, theme: { fg: (color: string, text: string) => string }) => Rendered;
	renderResult: (
		result: ToolResult,
		options: { expanded: boolean },
		theme: { fg: (color: string, text: string) => string },
		context: { isError: boolean },
	) => Rendered;
};
type Command = { handler: (args: string, ctx: unknown) => Promise<void> };
type Shortcut = { handler: (ctx: unknown) => Promise<void> };
type ListComponent = { handleInput(data: string): void; render(width: number): string[] };

const KEY = { up: "\x1b[A", down: "\x1b[B", space: " ", escape: "\x1b", altT: "\x1bt" };

function fakePi(branch: Entry[] = []) {
	const handlers = new Map<string, Handler[]>();
	const tools = new Map<string, Tool>();
	const commands = new Map<string, Command>();
	const shortcuts = new Map<string, Shortcut>();
	const notes: { message: string; type?: string }[] = [];
	const widgets = new Map<string, string[] | undefined>();
	const statuses = new Map<string, string | undefined>();
	// Rendered lines of the /todos list after each key.
	const screens: string[][] = [];
	const inputs: string[] = [];
	// Each element holds the keys for one opening of the /todos list.
	const keys: string[][] = [];

	const pi = {
		on(event: string, handler: Handler) {
			handlers.set(event, [...(handlers.get(event) ?? []), handler]);
		},
		registerTool(tool: Tool & { name: string }) {
			tools.set(tool.name, tool);
		},
		registerCommand(name: string, command: Command) {
			commands.set(name, command);
		},
		registerShortcut(key: string, shortcut: Shortcut) {
			shortcuts.set(key, shortcut);
		},
		appendEntry(customType: string, data: unknown) {
			branch.push({ id: `e${branch.length + 1}`, type: "custom", customType, data: structuredClone(data) });
		},
	};

	const ctx = {
		mode: "tui",
		hasUI: true,
		ui: {
			notify(message: string, type?: string) {
				notes.push({ message, type });
			},
			setStatus(key: string, text: string | undefined) {
				statuses.set(key, text);
			},
			setWidget(key: string, content: string[] | undefined) {
				widgets.set(key, content);
			},
			async input() {
				return inputs.shift();
			},
			custom<T>(factory: (tui: unknown, theme: unknown, keybindings: unknown, done: (value: T) => void) => ListComponent) {
				return new Promise<T>((resolve) => {
					let closed = false;
					const theme = { fg: (_color: string, text: string) => text, bold: (text: string) => text };
					const component = factory({ requestRender() {} }, theme, {}, (value) => {
						closed = true;
						resolve(value);
					});
					for (const key of keys.shift() ?? [KEY.escape]) {
						if (closed) break;
						component.handleInput(key);
						screens.push(component.render(200));
					}
					assert.ok(closed, "the key script must close the list");
				});
			},
		},
		sessionManager: { getBranch: () => branch },
	};

	extension(pi as never);

	async function emit(event: string, fields: Record<string, unknown> = {}) {
		let result: unknown;
		for (const handler of handlers.get(event) ?? []) {
			result = (await handler({ type: event, ...fields }, ctx)) ?? result;
		}
		return result as Record<string, unknown> | undefined;
	}

	async function tool(name: string, params: Record<string, unknown> = {}) {
		const result = await tools.get(name)!.execute("call", params, undefined, undefined, ctx);
		return result.content[0]!.text;
	}

	function ledger(): Ledger {
		const snapshots = branch.filter((entry) => entry.customType === "tasks-ledger");
		return snapshots.at(-1)?.data as Ledger;
	}

	return { branch, notes, widgets, statuses, inputs, keys, ctx, emit, tool, tools, ledger, handlers, commands, shortcuts, screen: () => screens.at(-1) ?? [], screens };
}

test("records messages before the agent selects actionable todos", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "Fix the parser and update docs", source: "interactive" });
	await pi.emit("input", { text: "  Thanks ", source: "extension", streamingBehavior: "steer" });
	await pi.emit("input", { text: "Fix the parser and update docs", source: "rpc" });
	const snapshots = pi.branch.length;
	await pi.emit("input", { text: " \n ", source: "interactive" });
	assert.equal(pi.branch.length, snapshots, "empty input must not write snapshots");
	assert.deepEqual(pi.ledger().tasks, [], "input does not create todos");
	assert.deepEqual(pi.ledger().prompts.map((prompt) => [prompt.id, prompt.source]),
		[[1, "interactive"], [2, "extension"], [3, "rpc"]]);

	await pi.tool("todo_add", { title: "Fix parser" });
	await pi.tool("todo_add", { title: "Update docs" });
	await pi.tool("todo_add_subtodo", { title: "Read parser", parentId: 1 });
	assert.deepEqual(pi.ledger().tasks.map((task) => [task.title, task.parentId]),
		[["Fix parser", undefined], ["Update docs", undefined], ["Read parser", 1]]);
	assert.equal(pi.ledger().tasks.length, 3);
	await pi.tool("todo_update", {id: 3, status: "closed" });
	await pi.tool("todo_update", {id: 1, status: "closed" });
	const listing = await pi.tool("todo_list");
	assert.match(listing, /P2: Thanks/);
	assert.match(listing, /\[x\] #1 Fix parser/);
	assert.match(listing, /\[ \] #2 Update docs/);

	// A replacement is a delete followed by a new todo.
	await pi.tool("todo_delete", {id: 2 });
	const replaced = await pi.tool("todo_add", { title: "Revise documentation" });
	assert.doesNotMatch(replaced, /Update docs/);
	assert.match(replaced, /\[ \] #4 Revise documentation/);
});

test("has only open and closed todos, without waiting, blocked, or resume behavior", async () => {
	const pi = fakePi();
	for (const event of ["message_start", "before_agent_start"]) {
		assert.equal(pi.handlers.has(event), false, `no ${event} handler`);
	}
	const update = pi.tools.get("todo_update")!;
	assert.deepEqual(update.parameters.properties.status!.enum, ["open", "closed"]);
	assert.deepEqual([...pi.tools.keys()], ["todo_list", "todo_add", "todo_add_subtodo", "todo_update", "todo_delete"]);
	assert.doesNotMatch(`${update.description} ${pi.tools.get("todo_list")!.promptGuidelines.join(" ")}`, /waiting|blocked/);
	assert.match(pi.tools.get("todo_list")!.description, /not Tatr repository issues/);
	const add = pi.tools.get("todo_add")!.parameters;
	const subtodo = pi.tools.get("todo_add_subtodo")!.parameters;
	assert.deepEqual(add.required, ["title"]);
	assert.deepEqual(Object.keys(add.properties), ["title"]);
	assert.deepEqual(subtodo.required, ["parentId", "title"]);
	assert.deepEqual(Object.keys(subtodo.properties), ["parentId", "title"]);
	assert.equal(subtodo.properties.parentId!.minimum, 1);
	assert.equal(update.parameters.properties.id!.minimum, 1);

	// w, b, i, and p no longer open dialogs or change todos.
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool("todo_add", {title: "Open work" });
	const snapshots = pi.branch.length;
	pi.keys.push(["w", "b", "i", "p", KEY.escape]);
	pi.inputs.push("unused");
	await pi.commands.get("todos")!.handler("", pi.ctx);
	assert.equal(pi.branch.length, snapshots);
	assert.deepEqual(pi.inputs, ["unused"]);
	const screen = pi.screen().join("\n");
	assert.match(screen, /> \[ \] #1 Open work/);
	assert.doesNotMatch(screen, /waiting|blocked/);
});

test("/todos shows the checklist but not the recorded message history", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "Fix parser", source: "interactive" });
	await pi.emit("input", { text: "Thanks for the help", source: "interactive" });
	await pi.commands.get("todos")!.handler("", pi.ctx);
	assert.match(pi.screen().join("\n"), /No todos\./);
	assert.doesNotMatch(pi.screen().join("\n"), /Fix parser|Thanks for the help/);

	await pi.tool("todo_add", { title: "Fix parser" });
	await pi.commands.get("todos")!.handler("", pi.ctx);
	const screen = pi.screen().join("\n");
	assert.match(screen, /> \[ \] #1 Fix parser/);
	assert.equal((screen.match(/Fix parser/g) ?? []).length, 1);
	assert.doesNotMatch(screen, /Thanks for the help/);
	assert.match(await pi.tool("todo_list"), /P2: Thanks for the help/, "history remains in the ledger");
});

test("Alt+T opens the same checklist as /todos", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool("todo_add", {title: "Verify shortcut" });
	await pi.commands.get("todos")!.handler("", pi.ctx);
	const commandScreen = pi.screen();
	await pi.shortcuts.get("alt+t")!.handler(pi.ctx);
	assert.deepEqual(pi.screen(), commandScreen);
	assert.match(pi.screen().join("\n"), /> \[ \] #1 Verify shortcut/);
});

test("Alt+T closes an open checklist and can reopen it", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool("todo_add", {title: "Toggle checklist" });
	pi.keys.push([KEY.altT]);
	await pi.shortcuts.get("alt+t")!.handler(pi.ctx);
	assert.match(pi.screen().join("\n"), /alt\+t \/ esc close/);
	pi.keys.push([KEY.escape]);
	await pi.shortcuts.get("alt+t")!.handler(pi.ctx);
	assert.match(pi.screen().join("\n"), /> \[ \] #1 Toggle checklist/);
});

test("clips long recorded messages without generating todo titles", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "x".repeat(2000), source: "interactive" });
	assert.equal(pi.ledger().prompts[0]!.text, `${"x".repeat(1000)}...`);
	assert.deepEqual(pi.ledger().tasks, []);
});

test("restores recorded messages and agent-selected todos without duplicates", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "First request", source: "interactive" });
	await pi.emit("input", { text: "Second request", source: "extension" });
	await pi.tool("todo_add", { title: "Do first" });
	await pi.tool("todo_update", {id: 1, status: "closed" });

	const restored = fakePi([...pi.branch]);
	await restored.emit("session_start", { reason: "resume" });
	await restored.emit("session_tree", { newLeafId: null, oldLeafId: null });
	await restored.emit("session_start", { reason: "reload" });
	assert.equal(await restored.tool("todo_list"), await pi.tool("todo_list"));
	await restored.emit("input", { text: "Third request", source: "interactive" });
	await restored.tool("todo_add", { title: "Do third" });
	assert.deepEqual(restored.ledger().tasks.map((task) => [task.id, task.status]),
		[[1, "closed"], [2, "open"]]);
	assert.deepEqual(restored.ledger().prompts.map((prompt) => prompt.id), [1, 2, 3]);
});

test("deletes a todo with its subtodos for good", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "Old request", source: "interactive" });
	await pi.tool("todo_add", { title: "Old request" });
	await pi.tool("todo_add_subtodo", {title: "Step", parentId: 1 });
	await pi.tool("todo_add_subtodo", {title: "Detail", parentId: 2 });
	await pi.tool("todo_add", {title: "Keep" });

	const deleted = await pi.tool("todo_delete", {id: 1 });
	assert.match(deleted, /^Deleted #1, #2, #3\./);
	assert.match(deleted, /P1: Old request/, "prompt history stays");
	assert.deepEqual(pi.ledger().tasks.map((task) => task.id), [4]);
	assert.equal(pi.statuses.get("todos"), "todos 0/1");

	const snapshots = pi.branch.length;
	await assert.rejects(pi.tool("todo_delete", {id: 1 }), /todo #1 does not exist/);
	await assert.rejects(pi.tool("todo_update", {id: 2, status: "closed" }), /todo #2 does not exist/);
	await assert.rejects(pi.tool("todo_add_subtodo", { title: "Late", parentId: 1 }), /todo #1 does not exist/);
	await assert.rejects(pi.tool("todo_add_subtodo", { title: "Zero", parentId: 0 }), /todo #0 does not exist/);
	assert.equal(pi.branch.length, snapshots, "failed changes must not write snapshots");

	// Ids are not reused after a delete.
	await pi.tool("todo_add", {title: "New" });
	assert.deepEqual(pi.ledger().tasks.map((task) => task.id), [4, 5]);

	// Deleting an open subtodo lets its parent close.
	await pi.tool("todo_add_subtodo", {title: "Child", parentId: 5 });
	await assert.rejects(pi.tool("todo_update", {id: 5, status: "closed" }), /open subtodos: #6/);
	await pi.tool("todo_delete", {id: 6 });
	await pi.tool("todo_update", {id: 5, status: "closed" });
	assert.equal(pi.ledger().tasks[1]!.status, "closed");
});

test("reopens closed parents when a subtodo reopens", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool("todo_add", {title: "Parent" });
	await pi.tool("todo_add_subtodo", {title: "Child", parentId: 1 });
	await pi.tool("todo_update", {id: 2, status: "closed" });
	await pi.tool("todo_update", {id: 1, status: "closed" });
	await assert.rejects(pi.tool("todo_add_subtodo", {title: "Late", parentId: 1 }), /parent todo #1 is closed/);

	await pi.tool("todo_update", {id: 2, status: "open" });
	assert.equal(pi.ledger().tasks[0]!.status, "open");
});

test("persists tool and /todos changes and restores them in a new runtime", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool("todo_add", { title: "First" });
	await pi.tool("todo_add", { title: "Second" });

	// Close #2 and add two subtodos to #1. The add dialog keeps the cursor, so delete the first.
	pi.keys.push([KEY.down, KEY.space, KEY.up, "o"], ["o"], [KEY.down, "x", KEY.escape]);
	pi.inputs.push("Sub", "Sub 2");
	await pi.commands.get("todos")!.handler("", pi.ctx);
	assert.match(pi.screen().join("\n"), /a add  o subtodo  x delete/);

	const expected = pi.ledger();
	assert.deepEqual(
		expected.tasks.map((task) => [task.id, task.title, task.status, task.parentId]),
		[
			[1, "First", "open", undefined],
			[2, "Second", "closed", undefined],
			[4, "Sub 2", "open", 1],
		],
	);
	assert.match(pi.screen().join("\n"), /\[ \] #1 First\n> {3}\[ \] #4 Sub 2/);

	const restored = fakePi([...pi.branch]);
	await restored.emit("session_start", { reason: "resume" });
	assert.equal(await restored.tool("todo_list"), await pi.tool("todo_list"));

	// Rule errors show in the list and do not write snapshots.
	const count = pi.branch.length;
	pi.keys.push([KEY.space, KEY.escape]);
	await pi.commands.get("todos")!.handler("", pi.ctx);
	assert.equal(pi.branch.length, count);
});

test("restores the ledger of the selected branch", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool("todo_add", {title: "Keep" });
	const fork = pi.branch.length;
	await pi.tool("todo_add", {title: "Abandoned" });
	await pi.tool("todo_update", {id: 1, status: "closed" });

	pi.branch.splice(fork);
	await pi.emit("session_tree", { newLeafId: `e${fork}`, oldLeafId: null });
	const listing = await pi.tool("todo_list");
	assert.match(listing, /\[ \] #1 Keep/);
	assert.doesNotMatch(listing, /Abandoned/);

	pi.branch.splice(0);
	await pi.emit("session_tree", { newLeafId: null, oldLeafId: null });
	assert.equal(await pi.tool("todo_list"), "No todos.");
});

test("renders compact todo calls and results, with the full ledger on expansion", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "Fix parser", source: "interactive" });
	await pi.tool("todo_add", { title: "Fix parser" });
	const listTool = pi.tools.get("todo_list")!;
	const theme = { fg: (_color: string, text: string) => text };
	const text = (component: Rendered) => component.render(100).map((line) => line.trimEnd()).join("\n").trimEnd();
	const call = (name: string, args: Record<string, unknown>) => text(pi.tools.get(name)!.renderCall(args, theme));
	assert.equal(call("todo_update", { id: 1, status: "closed" }), "todo_update #1 closed");
	assert.equal(call("todo_add", { title: "Fix parser" }), 'todo_add "Fix parser"');
	assert.equal(call("todo_add_subtodo", { parentId: 1, title: "Read parser" }),
		'todo_add_subtodo under #1 "Read parser"');
	assert.equal(call("todo_delete", { id: 1 }), "todo_delete #1");
	assert.equal(call("todo_list", {}), "todo_list");

	const list = await listTool.execute("call", {}, undefined, undefined, pi.ctx);
	const collapsed = text(listTool.renderResult(list, { expanded: false }, theme, { isError: false }));
	assert.equal(collapsed, "1 todo, 1 open");
	const expanded = text(listTool.renderResult(list, { expanded: true }, theme, { isError: false }));
	assert.match(expanded, /\[ \] #1 Fix parser/);

	const updateTool = pi.tools.get("todo_update")!;
	const update = await updateTool.execute("call", { id: 1, status: "closed" }, undefined, undefined, pi.ctx);
	assert.equal(text(updateTool.renderResult(update, { expanded: false }, theme, { isError: false })),
		"Todo #1 is closed.");
	assert.match(text(updateTool.renderResult(update, { expanded: true }, theme, { isError: false })),
		/\[x\] #1 Fix parser/);
	const error = { content: [{ type: "text", text: "Todo not found" }] };
	assert.equal(text(listTool.renderResult(error, { expanded: false }, theme, { isError: true })),
		"Todo not found");
});

function boundary(fields: Record<string, unknown> = {}) {
	return { outcome: "completed", continue: false, entries: [], context: { pendingMessages: [] }, ...fields };
}

test("continues at settlement while todos are open", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	assert.equal(await pi.emit("agent_before_settle", boundary()), undefined, "no todos, no nudge");

	await pi.tool("todo_add", { title: "Fix parser" });
	await pi.tool("todo_add", { title: "Update docs" });
	const nudge = await pi.emit("agent_before_settle", boundary());
	assert.equal(nudge?.continue, true);
	const entries = nudge?.entries as { customType: string; content: string }[];
	assert.equal(entries.at(-1)!.customType, "todos-continue");
	assert.match(entries.at(-1)!.content, /#1 Fix parser\n#2 Update docs/);

	await pi.emit("tool_call", { toolName: "bash" });
	await pi.tool("todo_update", {id: 1, status: "closed" });
	const next = await pi.emit("agent_before_settle", boundary());
	assert.doesNotMatch((next?.entries as { content: string }[]).at(-1)!.content, /#1 /, "closed todos are not listed");

	await pi.tool("todo_update", {id: 2, status: "closed" });
	assert.equal(await pi.emit("agent_before_settle", boundary()), undefined, "all closed, no nudge");
});

test("does not nudge after an abort, an error, an existing continuation, or a queued message", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool("todo_add", {title: "Work" });
	assert.equal(await pi.emit("agent_before_settle", boundary({ outcome: "aborted" })), undefined);
	assert.equal(await pi.emit("agent_before_settle", boundary({ outcome: "error" })), undefined);
	assert.equal(await pi.emit("agent_before_settle", boundary({ continue: true })), undefined);
	assert.equal(await pi.emit("agent_before_settle", boundary({ context: { pendingMessages: [{}] } })), undefined);
});

test("stops when the agent makes no tool calls after a nudge, and resets for the next activity", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool("todo_add", {title: "Wait for the job" });
	assert.equal((await pi.emit("agent_before_settle", boundary()))?.continue, true);
	assert.equal(await pi.emit("agent_before_settle", boundary()), undefined, "an idle turn ends the loop");
	await pi.emit("agent_settled");

	// A wake from a finished job starts a new activity with a fresh budget.
	assert.equal((await pi.emit("agent_before_settle", boundary()))?.continue, true);
});

test("stops after repeated nudges without a todo change", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool("todo_add", {title: "Endless work" });
	for (let i = 0; i < 5; i++) {
		assert.equal((await pi.emit("agent_before_settle", boundary()))?.continue, true, `nudge ${i + 1}`);
		await pi.emit("tool_call", { toolName: "bash" });
	}
	assert.equal(await pi.emit("agent_before_settle", boundary()), undefined);
	assert.match(pi.notes.at(-1)!.message, /no todo changed after 5 nudges/);

	// A todo change resets the stall count.
	await pi.emit("agent_settled");
	for (let i = 0; i < 4; i++) {
		await pi.emit("agent_before_settle", boundary());
		await pi.emit("tool_call", { toolName: "bash" });
	}
	await pi.tool("todo_add", {title: "More work" });
	for (let i = 0; i < 5; i++) {
		assert.equal((await pi.emit("agent_before_settle", boundary()))?.continue, true, `nudge after change ${i + 1}`);
		await pi.emit("tool_call", { toolName: "bash" });
	}
});
