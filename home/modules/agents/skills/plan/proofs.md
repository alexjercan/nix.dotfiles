# Definition of Done proofs

Every DoD item ends with one parenthesized proof. `tatr check` validates the
shape; `tatr -r <task-root> proofs <id>` lists it.

- ``(test: `name`)`` - automated test red without the change.
- ``(cmd: `command`)`` - command whose result proves the criterion.
- ``(manual: user judgement)`` - genuinely human confirmation.

Backtick test names/commands. A whole manual criterion stays inside its group.
Move unprovable statements to Notes. Manual checks remain pending through
review/landing and are batched to the user.

## What earns which proof

A `test:` proof requires observable behavior with a failure mode a test can
provoke. Nothing else earns one:

- Documentation, comments, README and skill prose: no test. Where the content
  is load-bearing - a checklist a tool reads, a command someone will paste -
  the proof is a `cmd:` that runs it or greps for it, not a test asserting the
  words exist.
- Examples and prototypes: the proof is that the documented run command works,
  as a `cmd:`. A test wrapping an example tests the example, not the change.
- Renames, moves and internal refactors: the existing suite is the proof. A
  `cmd:` absence search covers the old name; nothing new is written.
- Config, packaging and wiring: a `cmd:` that evaluates or builds it.
- Taste, naming and structure: `manual:`, or nothing. Review reads the diff.

A DoD item whose honest proof is `manual:` gets `manual:`. Inventing a test to
avoid it produces a test that asserts the implementation back to itself, and
that is worse than the unproven line it replaced.

## Test-first contract

Phrase proofs so `work` can encode and watch them fail before implementation.
Pin a bug at its own boundary. A negative result needs a positive delivery
guard proving the stimulus ran. Never end a command in a pipe or `echo`; keep
the producing check's exit code.

## Absence searches

Task history and prose about a removal are valid matches, not stale code.
Exclude `tasks/` and `.git`; scope code by directories/extensions. Where `#`
starts comments, this form can exclude prose:

```markdown
(cmd: `grep -rn --exclude-dir=tasks --exclude-dir=.git --include='*.nix' -E '^[^#]*oldname' .`)
```

Use every relevant extension. `^[^#]*` is invalid for markdown headings or
languages where `#` is data; never invent a `//` version (`^[^/]*` hides paths
and URLs). Scope docs by directory/include, not comment patterns. Cross-check
once with a bare-token search and confirm every dropped hit is prose; otherwise
choose narrower scope/token. Keep one command: a filtering pipe can hide a bad
path as success.

## Sabotage at plan time

For each proof, delete/invert only its pinned clause and confirm that proof
alone turns red while others stay green. Reject a proof already green on the
base branch. This catches patterns matching neighboring prose/code and checks
that never observed the proposed change. Size is no exemption.
