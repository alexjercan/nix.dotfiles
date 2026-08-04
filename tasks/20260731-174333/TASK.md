# Epic: enforce ambitious simplicity and bounded-context flow

- PRIORITY: 0
- TAGS: goal, skills, flow
- ACTIVITY: COMPOUNDING
- GATES: PLAN
- RESOLUTION: DONE

## Epic

Make the flow-family skills enforce the repository's existing correctness,
KISS, YAGNI, and maintainability bar as one system. Reviews reject avoidable
spaghetti; plans shape work that is simple and reviewable; workers keep their
active context bounded; flow resumes from durable state; compound turns review
and context failures into better future plans.

## Done Means

- Review treats applicable `AGENTS.md` rules and avoidable structural
  complexity as approval criteria while keeping correctness and evidence first.
  (manual: run a fresh-context review over a deliberately correct but tangled
  fixture diff and confirm it requests concrete simplification rather than
  approving or inventing a speculative rewrite)
- Plan sizes independently landable work for one understand-build-review
  context and challenges unnecessary concepts before implementation. (manual:
  plan one broad request and confirm the result either splits at independently
  landable boundaries or records why a cohesive Story cannot split cleanly)
- Work and flow define bounded delegation, durable checkpoints, and a minimal
  fresh-session resume path without claiming an agent can invoke `/clear` or
  `/compact` itself. (manual: interrupt one WORKING Story after a checkpoint,
  start a fresh session from the emitted prompt, and confirm it resumes from
  task/worktree state without the old conversation)
- Compound identifies planning failures behind oversized diffs, review churn,
  and context overruns, then routes only general lessons to the ledger. (manual:
  run compound on one qualifying Story and confirm RETRO names the failed plan
  decision plus a concrete prevention)
- Every changed skill stays inside its measured context budget and the full
  repository gates pass. (cmd: `rg -q 'Process signal' home/modules/agents/skills/review && rg -q '150K' home/modules/agents/skills/work && bash home/modules/agents/skills/check.sh && bash home/modules/scripts/sprout-test.sh && tatr check && nix flake check`)

## Child Tasks

- [x] 20260731-142000 (p100, nix.dotfiles) Make avoidable complexity block
      review approval. Landed 20b88ec; review APPROVE round 1;
      `fix-touches-its-neighbours` promotion completed.
- [x] 20260731-174343 (p90, nix.dotfiles) Plan simple reviewable one-context
      changes. Depends on: 20260731-142000. Landed 48a0caa; review APPROVE
      round 1; de-duplicated the sizing rule against `flow/epic.md`.
- [x] 20260731-174348 (p85, nix.dotfiles) Bound worker context with delegated
      checkpoints. Landed 68fe066; review APPROVE round 1; seeded
      20260731-202400 for the `baseline-dod-proofs` promotion.
- [x] 20260731-174352 (p80, nix.dotfiles) Make fresh-session handoff a flow
      contract. Depends on: 20260731-174348. Landed 287ccbe; review APPROVE
      round 2 after a MAJOR two-hop reference; DECISION.md records the
      `flow/SKILL.md` budget call.
- [x] 20260731-174415 (p75, nix.dotfiles) Turn review and context overruns into
      planning lessons. Depends on: 20260731-142000, 20260731-174348. Landed
      79aa479; review APPROVE round 2; seeded 20260731-205300 for the
      `sweep-for-restatement-not-just-contradiction` promotion.

## Decisions

- No universal source-file line limit. File and diff size trigger a cohesion
  and planning challenge; avoidable complexity, not a raw count, blocks review.
- Use 120K visible tokens as a soft checkpoint and 150K as a hard handoff
  ceiling. When usage is hidden, use compaction warnings or an unmanageable
  active working set as the trigger.
- Sequential delegation in one worktree is allowed with exclusive ownership.
  Parallel independently landable work uses separate Stories and worktrees.

## Fog

- Runtime token counters and compaction controls differ by agent host. Each
  skill must state portable fallback behavior without pretending those controls
  are callable tools.

## Out of Scope

- Building a cross-runtime token meter or automatic `/clear`/`/compact` driver.
- A universal 1,000-line or other language-independent file-size gate.
- Letting review patch code or letting multiple agents edit one worktree at the
  same time.

## Manual Acceptance

- Batch the four behavioral checks from `## Done Means` after all Stories land.

### Results

- Review over a tangled fixture: PASS. An out-of-context reviewer read the
  review skill and reviewed a deliberately correct 53-line diff (a one-entry
  discount-rule registry with `ctx`, `apply_discounts` and `strategy` knobs, a
  duplicated `legacy` branch, and an impossible `is not None` guard) against a
  fixture `AGENTS.md`. Verdict REQUEST_CHANGES with four MAJOR and one MINOR,
  every structural finding naming the exact lines to delete and the concept
  deleted with behavior preserved - no speculative rewrite. It ran the code
  before judging design and found a real correctness defect the tangle hid: the
  new `if "price" in i and "qty" in i` guard silently drops malformed items
  where the base raised `KeyError`. Evidence stayed first.
- Plan over a broad request: PASS. An out-of-context planner read the plan skill
  and planned a three-deliverable sprout/TUI request against the real
  implementation. It produced an EPIC container plus three independently
  landable Stories, named each one's ownership boundaries and its `-d` ordering,
  applied the shim test explicitly to refuse splitting the packaging seam of the
  completion Story, and deferred eight concepts by the concept budget with a
  named reason each. It quoted the reviewable-context, shim and concept-budget
  rules as the drivers, and wrote nothing to the repository.
- Compound over a qualifying Story: PASS. 20260731-174415's RETRO names the
  failed plan decision - reading a content-shaped Step ("Keep code findings in
  REVIEW, change facts in TASK...") as a dictation to paste rather than a
  criterion to check - says why it seemed sound, and gives the concrete
  prevention. Two general lessons went to the ledger; three one-offs stayed in
  RETRO.
- Fresh-session resume: NOT RUN - genuinely user-owned. It needs a real session
  interrupted at a checkpoint and a real new session started from the emitted
  `/flow <id>` prompt. Every Story in this Epic is landed and no worktree
  survives, so no honest fixture exists; a subagent given the prompt would prove
  context isolation but not the `/clear` actor boundary the Done Mean is about.
  The contract itself is reviewed and gated (`flow/resume.md`, APPROVE round 2).

## Notes

- Source considered: `/home/alex/Downloads/SKILL.md`, "Thermo-Nuclear Code
  Quality Review". It is input, not a file this Epic depends on.
- Keep correctness, security, specification, tests, documentation, and honesty
  from the current review dimensions. Add structural ambition without replacing
  their evidence discipline.
