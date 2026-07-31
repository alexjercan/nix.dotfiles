# Checkpointing and resuming a flow

Read this when picking up a task another session (or an earlier context)
started, and when this session must hand its own task off. The files on disk
are the whole state; the previous conversation is gone and must not be guessed
at.

## 0. Hand off before you lose the context

A checkpoint is a normal flow move, not a failure. `work` owns the trigger.
At one, commit an atomic green step, then record the completed Step, the
commit and check results, and the next Step in TASK.md. A checkpoint is not a
lifecycle transition, so it runs no `tatr flow` - the phase you paused in is
the phase you resume in.

Then emit the fresh-session prompt. Its whole payload is:

```
/flow <id>
```

Add a line only for state the next session cannot discover from `tatr`, `git`
and `sprout` - uncommitted work you chose to leave, or an external thing you
started. Never a conversation summary: everything a summary would carry is
either on disk already or was never durable.

A checkpoint is not terminal, so the handoff report carries no status line -
SKILL.md's four all end a goal.

The agent records and verifies that state, then ASKS the user to run `/clear`.
It cannot invoke `/clear` or `/compact` itself and must never claim it can.
Automatic compaction by the runtime is not the handoff - the committed branch
and the updated TASK.md are.

## 1. Read the state, not the history

```bash
tatr show <id>
tatr context <id> --phase resume
```

`tatr show` reports the structured state - flow step, status, plan status,
dependencies, claim - and that state, not the previous conversation, decides
which phase comes next. `tatr context --phase resume` prints every artifact
path with `present|missing`.

Read only that phase's packet: the present artifacts the next phase needs, and
nothing else. Pulling the whole task folder in to orient yourself spends the
context the phase itself is about to need, and a resume that reads everything
is indistinguishable from never having split the files at all.

## 2. Find the branch

```bash
sprout ls
```

One line per worktree: `<feature> <branch> <path>`. A task in WORKING,
REVIEWING or COMPOUNDING should have one. If it does not, the work never
started or the worktree was removed - check `git branch --list` for the branch
before re-sprouting, because `sprout new` reuses an existing branch.

## 3. Re-enter at the FLOW STEP

The Route table in SKILL.md already names the skill and the transition for
every recorded step; dispatch from it, not from the previous session's intent.
Resuming adds three cautions to those rows:

- WORKING: read the worktree diff and the literal Steps in TASK.md first, then
  finish only the unticked ones.
- REVIEWING: read REVIEW.md before dispatching - an open BLOCKER or MAJOR
  finding is the fix row, not another review round.
- DONE: the task is closed, which says nothing about whether it landed.

A DONE task whose branch still exists in `sprout ls` did not land. Verify with
`git log <default> --oneline` before assuming either way.

## 4. Trust the records over the ticks

Unticked Steps with the work visibly done, or ticked Steps with nothing in the
diff, mean the previous session lost its context mid-edit. Re-read each step's
literal text against the branch diff and correct TASK.md before continuing.
Never tick from intent.

## 5. Report where you re-entered

State the task, the FLOW STEP you resumed at, and what the previous session
left half-done. Then continue the normal cycle.
