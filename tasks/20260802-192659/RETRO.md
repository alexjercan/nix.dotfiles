# Retro: afk: show the session's context token count, colored by budget

- TASK: 20260802-192659
- BRANCH: feature/afk-session-token-meter
- REVIEW ROUNDS: 2

## What went well

The band test harness. A `DONE` marker on a task with no sprout worktree is
the runner's cheapest clean exit, so each color band costs one fake session on
a pty instead of a four-invocation cycle - five boundaries tested for the
price of one full-cycle test.

Splitting the fixture's token total across all four `usage` fields with
distinct small values (`total-6`, 1, 2, 3) means a parser that drops a field
prints a visibly wrong number, so `not str_contains "$out" "57.5K"` is a real
assertion rather than a shape check.

Adding `usage` to the shared `reply` fixture rather than only to new fixtures
made every pre-existing test exercise the new line for free, which is how the
off-a-TTY and spinner assertions came cheap.

## What went wrong

R1.1 (MAJOR): the count printed only on `run_claude`'s success path, so all
four `die`s threw it away - including the heartbeat kill, which is afk's own
stall detector and the exact scenario the Story opens with.

The root cause is in the plan, not the implementation. The Step said "after
the terminal result, print the `tokens` line", and the implementation did
literally that. The plan wrote down one exit because that is the one the
Target output block shows; nothing made it enumerate the others.

The from-scratch challenge would not have caught it - the design was right.
The cold-reader rationale test in `plan/decision.md` would have: DECISION.md
argues for the `assistant` event over the `result` event precisely because "a
killed session would report nothing", and then the Steps placed the print
where a killed session reports nothing anyway. The decision and the step
contradicted each other on the page and nobody read them against each other.

## What to improve next time

When a plan Step places an output or side effect at one point in a function
that has several exits, the Step should name the exits it covers. "Print X
after the terminal result" is a location; "print X on every exit from
`run_claude`" is a requirement.

Read DECISION.md's rejected alternatives against the Steps before approving a
plan. A rejection reason ("that option loses the count on a killed session")
is a requirement in disguise, and here it was already written down one file
away from the step that violated it.

The last Step asked for "one real `afk run <id>` sanity read" and got a live
`claude -p --output-format stream-json` probe instead - defensible, since a
nested `afk run` spends real quota, and recorded in the step. But the plan
should have asked for what it actually wanted: a probe confirming the `usage`
field shape. An unrunnable step invites a substitution, and a substitution is
only honest when someone reads the step afterwards.

Breadth: two script files, one feature, no split available - the test and the
implementation are the same change. Nothing to separate.

Context: no pressure observed. No compaction warning, no checkpoint, no
delegation. Round 2 ran in a fresh `/flow` session by design (the
out-of-context reviewer), not because anything was full.

## Action items

- None. The two improvements above are plan-review habits, submitted to the
  knowledge repository rather than tracked as work here.
