# Notes: sprout sync, land --dry-run, a remembered target, and a compound-written landing message

## What changes

Today landing is three hand-driven steps out of `flow/landing.md`: an agent
merges the default branch into the feature branch, invents a squash commit
message from the diff, then runs `sprout land`. Only the message needs
judgement, and the branch's landing target is guessed at land time from
whatever the main checkout happens to have checked out.

After:

| Step | Before | After |
| --- | --- | --- |
| merge target into feature | `git -C "$(sprout show f)" merge master` by hand | `sprout sync f` |
| probe whether it will work | nothing; you find out by doing it | `sprout sync -n f`, `sprout land -n f` |
| which branch is the target | main checkout's current branch, at land time | `sprout.target`, recorded at `sprout new` |
| the commit message | written at land time by whoever lands | written by `compound`, into `RETRO.md` |

Net effect: a script (afk) can drive the whole landing without ever reading a
diff, and a human gets two read-only probes that were not available before.

## Surfaces

| File | Why |
| --- | --- |
| `home/modules/scripts/sprout.sh` | new `cmd_sync`; `-n` for `land`; record and prefer `sprout.target`; usage text |
| `home/modules/scripts/sprout-test.sh` | integration cases for sync, dry-run land, and the target config |
| `home/modules/agents/skills/sprout/SKILL.md` | `sync` is a command the CLI now has; `land` gains `-n` |
| `home/modules/agents/skills/flow/landing.md` | step 1 becomes `sprout sync`; step 4 reads the message from RETRO.md |
| `home/modules/agents/skills/compound/SKILL.md` | compound now also writes the landing message |
| `AGENTS.md` | only if the check list changes; it should not |

Not touched: `afk.sh`. It already gates LAND_READY and delegates the landing
to the session. Teaching the runner to call `sprout land -m` itself is the
thing this task makes *possible*, not the thing it does.

## Data and interfaces

New shell functions in `sprout.sh`:

```
resolve_target <worktree-path>    -> prints the landing target branch
    git -C <wt> config --worktree --get sprout.target, else
    git -C "$main_worktree" symbolic-ref --quiet --short HEAD
    empty + non-zero when neither resolves (detached main, no config)

land_guards <feature> <path> <target>  -> 0 when a land would be allowed
    every existing cmd_land refusal, read-only, same messages

cmd_sync <feature> [-n|--dry-run]
    dry:  git merge-tree --write-tree --name-only --no-messages <target> <feature>
          exit 0 clean; exit non-zero + conflicting paths on stderr
    real: git -C <worktree> merge <target>
          conflicts stay in the worktree; "Already up to date" is success

cmd_land <feature> [-n|--dry-run] -m <subject> [-m <body>]
```

Worktree-local git config, both written at `sprout new`:

- `sprout.task` - unchanged, only with `--task`
- `sprout.target` - new, the main checkout's current branch at sprout time

`ls` output stays `BRANCH TASK PATH`; the target is not a column. Nothing
downstream reads it positionally today, and a fourth column is a display
change nobody asked for.

`RETRO.md` gains one section, after `## Action items`:

    ## Landing message

    ```
    feat: add sprout sync and land --dry-run

    Body paragraph.
    ```

A fenced block, subject / blank / body, so `awk` can lift it. `tatr` validates
only that a record's four schema sections are present and non-empty; extra
sections pass `tatr check`, so no `tatr` change is needed. A separate record
kind would need one - the kinds are a fixed enum in `tatr.c` - which is why
this lives in RETRO.md.

## Sketches

Illustrative only, not the patch.

`cmd_sync`, the dry-run half:

```diff
+    if [[ $dry_run == true ]]; then
+        conflicts=$(git merge-tree --write-tree --name-only --no-messages \
+                        "$target" "$feature" 2>&1)
+        rc=$?
+        [[ $rc -eq 0 ]] && exit 0
+        echo "sprout: merging '$target' into '$feature' would conflict:" >&2
+        echo "$conflicts" | tail -n +2 >&2   # drop the tree oid line
+        exit 1
+    fi
+    git -C "$path" merge "$target" 1>&2 || {
+        echo "sprout: merge conflicted; resolve it in $path, then commit" >&2
+        exit 1
+    }
```

`land`, factoring the guards so `-n` is a return rather than a second copy:

