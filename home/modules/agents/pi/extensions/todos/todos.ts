import { StringEnum, Type } from "@earendil-works/pi-ai";
import type { AgentToolResult, ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, Text, truncateToWidth } from "@earendil-works/pi-tui";

export type TaskStatus = "open" | "closed";

export type Task = {
	id: number;
	title: string;
	status: TaskStatus;
	parentId?: number;
};

export type Prompt = {
	id: number;
	text: string;
	source: string;
};

export type Ledger = {
	version: 1;
	nextTaskId: number;
	nextPromptId: number;
	prompts: Prompt[];
	tasks: Task[];
};

// Keep this session entry type and the ledger field names for existing sessions.
const STATE_TYPE = "tasks-ledger";
const CONTINUE_TYPE = "todos-continue";
// Nudges in one agent activity without a ledger change before the loop gives up.
const MAX_STALLED_NUDGES = 5;
const MAX_PROMPT_CHARS = 1000;
const MAX_TITLE_CHARS = 120;
const STATUS_MARK: Record<TaskStatus, string> = {
	open: "[ ]",
	closed: "[x]",
};

export function emptyLedger(): Ledger {
	return { version: 1, nextTaskId: 1, nextPromptId: 1, prompts: [], tasks: [] };
}

function isOpen(task: Task): boolean {
	return task.status === "open";
}

function findTask(ledger: Ledger, id: number): Task {
	const task = ledger.tasks.find((candidate) => candidate.id === id);
	if (!task) throw new Error(`todo #${id} does not exist`);
	return task;
}

/** A todo and all of its subtodos. */
function subtree(ledger: Ledger, id: number): Task[] {
	return ledger.tasks.filter((task) => task.id === id || isDescendant(ledger, task.id, id));
}

function isDescendant(ledger: Ledger, id: number, ancestorId: number): boolean {
	let current = ledger.tasks.find((task) => task.id === id);
	while (current?.parentId !== undefined) {
		if (current.parentId === ancestorId) return true;
		current = ledger.tasks.find((task) => task.id === current?.parentId);
	}
	return false;
}

function clip(text: string, max: number): string {
	return text.length > max ? `${text.slice(0, max)}...` : text;
}

export function addPrompt(ledger: Ledger, text: string, source: string): Prompt | undefined {
	const trimmed = text.trim();
	if (!trimmed) return undefined;
	const prompt = { id: ledger.nextPromptId++, text: clip(trimmed, MAX_PROMPT_CHARS), source };
	ledger.prompts.push(prompt);
	return prompt;
}

/** Reopen closed ancestors of an open todo. */
function reopenAncestors(ledger: Ledger, task: Task) {
	if (!isOpen(task)) return;
	let parent = ledger.tasks.find((candidate) => candidate.id === task.parentId);
	while (parent) {
		if (parent.status === "closed") parent.status = "open";
		parent = ledger.tasks.find((candidate) => candidate.id === parent?.parentId);
	}
}

export function addTask(ledger: Ledger, title: string, parentId?: number): Task {
	if (parentId !== undefined) {
		const parent = findTask(ledger, parentId);
		if (!isOpen(parent)) throw new Error(`parent todo #${parentId} is ${parent.status}`);
	}
	const trimmed = title.trim();
	if (!trimmed) throw new Error("todo title must not be empty");
	const task: Task = { id: ledger.nextTaskId++, title: trimmed, status: "open" };
	if (parentId !== undefined) task.parentId = parentId;
	ledger.tasks.push(task);
	return task;
}

