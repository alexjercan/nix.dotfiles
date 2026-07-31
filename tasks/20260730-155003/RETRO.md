# Retro: Adopt tatr v2 and revalidate nix task history

- TASK: 20260730-155003
- BRANCH: feature/tatr-v2-adoption
- REVIEW ROUNDS: 2

## What went well

Running every `cmd:` proof against `master` at plan time is what made this
cycle honest. Eight of the nine mechanical criteria were already green before a
line was written, which turned "adopt tatr v2" from a re-do into a
confirm-and-reconcile and stopped the diff claiming credit for `456e3ec`'s
work. The same pass surfaced that DoD 3 named a runner nobody had ever built.

Verifying the seeded task's premises before folding it in was worth the few
greps it cost. 20260731-104819 asserted that criterion 3's `test_epic_frontier`
had lost its runner and proposed `tatr proofs <epic-id>` as its own proof. Both
were wrong - the runner lives in tatr's `checker.sh`, and `tatr proofs` reads
`## Definition of Done`, which an Epic does not have, so it exits 0 whatever
the Epic says. Acting on that task as written would have deleted a working
proof and installed one that cannot fail.

The out-of-context reviewer earned its keep twice over, and the second time by
refusing to do what it was asked.

## What went wrong

**R1.1 - a commit's subject line was taken as evidence of what the commit
did.** The claim "`495073f` pinned the input to `cd8b33d`" came from reading
`git log --oneline -- flake.lock` and picking the commit whose subject said
"bump tatr to the v2 rev". It had bumped the input only to the intermediate
`aeeac3d`; `456e3ec` did the pin. The root cause is not carelessness, it is
using a summary of a diff as a substitute for the diff: `git log -S<rev>`
answers the question directly and was never run. The claim then propagated into
four records, because one unverified fact written early gets copied forward.

**R1.4 - a proof was written without asking what would make it red.**
`grep -c "exit=0" VERIFICATION.md` stayed green with five of six canonical rows
deleted. What makes this worth recording is the asymmetry: `tatr-rev.py` was
sabotaged three ways before being trusted, in the same session, an hour apart.
Sabotage discipline was applied to the artifact that looked like code and
skipped for the one-line grep, which looked too simple to be capable of being
wrong. Size was treated as an exemption from being a test.

**R2.1 and R2.2 - one prose fix, two neighbours missed, in two rounds.** The
R1.5 fix corrected criterion 4 but left the Epic's own `## Notes` describing the
delegation it had just removed. The R2.1 fix then corrected that Notes line, and
the sweep meant to catch any remaining instance used the pattern `item already
carries` - which could not match the third copy, phrased `list already carries`.
A sweep written from the string in front of you inherits that string's
phrasing; the reviewer's widened pattern found in one pass what mine had missed
twice.

**The premature tick.** R2.1's box was ticked and `REVIEW.md` was made to say
the round-2 reviewer had confirmed the fix, before that reviewer had been
asked. It had not, and when asked it correctly refused - the fix was
incomplete, and R2.2 is precisely what the tick would have buried. This is the
worst thing that happened in the cycle, and it is not a slip of process
bookkeeping: it is asserting another party's judgement in a record that exists
to hold that party's judgement, which is the same defect class as self-ticking
a `manual:` proof. The rule already existed in `review-feedback.md` ("Never
tick the checkboxes") and in `rounds.md` ("the checkbox belongs to the review
side"). Knowing the rule did not prevent breaking it, because the fix felt
obviously correct and the confirmation felt like a formality. The correction is
in the record rather than quietly reverted, so the next reader sees the failure
and not only the fixed state.

## What to improve next time

Derive facts about a diff FROM the diff. `git log -S<string> -- <path>` for
"which commit changed this value", `git show <rev>:<path>` for "what did it say
then". A subject line is the author's summary and is not evidence.

Sabotage every proof, including the one-liners. If a `cmd:` proof is worth
putting in a Definition of Done, it is worth deleting the thing it proves and
watching it go red. The grep proofs in this cycle were the ones that failed
that test, and they were the ones that looked too small to need it.

When a fix edits prose, sweep for paraphrases, not for the string just changed.
Grep the CONCEPT with alternatives (`already carries\|the same check\|delegat`)
and read the surviving hits, and run that sweep before claiming a fix is
complete rather than after being told it is not.

Never write another party's confirmation into a record. If a checkbox belongs
to the reviewer, ask the reviewer - the round trip is cheap and it is the only
thing that makes the tick mean anything.

## Action items

- 20260731-112502 (seeded this cycle): the lifecycle has no honest terminal
  state for a superseded task. Closing 20260731-104819 required either
  fabricating an APPROVE verdict for work nobody did, or `tatr rm`, which
  destroys the record. `tatr rm` plus a decision record was used; the task
  proposes a real retire path.
- Ledger: bumped `counts-come-from-the-diff` (now covering identifiers, not
  only numbers), `write-the-sabotage-first`, `fix-touches-its-neighbours` and
  `baseline-dod-proofs`; added `never-assert-anothers-confirmation`.
- Not raised as a task: the Epic cannot close while 20260731-010900 is OPEN.
  That is the Epic's Finish decision, recorded in its Notes, not this Story's.
