# Review: Add an unattended afk flow runner

- TASK: 20260802-132348
- BRANCH: feature/afk-flow-runner

## Round 1

- REVIEWER: out-of-context
- VERDICT: APPROVE

- [ ] R1.1 (MINOR) home/modules/scripts/afk.sh:65 - the injected PROTOCOL lists
  six statuses (PLAN_READY, WORK_DONE, LAND_READY, ROTATE, DONE, BLOCKED) but
  afk.sh:442 routes on a seventh, SPIKED. A session obeying the protocol
  literally cannot emit it, while a session obeying `flow/SKILL.md`'s `## Output`
  contract will. Add a `SPIKED  the flow spiked this task and seeded others`
  line to the PROTOCOL status list so the branch is reachable by contract.
  - Response:
- [ ] R1.2 (MINOR) AGENTS.md:80 - the new paragraph says afk "routes on the
  statuses in the skills' `## Output` contracts". ROTATE, DONE and BLOCKED
  appear in no skill `## Output` contract; they are afk's own vocabulary,
  defined in the PROTOCOL heredoc. As written the docs-sync warning points a
  future editor at the wrong file. Reword to: the three approve labels in
  `flow/gates.md` are the shared literal contract, and `SPIKED`/`PLAN_READY`/
  `WORK_DONE`/`LAND_READY` from `flow/SKILL.md` map into afk's PROTOCOL block.
  - Response:
- [ ] R1.3 (MINOR) home/modules/scripts/afk.sh:390 - on a goal run, the guard
  that the marker's newly-minted task ID actually has a record is the one
  failure branch with no case in `test_failure_paths`. Add a case: invocation 1
  emits `AFK PLAN_READY 19990101-000000` with no side effect, and assert the
  run exits nonzero naming "no such record".
  - Response:
- [ ] R1.4 (NIT) home/modules/scripts/afk.sh:46 - `AFK_VERBOSE` is a knob no
  Step asked for. It is one small branch and genuinely useful for diagnosing a
  run that looks hung, so keep it if you want the diagnostic; delete
  afk.sh:241-246 and the usage line if you do not.
  - Response:

Verification performed by this reviewer, independently of the implementing
session:

- Ran the whole DoD suite from the worktree: `afk-test.sh` 8/8 (~15s),
  `sprout-test.sh` 16/16, `skills/check.sh` clean (8 skills, 22 rules),
  `tatr check` rc=0, `nix flake check` all 6 checks passed, and the packaged
  binary proof `test -x .../bin/afk` passes after a real `nix build`.
- Re-derived the load-bearing claim that the tests pin behavior rather than
  execute code, by mutating a scratch copy of `afk.sh` four ways: dropping the
  post-gate `require_step`, disabling the fingerprint stop, reusing one
  session UUID across worker turns, and deleting the surviving-branch check
  after landing. Each mutation turned exactly one case red; none was silently
  tolerated.
- Re-derived the gate labels character by character against
  `home/modules/agents/skills/flow/gates.md` and the deployed
  `~/.claude/skills/flow/gates.md`: all three match exactly.
- Re-read every ticked Step against the diff; all seven are delivered.
- Doc-surface sweep: grepped README.md, the global agents AGENTS.md and the
  skills README for the changed script inventory and check list; no stale
  mentions remain, and the `sprout/daily/today` -> `sprout/afk/today` edit is
  correct since no `daily` script exists in `home/modules/scripts/`.
- Honesty: the close-out's claims match the code. It names the two unverified
  assumptions (that `claude -p "/flow <id>"` resolves the repo skill, and that
  a gate surfaces as an ended turn once AskUserQuestion is denied) instead of
  claiming them proven, and `DECISION.md` carries the implementation addendum
  for the three choices a cold reader would need the *why* of.

Pending user checks, which do not block this verdict:

- The real end-to-end run against a live Claude, blocked by the account's
  weekly rate limit. Until it happens, the two assumptions above are open.

Process signal: the plan's audit-log example implied scraping Claude's prose
for FLOW/COMMIT lines; the implementation derives them from `tatr` and `git`
instead, and added `pkgs.tatr` to `runtimeInputs` that Step 6 did not list.
Both are improvements, but they are plan-level details the planning phase got
wrong in the same direction - it under-specified where authority lives.

Inspection commands:

```bash
cd "$(sprout show feature/afk-flow-runner)"
git diff master --stat
bash home/modules/scripts/afk-test.sh
nix flake check
```
