# Squash-merge task branches in flow

- STATUS: CLOSED
- PRIORITY: 1
- TAGS: feature,docs,skills

## Context

The `/flow` skill currently lands each APPROVEd task branch on the default
branch with `git merge --no-ff <branch>`, which preserves every intermediate
commit plus a merge bubble. The user wants each task/PR to land as a single
commit for the whole feature, i.e. a squash merge. Decision (confirmed with the
user): squash scope is one commit per task branch, not one commit for a whole
multi-task goal.

Only `flow/SKILL.md` issues the merge command; `work/SKILL.md` produces the
branch commits that get squashed and must describe that relationship so the two
skills stay consistent. Skills live at
`home/modules/agents/skills/<name>/SKILL.md` in this repo and are installed to
`~/.claude/skills/<name>/SKILL.md` via home-manager.

## Steps

- [x] Update `home/modules/agents/skills/flow/SKILL.md` step 5: replace
      `git merge --no-ff <branch>` with a squash merge - `git merge --squash
      <branch>` (stages without committing) followed by `git commit` with a
      single clean message describing the finished task, replacing git's
      pre-filled concatenation of branch messages. Keep "do not push" and the
      subsequent `sprout rm <feature>`. State that this yields one commit per
      task on the default branch.
- [x] Update the summary line near the end of `flow/SKILL.md` (the
      "the one thing flow does" paragraph) to say squash-merge as a single
      commit, for consistency.
- [x] Update `work/SKILL.md` step 7 to note that the branch's focused commits
      are working history that `/flow` squashes into a single commit on merge,
      so TASK.md and the squash commit are the durable record - without
      changing work's own "do not merge" behavior.
- [x] Verify `git merge --squash` behaves as documented (stages, does not
      commit, does not require the branch to be merged for later `sprout rm`
      / `git branch -D`).
- [x] Verify the edited skills still build/install via home-manager (or a
      faithful render), so the docs change does not break the module.

## Notes

- `git merge --squash` does not record a merge parent, so the branch is never
  marked "merged"; this is fine because `sprout rm` deletes with `git branch
  -D` (force) and the next task sprouts off the new default-branch HEAD, which
  already contains the squashed commit.
- Work is also used standalone (outside flow), so its note must be phrased as
  "when /flow merges" rather than asserting a squash always happens.

## Outcome

Changed `flow/SKILL.md` step 5 from `git merge --no-ff <branch>` to a two-step
squash merge (`git merge --squash <branch>` then `git commit` with a single
clean summary), and updated the "Relationship to the Other Skills" summary to
match. Updated `work/SKILL.md` step 7 to explain that the branch's focused
commits are review-time working history that `/flow` squashes into one commit,
so TASK.md plus the squash commit are the durable record - phrased
conditionally so standalone `/work` is unaffected.

Why this shape: only `flow` issues the merge, so the behavioral change is one
edit there; `work` gets a consistency note (not a behavior change) so an agent
reading either skill understands why its commit granularity does not survive on
the default branch. Considered squashing the whole multi-task goal into one
commit instead of one-per-task, but confirmed with the user that the scope is
one commit per task/PR.

Verification: reproduced `git merge --squash` in a scratch repo - it stages
without committing, does not mark the branch merged (no merge parent), and
`git branch -D` still deletes it, so the existing `sprout rm` teardown is
unaffected. The home-manager activation package still evaluates to a derivation
with the edited skills (skills are verbatim `recursive` file links, no `.nix`
touched).

Self-reflection: no code, so the risk was documentation drift - a `--no-ff`
reference left behind, or guidance that misstates git's behavior. Grepped the
whole repo for merge-strategy references up front (only one existed) and
verified git's actual `--squash` semantics rather than trusting memory, which
is what the recent retros push for ("ground truth beats reasoning"). Nothing
went wrong. Next time, for a self-referential skill edit like this, it is worth
sanity-checking that the new instructions are internally executable end to end,
which the scratch-repo dry run effectively did.
