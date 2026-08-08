# Add explicit flow dispatch table

- STATUS: CLOSED
- PRIORITY: 75
- TAGS: skills, flow, docs

## Story

As a flow user, I want an explicit state/condition dispatch table, so the
current task state names the next skill and legal transition without relying
on prose inference.

## Steps

- [x] Replace `flow/SKILL.md`'s numbered `## Route` with one compact table:
      state/condition, invoked skill, and transition/result.
- [x] Cover all eight tatr lifecycle states, the REVIEWING fix loop, post-DONE
      landing/finish work, and every phase skill dispatched by flow.
- [x] Route unknown WHAT to `spike` while staying in UNDERSTANDING; state that
      spike is a conditional handoff, not a tatr lifecycle state.
- [x] Re-read `tatr/lifecycle.md` and each phase body's transition contract;
      remove conflicting or duplicated route prose.
- [x] Run the skill gate, task/ledger checks, sprout tests, and flake checks.

## Definition of Done

- Flow exposes a state/condition -> skill -> transition/result table and an
  explicit unknown-WHAT -> `spike` route (cmd: `rg -q '^\| State / condition \| Skill \| Transition / result \|$' home/modules/agents/skills/flow/SKILL.md && rg -q '^\| UNDERSTANDING \+ WHAT unknown .*\| `spike` \|' home/modules/agents/skills/flow/SKILL.md`).
- The table covers every tatr state and preserves the guarded review fix loop
  (manual: fresh reviewer compares the table with `tatr/lifecycle.md` and all
  dispatched phase contracts).
- Flow remains at most 300 body words and the skill suite stays conformant
  (cmd: `bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `bash home/modules/scripts/sprout-test.sh && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- `tatr` owns lifecycle legality; the table documents routing, not a second
  transition engine.
- Skill descriptions support implicit model selection, but semantic matching
  is non-deterministic. Explicit flow routing makes phase choice inspectable.
- Expected shape: one table replacing prose, not an added graph or reference.

## Close-out

What/why: `flow/SKILL.md`'s six numbered Route steps became one 11-row table
keyed on state/condition. Every tatr state now names its skill and its
transition literally, so phase choice is a lookup rather than an inference
over prose. `resume.md`'s own FLOW STEP re-entry table was the same mapping
written twice; it is now three resume-specific cautions that ride on the Route
table instead of restating it.

Alternatives: keeping the numbered prose and appending a table (rejected - two
descriptions of one routing, and the router budget cannot hold both); a
separate `route.md` reference (rejected - the router's whole job is to be
resident, and a pointer would defer the lookup it exists to make cheap).

Difficulties/diagnosis: the 300-word router budget was the binding constraint,
not the content. A markdown table pays ~4 words per row in pipe characters
alone, so the first correct draft came in at 414 body words. Three levers got
it to 300: `|-|-|-|` for the separator row (7 words to 1), empty rather than
`-` cells in the Skill column for the four tatr-only rows, and dropping the
intro's container clause, which the `epic.md` pointer condition already
carries verbatim. The remaining trims were per-cell.

Evidence:
- Both DoD greps were red on master before the change and are green on the
  branch. Each conjunct sabotaged independently: rewriting the header row
  reddens the first and leaves the second green; deleting the spike row does
  the reverse.
- `check.sh` was a live proof throughout, not a formality - it rejected the
  414-, 340-, 323-, 313-, 303-, 302- and 301-word drafts in turn.
- `bash home/modules/scripts/sprout-test.sh` 14 passed 0 failed;
  `tatr check --ledger LESSONS.md` clean; `nix flake check` all checks passed.

Round 1 correction: the first draft's legend claimed `--to` marked a
non-default edge. A scratch-repo probe showed a bare `tatr flow` performs both
PLANNING -> PLANNED and PLANNED -> WORKING, so two default edges were labelled
non-default; the legend now says `--to` spells the target and only the fix
loop reverses. `version` was restored to the `epic.md` pointer condition, the
finish row no longer claims `GOAL DONE <id>` for a single task, and "last"
returned to the status-line rule. Those four words were paid for by
tightening the tagline, the legend and the post-table prose as well as two
table cells - no rule was retired to fund them.

Reflection: the budget-forced omissions are the part worth reviewing. The
container rule now lives only in the `epic.md` pointer condition, and "release"
survives there but not in the body; `## Stop`, the output contract and the
authority-of-task-prose rule were preserved verbatim. A reviewer should check
that no rule was retired by compression rather than by decision
(`refactor-by-rule-not-by-section`).
