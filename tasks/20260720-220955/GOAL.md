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

- [ ] 20260720-220044 (p90) plan skill: DoD-grep proof template excludes tasks/
- [ ] 20260720-220057 (p85) review skill: constrain reviewer to canonical severities
- [ ] 20260720-220111 (p60) flow skill: codify umbrella/GOAL lifecycle
- [ ] 20260720-220121 (p55) flow docs: cross-repo task-history immutability policy
- [ ] 20260720-220130 (p50) lessons: resolve 3 pending promotions
- [ ] 20260720-220137 (p30) retro-completeness: mark pre-flow tasks historical

## Manual acceptance (batched for the user at Finish)

Accumulates `manual:` DoD items as tasks land; presented at Finish.
