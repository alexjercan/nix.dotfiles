# Make avoidable complexity block review approval

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: skills, review, lessons, docs, flow
- KIND: STORY
- FLOW STEP: DONE
- PLAN STATUS: APPROVED
- PARENT: 20260731-174333

## Story

As a flow reviewer, I want the applicable `AGENTS.md` simplicity bar enforced
as an approval criterion, so behaviorally correct code cannot land with
avoidable spaghetti, speculative structure, or control flow a cold reader
cannot follow.

## Steps

- [x] Update `review/SKILL.md` and `review/dimensions.md` so applicable
      `AGENTS.md` files are part of the spec and correctness/evidence remain the
      first review obligation.
- [x] Make avoidable structural complexity a MAJOR approval blocker: scattered
      special cases, unnecessary modes/branches/wrappers/options, wrong
      ownership, or a flow a cold reader cannot follow.
- [x] Add the counterfactual question: knowing the current constraints, would
      we implement this route from scratch? Require any alternative to preserve
      behavior and name the concepts, branches, or indirection it deletes;
      reject subjective or speculative rewrites as invented nits.
- [x] Treat file/diff size as a cohesion and planning trigger, not a universal
      line-count verdict. Record unexpected scope, missed task splits, and
      review-driven restructuring as plain `Process signal:` observations for
      compound, separate from code findings.
- [x] Preserve the promoted neighboring-contract rule: for prose/contract
      edits, re-read neighboring rules and sweep changed concepts plus
      cross-references.
- [x] Keep the review body/reference budgets and every existing correctness,
      spec, test, docs, honesty, fresh-context, and round-ownership rule.
- [x] Run the skill gate, task/ledger checks, and full flake checks.
- [x] After landing, use the lessons workflow to finish the recorded
      `fix-touches-its-neighbours` promotion.

## Definition of Done

- The active review instructions explicitly cover applicable `AGENTS.md`, the
  from-scratch counterfactual, and process signals (cmd: `rg -q 'applicable .*AGENTS.md' home/modules/agents/skills/review/dimensions.md && rg -q 'AGENTS.md. files are the spec' home/modules/agents/skills/review/SKILL.md && rg -q 'from scratch' home/modules/agents/skills/review/SKILL.md && rg -q 'Process signal' home/modules/agents/skills/review/rounds.md`).
- Avoidable spaghetti blocks approval, while concrete simplification and the
  no-invented-nits guard prevent performative rewrites (manual: fresh reviewer
  applies the revised dimensions to one tangled diff and one direct diff, then
  confirms only the first receives a MAJOR structural finding).
- Review requires both a neighboring-rule read and concept/cross-reference
  sweep after prose contract changes (cmd: `rg -q 'neighboring rules' home/modules/agents/skills/review && rg -q 'cross-references' home/modules/agents/skills/review`).
- The skill suite remains conformant and within all measured budgets (cmd:
  `rg -q 'Process signal' home/modules/agents/skills/review && bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `rg -q 'Process signal' home/modules/agents/skills/review && tatr check && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- Promoted lesson: `fix-touches-its-neighbours` x3.
- Seeded by task 20260731-133122 review/retro.
- Promotion order audit found no reliable semantic checker or template owner;
  review prose is the narrowest owner.
- Preserve severity-by-impact and findings-first output. Structural ambition
  does not outrank bugs, security, data loss, or an undelivered Story.
- Prefer deletion, then direct flow, then a cohesive module. Require an
  abstraction to own a real invariant or serve demonstrated reuse.

## Close-out

What/why: the review skill now judges avoidable structural complexity, not
only correctness. Applicable `AGENTS.md` files joined Story/Steps/DoD as the
spec (`review/SKILL.md` workflow 1); the `Design` dimension gained the MAJOR
complexity bar and the size-is-a-cohesion-question clause; `## Rules` gained
the from-scratch counterfactual as a refinement of the existing
no-invented-nits rule; `rounds.md` gained the `Process signal:` bullet shape;
the `Docs` dimension gained the promoted neighboring-contract sweep.

Alternatives: a parallel `## Simplicity` dimension was drafted and rejected -
it restated YAGNI, missed reuse and unrequested scope, which `## Design`
already owns, and `check.sh` treats a repeated paragraph as drift. Extending
`Design` kept one concept in one place. A new conditional reference was also
rejected: simplicity is judged on every diff, so it must live in the file the
judging phase always loads.

Difficulties: the first draft put every new rule in `dimensions.md` and
measured 633 words against a 600-word cap. The counterfactual moved to
`SKILL.md` `## Rules`, which is where the no-invented-nits rule it qualifies
already lived - the budget forced the better placement rather than a cut.

Evidence: all five `cmd:` proofs confirmed red on the base commit before
implementation and green after. `check.sh` clean (9 skills, 22 rules);
`sprout-test.sh` 14/14; `tatr check` and `tatr check --ledger LESSONS.md`
exit 0; `nix flake check` all checks passed. Budgets after the change, as `check.sh`
measures them - BODY words for a SKILL.md, whole-file for a reference:
`SKILL.md` 306/400, `dimensions.md` 586/600, `rounds.md` 595/600.

Reflection: `dimensions.md` and `rounds.md` now sit within 14 and 10 words of
their caps, so the next rule added to either forces a real restructure rather
than an edit. Step 8 stays unticked until the ledger promotion runs after
landing.
