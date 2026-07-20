# Make the `today` script agent-friendly (non-interactive, exit codes, print path)

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: feature,historical

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

- [x] Make `--create` print the absolute entry path (and only that) to stdout
      on success and exit 0, whether the file was just created or already
      existed.
- [x] Add a `--path` flag that prints today's entry path to stdout without
      creating anything and exits 0.
- [x] Fix `templator`: when yesterday's file is missing, warn to stderr and
      continue (skip the carry-over) instead of `exit 1`, so a first entry
      still succeeds.
- [x] Make a missing template (`Templates/$TEMPLATE`) fail with a clear stderr
      message and non-zero exit rather than a silent `cp` failure.
- [x] Route all informational/warning messages to stderr; keep the
      interactive editor default (no flags) behaving as before.
- [x] Update `usage()` to document `--path` and the stdout contract of
      `--create`.
- [x] Test against a fixture den: `--create` prints a valid path and is
      idempotent; `--path` never creates; a first entry with no yesterday
      succeeds; a missing template exits non-zero.

## Notes

- Relevant file: home/modules/scripts/today.nix (the `writeShellApplication`
  text: `create`, `templator`, `edit`, arg parsing, main).
- The `${config...}`/`${pkgs...}` nix interpolations must be preserved; escape
  bash `$` as `$$` as the existing script does.

## Record

**What changed.** `home/modules/scripts/today.nix`:
- `--create` now prints the absolute entry path (and nothing else) to stdout
  and exits 0, whether it created the file or it already existed. Composes as
  `file=$(today --create)`.
- Added `-p`/`--path`: prints today's entry path to stdout without creating
  it, exit 0.
- `templator` no longer `exit 1`s when yesterday's file is missing; it warns
  to stderr and `return 0`s, so a first-ever entry (or a gap in the journal)
  still succeeds.
- `create` now checks the template exists and fails with a clear stderr error
  + exit 1 instead of a silent `cp` failure feeding a broken `templator`.
- Unknown options now print an error to stderr and exit 2 (usage error);
  informational/warning text goes to stderr so stdout stays parseable.
- Fixed a latent bug: the positional DEN-PATH handler had `$${DEN_PATH%/}`,
  which nix renders literally as `$${...}` (bash `$$` = PID). Changed to
  `''${DEN_PATH%/}` so it renders the intended `${DEN_PATH%/}`.
- Documented the stdout contract and exit codes in `usage()`.

**Decisions.** Kept the interactive editor path as the default (no flags) so
human use is unchanged; agent use is opt-in via `--create`/`--path`. Chose to
print the path on both create and path modes (rather than a JSON blob) because
`today` yields a single value; `daily` is where structured output belongs.

**Testing.** Built the real derivation via `lib.evalModules` +
`writeShellApplication` (so build == shellcheck pass) - clean. Ran the rendered
script against a fixture den: `--path` does not create; `--create` prints a
valid path and is idempotent; a first entry with no yesterday succeeds with a
stderr warning; a missing template exits 1; an unknown flag exits 2; the
no-flag default invokes `$EDITOR`.
