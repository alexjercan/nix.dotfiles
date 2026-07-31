# Retro: Add tatr-native wayfinding, web research, and retained prototypes

- TASK: 20260730-142540
- BRANCH: feature/wayfinding-research-prototypes
- REVIEW ROUNDS: 2

## What went well

Writing the five fixtures before the prose worked exactly as intended: each
went red naming a missing element, and the prose was written to satisfy a
stated criterion rather than the criterion being written to match finished
prose. The reviewer independently mutation-tested all five and each still went
red for its own element.

The plan's leading step was the right one. Noticing at plan time that the gate
prints nothing per passing case - so no criterion could be a `cmd:` proof -
turned an unprovable DoD into seven runnable commands before any prose existed.

## What went wrong

Two of the six round-1 findings were holes in the mechanism this task exists
to build, and both share a root cause: the content fixture kind was designed
from the cases I was about to write, not from the cases someone could write.
A vacuous case (no `requires:`, no `forbids:`) printed `ok`, and `section_of`
matched `##` headings inside fenced code blocks, so an illustrative template
could satisfy a criterion. Neither could occur in the five cases I wrote, so
neither was visible from them. A new checker needs an adversarial pass over
its INPUT FORMAT - what is the emptiest, most degenerate case this accepts,
and does it still print ok - and that pass is separate from proving each rule
can fire, which `--self-test` already covered.

R1.1 is the same shape one level down: the pointer condition named the branch
only via the target filename, and `spike-research.fixture`'s `when:` list was
broad enough that no single word was load-bearing. The fixture passed for a
reason unrelated to the clause it was supposed to guard.

R1.6/R2.1 was a plain arithmetic failure: the close-out's diff numbers were
read before the close-out itself was appended, then the correction mixed a
post-fix file count with pre-fix line counts. `counts-come-from-the-diff` was
already in the ledger and was still got wrong, because the count was taken at
the wrong MOMENT rather than from the wrong source.

## What to improve next time

- When adding a fixture kind, an assertion format or any input-driven checker,
  write the degenerate case first: empty, missing keys, and a match satisfied
  by decoration rather than content. Only then write the real cases.
- A fixture whose `when:`/`requires:` list has several alternatives proves only
  that ONE of them held. When a specific word is the thing being guarded,
  narrow the list to that word and move the rest to a case that asserts them
  directly - which is what `spike-research` plus `spike_mode_router` now do.
- Take a diff count AFTER the last edit to the file that quotes it, or cite it
  by commit range so it stops being a moving target.

## Action items

- None requiring code. The two mechanism holes were fixed in round 1 and are
  covered by the fence-aware `section_of`, the vacuous-case guard, and their
  self-test sabotage cases.
- The parent Epic 20260730-153122 now carries the manual acceptance item this
  task's DECISION.md created; it is the user's to run, not a follow-up task.
