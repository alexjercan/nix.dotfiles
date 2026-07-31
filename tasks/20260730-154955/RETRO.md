# Retro: Integrate guarded flow lifecycle and lesson decisions

- TASK: 20260730-154955
- BRANCH: feature/guarded-flow-lifecycle
- REVIEW ROUNDS: 4

29 findings: 4 BLOCKER, 4 MAJOR, 16 MINOR, 5 NIT. That is the largest count
this ledger has recorded, and the shape is the interesting part: every BLOCKER
was in something I had already declared verified.

## What went well

The plan's grep sweep. Reading the tree before planning turned a Story that
read as a large migration into a small one plus a regression guard, and put
that in the Notes rather than discovering it mid-build. `tatr flow` had been
the only writer of the lifecycle markers since 20260730-142533; only
`lessons/ledger.md` was actually stale. Planning from the system instead of
from the Story's wording is what made the task small.

Three review lanes on a diff that is mostly prose. It looked like overkill for
a docs change and was not: the correctness lane found a regex precedence bug
by testing the pattern in isolation, the design lane found the same exemption
hole by measuring it against the whole corpus (17 of 39 sentences), and the
behavior lane found a false number in my own close-out. One reviewer would
have found perhaps one of the three, because each needed a different mode of
attack.

Running the base-branch proofs at plan time. `tatr check --ledger` was already
red on master with exactly the two findings this task would fix, which is what
made it a criterion rather than decoration.

## What went wrong

**The gate I built was broken in both directions, and its own self-test said
it was fine.** `direct-state-edit` passed five hand-written sabotages while
being blind to 17 of 39 real marker sentences and flagging ordinary
descriptive prose. Root cause: I wrote the sabotage cases and the rule in the
same sitting, so the cases inherited the rule's assumptions - each one used
phrasing the rule already handled. `write-the-sabotage-first` was followed to
the letter and still failed, because writing the sabotage first does not help
when the same mind writes both and never asks what it flags WRONGLY. The
suite had no way to express "this must stay clean" until round 1 forced
`expect_clean` into existence.

**The exemption inverted the rule.** `EXEMPT_RE` matched a bare `tatr` or
`never` anywhere in the sentence, so "if `tatr flow` is unavailable, set FLOW
STEP by hand" - the single likeliest real violation - was exempt. It seemed
right because the sentences I checked it against were the CORRECT ones in the
tree, where `tatr` genuinely is the subject. I never wrote the sentence a
future author would write.

**`counts-come-from-the-diff` recurred three times in one close-out, twice
after I had promoted it.** 496 and 593 were read before the block quoting them
was finished. Then 462/1035 came from `git diff --cached --shortstat`, which
measures the index against the previous commit, not the branch against its
base - a different question returning a plausible-looking answer, which is why
re-reading did not catch it. Even the corrected 78/1188/929 was invalidated by
committing the review round that verified it. The failure is not carelessness;
it is that the number and the text quoting it live in the same file, so the
act of recording changes what is recorded.

**I filed R2.1 against my own work and then fixed it, which is the review
process eating its own tail.** Removing the fixtures on request left `RULES`
as an unverified claim. Writing that as a finding was right, but I should have
seen it while making the removal, not after.

## What to improve next time

Write the false-positive case before the rule, not after a reviewer asks. For
any checker, the first two artifacts are one input that must fire and one that
must stay silent. A suite that can only express "this fires" will pass a rule
that flags everything.

When a checker exempts something, write the sentence an adversary would use to
exploit the exemption, and put it in the suite. Key exemptions on a token's
ROLE, never its presence.

Choose a recorded measurement that survives being recorded. The diff stat only
became stable when scoped to exclude `tasks/`, because appending the review
round moves any figure that counts task records. Prefer a number the act of
writing it cannot change; if none exists, say which command produced it so a
reader can re-derive rather than trust.

## Action items

- `counts-come-from-the-diff` is at x5 and PROMOTEd to 20260731-094524
  (`tatr stat`). Five occurrences and three of them inside the close-out that
  narrates the lesson is the strongest case in this ledger that prose cannot
  hold a MOMENT-shaped failure.
- Two new lessons recorded: `test-the-quiet-direction` and
  `exempt-on-structure-not-on-a-token`.
- 20260731-104819 tracks the Epic's Done Means, which still name proofs the
  fixture removal left without a runner. It must land before the Epic Finish.
- Open for the user: DoD item 6, the `manual:` read of the three files that
  share the disposition gate.
