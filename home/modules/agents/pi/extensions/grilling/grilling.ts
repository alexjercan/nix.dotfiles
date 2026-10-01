import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const STATE = "grilling-state";
type Decision = { question: string; choice: string; reason: string };
type State = { enabled: boolean; decisions: Decision[] };

export default function grilling(pi: ExtensionAPI) {
	let state: State = { enabled: false, decisions: [] };
	function save() {
		pi.appendEntry(STATE, structuredClone(state));
	}
	function restore(ctx: { sessionManager: { getBranch(): readonly { type: string; customType?: string; data?: unknown }[] }; ui: { setStatus(key: string, value: string | undefined): void } }) {
		state = { enabled: false, decisions: [] };
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type !== "custom" || entry.customType !== STATE) continue;
			const data = entry.data as Partial<State> | undefined;
			if (typeof data?.enabled === "boolean" && Array.isArray(data.decisions)) state = structuredClone(data as State);
		}
		ctx.ui.setStatus("grilling", state.enabled ? "grilling ON" : undefined);
	}

	pi.on("session_start", (_event, ctx) => restore(ctx));
	pi.on("session_tree", (_event, ctx) => restore(ctx));
	pi.registerCommand("grill", {
		description: "Toggle planning and questions: /grill [on|off|status]",
		handler: async (args, ctx) => {
			const action = args.trim().toLowerCase();
			if (action === "status") {
				ctx.ui.notify(`Grilling is ${state.enabled ? "on" : "off"}. ${state.decisions.length} recorded decisions.`, "info");
				return;
			}
			if (action && action !== "on" && action !== "off") {
				ctx.ui.notify("Usage: /grill [on|off|status]", "warning");
				return;
			}
			const next = action === "on" ? true : action === "off" ? false : !state.enabled;
			if (next !== state.enabled) {
				state.enabled = next;
				save();
			}
			ctx.ui.setStatus("grilling", state.enabled ? "grilling ON" : undefined);
			ctx.ui.notify(`Grilling ${state.enabled ? "on: plan and ask questions" : "off: decide and continue"}.`, "info");
		},
	});
	pi.registerCommand("decisions", {
		description: "Review autonomous decisions in this session branch",
		handler: async (_args, ctx) => ctx.ui.notify(
			state.decisions.length
				? state.decisions.map((d, i) => `${i + 1}. ${d.question}\n   Choice: ${d.choice}\n   Reason: ${d.reason}`).join("\n")
				: "No autonomous decisions recorded.",
			"info",
		),
	});
	pi.registerTool({
		name: "record_decision",
		label: "Record decision",
		description: "Record a choice you made without asking the user. Use before acting on a consequential assumption outside grilling mode. Review with /decisions.",
		parameters: Type.Object({
			question: Type.String({ description: "Decision you made" }),
			choice: Type.String({ description: "Chosen default" }),
			reason: Type.String({ description: "Why this default was chosen" }),
		}),
		async execute(_id, params) {
			if (!state.enabled) {
				state.decisions.push({ question: params.question, choice: params.choice, reason: params.reason });
				save();
			}
			return { content: [{ type: "text", text: state.enabled ? "Grilling is on; no autonomous decision recorded." : "Decision recorded. Continue without waiting for user input." }], details: undefined };
		},
	});
	pi.on("before_agent_start", (event) => {
		event.systemPromptOptions.sections.grilling = state.enabled
			? "GRILLING MODE ON: Plan and discuss before implementing. Ask the user focused questions with ask_user when a decision needs their input."
			: "GRILLING MODE OFF: Do not ask the user questions or pause for input. Choose a sensible default and continue, including for high-risk decisions. Record consequential assumptions using record_decision so the user can review them with /decisions. If a subagent asks you a question, choose the answer yourself, record consequential choices, and reply to the subagent. This rule overrides instructions to ask for approval or block on missing user input.";
	});
	pi.on("tool_call", (event) => {
		if (!state.enabled && event.toolName === "ask_user") {
			return { block: true, reason: "Grilling is off. Choose a default, record consequential decisions with record_decision, and continue. Do not ask the user or stop." };
		}
	});
}
