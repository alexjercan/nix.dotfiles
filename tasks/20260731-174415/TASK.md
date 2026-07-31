# Turn review and context overruns into planning lessons

- STATUS: CLOSED
- PRIORITY: 75
- TAGS: skills, compound, lessons, docs, flow
- KIND: STORY
- FLOW STEP: DONE
- PLAN STATUS: APPROVED
- PARENT: 20260731-174333
- DEPENDS ON: 20260731-142000, 20260731-174348

## Story

As a compound agent, I want reviews and worker checkpoints mined for planning
failures, so oversized diffs, structural rework, and context overruns improve
the next plan instead of ending as isolated implementation pain.

## Steps

- [x] Update `home/modules/agents/skills/compound/SKILL.md` to compare the
      original Story/Steps with the final diff, branch log, all review rounds,
      `Process signal:` observations, and recorded worker checkpoints.
- [x] For unexpected breadth, ask why the diff grew: inherently large feature,
      missed independently landable split, weak ownership boundary, scope
      discovered late, or a plan that encoded the wrong design.
- [x] For structural review churn, identify which from-scratch or cold-reader
      question at plan time would have prevented the rework. Name the failed
      decision and why it seemed sound then; do not blame the worker.
- [x] For context pressure, record only measured or explicitly observed facts:
      threshold crossing, compaction warning, handoff, delegation, and what
      should be split, delegated, deferred, or loaded later next time. Never
      invent token counts absent from task records.
- [x] Keep code findings in REVIEW, change facts in TASK, one-off process detail
      in RETRO, and only recurring general lessons in LESSONS.md.
- [x] Preserve the compound body budget, ledger ownership, and landing order.
      Run all canonical checks.

## Definition of Done

- Compound explicitly asks why the diff grew, whether a split was missed, and
  how the plan caused structural review churn (cmd: `rg -q 'why the diff grew' home/modules/agents/skills/compound && rg -q 'a missed split that' home/modules/agents/skills/compound && rg -q 'which plan-time question would have prevented' home/modules/agents/skills/compound`).
- Compound audits context-budget evidence without inventing unavailable token
  counts (cmd: `rg -q 'measured or observed context pressure' home/modules/agents/skills/compound && rg -q 'Never invent a token count' home/modules/agents/skills/compound`).
- Record ownership remains unambiguous (manual: fresh reviewer confirms REVIEW
  owns findings, TASK owns change facts, RETRO owns one-off process analysis,
  and LESSONS owns recurring general lessons).
- The skill suite remains conformant and within all measured budgets (cmd:
  `rg -q 'why the diff grew' home/modules/agents/skills/compound && bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `rg -q 'why the diff grew' home/modules/agents/skills/compound && tatr check && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- Depends on the review task for `Process signal:` format and the work task for
  durable checkpoint evidence.
- Large PRs are red flags to diagnose, not automatic proof of a bad plan. The
  retro must distinguish indivisible feature size from avoidable task breadth.

## Close-out

What/why: compound now diagnoses the plan, not just the implementation.
Workflow step 2 reads `Process signal:` bullets and recorded checkpoints
alongside TASK.md and the review rounds, and compares the original Story and
Steps against the final diff. A new `## Diagnose` section asks three questions
answerable only from the records: why the diff grew (inherently large feature,
a missed independently landable split, a weak ownership boundary, scope found
late, or a plan that encoded the wrong design); which plan-time question would
have prevented the review rework; and what context pressure was actually
measured or observed. Record ownership is stated once, in the header line that
already owned it: RETRO takes one-off process, LESSONS recurring lessons, TASK
the change, REVIEW the findings.

Alternatives: a conditional `diagnose.md` reference was rejected. Compound has
no references at all, its body had 189 words spare, and the diagnosis runs on
every retro - a reference read every time is not progressive disclosure. This
is the same call 20260731-174343 made against a `sizing.md`.

Difficulties: two proofs were unfalsifiable as planned and were tightened
before implementation. `rg -q 'context'` failed on the shipped text for a
mundane reason - the only occurrence was the capitalised `Context:` label -
and `rg -q 'invent|recorded'` survived deleting `Never invent` entirely,
because `recorded` still matched `recorded checkpoints` two sections away. An
OR proves only that ONE branch held (`narrow-the-guard-to-the-word`), so both
were replaced with the literal rule text they guard.

The restatement sweep then caught a duplication I had introduced myself: the
`Churn` bullet repeated "Name the failed decision and why it seemed sound
then" verbatim from workflow step 3, which owns RETRO writing. The bullet now
carries only the half step 3 does not - that the plan, never the worker, is
the subject.

Evidence: all six planned conjuncts were red at base. Every conjunct of the
final proofs was sabotaged individually and turned its proof red:
`why the diff grew`, `a missed split that`, the plan-time-question clause,
`measured or observed context pressure`, `Never invent a token count`.
`check.sh` clean (9 skills, 22 rules); `sprout-test.sh` 14/14; `tatr check`
and `tatr check --ledger LESSONS.md` exit 0; `nix flake check` all checks
passed. Budget after the round-1 fixes: `compound/SKILL.md` body 361/400 -
the MAJOR fix deleted more than the other fixes added.

Reflection: this Story consumed the `Process signal:` format from
20260731-142000 and the checkpoint record from 20260731-174348, which is the
dependency the Epic declared. The producer-with-no-consumer finding raised in
20260731-142000's round 1 is now closed by this diff.
