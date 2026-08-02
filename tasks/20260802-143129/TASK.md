# Address the afk runner's round-1 review findings

- PRIORITY: 40
- TAGS: agents, flow
- KIND: TASK
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

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

Reopened: the afk run driving THIS task failed at its `WORK_DONE` gate with
"20260802-143129 is in PLANNED, not WORKING". The marker was right and the
cross-check was right; the record write went to the wrong checkout. The session
ran `tatr flow <id> --to WORKING` with no `-r`, so it landed as an uncommitted
edit in the main checkout while the sprout worktree - which owns the task, per
`sprout.task`, and which afk reads through `task_root` - stayed at PLANNED.
Same class as the "use absolute worktree paths for every edit/git call" rule
the work skill already states for git: shell cwd is main, so an unrooted
command writes to the stale copy. The skills name `tatr <sub> <id>` with no
root at ~25 sites; nothing enforces the rooted form.

## Steps

- [x] `home/modules/scripts/afk.sh` PROTOCOL heredoc (~line 65): add a `SPIKED`
      entry to the `<STATUS>` list, worded so the model knows the run stops
      there. Keep the two-column shape of the existing entries.
- [x] `AGENTS.md:80-83`: reword the machine-consumer paragraph. Split the two
      contracts - the three approve labels in `flow/gates.md` are shared
      literal strings that `afk.sh` matches; `ROTATE`/`DONE`/`BLOCKED` are
      afk's own vocabulary, defined in afk's PROTOCOL heredoc, not in any
      skill. `SPIKED`, `PLAN_READY`, `WORK_DONE`, `LAND_READY` come from the
      skills' `## Output` contracts. Keep the same-task change rule.
- [x] `home/modules/scripts/afk-test.sh` `test_failure_paths`: add a goal-mode
      case. Invocation 1 replies `AFK ROTATE 19990101-000000` without creating
      a record; assert the run fails and names the missing record. Goal mode is
      the only path with `TASK_ID` empty, so this is the only way to reach
      afk.sh:390.
- [x] `home/modules/scripts/afk-test.sh`: give `AFK_VERBOSE` a test so it stops
      being an untested knob (see DECISION.md). Emit an assistant event with
      text in a fixture, run with `AFK_VERBOSE=1`, assert the text appears
      prefixed `| `; run the same fixture without it and assert it does not.
- [x] `home/modules/agents/skills/compound/SKILL.md` step 4: name an explicit
      `--repo` when submitting through `knowledge`. The skill itself is owned
      by the `agent-knowledge` input and cannot be edited here; this repo's
      caller is the surface that can carry the warning. Body is 355 words
      against a 400-word budget - keep the addition under ~20 words.
- [x] `tasks/20260802-143129/DECISION.md`: record the R1.4 verdict and its
      rationale.
- [x] Re-read each edited file, then run the DoD commands.
- [x] `home/modules/agents/skills/check.sh`: add an `unrooted-tatr-call` rule.
      A `tatr` command naming a task placeholder (`flow`, `scaffold`, `check`,
      `proofs`, `context`, `show`, `edit` followed by `<...>`) must carry
      `-r <...>` before the subcommand. Match over a two-line window so a
      wrapped command cannot slip past. Declare the slug in `RULES`.
- [x] Root every such call in the flow family: `flow/SKILL.md` transitions,
      `flow/gates.md` both gate effects, `flow/epic.md` the epic transition,
      `plan/SKILL.md`, `plan/decision.md`, `plan/proofs.md`, `plan/lanes.md`,
      `spike/SKILL.md`, `work/SKILL.md`, `work/verify.md`,
      `work/review-feedback.md`, `review/SKILL.md`, `review/rounds.md`,
      `review/dimensions.md`, `compound/SKILL.md`. Use `<task-root>`, the term
      `flow/resume.md` already defines. `flow/SKILL.md` has 3 words of body
      budget left, so only its transition line changes.
- [x] `home/modules/agents/skills/README.md` `## Checks`: name the new rule in
      the sentence enumerating what `check.sh` owns, per the docs-sync rule.
- [x] Record the no-exemptions rationale. `DECISION.md` is spent on the R1.4
      verdict and the tree is append-only, so it goes in the rule's own header
      comment in `check.sh` and in Notes below, not in a second record.
- [x] Re-read each edited file, then run the DoD commands again.

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
- No flow-family skill names a task-taking `tatr` call without a root, and the
  suite still passes its budgets and reference graph.
  (cmd: `bash home/modules/agents/skills/check.sh`)
- The new rule actually fires: unrooting one call is a finding, not silence.
  (cmd: `d=$(mktemp -d) && cp -r home/modules/agents/skills "$d/s" && sed -i 's/tatr -r <task-root> flow <id> --to REVIEWING/tatr flow <id> --to REVIEWING/' "$d/s/flow/gates.md" && bash "$d/s/check.sh" 2>&1 | grep -q unrooted-tatr-call`)
- The rule inventory stays honest about it.
  (cmd: `bash home/modules/agents/skills/check.sh --rules | grep -qx unrooted-tatr-call`)
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
  `compound/SKILL.md` edits. (Superseded by the reopening: the rooting sweep
  touches both files.)
- Rooting sweep, no exemptions: `<task-root>` is the main checkout for a task
  with no worktree, so `-r <task-root>` is correct in every phase, including
  PLANNING and BACKLOG where no worktree can exist. A rule carrying a map of
  which phases it applies to costs more to follow, and to check, than one
  habit. That is why `plan/` and `spike/` are swept too.
- The rule matches over a two-line window. Every command site today sits on
  one line, but a later rewrap that splits `tatr` from its subcommand would
  otherwise silently drop the site out of the gate.
