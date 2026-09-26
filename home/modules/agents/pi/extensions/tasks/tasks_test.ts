// Runs the tasks extension against a minimal fake Pi runtime.
// Run with: npm test
import assert from "node:assert/strict";
import { test } from "node:test";

import extension, { type Ledger } from "./tasks.ts";

type Handler = (event: unknown, ctx: unknown) => unknown;
type Entry = { id: string; type: string; customType?: string; data?: unknown };
type ToolResult = { content: { text: string }[]; details?: { summary: string } };
type Rendered = { render(width: number): string[] };
type Tool = {
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

	async function tool(params: Record<string, unknown>) {
		const result = await tools.get("tasks")!.execute("call", params, undefined, undefined, ctx);
		return result.content[0]!.text;
	}

	function ledger(): Ledger {
		const snapshots = branch.filter((entry) => entry.customType === "tasks-ledger");
		return snapshots.at(-1)?.data as Ledger;
	}

	function settle(outcome = "completed", pendingMessages: unknown[] = []) {
		return emit("agent_before_settle", {
			outcome,
			entries: [],
			continue: false,
			context: { canContinue: false, pendingMessages },
		});
	}

	return { branch, notes, widgets, statuses, inputs, keys, ctx, emit, tool, tools, ledger, settle, commands, shortcuts, screen: () => screens.at(-1) ?? [], screens };
}

test("records messages before the agent selects actionable tasks", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "Fix the parser and update docs", source: "interactive" });
	await pi.emit("input", { text: "  Thanks ", source: "extension", streamingBehavior: "steer" });
	await pi.emit("input", { text: "Fix the parser and update docs", source: "rpc" });
	const snapshots = pi.branch.length;
	await pi.emit("input", { text: " \n ", source: "interactive" });
	assert.equal(pi.branch.length, snapshots, "empty input must not write snapshots");
	assert.deepEqual(pi.ledger().tasks, [], "input does not create tasks");
	assert.equal(await pi.settle(), undefined, "messages alone do not trigger reminders");
	assert.deepEqual(pi.ledger().prompts.map((prompt) => [prompt.id, prompt.source]),
		[[1, "interactive"], [2, "extension"], [3, "rpc"]]);

	await pi.tool({ action: "add", titles: ["Fix parser", "Update docs"], promptId: 1 });
	await pi.tool({ action: "add", title: "Read parser", parentId: 1 });
	assert.deepEqual(pi.ledger().tasks.map((task) => [task.title, task.promptId, task.parentId]),
		[["Fix parser", 1, undefined], ["Update docs", 1, undefined], ["Read parser", undefined, 1]]);
	await assert.rejects(pi.tool({ action: "add", title: "Bad link", promptId: 99 }), /prompt P99 does not exist/);
	assert.equal(pi.ledger().tasks.length, 3);
	await pi.tool({ action: "update", id: 3, status: "completed" });
	await pi.tool({ action: "update", id: 1, status: "completed" });
	assert.equal(await pi.emit("before_agent_start", { prompt: "x", systemPrompt: "" }), undefined);
	const reminder = await pi.settle();
	const content = (reminder?.entries as { content: string }[])[0]!.content;
	assert.doesNotMatch(content, /#1 /);
	assert.match(content, /\[ \] #2 P1: Update docs/);
	assert.doesNotMatch(content, /Thanks/);
	const listing = await pi.tool({ action: "list" });
	assert.match(listing, /P2: Thanks/);
	assert.match(listing, /\[x\] #1 P1: Fix parser/);

	const replaced = await pi.tool({ action: "supersede", id: 2, title: "Revise documentation" });
	assert.match(replaced, /\[~\] #2 P1: Update docs \(superseded by #4\)/);
	assert.match(replaced, /\[ \] #4 Revise documentation/);
});

test("/todos shows the checklist but not the recorded message history", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "Fix parser", source: "interactive" });
	await pi.emit("input", { text: "Thanks for the help", source: "interactive" });
	await pi.commands.get("todos")!.handler("", pi.ctx);
	assert.match(pi.screen().join("\n"), /No tasks\./);
	assert.doesNotMatch(pi.screen().join("\n"), /Fix parser|Thanks for the help/);

	await pi.tool({ action: "add", title: "Fix parser", promptId: 1 });
	await pi.commands.get("todos")!.handler("", pi.ctx);
	const screen = pi.screen().join("\n");
	assert.match(screen, /> \[ \] #1 P1: Fix parser/);
	assert.equal((screen.match(/Fix parser/g) ?? []).length, 1);
	assert.doesNotMatch(screen, /Thanks for the help/);
	assert.match(await pi.tool({ action: "list" }), /P2: Thanks for the help/, "history remains in the ledger");
});

test("Alt+T opens the same checklist as /todos", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool({ action: "add", title: "Verify shortcut" });
	await pi.commands.get("todos")!.handler("", pi.ctx);
	const commandScreen = pi.screen();
	await pi.shortcuts.get("alt+t")!.handler(pi.ctx);
	assert.deepEqual(pi.screen(), commandScreen);
	assert.match(pi.screen().join("\n"), /> \[ \] #1 Verify shortcut/);
});

test("Alt+T closes an open checklist and can reopen it", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool({ action: "add", title: "Toggle checklist" });
	pi.keys.push([KEY.altT]);
	await pi.shortcuts.get("alt+t")!.handler(pi.ctx);
	assert.match(pi.screen().join("\n"), /alt\+t \/ esc close/);
	pi.keys.push([KEY.escape]);
	await pi.shortcuts.get("alt+t")!.handler(pi.ctx);
	assert.match(pi.screen().join("\n"), /> \[ \] #1 Toggle checklist/);
});

test("clips long recorded messages without generating task titles", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "x".repeat(2000), source: "interactive" });
	assert.equal(pi.ledger().prompts[0]!.text, `${"x".repeat(1000)}...`);
	assert.deepEqual(pi.ledger().tasks, []);
});

