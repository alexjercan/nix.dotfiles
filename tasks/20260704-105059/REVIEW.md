# Review: Squash-merge task branches in flow

- TASK: 20260704-105059
- BRANCH: squash-merge

## Round 1

- VERDICT: APPROVE

Docs-only change to `flow/SKILL.md` and `work/SKILL.md`. Verified against the
goal (each APPROVEd task branch should land as a single commit, one-per-task
scope confirmed with the user) and for git correctness.

Checks: no CI/linter/justfile in repo; the relevant gate is nix evaluation.
`nix eval .#homeConfigurations.alex.activationPackage.drvPath` produces a
derivation with the edited skills (skills are verbatim `recursive` file links;
no `.nix` changed). Independently reproduced `git merge --squash` in a scratch
repo: it stages without committing, leaves the branch unmarked as merged (no
merge parent), and `git branch -D` still deletes it - so the instruction text
and the `sprout rm` teardown note are both accurate.

What is right:
- flow step 5 correctly splits the squash merge into `git merge --squash`
  (stages) then `git commit` (single summary), and correctly warns that git
  pre-fills concatenated branch messages to be replaced.
- The teardown parenthetical about `--squash` recording no merge parent is
  accurate and pre-empts a real "branch not merged" worry.
- work step 7 is phrased conditionally ("when `/flow` merges"), so standalone
  `/work` behavior is unchanged - correct, since work never merges.
- Repo grep confirms no other `--no-ff` / merge-strategy reference was left
  stale.

- [x] R1.1 (NIT) home/modules/agents/skills/flow/SKILL.md:50-54 - the rewritten
  step 5 uses "Then `git commit` ..." and later "Then `sprout rm` ...", two
  sentence-initial "Then"s in one paragraph. Optional: change the second to
  "Finally `sprout rm` ..." for flow. Take it or leave it; not blocking.
  - Response: fixed - second "Then" changed to "Finally".
