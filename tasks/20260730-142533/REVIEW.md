# Review: Refactor flow skills for bounded context and concise output

- TASK: 20260730-142533
- BRANCH: refactor/flow-skills-bounded-context

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

Verified by the reviewer: all four DoD proofs run green; the nix deployment
check was independently sabotaged and fails correctly; `description-budget`
and `condition-misses-branch` were independently broken and fire correctly;
every number in the close-out (179 description words, body and reference
ranges) was recomputed and is true; the `run.sh` sourcing contract and
`set -u` behavior are sound.

- [x] R1.1 (MAJOR) home/modules/agents/skills/check.sh:25 - `FLOW_FAMILY` and
  `ALL_SKILLS` are hardcoded, so a skill directory absent from the list is
  never checked at all. A new `newskill/SKILL.md` with a wrong `name`, no
  description, no `agents/openai.yaml` and a pointer to a nonexistent file
  still yields `skills: clean`. The sibling nix check derives its set from
  disk for exactly this reason. Derive the set from
  `find "$root" -mindepth 2 -maxdepth 2 -name SKILL.md`, keep `FLOW_FAMILY`
  and `IMPLICIT` as classification lists, and fail when a skill on disk is in
  neither.
  - Response: fixed. `ALL_SKILLS` is now read off disk (`find -mindepth 2 -maxdepth 2 -name SKILL.md`); `FLOW_FAMILY` and `TOOL_SKILLS` became classification lists, with new `unclassified-skill` and `missing-skill` rules covering both directions of drift. Self-test case `unlisted-skill` reproduces your `newskill` scenario.
- [x] R1.2 (MAJOR) home/modules/agents/skills/fixtures/disclosure/flow-single-task.fixture:2
  - the fixture named for the single-task path actually asserts the RESUME
  branch (`when: interrupted resuming session`, `loads: resume.md`), so no
  fixture proves a fresh single-task run does not load `resume.md`. The drift
  was invisible because `run.sh` never reads the `prompt:` key. Retarget this
  fixture at the single-task branch with an empty `loads:` and
  `forbids: epic.md landing.md resume.md`, add a separate resume fixture, and
  either assert `prompt:` against `when:` or drop the key so it cannot lie.
  - Response: fixed. `flow-single-task.fixture` now asserts the single-task branch (`when: single cohesive requested thing`, empty `loads:`, `forbids: epic.md landing.md resume.md`); the resume branch moved to a new `flow-resume.fixture`. The `prompt:` key was DELETED from every fixture rather than asserted - a second source of truth that nothing reads is the thing that drifted, so removing it is the fix.
- [x] R1.3 (MAJOR) home/modules/agents/skills/fixtures/selftest.sh:108 - the
  message "21 rules proven able to fail" is false as stated: the 21 cases
  cover 20 distinct slugs out of 26 that `check.sh` and `run.sh` can emit
  (`bad-invocation-policy` is covered twice). Uncovered: `description-budget`,
  `missing-skill`, both non-`name` arms of `bad-frontmatter`,
  `condition-misses-branch`, `wrong-policy`, `codex-parity` and all three
  `bad-fixture` arms. Report cases and coverage separately, and add the
  missing cases.
  - Response: fixed. The message now reports cases and coverage separately, and coverage is COMPUTED, not asserted: `check.sh --rules` declares the inventory (two rules are chosen at runtime and cannot be grepped), the self-test fails on any declared rule with no case, and it also fails on any literal `fail` slug missing from the declaration. Twelve cases added; now 35 cases, 30 of 30 rules covered.
- [x] R1.4 (MAJOR) home/modules/agents/skills/work/SKILL.md:19 - two rules were
  dropped with no replacement anywhere in the tree: "if the main working tree
  is dirty with unrelated changes, ask the user before touching anything" (a
  user-approval stop point; the surviving dirty-tree rules only cover
  `sprout land` at landing time) and the plain `git checkout -b` fallback when
  sprout is unavailable. Neither is owned by tatr, sprout, a scaffold or the
  orchestrator, so Step 3 did not license removing them. Restore both.
  - Response: fixed. Both clauses restored verbatim in `work/SKILL.md` step 2.
