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
2. Fold 20260731-104819 into this task and close it as superseded. Rewriting
   the Epic's `## Done Means` onto proofs that still have runners is already
   what Step 6 of this task asks for; running it as a second cycle over the
   same `TASK.md` buys records, not correctness.

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

## Consequences

- The Epic closes on the evidence that has runners, plus explicit user sign-off
  on the `## Manual Acceptance` list. Nothing claims an automated end-to-end
  proof exists.
- `check.sh` stays purely structural and fast. No fixture harness returns.
- 20260731-104819 is closed as superseded by this task; its rationale survives
  here.
- The Epic's criterion numbering shifts when 5 is removed; the Story records
  that cite criteria by number must be checked, not assumed stable.
