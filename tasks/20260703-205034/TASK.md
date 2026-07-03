# Confirm/fix double 'Today' marker vs carried-over tasks in daily/today

- STATUS: OPEN
- PRIORITY: 40
- TAGS: bug

## Goal

`today`'s `templator` appends a fresh `Today` block at the end of the entry
(rewriting yesterday's `Tomorrow` header to `Today`), while `daily`'s
`add_task_entry` / `today_tasks` / `run_json` all operate on the FIRST `Today`
marker in the file. If the production template `Templates/daily.md` also
contains a `Today` line under "Today's Tasks", the entry ends up with two
`Today` blocks: carried-over tasks in one, manually-added tasks in the other,
and `daily --json` reports only the first block's tasks.

This was surfaced while reviewing 20260703-203438 (daily --json). It is
pre-existing structure and could not be confirmed in the dev environment
because the real `~/personal/the-den/Templates/daily.md` was not available.

Done means: the real template is inspected, and either (a) confirmed that
there is exactly one `Today` block in practice so no change is needed (close
with a note), or (b) `templator` merges carried-over tasks into the existing
`Today` section (or the parsers read all `Today` blocks) so tasks are never
split/hidden.

## Steps

- [ ] Inspect `~/personal/the-den/Templates/daily.md` and a real recent entry
      to see how many `Today` markers occur after `today -c` runs.
- [ ] If a single block: close this task with the finding recorded, no code
      change.
- [ ] If two blocks: make `templator` append carried-over tasks under the
      template's existing `Today` header instead of a new block, and re-run
      `daily --json` to confirm all tasks appear with correct indices.
- [ ] Add a fixture-based test reproducing whichever real structure applies.

## Notes

- Relevant files: `home/modules/scripts/today.nix` (`templator`),
  `home/modules/scripts/daily.nix` (`today_tasks`, `add_task_entry`,
  `run_json`).
- See `tasks/20260703-203438/REVIEW.md` and
  `tasks/20260703-203435/REVIEW.md` for context.
