import { StringEnum, Type } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, Text, truncateToWidth } from "@earendil-works/pi-tui";

export type TaskStatus = "pending" | "in_progress" | "completed" | "blocked" | "superseded";

export type Task = {
	id: number;
	title: string;
	status: TaskStatus;
	parentId?: number;
	/** User prompt that this task addresses, when supplied by the agent. */
	promptId?: number;
	/** Blocked reason or supersession reason. */
	note?: string;
	/** Task that replaces this superseded task. */
	replacedBy?: number;
	/** Set while archived: the task whose archive action hid this task. */
	archivedWith?: number;
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

const STATE_TYPE = "tasks-ledger";
const REMINDER_TYPE = "tasks-reminder";
const MAX_PROMPT_CHARS = 1000;
const MAX_TITLE_CHARS = 120;
const STATUS_MARK: Record<TaskStatus, string> = {
	pending: "[ ]",
	in_progress: "[>]",
	completed: "[x]",
	blocked: "[!]",
	superseded: "[~]",
};

export function emptyLedger(): Ledger {
	return { version: 1, nextTaskId: 1, nextPromptId: 1, prompts: [], tasks: [] };
}

function isOpen(task: Task): boolean {
	return task.status === "pending" || task.status === "in_progress";
}

/** Tasks that still need a decision: open or blocked. */
function isUnresolved(task: Task): boolean {
	return isOpen(task) || task.status === "blocked";
}

function isArchived(task: Task): boolean {
	return task.archivedWith !== undefined;
}

function findTask(ledger: Ledger, id: number): Task {
	const task = ledger.tasks.find((candidate) => candidate.id === id);
	if (!task) throw new Error(`task #${id} does not exist`);
	return task;
}

/** Find a task that is not archived. Archived tasks do not change until restored. */
function findActiveTask(ledger: Ledger, id: number): Task {
	const task = findTask(ledger, id);
	if (isArchived(task)) throw new Error(`task #${id} is archived`);
	return task;
}

/** A task and all of its subtasks. */
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

/** Set completed ancestors of an unresolved task back to pending. */
function reopenAncestors(ledger: Ledger, task: Task) {
	if (!isUnresolved(task)) return;
	let parent = ledger.tasks.find((candidate) => candidate.id === task.parentId);
	while (parent) {
		if (parent.status === "completed") parent.status = "pending";
		parent = ledger.tasks.find((candidate) => candidate.id === parent?.parentId);
	}
}

export function addTask(ledger: Ledger, title: string, parentId?: number, promptId?: number): Task {
	if (parentId !== undefined) {
		const parent = findActiveTask(ledger, parentId);
		if (!isUnresolved(parent)) throw new Error(`parent task #${parentId} is ${parent.status}`);
	}
	if (promptId !== undefined && !ledger.prompts.some((prompt) => prompt.id === promptId)) {
		throw new Error(`prompt P${promptId} does not exist`);
	}
	const task = createTask(ledger, title, parentId);
	if (promptId !== undefined) task.promptId = promptId;
	return task;
}

function createTask(ledger: Ledger, title: string, parentId?: number): Task {
	const trimmed = title.trim();
	if (!trimmed) throw new Error("task title must not be empty");
	const task: Task = { id: ledger.nextTaskId++, title: trimmed, status: "pending" };
	if (parentId !== undefined) task.parentId = parentId;
	ledger.tasks.push(task);
	return task;
}

export function setStatus(ledger: Ledger, id: number, status: Exclude<TaskStatus, "superseded">, note?: string): Task {
	const task = findActiveTask(ledger, id);
	if (task.status === "superseded") throw new Error(`task #${id} is superseded by #${task.replacedBy}`);
	if (status === "completed") {
		const open = ledger.tasks.filter((child) => child.parentId === id && isUnresolved(child) && !isArchived(child));
		if (open.length > 0) {
			throw new Error(`task #${id} has unresolved subtasks: ${open.map((child) => `#${child.id}`).join(", ")}`);
		}
	}
	if (status === "blocked" && !note?.trim()) throw new Error("a blocked task needs a reason in note");
	task.status = status;
	if (status === "blocked" && note) task.note = note.trim();
	else delete task.note;
	reopenAncestors(ledger, task);
	return task;
}

/** Mark a task superseded and link it to an existing or new replacement task. */
export function supersede(
	ledger: Ledger,
	id: number,
	replacement: { id: number } | { title: string },
	note?: string,
): Task {
	const task = findActiveTask(ledger, id);
	if (task.status === "superseded") throw new Error(`task #${id} is already superseded by #${task.replacedBy}`);
	let target: Task;
	if ("id" in replacement) {
		target = findActiveTask(ledger, replacement.id);
		if (target.id === id || isDescendant(ledger, target.id, id)) {
			throw new Error(`task #${target.id} cannot replace #${id} because it is the same task or its subtask`);
		}
		if (target.status === "superseded") throw new Error(`replacement task #${target.id} is superseded`);
	} else {
		target = createTask(ledger, replacement.title, task.parentId);
	}
	task.status = "superseded";
	task.replacedBy = target.id;
	if (note?.trim()) task.note = note.trim();
	else delete task.note;
	// Unfinished subtasks now belong to the replacement. Archived subtasks move too and stay archived.
	for (const child of ledger.tasks) {
		if (child.parentId === id && isUnresolved(child)) {
			child.parentId = target.id;
			if (!isArchived(child)) reopenAncestors(ledger, child);
		}
	}
	reopenAncestors(ledger, target);
	return target;
}

/** Hide a task and its subtasks. Statuses, links, and prompts do not change. */
export function archive(ledger: Ledger, id: number): Task[] {
	findActiveTask(ledger, id);
	// Subtasks archived before keep their own archive group.
	const archived = subtree(ledger, id).filter((task) => !isArchived(task));
	for (const task of archived) task.archivedWith = id;
	return archived;
}

/** Show an archived task again, with the subtasks archived together with it. */
export function restoreArchived(ledger: Ledger, id: number): Task[] {
	const task = findTask(ledger, id);
	if (!isArchived(task)) throw new Error(`task #${id} is not archived`);
	if (task.archivedWith !== id) throw new Error(`task #${id} was archived with #${task.archivedWith}; restore #${task.archivedWith}`);
	const parent = ledger.tasks.find((candidate) => candidate.id === task.parentId);
	if (parent && isArchived(parent)) throw new Error(`parent task #${parent.id} is archived; restore it first`);
	const restored = subtree(ledger, id).filter((candidate) => candidate.archivedWith === id);
	for (const candidate of restored) delete candidate.archivedWith;
	// A restored unresolved subtask reopens a parent completed in the meantime.
	for (const candidate of restored) reopenAncestors(ledger, candidate);
	return restored;
}

/** Tasks in tree order with their depth. Archived tasks show only on request. */
export function treeRows(ledger: Ledger, showArchived = false): { task: Task; depth: number }[] {
	const rows: { task: Task; depth: number }[] = [];
	const tasks = showArchived ? ledger.tasks : ledger.tasks.filter((task) => !isArchived(task));
	const ids = new Set(tasks.map((task) => task.id));
	const visit = (parentId: number | undefined, depth: number) => {
		for (const task of tasks) {
			const parent = task.parentId !== undefined && ids.has(task.parentId) ? task.parentId : undefined;
			if (parent !== parentId) continue;
			rows.push({ task, depth });
			visit(task.id, depth + 1);
		}
	};
	visit(undefined, 0);
	return rows;
}

export function formatTask(task: Task, depth = 0): string {
	const request = task.promptId !== undefined ? `P${task.promptId}: ` : "";
	let line = `${"  ".repeat(depth)}${STATUS_MARK[task.status]} #${task.id} ${request}${task.title}`;
	if (task.status === "superseded") line += ` (superseded by #${task.replacedBy})`;
	if (task.note) line += ` - ${task.note}`;
	if (isArchived(task)) line += " (archived)";
	return line;
}

export function formatLedger(ledger: Ledger, showArchived = false): string {
	const lines: string[] = [];
	if (ledger.prompts.length > 0) {
		lines.push("User requests:");
		for (const prompt of ledger.prompts) lines.push(`  P${prompt.id}: ${prompt.text.replace(/\s+/g, " ")}`);
	}
	const rows = treeRows(ledger, showArchived);
	lines.push(rows.length > 0 ? "Tasks:" : "No tasks.");
	for (const { task, depth } of rows) lines.push(`  ${formatTask(task, depth)}`);
	const hidden = ledger.tasks.length - rows.length;
	if (hidden > 0) lines.push(`${hidden} archived task${hidden === 1 ? "" : "s"} hidden.`);
	return lines.join("\n");
}

function openTaskLines(ledger: Ledger): string[] {
	return treeRows(ledger)
		.filter(({ task }) => isOpen(task))
		.map(({ task, depth }) => formatTask(task, depth));
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

/** List position and filter that stay the same while a prompt dialog is open. */
type ListView = { selected: number; showArchived: boolean };

type ListAction =
	| { kind: "close" }
	| ({ kind: "add"; parentId?: number } & ListView)
	| ({ kind: "block"; id: number } & ListView)
	| ({ kind: "supersede"; id: number } & ListView);

/** Keyboard-driven view of the ledger for /todos. */
class TaskListComponent {
	private readonly ledger: () => Ledger;
	private readonly theme: Theme;
	private readonly change: (mutate: (ledger: Ledger) => void) => string | undefined;
	private readonly render_: () => void;
	private readonly done: (action: ListAction) => void;
	private selected: number;
	private showArchived: boolean;
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
		this.showArchived = view.showArchived;
		this.change = change;
		this.render_ = requestRender;
		this.done = done;
	}

	private rows() {
		return treeRows(this.ledger(), this.showArchived);
	}

	private view(): ListView {
		return { selected: this.selected, showArchived: this.showArchived };
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
		} else if (matchesKey(data, "v")) {
			this.showArchived = !this.showArchived;
			this.clamp();
		} else if (!task) {
			// The remaining keys act on the selected task.
		} else if (matchesKey(data, "space") || matchesKey(data, "enter")) {
			const next = task.status === "completed" ? "pending" : "completed";
			this.apply((ledger) => setStatus(ledger, task.id, next));
		} else if (matchesKey(data, "i")) {
			this.apply((ledger) => setStatus(ledger, task.id, "in_progress"));
		} else if (matchesKey(data, "p")) {
			this.apply((ledger) => setStatus(ledger, task.id, "pending"));
		} else if (matchesKey(data, "x")) {
			this.apply((ledger) => archive(ledger, task.id));
		} else if (matchesKey(data, "u")) {
			this.apply((ledger) => restoreArchived(ledger, task.id));
		} else if (matchesKey(data, "n")) {
			this.done({ kind: "add", parentId: task.id, ...this.view() });
			return;
		} else if (matchesKey(data, "b")) {
			this.done({ kind: "block", id: task.id, ...this.view() });
			return;
		} else if (matchesKey(data, "r")) {
			this.done({ kind: "supersede", id: task.id, ...this.view() });
			return;
		}
		this.render_();
	}

	render(width: number): string[] {
		const th = this.theme;
		const rows = this.rows();
		const title = this.showArchived ? " Tasks (with archived)" : " Tasks";
		const lines = ["", truncateToWidth(th.fg("accent", th.bold(title)), width), ""];
		if (rows.length === 0) lines.push(th.fg("dim", "  No tasks."));
		rows.forEach(({ task, depth }, index) => {
			const color =
				isArchived(task) || task.status === "completed" || task.status === "superseded"
					? "dim"
					: task.status === "blocked"
						? "warning"
						: "text";
			const cursor = index === this.selected ? th.fg("accent", "> ") : "  ";
			lines.push(truncateToWidth(cursor + th.fg(color, formatTask(task, depth)), width));
		});
		lines.push("");
		if (this.message) lines.push(truncateToWidth(th.fg("error", `  ${this.message}`), width));
		lines.push(truncateToWidth(th.fg("dim", "  up/down move  space done  x archive  u restore  v show archived"), width));
		lines.push(truncateToWidth(th.fg("dim", "  i doing  p pending  b blocked  r supersede  a add  n subtask"), width));
		lines.push(truncateToWidth(th.fg("dim", "  alt+t / esc close"), width));
		return lines;
	}

	invalidate(): void {}
}

export default function (pi: ExtensionAPI) {
	let ledger = emptyLedger();
	function updateStatus(ctx: ExtensionContext) {
		const active = ledger.tasks.filter((task) => !isArchived(task));
		const total = active.filter((task) => task.status !== "superseded").length;
		const done = active.filter((task) => task.status === "completed").length;
		ctx.ui.setStatus("tasks", total > 0 ? `tasks ${done}/${total}` : undefined);
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
		ledger = emptyLedger();
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type === "custom" && entry.customType === STATE_TYPE && isLedger(entry.data)) {
				ledger = structuredClone(entry.data);
			}
		}
		updateStatus(ctx);
	}

	pi.registerTool({
		name: "tasks",
		label: "Tasks",
		description:
			"Manage the session task ledger. User messages are recorded as P<n> without creating tasks. " +
			"Parse each message and add tasks only for actionable work. " +
			"Actions: list; add (title or titles, optional parentId for subtasks and promptId to link to a message); " +
			"update (id, status: pending|in_progress|completed|blocked, note required for blocked); " +
			"supersede (id, replacementId or title for a new replacement, optional note); " +
			"archive (id): hide a task and its subtasks without changing their status, only when the user asks; " +
			"restore (id): show an archived task again with the subtasks archived with it. " +
			"list hides archived tasks unless archived is true. " +
			"A parent cannot be completed while its subtasks are unresolved.",
		promptSnippet: "Track multi-step work and user requests in a task ledger",
		promptGuidelines: [
			"Before adding tasks, parse the user's message into actionable work. Add clear task titles and useful subtasks. Do not create tasks for chat or questions with no work. Optionally link tasks to a recorded P<n> using promptId.",
			"Do not stop while tasks are pending or in_progress. Mark each task completed, blocked with a reason, or superseded with a linked replacement.",
		],
		parameters: Type.Object({
			action: StringEnum(["list", "add", "update", "supersede", "archive", "restore"] as const),
			id: Type.Optional(Type.Integer({ description: "Task id for update, supersede, archive, or restore" })),
			title: Type.Optional(Type.String({ description: "New task title for add, or replacement title for supersede" })),
			titles: Type.Optional(Type.Array(Type.String(), { description: "Several new task titles for add" })),
			parentId: Type.Optional(Type.Integer({ description: "Parent task id for new subtasks" })),
			promptId: Type.Optional(Type.Integer({ description: "Recorded user message id to link to a new task" })),
			status: Type.Optional(StringEnum(["pending", "in_progress", "completed", "blocked"] as const)),
			note: Type.Optional(Type.String({ description: "Blocked reason or supersession reason" })),
			replacementId: Type.Optional(Type.Integer({ description: "Existing task that replaces the superseded task" })),
			archived: Type.Optional(Type.Boolean({ description: "Include archived tasks in the result" })),
		}),
		executionMode: "sequential",

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			let summary = "";
			switch (params.action) {
				case "list":
					break;
				case "add": {
					const titles = [...(params.titles ?? []), ...(params.title ? [params.title] : [])];
					if (titles.length === 0) throw new Error("add needs title or titles");
					change(ctx, (next) => {
						const added = titles.map((title) => addTask(next, title, params.parentId, params.promptId));
						summary = `Added ${added.map((task) => `#${task.id}`).join(", ")}.`;
					});
					break;
				}
				case "update": {
					if (params.id === undefined || params.status === undefined) throw new Error("update needs id and status");
					const { id, status } = params;
					change(ctx, (next) => {
						setStatus(next, id, status, params.note);
						summary = `Task #${id} is ${status}.`;
					});
					break;
				}
				case "supersede": {
					if (params.id === undefined) throw new Error("supersede needs id");
					if ((params.replacementId === undefined) === (params.title === undefined)) {
						throw new Error("supersede needs exactly one of replacementId or title");
					}
					const { id } = params;
					const replacement = params.replacementId !== undefined ? { id: params.replacementId } : { title: params.title ?? "" };
					change(ctx, (next) => {
						const target = supersede(next, id, replacement, params.note);
						summary = `Task #${id} is superseded by #${target.id}.`;
					});
					break;
				}
				case "archive":
				case "restore": {
					if (params.id === undefined) throw new Error(`${params.action} needs id`);
					const { id, action } = params;
					change(ctx, (next) => {
						const tasks = action === "archive" ? archive(next, id) : restoreArchived(next, id);
						const verb = action === "archive" ? "Archived" : "Restored";
						summary = `${verb} ${tasks.map((task) => `#${task.id}`).join(", ")}.`;
					});
					break;
				}
			}
			const listing = formatLedger(ledger, params.archived === true);
			const text = summary ? `${summary}\n\n${listing}` : listing;
			const visible = ledger.tasks.filter((task) => params.archived === true || !isArchived(task));
			const open = visible.filter(isOpen).length;
			return {
				content: [{ type: "text" as const, text }],
				details: { summary: summary || `${visible.length} task${visible.length === 1 ? "" : "s"}, ${open} open` },
			};
		},

		renderCall(args, theme) {
			let command = `tasks ${args.action}`;
			if (args.id !== undefined) command += ` #${args.id}`;
			if (args.status) command += ` ${args.status}`;
			if (args.parentId !== undefined) command += ` under #${args.parentId}`;
			if (args.promptId !== undefined) command += ` for P${args.promptId}`;
			if (args.replacementId !== undefined) command += ` with #${args.replacementId}`;
			if (args.title) command += ` ${JSON.stringify(clip(args.title.replace(/\s+/g, " "), 72))}`;
			if (args.titles) command += ` ${args.titles.length} titles`;
			if (args.note) command += ` note=${JSON.stringify(clip(args.note.replace(/\s+/g, " "), 72))}`;
			if (args.archived) command += " including archived";
			return new Text(theme.fg("toolTitle", command), 0, 0);
		},

		renderResult(result, { expanded }, theme, context) {
			const text = result.content.find((item) => item.type === "text");
			const full = text?.type === "text" ? text.text : "";
			const details = result.details as { summary?: string } | undefined;
			const summary = details?.summary ?? full.split("\n")[0] ?? "";
			return new Text(expanded ? full : theme.fg(context.isError ? "error" : "muted", summary), 0, 0);
		},
	});

	async function showTodos(ctx: ExtensionContext) {
		if (ctx.mode !== "tui") {
			ctx.ui.notify(formatLedger(ledger), "info");
			return;
		}
		let view: ListView = { selected: 0, showArchived: false };
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
			view = { selected: action.selected, showArchived: action.showArchived };
			try {
				if (action.kind === "add") {
					const label = action.parentId === undefined ? "New task" : `New subtask of #${action.parentId}`;
					const title = await ctx.ui.input(label);
					if (title?.trim()) change(ctx, (next) => addTask(next, title, action.parentId));
				} else if (action.kind === "block") {
					const reason = await ctx.ui.input(`Why is #${action.id} blocked?`);
					if (reason?.trim()) change(ctx, (next) => setStatus(next, action.id, "blocked", reason));
				} else {
					const title = await ctx.ui.input(`Replacement for #${action.id}`);
					if (title?.trim()) change(ctx, (next) => supersede(next, action.id, { title }));
				}
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			}
		}
	}

	pi.registerCommand("todos", {
		description: "Show and edit the task ledger for this branch",
		handler: async (_args, ctx) => showTodos(ctx),
	});
	pi.registerShortcut(Key.alt("t"), {
		description: "Open the task checklist",
		handler: showTodos,
	});

	pi.on("session_start", async (_event, ctx) => restore(ctx));
	pi.on("session_tree", async (_event, ctx) => restore(ctx));

	// Record messages, not tasks: only the agent can decide what work a message
	// requires. Extension commands never reach input; messages from other
	// extensions (for example Telegram) do. Reminders and subagent wakes are
	// custom messages and do not create prompts.
	pi.on("input", async (event, ctx) => {
		if (event.text.trim()) {
			change(ctx, (next) => {
				addPrompt(next, event.text, event.source);
			});
		}
		return { action: "continue" };
	});

	pi.on("agent_before_settle", async (event, ctx) => {
		if (event.outcome !== "completed") return;
		// Another handler or a queued user message already continues the run.
		if (event.continue || event.context.pendingMessages.length > 0) return;
		const open = openTaskLines(ledger);
		if (open.length === 0) return;
		// event.context predates the reminder draft, so its canContinue is false
		// after a final assistant message. The reminder makes the context continuable.
		const content =
			`The task ledger still has open tasks. Continue the work, or update each task with the tasks tool: ` +
			`completed, blocked with a reason, or superseded with a replacement.\n${open.join("\n")}`;
		return {
			entries: [...event.entries, { type: "custom_message", customType: REMINDER_TYPE, content, display: true }],
			continue: true,
		};
	});
}
