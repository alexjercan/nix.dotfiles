# Close the three deferred round-2 findings on sprout sync

- PRIORITY: 40
- TAGS: sprout,scripts,followup
- KIND: TASK
- ACTIVITY: -
- GATES: -
- RESOLUTION: -

Review round 2 of 20260803-105234 APPROVEd with three non-blocking findings
left open. They are carried here verbatim rather than lost.

- R2.1 (MINOR) `home/modules/scripts/sprout.sh` - `sync -n` still treats any
  non-zero `git merge-tree` as a conflict. On unrelated histories `merge-tree`
  exits 128 with empty stdout, so the probe prints a blank line and "would
  conflict" where the real `sync` correctly says "failed". Capture the probe's
  stderr; print "would conflict" only when it exited 1 with a non-empty path
  list, otherwise the `failed` wording plus the probe's own error. Same class
  of defect as R1.3, on the path R1.3 did not name.
- R2.2 (NIT) `tasks/20260803-105234/TASK.md` Close-out Evidence - the paragraph
  contradicts itself: it says "Round 1 found three cases that were then
  non-discriminating for reasons that were NOT inherent", names two, and says
  "both are fixed", while the sentence before classifies the third as
  inherently non-discriminating. Reword to "two ... both are fixed; the third
  it flagged is the inherent case above."
- R2.3 (NIT) `home/modules/scripts/sprout-test.sh` - the detached-worktree dry
  run case pins only an exit code, so it cannot tell that refusal from any
  other. Capture stderr and assert it names the worktree path, matching the
  real-run assertion above it.
