# Goal: harden the flow skill surfaces and clear the ledger/retro backlog in nix.dotfiles

- DATE: 20260720
- UMBRELLA TASK: 20260720-220955
- LANDING SCOPE: squash-merge each task to local master; do NOT push (user's call). Skill edits are a doc surface deployed to all repos - keep them generic.

## Goal

nix.dotfiles is the source of the flow-family skills (home/modules/agents/skills/)
and the LESSONS.md ledger. This run closes the six flow-improvement tasks filed
after the cross-project flow review: three skill/doc-surface fixes (DoD-grep
template, reviewer severity constraint, umbrella lifecycle), one shared-policy
doc (task-history immutability), and two ledger/retro-backlog cleanups
(promote 3 pending lessons, mark pre-flow tasks historical). The net effect is
that the recurring cross-repo failures the review surfaced are absorbed by
tooling/templates instead of prose, and this repo's own conformance is clean.

## Done means

1. plan skill emits DoD grep proofs that exclude tasks/ by default (manual: inspect a freshly-planned task's proofs; skill text generic)
2. review skill constrains reviewer severities to BLOCKER|MAJOR|MINOR|NIT (manual: inspect reviewer prompt)
3. flow skill documents the umbrella/GOAL lifecycle incl. no-RETRO-by-design (manual: read the new section)
4. a written cross-repo task-history immutability policy exists (manual: read the policy)
5. the 3 x3+ pending lessons are annotated promoted or retired (cmd: `tatr check --ledger LESSONS.md`)
6. pre-flow Jul-3/4 tasks no longer flag under strict check (cmd: `tatr check -S`)

Overall: `tatr check --ledger LESSONS.md` clean; `nix flake check --no-build` green; skill edits generic (no nix.dotfiles-local paths).

## Tasks

- [x] 20260720-220044 (p90) plan skill: DoD-grep proof template excludes tasks/
      landed c4ef5c5; 1 review round (APPROVE, no findings); REVIEW.md was lost
      with the worktree and reconstructed - fix applied forward (commit REVIEW on branch).
- [x] 20260720-220057 (p85) review skill: constrain reviewer to canonical severities
      landed f6072ba; 1 review round (APPROVE, no findings); REVIEW.md committed
      on branch pre-land (lesson applied) - clean auto-removal.
- [x] 20260720-220111 (p60) flow skill: codify umbrella/GOAL lifecycle
      landed cfa41c2; 1 review round (APPROVE, no findings); DoD #2 amended
      during work (the -S exemption belongs to tatr task 20260720-220046).
- [x] 20260720-220121 (p55) flow docs: cross-repo task-history immutability policy
      landed 7b9729b; 1 review round (APPROVE, no findings); policy in work +
      flow skills, reinforces 220044's tasks/-exclusion.
- [x] 20260720-220130 (p50) lessons: resolve 3 pending promotions
      landed 1a0f25d; 1 review round (APPROVE, no findings); dod-grep + edit-worktree
      + dry-run promoted into plan/work skills; Pending promotions now empty.
- [ ] 20260720-220137 (p30) retro-completeness: mark pre-flow tasks historical
      DEFERRED - blocked on tatr task 20260720-220046 (the historical/no-retro
      marker in `tatr check`). Cannot be done by a nix.dotfiles change alone;
      done-criterion 6 (`tatr check -S` clean) needs that mechanism first.
      Left OPEN as a legitimately-queued task, not abandoned.

## Manual acceptance (batched for the user at Finish)

The five landed tasks were doc-surface edits to the flow-family skills; each
`manual:` DoD item ("reviewer reads the section", "inspect the reviewer prompt",
"confirm no repo-local paths") was checked by that task's out-of-context
reviewer. Remaining user-facing acceptance:

- (pending) 20260720-220044..220130: skim the five skill/ledger diffs on master
  (c4ef5c5, f6072ba, cfa41c2, 7b9729b, 1a0f25d) and confirm the new guidance
  reads the way you want the flow to behave going forward.
- (pending) 20260720-220137: decide whether to keep this umbrella OPEN until
  tatr task 20260720-220046 lands, or close it now with criterion 6 recorded
  as deferred.

## Deferred done-definition

6. pre-flow Jul-3/4 tasks pass `tatr check -S` - DEFERRED to tatr task
   20260720-220046 (external dependency). Criteria 1-5 met; overall green bar
   (nix flake check, tatr check --ledger) holds.
