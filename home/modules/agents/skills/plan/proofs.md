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

## Absence proofs must exclude the records

A repo-wide grep that proves an ABSENCE - no stale references to a renamed
symbol, no leftover TODO - self-matches the DoD item that quotes the string,
and can never go green. The `tasks/` tree is append-only history, not a doc
surface, so scope the grep away from it from the start:

```
(cmd: `grep -rn oldname src/ docs/`)
(cmd: `grep -rn --exclude-dir=tasks oldname .`)
```

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
