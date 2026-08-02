# Retro: afk spinner must never wrap to a second row

- TASK: 20260802-203817
- BRANCH: fix/afk-spinner-wrap
- REVIEW ROUNDS: 1

## What went well

The root cause was measured in scratch before planning, not inferred from
reading the code: `${#}` counting 5 for a 6-column string is what turned "the
truncation might be wrong" into a known defect and let the plan reject the two
plausible-but-worse fixes (per-frame `wcswidth` shell-out, `SIGWINCH` trap) on
stated grounds rather than taste.

The plan also pre-registered its own falsification - "reverting the `spin()`
change alone turns `test_spinner_never_wraps` red while the rest stays green".
Review re-ran that sabotage and a second one against `spin_clear`, and both
behaved as written. A plan that names the experiment that would discredit it
makes review cheap.

## What went wrong

Nothing at the plan or design level. Breadth: the diff is two source files and
stayed inside the stated scope, so there was no missed split. Churn: review
returned APPROVE in round 1 with a single MINOR, so no plan-time question was
missing - neither the from-scratch challenge nor the cold-reader test would
have changed anything. Context: no threshold crossing, compaction warning,
checkpoint, or delegation was recorded, so there is no context lesson to draw.

The one real cost was inside implementation and is recorded in TASK.md
Close-out: the capture parser recognized a spinner erase by EQUALITY, assuming
every spinner write is CR-terminated. Only frames are - `spin_clear` and the
permanent line it makes room for share a chunk - so the autowrap assertions
stayed red against already-correct code. The assumption seemed sound because
frames and erases are emitted by the same pair of functions and look
symmetric in the source; they are not symmetric in the byte stream, because
what follows them differs.

The MINOR from review is the only open item: the `SPIN_MSG` CR/ESC flattening
shipped without a proof. It was hand-verified and is strictly a narrowing, so
it did not block, but it is a behavior change no DoD clause holds down.

## What to improve next time

When a test asserts on a raw terminal byte stream, dump the capture and read
the actual bytes BEFORE writing the parser. The framing of a byte stream is an
empirical question; deriving it from the emitting source reads the writes but
not what surrounds them, which is exactly the part the parser depends on.

When a Step adds hardening beyond the defect under repair, either give it its
own DoD clause or split it out. Bundled unproven changes are how a diff
acquires behavior nobody can later justify from the records.

## Action items

- Seeded follow-up for review finding R1.1: cover the `SPIN_MSG` CR/ESC
  flattening with a test, or record why it stays unproven.
