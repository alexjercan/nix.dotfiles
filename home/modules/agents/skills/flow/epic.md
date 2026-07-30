# Epic containers

Read this ONLY when the user asked, in those words, for a sprint, version,
release, epic or multi-feature goal. One requested thing is one task; a
container created for a single feature is pure overhead.

## Create the container

```bash
tatr new "Epic: <what it delivers>" -k EPIC -p 0 -t goal
tatr new "<child title>" -k STORY -P <epic-id> -p <priority> [-d <dep-id>,...]
```

`-k STORY` requires `-P`. `-d` records hard ordering; priority alone is a soft
hint. A child in ANOTHER repository is named in the body prose, not in
`-P`/`-d` - those hold IDs from one `tasks/` tree only.

Epic containers are exempt from plan approval, review, retro and
unchecked-Steps requirements. Their dependencies and DECISION.md are not.

## Container TASK.md sections

`tatr check` requires `## Done Means` and `## Child Tasks` on a `KIND: EPIC`.

```markdown
## Epic

What this epic delivers and why.

## Done Means

1. <criterion> (cmd: `<command that proves it>`)
2. <criterion> (manual: <what the user checks at Finish>)

## Child Tasks

- [ ] <task-id> (p<priority>, <repo>) <short title>
- [x] <task-id> (p<priority>, <repo>) <short title>
      landed <commit>; <n> review rounds; <anything notable>

## Decisions

- <task-id> DECISION.md: <one-line decision> (ACCEPTED)

## Manual Acceptance

- (pending) <task-id>: <what the user should confirm>
```

## Pick the next child

```bash
tatr frontier <epic-id>
```

One tab-separated row per open child: `<STATE> <id> p<priority> <flow step>
<title>`, plus `blocked-by=<ids>` on a BLOCKED row. STATE is READY, BLOCKED or
CLAIMED. Take the top READY row. Never read every child's TASK.md to choose.

Skip the container itself until Finish.

## Parallel sessions

`tatr claim <id>` is an atomic claim; exactly one racing session wins.
`tatr flow <id> --to WORKING` refuses a task another session holds. Ownership
is `TATR_SESSION` (default: the working directory). Set `TATR_CLAIMS_DIR` to
ONE shared directory across parallel worktrees, or each tree gets its own and
the guard can never fire. Nothing expires; `tatr release <id> --force`
recovers a claim from a session that is gone.

## Close the container

Only after its `## Done Means` are met. Verify each `cmd:`/`test:` criterion,
present the batched `## Manual Acceptance` items to the user, then
`tatr flow <epic-id> --to DONE`. Finish with `GOAL DONE <epic-id>`.

## Keep stories one-context sized

A child that cannot be understood, built and reviewed inside one context is
too big: split it before working it. Splitting mid-cycle is a stop-and-ask,
not a silent re-cut - and if two children turn out inseparable without
throwaway shim code, merge them into one cycle instead of grinding out the
shims.
