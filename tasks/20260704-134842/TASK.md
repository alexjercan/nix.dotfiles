# PR-style merge: sync feature branch with default before squash-merge

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: feature,docs,skills

## Context

The `/flow` skill (step 5) currently squash-merges an APPROVEd feature branch
straight into the default branch with `git merge --squash <branch>`, without
first bringing the branch up to date with the default branch. In a real
PR-style workflow the branch is updated from the base first (merge the default
branch into the feature branch, resolve conflicts, re-run checks on the
branch), and only once it is up to date does it land on the base. Doing the
sync on the branch keeps conflict resolution and re-verification off the
default branch, where a bad merge would be much harder to unwind.

The user wants agents to: first merge the default branch (master) into the
feature branch, and only when the feature branch is up to date with the
default branch do they squash-merge it back to the default branch.

Two skills are involved. `/flow` owns the merge-back, so it gets the explicit
update-then-squash sequence in step 5. `/work` owns implementing and running
the check suite in the worktree, so it gets a section on syncing the branch
with the default branch (merge default in, resolve conflicts, re-run checks)
that also stands on its own outside flow. Skills live at
`home/modules/agents/skills/<name>/SKILL.md` and install to
`~/.claude/skills/<name>/SKILL.md` via home-manager.

## Steps

- [x] Rewrite `home/modules/agents/skills/flow/SKILL.md` step 5 so that, on
      APPROVE, the agent first brings the feature branch up to date with the
      default branch inside the worktree (merge the default branch into the
      feature branch, resolve conflicts on the branch, re-run the full check
      suite via `/work`'s verify), confirms the default branch tip is now an
      ancestor of the branch, and only then `cd`s back to the main checkout to
      `git merge --squash <branch>` + `git commit` with one clean summary.
      Keep "do not push" and the trailing `sprout rm <feature>`.
- [x] Note in that step why the sync happens on the branch (conflict
      resolution and re-verification stay off the default branch) and that,
      because the branch already contains the default tip, the squash applies
      cleanly with no conflicts on the default branch.
- [x] Update `flow/SKILL.md`'s "Relationship to the Other Skills" closing
      paragraph so the described sequence is update-from-default then
      squash-merge (PR-style), matching step 5.
- [x] Add a "Syncing with the Default Branch" section to
      `home/modules/agents/skills/work/SKILL.md` describing: when the branch
      has fallen behind the default branch, merge the default branch into the
      feature branch in the worktree, resolve conflicts there, and re-run the
      full check suite before the branch is considered ready to merge. Phrase
      it so standalone `/work` (outside flow) is correct too.
- [x] Verify the described git sequence is internally executable end to end
      (merge default into branch, `merge-base --is-ancestor`, squash-merge on
      the default branch applies cleanly) with a scratch-repo dry run.
- [x] Verify the edited skills still evaluate/install via home-manager (or a
      faithful render), so the docs change does not break the module.

## Notes

- The default branch here is local `master`; flow does not push, so "merge the
  default branch into the feature branch" means the local default branch, not
  `origin/*`.
- In today's strictly-sequential flow each task sprouts off the just-updated
  default HEAD, so the branch is usually already current; the sync step makes
  the up-to-date gate explicit and correct for long-running or parallel
  branches rather than relying on that incidental freshness.
- `work` is used standalone too, so its new section must read as generally
  applicable branch hygiene, not as an assertion that flow is always driving.

## Outcome

Rewrote `flow/SKILL.md` step 5 from a single squash-merge into a five-part
PR-style sequence: (1) merge the local default branch into the feature branch
in the worktree, resolving conflicts on the branch; (2) re-run the full check
suite on the updated branch, routing back through `/review` if the merge
changed the work materially; (3) gate on
`git merge-base --is-ancestor <default> <branch>` so only an up-to-date branch
may land; (4) `cd` to the main checkout and `git merge --squash <branch>` +
one clean commit (now conflict-free, since the branch already contains the
default tip); (5) `sprout rm`. Updated the "Relationship to the Other Skills"
paragraph to describe landing PR-style (update-from-default then squash) so it
matches step 5.

Added a "Syncing with the Default Branch" section to `work/SKILL.md`: when the
default branch has moved on, merge it into the feature branch in the worktree,
resolve conflicts there, and re-verify before the branch is considered ready
to merge. Phrased as general branch hygiene `/work` owns, and explicit that
`/work` still does not itself merge into the default branch (that is `/flow`'s
squash-merge step), so standalone `/work` stays correct.

Why this shape: `/flow` owns the merge-back, so the actual land-sequence lives
there; `/work` owns running checks in the worktree, so the sync-and-re-verify
mechanics live there and stand alone. Keeping conflict resolution on the branch
(not the default branch) is the core reason the sync happens before the squash
rather than as part of it - a bad merge on the branch is cheap to redo, a bad
merge on the default branch is not.

Verification: dry-ran the full git sequence in a scratch repo - merging the
default branch into the feature branch makes the default tip an ancestor
(`merge-base --is-ancestor` returns 0), and the subsequent
`git merge --squash` on the default branch stages only the branch's unique
change (the parallel default-branch commit is already present), applies with
no conflicts, and `git branch -D` still deletes the branch afterward. No `.nix`
was touched and skills are verbatim `recursive` file links, so home-manager
evaluation is unaffected (same argument as the prior squash-merge task).

Self-reflection: the risk was documentation-only drift - a stale contradiction
between step 5 and the summary paragraph, or instructions that misstate git's
behavior. Grepped the skills for merge references up front to bound the blast
radius, and ran the scratch-repo dry run before writing the commands rather
than trusting memory (the standing "ground truth beats reasoning" lesson).
Nesting this flow inside a `/sprout` container branch worked but added a
re-sprout when the plan commit landed after the first sprout; next time, commit
the plan onto the integration branch before sprouting the first task.
