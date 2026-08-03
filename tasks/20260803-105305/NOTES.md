# Notes: Replace afk's agent-driven gates with tatr flow and sprout land probes

## What changes

Before: every approval gate in `afk run` spends a whole Claude session. afk
prints `gate ... approved automatically`, then `run_claude resume
"$SESSION_UUID" "<the exact gates.md approve label>"` and lets that resumed
session run `tatr flow`, commit the task records, or walk `landing.md`'s five
steps by hand. Four gates per task, four resumed sessions, and everything they
do is mechanical.

After: afk performs the gates itself. Each gate is probe, execute, verify:

| gate | probe | execute |
| --- | --- | --- |
| NOTES_READY, PLAN_READY, WORK_DONE | `tatr -r <root> flow -n <id>` | `tatr -r <root> flow <id>`, then commit `tasks/<id>` in `<root>` |
| LAND_READY | `sprout sync -n <feature>`, then `sprout land -n <feature> -m <subject>` | `sprout sync <feature>`, then `sprout land <feature> -m <subject> [-m <body>]` |

Visible differences to a user watching a run:

- Session count roughly halves. A task that took eight sessions takes four.
- A gate line still prints, but the next line is a commit or a landing, not a
  new `session <uuid>` header.
- A refused probe is not a failure: afk starts a **fresh** `/flow <id>` session
  with the probe's unmet text appended to the prompt, so an agent is woken only
  when the mechanical path refuses.
- `--resume` disappears from afk entirely; every claude invocation is fresh.

## Surfaces

| File | Why |
| --- | --- |
| `home/modules/scripts/afk.sh` | the whole change: `gate`, `lifecycle_gate`, the `LAND_READY` arm, `run_claude`'s resume mode, and the `PROTOCOL` heredoc |
| `home/modules/scripts/afk-test.sh` | fixtures currently script the transitions inside the fake claude's side scripts; afk does them now, so those side scripts shrink and new probe/refusal cases appear |
| `home/modules/scripts/afk.nix` | `runtimeInputs` needs `sprout`, which is not a `pkgs` attribute today |
| `home/modules/scripts/sprout.nix` | to give afk the sprout derivation, the `writeShellApplication` moves into a file both modules import |
| `AGENTS.md` | line 87 already says afk.sh and afk-test.sh change together; the checks list may need no edit |

Nothing under `~/.claude/skills/` is touched. The flow skills keep describing
the gates for a human-driven `/flow`; that boundary is task 20260803-003849.

## Data and interfaces

Removed:

- `gate()` - the one-resume helper. Nothing replaces it directly.
- `run_claude`'s `$1` mode parameter and the `--resume` branch. Signature
  becomes `run_claude <session-uuid> <prompt>`; it always passes
  `--session-id`.

Added (bash, so "signature" means positional arguments and the globals read):

- `probe <root> <id>` -> exit status of `tatr -r <root> flow -n <id>`, with the
  refusal text left in `PROBE_TEXT` (tatr writes unmet lines to **stderr**, one
  `  - <message>` per line).
- `commit_records <root> <id> <message>` - `git -C <root> add tasks/<id>` then
  commit. A no-op when the add stages nothing, because a double advance leaves
  the record already committed.
- `advance <id> <target-activity-or-gate> <human name>` - the replacement for
  `lifecycle_gate`. Reads `task_root`, checks the at-or-past skip, probes,
  executes, commits, then runs the existing `require_gate` /
  `require_activity_at_least` postcondition.
- `land <id>` - the `LAND_READY` arm's body: read the landing message, sync,
  probe, land.
- `landing_message <root> <id>` -> the subject on line 1 and the body on the
  rest, read from the fenced block under `## Landing message` in
  `<root>/tasks/<id>/RETRO.md`. Missing section or empty subject is a `die`,
  never a guess.

Unchanged and still load-bearing: `task_root`, `task_activity`, `task_gates`,
`activity_rank`, `require_activity`, `require_record`,
`require_activity_at_least`, `require_gate`, `require_resolution`,
`require_progress`, `fingerprint`, `report_phase`, `report_commits`.

The `AFK <STATUS> <id>` marker vocabulary keeps every status. `ROTATE` still
means a mid-phase context handoff; the four gate statuses now mean "I stopped
at the gate", full stop, since the session no longer performs the transition.

## Sketches

Illustrative only, not a patch.

The PROTOCOL heredoc loses the transition instruction:

```
-Once the runner answers a gate, perform that gate's lifecycle transition,
-commit the task records, then stop and report ROTATE. Do not continue into the
-next phase; it gets a fresh context.
+When the flow reaches an approval gate, summarize the phase, report the gate's
+status and end the turn. The runner performs the transition itself; do not run
+`tatr flow`, do not commit the task records, and do not continue into the next
+phase.
```

The gate body, replacing the resume:

```bash
advance() {                     # $1 id  $2 want  $3 kind  $4 human name
    local root; root=$(task_root "$1") || die ...
    if at_or_past "$1" "$3" "$2"; then          # the double-advance case
        line "$C_GATE" gate "$4 - already advanced by the session"
        return 0
    fi
    if ! PROBE_TEXT=$(tatr -r "$root" flow -n "$1" 2>&1 >/dev/null); then
        line "$C_GATE" gate "$4 - refused; waking a session to resolve it"
        return 1                                # caller starts a fresh /flow
    fi
    tatr -r "$root" flow "$1" >/dev/null || die "..."
    commit_records "$root" "$1" "docs: advance $1 to $2"
}
```

