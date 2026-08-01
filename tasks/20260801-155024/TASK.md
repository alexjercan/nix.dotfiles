# Make flow stop gates explicit approval transitions

- STATUS: OPEN
- PRIORITY: 85
- TAGS: skills, flow, review, docs
- KIND: TASK
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Story

As a flow user, I want every context-cut boundary to ask for an explicit
decision before changing lifecycle state or landing, so a fresh `/flow <id>`
can route from durable state without a chat-only hint.

## Steps

- [ ] Add a concise, conditionally loaded gate protocol under
      `home/modules/agents/skills/flow/` and route all STOP gates through it.
      Require a blocking user question when the runtime provides one, with a
      direct question fallback, explicit approval effects, and a no-transition
      "Stop and let me decide" path that prints the fresh-session command.
- [ ] Align `flow/SKILL.md`, `plan/SKILL.md`, and `work/SKILL.md`: plan approval
      records PLANNED before the cut; initial work remains WORKING until work
      approval records REVIEWING; phase reports return gate statuses instead
      of substituting passive `/clear` instructions for approval.
- [ ] Align `work/review-feedback.md` and `review/SKILL.md`: change-request
      fixes return directly to review, except fixes after review rounds 3, 6,
      and later multiples of three stop at the work approval gate; an APPROVE
      verdict proceeds directly to COMPOUNDING.
- [ ] Align `compound/SKILL.md`, `flow/landing.md`, `flow/resume.md`, and the
      final flow report: compound closes the task and returns LAND_READY;
      landing requires explicit approval; lessons finish with results,
      verification, and usage guidance; cold sessions re-emit a pending gate
      from task, branch, proof, and review state.
- [ ] Re-read neighboring gate, route, output, and deployment documentation;
      remove contradictions or restatements. Validate every changed skill,
      measured budgets, task records, and the full repository checks.

## Definition of Done

- PLAN_READY, WORK_DONE, each third-round continuation, and LAND_READY use one
  blocking approval protocol whose approve choice names its transition/action
  and whose stop choice performs none and prints `/clear` plus `/flow <id>`
  (cmd: `rg -q 'blocking user-question tool' home/modules/agents/skills/flow/gates.md && rg -q 'PLAN_READY.*PLANNED' home/modules/agents/skills/flow/gates.md && rg -q 'WORK_DONE.*REVIEWING' home/modules/agents/skills/flow/gates.md && rg -q 'LAND_READY.*land' home/modules/agents/skills/flow/gates.md && rg -q 'Stop and let me decide' home/modules/agents/skills/flow/gates.md && rg -q '/clear.*flow <id>' home/modules/agents/skills/flow/gates.md`).
- Initial work does not enter REVIEWING before approval; review fixes loop back
  without a stop except after a latest round divisible by three
  (cmd: `rg -q 'Initial work.*WORK_DONE.*without.*transition' home/modules/agents/skills/work/SKILL.md && rg -q 'not a multiple of three.*REVIEWING' home/modules/agents/skills/work/review-feedback.md && rg -q 'multiple of three.*WORK_DONE' home/modules/agents/skills/work/review-feedback.md`).
- Review APPROVE proceeds to COMPOUNDING, compound returns LAND_READY only
  after DONE, and landing then lessons produces the terminal report
  (cmd: `rg -q 'APPROVE.*COMPOUNDING' home/modules/agents/skills/review/SKILL.md && rg -q 'DONE.*LAND_READY' home/modules/agents/skills/compound/SKILL.md && rg -q 'land.*lessons' home/modules/agents/skills/flow/SKILL.md`).
- A cold session distinguishes pending plan, work, review-continuation, and
  land gates from unfinished phase work (manual: forward-test `/flow <id>`
  against four minimal task/branch states and confirm the question, transition,
  stop path, and resume command for each).
- Changed skill folders pass skill validation and all repository gates remain
  clean (cmd: `bash home/modules/agents/skills/check.sh && tatr check && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- A round-multiple gate applies only when REQUEST_CHANGES requires another
  review. APPROVE proceeds to compound because no continuation exists.
- Tatr already owns every required lifecycle state. No new marker or CLI state
  is needed: approval performs the existing transition before the context cut;
  refusal leaves the current state unchanged.
- One cohesive task: splitting router and phase text would temporarily publish
  a contradictory lifecycle.