export function setStatus(ledger: Ledger, id: number, status: TaskStatus): Task {
	const task = findTask(ledger, id);
	if (status === "closed") {
		const open = ledger.tasks.filter((child) => child.parentId === id && isOpen(child));
		if (open.length > 0) {
			throw new Error(`todo #${id} has open subtodos: ${open.map((child) => `#${child.id}`).join(", ")}`);
		}
	}
	task.status = status;
	reopenAncestors(ledger, task);
	return task;
}

/** Remove a todo and its subtodos for good. A replacement is a new todo. */
export function deleteTask(ledger: Ledger, id: number): Task[] {
	findTask(ledger, id);
	const removed = subtree(ledger, id);
	ledger.tasks = ledger.tasks.filter((task) => !removed.includes(task));
	return removed;
}

/** Todos in tree order with their depth. */
export function treeRows(ledger: Ledger): { task: Task; depth: number }[] {
	const rows: { task: Task; depth: number }[] = [];
	const visit = (parentId: number | undefined, depth: number) => {
		for (const task of ledger.tasks) {
			if (task.parentId !== parentId) continue;
			rows.push({ task, depth });
			visit(task.id, depth + 1);
		}
	};
	visit(undefined, 0);
	return rows;
}

export function formatTask(task: Task, depth = 0): string {
	return `${"  ".repeat(depth)}${STATUS_MARK[task.status]} #${task.id} ${task.title}`;
}

export function formatLedger(ledger: Ledger): string {
	const lines: string[] = [];
	if (ledger.prompts.length > 0) {
		lines.push("User requests:");
		for (const prompt of ledger.prompts) lines.push(`  P${prompt.id}: ${prompt.text.replace(/\s+/g, " ")}`);
	}
	const rows = treeRows(ledger);
	lines.push(rows.length > 0 ? "Todos:" : "No todos.");
	for (const { task, depth } of rows) lines.push(`  ${formatTask(task, depth)}`);
	return lines.join("\n");
}

function isLedger(value: unknown): value is Ledger {
	const ledger = value as Ledger | undefined;
	return (
		ledger?.version === 1 &&
		Number.isInteger(ledger.nextTaskId) &&
		Number.isInteger(ledger.nextPromptId) &&
		Array.isArray(ledger.prompts) &&
		Array.isArray(ledger.tasks)
	);
}

/** List position that stays the same while a prompt dialog is open. */
type ListView = { selected: number };

type ListAction = { kind: "close" } | ({ kind: "add"; parentId?: number } & ListView);

/** Keyboard-driven view of the ledger for /todos. */
class TaskListComponent {
	private readonly ledger: () => Ledger;
	private readonly theme: Theme;
	private readonly change: (mutate: (ledger: Ledger) => void) => string | undefined;
	private readonly render_: () => void;
	private readonly done: (action: ListAction) => void;
	private selected: number;
	private message = "";

	constructor(
		ledger: () => Ledger,
		theme: Theme,
		view: ListView,
		change: (mutate: (ledger: Ledger) => void) => string | undefined,
		requestRender: () => void,
		done: (action: ListAction) => void,
	) {
		this.ledger = ledger;
		this.theme = theme;
		this.selected = view.selected;
		this.change = change;
		this.render_ = requestRender;
		this.done = done;
	}

	private rows() {
		return treeRows(this.ledger());
	}

	private view(): ListView {
		return { selected: this.selected };
	}

	/** Keep the cursor on a row after rows disappear. */
	private clamp() {
		this.selected = Math.max(0, Math.min(this.selected, this.rows().length - 1));
	}

	private apply(mutate: (ledger: Ledger) => void) {
		this.message = this.change(mutate) ?? "";
		this.clamp();
	}

	handleInput(data: string): void {
		const rows = this.rows();
		this.clamp();
		const task = rows[this.selected]?.task;
		this.message = "";
		if (matchesKey(data, "escape") || matchesKey(data, "q") || matchesKey(data, "ctrl+c") || matchesKey(data, Key.alt("t"))) {
			this.done({ kind: "close" });
			return;
		} else if (matchesKey(data, "up") || matchesKey(data, "k")) {
			this.selected = Math.max(0, this.selected - 1);
		} else if (matchesKey(data, "down") || matchesKey(data, "j")) {
			this.selected = Math.min(rows.length - 1, this.selected + 1);
		} else if (matchesKey(data, "home") || matchesKey(data, "g")) {
			this.selected = 0;
		} else if (matchesKey(data, "end") || matchesKey(data, "shift+g")) {
			this.selected = Math.max(0, rows.length - 1);
		} else if (matchesKey(data, "a")) {
			this.done({ kind: "add", ...this.view() });
			return;
		} else if (!task) {
			// The remaining keys act on the selected todo.
		} else if (matchesKey(data, "space") || matchesKey(data, "enter")) {
			const next = isOpen(task) ? "closed" : "open";
			this.apply((ledger) => setStatus(ledger, task.id, next));
		} else if (matchesKey(data, "x")) {
			this.apply((ledger) => deleteTask(ledger, task.id));
		} else if (matchesKey(data, "o")) {
			this.done({ kind: "add", parentId: task.id, ...this.view() });
			return;
		}
		this.render_();
	}

	render(width: number): string[] {
		const th = this.theme;
		const rows = this.rows();
		const lines = ["", truncateToWidth(th.fg("accent", th.bold(" Todos")), width), ""];
		if (rows.length === 0) lines.push(th.fg("dim", "  No todos."));
		rows.forEach(({ task, depth }, index) => {
			const color = isOpen(task) ? "text" : "dim";
			const cursor = index === this.selected ? th.fg("accent", "> ") : "  ";
			lines.push(truncateToWidth(cursor + th.fg(color, formatTask(task, depth)), width));
		});
		lines.push("");
		if (this.message) lines.push(truncateToWidth(th.fg("error", `  ${this.message}`), width));
		lines.push(truncateToWidth(th.fg("dim", "  up/down move  space close/reopen"), width));
		lines.push(truncateToWidth(th.fg("dim", "  a add  o subtodo  x delete"), width));
		lines.push(truncateToWidth(th.fg("dim", "  alt+t / esc close"), width));
		return lines;
	}

	invalidate(): void {}
}

export default function (pi: ExtensionAPI) {
	let ledger = emptyLedger();
	// Continuation state for the current agent activity.
	let nudges = 0;
	let nudgedTasks: string | undefined;
	let toolCalled = false;

	function resetLoop() {
		nudges = 0;
		nudgedTasks = undefined;
		toolCalled = false;
	}

	function updateStatus(ctx: ExtensionContext) {
		const total = ledger.tasks.length;
		const done = ledger.tasks.filter((task) => !isOpen(task)).length;
		ctx.ui.setStatus("todos", total > 0 ? `todos ${done}/${total}` : undefined);
	}

	/** Apply a change to a copy and save a snapshot only when it succeeds. */
	function change(ctx: ExtensionContext, mutate: (next: Ledger) => void) {
		const next = structuredClone(ledger);
		mutate(next);
		ledger = next;
		pi.appendEntry(STATE_TYPE, structuredClone(ledger));
		updateStatus(ctx);
	}

	function restore(ctx: ExtensionContext) {
		resetLoop();
		ledger = emptyLedger();
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type === "custom" && entry.customType === STATE_TYPE && isLedger(entry.data)) {
				ledger = structuredClone(entry.data);
			}
		}
		updateStatus(ctx);
	}

	function result(summary = "") {
		const listing = formatLedger(ledger);
		const total = ledger.tasks.length;
		const open = ledger.tasks.filter(isOpen).length;
		return {
			content: [{ type: "text" as const, text: summary ? `${summary}\n\n${listing}` : listing }],
			details: { summary: summary || `${total} todo${total === 1 ? "" : "s"}, ${open} open` },
		};
	}

	function renderResult(toolResult: AgentToolResult<{ summary: string }>, { expanded }: { expanded: boolean }, theme: Theme, context: { isError: boolean }) {
		const text = toolResult.content.find((item) => item.type === "text");
		const full = text?.type === "text" ? text.text : "";
		const summary = toolResult.details?.summary ?? full.split("\n")[0] ?? "";
		return new Text(expanded ? full : theme.fg(context.isError ? "error" : "muted", summary), 0, 0);
	}

	const promptGuidelines = [
		"Before adding todos, parse the user's message into actionable work. Add clear todo titles and useful subtodos. Do not create todos for chat or questions with no work.",
		"Update todos as work progresses. A subagent result alone does not close a todo. " +
			"Close todos only when the work is done. Delete todos that are dropped or replaced, and add new todos for replacement work. " +
			"Todos have no priority; do not create a Tatr issue just to prioritize a todo.",
		"Open todos keep the run going. If you need something that will wake you later, or you cannot make progress, end your turn without tool calls. Do not close unfinished todos to stop.",
	];
	const shared = {
		executionMode: "sequential" as const,
		renderResult,
	};

	pi.registerTool({
		...shared,
		promptSnippet: "Track work in session todos, separate from Tatr repository issues",
		promptGuidelines,
		name: "todo_list",
		label: "Todo list",
		description: "List session todos and recorded user messages. These are not Tatr repository issues.",
		parameters: Type.Object({}),
		async execute() { return result(); },
		renderCall(_args, theme) { return new Text(theme.fg("toolTitle", "todo_list"), 0, 0); },
	});

	pi.registerTool({
		...shared,
		name: "todo_add",
		label: "Add todo",
		description: "Add one top-level session todo for actionable work. Use todo_add_subtodo for a child. User messages are recorded separately as P<n>.",
		parameters: Type.Object({ title: Type.String({ description: "New todo title" }) }),
		async execute(_id, { title }, _signal, _onUpdate, ctx) {
			let summary = "";
			change(ctx, (next) => { summary = `Added #${addTask(next, title).id}.`; });
			return result(summary);
		},
		renderCall({ title }, theme) { return new Text(theme.fg("toolTitle", `todo_add ${JSON.stringify(clip(title.replace(/\s+/g, " "), 72))}`), 0, 0); },
	});

	pi.registerTool({
		...shared,
		name: "todo_add_subtodo",
		label: "Add subtodo",
		description: "Add one child of an existing open session todo. parentId must be an existing todo id, not 0. Use todo_list to find ids.",
		parameters: Type.Object({
			parentId: Type.Integer({ minimum: 1, description: "Existing open parent todo id (at least 1)" }),
			title: Type.String({ description: "New subtodo title" }),
		}),
		async execute(_id, { parentId, title }, _signal, _onUpdate, ctx) {
			let summary = "";
			change(ctx, (next) => { summary = `Added #${addTask(next, title, parentId).id}.`; });
			return result(summary);
		},
		renderCall({ parentId, title }, theme) { return new Text(theme.fg("toolTitle", `todo_add_subtodo under #${parentId} ${JSON.stringify(clip(title.replace(/\s+/g, " "), 72))}`), 0, 0); },
	});

	pi.registerTool({
		...shared,
		name: "todo_update",
		label: "Update todo",
		description: "Set a session todo to open or closed. A parent cannot close while its subtodos are open. Close only when the work is done.",
		parameters: Type.Object({
			id: Type.Integer({ minimum: 1, description: "Existing todo id" }),
			status: StringEnum(["open", "closed"] as const),
		}),
		async execute(_callId, { id, status }, _signal, _onUpdate, ctx) {
			change(ctx, (next) => { setStatus(next, id, status); });
			return result(`Todo #${id} is ${status}.`);
		},
		renderCall({ id, status }, theme) { return new Text(theme.fg("toolTitle", `todo_update #${id} ${status}`), 0, 0); },
	});

	pi.registerTool({
		...shared,
		name: "todo_delete",
		label: "Delete todo",
		description: "Remove a session todo and its subtodos for good. To replace one, delete it and add a new todo.",
		parameters: Type.Object({ id: Type.Integer({ minimum: 1, description: "Existing todo id" }) }),
		async execute(_callId, { id }, _signal, _onUpdate, ctx) {
			let summary = "";
			change(ctx, (next) => { summary = `Deleted ${deleteTask(next, id).map((task) => `#${task.id}`).join(", ")}.`; });
			return result(summary);
		},
		renderCall({ id }, theme) { return new Text(theme.fg("toolTitle", `todo_delete #${id}`), 0, 0); },
	});

	async function showTodos(ctx: ExtensionContext) {
		if (ctx.mode !== "tui") {
			ctx.ui.notify(formatLedger(ledger), "info");
			return;
		}
		let view: ListView = { selected: 0 };
		for (;;) {
			const action = await ctx.ui.custom<ListAction>((tui, theme, _keybindings, done) =>
				new TaskListComponent(
					() => ledger,
					theme,
					view,
					(mutate) => {
						try {
							change(ctx, mutate);
							return undefined;
						} catch (error) {
							return error instanceof Error ? error.message : String(error);
						}
					},
					() => tui.requestRender(),
					done,
				),
			);
			if (action.kind === "close") return;
			view = { selected: action.selected };
			try {
				const label = action.parentId === undefined ? "New todo" : `New subtodo of #${action.parentId}`;
				const title = await ctx.ui.input(label);
				if (title?.trim()) change(ctx, (next) => addTask(next, title, action.parentId));
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			}
		}
	}

	pi.registerCommand("todos", {
		description: "Show and edit session todos for this branch",
		handler: async (_args, ctx) => showTodos(ctx),
	});
	pi.registerShortcut(Key.alt("t"), {
		description: "Open the session todo checklist",
		handler: showTodos,
	});

	pi.on("session_start", async (_event, ctx) => restore(ctx));
	pi.on("session_tree", async (_event, ctx) => restore(ctx));

	// Agents often end a turn with text while work remains. Open todos mean the
	// user wants more, so continue at settlement. A queued message (for example
	// a wake from a finished job) already continues the run. Each new activity,
	// whatever started it, gets a fresh nudge budget.
	pi.on("tool_call", async () => {
		toolCalled = true;
	});
	pi.on("agent_settled", async () => resetLoop());
	pi.on("agent_before_settle", async (event, ctx) => {
		if (event.outcome !== "completed" || event.continue || event.context.pendingMessages.length > 0) return;
		const open = ledger.tasks.filter(isOpen);
		if (open.length === 0) return;
		// No tool calls after a nudge: the agent is waiting or cannot progress.
		if (nudges > 0 && !toolCalled) return;
		const tasks = JSON.stringify(ledger.tasks);
		if (tasks !== nudgedTasks) nudges = 0;
		if (nudges >= MAX_STALLED_NUDGES) {
			ctx.ui.notify(`Todos loop stopped: no todo changed after ${nudges} nudges`, "warning");
			return;
		}
		nudges++;
		nudgedTasks = tasks;
		toolCalled = false;
		const content =
			"Open todos remain. Continue with the next open todo and close each todo when its work is done. " +
			"If you need something that will wake you later, or you cannot make progress, end your turn without tool calls.\n" +
			open.map((task) => `#${task.id} ${task.title}`).join("\n");
		return {
			entries: [...event.entries, { type: "custom_message" as const, customType: CONTINUE_TYPE, content, display: true }],
			continue: true,
		};
	});

	// Record messages, not todos: only the agent can decide what work a message
	// requires. Extension commands never reach input; messages from other
	// extensions (for example Telegram) do. Subagent wakes are custom messages
	// and do not create prompts.
	pi.on("input", async (event, ctx) => {
		if (event.text.trim()) {
			change(ctx, (next) => {
				addPrompt(next, event.text, event.source);
			});
		}
		return { action: "continue" };
	});
}
