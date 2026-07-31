# Epic: flow-suite v3 concise context and tatr-native orchestration

- STATUS: OPEN
- PRIORITY: 0
- TAGS: goal,skills,flow
- KIND: EPIC
- FLOW STEP: PLANNING
- PLAN STATUS: DRAFT

## Epic

Deliver flow-suite v3 across tatr and nix.dotfiles: a compact skill system
with lazy context loading, tatr-enforced lifecycle and Epic/Story graphs,
explicit lesson-promotion decisions, retained research/prototypes, and
conditional parallel planning and review.

## Done Means

1. Tatr owns the mechanical task lifecycle, graph, record schemas, and lesson
   disposition checks, with its own historical tasks migrated and revalidated.
   (cmd: `cd /home/alex/personal/tatr && tatr check --ledger LESSONS.md`)
2. The flow-family skills load branch/phase references on demand and obey
   measured description, body, reference, handoff, and output budgets.
   (cmd: `cd /home/alex/personal/nix.dotfiles && bash home/modules/agents/skills/check.sh`)
3. Tatr-backed Epics expose an index and frontier while Stories remain sized
   for one context. (test: `test_epic_frontier`, defined in
   `/home/alex/personal/tatr/checker.sh`)
4. Spike supports cited web research plus retained UI/logic prototypes in the
   repository-cached location. (manual: run one research spike and read its
   SPIKE.md, confirming each external claim carries a citation; then run one
   prototype-retaining spike and confirm the prototype still runs from its
   recorded command after the spike closes)
5. A lesson at the promotion threshold cannot pass the finish gate without an
   explicit user disposition, and an approved promotion uses the normal
   plan/work/review/compound lifecycle. (test:
   `test_ledger_pending_requires_disposition`, defined in
   `/home/alex/personal/tatr/checker.sh`)
6. nix.dotfiles adopts the released tatr skill/tool, migrates or explicitly
   classifies every old task record, and both repositories pass their full
   suites. (cmd: `cd /home/alex/personal/nix.dotfiles && tatr check --ledger LESSONS.md && nix flake check --no-build`)

## Child Tasks

- [x] 20260730-153325 (p100, tatr) Add typed v2 workflow schema and migrate
      tatr history.
- [x] 20260730-154657 (p90, tatr) Add transactional flow lifecycle commands
      and guards. Depends on: 20260730-153325.
- [x] 20260730-154740 (p85, tatr) Add Epic graph, frontier, claims, and phase
      context. Depends on: 20260730-153325, 20260730-154657.
- [x] 20260730-154745 (p85, tatr) Scaffold and validate flow artifact schemas.
      Depends on: 20260730-153325.
- [x] 20260730-154756 (p80, tatr) Require user disposition for lesson
      promotions. Depends on: 20260730-153325, 20260730-154745.
- [x] 20260730-142533 (p80, nix.dotfiles) Refactor flow skills for bounded
      context and concise output. Depends on: 20260730-153325,
      20260730-154745.
      3 review rounds, 27 findings (1 withdrawn on scope); adds
      skills/check.sh, its --self-test, and two nix checks.
- [x] 20260730-154955 (p75, nix.dotfiles) Integrate guarded flow lifecycle and
      lesson decisions. Depends on: 20260730-154657, 20260730-154745,
      20260730-154756, 20260730-142533.
      4 review rounds, 29 findings (4 BLOCKER, 4 MAJOR, 16 MINOR, 5 NIT) from
      three out-of-context lanes; adds the `tatr ledger` disposition gate and
      the `direct-state-edit` rule. Mid-cycle the user REMOVED the fixture
      suite, so `skills/fixtures/`, `--fixture` and `--self-test` are gone and
      check.sh is purely structural; `missing-output-contract` and
      `stale-rule-inventory` were added in their place. Seeds 20260731-094524,
      20260731-094537 and 20260731-104819 (the last was absorbed by
      20260730-155003 and its record retired; `tatr show` will not resolve it).
- [x] 20260730-142540 (p70, nix.dotfiles) Add tatr-native wayfinding, web
      research, and retained prototypes. Depends on: 20260730-153325,
      20260730-154657, 20260730-154740, 20260730-142533.
      2 review rounds, 7 findings (all MINOR/NIT); adds the Epic index, the
      spike mode router over research.md/prototype.md, a `content` fixture
      kind and `check.sh --fixture <case>`.
- [x] 20260730-154958 (p65, nix.dotfiles) Add conditional parallel planning
      and review lanes. Depends on: 20260730-154740, 20260730-154745,
      20260730-142533.
      3 review rounds, 11 findings (1 MAJOR in each of rounds 1 and 2, the
      rest MINOR/NIT); adds plan/lanes.md, review/lanes.md and 20 fixture
      cases. Seeds 20260731-084705.
