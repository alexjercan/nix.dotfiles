# Add sprout land: guarded squash-merge landing as one command

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: feature, tooling

## Story

As the flow orchestrator, I want `sprout land <feature>` to perform the whole
guarded landing (checks, squash-merge, commit, worktree/branch cleanup) as one
command, so the 40-line prose protocol in the flow skill (and its
staged-squash race) becomes impossible to get wrong. From the 2026-07-20 flow
review: promotion order is tool > skill text; the landing dance is the most
dangerous prose in the suite.

## Steps

- [x] Extract the script body from home/modules/scripts/sprout.nix into
      home/modules/scripts/sprout.sh; sprout.nix becomes
      `text = builtins.readFile ./sprout.sh;` (drops the nix `''` escaping
      and makes the script directly testable).
- [x] Add cmd_land to sprout.sh: `sprout land <feature> -m <subject> [-m <body>]`:
      - target = branch checked out in the MAIN worktree; refuse detached
        HEAD or target == feature;
      - refuse if the main worktree is dirty (staged or unstaged) - parallel
        session safety;
      - refuse unless `git merge-base --is-ancestor <target> <feature>`
        (sync + conflict resolution stay on the branch, per /work);
      - `git -C <main> merge --squash <feature>` then commit with the given
        -m parts; if the commit fails, `git -C <main> reset --merge` so no
        staged state is ever left behind;
      - on success, run cmd_rm's cleanup (worktree, branch, tmux session)
        and print the landed short hash + subject.
- [x] Add home/modules/scripts/sprout-test.sh: integration suite (modeled on
      tatr's checker.sh) driving sprout.sh against throwaway git repos under
      mktemp: new/show/rm happy paths, land happy path, dirty-main refusal,
      not-an-ancestor refusal, detached refusal, missing-feature refusal,
      commit-failure rollback leaves a clean index.
- [x] Update the flow skill's landing step to call `sprout land` and delete
      the atomic-command prose it replaces (shrink-on-absorb); keep the
      sync, re-verify and inspect-the-diff steps.
- [x] Update the sprout skill (SKILL.md + reference.md) and docs/sprout.md in
      the same task (docs-sync rule).

## Definition of Done

- sprout-test.sh passes (cmd: bash home/modules/scripts/sprout-test.sh)
- shellcheck is clean on the extracted script (cmd: shellcheck home/modules/scripts/sprout.sh)
- the sprout package builds, including writeShellApplication's build-time
  shellcheck (cmd: nix build --no-link --impure --expr on sprout.nix; amended
  from `nix flake check --no-build`, which fails on untouched master with a
  pre-existing store error - filed as task 20260720-153613)
- flow SKILL.md landing step uses sprout land and no longer contains the
  pwd/branch/squash/commit one-liner (cmd: grep -n "merge --squash" home/modules/agents/skills/flow/SKILL.md)
- new/ls/show/rm behavior unchanged (test: sprout-test.sh new/show/rm cases)
- manual: user sees a later task of this very flow landed via sprout land

## Notes

- writeShellApplication runs shellcheck at build time; the extracted file
  must keep the relaxed `set +o` prologue.
- `''${` escapes in the nix string become plain `${` after extraction.
- Files: home/modules/scripts/sprout.nix, home/modules/agents/skills/flow/SKILL.md,
  home/modules/agents/skills/sprout/SKILL.md,
  home/modules/agents/skills/sprout/reference.md, docs/sprout.md.

## Close-out (2026-07-20)

What changed and why:

- sprout.sh extracted from the nix indented string (sprout.nix is now a thin
  readFile wrapper). Alternative considered: keep the script inline and test
  via `nix eval` extraction - rejected; a plain file is testable, diffable
  and drops the `''${` escaping class entirely.
- cmd_land implements the guarded landing: refusals (missing worktree/branch,
  inside-the-worktree, detached HEAD, feature==target, dirty tracked files,
  not-up-to-date) all precede any mutation; squash+commit roll back to a
  clean tree on failure; cleanup reuses cmd_rm. Untracked files in the main
  checkout deliberately do NOT block (they cannot enter the commit; a real
  collision aborts the squash, which rolls back) - full-porcelain strictness
  would make land unusable in practice and push users back to the manual
  sequence.
- The inside-the-worktree refusal was added during implementation (not in
  the plan): git refuses to remove the current worktree, which would have
  half-landed (commit done, cleanup failed). Caught by dry-running the
  sequence mentally against git semantics before writing tests.
- sprout-test.sh: 11 integration tests, hermetic git (fixed identity,
  GIT_CONFIG_GLOBAL=/dev/null so a user gpgsign/defaultBranch cannot leak).
- Skill/doc surfaces updated in the same task: flow landing step 3.5.4+5
  collapsed to one sprout land step (~20 lines of race-warning prose
  deleted); sprout SKILL.md + reference.md; docs/sprout.md gained a Landing
  section and its design notes no longer claim the inline-nix style.

Difficulties:

- shellcheck SC2319 rejected the `[[ cond ]]; check $?` assertion idiom
  across the test file; rewrote check() to take the assertion as a command
  (with not/quiet/str_prefix/str_contains helpers), which reads better.
- `nix flake check --no-build` turned out broken on master itself (store
  path 'f5m9...-hosts is not valid'), unrelated to this diff; verified by
  running it on the untouched master checkout. Fell back to building the
  sprout package directly (which still runs shellcheck) and filed
  20260720-153613.

Evidence:

- 11/11 integration tests green; sabotage check: deleting the dirty-main
  guard turns test_land_refuses_dirty_main red (3 asserts), restore turns
  it green again.
- Standalone shellcheck clean on sprout.sh and sprout-test.sh; package
  build BUILD-OK; built binary's help shows land.

Self-reflection: the DoD named `nix flake check` as a proof without first
confirming that check passes on master - a proof should be validated against
the baseline when the plan is written, or the first verify run wastes time on
an inherited failure. Wrote it into the retro.
