# Decision: Adopt tatr v2 and revalidate nix task history

- DATE: 20260731-111529
- STATUS: ACCEPTED
- TASK: 20260730-155003
- TAGS: flow, tatr, testing, epic

## Context

Two Definition-of-Done proofs in this Epic name a runner that does not exist:

- this task's DoD 3, `test: flow_v3_end_to_end` - never had a runner; it was
  written expecting the skills fixture suite to grow one.
- the Epic's `## Done Means` criterion 5, `test: parallel_lane_selection` - its
  runner was one of the 20 fixture cases added by 20260730-154958 and deleted
  mid-cycle by 20260730-154955, when the user removed `skills/fixtures/`,
  `check.sh --fixture` and `check.sh --self-test` for being slow to iterate on.

The other Epic criteria are runnable and green today: 3
(`test_epic_frontier`) and 6 (`test_ledger_pending_requires_disposition`) live
in `/home/alex/personal/tatr/checker.sh`; 1, 2 and 7 are `cmd:` proofs that
pass. Every other Step of this task was already satisfied before the cycle
started: the root `tatr` flake input is locked to the published `cd8b33d`, the
deployed skill matches tatr HEAD, all 55 task records carry v2 fields, and
`tatr check`, `tatr check --ledger LESSONS.md`, `check.sh`, `sprout-test.sh`
and `nix flake check --no-build` all exit 0.

Seeded task 20260731-104819, "Rewrite the flow-suite v3 Epic Done Means onto
runnable proofs", was created to fix the Epic half of the same problem. It is
not in the Epic's child index, and its scope is contained in this task's
Step 6.

## Decision

1. Drop the unrunnable criteria rather than rebuild a runner for them. This
   task's DoD 3 and the Epic's criterion 5 are deleted. The end-to-end path is
   evidenced by the tatr-side checker tests plus the structural `check.sh`
   gate, and by the pending `## Manual Acceptance` items the user already owns.
2. Fold 20260731-104819 into this task and retire its record. Rewriting the
   Epic's `## Done Means` onto proofs that still have runners is already what
   Step 6 of this task asks for; running it as a second cycle over the same
   `TASK.md` buys records, not correctness.
3. Retire it with `tatr rm`, not by walking it to DONE. The plan said "set its
   `STATUS: CLOSED` via `tatr edit`"; that is not possible on the released
   binary. `tatr edit` has no `--status`, and the only route from BACKLOG to
   CLOSED is the full lifecycle walk, whose COMPOUNDING step refuses without a
   REVIEW.md carrying an APPROVE verdict (verified in a scratch copy of the
   record). Closing it that way would have meant fabricating an approving
   review and a retro for work nobody did. Since the task was a duplicate
   rather than abandoned work, removing the record is honest and the tool's own
   answer. Its content is preserved below and its rationale in the Epic Notes.
   The missing terminal state is now task 20260731-112502.

### What 20260731-104819 said, preserved

Title: "Rewrite the flow-suite v3 Epic Done Means onto runnable proofs"
(p70, chore/tatr/skills, BACKLOG). Raised as R2.2 in
tasks/20260730-154955/REVIEW.md, because deleting
`home/modules/agents/skills/fixtures/` removed the runner for fixture names
the Epic's `## Done Means` cite. It was kept out of 20260730-154955
deliberately: editing the parent Epic's acceptance criteria from inside a child
Story's diff widens that task past one cohesive change. Its steps asked to
rewrite criteria 3, 5 and 4's harness clause, confirm 1, 2, 6 and 7 still run,
and re-lint the Epic; its DoD asked that every `## Done Means` proof run, pass
or be an explicit `manual:` item, and that the Epic lint clean.

Two of its premises were wrong and are corrected here rather than acted on:

- Criterion 3's `test_epic_frontier` was never a fixture case. It is defined in
  `/home/alex/personal/tatr/checker.sh`, still runs, and was left alone.
- Its DoD proposed `cmd: tatr proofs 20260730-153122`. `tatr proofs` reads
  `## Definition of Done`, which an Epic does not have, so that command prints
  nothing and exits 0 no matter what the Epic says - a proof that cannot fail.

## Alternatives considered

- **Prove the path with a recorded manual run.** Rewrite both criteria as
  `manual:` proofs, drive one real Epic -> Story -> plan -> work -> review ->
  compound -> disposition -> close -> land cycle in a scratch repository, and
  record the observations. Rejected: it converts an unrunnable proof into an
  unrepeatable one, and it duplicates the manual acceptance items already
  pending on the Epic.
- **Rebuild a small `flow_v3_end_to_end` shell test.** Executable and
  repeatable, but it re-introduces the suite the user deliberately deleted, and
  it could only exercise tatr's lifecycle commands - never the skill behavior
  the criterion was about.
- **Run 20260731-104819 as its own cycle first.** Cleaner separation of
  records, but two full plan/work/review cycles editing the same Epic
  `TASK.md`, with this task blocked behind the second one.
- **Restate criterion 5 as a grep over the lanes skill texts.** This is what
  20260731-104819 itself proposed: a `cmd:` proof that
  `home/modules/agents/skills/plan/lanes.md` and `review/lanes.md` state the
  lane-selection rule. Both files exist, the proof would run, and it can fail,
  so it was reconsidered on the user's behalf in round 1 of review before being
  rejected again. Rejected because it proves the skill text CONTAINS a phrase,
  not that a lane gets selected or stays inside its cap - which is precisely
  the `content` fixture kind removed in 20260730-154955, re-entering by the
  back door as a DoD proof. Worse, it would let the Epic go green on parallel
  lanes while nothing had observed a lane run: a criterion satisfied by prose
  is weaker than an honest `manual:` item, because it stops anyone looking. The
  acceptance for lanes therefore lives in the `## Manual Acceptance` item for
  20260730-154958, which the Epic now marks as the only one covering that
  feature.

## Consequences

- The Epic closes on the evidence that has runners, plus explicit user sign-off
  on the `## Manual Acceptance` list. Nothing claims an automated end-to-end
  proof exists.
- `check.sh` stays purely structural and fast. No fixture harness returns.
- 20260731-104819's record is gone; its content and rationale survive in this
  file and in the Epic's Notes. Anything citing the bare ID will not resolve
  through `tatr show`.
- The lifecycle has no honest terminal state for a superseded task. Task
  20260731-112502 was seeded to add one; until it lands, retiring a task means
  `tatr rm` plus a decision record.
- The Epic's criterion numbering shifts when 5 is removed; the Story records
  that cite criteria by number must be checked, not assumed stable.
