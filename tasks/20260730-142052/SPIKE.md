# Spike: Redesign the flow skills for concise progressive disclosure

- DATE: 20260730-142052
- STATUS: RECOMMENDED
- TAGS: spike, skills, flow, context

## Question

Which ideas from `/home/alex/third-party/skills` should improve the local
flow-family skills, while preserving the stronger tatr, sprout, review, and
lessons lifecycle? A good answer must reduce context and user-facing prose,
add conditional parallel planning and executable prototypes, and remain
concrete enough to plan without changing the skills yet.

## Context

The local flow family is mature but prose-heavy. Its eight core `SKILL.md`
bodies contain 13,485 words before loading tatr, repository instructions,
task records, lessons, or code. `flow` alone is 3,225 body words, `plan` 2,301,
and `work` 2,400. Their descriptions add 591 always-visible words, and all
local skills are currently implicitly invocable.

Matt's selected planning and delivery bodies total 6,680 words, but the number
is not directly comparable: several commands are user-only, `implement` is
only 50 body words, and branch details are disclosed later. Matt's strongest
example is `prototype`: a 431-word dispatcher loads either `UI.md` or
`LOGIC.md`. His current checkout does not contain a broad catalog of page
templates. It contains artifact templates, provider-specific setup templates,
and UI/logic branches. The reusable idea is conditional templates, not a
ready-made page-type library.

Splitting files is not sufficient by itself. If one long-lived agent reads
every phase file, those tokens still accumulate. Real savings require:

1. Branch-only references that are never loaded on other branches.
2. Fresh phase contexts with small on-disk handoffs.
3. Short metadata and output contracts.
4. Tool enforcement replacing repeated prose.

## Comparison

| Area | Local flow family | Matt's skills | Better basis |
| --- | --- | --- | --- |
| End-to-end delivery | Explicit state, gate, worktree, review loop, retro, atomic land | Loose composition; `implement` is skeletal | Local |
| Task truth | Versioned tatr records and proof-bearing DoD | Tracker issues/specs, weaker execution state | Local |
| Isolation | Sprout per task plus guarded landing | Throwaway branches, no general worktree contract | Local |
| Review | Durable rounds, severity, responses, re-review, proof execution | Independent Standards and Spec passes | Local core, Matt's parallel lenses |
| Learning | RETRO plus counted LESSONS and promotion | No equivalent | Local |
| Context hierarchy | Mostly monolithic; repeated rules across phases | Strong branch disclosure and user/model invocation split | Matt |
| Discovery | Text-only spike, then plan | Research, grilling, prototype, wayfinder | Matt |
| Large planning | Epic support, mostly serial | Low-resolution map, frontier, fog, parallel research | Matt |
| Output discipline | Some short-report guidance and terminal status lines | Explicit subagent word caps in places; `to-spec` demands extensive output | Mixed |
| Conformance | `tatr check` and project checks | No comparable skill-suite gate | Local |

## What the local suite already does well

- It has a real transaction boundary: approved plan -> isolated worktree ->
  verified work -> review rounds -> retro -> guarded squash land.
- Task records survive context loss and make resume behavior deterministic.
- DoD items identify their proof, and work and review both execute it.
- Review is stronger than Matt's current version because findings have
  severity, ownership, responses, repeated verification, and one ship verdict.
- Lessons have a lifecycle. Recurrence is counted, promoted in the order
  tool -> template -> prose, and absorbed rules are meant to shrink skills.
- Sprout turns parallel implementation from a prompt convention into actual
  filesystem and branch isolation.

These are the foundation. Replacing them with Matt's tracker-first
`to-spec -> to-tickets -> implement` chain would be a regression.

## What to take from Matt

1. **Progressive disclosure by branch.** Keep the selector and invariants in
   `SKILL.md`; move UI, logic, bug, epic, landing, decision, and format detail
   behind explicit condition-and-file pointers.
2. **Low-resolution maps.** A large effort should load destination, decided
   facts, frontier, fog, and out-of-scope notes, not every child record.
3. **Design it twice.** For a load-bearing fork, ask independent planners for
   radically different designs before synthesis.
4. **Parallel context isolation.** Independent review/planning lenses should
   not inherit each other's conclusions.
5. **Prototype as evidence.** Spike should be able to produce throwaway UI or
   logic code when prose cannot answer the question.
6. **Leading words and domain vocabulary.** Compact terms such as `frontier`,
   `fog`, `tracer bullet`, and project-owned domain terms replace repeated
   explanations.
