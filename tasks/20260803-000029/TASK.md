# Close the afk batch review's three MINOR findings

- PRIORITY: 40
- TAGS: afk, scripts
- KIND: TASK
- ACTIVITY: -
- GATES: -
- RESOLUTION: -

Round 1 of `tasks/20260802-234130/REVIEW.md` approved the `afk run` batch with
three MINOR findings left open. None of them blocked the landing; all three
are small, independent, and land together.

- R1.1 `home/modules/scripts/afk.sh` - `BATCH_REMAINING` is space-joined with
  `${*:index+1}`, so a stopped batch of goal strings prints a `not started:`
  line that cannot be re-issued verbatim. Join with
  `printf ' %q' "${@:index+1}"`.
- R1.2 `home/modules/scripts/afk-test.sh` - `seed_working_task` retries
  `tatr new` forever with stderr discarded. Bound the loop and fail with the
  captured stderr, so a non-collision failure ends the suite instead of
  hanging it.
- R1.3 `home/modules/scripts/afk-test.sh` - the per-item elapsed time in
  `run_item` is unpinned; reverting it to a bare `$SECONDS` leaves the suite
  green. Delay item 1 past a second boundary with `reply_slow` and assert
  item 2's own summary while the batch total differs.
