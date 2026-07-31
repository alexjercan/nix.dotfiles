# Review: Compact flow skills to stricter budgets

- TASK: 20260731-133122
- BRANCH: refactor/compact-flow-skills

## Round 1

- REVIEWER: out-of-context lanes (behavior/proofs; correctness; design/docs)
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/agents/skills/flow/SKILL.md:44 - The compact
  routing drops explicit `version` goals and same-session context loss; restore
  both conditions so `epic.md` and `resume.md` still load.
  - Response: fixed in this commit.
- [x] R1.2 (MAJOR) home/modules/agents/skills/review/SKILL.md:25 - Later rounds
  no longer keep the out-of-context default; require fresh re-review unless a
  recorded exception applies.
  - Response: fixed in this commit.
- [x] R1.3 (MAJOR) tasks/20260731-133122/NOTES.md:10 - The inventory silently
  reverses master `plan/SKILL.md`'s base-red proof rule. Record the old rule,
  its conflict with `proofs.md`, why it was retired, and the behavior correction
  in TASK.md close-out.
  - Response: fixed in this commit.
- [x] R1.4 (MAJOR) home/modules/agents/skills/review/SKILL.md:14 - `Run checks
  in sprout show <feature>` is not executable because `sprout show` only prints
  a path; restore `cd "$(sprout show <feature>)"` or require that workdir.
  - Response: fixed in this commit.
- [x] R1.5 (MAJOR) home/modules/agents/skills/lessons/ledger.md:22 - The blanket
  ban on hand-composed annotations contradicts the required post-land PROMOTED
  transition, which has no tatr command. Limit the ban to dispositions and
  assign the manual completion transition explicitly.
  - Response: fixed in this commit.
- [x] R1.6 (MINOR) home/modules/agents/skills/flow/resume.md:39 - Flow section
  renumbering left `flow step 2` here and `flow/landing.md:3`'s `step 4.5`
  stale; replace both with named phases.
  - Response: fixed in this commit.
- [x] R1.7 (MINOR) home/modules/agents/skills/lessons/ledger.md:8 - The compact
  format omits the exact headings needed to create a new ledger; restore a
  literal minimal skeleton.
  - Response: fixed in this commit.
- [x] R1.8 (MINOR) home/modules/agents/skills/sprout/SKILL.md:30 - `leaves main
  unstaged` weakens the atomic failure guarantee; state that failed landing
  rolls main back to a clean tracked tree.
  - Response: fixed in this commit.
- [x] R1.9 (MINOR) home/modules/agents/skills/today/SKILL.md:24 - Restore
  `weight --days N` and state that read commands also support `--json`.
  - Response: fixed in this commit.
- [x] R1.10 (MINOR) home/modules/agents/skills/README.md:37 - The family includes
  `sprout`, which is not a phase; name the actual phases and classify sprout as
  the explicit worktree helper.
  - Response: fixed in this commit.

Pending user check: compare the imperative inventory with each rewritten
skill/reference after fixes.

## Round 2

- REVIEWER: out-of-context lanes (behavior/proofs; correctness; design/docs)
- VERDICT: APPROVE

All Round 1 responses independently verified. No fix regressions.

Pending user check: compare the imperative inventory with each rewritten
skill/reference after fixes.
