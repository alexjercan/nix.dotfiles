# Refactor flow skills for bounded context and concise output

- STATUS: CLOSED
- PRIORITY: 80
- TAGS: feature, skills, flow, docs, spike
- KIND: STORY
- FLOW STEP: DONE
- PLAN STATUS: APPROVED
- PARENT: 20260730-153122

## Story

As the flow-suite maintainer, I want each skill to load only the instructions
needed for its current branch and phase, so that repository context and
reasoning receive most of the context window.

## Steps

- [x] Define the single owner and target word budget for every flow-family
      rule, description, core body, conditional reference, phase handoff, and
      user-facing report.
- [x] Refactor `flow` into a compact state-machine dispatcher and refactor each
      phase skill so its core path stays in SKILL.md while branch-specific
      material is loaded through direct, conditional references.
- [x] Remove repeated lifecycle/tool details, historical anecdotes, embedded
      record templates, and redundant Relationship sections once their
      behavior is owned by tatr, sprout, a scaffold, or the orchestrator.
- [x] Add explicit Codex and Claude invocation metadata; keep only skills that
      need automatic or cross-skill reach implicitly invocable, with concise
      branch-complete descriptions.
- [x] Add the repository-workflow cache convention: AGENTS.md stores short
      answers for tracker, Epic/Story layout, example/prototype location,
      research policy, domain docs, and canonical checks, with detail behind
      one pointer.
- [x] Add phase output contracts and bounded subagent handoffs; durable task
      artifacts hold detail while chat reports only result, proof, next step,
      and required status marker.
- [x] Add `home/modules/agents/skills/check.sh` plus integration fixtures for
      budgets, ASCII, frontmatter, broken/indirect references, duplicated
      paragraphs, invocation policy, conditional loading, and output shape.
- [x] Update the skills README and deployment checks so references,
      templates/assets, and `agents/openai.yaml` files reach both agent tools.

## Definition of Done

- Flow-family descriptions total at most 200 words, `flow/SKILL.md` is at most
  500 body words, each phase core is at most 800, and each conditional
  reference is at most 1,000 (cmd:
  `bash home/modules/agents/skills/check.sh`).
- Fixture branch words prove branch-only references are not loaded on
  unrelated paths (test: `skill_progressive_disclosure`). The plan wrote
  "fixture prompts"; the `prompt:` key was removed during review round 1
  because nothing read it and it had already drifted from the `when:` words
  that carry the actual assertion.
- Codex and Claude fixtures select the same intended implicit/explicit skills
  (test: `skill_invocation_policy`).
- Phase reports satisfy the agreed output limits without omitting required
  findings, proofs, gates, or status markers (test: `skill_output_contracts`).
- The home-manager activation result contains every required skill body,
  reference, asset/template, and OpenAI metadata file
  (test: `skills-deployment-tree`, a `nix flake check` derivation; the plan
  wrote it `skills_deployment_tree`, renamed to match the hyphenated
  convention the sibling check in `flake/` already uses).
- Repository conformance and flake evaluation pass
  (cmd: `tatr check --ledger LESSONS.md && nix flake check --no-build`).

## Notes

- Parent Epic: 20260730-153122.
- Spike: tasks/20260730-142052/SPIKE.md
- Refinement: tasks/20260730-142533/NOTES.md
- Depends on tatr: 20260730-153325, 20260730-154745.
- Preserve the current tatr task, sprout isolation, proof-bearing DoD, review,
  landing, and lessons lifecycle.

## Close-out

### What changed

The eight flow-family skills were rewritten against measured context budgets
and a machine-checked structure, and the gate that keeps them there was built.

- `flow/SKILL.md` is a 483-word dispatcher. Landing, epic containers and resume
  moved to `flow/{landing,epic,resume}.md` behind conditional pointers.
- Every phase skill fits 800 body words, with branch material in a reference:
  `plan/{proofs,decision}.md`, `work/{bug,verify,review-feedback}.md`,
  `review/{dimensions,rounds}.md`, `lessons/ledger.md`, `sprout/reference.md`.
  Bodies now run 483-659 words against the 800 budget, references 307-619
  against 1000. (These are the numbers after review round 1; the first draft's
  were smaller, before the restored rules went back in.)
- Conditional pointers live in one `## Load on demand` section per skill, in
  the shape `<condition> -> \`<file>.md\``. That single surface is what the
  disclosure fixtures assert against, and it is why the pointers were pulled
  out of the prose: an arrow whose condition wrapped onto the next line stated
  no condition the checker could read.
- Removed: every "Relationship to ..." section, the dated anecdotes (nova
  protocol, the bcs status item, ledger occurrence counts inside skill prose),
  the restated tatr lifecycle rules, and the TASK/SPIKE/DECISION/REVIEW/RETRO
  templates now written by `tatr scaffold`. What survived is the semantics a
  tool cannot supply: the four severities, the DECISION status values, the
  ledger's promotion and retirement lifecycle.
