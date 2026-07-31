# Review - Keep agent code comments minimal

## Round 1

Reviewer: out-of-context `general-purpose` subagent `a6eee852a9927314c`.
Diff: `git diff e2d065d~1 HEAD` (two commits, landed on `master`; no feature
branch, per user direction to commit on master).

Primary re-derived two load-bearing claims independently:

- `nix flake check --no-build` exits 0, `all checks passed!` -- refutes the
  close-out limitation.
- `hosts/nixos/default.nix:101` `displayManager.sessionCommands` is an empty
  `''`/`''` block after the deletion; no package module currently duplicates
  kitty/dunst/i3status-rust, so the deleted `packages/default.nix` header was
  a live invariant, not a label.

Proofs rerun at HEAD: DoD rule grep exit 0; DoD absence grep exit 1 (clean);
`check.sh` clean (9 skills, 22 rules, 179 words); `tatr check --ledger`
exit 0; `sprout-test.sh` 14 passed 0 failed; `alejandra --check` exit 0; all
touched `.nix` parse.

No deletion changed evaluated semantics. Removals inside Nix string literals
(`.xinitrc`, `/etc/X11/xinit/xinitrc`) drop shell comments from generated
files only; the lua and kitty-conf removals are comments in those grammars
too.

### Findings

- MAJOR `home/modules/agents/skills/work/SKILL.md:24` -- the work skill
  carries only the prune half of the new rule and omits the guard half. That
  is the exact reading that produced the over-prune this task's own close-out
  documents, and work/SKILL.md is the surface that governs implementation.
  The DoD requires agent-facing surfaces to state the rule; stating half of
  it reproduces the defect the task exists to fix. Add the guard clause to
  step 4.
- MAJOR `home/modules/packages/default.nix:1` -- deleted header encoded an
  invariant: packages a feature module already provides are not repeated
  here, or home-manager raises a file collision. Guard-class under this
  change's own new AGENTS.md clause, so the diff violates the rule it adds.
  Restore one condensed line.
- MAJOR `tasks/20260731-163120/TASK.md` Limitations -- the `nix flake check`
  claim is refuted; it runs and passes (`--no-build`, exit 0). A false
  limitation in the record is an honesty defect. Replace with the result.
- MINOR `hosts/nixos/default.nix:101` -- `displayManager.sessionCommands` is
  now an empty block, dead config that reads as accidentally emptied. Delete
  the attribute.
- MINOR `home/modules/neovim/plugins/_99.nix:50` -- `--- CWD-sensitive
  upstream lookup.` dropped the hazard ("breaks if you change cwd") and no
  longer says what `md_files` does. Restore the hazard in one line.
- MINOR `home/modules/neovim/plugins/_99.nix:36` -- dropped the
  `<dir>/<skill_name>/SKILL.md` path contract for `custom_rules`; the bare
  path is no longer verifiable without upstream docs. Restore one line.
- NIT `hosts/nixos/default.nix:47,49` -- `powerManagement.finegrained` and
  `open` lost their rationale (Turing+, alpha-quality). Guard-class under the
  new rule.
- NIT `home/modules/agents/AGENTS.md:20` -- comment policy filed under
  `## Writing`, which is otherwise about the character set.
  `## Technical decisions` fits better. No contradiction either way.
- NIT `home/modules/neovim/plugins/_99.nix:42` -- `max_file_size` lost its
  unit ("bytes").

### Verdict

REQUEST_CHANGES. Three open MAJORs: the work skill states half the rule, the
diff strips a guard the rule it adds says to keep, and the record carries a
refuted limitation. The reviewer graded all findings MINOR/NIT and returned
APPROVE; the primary raised those three on spec-conformance and honesty
grounds after re-deriving both the flake-check and the package-collision
claims.

Pending user checks:

- `manual:` comment-audit classification remains user judgement. The user
  reviewed the working set directly and flagged the guard class; the restore
  and the second AGENTS.md clause answer that feedback.
