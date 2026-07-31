# Verification: tatr v2 adoption and nix task history

Recorded by 20260730-155003 on branch `feature/tatr-v2-adoption`, worktree
`/home/alex/.cache/sprouts/nix.dotfiles/feature/tatr-v2-adoption`.

Every command below was run bare from the worktree root, one per shell call,
with its exit status captured on the producing line. Re-derive rather than
trust: each row names the command that produced it.

## Canonical checks

```
$ tatr check                                          exit=0
$ tatr check --ledger LESSONS.md                      exit=0
$ python3 tasks/20260730-155003/tatr-rev.py           exit=0
$ bash home/modules/agents/skills/check.sh            exit=0
$ bash home/modules/scripts/sprout-test.sh            exit=0
$ nix flake check --no-build                          exit=0
```

Summary lines the runs printed:

- `check.sh`: `skills: clean (9 skills, 22 rules, 179 flow-family description
  words)`
- `sprout-test.sh`: `passed: 14  failed: 0`
- `nix flake check --no-build`: `all checks passed!`

## Resolved tatr revision

`python3 tasks/20260730-155003/tatr-rev.py` resolves the root `tatr` input
through `flake.lock`'s root input map, so it cannot read the older tatr node
`scufris` pulls in. It reported:

```
root tatr node: tatr_2
locked rev:     cd8b33d7b0827df553072a1156b9dbd78f420c01
published rev:  cd8b33d7b0827df553072a1156b9dbd78f420c01  (refs/remotes/origin/master)
prerequisite 20260730-153325: CLOSED
prerequisite 20260730-154657: CLOSED
prerequisite 20260730-154740: CLOSED
prerequisite 20260730-154745: CLOSED
prerequisite 20260730-154756: CLOSED
OK
```

The pin landed earlier, in `456e3ec`; this Story added the proof, not the bump.
(`495073f` bumped the input to `aeeac3d`, an intermediate revision, not to the
tip - re-derive with `git log -S cd8b33d7b0827df553072a1156b9dbd78f420c01 --
flake.lock`.)
Remote dependency, deliberately soft: the script fetches the tatr checkout
before reading `refs/remotes/origin/HEAD`, but no check in this repository may
require the network (AGENTS.md), so an unreachable remote only prints
`WARNING: could not fetch ...; origin refs may be stale` and the comparison
proceeds against the remote-tracking ref as it stands. A missing
`refs/remotes/origin/HEAD` is a real failure and reports one, naming
`git remote set-head origin --auto` as the fix. Both paths were exercised
against a clone whose origin URL was repointed at a nonexistent path.

The script was sabotaged three ways before being trusted, and failed each time:
a stale locked rev (`4de04d5`), an absent tatr checkout (`TATR_REPO=/nonexistent`),
and a rev predating the Stories (`21d640e` -> "prerequisite Story 20260730-154657
is OPEN at the locked revision, not CLOSED").

## Deployed skill and CLI

- `diff -q ~/.claude/skills/tatr/SKILL.md
  /home/alex/personal/tatr/skills/tatr/SKILL.md` -> `exit=0`, so the deployed
  tatr skill is byte-identical to the released one.
- `tatr --help` lists every v2 subcommand this workflow depends on: `flow`,
  `frontier`, `context`, `claim`, `scaffold`, `proofs`, `ledger`.

## Record migration

Counts from `tasks/` in this worktree; re-derive with the command shown.

- `ls tasks | wc -l` -> 55 task directories.
- `grep -L "^- KIND:" tasks/*/TASK.md | wc -l` -> 0. Same for
  `^- FLOW STEP:` and `^- PLAN STATUS:`: every record carries its v2 fields.
- `grep -l '^- TAGS:.*historical' tasks/*/TASK.md` -> 10 records, all from the
  2026-07-03/04 pre-tatr era: 20260703-104437, 20260703-104501, 20260703-110225,
  20260703-203418, 20260703-203435, 20260703-203438, 20260704-105059,
  20260704-130605, 20260704-130606, 20260704-134842. These are explicitly
  classified as historical rather than back-filled with phase facts nobody
  recorded at the time.

No record needed migrating during this Story; the migration landed with the
earlier Stories and this run confirms it.

## Lesson ledger

`tatr ledger` reports two entries at the promotion threshold, both already
carrying an explicit user disposition, so the finish gate is satisfied:

```
counts-come-from-the-diff	x5	PROMOTE 20260731-094524
dod-grep-excludes-task-records	x6	PROMOTE 20260731-094537
```

Each names the task that will carry the promotion through the normal
plan/work/review/compound lifecycle.

## Not proven here

- The Epic's `## Manual Acceptance` items. Five remain pending and are the
  user's call at the Epic's Finish; nothing in this record substitutes for
  them.
- Live agent behavior. `check.sh` is purely structural: it proves the skill
  files have the right shape, never that a session obeys them.
- The Epic itself cannot close yet. `tatr flow <epic-id> --to DONE` refuses
  while any child is not CLOSED, and 20260731-010900 is still OPEN.
