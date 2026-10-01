import assert from "node:assert/strict";
import { test } from "node:test";
import extension from "./grilling.ts";

function fakePi(branch: { type: string; customType?: string; data?: unknown }[] = []) {
	const handlers = new Map<string, (event: any, ctx: any) => any>();
	const commands = new Map<string, (args: string, ctx: any) => Promise<void>>();
	let record: (id: string, params: { question: string; choice: string; reason: string }) => Promise<any>;
	const notices: string[] = [];
	const statuses: (string | undefined)[] = [];
	const ctx = {
		sessionManager: { getBranch: () => branch },
		ui: { notify: (message: string) => notices.push(message), setStatus: (_key: string, value: string | undefined) => statuses.push(value) },
	};
	const pi = {
		on: (name: string, handler: any) => handlers.set(name, handler),
		registerCommand: (name: string, command: any) => commands.set(name, command.handler),
		registerTool: (tool: any) => { record = tool.execute; },
		appendEntry: (customType: string, data: unknown) => branch.push({ type: "custom", customType, data: structuredClone(data) }),
	};
	extension(pi as never);
	return {
		branch, notices, statuses,
		emit: (name: string, event: any = {}) => handlers.get(name)! (event, ctx),
		command: (name: string, args = "") => commands.get(name)!(args, ctx),
		record: (params: { question: string; choice: string; reason: string }) => record("id", params),
	};
}

test("off by default: blocks ask_user and records reviewable choices", async () => {
	const pi = fakePi();
	pi.emit("session_start");
	const event = { systemPromptOptions: { sections: {} as Record<string, string> } };
	pi.emit("before_agent_start", event);
	assert.match(event.systemPromptOptions.sections.grilling, /subagent asks/);
	assert.equal(pi.emit("tool_call", { toolName: "ask_user" }).block, true);
	assert.equal(pi.emit("tool_call", { toolName: "read" }), undefined);
	await pi.record({ question: "Which parser?", choice: "existing", reason: "smallest change" });
	await pi.command("decisions");
	assert.match(pi.notices.at(-1)!, /Choice: existing/);
	const resumed = fakePi([...pi.branch]);
	resumed.emit("session_start");
	await resumed.command("decisions");
	assert.match(resumed.notices.at(-1)!, /Choice: existing/);
});

test("toggle restores per-branch mode and decisions", async () => {
	const pi = fakePi();
	pi.emit("session_start");
	await pi.command("grill", "on");
	assert.equal(pi.emit("tool_call", { toolName: "ask_user" }), undefined);
	const event = { systemPromptOptions: { sections: {} as Record<string, string> } };
	pi.emit("before_agent_start", event);
	assert.match(event.systemPromptOptions.sections.grilling, /Plan and discuss/);
	const fork = fakePi([...pi.branch]);
	fork.emit("session_start");
	assert.equal(fork.emit("tool_call", { toolName: "ask_user" }), undefined);
	await fork.command("grill", "off");
	assert.equal(fork.emit("tool_call", { toolName: "ask_user" }).block, true);
	pi.emit("session_tree");
	assert.equal(pi.emit("tool_call", { toolName: "ask_user" }), undefined);
	const fresh = fakePi();
	fresh.emit("session_start");
	assert.equal(fresh.emit("tool_call", { toolName: "ask_user" }).block, true);
});