- [x] R1.5 (MAJOR) WITHDRAWN by the reviewer in round 2 - home/modules/agents/skills/compound/SKILL.md:51 - the
  mandatory lesson-promotion gate specified in `tasks/20260730-142533/NOTES.md`
  is not delivered: no explicit STOP at a user decision gate, no
  PROMOTE/DEFER/RETIRE/ABSORBED outcomes, and a bare Pending entry does not
  keep the Finish gate red.
  - Response: not this task. The lesson-promotion gate is owned by two sibling tasks under the same Epic: tatr 20260730-154756 (`Require user disposition for lesson promotions`, currently WIP - it adds the `promotion-awaiting-decision` lint and validates PROMOTE/DEFER/RETIRE/ABSORBED) and nix.dotfiles 20260730-154955 (`Integrate guarded flow lifecycle and lesson decisions`, which wires the skills to it and depends on both this task and 154756). NOTES.md is the Epic-level refinement note, not this task's spec; this task's Steps and Definition of Done contain no promotion-gate clause. Building it here would duplicate 154955 and hard-code a disposition vocabulary that 154756 has not finalised. Deliberately deferred, not overlooked.
- [x] R1.6 (MINOR) tasks/20260730-142533/TASK.md:38 - Step 6's "bounded
  subagent handoffs" clause is ticked, but the `## Output` contracts govern
  in-session phase reports; the suite's only actual subagent is review's
  round-1 reviewer, and nothing bounds what it receives or returns. Bound it
  in `review/rounds.md`, or amend the step and close-out.
  - Response: fixed. `review/rounds.md` gained a `## The round-1 subagent handoff` section bounding both directions: exactly what the reviewer receives (task ID, branch, worktree path, default branch, dimensions, format - never the implementing conversation) and what it returns (findings only, no writes, no commits, 400 words or fewer outside the findings).
- [x] R1.7 (MINOR) tasks/20260730-142533/DECISION.md:66 - the record claims the
  gate "runs in CI-shaped contexts", but nothing wraps `check.sh`, so the
  repo's only aggregate gate (`nix flake check`) never runs it and the budgets
  can still rot silently. Wire it into `flake/checks-skills.nix`, or soften
  the claim.
  - Response: fixed, not softened. `flake/checks-skills.nix` gained `checks.skills-conformance`, which runs `check.sh --self-test` and then `check.sh`, so `nix flake check` now runs both. Verified it fails: setting `BUDGET_ROUTER_BODY=10` in a scratch git copy failed the build with `router-body-budget: 483 body words > 10`.
- [x] R1.8 (MINOR) flake/checks-skills.nix:77 - section 2's comment says it
  checks the DEPLOYED tree, but the loop stats `$source/$name/...`, the same
  repository directory `check.sh` already inspects, and never reads the
  `home.file` values. A skill deployed with `recursive = false` or a wrong
  `source` passes. Assert `recursive` and the `source` suffix, or reword the
  comment.
  - Response: fixed. Section 2 now reads the `home.file` VALUES out of the evaluated config (`recursive` and `source`, passed in as JSON) and asserts each entry is recursive and points at its own source directory. Verified both can fail in a scratch git copy: `recursive = false` gives `.claude/skills/compound is not deployed recursively`, and pointing every entry at `./skills/flow` gives `.claude/skills/compound deploys from .../skills/flow`.
- [x] R1.9 (MINOR) home/modules/agents/skills/check.sh:28 - the comment cites
  "SPIKE.md, section 2", which has no numbered sections, and sets
  `BUDGET_DESCRIPTION_EACH=40` where the spike's table says 20-30. Every
  shipped description is 20-25, so tightening is free. Set it to 30 and cite
  `## Recommendation`.
  - Response: fixed. `BUDGET_DESCRIPTION_EACH=30`, and the comment now cites the budget table under `## Recommendation` instead of a section number that does not exist.
- [x] R1.10 (MINOR) tasks/20260730-142533/DECISION.md:40 - the record still
  calls the check `skills_deployment_tree` after TASK.md recorded the rename
  to `skills-deployment-tree`, so the durable artifact names something that
  does not exist.
  - Response: fixed. DECISION.md now names `skills-deployment-tree` and records the rename inline; the `## Context` paragraph still quotes `skills_deployment_tree` deliberately, because that is the wording of the plan it is reasoning about.
- [x] R1.11 (MINOR) home/modules/agents/skills/README.md:75 - the Checks
  section summarises the rule as "ASCII", but the implementation deliberately
  narrowed it to substituted typographic glyphs so `today/SKILL.md` can quote
  an emoji. Say "substituted typographic glyphs".
  - Response: fixed. README now says "substituted typographic glyphs" and names them, with the reason the broad rule was rejected.
- [x] R1.12 (MINOR) home/modules/agents/skills/check.sh:60 - a pointer whose
  condition is empty (its text wrapped onto the previous line) passes section
  4 and is caught only if a disclosure fixture happens to cover that file.
  Since fixture coverage is not itself enforced, the guard is coincidental.
  Add an `empty-pointer-condition` rule, and a rule that every reachable
  reference has at least one disclosure fixture naming it.
  - Response: fixed. Two new rules: `empty-pointer-condition` (a reachable pointer whose text before the arrow strips to nothing) and `no-disclosure-fixture` (a reachable reference no disclosure fixture names in `loads:`). Both have self-test cases; the `wrapped-condition` case reproduces exactly the wrap you found.