- [x] 20260730-155003 (p50, nix.dotfiles) Adopt tatr v2 and revalidate nix
      task history. Depends on every Story above and published tatr default.
      The adoption and the record migration had already landed (`456e3ec`
      pinned the root `tatr` input to the published `cd8b33d`; every record
      already carried its v2 fields), so this Story confirmed them with a
      re-runnable proof and spent its diff on reconciling the records: it
      rewrote this `## Done Means` onto proofs that still have a runner, and
      folded 20260731-104819 in as superseded. Seeds 20260731-112502.
- [ ] 20260731-010900 (p20, nix.dotfiles) Decide whether the live-agent skill
      behavior pass is worth automating. Depends on: 20260730-142533.

## Decisions

- 20260730-153122 DECISION.md: use a typed breaking tatr v2 schema,
  transactional lifecycle commands, and explicit repository migrations
  (ACCEPTED).
- 20260730-142540 DECISION.md: prove the retained-prototype criteria
  structurally over the skill texts rather than making the gate execute
  prototype fixtures (ACCEPTED).
- 20260730-142533 DECISION.md: prove the skill suite structurally, and treat
  live-agent behavior as a manual acceptance item here rather than building a
  credential-bound, non-deterministic harness into the gate (ACCEPTED).
- 20260730-155003 DECISION.md: drop the two acceptance criteria whose runner
  the fixture-suite removal took with it rather than rebuild one, and fold
  20260731-104819 into that Story instead of running it as a second cycle over
  this file (ACCEPTED).

## Manual Acceptance

- (pending) 20260730-154955: read `flow/SKILL.md` Finish, `lessons/SKILL.md`
  step 5 and `compound/SKILL.md` step 6 together and confirm one actor asks
  for the lesson disposition, one tool records it, and compound does neither.
  Nothing automated checks that three prose files agree about an actor.
- (pending) Confirm the final output budgets produce concise but sufficient
  reports on representative flow, spike, plan, work, review, and compound runs.
- (pending) 20260730-154958: run one lane-selecting review and read the round,
  confirming the lanes stay inside their stated caps and the round reads as one
  deduplicated review rather than three concatenated ones. (The fixtures that
  proved the skill texts SAY this were removed in 20260730-154955, so this
  item now covers both the text and the behavior.) Since 20260730-155003
  dropped the automated parallel-lanes criterion from `## Done Means`, this is
  the Epic's ONLY remaining acceptance for bounded parallel lanes: it cannot be
  waived without leaving that feature unaccepted.
- (pending) 20260730-142540: run one real spike that retains a prototype, then
  confirm the prototype still runs from its recorded command after the spike
  closes. The `retained_prototype_smoke` fixture that proved the record NAMES a
  command, observations, a verdict and its limitations was removed in
  20260730-154955, so this item now covers both. See
  tasks/20260730-142540/DECISION.md.
- (pending) 20260730-142533: confirm the live behavior the structural gate
  cannot observe - that a real session loads only the guarded branch files,
  selects the intended skill on both Claude Code and codex, and keeps its
  reports inside the stated caps. `bash home/modules/agents/skills/check.sh`
  proves the SHAPE that makes this possible, never the obedience.

## Notes

- Source review: tasks/20260730-142052/SPIKE.md
- This is an explicit cross-repository Epic. Child task records live in the
  repository they modify.
- The user explicitly permits breaking tatr compatibility. Prefer the clean
  target schema and migrate/revalidate old records rather than retaining a
  permanent compatibility layer.
- `## Done Means` was rewritten by 20260730-155003 onto proofs that still have
  a runner. Two criteria named fixture cases that the 20260730-154955 removal
  of `home/modules/agents/skills/fixtures/` deleted: the parallel-lanes one was
  dropped (its acceptance now lives in the 20260730-154958 item under
  `## Manual Acceptance`), and criterion 4's "skill evaluation harness" clause
  was restated as a manual read that states both the cited-research and the
  retained-prototype halves itself, rather than delegating to the
  20260730-142540 item, which covers prototypes only.
  Criteria 3 and 5 kept their `test:` proofs - those runners were never in the
  fixture suite, they live in `/home/alex/personal/tatr/checker.sh`. The
  argument is in tasks/20260730-155003/DECISION.md.
- Finish blocker: `tatr flow <epic-id> --to DONE` refuses while ANY child is
  not CLOSED (verified in a scratch repo; it reports "child <id> is not
  CLOSED"). 20260731-010900 is still OPEN, so before this Epic can close it
  must either run its own cycle or be dropped from `## Child Tasks` with a
  reason. The Epic also has to walk PLANNING -> PLANNED -> WORKING ->
  REVIEWING -> COMPOUNDING -> DONE; there is no direct move to DONE.