test("restores recorded messages and agent-selected tasks without duplicates", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "First request", source: "interactive" });
	await pi.emit("input", { text: "Second request", source: "extension" });
	await pi.tool({ action: "add", title: "Do first", promptId: 1 });
	await pi.tool({ action: "update", id: 1, status: "in_progress" });

	const restored = fakePi([...pi.branch]);
	await restored.emit("session_start", { reason: "resume" });
	await restored.emit("session_tree", { newLeafId: null, oldLeafId: null });
	await restored.emit("session_start", { reason: "reload" });
	assert.equal(await restored.tool({ action: "list" }), await pi.tool({ action: "list" }));
	await restored.emit("input", { text: "Third request", source: "interactive" });
	await restored.tool({ action: "add", title: "Do third", promptId: 3 });
	assert.deepEqual(restored.ledger().tasks.map((task) => [task.id, task.status, task.promptId]),
		[[1, "in_progress", 1], [2, "pending", 3]]);
	assert.deepEqual(restored.ledger().prompts.map((prompt) => prompt.id), [1, 2, 3]);
});

test("supersedes a task with a linked replacement and moves open subtasks", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool({ action: "add", title: "Old approach" });
	await pi.tool({ action: "add", title: "Step", parentId: 1 });
	await pi.tool({ action: "supersede", id: 1, title: "New approach", note: "old API is gone" });

	let ledger = pi.ledger();
	assert.deepEqual(ledger.tasks[0], {
		id: 1,
		title: "Old approach",
		status: "superseded",
		replacedBy: 3,
		note: "old API is gone",
	});
	assert.equal(ledger.tasks[1]!.parentId, 3);
	assert.equal(ledger.tasks[2]!.title, "New approach");

	await assert.rejects(pi.tool({ action: "update", id: 1, status: "pending" }), /superseded by #3/);
	await assert.rejects(pi.tool({ action: "update", id: 3, status: "completed" }), /unresolved subtasks: #2/);
	await assert.rejects(pi.tool({ action: "supersede", id: 3, replacementId: 2 }), /its subtask/);
	await assert.rejects(pi.tool({ action: "update", id: 2, status: "blocked" }), /needs a reason/);
	const snapshots = pi.branch.length;

	await pi.tool({ action: "add", title: "Other" });
	await pi.tool({ action: "supersede", id: 4, replacementId: 3 });
	ledger = pi.ledger();
	assert.equal(ledger.tasks[3]!.status, "superseded");
	assert.equal(ledger.tasks[3]!.replacedBy, 3);
	assert.equal(pi.branch.length, snapshots + 2, "failed changes must not write snapshots");
});

test("reopens completed parents when a subtask becomes unresolved", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool({ action: "add", title: "Parent" });
	await pi.tool({ action: "add", title: "Child", parentId: 1 });
	await pi.tool({ action: "update", id: 2, status: "completed" });
	await pi.tool({ action: "update", id: 1, status: "completed" });
	await assert.rejects(pi.tool({ action: "add", title: "Late", parentId: 1 }), /parent task #1 is completed/);

	await pi.tool({ action: "update", id: 2, status: "pending" });
	assert.equal(pi.ledger().tasks[0]!.status, "pending");

	await pi.tool({ action: "update", id: 2, status: "completed" });
	await pi.tool({ action: "update", id: 1, status: "completed" });
	await pi.tool({ action: "supersede", id: 2, title: "Child v2" });
	const tasks = pi.ledger().tasks;
	assert.deepEqual(
		tasks.map((task) => [task.id, task.status, task.parentId]),
		[
			[1, "pending", undefined],
			[2, "superseded", 1],
			[3, "pending", 1],
		],
	);
});

test("persists tool and /todos changes and restores them in a new runtime", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool({ action: "add", titles: ["First", "Second"] });

	// Complete #2, block #1, add a subtask to #1, then supersede it.
	pi.keys.push([KEY.down, KEY.space, KEY.up, "b"], ["n"], [KEY.down, "r"], [KEY.escape]);
	pi.inputs.push("waiting for review", "Sub", "Sub v2");
	await pi.commands.get("todos")!.handler("", pi.ctx);

	const expected = pi.ledger();
	assert.deepEqual(
		expected.tasks.map((task) => [task.id, task.status, task.parentId, task.replacedBy, task.note]),
		[
			[1, "blocked", undefined, undefined, "waiting for review"],
			[2, "completed", undefined, undefined, undefined],
			[3, "superseded", 1, 4, undefined],
			[4, "pending", 1, undefined, undefined],
		],
	);

	const restored = fakePi([...pi.branch]);
	await restored.emit("session_start", { reason: "resume" });
	assert.equal(await restored.tool({ action: "list" }), await pi.tool({ action: "list" }));

	// Rule errors show in the list and do not write snapshots.
	const count = pi.branch.length;
	pi.keys.push([KEY.space, KEY.escape]);
	await pi.commands.get("todos")!.handler("", pi.ctx);
	assert.equal(pi.branch.length, count);
});

