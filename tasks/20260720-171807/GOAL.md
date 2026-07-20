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
- [x] 20260720-171843 (bevy-common-systems, 16 findings)
      landed 0ae11b0; 1 round out-of-context APPROVE (1 NIT taken); 16
      findings -> 3 residue tasks (9 boxes); 24 x3+ lessons parked in
      Pending promotions byte-identically
- [x] 20260720-171850 (scufris, 23 findings)
      landed 43e8a87; 1 round out-of-context APPROVE (every changed line
      read, 1 NIT taken); 23 findings -> 4 residue; pre-existing mypy red
      filed as scufris 20260720-174021
- [x] 20260720-171855 (today, 1 finding)
      landed 3e9836a; 1 round out-of-context APPROVE, zero findings; the one
      bad-severity mapped meaning-preservingly; residue: none; pre-existing
      checks.pytest sandbox bug filed as today 20260720-172833
- [x] 20260720-171902 (tatr, 0 findings; ledger to create)
      landed b2455e0; 2 rounds out-of-context APPROVE (R2 covered the
      user-directed docs/ wipe after distillation was verified faithful);
      12-lesson ledger seeded from the seven pre-flow retros; residue: none
- [x] 20260720-171910 (nix.dotfiles, 0 findings; root AGENTS.md to create)
      landed 862589e; 1 round out-of-context APPROVE (1 NIT taken); ledger
      pure-renamed to root, flow/compound skill path mentions generalized,
      repo AGENTS.md created; residue: none

## Manual acceptance (batched for the user at Finish)

- (pending) the per-repo unresolved-checks residue (Unresolved checks
  section below) awaits user rulings.

## Unresolved checks (residue for intervention)

scufris (4 findings, 5 boxes - rulings needed: tick, amend the step, or
leave as permanent record):
- 20260719-223102 step 5: serve smoke/copy-button eyeball never recorded
  (npm ci green is recorded)
- 20260719-223103 step 6: review says a real codex turn was NOT run
  (fake-codex only)
- 20260719-235505 step 3: read_context/read_transcript/read_usage have no
  log calls (only list+delete log)
- 20260720-002621 step 3: "tool events append live chips" shipped as the
  "ran <tool>" status line; chips came later in 122513 (ambiguous)
- 20260720-002621 step 4: no "token cursor/typing affordance" CSS exists

bevy-common-systems (3 findings, 9 boxes - rulings needed):
- 20260704-102342 (5 boxes): task is SUPERSEDED by the 103544/103553/103517
  split; nothing shipped under this id - candidate for an archive-stub
  conversion rather than ticks
- 20260705-140043 (1 box): "re-read the Examples section" has no evidence
  (commit ace3138 touched only Module Map + versions)
- 20260711-094942 (3 boxes): steps annotated "(dropped, premise falsified)"
  in the task body - ticking would misrecord deliberate drops
