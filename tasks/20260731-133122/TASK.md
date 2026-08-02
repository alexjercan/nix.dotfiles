# Compact flow skills to stricter budgets

- PRIORITY: 80
- TAGS: refactor, skills, flow, docs
- KIND: TASK
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

## Story

As the flow-suite maintainer, I want stricter context budgets and concise skill
text, so that each phase keeps only essential instructions.

## Steps

- [x] Action Item - budgets: set `BUDGET_ROUTER_BODY=300`,
      `BUDGET_PHASE_BODY=400`, and `BUDGET_REFERENCE=600` in
      `home/modules/agents/skills/check.sh`; update the budget table and prose
      in `home/modules/agents/skills/README.md`.
- [x] Action Item - flow: compact `flow/SKILL.md` to at most 300 body words;
      compact every `flow/*.md` reference to at most 600 words.
- [x] Action Item - plan: compact `plan/SKILL.md` to at most 400 body words;
      compact every `plan/*.md` reference to at most 600 words.
- [x] Action Item - work: compact `work/SKILL.md` to at most 400 body words;
      compact every `work/*.md` reference to at most 600 words.
- [x] Action Item - review: compact `review/SKILL.md` to at most 400 body
      words; compact every `review/*.md` reference to at most 600 words.
- [x] Action Item - spike: compact `spike/SKILL.md` to at most 400 body words;
      keep every `spike/*.md` reference within 600 words.
- [x] Action Item - compound: compact `compound/SKILL.md` to at most 400 body
      words.
- [x] Action Item - lessons: compact `lessons/SKILL.md` to at most 400 body
      words; compact every `lessons/*.md` reference to at most 600 words.
- [x] Action Item - sprout: compact `sprout/SKILL.md` to at most 400 body
      words; keep every `sprout/*.md` reference within 600 words.
- [x] Action Item - today: compact `today/SKILL.md` to at most 400 body words.
- [x] Inventory each edited file's imperative rules before rewriting; retain
      each rule, move it to a reachable reference/tool, or record why it is
      obsolete. Re-read each edited artifact and its neighboring rules.
- [x] Run the skill gate, tatr gates, and full flake checks.

## Definition of Done

- Checker and README declare inclusive 300/400/600 word limits for router,
  phase, and reference surfaces (cmd: `grep -q '^BUDGET_ROUTER_BODY=300 ' home/modules/agents/skills/check.sh && grep -q '^BUDGET_PHASE_BODY=400 ' home/modules/agents/skills/check.sh && grep -q '^BUDGET_REFERENCE=600 ' home/modules/agents/skills/check.sh && grep -Fq '| `flow/SKILL.md` body | at most 300 words |' home/modules/agents/skills/README.md && grep -Fq '| Any other `SKILL.md` body | at most 400 words |' home/modules/agents/skills/README.md && grep -Fq '| One conditional reference | at most 600 words, one level deep |' home/modules/agents/skills/README.md`).
- All managed skill bodies and references pass the stricter structural gate
  (cmd: `grep -q '^BUDGET_ROUTER_BODY=300 ' home/modules/agents/skills/check.sh && grep -q '^BUDGET_PHASE_BODY=400 ' home/modules/agents/skills/check.sh && grep -q '^BUDGET_REFERENCE=600 ' home/modules/agents/skills/check.sh && bash home/modules/agents/skills/check.sh`).
- Compaction preserves lifecycle guards, invocation policy, conditional
  loading, output contracts, and tool ownership (manual: reviewer compares the
  imperative-rule inventory with each rewritten skill and reference).
- Repository task, ledger, skill, deployment, and flake checks pass with the
  new limits (cmd: `grep -q '^BUDGET_ROUTER_BODY=300 ' home/modules/agents/skills/check.sh && tatr check && tatr check --ledger LESSONS.md && bash home/modules/agents/skills/check.sh && nix flake check`).

## Notes

- Scope: `flow`, `plan`, `work`, `review`, `spike`, `compound`, `lessons`,
  `sprout`, and `today`; `today` is required because the checker applies the
  phase-body budget to every non-`flow` skill.
- Current body counts: flow 499; phase bodies 534-799. All nine bodies exceed
  the proposed caps.
- Current references over 600 words: `flow/epic.md`, `plan/lanes.md`,
  `plan/proofs.md`, `work/verify.md`, `review/lanes.md`, and
  `lessons/ledger.md`.
- Preserve existing behavior. Prefer deletion of repetition and tool-owned
  rules over moving core-path prose into references.

## Close-out

### What changed

- Enforced inclusive 300/400/600 router, skill-body, and reference budgets.
- Compacted all nine managed skill bodies to 211-289 words and six oversized
  references to 177-286 words.
- Updated README and AGENTS.md budget documentation.
- Recorded the pre-rewrite imperative inventory in NOTES.md for review.
- Corrected the old plan-core claim that base-red final-state proofs were
  broken; `proofs.md` already required red-before-change sabotage.

### Why

Smaller always-loaded instructions leave more context for repository code and
task evidence while preserving branch-only disclosure.

### Alternatives

- Rejected moving more core rules into references: smaller initial context,
  but ordinary phases would immediately reload it.
- Rejected checker-only changes: they would fail without delivering concise
  skills.

### Difficulties

- The phase-body gate also covers `today`; measurement caught it before the
  rewrite scope was fixed.
- Compact command tables can become invalid shell shorthand. Re-reading found
  and split combined `today` commands into real invocations.

### Evidence

- `bash home/modules/agents/skills/check.sh`: clean, 9 skills and 22 rules.
- `bash home/modules/scripts/sprout-test.sh`: 14 passed.
- All executable `tatr proofs 20260731-133122` commands: passed.
- `nix flake check`: all checks passed.

### Reflection

Rule-first inventory prevented budget-driven section deletion. Re-reading
examples as commands caught a correctness loss the word-count gate cannot.
