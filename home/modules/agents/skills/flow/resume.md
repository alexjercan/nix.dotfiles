# Resuming an interrupted flow

Read this when picking up a task another session (or an earlier context)
started. The files on disk are the whole state; the previous conversation is
gone and must not be guessed at.

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

| FLOW STEP | Resume by |
| --- | --- |
| BACKLOG, UNDERSTANDING | flow step 2 |
| PLANNING | invoke `plan`, then the gate |
| PLANNED | invoke `work` (plan is already approved) |
| WORKING | read the branch diff and TASK.md Steps, finish the unticked ones |
| REVIEWING | read REVIEW.md; open BLOCKER/MAJOR findings -> `work`, else `review` |
| COMPOUNDING | invoke `compound`, then land |
| DONE | the task is closed; check whether the branch actually landed |

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
