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
   for one context. (test: `test_epic_frontier`)
4. Spike supports cited web research plus retained UI/logic prototypes in the
   repository-cached location. (manual: run one research spike and one retained
   prototype fixture through the skill evaluation harness)
5. High-risk planning and review can use bounded independent parallel lanes,
   while ordinary work stays single-agent. (test: `parallel_lane_selection`)
6. A lesson at the promotion threshold cannot pass the finish gate without an
   explicit user disposition, and an approved promotion uses the normal
   plan/work/review/compound lifecycle. (test: `test_ledger_pending_requires_disposition`)
7. nix.dotfiles adopts the released tatr skill/tool, migrates or explicitly
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
- [ ] 20260730-154756 (p80, tatr) Require user disposition for lesson
      promotions. Depends on: 20260730-153325, 20260730-154745.
- [x] 20260730-142533 (p80, nix.dotfiles) Refactor flow skills for bounded
      context and concise output. Depends on: 20260730-153325,
      20260730-154745.
      3 review rounds, 27 findings (1 withdrawn on scope); adds
      skills/check.sh, its --self-test, and two nix checks.
- [ ] 20260730-154955 (p75, nix.dotfiles) Integrate guarded flow lifecycle and
      lesson decisions. Depends on: 20260730-154657, 20260730-154745,
      20260730-154756, 20260730-142533.
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
- [ ] 20260730-155003 (p50, nix.dotfiles) Adopt tatr v2 and revalidate nix
      task history. Depends on every Story above and published tatr default.
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

## Manual Acceptance

- (pending) Confirm the final output budgets produce concise but sufficient
  reports on representative flow, spike, plan, work, review, and compound runs.
- (pending) 20260730-154958: run one lane-selecting review and read the round,
  confirming the lanes stay inside their stated caps and the round reads as one
  deduplicated review rather than three concatenated ones. The fixtures prove
  the skill texts SAY this; nothing deterministic observes a live agent.
- (pending) 20260730-142540: run one real spike that retains a prototype, then
  confirm the prototype still runs from its recorded command after the spike
  closes. The `retained_prototype_smoke` fixture proves the record NAMES a
  command, observations, a verdict and its limitations; nothing automated runs
  that command. See tasks/20260730-142540/DECISION.md.
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
