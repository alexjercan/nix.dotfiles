# keep the flow skills free of afk, and state the boundary

- PRIORITY: 55
- TAGS: agents,skills,afk
- KIND: TASK
- ACTIVITY: -
- GATES: -
- RESOLUTION: -
- DEPENDS ON: 20260803-002416

The dependency between the flow-family skills and the afk runner goes one way
and must keep going one way: `afk.sh` depends on the skills and on tatr's state
machine; no skill may depend on, mention, or be shaped for afk. afk drives
Claude by injecting its own `AFK <STATUS> <id>` protocol; whatever steering it
needs belongs in that heredoc, not in a skill that also runs for a human at an
interactive prompt in some other repository.

This is worth a task because the boundary currently holds by luck rather than
by statement. Nothing says it, nothing checks it, and one clause already
drifted across.

## What a scan found

No flow-family skill contains the string `afk`, or `unattended`, `runner` or
`headless`. So this is an audit, a stated invariant and a guard - not a rewrite.
Do not manufacture findings to justify the task; an audit that confirms the
files are clean has done its job.

Known drift, and the one clause that motivated this:

- `review/SKILL.md` step 2, "A fresh `/flow <id>` session that starts at
  REVIEWING counts as the outside reviewer; do not spawn another by default",
  repeated in `review/rounds.md`. It only pays off when something automatically
  starts a fresh session at each phase, which is afk's rotation and nothing
  else. It is already being deleted by 20260803-002416, for an independent
  reason - hence the dependency. Treat it as the worked example of the drift
  this task exists to prevent, not as work to do again.

Clauses to re-derive rather than assume - each is either justified without afk
or it goes:

- `flow/gates.md`, "Use the runtime's blocking user-question tool when it is
  available. Otherwise ask one direct blocking question and end the turn." The
  hedge is TRUE of codex and opencode, which have no such tool, and it is also
  exactly the accommodation afk needs, since afk runs claude with
  `--disallowed-tools AskUserQuestion`. Keep it only on the first ground, and
  make the wording carry that reason.
- `flow/SKILL.md` `## Output`, which requires one status token from a fixed set.
  Ask whether that shape serves flow's own routing and a human reader, or
  whether it is there for a parser. If the former, it stays as it is.

## Restate the coupling in AGENTS.md, which overstates it

`AGENTS.md` under `## Skills are a doc surface` says afk "routes on `SPIKED`,
`PLAN_READY`, `WORK_DONE` and `LAND_READY` from the skills' `## Output`
contracts". That is not what the code does. `parse_marker` greps
`^AFK [A-Z_]+ <id>`, so afk reads ONLY the marker its own PROTOCOL defines; all
seven statuses, the four shared names included, are declared in that heredoc.
The name overlap is convenience, not a channel.

The single real coupling is the three approve labels: `afk.sh` sends the
`flow/gates.md` table's labels verbatim, so editing a label breaks afk. That is
the permitted direction - afk knows about flow - and it stays. Say it precisely,
in one place, on afk's side of the boundary.

## Deliverables

- The invariant stated where an agent editing either side will read it:
  `AGENTS.md` `## Skills are a doc surface`, and `skills/README.md` if it earns
  a line there too. Name the direction, name the one shared surface (the
  approve labels), and say that a steering need discovered while running under
  afk is fixed in afk's PROTOCOL.
- The AGENTS.md paragraph corrected to match `parse_marker`.
- Any clause that survives the audit only because afk exists, deleted or
  reworded.
- Optionally a `check.sh` rule failing any flow-family skill that contains
  `afk`. It is three lines and matches the gate's existing structural
  character. Be honest about what it buys: it catches the NAME, never the
  shape, and the clause that actually drifted would have passed it. Worth
  having as regression insurance, not as the guarantee.

## Precedent to preserve

20260803-002416 needs a session to stop at the context cut after a gate. It
puts that in afk's `PROTOCOL` heredoc, not in `flow/gates.md`. That is the rule
this task is generalizing, and it is the test to apply to the next such
request: if the fix is only needed because a runner is driving, it belongs to
the runner.
