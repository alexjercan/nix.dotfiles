# Delegation and context checkpoints

Two ways to keep an implementation context bounded: hand one Step to a
subagent, or checkpoint and hand the whole task to a fresh session. Neither
weakens verification - the parent still proves everything itself.

## Thresholds

120K visible context tokens is the soft checkpoint: finish the current step,
commit, and decide whether to continue. 150K is the hard ceiling - hand off.
When token usage is unavailable, the trigger is the first compaction warning,
or an active working set that no longer fits one focused pass.

## Delegating one Step

Delegate when a Step or proof is independently bounded, or when reading the
files it needs would cost more context than the Step is worth.

What the subagent RECEIVES, and nothing else:

- the task ID, the branch, and the worktree path
- exactly one Step or one proof, quoted literally
- the files it exclusively owns for the duration
- the paths it may read, and the checks it must run
- the shape of its return

Never the implementing conversation, a summary of it, or unrelated task
context - those carry the assumptions the fresh context exists to exclude.

What it RETURNS: the commit, the files changed, the proof results, and any
unresolved fact. Durable detail belongs in the code, the tests and the task
records, not in return prose.

## One writer

A worktree has one writer at a time. While a subagent holds its files the
parent edits none of them, and waits rather than working ahead elsewhere in
the same tree.

When the subagent returns, the parent re-reads the commit and its diff, then
runs the proof independently before integrating. A returned claim is a claim,
not evidence. The parent keeps the task records, the lifecycle transitions and
the final verification; a subagent never runs `tatr flow` and never lands.

Truly parallel work becomes its own Story and its own sprout worktree. Do not
add a second writer to one worktree, and do not build a multi-branch
integration scheme for it.

## Checkpointing for a fresh session

At a checkpoint, finish an atomic green step if one is close, and commit it.
Uncommitted work does not survive the handoff.

Then record in TASK.md what the next session cannot re-derive: the Step just
completed, the commit and check results, and the next Step to take. Tick only
what is genuinely done.

Then hand off. Leave the task at its current FLOW STEP, report the task ID,
the branch and the next Step, and ask the user to clear the session. The agent
cannot invoke `/clear` or `/compact` itself and must never claim it can.
Automatic compaction by the runtime is not the contract - the committed branch
and the updated TASK.md are.
