# Definition of Done proofs

Every DoD item ends by naming how it is checked. `tatr check` flags an item
with no proof as `bad-proof-syntax`, and `tatr proofs <id>` prints the proofs
as `<n> <kind> <text>` lines for `work` and `review` to execute.

Put the test name or command in backticks so globs, quotes and stars render
literally.

## The three kinds

- ``(test: `the_test_name`)`` - an automated test that fails without the
  change.
- ``(cmd: `grep -n foo file`)`` - a command whose output shows the criterion
  holds. `work` and `review` run it verbatim.
- ``(manual: <what the user confirms>)`` - a human judgement no test can make.
  When the whole criterion IS the judgement, put the whole sentence inside the
  group and write nothing outside it; the criterion and its proof are one
  thing. All three kinds are parenthesized - `tatr check` scans only for
  `(<kind>: ...)` groups and rejects a bare leading marker as
  `bad-proof-syntax`.

An item with no nameable proof is a red flag. Rephrase it into something
observable, or demote it to a Notes bullet. Do not ship acceptance criteria
nothing can check.

`manual:` is the honest escape hatch for genuinely human calls, not a dumping
ground for "hard to test". Manual items do not block landing; they are batched
to the user at flow's Finish.

## Proofs are the test-first target

`work` writes each `test:` and `cmd:` proof BEFORE the implementation and
watches it fail for the right reason. Phrase every proof so the implementer
can encode it as the first artifact, not reverse-engineer it from finished
code.

## Absence proofs must exclude prose about the code

A repo-wide grep that proves an ABSENCE - no stale references to a renamed
symbol, no leftover TODO - matches talk about the code as readily as the code.
It self-matches the DoD item that quotes the string, and it matches the prose
the same diff writes ABOUT the removal: the comment naming the deleted module,
the NOTE explaining why something is gone. Both are green states reported red,
and the pressure that creates is to reword the prose until the matcher is
happy. Scope BOTH out from the start - `tasks/` by directory, comments by
pattern:

```
(cmd: `grep -rn oldname src/ docs/`)
(cmd: `grep -rn --exclude-dir=tasks --exclude-dir=.git --include='*.<ext>' -E '^[^#]*oldname' .`)
```

`^[^#]*` keeps a hit only where the token appears before any `#`, so
`# NOTE: oldname is gone` and `x = 1; # oldname was here` both drop out. It is
a filter, not a rule:

- It holds only where `#` STARTS a comment, which is why the command carries
  `--include`: fill in every extension the mechanism could live in
  (`*.nix`, `*.sh`), or the search skips the file still referencing it. A
  markdown `# oldname` heading is a real hit the filter hides, and so is a
  line whose earlier `#` sits in a string.
- Cross-check it once with the bare token - same flags, but searching
  `oldname` instead of the pattern - and confirm everything the filter drops
  is prose. Deleting just the `-E` changes nothing: `^[^#]*oldname` means the
  same thing as a BRE. If the cross-check shows a real hit dropped, the
  pattern is wrong for that token: scope by directory and pin the proof on a
  narrower token instead.
- Scope doc trees by directory or `--include`, never by this pattern.
- Do not invent the equivalent for another comment syntax. `^[^/]*` is not the
  `//` form: it stops at the slash in any path or URL, hiding real code.
- Keep it ONE command. A `| grep -v` tail hides a search that ran wrong - a
  mistyped path also exits 1, and reads as absent.

## Proofs must be able to fail

A check that still passes with the mechanism deleted proves nothing. Before
writing a proof, ask what would make it red. In particular:

- A "nothing happens" or "X stays zero" criterion needs a paired delivery
  guard proving the provoking stimulus actually fired. A steady hull and a
  dead engine must not be indistinguishable.
- A bug fix is pinned at its OWN boundary - a test that fails under the bug -
  not only by a downstream end-to-end test.
- Never write a `cmd:` proof that ends in a pipe or an echo. `cargo test |
  grep ...` reports grep's exit code and reads as success on a failed compile.

## Sabotage every proof before accepting it

Asking what would make a proof red is not proving it can go red. Before a proof
enters a Definition of Done, delete or invert the clause it pins and confirm it
goes red ALONE, every other proof still green. Do that at PLAN time, not at
work: a proof that cannot die before a branch exists cannot judge one. Size is
no exemption - a one-line `grep -c` is the shape that has failed twice. Two
failure modes survive running the proof and only the mutation exposes them:

- The proof matches MORE than the clause it pins - a pattern hitting both a
  code fence and the prose beside it stays green after either half is deleted.
- The proof is already green on the base branch, pinning something the change
  does not alter, and it passes plan, work and review having tested nothing.

## Example

```markdown
## Definition of Done

- Requests over the limit get a 429 with a Retry-After header
  (test: `ratelimit_returns_429_when_over_limit`).
- The limit is read from config and its default is documented
  (cmd: `grep -n "req/min" docs/config.md`).
- (manual: under a real burst from one client, other clients' latency stays
  flat).
```
