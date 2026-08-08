# Plan simple reviewable one-context changes

- STATUS: CLOSED
- PRIORITY: 90
- TAGS: skills, plan, docs, flow

## Story

As a planner, I want each Story shaped for the new simplicity review bar and
one cold execution context, so avoidable complexity and oversized diffs are
prevented before work begins.

## Steps

- [x] Update `home/modules/agents/skills/plan/SKILL.md` and the narrowest
      applicable plan reference with a from-scratch design challenge: choose
      the simplest route that meets the DoD before writing Steps.
- [x] Add a concept budget. Every proposed mode, branch, option, wrapper,
      extension point, or abstraction needs a named requirement, caller, or
      invariant in this Story; otherwise delete or defer it.
- [x] Add a reviewability/context budget. Estimate affected ownership
      boundaries and split independently implementable, committable vertical
      slices that can each fit one understand-build-review context.
- [x] For a large cohesive Story that cannot split without temporary shims or
      broken intermediate behavior, record that reason and its expected breadth
      rather than forcing an artificial task boundary.
- [x] Keep file/line counts as prompts for inspection, never universal design
      verdicts. Preserve the one-request-one-task rule for genuinely cohesive
      work.
- [x] Run the skill gate, task/ledger checks, and full flake checks.

## Definition of Done

- Plan explicitly asks whether the route would be chosen from scratch and
  budgets both concepts and reviewable context (cmd: `rg -q 'from scratch' home/modules/agents/skills/plan && rg -q 'concept budget' home/modules/agents/skills/plan && rg -q 'reviewab.*context|context.*reviewab' home/modules/agents/skills/plan`).
- Splitting guidance requires independently landable boundaries and records why
  a broad cohesive Story cannot split cleanly (manual: plan one broad fixture
  request and confirm the result creates landable Stories or names the concrete
  shim/broken-intermediate-state cost that prevents the split).
- The skill suite remains conformant and within all measured budgets (cmd:
  `rg -q 'concept budget' home/modules/agents/skills/plan && bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `rg -q 'concept budget' home/modules/agents/skills/plan && tatr check && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- `review/SKILL.md` and `review/dimensions.md` after 20260731-142000 define the
  approval bar this planner must anticipate without duplicating its full prose.
- A huge diff is evidence to question the plan, not proof that the feature was
  divisible. Splits must remain independently useful and green.

## Close-out

What/why: the plan skill now challenges the route before it writes Steps.
`plan/SKILL.md` workflow 2 gained the reviewable-context budget (one
understand-build-review pass over the ownership boundaries touched) and the
shim/broken-intermediate exception that keeps a genuinely cohesive task whole.
`## Rules` folded the from-scratch counterfactual and the named concept budget
into the existing simplest-design rule, and added the file/line-count clause.
`plan/decision.md` gained the counterfactual in the record format itself: the
`## Decision` bullet must say why the chosen route would be built from scratch
under today's constraints, not merely that it is what exists.

Alternatives: a new `sizing.md` reference was rejected. Its condition would be
"shaping or splitting a task", which is every plan, and a reference read on
every run is not progressive disclosure - it is the same context cost one file
later, which is the `split-files-need-isolated-phases` lesson. Extending the
existing simplest-design rule was also chosen over a parallel rule: the
concept budget IS that rule made checkable, and a second bullet would have
been two names for one idea.

Difficulties: the first draft measured 396 words against the 400-word body cap
and left the next planner four words of headroom. Tightening the new prose
(not the old) brought it to 390. This is the same pressure the previous two
Stories hit; the plan body is now the tightest phase body in the suite, though
`flow/SKILL.md` is tighter still at 300/300 with no headroom at all.

Evidence: all three `cmd:` conjuncts were red at base and are green now, each
sabotaged individually (`from scratch`, `concept budget`,
`one reviewable context`) and each turning the proof red. `check.sh` clean
(9 skills, 22 rules); `sprout-test.sh` 14/14; `tatr check` and
`tatr check --ledger LESSONS.md` exit 0; `nix flake check` all checks passed.
Budgets after the round-1 fixes: `plan/SKILL.md` body 394/400,
`plan/decision.md` 509/600, `flow/epic.md` 276/600.

Doc sweep: `AGENTS.md` ("one requested thing is one task") already agrees with
the new text. `flow/epic.md` carried the same sizing rule in a second
vocabulary; the round-1 reviewer caught that my sweep had read it as agreement
rather than duplication, and `epic.md` now points at the plan rule instead of
restating it.

Reflection: sabotage wiped uncommitted work here for the second time in this
Epic, via `git checkout HEAD --` before the edits were committed. The ledger
has carried that rule since 20260720-152433.
