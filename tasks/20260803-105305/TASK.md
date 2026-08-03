# Replace afk's agent-driven gates with tatr flow and sprout land probes

- PRIORITY: 65
- TAGS: afk, scripts, agents
- KIND: TASK
- ACTIVITY: PLANNING
- GATES: -
- RESOLUTION: -
- DEPENDS ON: 20260803-105234

Every approval gate in afk currently costs a resumed Claude session
(`gate`/`lifecycle_gate` in `home/modules/scripts/afk.sh`), and everything
that session does is mechanical: `tatr flow <id>` for the three lifecycle
gates, and the `landing.md` sequence for the last one. Replace those sessions
with code. An agent is only worth waking when the mechanical path refuses.

Both halves of the contract are now available. `tatr flow -n` is a real probe
as of tatr v1.0.1 (flake bumped from v1.0.0; task 20260803-105225 in
~/personal/tatr), and `sprout sync` / `sprout land -n` / the compound landing
message landed with task 20260803-105234 in this repo. Nothing blocks the
work.

## The new gate shape

Probe, execute, verify - the same three steps for every gate:

| gate | probe | execute |
| --- | --- | --- |
| NOTES_READY, PLAN_READY, WORK_DONE | `tatr -r <root> flow -n <id>` | `tatr -r <root> flow <id>`, then commit the task records |
| LAND_READY | `sprout sync -n <feature>` then `sprout land -n <feature>` | `sprout sync`, then `sprout land -m <subject> -m <body>` |

The existing postcondition checks (`require_gate`,
`require_activity_at_least`, the landed-commit and branch-gone checks) stay
and get stronger: afk now observes the transition instead of trusting a
session's marker.

A non-zero probe is not a failure of the run. Start a fresh `/flow <id>`
session with the unmet text appended to the prompt and let it resolve the
block, then re-probe.

## Consequences to handle

- `--resume` and `SESSION_UUID` can leave `run_claude` entirely: the fallback
  is a fresh session, and durable state is all a fresh `/flow` ever needed.
  Confirm nothing else depends on the resume path before removing it.
- Double advance: a session that ran `tatr flow` itself after emitting its
  marker leaves the cursor already at the target. Treat at-or-past as
  satisfied and skip the call rather than dying, which is what
  `require_activity`'s equality does today.
- afk inherits the task-record commit that `gates.md` currently asks the
  session for. It runs in the main checkout before WORKING and in the sprout
  worktree after, and `sprout land` refuses a dirty main checkout, so it
  cannot be skipped. Open question: a mechanical message
  (`docs: advance <id> to PLANNING`) or something better.
- The landing message comes from the task record that compound wrote; afk
  reads it and passes it to `land -m`. A missing message is a refusal, not a
  guess.
- No verification step after the sync: review already proved the branch, and
  the user checks the default branch after the run.

## Boundary

afk depends on the tatr and sprout contracts, not on the flow skill's prose.
The skills keep describing the gates for a human-driven `/flow`; afk must not
require them to change. See task 20260803-003849.

Cover the new gate paths in `home/modules/scripts/afk-test.sh`.
