# Retro: Add conditional parallel planning and review lanes

- TASK: 20260730-154958
- BRANCH: feature/parallel-lanes
- REVIEW ROUNDS: 3

## What went well

- Writing all eleven fixture cases before a line of prose worked exactly as the
  ledger promises. Each was red for an honest reason (`not-loadable`, `no such
  file`) before the files existed, and the two line-wrap misses surfaced as
  assertion failures rather than as a later reader's doubt.
- A/B sabotage per assertion, not per rule, caught the real defect of this
  cycle. The gate was green and the fixtures looked thorough; only deleting
  `secrets` from a pointer condition showed that a whole class of case was
  unfalsifiable.
- The out-of-context reviewer earned its place for the fifth recorded time. It
  produced R1.2 (a record claiming more than its mechanism proves) and R2.1 (an
  instruction whose input nothing supplies), neither of which the implementing
  session could see, because both are invisible to a reader who already knows
  what the text was meant to say.

## What went wrong

- The first disclosure cases were unfalsifiable. Root cause: I wrote the
  `when:` list as a transcription of the pointer condition I had just authored,
  and never asked what a single token proves. The runner ORs the tokens, so the
  case would have survived deleting any six of the seven triggers. The ledger's
  `narrow-the-guard-to-the-word` says exactly this about `requires:` lists; I
  applied it there and did not carry it across to `when:`.
- Two content assertions failed on their first run for a reason unrelated to
  the rule: the asserted phrase had wrapped across a line break. The matcher
  reads raw text including newlines, so `share the checkout` was absent from a
  file that says it. The same invisible-line-break class bit the first pointer
  I wrote, where only the arrow's own line counts as the condition, so a
  wrapped condition silently lost half its words.
- Rounds 2 and 3 each found a defect introduced by the previous round's fix.
  R1.1's fix told a lane to judge a result the closed handoff never gives it;
  R2.1's fix pinned a timing that a different section still contradicted. Root
  cause: I edited the sentence the finding cited and re-ran the gate, which
  cannot read prose, instead of re-reading every section naming the same actor
  or ordering.

## What to improve next time

- When an assertion format takes a LIST, establish what one element proves
  before writing the list. If the checker ORs them, one element per case.
- Treat a line break as a token the checker can see. Either the matcher
  normalizes whitespace, or the asserted phrase is short enough not to wrap -
  and the fix belongs in the matcher, which is why it is an action item.
- After fixing a review finding in prose, re-read the neighbouring rules that
  share its actor, ordering or handoff, and state what they now imply together.
  The gate cannot do this and neither can a diff.

## Action items

- 20260731-084705: make `content` fixture matching insensitive to line breaks
  in `fixtures/run.sh`, so an assertion cannot be defeated by where the prose
  happens to wrap. Created in this worktree.
- Ledger: new `line-breaks-are-load-bearing` and `fix-touches-its-neighbours`;
  bumped `narrow-the-guard-to-the-word` and `out-of-context-review-pass`.