7. **Invocation policy.** Only skills that must trigger automatically or be
   reached by another skill should pay permanent description cost.
8. **Templates as resources.** Formats belong in one reference or tool
   scaffold, not repeated inline across orchestrators.

## Matt's advantages and limits

`wayfinder` is better than local planning for work whose route is genuinely
unknown. Its map is an index, its tickets resolve decisions rather than fake
implementation slices, and its frontier supports concurrency. Its weakness is
that the 1,975-word dispatcher is itself monolithic, and parallelism is mostly
limited to research.

`prototype` is the best context design in the repo. Its weakness is the
absolute "no tests" rule and vague branch retention. A throwaway shell needs
only a smoke check, but logic promoted into production still needs the normal
test-first flow.

`code-review` usefully separates Spec from Standards, but those two axes omit
an explicit correctness/security/test-proof lane and its final report does not
rerank findings into one ship decision. The local review contract is safer.

`to-spec` and `to-tickets` provide useful templates and vertical slices, but
`to-spec` explicitly requires a long, exhaustive story list, which conflicts
with this project's concision goal. `implement` is too short to be a reliable
delivery contract.

## Gaps in the local suite

- `flow` restates work, review, compound, lessons, sprout, decision, bug, and
  test policy. The orchestrator does not "add little machinery" in practice.
- `plan`, `work`, and `flow` repeat tatr state and proof rules. Single-source
  contracts are not yet real.
- `flow` reads every sibling artifact for an existing task even when most are
  irrelevant to the current phase.
- There is no bounded phase context packet or fresh-context phase execution.
- Parallel planning and tatr-native frontier/claim semantics are absent.
- Spike prohibits code, so uncertain interaction and state models stay
  hypothetical.
- Output limits are advisory and inconsistent. Durable files and chat can
  restate the same facts.
- The skill suite has no token budget, broken-reference check, duplicate-rule
  check, trigger evaluation, or realistic fixture-prompt evaluation.
- `spike` says to close its task immediately, while `tatr check` requires
  review and retro for every closed task. The contracts disagree.

## Gaps in both systems

- Neither measures actual prompt/context use or invocation precision.
- Neither generates a minimal phase context packet from task metadata.
- Neither validates that a conditional pointer was followed only when needed.
- Neither has a conflict-aware protocol for parallel writers beyond branch
  isolation.
- Neither tests the same skill behavior across Codex and Claude invocation
  policies.
- Both rely on prose for rules that could be schemas, transitions, or CLI
  guards.

## Options considered

- **Adopt Matt's flow wholesale.** Rejected. It would lose tatr state, sprout
  isolation, proof-bearing DoD, durable review rounds, and compounding.
- **Only split the current files.** Rejected. It improves navigation but does
  not reduce a full run if one agent reads all files.
- **Keep the current suite and add wayfinder/prototype.** Rejected. It adds
  more permanent context without removing duplication.
- **Hybrid with phase isolation and tool-owned contracts.** Recommended. Keep
  the local lifecycle, adopt Matt's disclosure and discovery patterns, and
  make context/output budgets measurable.

## Recommendation

### 1. Make flow a small state machine

Target `flow/SKILL.md` at 350-500 words. It should own only:

1. Resolve or create the active tatr task.
2. Dispatch exactly one phase from durable `FLOW STEP`.
3. Enforce the plan approval gate.
4. Repeat work/review until approved.
5. Compound, land, verify, and finish.

At a phase boundary, load that phase's skill, not its rules copied into flow.
Keep `epic.md`, `landing.md`, and `resume.md` as one-level conditional
references. Run planning, work, review, and compound in fresh contexts when
the platform supports it. Each phase reads its task packet, writes durable
results, and returns a bounded summary to flow.

### 2. Give every skill a context budget

Initial budgets:

| Surface | Budget |
| --- | --- |
| Model-invoked description | 20-30 words |
| All flow-family descriptions | Under 200 words |
| Router/orchestrator body | Under 500 words |
| Phase body | Under 800 words |
| Conditional reference | Under 1,000 words; one level deep |
| Phase handoff | Under 150 words plus file pointers |

Add a skill conformance command that checks word budgets, ASCII, frontmatter,
broken references, reference depth, and duplicate paragraphs. Add fixture
prompts that verify trigger choice, files loaded, artifacts written, and final
output shape. Budgets are failure signals, not excuses to omit a required
guard.

### 3. Move invariants into tools and templates

Extend tatr before adding more prose:

