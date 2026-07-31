# Delegating a bounded Step

Handing one Step to a subagent keeps the implementation context bounded
without weakening verification - the parent still proves everything itself.
When the whole task must move instead, `flow/resume.md` owns that handoff.

## Thresholds

120K visible context tokens is the soft checkpoint: finish the current step,
commit, and decide whether to continue or delegate. 150K is the hard ceiling.
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
