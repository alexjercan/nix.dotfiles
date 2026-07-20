# Review skill: out-of-context reviewer is the round-1 default

- STATUS: OPEN
- PRIORITY: 95
- TAGS: feature,skills

## Story

As the review phase, I want round 1 of any substantive review produced by a
reviewer with no memory of the implementing session, so the implementer's
assumptions cannot leak into the critique. Evidence: nova-protocol's ledger
recorded `out-of-context-review-pass` 31 times without it ever becoming the
default; scufris approved 44/44 reviews in round 1.

## Steps

- [ ] review SKILL.md step 2: for substantive branches (anything past a
      trivial docs/typo diff) round-1 findings come from an OUT-OF-CONTEXT
      reviewer - a fresh subagent, /code-review, or a separate session whose
      prompt contains only the task id, branch, worktree path and the
      REVIEW.md format, never the implementing conversation. The in-session
      pass supplements: runs the check suite, verifies claims, merges
      findings into the round.
- [ ] Round header gains `- REVIEWER: out-of-context | in-session`; an
      in-session-only round on a substantive branch must say why.
- [ ] Rework the existing blind-spot guideline paragraph: it becomes the
      rationale for the default, not a soft mitigation.
- [ ] flow SKILL.md step 3.4: name the out-of-context default so flow's
      wording matches the review skill.

## Definition of Done

- review SKILL.md defines the default, the REVIEWER field and the carve-out
  (cmd: grep -n "out-of-context" home/modules/agents/skills/review/SKILL.md)
- flow SKILL.md references it (cmd: grep -n "out-of-context" home/modules/agents/skills/flow/SKILL.md)
- manual: the remaining reviews in this flow use the default and the user
  sees the REVIEWER field in committed REVIEW.md files

## Notes

- Phrase the mechanism tool-agnostically ("a reviewer that has not seen this
  session"): Claude Code offers subagents and /code-review; codex/opencode
  sessions also qualify.
