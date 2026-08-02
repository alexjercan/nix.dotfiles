# State YAGNI and KISS in the global rules, plan scope gate, and review dimensions

- PRIORITY: 70
- TAGS: skills, flow, docs, plan, review
- KIND: TASK
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

## Story

As the operator of the flow skills, I want YAGNI/KISS stated once globally and
applied at the two decision points that can enforce it - `plan` (scope the
design to the observed need) and `review` (flag speculative work as a finding)
- so agents stop shipping unrequested abstractions, knobs and parameters.

## Steps

- [x] Rewrite `## Technical decisions` in `home/modules/agents/AGENTS.md`:
      drop "More code" from the effort bullet so it licenses refactoring and
      tests but not scope, then add a `YAGNI:` bullet (no speculative
      parameter, hook, abstraction, or config knob), a `KISS:` bullet
      (simplest design meeting the requirement; one caller is not an
      abstraction), and `Quality is a cost worth paying; scope is not.`
- [x] Add one `## Rules` bullet to `home/modules/agents/skills/plan/SKILL.md`:
      plan the simplest design that satisfies the DoD; generality, options and
      extension points need a caller in this task, or they are deferrals.
      Body is 289 of 400 words; the drafted bullet costs 24.
- [x] Rewrite the opening sentence of the Design lens in
      `home/modules/agents/skills/review/dimensions.md` to name the YAGNI
      finding class (abstraction with one caller, unused parameter or option,
      unrequested knob, generality no Step names), to require naming the lines
      to delete, and to exempt refactoring, tests and records the plan asked
      for. File is 461 of 600 words; the drafted replacement costs 39 net.
- [x] Sweep the doc surfaces the edit invalidates: grep the repo outside
      `tasks/` for `More code` and `needless complexity` and confirm no other
      file quotes the replaced wording.
- [x] Run the canonical checks: `bash home/modules/agents/skills/check.sh`,
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

## Close-out

What/why: the global rules said "More code, refactoring, or tests are valid
costs", which licensed scope as well as effort - so a YAGNI rule added only to
a skill would have contradicted the file every session loads. The effort
bullet now covers refactoring and tests alone, and `YAGNI:`, `KISS:` and
"Quality is a cost worth paying; scope is not." state the principle once,
globally. Its operational form lives at the two decision points that can act
on it: a `plan` Rules bullet requiring the simplest design that satisfies the
DoD, with generality/options/extension points needing a caller in this task or
becoming deferrals; and the review Design lens, where YAGNI is now a named
finding class (one-caller abstraction, unused parameter or option,
unrequested knob, generality no Step names) that must name the lines to
delete.

Alternatives: putting the rule only in the flow family (rejected - the global
contradiction survives, and it would not apply to work outside `/flow`);
adding it to `flow/SKILL.md` (rejected - the router dispatches and never
restates, and its 300-word cap is already full); adding a clause to
`work/SKILL.md` (rejected - "not the smallest plausible diff" there is an
anti-hack rule, and review now owns removal, so a second statement would be
the duplication the gate exists to prevent).

Difficulties: none in implementation. The exemption clause was the real
design question - a YAGNI finding class with no boundary would let a reviewer
attack the refactoring, tests and records the plan itself asked for, which is
the opposite of the repository's standing rule. It is stated in the same
paragraph as the finding class rather than left implicit.

Evidence: all four DoD proofs green in the worktree, red on the base commit
before the edit (proof 1, 2 and 3 all exited 1 at `c34c26b`). Sabotage was run
at plan time on a scratch copy: dropping the YAGNI bullet, dropping the KISS
bullet or restoring "More code" each reddened proof 1 alone; dropping the plan
rule reddened proof 2 alone; rewording the dimensions clause reddened proof 3
alone. `check.sh` clean (9 skills, 22 rules, 179 description words),
`sprout-test.sh` 14 passed / 0 failed, `tatr check --ledger LESSONS.md` exit
0, `nix flake check` all checks passed. Diff: 3 files, +13/-3.

Budgets after the change: `plan/SKILL.md` body 289 -> 313 of 400 (+24, as
planned); `review/dimensions.md` 461 -> 506 of 600 (+45, where the plan
estimated +39 - the estimate was drafted before the final wording and is
recorded here rather than back-fitted).

Reflection: the plan-time sabotage made the work phase mechanical - every
proof's failure mode was already known, so nothing had to be diagnosed from a
red run. The one thing worth carrying forward is that a rule which
CONSTRAINS scope has to name what it does not constrain in the same breath;
the exemption is not padding, it is the half that keeps the rule from being
read as an argument against quality work.
