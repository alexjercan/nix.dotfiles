# Definition of Done proofs

Every DoD item ends with one parenthesized proof. `tatr check` validates the
shape; `tatr proofs <id>` lists it.

- ``(test: `name`)`` - automated test red without the change.
- ``(cmd: `command`)`` - command whose result proves the criterion.
- ``(manual: user judgement)`` - genuinely human confirmation.

Backtick test names/commands. A whole manual criterion stays inside its group.
Move unprovable statements to Notes. Manual checks remain pending through
review/landing and are batched to the user.

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
