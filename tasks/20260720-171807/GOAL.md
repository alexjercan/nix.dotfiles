# Goal: flow-v2 adoption across six repos

- DATE: 20260720
- UMBRELLA TASK: 20260720-171807
- LANDING SCOPE: each repo's migration branch squash-merges to that repo's
  master via sprout land; no pushes anywhere (user's call at the end).

## Goal

Every repo in ~/personal that uses the flow (nova-protocol,
bevy-common-systems, nix.dotfiles, tatr, today, scufris) follows the v2
conventions: the lessons ledger lives at the repo root as LESSONS.md, the
task backlog lints clean under tatr check (best-effort fixes, residue
surfaced for intervention), and AGENTS.md directs development through /flow
and its skills.

## Done means

1. LESSONS.md at each repo's root, docs/ copy gone, references updated
   (cmd: per-repo test -f LESSONS.md && ! test -f docs/LESSONS.md).
2. tatr check exit 0 in each repo, or the residue is listed in this file's
   Unresolved checks section (cmd: /home/alex/personal/tatr/tatr check per
   repo; manual: user rules on the residue).
3. Each ledger lints clean (cmd: tatr check --ledger LESSONS.md per repo).
4. Each AGENTS.md names /flow and LESSONS.md (cmd: grep per repo).
5. Each repo's own check suite still green after the migration
   (cmd: repo-specific, recorded per task).

## Tasks

- [ ] 20260720-171836 (nova-protocol, 89 findings at scout time)
- [ ] 20260720-171843 (bevy-common-systems, 16 findings)
- [ ] 20260720-171850 (scufris, 23 findings)
- [x] 20260720-171855 (today, 1 finding)
      landed 3e9836a; 1 round out-of-context APPROVE, zero findings; the one
      bad-severity mapped meaning-preservingly; residue: none; pre-existing
      checks.pytest sandbox bug filed as today 20260720-172833
- [ ] 20260720-171902 (tatr, 0 findings; ledger to create)
- [ ] 20260720-171910 (nix.dotfiles, 0 findings; root AGENTS.md to create)

## Manual acceptance (batched for the user at Finish)

- (pending) the per-repo unresolved-checks residue (Unresolved checks
  section below) awaits user rulings.

## Unresolved checks (residue for intervention)

(filled per repo as tasks land)