```diff
-    if [[ -n $(git -C "$main_worktree" status --porcelain --untracked-files=no) ]]; then
-        echo "sprout: main checkout has staged or modified files; ..." >&2
-        exit 1
-    fi
+    land_guards "$feature" "$path" "$target" || exit 1
+    if [[ $dry_run == true ]]; then
+        echo "sprout: '$feature' would land onto '$target'"
+        exit 0
+    fi
```

`new`, recording the target next to the task:

```diff
-    if [[ -n $task ]]; then
-        if ! git -C "$main_worktree" config extensions.worktreeConfig true ||
+    target=$(git -C "$main_worktree" symbolic-ref --quiet --short HEAD)
+    if [[ -n $task || -n $target ]]; then
+        git -C "$main_worktree" config extensions.worktreeConfig true || fail
+        [[ -z $target ]] || git -C "$path" config --worktree sprout.target "$target"
```

## Shape

```
  sprout new feat --task ID
        |
        +-- worktree config: sprout.task = ID
        +-- worktree config: sprout.target = <main checkout's branch>   NEW
        |
        v
  ... work, review, compound ...
        |
        +-- compound writes RETRO.md "## Landing message"              NEW
        |
        v
  LAND_READY gate
        |
        v
  sprout sync -n feat   ---> conflicts? ---> resolve in the worktree   NEW
        |                                          |
        v                                          |
  sprout sync feat  <--------------------------------
        |            (merge target into feature, inside the worktree)
        v
  re-verify on the branch (unchanged, still the caller's job)
        |
        v
  sprout land -n feat   (all guards, writes nothing)                   NEW
        |
        v
  sprout land feat -m "<subject from RETRO.md>" -m "<body>"

  target resolution, used by both sync and land:
      sprout.target (worktree config)  ->  main checkout symbolic-ref  ->  fail
```

## Consequences and open questions

Costs and constraints:

- `compound/SKILL.md` has a 390-word body against a 400-word `phase-body-budget`
  in `home/modules/agents/skills/check.sh`. The landing-message instruction has
  ~10 words of headroom. Either it is stated that tightly, or existing prose is
  trimmed to pay for it. A new reference file is the worse trade: the reference
  graph check requires it be reachable from a `## Load on demand` bullet, which
  costs body words too. `landing.md` (466 of 600) and `sprout/SKILL.md` (254 of
  400 body) both have room.
- Two verbs where there was one hand-written command. `sync` is deliberately
  not folded into `land`: an auto-merge inside `land` can conflict and would
  leave a half-merged worktree behind, and `land` is documented as atomic.
- `merge-tree --write-tree` writes loose objects into the shared object db.
  Harmless (unreferenced, gc-able) but worth knowing: "dry run" is not
  literally zero-write, it is zero-ref, zero-index, zero-worktree.
- Verification after `sync` stays outside sprout, per the task. `sync` can turn
  a test red and say nothing.

Open questions:

1. **What `land` does when `sprout.target` and the main checkout's branch
   disagree.** `land` squash-merges into whatever branch the main checkout has
   checked out - that is what `git merge --squash` in that worktree means. If
   `sprout.target` says `master` but main has `other` checked out, "prefer
   `sprout.target`" cannot mean "land onto master"; it would check ancestry
   against one branch and commit onto another. Recommended: `land` refuses the
   mismatch, naming both branches, and tells the caller to check out the target.
   `sprout.target` then makes the existing implicit assumption explicit and
   checkable rather than changing where things land. Assumption taken unless
   corrected.
2. **Whether `land -n` still requires `-m`.** The task lists the guards to run
   read-only and the message is not among them. But `-n` should answer "would
   this exact call succeed", and a message-less `-n` that reports OK describes
   a call `land` would refuse. Recommended: `-n` requires `-m` like the real
   thing. Cheap to relax later; not cheap to un-lie.
3. **Recording `sprout.target` needs `extensions.worktreeConfig` on for every
   `new`**, not just `--task` ones. That is a repo-level config write on a
   previously read-only-for-plain-`new` path. Assumed acceptable - it is the
   same write `--task` already performs, and it is idempotent.
4. Existing worktrees have no `sprout.target`. The fallback keeps them working,
   so there is no migration; the guard in (1) simply cannot fire for them.
