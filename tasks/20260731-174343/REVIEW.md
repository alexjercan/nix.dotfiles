# Review: Plan simple reviewable one-context changes

- TASK: 20260731-174343
- BRANCH: refactor/plan-one-context-changes

## Round 1

- REVIEWER: out-of-context
- VERDICT: APPROVE

No BLOCKER or MAJOR finding. Five MINOR/NIT findings, all fixed below.

- [ ] R1.1 (MINOR) home/modules/agents/skills/plan/SKILL.md:19 - the shim
  clause restates a rule already owned by `flow/epic.md:51` under a second
  vocabulary ("reviewable context" vs "understand-build-review context"). In
  an epic flow both files are loaded, so one rule is stated twice.
  `duplicated-paragraph` is verbatim-only and cannot see it.
  - Response: fixed as the reviewer's second option. `plan/SKILL.md` keeps the
    canonical statement - plan time is where splitting is decided, and the
    plan body is always loaded - and `flow/epic.md` now points at it instead
    of restating it. `epic.md` 281 -> 276 words.
- [ ] R1.2 (MINOR) tasks/20260731-174343/TASK.md:79 - the close-out claims the
  plan body is "the tightest surface in the suite". Re-derived: plan is
  390/400 (10 words spare), `flow/SKILL.md` is 300/300 (none). False.
  - Response: fixed; the sentence now says "tightest phase body" and names
    `flow/SKILL.md` at 300/300 as tighter. Independently re-derived before
    accepting: the flow router body is exactly 300 against a 300 cap, which
    also forced a user decision in Story 20260731-174352.
- [ ] R1.3 (MINOR) home/modules/agents/skills/plan/decision.md:63 - the new
  sentence puts the CHOSEN route's justification inside
  `## Alternatives considered`, defined one clause earlier as "each rejected
  option", so the scaffold now asks for a non-rejected item in the rejected
  list.
  - Response: fixed; the counterfactual moved onto the `## Decision` bullet,
    which already states the choice. `## Alternatives considered` is about
    rejected options again.
- [ ] R1.4 (NIT) home/modules/agents/skills/plan/SKILL.md:18 - Step 3's
  literal text asks the planner to "Estimate affected ownership boundaries";
  the shipped text used them only as a sizing unit and never asked for the
  estimate.
  - Response: fixed; the instruction is active - "Name the ownership
    boundaries each piece touches and size it to one reviewable context".
    This is the `tick-against-the-literal-step` failure caught by a reader
    rather than by me.
- [ ] R1.5 (NIT) home/modules/agents/skills/plan/SKILL.md:40 - the rewritten
  concept budget dropped "Generality" from the list the old rule carried,
  while `review/dimensions.md` still fails a diff for "generality no Step
  names".
  - Response: fixed; `generality` is back in the enumeration. This is
    `refactor-by-rule-not-by-section` - a rule word retired by a
    budget-driven rewrite, which is exactly the pending-promotion lesson.

Findings are unticked: they were fixed in-session after the round's
out-of-context reviewer recorded its verdict, so no reviewer has confirmed the
fixes. None is BLOCKER or MAJOR.

- Process signal: no unexpected scope - two files, twelve added lines, each
  traceable to a ticked Step.
- Process signal: three of the four added clauses mirror rules already living
  in `review/` and `flow/`. That is inherent to a suite where each skill loads
  alone, but `flow/epic.md` was the one place the redundancy became visible
  inside a single loaded context, and R1.1 removed it.

Verified by the reviewer: the full diff; DoD proof 1 green here and red on
master; each conjunct sabotaged separately and confirmed red, tree restored
clean; `check.sh` 0, `sprout-test.sh` 14/14, `tatr check` 0, `--ledger` 0,
`nix flake check` 0; both budget numbers re-derived; all six Steps re-read
against the diff; the whole skills tree and `AGENTS.md` swept for restatements
of the sizing rules. The reviewer also confirmed `decision.md` was the right
reference for Step 1 - `proofs.md` owns proof shape and `lanes.md` owns
parallel lanes, and neither is where a route is chosen.

Pending user checks (do not block APPROVE): the `manual:` DoD proof - plan one
broad fixture request and confirm the result either creates independently
landable Stories or names the concrete shim or broken-intermediate cost that
prevents the split.