The refusal route in `run_item`, where a fresh session gets the unmet text:

```bash
prompt="/flow $TASK_ID"
[[ -z $PENDING_UNMET ]] ||
    prompt+=$'\n\n'"The gate refused:"$'\n'"$PENDING_UNMET"
```

## Shape

```
run_item loop, one task
  |
  +-- run_claude fresh "/flow <id>"        <- the only agent work left
  |     |
  |     +-> marker
  |
  +-- ROTATE ---------------------> require_progress, loop
  |
  +-- NOTES_READY / PLAN_READY / WORK_DONE
  |     require_activity + (NOTES.md)
  |     at_or_past? --yes--> skip execute
  |         |no
  |     tatr flow -n  --refused--> stash unmet text, loop (fresh /flow)
  |         |ok
  |     tatr flow, commit tasks/<id> in <root>
  |     require_gate / require_activity_at_least
  |     loop
  |
  +-- LAND_READY
  |     require_resolution DONE, branch exists
  |     landing_message <- RETRO.md '## Landing message'
  |     sprout sync -n  --conflict--> stash text, loop (fresh /flow resolves it)
  |     sprout sync
  |     sprout land -n  --refused--> stash text, loop
  |     sprout land -m subject -m body
  |     landed-commit + branch-gone checks   (unchanged)
  |     done
  |
  +-- DONE / BLOCKED / SPIKED               (unchanged)

<root> is the main checkout before WORKING and the sprout worktree after,
which is exactly what task_root already returns.
```

## Consequences and open questions

**Unblocked; the probe is real.** tatr v1.0.1 (flake input bumped from v1.0.0)
makes `tatr flow -n` run the same preconditions as the write and exit non-zero
when they fail. Verified against this task, which sits at PLANNING with no
`## Steps`:

```
$ tatr flow -n 20260803-105305; echo $?
Task 20260803-105305 would move PLANNING -> WORKING      # stdout
  gate PLAN would run                                    # stdout
ERROR: tatr.c:5951: Would refuse to advance ... 2 precondition(s) not met
  - bad-record-schema: TASK.md has no '## Steps' section
  - bad-record-schema: TASK.md has no '## Definition of Done' section
  Record unchanged.
1
```

So the sketch's `PROBE_TEXT=$(tatr -r "$root" flow -n "$1" 2>&1 >/dev/null)`
capture is correct: the "would move" preamble goes to stdout, and the refusal
plus its `  - <message>` lines go to stderr.

One wrinkle: **tatr colors the ERROR label unconditionally.** The escape
sequences survive a redirect to a file, and neither `NO_COLOR=1` nor
`TERM=dumb` suppresses them. `PROBE_TEXT` is appended to a `/flow` prompt, so
afk must strip ANSI (`sed 's/\x1b\[[0-9;]*m//g'`) before using it. Test
assertions on refusal text need the same treatment.

The sprout half was already available: `sprout sync`, `sprout sync -n` and
`sprout land -n` all exist on the installed binary (task 20260803-105234,
DONE).

**Packaging.** `sprout` is not `pkgs.sprout`; it is an inline
`writeShellApplication` inside `home/modules/scripts/sprout.nix`. afk needs the
binary on its PATH, so the derivation has to move somewhere both modules can
import - a `sprout-pkg.nix` taking `pkgs` and returning the derivation is the
smallest change. The test suite needs the same thing differently: `afk-test.sh`
should put a shim for `home/modules/scripts/sprout.sh` on PATH next to the fake
`claude`, so the tests exercise the working tree's sprout rather than whatever
is installed.

**The commit message.** TASK.md leaves it open. `docs: advance <id> to
PLANNING` is mechanical and honest; the alternative is reusing the task title,
which reads better but duplicates what the record already says. Recommendation:
the mechanical form, because the commit exists to keep the tree clean for
`sprout land`, not to describe the change. Decide before writing the plan.

**`sprout land -n` needs `-m`.** The dry run refuses without a subject, by
design, so the landing message has to be read from RETRO.md *before* the probe,
not between the probe and the land. A missing `## Landing message` is therefore
a refusal that arrives before any sync happens - which is the right order.

**Removing `--resume`.** `gate()` is the only caller of the resume branch, and
`SESSION_UUID` survives as the `--session-id` for fresh sessions and for the
`session <uuid>` header line. `test_argv_session_and_resume_policy` asserts the
resume policy explicitly and has to be rewritten rather than deleted: the new
invariant is "every invocation is fresh", which is still worth an assertion.

**Test surface.** `gen_work_to_land` and `gen_goal_cycle` script `tatr flow`
and the landing inside the fake claude's side scripts. Those halves move out of
the fixtures and into afk, so the fixtures get shorter but every existing
invocation number shifts - the gate invocations disappear entirely. That
renumbering touches most of the suite, and it is the single largest mechanical
risk in this task.

**What is lost.** A resumed gate session could, in principle, notice something
wrong and refuse in prose. Mechanical gates cannot; they only see exit codes
and durable state. That is the intended trade: TASK.md's rule is that an agent
is worth waking only when the mechanical path refuses.

**Open: does `no verification after sync` hold?** TASK.md says yes - review
already proved the branch and the user checks the default branch afterwards.
`landing.md` step 2 asks a human-driven flow to re-verify. afk deliberately
skips it. Worth stating in the plan so it is a decision, not an omission.
