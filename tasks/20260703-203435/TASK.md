# Make the `today` script agent-friendly (non-interactive, exit codes, print path)

- STATUS: OPEN
- PRIORITY: 100
- TAGS: feature

## Goal

`today` (home/modules/scripts/today.nix) is built for a human: its default
action opens `$EDITOR` on today's journal entry. An agent cannot use an
editor, and the one non-interactive path (`--create`) prints nothing it can
consume and has a latent abort. Make `today` composable and non-interactive
so an agent can locate or create today's entry and get its path back, while
the interactive default stays unchanged for human use.

Done means:
- `today --create` creates the entry if missing (idempotent if present) and
  prints ONLY the absolute path of the entry file to stdout, exit 0. So
  `f=$(today --create)` works.
- `today --path` prints the absolute path to today's entry WITHOUT creating
  it, exit 0, so an agent can locate the file first.
- A first-ever entry (no yesterday file to carry `Tomorrow` tasks from)
  succeeds instead of aborting.
- All human/diagnostic text goes to stderr; stdout stays machine-parseable in
  `--create`/`--path`. Real errors (missing template, bad args) exit non-zero
  with a clear stderr message.

## Steps

- [ ] Make `--create` print the absolute entry path (and only that) to stdout
      on success and exit 0, whether the file was just created or already
      existed.
- [ ] Add a `--path` flag that prints today's entry path to stdout without
      creating anything and exits 0.
- [ ] Fix `templator`: when yesterday's file is missing, warn to stderr and
      continue (skip the carry-over) instead of `exit 1`, so a first entry
      still succeeds.
- [ ] Make a missing template (`Templates/$TEMPLATE`) fail with a clear stderr
      message and non-zero exit rather than a silent `cp` failure.
- [ ] Route all informational/warning messages to stderr; keep the
      interactive editor default (no flags) behaving as before.
- [ ] Update `usage()` to document `--path` and the stdout contract of
      `--create`.
- [ ] Test against a fixture den: `--create` prints a valid path and is
      idempotent; `--path` never creates; a first entry with no yesterday
      succeeds; a missing template exits non-zero.

## Notes

- Relevant file: home/modules/scripts/today.nix (the `writeShellApplication`
  text: `create`, `templator`, `edit`, arg parsing, main).
- The `${config...}`/`${pkgs...}` nix interpolations must be preserved; escape
  bash `$` as `$$` as the existing script does.
