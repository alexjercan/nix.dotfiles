# Retro: cross-repo task-history immutability policy

## What went well

- Placed the policy where the action happens (work skill's DOC-SURFACE SWEEP
  step) and cross-referenced it from the flow skill's trail guideline, so both
  a task-worker and a flow-driver hit it. Reviewer confirmed the two surfaces
  are mutually consistent and reinforce (not contradict) the plan skill's
  existing tasks/-exclusion guidance from task 20260720-220044.
- Resolved the concrete v2-wave divergence (nova rewrote history, nix.dotfiles
  did not) with an explicit ruling: verbatim is the policy. Kept the example a
  parenthetical so the rule stays generic.

## What went wrong

- Nothing material. One-round clean landing.

## What to improve next time

- This task and 20260720-220044 shared one underlying tension (task records
  self-matching greps); doing 220044 first meant this one could just point at
  it rather than re-explain. Sequencing dependent doc tasks by their shared
  root paid off.

## Action items

- [x] Policy stated in work + flow skills; DoD proof pins both surfaces.
