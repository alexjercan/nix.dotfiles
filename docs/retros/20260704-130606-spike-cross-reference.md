# Retro: Cross-reference spike into the plan, flow and tatr lifecycle

- TASK: 20260704-130606
- BRANCH: spike-skill (flow's integration branch; not squash-merged to master)
- REVIEW ROUNDS: 1 (APPROVE)

See `tasks/20260704-130606/{TASK,REVIEW}.md`. Process notes only.

## What went well

- The dependency ordering paid off exactly as planned: task 1 settled the
  spike/plan boundary (the coarse-task model) before this task referenced it,
  so all three cross-references could state one consistent model instead of
  three subtly different ones. Sequencing the cross-ref task after the skill
  it points at was the right call.
- Grepped for the canonical lifecycle phrasing first ("tatr tracks, `/plan`
  scopes ..." in flow, "plan-work-review-compound cycle" in tatr) and extended
  the existing sentences in place, rather than bolting on new sections. Kept
  the edits additive and small, as the precedent commit 841bff5 did.
- Read the actual diff before approving, which is what caught the one real
  defect.

## What went wrong

- The flow insertion left an uneven line wrap ("...sprouting a" / "worktree"
  on a stubby line) - review R1.1. Root cause: I edited by replacing a
  sentence mid-paragraph without re-flowing the surrounding lines, so the old
  line breaks stayed frozen around the new text. Caught in review and fixed
  the same round.

## What to improve next time

- After an in-place prose edit that changes a sentence's length, re-read the
  whole surrounding paragraph and re-wrap it, not just the changed sentence.
  A mid-paragraph Edit freezes the neighbouring line breaks, which is exactly
  how the stubby line appeared. Cheap to check, cheap to fix, easy to miss.

## Action items

- [x] Closed R1.2 from task 20260704-130605 - flow (and plan, tatr) now name
      spike, so the front-of-lifecycle claim is true from both sides.
- [ ] None outstanding. The two-task goal (spike skill + its lifecycle
      cross-references) is delivered.
