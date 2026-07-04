# Review: PR-style branch sync before squash-merge

- TASK: 20260704-134842
- BRANCH: feature/pr-style-branch-sync
- VERDICT: APPROVE

## Round 1

Reviewed the diff of `flow/SKILL.md` and `work/SKILL.md` against the
integration branch, plus the surrounding skills for stale references.

### Correctness

- The git sequence is right and matches a scratch-repo dry run: merging the
  local default branch into the feature branch makes the default tip an
  ancestor (`merge-base --is-ancestor` returns 0), and the later
  `git merge --squash <branch>` on the default branch then stages only the
  branch's unique changes and applies with no conflicts. The claim in step 5.4
  ("because the branch already contains the default tip, this applies cleanly")
  is therefore accurate, not hand-waving.
- `<default>` is correctly qualified as the local default branch (not
  `origin/*`) in both skills, consistent with flow's "do not push".
- The up-to-date gate (`merge-base --is-ancestor`) is stated in both skills
  with the same semantics. The duplication is intentional reinforcement, not a
  contradiction.

### Completeness / blast radius

- No other skill needed changing: `/review` diffs `<default>...<branch>`
  (three-dot, merge-base based); after the sync the merge-base is the default
  tip, so the review diff still shows exactly the task's changes. `/compound`
  and the README carry no merge-strategy prose. Grep confirms no stale
  references to the old single-step squash flow.
- `work`'s new section is correctly scoped: it describes branch hygiene and
  explicitly states `/work` does not itself merge into the default branch, so
  standalone `/work` stays correct.

### Findings

- NIT (not blocking): the up-to-date gate is spelled out in both `flow` step 5
  and `work`'s new section. Acceptable as reinforcement since each skill is
  read on its own, but worth keeping an eye on if the wording later drifts
  between the two.

No correctness, consistency, or completeness issues. Approving.