- [x] R1.13 (MINOR) home/modules/agents/skills/flow/SKILL.md:71 - two workflow
  rules ("new work found mid-flow ...", "a mid-flow lesson re-audits ...") sit
  inside `## Output`, where a reader will not look for them, and consume 30 of
  the 150-word output-contract budget. Move them under section 4.
  - Response: fixed. Both rules moved under section 4, where the work loop is.
- [x] R1.14 (MINOR) home/modules/agents/skills/spike/SKILL.md:36 - spike's step
  5 seeds several tasks, which is exactly the step that invites chaining
  `tatr new`, but the "one `tatr new` per command, never chained" rule now
  survives only in `plan/SKILL.md`, which spike does not load. It is an
  incident rule (`same-second-ids (x7)`). Restore it as a parenthetical.
  - Response: fixed. Restored as a clause in spike step 5, with the reason (a same-second collision kills the rest of the chain).
- [x] R1.15 (MINOR) home/modules/agents/skills/review/SKILL.md:73 - "on APPROVE
  the cycle ends; merging is the user's call" was dropped, and the nearest
  survivor (`flow/landing.md`) only covers the flow-driven path, so a
  standalone `/review` no longer states that APPROVE ends its authority.
  - Response: fixed. Added to review step 5: "On APPROVE the review cycle ends; merging and pushing are the user's call, or the orchestrator's."
- [x] R1.16 (MINOR) home/modules/agents/skills/spike/SKILL.md:36 - the spike
  `## Fix record` mechanism was deleted from both spike and compound with
  nothing replacing it; it was the only place a multi-task spike family's
  current state was aggregated. Restore it, or record its retirement.
  - Response: fixed. Restored in spike step 5 (with the multi-task condition that gates it) and re-added to compound's lane list.
- [x] R1.17 (NIT) home/modules/agents/skills/flow/SKILL.md:1 - the body is
  exactly 500 of 500 words, so the next one-word edit fails the gate. Trim to
  roughly 470.
  - Response: fixed. The body is now 483 words, and the budget is documented as "at most" in both the README table and the DoD, matching the `-le` comparison.
- [x] R1.18 (NIT) home/modules/agents/skills/README.md:39 - the inline example
  escapes backticks inside a code span, which markdown cannot do; it renders
  mangled. Use a fenced block.
  - Response: fixed. The example is now a fenced markdown block showing a real pointer line.
- [x] R1.19 (NIT) home/modules/agents/skills/check.sh:93 - `if line="$(... |
  head -1)"` takes `head`'s exit status and is always true; only the inner
  `[ -n "$line" ]` does any work. Drop the `if`.
  - Response: fixed. The `if` is gone; the capture's emptiness is the only test, with a comment naming why.
- [x] R1.20 (NIT) home/modules/agents/skills/check.sh:38 - the claim that both
  tools read `disable-model-invocation` could not be verified for codex (the
  binary is packed), so the DoD's cross-tool item rests on an unchecked
  assumption. State the asymmetry honestly.
  - Response: fixed by stating the asymmetry. The comment now says Claude Code honours the key (it is present in the shipped binary), that codex's behavior is unverified because its binary is packed, and that what the check really enforces is a single declaration site rather than two divergent policies.

## Round 2

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

Round-1 verdicts: R1.1, R1.2, R1.4, R1.6, R1.7, R1.8, R1.9, R1.10, R1.11,
R1.13, R1.14, R1.15, R1.16, R1.17, R1.18, R1.19 and R1.20 RESOLVED, each
re-verified by sabotage rather than by reading the diff. R1.3 and R1.12
resolved in the direction they were raised but left the holes below. R1.5 is
WITHDRAWN by the reviewer: the scope pushback holds, since Epic
20260730-153122 Done Means 6 assigns the promotion gate to tatr
20260730-154756 and sibling 20260730-154955 Step 5 wires the skills to it.

- [x] R2.1 (MAJOR) home/modules/agents/skills/fixtures/selftest.sh:169 - the
  undeclared-rule check increments `failures` AFTER the only place `failures`
  is read, so it can never fail the run. Adding
  `fail somewhere brand-new-undeclared-rule "detail"` to `check.sh` prints the
  warning and exits 0, leaving `nix flake check` green. This is the half of
  the R1.3 fix that keeps `RULES` honest as rules are added. Compute
  everything first, then make ONE exit decision.
  - Response: fixed. All three conditions - failed cases, undeclared rules,
    uncovered rules - are now computed before a single `status` decision at
    the end, so none can be evaluated after the exit. Re-ran your exact
    reproduction: the run now prints the undeclared slug and exits 1.
