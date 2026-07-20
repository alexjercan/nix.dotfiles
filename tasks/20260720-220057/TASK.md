# review skill: constrain reviewer to BLOCKER|MAJOR|MINOR|NIT

- STATUS: OPEN
- PRIORITY: 85
- TAGS: feature,flow

## Story

As a flow user, I want the review skill to constrain its out-of-context
reviewer to the four canonical severities (BLOCKER, MAJOR, MINOR, NIT), so that
reviewers stop emitting LOW/INFO/OBSERVATION which then fail `tatr check`'s
`bad-severity` rule after the task has landed. Seen in scufris and bevy.

## Steps

- [ ] Find the reviewer prompt/instructions in the review skill under home/modules/agents/skills/.
- [ ] Constrain the severity vocabulary explicitly to BLOCKER|MAJOR|MINOR|NIT, and instruct that verification notes go as plain prose (not `- [ ] Rn.n (SEVERITY)` checkbox syntax).
- [ ] Optionally add a remap/normalize step before REVIEW.md is written.
- [ ] Deploy and confirm the skill text renders after rebuild.

## Definition of Done

- A review run cannot produce a severity outside the canonical four (manual: inspect reviewer prompt; spot-check a review).
- `tatr check` `bad-severity` no longer triggers on freshly reviewed tasks (cmd: `tatr check` clean on a new review).

## Notes

- Keep generic; this is a skill doc surface deployed to all repos.
