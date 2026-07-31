# Review: Keep agent code comments minimal

- TASK: 20260731-163120
- BRANCH: master

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

Reviewer: out-of-context `general-purpose` subagent `a6eee852a9927314c`. Its
prompt carried only the task ID, the diff range, the dimensions, and this
record format. Diff reviewed: `git diff e2d065d~1 HEAD`, landed on `master`
per user direction to commit there rather than sprout a worktree.

Primary re-derived two load-bearing claims independently rather than
accepting them:

- `nix flake check --no-build` exits 0, `all checks passed!`. This refutes the
  close-out's claim that the nix daemon socket was unreachable.
- `services.xserver.displayManager.sessionCommands` was left an empty
  `''`/`''` block, and no package module currently duplicates
  kitty/dunst/i3status-rust, so the deleted `packages/default.nix` header
  guarded a live invariant rather than labelling the file.

Proofs rerun at HEAD: DoD rule grep exit 0; DoD absence grep exit 1 (clean);
`check.sh` clean (9 skills, 22 rules, 179 flow-family words); `tatr check
--ledger` exit 0; `sprout-test.sh` 14 passed 0 failed; `alejandra --check`
exit 0; every touched `.nix` parses.

No deletion changed evaluated semantics. The removals inside Nix string
literals (`.xinitrc`, `/etc/X11/xinit/xinitrc`) drop shell comments from
generated files only; the lua and kitty-conf removals are comments in those
grammars too.

The reviewer graded every finding MINOR or NIT and returned APPROVE. The
primary raised R1.1 through R1.3 to MAJOR on spec-conformance and honesty
grounds after re-deriving the two claims above, and issued REQUEST_CHANGES.

- [x] R1.1 (MAJOR) home/modules/agents/skills/work/SKILL.md:24 - the work
  skill carried only the prune half of the new rule and omitted the guard
  half. That is the exact reading that produced the over-prune this task's own
  close-out documents, and work/SKILL.md is the surface that governs
  implementation. The DoD requires agent-facing surfaces to state the rule;
  stating half of it reproduces the defect the task exists to fix. Add the
  guard clause to step 4.
  - Response: fixed. Step 4 now reads "Never prune a comment that guards a
    value or explains a non-obvious setting."
- [x] R1.2 (MAJOR) home/modules/packages/default.nix:1 - the deleted header
  encoded an invariant: packages a feature module already provides are not
  repeated here, or home-manager raises a file collision. Guard-class under
  the AGENTS.md clause this same diff adds, so the diff violated the rule it
  introduced. Restore one condensed line.
  - Response: fixed. Restored as a two-line guard naming kitty, dunst, and
    i3status-rust and the collision consequence.
- [x] R1.3 (MAJOR) tasks/20260731-163120/TASK.md - the `nix flake check`
  limitation is refuted; it runs and passes. A false limitation in the record
  is an honesty defect. Replace with the result.
  - Response: fixed. Both the Evidence and Limitations entries now record
    `nix flake check --no-build` passing, and the Limitations entry names
    round 1 as the source of the correction.
- [x] R1.4 (MINOR) hosts/nixos/default.nix:101 -
  `displayManager.sessionCommands` is now an empty block, dead config that
  reads as accidentally emptied. Delete the attribute.
  - Response: fixed. Attribute deleted.
- [x] R1.5 (MINOR) home/modules/neovim/plugins/_99.nix:50 - `--- CWD-sensitive
  upstream lookup.` dropped the hazard and no longer says what `md_files`
  does, so it informs nothing. Restore the hazard in one line.
  - Response: fixed. Now states the parent-walk behavior and the cwd hazard.
- [x] R1.6 (MINOR) home/modules/neovim/plugins/_99.nix:36 - dropped the
  `<dir>/<skill_name>/SKILL.md` path contract for `custom_rules`; the bare
  path is no longer verifiable without upstream docs. Restore one line.
  - Response: fixed.
- [x] R1.7 (NIT) hosts/nixos/default.nix:47,49 - `powerManagement.finegrained`
  and `open` lost their rationale (Turing+, experimental). Guard-class under
  the new rule.
  - Response: fixed. One shared note covers both, and distinguishes the NVIDIA
    open kernel module from nouveau.
- [x] R1.8 (NIT) home/modules/agents/AGENTS.md:20 - the comment policy sits
  under `## Writing`, which is otherwise about the permitted character set.
  `## Technical decisions` fits better.
  - Response: fixed. Both clauses moved; rule count unchanged at 22.
- [x] R1.9 (NIT) home/modules/neovim/plugins/_99.nix:42 - `max_file_size` lost
  its unit.
  - Response: fixed. `-- bytes` restored.

## Round 2

- REVIEWER: in-session primary
- VERDICT: APPROVE

Exception recorded: round 2 verified fixes only. Every round 1 finding was
raised by the primary or already re-derived by it, each fix is a one-to-three
line documentation or comment edit, and no fix introduced new logic. Proofs
rerun after the fixes: DoD rule grep exit 0 (matches AGENTS.md:34-37 and
work/SKILL.md:24-26); absence grep exit 1 (clean); `check.sh` clean, still
9 skills / 22 rules / 179 flow-family words; `alejandra --check` clean;
`nix flake check --no-build` `all checks passed!`. No fix regressions found.

Pending user checks:

- The `manual:` comment-audit classification remains user judgement. The user
  reviewed the working set directly, flagged the guard class via the Home
  Manager `stateVersion` warning, and the restores plus the second AGENTS.md
  clause answer that feedback.
