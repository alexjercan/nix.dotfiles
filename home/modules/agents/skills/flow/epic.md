# Epic containers

Load only for an explicit sprint, release, epic, or multi-feature goal. One
requested thing remains one task.

## Create

```bash
tatr new "Epic: <delivery>" -k EPIC -p 0 -t goal
tatr new "<child>" -k STORY -P <epic-id> -p <priority> [-d <ids>]
```

STORY requires an EPIC parent. `-d` is hard ordering; priority is soft.
Relationships accept only IDs from the same `tasks/` tree; name cross-repo
work in body prose.

EPIC skips plan approval, review, retro, and unchecked-Steps gates, but not
dependencies or DECISION validation.

## Index

The container maps, never copies, children:

- Destination: `## Epic` and proof-bearing `## Done Means`.
- Decisions: one line pointing to each deciding record.
- Frontier: derive with `tatr frontier <epic-id>`; never hand-maintain.
- Fog: one sentence per in-scope question until discovery graduates it.
- Out of Scope: boundaries and reasons.

`tatr check` requires `## Done Means` and `## Child Tasks`. Child rows record
ID, priority, repo, title, and landed result. Keep pending user checks under
`## Manual Acceptance`.

## Pick work

`tatr frontier <epic-id>` returns READY, BLOCKED, or CLAIMED rows with ID,
priority, step, title, and blockers. Take the top READY row without opening
all child bodies. Resume the same way: index, frontier, selected child.

For parallel work, `tatr claim <id>` is atomic. Share one `TATR_CLAIMS_DIR`
across worktrees; ownership defaults to `TATR_SESSION`/cwd. Claims do not
expire; recover an abandoned one with `tatr release <id> --force`.

## Close

After children land, verify every Done Means proof, batch Manual Acceptance to
the user, then `tatr flow <epic-id> --to DONE`. Report
`GOAL DONE <epic-id>`.

Children are sized by the `plan` skill's reviewable-context and shim rules.
Ask before splitting mid-cycle.
