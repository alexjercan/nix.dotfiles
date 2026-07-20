# Retro: flow skill umbrella/GOAL lifecycle

## What went well

- Codified the lifecycle in the two places a reader lands (Finish step + GOAL
  artifact section) and cross-referenced them, so the no-records rule is stated
  consistently. Reviewer swept flow/compound/lessons skills and found no
  lingering "umbrella is retro'd" contradiction.
- Verified the actual conformance behavior first (`tatr check -S` flags the two
  prior umbrellas 20260720-152427 / -171807 with closed-missing-review/retro,
  plain check is clean) before writing the doc, rather than asserting from
  memory.

## What went wrong

- The task's own DoD #2 was self-contradictory: it wanted "no RETRO by design"
  AND "tatr check -S clean on a closed umbrella", but `-S` flags exactly the
  missing REVIEW/RETRO. A doc change cannot satisfy `-S`; only a tatr-side
  exemption for `goal`-tagged tasks can. Caught during work by running the
  actual check.

## What to improve next time

- When a task's DoD proof turns out to belong to a different repo/tool, amend
  the proof and scope the dependency out explicitly (done here: DoD now proves
  plain `tatr check` + a doc grep, and names tatr task 20260720-220046 as the
  owner of the `-S` exemption) rather than forcing the proof green locally.

## Action items

- [x] DoD amended and the scoping recorded in TASK.md Notes and here.
- Dependency surfaced: tatr task 20260720-220046 should exempt `goal`-tagged
  tasks from `-S` closed-missing-review/retro so a closed umbrella lints clean.