- Descriptions total 179 words across the family, down from 591.
- Invocation policy is declared once, in frontmatter both tools read.
  `sprout` is explicit-only (`disable-model-invocation: true`) because `work`
  and `flow` embed its commands rather than invoking the skill. Everything else
  stays model-invocable, since `flow` dispatches phases by name and a skill
  Claude cannot invoke would break that dispatch. Each skill also ships
  `agents/openai.yaml`, matching the tatr skill's convention.
- `AGENTS.md` gained the repository-workflow cache (this repo's answers) and
  the global `home/modules/agents/AGENTS.md` gained the convention that
  defines it.
- The home-manager module deploys from an explicit `localSkills` list instead
  of globbing `skills/*/`, so `check.sh` and `fixtures/` stop being deployed
  as skills.

### Why the tests are structural

See DECISION.md. The four DoD `test:` items name runtime behavior no
repository check can observe. The gate proves the SHAPE that makes the
behavior possible - conditions guard every loadable branch, one policy is
declared per skill, every contract is stated and bounded - and the live
behavior is the user's manual pass. That gap is stated in the decision record,
the README and `fixtures/run.sh` rather than hidden behind a green check.

### Difficulties

- **A gate that cannot fail proves nothing.** The first version of `check.sh`
  went green on the first run, which is exactly the signal the ledger warns
  about. `--self-test` was added to sabotage each rule in a scratch copy and
  assert that rule fires; it immediately caught two vacuous cases (a
  duplicated-paragraph sabotage that merged into the preceding paragraph and
  so was never a duplicate, and an output-budget sabotage that appended filler
  to the wrong section and tripped the body budget instead). Both were
  sabotage bugs, but until the self-test existed neither rule had ever been
  observed failing.
- **The ASCII rule was too broad.** Flagging every non-ASCII byte failed
  `today/SKILL.md`, which quotes a real habit named with an emoji. Rewriting
  the CLI's own output to satisfy a doc rule would have been wrong, so the
  rule was narrowed to the substituted glyphs the writing rule actually
  forbids: en/em dash, smart quotes, ellipsis, arrows, bullet, nbsp, times.
- **An untracked file is invisible to a dirty flake.** The first
  `nix build .#checks...skills-deployment-tree` failed with "does not provide
  attribute" because `flake/checks-skills.nix` was untracked. `git add -A`
  fixed it.
- **`git checkout --` restores from the INDEX.** While sabotage-testing the
  deployment check, the sabotaged module had already been staged, so the
  restore put the sabotage back. Caught by grepping the file afterwards rather
  than trusting the restore.

### Review round 1

An out-of-context reviewer raised 20 findings; 19 were fixed and one (R1.5, the
mandatory lesson-promotion gate) was pushed back as belonging to sibling tasks
20260730-154756 and 20260730-154955 under the same Epic. The findings that
changed the shipped artifact rather than its prose:

- `check.sh` was checking a HARDCODED skill list, so a new skill directory was
  never checked at all. It now reads the set off disk and reports an
  unclassified skill as a finding.
- The self-test's "21 rules proven able to fail" was an overclaim: 21 cases
  covered 20 of 26 slugs. Coverage is now computed against a declared rule
  inventory (`check.sh --rules`) and the self-test fails both on an uncovered
  rule and on a rule the source can emit but never declared. 35 cases, 30 of 30.
- The fixture named for the single-task branch was actually asserting the
  resume branch, and its `prompt:` key - which nothing read - had drifted from
  its `when:` without anyone noticing. The key is gone.
- `check.sh` ran only by hand, so the budgets could still rot; it is now
  `checks.skills-conformance` inside `nix flake check`.
- The deployment check's section 2 read the SOURCE tree while claiming to check
  the DEPLOYED one. It now reads `recursive` and `source` out of the evaluated
  home config, and both new assertions were sabotage-verified.
- `work/SKILL.md` had silently dropped two rules the budget did not require
  dropping: ask before working a dirty main tree, and the non-sprout fallback.
  Also restored: spike's same-second `tatr new` rule and its `## Fix record`,
  and review's "APPROVE ends the cycle; merging is the user's call".

### Self-reflection

The plan's `test:` names should have been recognised as unobservable at plan
time, not at work time. Reading the DoD for "can this proof actually run?"
belongs in the plan gate; here it surfaced only once the checker had to be
written, and cost a round trip to the user mid-work.

The self-test should have been the first artifact, not a late addition. The
budgets and structure rules were written and then observed to pass, which is
the after-the-fact test the work skill forbids for code and should equally
forbid for a checker. Writing one sabotage case per rule BEFORE the rule would
have made every rule test-first by construction - and would have caught the
hardcoded skill list (R1.1) and the coverage overclaim (R1.3) before review,
since both are invisible to a gate you only ever watch pass.

The three restored rules (R1.4, R1.14, R1.15, R1.16) share one cause: the
refactor deleted prose by SECTION rather than by RULE. "Remove the Relationship
sections" and "cut to 800 words" were applied to blocks of text, and rules that
happened to live inside those blocks went with them. A diff-of-rules pass -
extract every imperative from the old file, check each one is present, moved,
or deliberately retired - would have caught all four, and costs far less than a
review round.
