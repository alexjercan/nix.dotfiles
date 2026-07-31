# Keep agent code comments minimal

- STATUS: CLOSED
- PRIORITY: 70
- TAGS: skills, flow, docs, refactor
- KIND: TASK
- FLOW STEP: DONE
- PLAN STATUS: APPROVED

## Why

Current flow behavior encourages agents to add explanatory prose inside code.
User wants comments kept minimal: docstrings or essential implementation notes
only. Explanations about what/why/tradeoffs belong in TASK.md, NOTE.md,
DECISION.md, REVIEW.md, or RETRO.md records.

## Definition of Done

- Agent-facing surfaces state that code comments stay limited to docstrings or
  essential implementation notes. (cmd: `rg -n "comment|comments|prose|docstring|essential|minimal" home/modules/agents/AGENTS.md home/modules/agents/skills/work/SKILL.md home/modules/agents/skills/plan/SKILL.md home/modules/agents/skills/README.md`)
- Redundant comment labels and scaffold prose found in the initial audit are
  gone from non-task source files. (cmd: `rg -n "^\\s*#\\s+(Move Focus|Split|Bootloader\\.|Enable networking|Enable CUPS|Storage optimization|Allow unfree packages|List packages installed|Optional, hint Electron|Create wrapper scripts|Create default xinitrc|Default xinitrc|Start i3 by default|Terminal / command-line utilities\\.|GUI applications:|Games and game launchers\\.|Development tooling|Desktop / X11 utilities:|Audio / video / graphics|change the following as needed|optional entries:)" --glob '!tasks/**' --glob '!secrets/**'`)
- The skill suite remains conformant. (cmd: `bash home/modules/agents/skills/check.sh`)
- The task and ledger gate remains clean. (cmd: `tatr check --ledger LESSONS.md`)
- A comment audit over non-task source files classifies removed comments as
  redundant labels, scaffold comments, or prose better suited to task records;
  retained comments explain non-obvious behavior or constraints. (manual: user judgement)

## Steps

- [x] Update agent-facing prose in `home/modules/agents/AGENTS.md` and the
  relevant flow-family skill surface so agents stop adding explanatory code
  comments except docstrings or essential notes.
- [x] Audit non-task source comments with `rg`, then remove redundant labels,
  generated scaffold comments, and stale/freeform prose that does not explain
  a non-obvious constraint.
- [x] Keep essential comments where they encode a verified workaround,
  cross-evaluation constraint, generated-file warning, or command contract.
- [x] Re-read edited files and run every DoD proof.
- [x] Record close-out notes in the task record, not in code comments.

## Notes

- Initial scan found likely cleanup targets in package-set headers,
  `hosts/nixos/default.nix` scaffold comments, kitty/tmux label comments, and
  neovim plugin example prose.
- Existing long comments in scufris, sops, flake path, skills deployment, and
  sprout logic mostly encode non-obvious constraints and should be retained
  unless a nearby record can replace them without losing local safety.

## Close-out

Changed:

- Added the global agent rule in `home/modules/agents/AGENTS.md`: code
  comments are for docstrings or essential implementation notes; explanatory
  prose belongs in task records.
- Added the same working rule to `home/modules/agents/skills/work/SKILL.md`,
  where implementation behavior is governed.
- Removed redundant labels, copied examples, and stock scaffold comments from
  kitty, tmux, neovim plugin config, package modules, `home/alex/default.nix`,
  and `hosts/nixos/default.nix`.
- Retained comments that explain flake path literal hazards, sops/scufris
  secret wiring, generated hardware config, deployment checks, firewall
  intent, and other non-obvious constraints.

Evidence:

- `rg -n "comment|comments|prose|docstring|essential|minimal" ...` found the
  new agent-facing rule.
- Targeted useless-prose absence grep returned no matches.
- `bash home/modules/agents/skills/check.sh` passed:
  `skills: clean (9 skills, 22 rules, 179 flow-family description words)`.
- `tatr check 20260731-163120` passed.
- `tatr check --ledger LESSONS.md` passed.
- `bash home/modules/scripts/sprout-test.sh` passed: 14 passed, 0 failed.
- `nix flake check --no-build` passed: `all checks passed!`.

Follow-up (user review of the working set):

- The first pass over-pruned guard comments. User flagged the Home Manager
  `stateVersion` warning as the class they want kept: "attention, do not
  change this".
- Restored, condensed: `home.stateVersion` and `system.stateVersion` do-not-
  change warnings, tmux `escapeTime`/`secureSocket` rationale, and the `_99`
  `tmp_dir` must-stay-inside-CWD constraint.
- Added a second AGENTS.md clause so the rule cannot be read as license to
  strip guards: keep comments that guard a value or explain a non-obvious
  setting.
- Re-ran proofs after the restore: check.sh clean, `tatr check --ledger`
  clean, absence grep still empty.

Round 1 review fixes:

- `work/SKILL.md` step 4 now carries the guard half of the rule, not just the
  prune half.
- Restored the `packages/default.nix` collision invariant, the `_99`
  `custom_rules` path contract and `md_files` cwd hazard, the `max_file_size`
  unit, and the nvidia `finegrained`/`open` rationale.
- Deleted `services.xserver.displayManager.sessionCommands`, which the first
  pass had emptied to a bare `''`/`''` block.
- Moved the comment rules from `## Writing` to `## Technical decisions` in
  AGENTS.md; `## Writing` is about the character set.
- Corrected the refuted `nix flake check` limitation above.

Limitations:

- The planned sprout worktree was never created: the first pass hit a
  read-only `.git/index.lock`, and the user then chose to commit on `master`
  directly. Landed as `e2d065d`.
- `nix flake check --no-build` runs and passes at HEAD (`all checks
  passed!`). The earlier close-out claimed the daemon socket was unreachable;
  review round 1 refuted that.
- Manual DoD remains user judgement: audit classification matches the removed
  comment set and retained constraint comments.
