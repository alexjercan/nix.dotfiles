# Review

## Review round 1 (out-of-context reviewer)

What I tried to break: whether the new plan-skill guidance is correct, generic,
and placed where a plan-writer actually reads it; whether the example commands
do what the prose claims; and whether the rule and its examples agree.

Verification notes (plain prose, not findings): the change adds guidance to the
`(cmd: ...)` DoD-proof bullet in home/modules/agents/skills/plan/SKILL.md
telling authors that an absence-proving repo-wide grep must exclude the `tasks/`
tree, since the task record and the DoD item itself quote the searched string
and would self-match. The guidance is generic (placeholder `oldname`,
`src/ docs/`, no nix.dotfiles-local paths); the two examples agree with the rule
(positive scoping and explicit `--exclude-dir=tasks` both prevent self-match);
it is placed exactly where a proof-author reads it; markdown fencing matches the
surrounding bullets. Reproduced `--exclude-dir=tasks` in a scratch dir: it drops
the tasks/ record while keeping the code match, so the example does what the
prose claims. The rule is correctly limited to absence greps; nothing overclaimed.

- No findings.
- VERDICT: APPROVE

Note: this REVIEW.md was reconstructed in the main checkout after landing - the
reviewer wrote it in the worktree but it was untracked and removed with the
worktree by `sprout land`. Recorded as a lesson in RETRO.md.
