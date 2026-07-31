# State YAGNI and KISS in the global rules, plan scope gate, and review dimensions

- STATUS: OPEN
- PRIORITY: 70
- TAGS: skills, flow, docs, plan, review
- KIND: TASK
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Story

As the operator of the flow skills, I want YAGNI/KISS stated once globally and
applied at the two decision points that can enforce it - `plan` (scope the
design to the observed need) and `review` (flag speculative work as a finding)
- so agents stop shipping unrequested abstractions, knobs and parameters.

## Steps

- [ ] Rewrite `## Technical decisions` in `home/modules/agents/AGENTS.md`:
      drop "More code" from the effort bullet so it licenses refactoring and
      tests but not scope, then add a `YAGNI:` bullet (no speculative
      parameter, hook, abstraction, or config knob), a `KISS:` bullet
      (simplest design meeting the requirement; one caller is not an
      abstraction), and `Quality is a cost worth paying; scope is not.`
- [ ] Add one `## Rules` bullet to `home/modules/agents/skills/plan/SKILL.md`:
      plan the simplest design that satisfies the DoD; generality, options and
      extension points need a caller in this task, or they are deferrals.
      Body is 289 of 400 words; the drafted bullet costs 24.
- [ ] Rewrite the opening sentence of the Design lens in
      `home/modules/agents/skills/review/dimensions.md` to name the YAGNI
      finding class (abstraction with one caller, unused parameter or option,
      unrequested knob, generality no Step names), to require naming the lines
      to delete, and to exempt refactoring, tests and records the plan asked
      for. File is 461 of 600 words; the drafted replacement costs 39 net.
- [ ] Sweep the doc surfaces the edit invalidates: grep the repo outside
      `tasks/` for `More code` and `needless complexity` and confirm no other
      file quotes the replaced wording.
- [ ] Run the canonical checks: `bash home/modules/agents/skills/check.sh`,
      `bash home/modules/scripts/sprout-test.sh`,
      `tatr check --ledger LESSONS.md`, `nix flake check`.

## Definition of Done

- The global rules separate scope from effort and state both principles: the
  effort bullet no longer says "More code", and `YAGNI:` and `KISS:` bullets
  exist (cmd: `grep -q '^- YAGNI' home/modules/agents/AGENTS.md && grep -q '^- KISS' home/modules/agents/AGENTS.md && ! grep -q 'More code' home/modules/agents/AGENTS.md`).
- `plan` carries a simplest-design rule and the suite stays within its budgets
  (cmd: `tr '\n' ' ' < home/modules/agents/skills/plan/SKILL.md | grep -q 'simplest design that satisfies' && bash home/modules/agents/skills/check.sh`).
- The review Design lens names YAGNI as a finding class and the suite stays
  within its budgets (cmd: `tr '\n' ' ' < home/modules/agents/skills/review/dimensions.md | grep -q 'YAGNI is a finding' && bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `bash home/modules/scripts/sprout-test.sh && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- Sabotage run at plan time in a scratch copy of `home/modules/agents`
  (`write-the-sabotage-first`): all three proofs are red on master and green
  after the drafted text; dropping the YAGNI bullet, dropping the KISS
  bullet, or restoring "More code" each reddens proof 1 alone; dropping the
  plan rule reddens proof 2 alone; rewording the dimensions clause reddens
  proof 3 alone; 120 filler words in `plan/SKILL.md` trip the shared
  `check.sh` conjunct in proofs 2 and 3. `nix flake check` and the other
  canonical checks are green on master.
- Each `tr | grep` proof normalizes line breaks on purpose
  (`line-breaks-are-load-bearing`): the anchors span a wrap, and `grep` is the
  last stage so its exit code is the result.
- Whether agents actually build less is not provable by this diff; it is a
  behavior claim for later occurrences in the ledger, not a DoD item.
- The global `home/modules/agents/AGENTS.md` currently pulls the other way:
  "Ignore implementation time. More code, refactoring, or tests are valid
  costs." That licenses over-building; scope and effort are conflated.
- Refactoring, tests and quality work stay valid costs. The rule targets
  SCOPE (unrequested features/abstractions), not effort.
- `flow/SKILL.md` is out of scope: it dispatches and never restates, and its
  body budget is 300 words.
- `check.sh` budgets: phase body 400 words, reference 600, and
  `duplicated-paragraph` forbids restating the same paragraph in two files.
