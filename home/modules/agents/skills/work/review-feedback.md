# Addressing review feedback

Read this when `review` left a `tasks/<id>/REVIEW.md` with a
`- VERDICT: REQUEST_CHANGES`. Addressing it is `work`'s job.

## 1. Stay on the branch

Same worktree, same feature branch. `tatr flow <id> --to WORKING` moves the
task back from REVIEWING; that edge exists precisely for this loop.

## 2. Answer every open finding

Read the LATEST round only. For each finding whose checkbox is not ticked,
either:

- fix it, and write `Response: fixed in <commit>` on its Response line; or
- push back with concrete reasoning on the Response line, if you believe the
  finding is wrong.

Reasoned pushback is legitimate. "I disagree" is not - name the code, the
test, or the constraint that makes the finding wrong.

## 3. Never tick the checkboxes

The checkboxes belong to the review side. Whoever the round's `- REVIEWER:`
line names verifies the fix before its box is ticked. Ticking your own
findings is the review equivalent of self-ticking a `manual:` proof.

## 4. Re-verify and hand back

Re-run the whole verification (`verify.md`), including every proof, not just
the tests near the fixes. A finding's fix has broken a neighbour before.

Commit the code AND the updated REVIEW.md together, then `tatr flow <id>` to
REVIEWING for the next round.

## 5. When the dispute will not resolve

If the same finding is still open after three rounds, stop and surface the
disagreement to the user with both positions stated plainly. Do not keep
cycling, and do not concede a point you believe is wrong just to converge.

## 6. Findings that are not this branch's problem

A finding about a pre-existing problem the diff did not introduce becomes a
new tatr task, created in this worktree, and its Response line names that task
ID. It is not fixed here and it does not block the verdict.
