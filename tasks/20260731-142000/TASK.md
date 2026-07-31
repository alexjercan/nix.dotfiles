# Make avoidable complexity block review approval

- STATUS: OPEN
- PRIORITY: 100
- TAGS: skills,review,lessons,docs,flow
- KIND: STORY
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT
- PARENT: 20260731-174333

## Story

As a flow reviewer, I want the applicable `AGENTS.md` simplicity bar enforced
as an approval criterion, so behaviorally correct code cannot land with
avoidable spaghetti, speculative structure, or control flow a cold reader
cannot follow.

## Steps

- [ ] Update `review/SKILL.md` and `review/dimensions.md` so applicable
      `AGENTS.md` files are part of the spec and correctness/evidence remain the
      first review obligation.
- [ ] Make avoidable structural complexity a MAJOR approval blocker: scattered
      special cases, unnecessary modes/branches/wrappers/options, wrong
      ownership, or a flow a cold reader cannot follow.
- [ ] Add the counterfactual question: knowing the current constraints, would
      we implement this route from scratch? Require any alternative to preserve
      behavior and name the concepts, branches, or indirection it deletes;
      reject subjective or speculative rewrites as invented nits.
- [ ] Treat file/diff size as a cohesion and planning trigger, not a universal
      line-count verdict. Record unexpected scope, missed task splits, and
      review-driven restructuring as plain `Process signal:` observations for
      compound, separate from code findings.
- [ ] Preserve the promoted neighboring-contract rule: for prose/contract
      edits, re-read neighboring rules and sweep changed concepts plus
      cross-references.
- [ ] Keep the review body/reference budgets and every existing correctness,
      spec, test, docs, honesty, fresh-context, and round-ownership rule.
- [ ] Run the skill gate, task/ledger checks, and full flake checks.
- [ ] After landing, use the lessons workflow to finish the recorded
      `fix-touches-its-neighbours` promotion.

## Definition of Done

- The active review instructions explicitly cover applicable `AGENTS.md`, the
  from-scratch counterfactual, and process signals (cmd: `rg -q 'applicable.*AGENTS.md' home/modules/agents/skills/review && rg -q 'from scratch' home/modules/agents/skills/review && rg -q 'Process signal' home/modules/agents/skills/review`).
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
