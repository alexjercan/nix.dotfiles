# Goal: harden flow planning and resume gates

- DATE: 20260725
- UMBRELLA TASK: 20260725-110435
- LANDING SCOPE: squash-merge each nix.dotfiles task to master, no push. If the
  implementation needs tatr CLI changes, land the matching tatr task in
  /home/alex/personal/tatr on master as its own squash commit, no push.

## Goal

Harden the flow-family skills and tatr checker so an agent cannot start work
from an unconfirmed or merely checkbox-shaped task. A flow that is run against
an existing task must reuse that task as its durable context, start from
problem understanding, record what phase it is in, and refuse implementation
until the task is explicitly marked planned or has the full planning artifacts.

## Done means

1. Flow skill supports both new-goal and existing-task entry: `flow task <id>`
   reuses the named task folder and never creates a new umbrella unless the user
   explicitly asks for a broader goal (cmd: `grep -n "existing task" home/modules/agents/skills/flow/SKILL.md`).
2. Flow and plan skills require an understanding/confirmation phase before
   planning, including user-facing questions or explicit assumptions when the
   task text is incomplete, stale, or potentially wrong (cmd: `grep -rn "Understand" home/modules/agents/skills/{flow,plan}/SKILL.md`).
3. Task phase state is durable on disk: planned tasks carry an explicit marker
   that a fresh session can parse, and the skills state that unchecked Steps
   alone never prove planning happened (cmd: `grep -rn "FLOW STEP" home/modules/agents/skills`).
4. Work refuses to implement an unplanned task and points the user back to flow
   or plan; it no longer treats a `## Steps` checklist by itself as enough
   authority to start implementation (cmd: `grep -n "refuse" home/modules/agents/skills/work/SKILL.md`).
5. `tatr check` in /home/alex/personal/tatr catches the process drift that can
   be enforced mechanically, with integration tests and docs updated from the
   real CLI behavior (cmd: `cd /home/alex/personal/tatr && nix develop -c ./checker.sh`).
6. The deployed skill source in nix.dotfiles and the tatr skill docs describe
   the new phase markers and checker rule without stale examples (cmd: `grep -rn "planned" home/modules/agents/skills/{flow,plan,work,tatr}/SKILL.md`).
7. Both repositories' conformance gates are clean: nix.dotfiles runs
   `/home/alex/personal/tatr/tatr check` and
   `/home/alex/personal/tatr/tatr check --ledger LESSONS.md`; tatr runs
   `./tatr check` and `./tatr check --ledger LESSONS.md` after its suite
   (cmd: `/home/alex/personal/tatr/tatr check --ledger LESSONS.md`; manual:
   tatr repo gate output reviewed after the tatr task lands).

Overall: nix.dotfiles `nix flake check --no-build` and tatr
`nix develop -c ./checker.sh` are green, or any pre-existing failure is
verified against master and recorded with a follow-up task.

## Tasks

Updated as tasks land (one line per land, like a spike's Fix record).

## Decisions (load-bearing, architectural)

Index of the DECISION.md records this goal produced.

## Manual acceptance (batched for the user at Finish)

Accumulates `manual:` DoD items as tasks land; presented at Finish.

- (pending) tatr repo gate output reviewed after the tatr task lands.