- Scaffold TASK, SPIKE, DECISION, REVIEW, and RETRO records.
- Make state transitions enforce plan approval and close requirements.
- Produce `tatr context <id> --phase <phase>` with only relevant pointers.
- Represent dependencies, frontier, and an atomic claim if parallel sessions
  will share a backlog.

Let `sprout land` own landing guarantees. Flow should say when to call it and
how to respond to failure, not re-document its implementation.

### 4. Split phase content by actual branches

- `plan`: core five-step process; disclose `decision.md`, `proofs.md`,
  `epic.md`, and `parallel.md` only when triggered.
- `work`: core task loop; disclose `bug.md`, `review-feedback.md`,
  `sync.md`, and risk-specific verification references.
- `review`: core round/verdict loop; disclose the record format and
  risk-specific rubrics. Keep one ranked finding ledger.
- `spike`: route among research, UI prototype, logic prototype, or mixed
  evidence. Each mode gets one direct reference from `SKILL.md`.
- `compound` and `lessons`: keep only collection, distillation, promotion,
  and completion criteria; move formats out or let tatr scaffold them.
- `sprout`: its current `SKILL.md` plus optional `reference.md` is already
  close to the desired shape.

Delete "Relationship to..." sections once the orchestrator and descriptions
encode the handoff. Delete historical anecdotes from active instructions after
their rule is tool-enforced or captured in the ledger.

### 5. Add conditional parallel planning

Use one planner by default. Use three independent planners only when at least
one condition holds:

- a load-bearing interface or architecture fork exists;
- the task spans multiple independent domains;
- one context cannot hold the needed exploration;
- the user explicitly asks for alternatives.

Give every planner the same read-only context packet and a different lens:
minimal end-to-end slice, deepest maintainable interface, and migration/risk.
Cap each candidate at 250 words. Persist only the selected plan; summarize
rejected alternatives in `DECISION.md`. Candidate scratch should not become
permanent context.

For very large uncertain work, add a tatr-native wayfinder record:
Destination, Decisions, Frontier, Fog, and Out of Scope. Children are decision
tasks with dependencies, not premature implementation tasks. Resolve one
decision per context, parallelize only unblocked research/prototype tasks, and
send accepted decisions through normal plan/work/review/compound.

### 6. Let spike produce disposable code

Keep `spike` as the umbrella. Add:

- **Research**: primary sources or local code; no prototype unless evidence
  remains insufficient.
- **Logic prototype**: tiny interactive state driver using the project's
  runtime.
- **UI prototype**: 3 structurally different variants in the real app context,
  switchable on one route.

Prototype code lives on a `prototype/<slug>` sprout branch and does not land.
`SPIKE.md` records the question, run command, branch/commit pointer, evidence,
verdict, and discarded alternatives. Accepted behavior becomes a decision and
a normal planned task with production tests. Add page-archetype references
only when a real recurring branch appears; do not preload a generic catalog.

### 7. Make concise output a contract

Chat should point to durable artifacts instead of restating them:

| Phase | User-facing output |
| --- | --- |
| Spike | Recommendation, open risk, artifact/task links; <=120 words |
| Plan gate | Done definition, ordered steps, decisions; <=250 words |
| Work | Changed, proofs, branch/task; <=150 words |
| Review | Findings first; no duplicate narrative |
| Compound | New/bumped lesson slugs and follow-ups; <=100 words |
| Flow progress | One or two sentences plus the terminal status line |

Use a default response shape of `Result`, `Proof`, `Next` only when all three
carry information. Omit empty sections. Store detail once: TASK is scope and
execution truth, REVIEW is findings, RETRO is process, LESSONS is reusable
learning, and chat is only the pointer.

## Open questions

- Should fresh phase contexts be mandatory for every `/flow`, or only once a
  task crosses a measured context threshold?
- Should tatr own map/frontier/claim behavior, or should the first version use
  markdown conventions and promote only after recurrence?
- Which phase skills must remain implicitly invocable on both Codex and
  Claude? This needs a cross-platform trigger test before changing policy.
- Should prototype branches be retained indefinitely, tagged, or pruned after
  their decision is implemented?
- Are output budgets hard conformance limits or review warnings?

## Next steps

- tatr 20260730-142533: refactor flow skills for bounded context and concise
  output.
- tatr 20260730-142540: add tatr-native wayfinding, parallel planning, and
  prototypes.

## Fix record

This spike seeded two tasks. Each task should append its landed result and
proof here rather than duplicating its full close-out.