test("restores the ledger of the selected branch", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool({ action: "add", title: "Keep" });
	const fork = pi.branch.length;
	await pi.tool({ action: "add", title: "Abandoned" });
	await pi.tool({ action: "update", id: 1, status: "completed" });

	pi.branch.splice(fork);
	await pi.emit("session_tree", { newLeafId: `e${fork}`, oldLeafId: null });
	const listing = await pi.tool({ action: "list" });
	assert.match(listing, /\[ \] #1 Keep/);
	assert.doesNotMatch(listing, /Abandoned/);

	pi.branch.splice(0);
	await pi.emit("session_tree", { newLeafId: null, oldLeafId: null });
	assert.equal(await pi.tool({ action: "list" }), "No tasks.");
});

test("continues while actionable tasks remain, without a retry limit", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	assert.equal(await pi.settle(), undefined, "no tasks, no continuation");

	await pi.tool({ action: "add", titles: ["A", "B"] });
	assert.equal(await pi.settle("error"), undefined);
	assert.equal(await pi.settle("aborted"), undefined, "Esc cancels the run");
	assert.equal(await pi.settle("completed", [{ role: "user" }]), undefined, "queued input continues the run");

	for (let index = 1; index <= 6; index++) {
		if (index === 2) {
			await pi.tool({ action: "add", title: "C" });
			await pi.tool({ action: "archive", id: 1 });
		}
		if (index === 3) await pi.tool({ action: "restore", id: 1 });
		const result = await pi.settle();
		assert.equal(result?.continue, true);
		const [entry] = result?.entries as { type: string; content: string }[];
		assert.equal(entry!.type, "custom_message");
		assert.match(entry!.content, /#2 B/);
		assert.doesNotMatch(entry!.content, /Continuation \d+ of/);
	}
	assert.equal(pi.notes.length, 0, "no retry-limit warning");

	await pi.tool({ action: "update", id: 1, status: "completed" });
	assert.equal((await pi.settle())?.continue, true);
	await pi.emit("input", { text: "keep going", source: "interactive" });
	await pi.tool({ action: "add", title: "Continue work", promptId: 1 });
	assert.equal((await pi.settle())?.continue, true);

	// Blocked tasks need the user, so they do not continue the run.
	await pi.tool({ action: "update", id: 3, status: "completed" });
	await pi.tool({ action: "update", id: 4, status: "completed" });
	await pi.tool({ action: "update", id: 2, status: "blocked", note: "needs credentials" });
	assert.equal(await pi.settle(), undefined);
});