- [x] R2.2 (MAJOR) home/modules/agents/skills/check.sh:227 -
  `no-disclosure-fixture` builds a global bag of `loads:` basenames with no
  `skill:` filter, so any skill's fixture vouches for any other skill's
  same-named reference. Adding `review/proofs.md` with a pointer passes
  cleanly because `plan-proofs.fixture` names `proofs.md`. Since `proofs.md`,
  `bug.md`, `rounds.md` and `ledger.md` are generic names this is a live
  collision, and a falsely-covered reference also escapes
  `condition-misses-branch` and `leaks-on-unrelated-branch`. Filter by skill.
  - Response: fixed with the scoped awk you suggested. Re-ran your
    reproduction: `review/proofs.md` now reports
    `no-disclosure-fixture: no fixtures/disclosure case for review names it in
    loads:`.
- [x] R2.3 (MINOR) home/modules/agents/skills/README.md:52 - the budget table
  still says 40 words per description while the gate now enforces 30, so an
  author trimming to 38 would believe they were conformant. The table header
  also does not say the limits are inclusive.
  - Response: fixed. Every row now reads "at most N", and a sentence states
    that a surface sitting exactly on its number is conformant and has no
    headroom.
- [x] R2.4 (MINOR) AGENTS.md:56 - the check-suite entry still calls
  `flake/checks-skills.nix` "the deployment half of the skills gate" after
  R1.7 made it carry both, and still presents `check.sh` as a hand-run
  command with no note that `nix flake check` now runs it.
  - Response: fixed. The entry now names both derivations and says the hand
    run is the fast path, not the only run; it also documents `--rules`.
- [x] R2.5 (MINOR) tasks/20260730-142533/TASK.md:80 - the close-out still
  claims a "500-word dispatcher" and "bodies 500-630, references 300-620";
  after the round-1 restorations the real numbers are 483, 483-659 and
  307-619. Precise-looking numbers in a durable record are exactly what a
  later session trusts without recomputing.
  - Response: fixed with the recomputed figures, and a parenthetical noting
    they are the post-review numbers so the change is not read as drift.
- [x] R2.6 (NIT) home/modules/agents/skills/check.sh:19 - an unrecognised flag
  is silently ignored, so `check.sh --selftest` prints `skills: clean` and
  exits 0, reading exactly like a passing self-test.
  - Response: fixed. Any argument other than `--self-test` or `--rules` now
    prints `unknown argument: <x> (expected --self-test or --rules)` and exits
    2.
- [x] R2.7 (NIT) home/modules/agents/skills/fixtures/selftest.sh:129 - the
  `policy-mismatch` and `codex-unreachable` cases edit `check.sh` itself to
  steer which rule fires. A sabotage case that mutates the gate proves less
  than one that only mutates the tree, and `codex-unreachable`'s edit also
  left stray `grep: No such file` noise on stderr.
  - Response: fixed. Both cases now sabotage the tree only, with a comment
    saying why. Both still trip their intended rule.

## Round 3

- REVIEWER: out-of-context
- VERDICT: APPROVE

R2.1-R2.7 confirmed RESOLVED, each MAJOR re-verified by the reviewer breaking
it again in a scratch copy rather than by reading the diff. R2.1 was checked on
all three of its paths (failed case, undeclared rule, uncovered rule) because
the fix put them on one shared `status`; all three still fail the run. R2.2's
legitimate path was checked alongside the hole, and the `skill:`-less fixture
hazard the scoped awk could have introduced is already caught by `bad-fixture`.
Every documented word count was independently recomputed and is true.

Proof runs on 717bfd6: `check.sh` clean; `--self-test` 35 cases, 30 of 30 rules
covered; `--rules` 30 slugs; bare `nix flake check` green on a fresh `git init`
copy; `tatr check --ledger LESSONS.md` clean.

Two NITs were raised and both fixed at the implementer's discretion:

- [x] R3.1 (NIT) AGENTS.md:61 - the round-2 rewrite left an 89-column line
  against the file's ~76-column wrap. Rewrapped.
- [x] R3.2 (NIT) tasks/20260730-142533/TASK.md:45 - the DoD still said "fixture
  prompts" after the `prompt:` key was deleted in round 2. Reworded to "fixture
  branch words", with the reason recorded inline.

`tatr proofs 20260730-142533` returns six proofs, four `test:` and two `cmd:`,
and no `manual:` item, so this task has no pending user check of its own. The
manual acceptance it depends on sits on Epic 20260730-153122: the live-behavior
pass this gate deliberately cannot make (DECISION.md), and the Epic's own Done
Means 4.
