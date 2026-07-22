# Lessons ledger

One or two lines per lesson: slug, one sentence, an occurrence count, and a
task id or two. /compound and /lessons append new lessons or bump counts; two
lines is the cap. At three occurrences a lesson moves to Pending promotions.

## Process lessons

- `out-of-context-review-pass` (x3, PROMOTED 2026-07-20 -> review skill
  round-1 default): the fresh-context reviewer found what the implementing
  session could not see (an unfailable test; a docs-only loophole; a
  whitespace hole in a validator). 20260720-152433, 20260720-152438, 20260720-152503
- `commit-before-every-sabotage` (x1): the A/B commit-first rule applies per
  sabotage, not per task - a restore reverted uncommitted review fixes. 20260720-152433
- `scripted-replace-asserts-match` (x1): str.replace edits silently no-op on a
  one-char mismatch; assert the match and re-read the artifact. 20260720-152433
- `baseline-dod-proofs` (x1): run each DoD cmd: proof against the base branch
  at plan time - nix flake check was already broken on master. 20260720-152433
- `heredoc-splits-the-chain` (x1): commands after a heredoc block are not part
  of its && chain - commit in a separate call gated on success. 20260720-152438
- `tick-against-the-literal-step` (x2): re-read a step's exact text before
  ticking it; intent-from-memory has ticked undelivered clauses twice. 20260720-152438, 20260720-152508
- `optional-step-as-decision` (x1) -> plan skill: phrase a conditional step as a
  checkable DECISION ("decide X: do / defer with reason"), not "Optional: do X" -
  a deferred "Optional: do X" leaves a CLOSED task with an unchecked Step
  (`closed-unchecked`) and no honest tick. 20260722-113105
- `read-the-callee-not-the-name` (x1): find_current_tasks_dir returns project
  dirs, not tasks dirs - a misleading name cost a silent no-op walk. 20260720-152503
- `validate-the-exact-parsed-token` (x1): a trimmed re-validation of an
  untrimmed parse is a hole; check the bytes the parser consumes. 20260720-152503
- `flake-path-literal-string-coercion` (x1): coercing a `../subdir` path
  literal to a string in a flake (interpolation or `builtins.readDir`) copies
  it to the store as a floating non-GC-root `<hash>-subdir` that GC orphans
  against the eval cache ("path is not valid"); use `${inputs.self}/subdir`. 20260720-153613

- `rule-and-example-must-agree` (x2): re-read a rule and its examples together
  before committing - a format example has twice modeled the mistake its rule
  forbids. 20260720-152457, 20260720-152514
- `document-where-the-reader-reads` (x1): a convention that makes a mechanism
  reliable belongs in the doc its user loads, not the close-out that shipped
  it. 20260720-152508
- `doc-a-cli-from-its-real-output` (x1): when a doc surface (skill/README)
  documents a CLI, regenerate its examples by RUNNING the new binary, not by
  editing the predecessor's doc - a replaced tool changes flag names, output
  keys and scoping a memory-edit silently keeps wrong. 20260720-210202
- `land-from-the-main-checkout` (x2): sprout land is its own call from the
  main checkout, never the tail of a worktree chain - the guard refuses, but
  each refusal is a wasted retry. 20260720-152438, 20260720-152508
- `commit-the-review-before-landing` (x1): the out-of-context reviewer's
  REVIEW.md must be committed on the feature branch before `sprout land` -
  squash-land only takes tracked files and then removes the worktree, so an
  uncommitted REVIEW.md is lost with it (had to be reconstructed once). The
  review skill's "in-session pass writes and commits the round" covers this
  when followed. 20260720-220044
- `proof-must-cover-its-conjunct` (x1): a DoD proof for a two-part criterion
  must fail if either part is deleted; a case-sensitive grep survived its
  target's removal. 20260720-152519
- `counts-come-from-the-diff` (x2): work reports and close records have
  miscounted their own changes; cite the diff's numbers, not the
  narrative's. 20260720-171843, 20260720-171836
- `claim-only-verified-state` (x1): a REVIEW.md Response claimed a scripted
  fix that had silently aborted; re-run the exposing check before writing
  the claim. 20260720-171836
- `sprout-inherits-committed-head` (x1): a new worktree contains only what is
  committed on HEAD - commit the plan before sprouting. 20260704-134842
- `read-secret-keys-not-assume` (x1): derive a secret's variable NAMES from the
  actual secret file's keys (names only), not from a nearby code comment/config -
  a dummy PoC used `SCUFRIS_OPENAI_API_KEY` from a comment when the real env held
  only `TELEGRAM_BOT_TOKEN`. 20260722-221356
- `inputs-self-needs-tracked-file` (x1): a `${inputs.self}/<path>` reference
  resolves against the git tree, so a newly-created file is invisible to
  `nix flake check`/build until `git add`ed - stage new referenced files before
  the first eval. 20260722-214112
- `build-just-the-package` (x2): verify a script module by nix-building only
  its package via the flake's nixpkgs, not a full home-manager rebuild.
  20260703-104437, 20260720-152433
- `dod-grep-excludes-task-records` (x5, PROMOTED 2026-07-20 -> plan skill DoD
  guidance): a blanket no-stale-references grep self-matches the task's own
  record; absence-proving DoD greps now exclude tasks/ from the start.
  20260720-171855, 20260720-171910, 20260720-171902, 20260720-171843, 20260720-171836, 20260720-220044
- `edit-the-worktree-not-the-cwd` (x3, PROMOTED 2026-07-20 -> work skill sprout
  step): the shell cwd resets between Bash calls - drive edits/git by absolute
  worktree path or `git -C`, never chain cross-repo git in one call (two GOAL
  ticks committed from the wrong repo). 20260720-152451, 20260720-171902, 20260720-171843, 20260720-220130
- `dry-run-in-a-scratch-repo` (x3, PROMOTED 2026-07-20 -> plan skill verify-first
  guidance): verify load-bearing git/nix semantics in a throwaway scratch repo
  before writing a step on them. 20260703-104437, 20260704-105059, 20260704-134842, 20260720-220130, 20260722-220536
- `hm-external-pkgs-ignores-nixpkgs-config` (x1): when a home config is built
  with an EXTERNALLY-imported `pkgs` (the flake-parts pattern here:
  `homeManagerConfiguration { pkgs = import nixpkgs {...}; }`), the in-module
  `nixpkgs.config.allowUnfree`/overlays are IGNORED - set them on that external
  `import nixpkgs {...}` (flake/home-configurations.nix). Symptom: an unfree pkg
  (codex, claude-code) errors despite `nixpkgs.config.allowUnfree = true` in the
  user module. 20260721-140158.
- `path-input-copies-untracked-tree` (x1): a `path:/abs/dir` flake input copies
  the ENTIRE directory (no gitignore filter) - node_modules/.venv/.git all land
  in the store (231M for scufris) and re-copy on every content change. Use
  `git+file://<dir>?ref=<branch>` for a git-filtered reproducible input when copy
  cost matters; `path:` only when reading the live working tree is the point.
  20260721-140158.

## Pending promotions (3+ occurrences, user decides)

None open - the three x3+ lessons were resolved and promoted into the plan and
work skills on 2026-07-20 (task 20260720-220130).
