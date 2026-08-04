# Goals that span several tasks

Load only for an explicit sprint, release, or multi-feature goal. One requested
thing remains one task; this is about the edges between them.

A task has no kind. What makes one a container is that other tasks depend on
it, and what makes one a step is that it depends on others. Nothing else
distinguishes them: the same activities, the same gates, the same records.

## Create

```bash
tatr new "<title>" -p <priority> [-d <ids>] -t <tags>
```

`-d` is hard ordering - the task cannot start until those IDs resolve. Priority
is soft ordering within what is already startable. Dependencies accept only IDs
from the same `tasks/` tree; name cross-repo work in body prose.

Create the tasks the goal needs, then wire the edges. A dependency exists
because one task's output is another's input - not because you would prefer to
do them in that order. An edge that is only a preference is priority.

## Pick work

`tatr frontier <id>` returns the open work behind that task as READY, BLOCKED
or CLAIMED rows, with ID, priority, step, title and blockers. Take the top
READY row without opening every body. Resume the same way.

For parallel work, `tatr claim <id>` is atomic. Share one `TATR_CLAIMS_DIR`
across worktrees; ownership defaults to `TATR_SESSION` or the cwd. Claims do
not expire; recover an abandoned one with `tatr release <id> --force`.

## Keep the goal findable

The tasks are the index; do not copy their contents into a summary that goes
stale. What the graph itself cannot hold, the entry task's body records:

- what the whole goal delivers, and how anyone will know it landed;
- one line per deciding record, pointing at it rather than repeating it;
- the open questions, one sentence each, until a task answers one;
- what is deliberately out of scope, and why.

Keep pending user checks with the task that produced them.

## Close

A task closes when its own gates say so, whatever depends on it. When the last
dependent lands, verify the goal's stated proofs, batch any manual checks to
the user, and walk the entry task to closure with
`tatr -r <task-root> flow <id>`.

Retire work that is no longer wanted with
`tatr -r <task-root> close <id> --resolution WONTDO|SUPERSEDED --reason <why>`;
its dependents are then unblocked or retired with it, never left pointing at a
task nobody will do. Report `FLOW_DONE <id>`.

Tasks are sized by the `plan` skill's reviewable-context and shim rules. Ask
before splitting mid-cycle.
