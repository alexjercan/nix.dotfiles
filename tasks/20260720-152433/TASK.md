# Add sprout land: guarded squash-merge landing as one command

- STATUS: OPEN
- PRIORITY: 100
- TAGS: feature,tooling

## Story

As the flow orchestrator, I want `sprout land <feature>` to perform the whole
guarded landing (checks, squash-merge, commit, worktree/branch cleanup) as one
command, so the 40-line prose protocol in the flow skill (and its
staged-squash race) becomes impossible to get wrong. From the 2026-07-20 flow
review: promotion order is tool > skill text; the landing dance is the most
dangerous prose in the suite.

## Steps

- [ ] Extract the script body from home/modules/scripts/sprout.nix into
      home/modules/scripts/sprout.sh; sprout.nix becomes
      `text = builtins.readFile ./sprout.sh;` (drops the nix `''` escaping
      and makes the script directly testable).
- [ ] Add cmd_land to sprout.sh: `sprout land <feature> -m <subject> [-m <body>]`:
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
- [ ] Add home/modules/scripts/sprout-test.sh: integration suite (modeled on
      tatr's checker.sh) driving sprout.sh against throwaway git repos under
      mktemp: new/show/rm happy paths, land happy path, dirty-main refusal,
      not-an-ancestor refusal, detached refusal, missing-feature refusal,
      commit-failure rollback leaves a clean index.
- [ ] Update the flow skill's landing step to call `sprout land` and delete
      the atomic-command prose it replaces (shrink-on-absorb); keep the
      sync, re-verify and inspect-the-diff steps.
- [ ] Update the sprout skill (SKILL.md + reference.md) and docs/sprout.md in
      the same task (docs-sync rule).

## Definition of Done

- sprout-test.sh passes (cmd: bash home/modules/scripts/sprout-test.sh)
- shellcheck is clean on the extracted script (cmd: shellcheck home/modules/scripts/sprout.sh)
- nix evaluation still green (cmd: nix flake check --no-build)
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
