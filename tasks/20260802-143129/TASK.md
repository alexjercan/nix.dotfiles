# Address the afk runner's round-1 review findings

- STATUS: OPEN
- PRIORITY: 40
- TAGS: agents, flow
- KIND: TASK
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Story

Round 1 of the afk flow runner review (20260802-132348, REVIEW.md) closed
APPROVE with three MINOR findings and a NIT left open. All three MINORs sit in
one seam: afk's injected PROTOCOL status vocabulary versus the flow skill's
`## Output` contract. Close them together.

- R1.1 `home/modules/scripts/afk.sh:65` - add `SPIKED` to the PROTOCOL status
  list so the branch at afk.sh:442 is reachable by contract.
- R1.2 `AGENTS.md:80` - reword the machine-consumer paragraph: `flow/gates.md`'s
  three approve labels are the shared literal contract; ROTATE/DONE/BLOCKED are
  afk's own vocabulary, defined in the PROTOCOL heredoc.
- R1.3 `home/modules/scripts/afk.sh:390` - cover the "the session reported a
  task with no record" guard in `test_failure_paths`.
- R1.4 (NIT) decide whether `AFK_VERBOSE` stays; keep it as a diagnostic or
  delete afk.sh:241-246 and its usage line.

Also from the retro of 20260802-132348: consider showing `--repo` explicitly in
the `knowledge` skill's command block, since its default of `$PWD` fails
silently by writing a shadow lesson tree into the project checkout.

## Steps

- [ ] `home/modules/scripts/afk.sh` PROTOCOL heredoc (~line 65): add a `SPIKED`
      entry to the `<STATUS>` list, worded so the model knows the run stops
      there. Keep the two-column shape of the existing entries.
- [ ] `AGENTS.md:80-83`: reword the machine-consumer paragraph. Split the two
      contracts - the three approve labels in `flow/gates.md` are shared
      literal strings that `afk.sh` matches; `ROTATE`/`DONE`/`BLOCKED` are
      afk's own vocabulary, defined in afk's PROTOCOL heredoc, not in any
      skill. `SPIKED`, `PLAN_READY`, `WORK_DONE`, `LAND_READY` come from the
      skills' `## Output` contracts. Keep the same-task change rule.
- [ ] `home/modules/scripts/afk-test.sh` `test_failure_paths`: add a goal-mode
      case. Invocation 1 replies `AFK ROTATE 19990101-000000` without creating
      a record; assert the run fails and names the missing record. Goal mode is
      the only path with `TASK_ID` empty, so this is the only way to reach
      afk.sh:390.
- [ ] `home/modules/scripts/afk-test.sh`: give `AFK_VERBOSE` a test so it stops
      being an untested knob (see DECISION.md). Emit an assistant event with
      text in a fixture, run with `AFK_VERBOSE=1`, assert the text appears
      prefixed `| `; run the same fixture without it and assert it does not.
- [ ] `home/modules/agents/skills/compound/SKILL.md` step 4: name an explicit
      `--repo` when submitting through `knowledge`. The skill itself is owned
      by the `agent-knowledge` input and cannot be edited here; this repo's
      caller is the surface that can carry the warning. Body is 355 words
      against a 400-word budget - keep the addition under ~20 words.
- [ ] `tasks/20260802-143129/DECISION.md`: record the R1.4 verdict and its
      rationale.
- [ ] Re-read each edited file, then run the DoD commands.

## Definition of Done

- The PROTOCOL heredoc lists `SPIKED`, so afk.sh:442 is reachable by contract.
  (cmd: `sed -n '/^read -r -d .. PROTOCOL/,/^EOF$/p' home/modules/scripts/afk.sh | grep -q SPIKED`)
- `AGENTS.md` no longer claims afk routes only on skill `## Output` statuses.
  (cmd: `grep -q 'PROTOCOL' AGENTS.md`)
- The afk suite is green and covers both new cases.
  (cmd: `bash home/modules/scripts/afk-test.sh`)
- The missing-record guard is exercised.
  (cmd: `bash home/modules/scripts/afk-test.sh -v 2>&1 | grep -q 'no such record'`)
- `AFK_VERBOSE` is exercised.
  (cmd: `grep -q AFK_VERBOSE home/modules/scripts/afk-test.sh`)
- `compound/SKILL.md` names `--repo` and stays inside its budget.
  (cmd: `grep -q -- '--repo' home/modules/agents/skills/compound/SKILL.md && bash home/modules/agents/skills/check.sh`)
- Repository checks pass.
  (cmd: `bash home/modules/scripts/sprout-test.sh && tatr check && nix flake check`)

## Notes

- Confirmed on base: the PROTOCOL grep, the `AGENTS.md` grep, the two
  `afk-test.sh` greps and the `--repo` grep are all red. The suite itself is
  green (8 cases).
- afk.sh:390 (`but no such record exists`) is guarded by `[[ -z $TASK_ID ]]`,
  which only holds in goal mode - `afk run "<goal>"`. `gen_goal_cycle` is the
  existing goal-mode fixture; the new case needs only invocation 1, no side
  script.
- The `knowledge` skill comes from `inputs.agent-knowledge.skills.knowledge`
  (`home/modules/agents/default.nix:38`). Its command block is out of this
  repo's ownership; only the `compound` caller can be changed here. Fixing the
  skill's own default belongs in the `agent-knowledge` repo.
- No status vocabulary changes, so `flow/SKILL.md` and `flow/gates.md` are
  untouched; the docs-sync rule is satisfied by the `AGENTS.md` and
  `compound/SKILL.md` edits.
