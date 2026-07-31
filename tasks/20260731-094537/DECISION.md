# Decision: Widen absence-proof grep guidance to exclude prose about the removal

- DATE: 20260731-121542
- STATUS: ACCEPTED
- TASK: 20260731-094537
- TAGS: skills, proofs, lessons

## Context

`plan/proofs.md` tells absence-proving greps to scope away from `tasks/`,
because a repo-wide grep self-matches the DoD item quoting the string. The
`dod-grep-excludes-task-records` ledger entry (x6) says that is only half the
self-match, and 20260730-190929 is the worked example: its DoD grep for `sops`
under `home/alex` went red twice against the diff's OWN prose - first the
comments explaining the new arrangement, then, after the author narrowed the
pattern to declaration syntax, the `NOTE` in `flake/home-configurations.nix`
explaining why the module is absent. The mechanism was gone both times. The
pressure a false red creates is to reword the prose until the matcher is happy,
which inverts the relationship between a proof and the thing it proves.

The ledger proposed a worked form of `| grep -vE ":[0-9]+: *#"`. That form
contradicts `## Proofs must be able to fail` in the same file, twelve lines
above the section being edited: a `cmd:` proof must never end in a pipe,
because the tail command's exit code is the one reported. So WHICH command form
to document was a real open choice, not a transcription.

The user was asked and chose the pipe-free form on 2026-07-31.

## Decision

Widen the section to state that an absence proof must distinguish code from
prose ABOUT the code, and give ONE pipe-free worked command that excludes
commented lines with a pattern rather than a filter stage:

    (cmd: `grep -rn --exclude-dir=tasks -E '^[^#]*oldname' .`)

The guidance also says the `#` in that pattern is language-specific (`^[^/]*`
for `//` languages) and states WHY it is one command rather than a pipeline, so
the reader does not reinvent the rejected form.

The pattern was dry-run in a scratch tree before being written into guidance:
against a file with a leading `# NOTE:` comment and a trailing `# oldname was
here` comment plus a file with the real declarations, it printed only the two
declaration lines, honoured `--exclude-dir=tasks`, and returned rc=1 with no
output once the declarations were removed.

## Alternatives considered

- The ledger's pipeline form, `| grep -vE ":[0-9]+: *#"`, plus an explicit
  carve-out to the no-pipe rule for absence greps. REJECTED: it weakens a rule
  that exists because a pipeline reports the wrong exit code, and it buys
  nothing the pattern form does not already give.
- State the principle only and let each plan author pick a mechanism. REJECTED:
  20260730-190929 shows the author already tried narrowing by hand, and the
  second attempt still matched prose. The principle without a copyable form is
  what the ledger already holds, and it did not hold in practice.
- Retire the lesson instead of promoting it. REJECTED by the user: six
  recurrences of the parent lesson, and the widening costs a handful of words
  in a reference file at half its budget (508 of 1000 words).

## Consequences

- `plan/proofs.md` grows by roughly six lines; its section heading changes from
  "must exclude the records" to cover prose generally, so anything citing that
  heading by name has to be re-pointed.
- The `test: dod_grep_excludes_comments` proof in the task's current DoD has no
  runner: it assumed the content-fixture suite deleted in 20260730-154955. The
  DoD is re-pinned onto a `cmd:` grep over the reference file itself plus the
  structural gate.
- The `dod-grep-excludes-task-records` ledger entry moves out of Pending
  promotions and back to its own section with the applied marker, per
  shrink-on-absorb.