- `flow/SKILL.md` had 3 words of body budget left and needed 4. Reclaimed 7 by
  cutting "and select the authoritative task root before reading state" to
  "to select `<task-root>`" - the sentence named the concept twice once the
  command carried the flag. Body is 298 of 300.
- `tatr new`, `ls`, `frontier`, `claim`, `release` and `claims` stay out of the
  rule: they either predate the record or quantify over the whole tree.

## Close-out

What/why: closed all three round-1 MINORs plus the NIT in one pass, since they
share one seam - afk's injected status vocabulary against the flow skills'
`## Output` contracts. `SPIKED` now appears in the PROTOCOL heredoc, so the
`SPIKED)` branch at afk.sh:445 is reachable by contract rather than by luck.
`AGENTS.md` now separates the shared literals from afk's own vocabulary.
`test_failure_paths` covers the goal-mode missing-record guard, and
`AFK_VERBOSE` gained a test in both states per DECISION.md. `compound`'s
`knowledge` call now names `--repo`.

Alternatives: deleting `AFK_VERBOSE` (rejected in DECISION.md - it is the only
in-tool way to watch a live session); fixing the `knowledge` skill's own `$PWD`
default (out of this repo's ownership, it comes from the `agent-knowledge`
input, so only this repo's caller could carry the warning).

Difficulties: the "missing record" DoD proof greps `-v` output, which prints
only assert descriptions, not the runner's stderr. The first description did
not contain the literal, so the proof stayed red while the case passed. Renamed
the check to "the failure says no such record exists".

Evidence: `afk-test.sh` 9/9 green (was 8); `-v | grep 'no such record'` passes;
`sprout-test.sh`, `skills/check.sh`, `tatr check` and `nix flake check`
(6 checks) all green.

Reflection: a `cmd:` proof that greps a test harness's own verbose output
couples the proof to assert wording. Asserting on the suite's exit status plus
a grep of the test source would have been less brittle.

## Close-out (round 2, the unrooted-tatr fix)

What/why: the afk run driving this task died at its `WORK_DONE` gate -
"20260802-143129 is in PLANNED, not WORKING". Diagnosis: the marker and the
cross-check were both correct; the session's `tatr flow <id> --to WORKING` ran
without `-r`, so it wrote the main checkout's stale copy while the sprout that
owns the task stayed PLANNED. Repaired by reverting the stray main-tree edit
and running the transition against the task root. The durable fix is that the
skills now name `-r <task-root>` at all 25 task-taking `tatr` sites, and
`check.sh` gained `unrooted-tatr-call` so a new unrooted call is a gate
failure rather than a silent write to the wrong checkout.

Alternatives: (a) state the rule once in prose instead of at every site -
rejected, prose is what already failed here, and no skill file is read by every
phase; (b) exempt the pre-worktree phases - rejected, see Notes; (c) harden
`afk.sh` to detect a lifecycle edit sitting uncommitted in main - rejected as
treating the symptom: afk already refused to build on state it could not see,
which is the behavior wanted.

Difficulties: `flow/SKILL.md` was 3 words under its 300-word router budget and
the sweep needed 4; the fix was cutting a phrase the flag made redundant, not
raising the budget. Rewrapping the touched paragraphs to 80 columns had to be
done in full - the first pass only rewrapped the lengthened line and pushed the
overflow onto its neighbor.

Evidence: `check.sh` clean (8 skills, 23 rules); `--rules` lists
`unrooted-tatr-call`; the falsification proof (unroot one gate row in a temp
copy) reports the finding; `afk-test.sh` 9/9; `sprout-test.sh` 16/16;
`tatr check` clean; `nix flake check` 6/6.

Reflection: the failure was a shell-cwd bug of exactly the class the work skill
already warned about for git paths ("use absolute worktree paths"), and the tatr
half of that warning was missing. Worth asking, of every tool the skills drive,
which of its arguments defaults to cwd.

## Close-out (round 3, review round 1 findings)

What/why: the round-1 review found the rooting sweep named `-r <task-root>`
everywhere but defined `<task-root>` nowhere outside `flow/resume.md`, and that
its referent silently changes between `work/SKILL.md` steps 1 and 2 - the exact
moment the original bug happened, and a spot the new lint cannot police, since
a wrongly-rooted call is still a rooted call. `work/SKILL.md` now names the
sprout as the new task root at the transition, and `flow/SKILL.md` states the
main checkout for a new ID. `check.sh`'s exemption comment was also wrong about
`claim`/`release`, which do take a task ID; it now gives each exempt subcommand
its real reason.

Alternatives: pulling `claim`/`release` into `TATR_ID_SUBS` - rejected, they
write `TATR_CLAIMS_DIR` rather than the checkout, so a root would be noise.
Defining `<task-root>` once in a shared reference - rejected, no file is loaded
by every phase, which is why the prose-only rule failed in the first place.

Difficulties: `work/SKILL.md` went 1 word over its 400-word budget on the first
wording; collapsing "is `<task-root>` from here on" to "becomes `<task-root>`"
bought the room back without losing the change-of-referent meaning.

Evidence: `check.sh` clean (8 skills, 23 rules); falsification proof and
`--rules` proof both pass; `afk-test.sh` 9/9; `sprout-test.sh` 16/16;
`tatr check` clean; `nix flake check` 6/6.

Reflection: a lint that checks the SHAPE of a call cannot check its REFERENT.
`unrooted-tatr-call` proves every site names a root; only prose can say which
root is right, so the two have to ship together. Round 2 shipped the half a
grep can enforce and assumed the other half was obvious.