test("archives a task tree without changing statuses, links, or prompts", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "Old request", source: "interactive" });
	await pi.tool({ action: "add", title: "Old request", promptId: 1 });
	await pi.tool({ action: "add", title: "Step", parentId: 1 });
	await pi.tool({ action: "add", title: "Detail", parentId: 2 });
	await pi.tool({ action: "update", id: 3, status: "in_progress" });
	await pi.tool({ action: "add", title: "Keep" });
	await pi.tool({ action: "supersede", id: 4, title: "Keep v2" });
	const before = pi.ledger();

	const archived = await pi.tool({ action: "archive", id: 1 });
	assert.match(archived, /^Archived #1, #2, #3\./);
	assert.doesNotMatch(archived, /#[123] /);
	assert.match(archived, /P1: Old request/, "prompt history stays");
	assert.match(archived, /3 archived tasks hidden\./);
	assert.equal(pi.statuses.get("tasks"), "tasks 0/1");

	// Only archivedWith changes. Nothing is deleted.
	const after = pi.ledger();
	assert.deepEqual(after.prompts, before.prompts);
	assert.deepEqual(
		after.tasks.map(({ archivedWith, ...task }) => task),
		before.tasks,
	);
	assert.deepEqual(
		after.tasks.map((task) => task.archivedWith),
		[1, 1, 1, undefined, undefined],
	);
	assert.equal(after.tasks[3]!.replacedBy, 5);

	const full = await pi.tool({ action: "list", archived: true });
	assert.match(full, /\[ \] #1 P1: Old request \(archived\)/);
	assert.match(full, /    \[>\] #3 Detail \(archived\)/);

	// Archived tasks leave reminders and continuations.
	await pi.tool({ action: "update", id: 5, status: "completed" });
	const start = await pi.emit("before_agent_start", { prompt: "x", systemPrompt: "" });
	assert.equal(start, undefined);
	assert.equal(await pi.settle(), undefined);
	assert.equal(pi.statuses.get("tasks"), "tasks 1/1");

	// Restore brings back the whole tree with the old statuses.
	const restored = await pi.tool({ action: "restore", id: 1 });
	assert.match(restored, /^Restored #1, #2, #3\./);
	assert.deepEqual(
		pi.ledger().tasks.map((task) => [task.id, task.status, task.archivedWith]),
		[
			[1, "pending", undefined],
			[2, "pending", undefined],
			[3, "in_progress", undefined],
			[4, "superseded", undefined],
			[5, "completed", undefined],
		],
	);
	assert.equal((await pi.settle())?.continue, true);
	assert.equal(pi.statuses.get("tasks"), "tasks 1/4");
});

test("keeps archive groups coherent and rejects changes to archived tasks", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool({ action: "add", title: "Parent" });
	await pi.tool({ action: "add", titles: ["A", "B"], parentId: 1 });
	await pi.tool({ action: "add", title: "Other" });
	await pi.tool({ action: "archive", id: 2 });
	await pi.tool({ action: "archive", id: 1 });
	assert.deepEqual(
		pi.ledger().tasks.map((task) => task.archivedWith),
		[1, 2, 1, undefined],
	);

	const snapshots = pi.branch.length;
	await assert.rejects(pi.tool({ action: "archive", id: 1 }), /task #1 is archived/);
	await assert.rejects(pi.tool({ action: "restore", id: 4 }), /task #4 is not archived/);
	await assert.rejects(pi.tool({ action: "restore", id: 3 }), /archived with #1; restore #1/);
	await assert.rejects(pi.tool({ action: "restore", id: 2 }), /parent task #1 is archived/);
	await assert.rejects(pi.tool({ action: "restore" }), /restore needs id/);
	await assert.rejects(pi.tool({ action: "update", id: 3, status: "completed" }), /task #3 is archived/);
	await assert.rejects(pi.tool({ action: "add", title: "Late", parentId: 1 }), /task #1 is archived/);
	await assert.rejects(pi.tool({ action: "supersede", id: 1, title: "New" }), /task #1 is archived/);
	await assert.rejects(pi.tool({ action: "supersede", id: 4, replacementId: 1 }), /task #1 is archived/);
	assert.equal(pi.branch.length, snapshots, "failed changes must not write snapshots");

	// The parent group comes back without the subtask archived on its own.
	await pi.tool({ action: "restore", id: 1 });
	assert.deepEqual(
		pi.ledger().tasks.map((task) => task.archivedWith),
		[undefined, 2, undefined, undefined],
	);

	// An archived open subtask does not hold its parent open. Restoring it reopens the parent.
	await pi.tool({ action: "update", id: 3, status: "completed" });
	await pi.tool({ action: "update", id: 1, status: "completed" });
	// Supersession moves an archived open subtask to the replacement and keeps it archived.
	await pi.tool({ action: "update", id: 4, status: "completed" });
	await pi.tool({ action: "supersede", id: 1, replacementId: 4 });
	assert.deepEqual(
		pi.ledger().tasks.map((task) => [task.id, task.status, task.parentId, task.archivedWith]),
		[
			[1, "superseded", undefined, undefined],
			[2, "pending", 4, 2],
			[3, "completed", 1, undefined],
			[4, "completed", undefined, undefined],
		],
	);
	await assert.rejects(pi.tool({ action: "update", id: 1, status: "pending" }), /superseded by #4/);
	await pi.tool({ action: "restore", id: 2 });
	assert.equal(pi.ledger().tasks[3]!.status, "pending", "the restored subtask reopens its new parent");

	await pi.tool({ action: "add", title: "Solo" });
	await pi.tool({ action: "add", title: "Solo step", parentId: 5 });
	await pi.tool({ action: "archive", id: 6 });
	await pi.tool({ action: "update", id: 5, status: "completed" });
	await pi.tool({ action: "restore", id: 6 });
	assert.equal(pi.ledger().tasks[4]!.status, "pending");
});

test("archives and restores from /todos and keeps the view across dialogs", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.tool({ action: "add", title: "Parent" });
	await pi.tool({ action: "add", title: "Child", parentId: 1 });
	await pi.tool({ action: "add", title: "Other" });

	// Archive the parent tree, show archived rows, fail to restore the child alone, then restore the parent.
	pi.keys.push(["x", KEY.escape]);
	await pi.commands.get("todos")!.handler("", pi.ctx);
	assert.deepEqual(
		pi.ledger().tasks.map((task) => task.archivedWith),
		[1, 1, undefined],
	);
	assert.match(pi.screen().join("\n"), /> \[ \] #3 Other/);
	assert.doesNotMatch(pi.screen().join("\n"), /#1 Parent/);
	assert.match(pi.screen().join("\n"), /x archive  u restore  v show archived/);

	const snapshots = pi.branch.length;
	pi.keys.push(["v", KEY.down, "u", "x", KEY.escape]);
	await pi.commands.get("todos")!.handler("", pi.ctx);
	assert.equal(pi.branch.length, snapshots, "rejected restore and archive must not write snapshots");
	const [, , afterRestore, afterArchive] = pi.screens.slice(-5).map((lines) => lines.join("\n"));
	assert.match(afterRestore!, /Tasks \(with archived\)/);
	assert.match(afterRestore!, /> {3}\[ \] #2 Child \(archived\)/);
	assert.match(afterRestore!, /archived with #1; restore #1/);
	assert.match(afterArchive!, /task #2 is archived/);

	pi.keys.push(["v", "a"], [KEY.escape]);
	pi.inputs.push("Added");
	await pi.commands.get("todos")!.handler("", pi.ctx);
	assert.match(pi.screen().join("\n"), /Tasks \(with archived\)/, "the view stays after the add dialog");

	pi.keys.push(["v", "u", KEY.escape]);
	await pi.commands.get("todos")!.handler("", pi.ctx);
	assert.deepEqual(
		pi.ledger().tasks.map((task) => [task.title, task.archivedWith]),
		[
			["Parent", undefined],
			["Child", undefined],
			["Other", undefined],
			["Added", undefined],
		],
	);
	assert.match(pi.screen().join("\n"), /> \[ \] #1 Parent\n {4}\[ \] #2 Child/);
});

test("restores archive state from the selected branch", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "Request", source: "interactive" });
	await pi.tool({ action: "add", title: "Request", promptId: 1 });
	await pi.tool({ action: "add", title: "Step", parentId: 1 });
	const fork = pi.branch.length;
	await pi.tool({ action: "archive", id: 1 });
	const archivedBranch = [...pi.branch];

	// Leaving the branch brings the tasks back. The archive snapshot stays in history.
	pi.branch.splice(fork);
	await pi.emit("session_tree", { newLeafId: `e${fork}`, oldLeafId: null });
	assert.match(await pi.tool({ action: "list" }), /\[ \] #1 P1: Request\n    \[ \] #2 Step$/);
	assert.equal((await pi.settle())?.continue, true);

	const resumed = fakePi(archivedBranch);
	await resumed.emit("session_start", { reason: "resume" });
	const listing = await resumed.tool({ action: "list" });
	assert.match(listing, /P1: Request\nNo tasks\.\n2 archived tasks hidden\./);
	assert.equal(await resumed.settle(), undefined);
	await resumed.tool({ action: "restore", id: 1 });
	assert.match(await resumed.tool({ action: "list" }), /\[ \] #1 P1: Request\n    \[ \] #2 Step$/);
	// Every snapshot keeps every task. Archive and restore never delete.
	for (const entry of resumed.branch.slice(fork)) {
		assert.equal((entry.data as Ledger).tasks.length, 2);
	}
});

test("renders compact task calls and results, with the full ledger on expansion", async () => {
	const pi = fakePi();
	await pi.emit("session_start", { reason: "startup" });
	await pi.emit("input", { text: "Fix parser", source: "interactive" });
	await pi.tool({ action: "add", title: "Fix parser", promptId: 1 });
	const tasks = pi.tools.get("tasks")!;
	const theme = { fg: (_color: string, text: string) => text };
	const text = (component: Rendered) => component.render(100).map((line) => line.trimEnd()).join("\n").trimEnd();
	const call = (args: Record<string, unknown>) => text(tasks.renderCall(args, theme));
	assert.equal(call({ action: "update", id: 1, status: "completed" }), "tasks update #1 completed");
	assert.equal(call({ action: "add", parentId: 1, promptId: 1, title: "Read parser" }),
		'tasks add under #1 for P1 "Read parser"');
	assert.equal(call({ action: "supersede", id: 1, replacementId: 2, note: "new plan" }),
		'tasks supersede #1 with #2 note="new plan"');
	assert.equal(call({ action: "list", archived: true }), "tasks list including archived");

	const list = await tasks.execute("call", { action: "list" }, undefined, undefined, pi.ctx);
	const collapsed = text(tasks.renderResult(list, { expanded: false }, theme, { isError: false }));
	assert.equal(collapsed, "1 task, 1 open");
	const expanded = text(tasks.renderResult(list, { expanded: true }, theme, { isError: false }));
	assert.match(expanded, /\[ \] #1 P1: Fix parser/);

	const update = await tasks.execute("call", { action: "update", id: 1, status: "completed" }, undefined, undefined, pi.ctx);
	assert.equal(text(tasks.renderResult(update, { expanded: false }, theme, { isError: false })),
		"Task #1 is completed.");
	assert.match(text(tasks.renderResult(update, { expanded: true }, theme, { isError: false })),
		/\[x\] #1 P1: Fix parser/);
	const error = { content: [{ type: "text", text: "Task not found" }] };
	assert.equal(text(tasks.renderResult(error, { expanded: false }, theme, { isError: true })),
		"Task not found");
});
