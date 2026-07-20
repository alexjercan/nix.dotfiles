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
- `read-the-callee-not-the-name` (x1): find_current_tasks_dir returns project
  dirs, not tasks dirs - a misleading name cost a silent no-op walk. 20260720-152503
- `validate-the-exact-parsed-token` (x1): a trimmed re-validation of an
  untrimmed parse is a hole; check the bytes the parser consumes. 20260720-152503
- `flake-path-literal-string-coercion` (x1): coercing a `../subdir` path
  literal to a string in a flake (interpolation or `builtins.readDir`) copies
  it to the store as a floating non-GC-root `<hash>-subdir` that GC orphans
  against the eval cache ("path is not valid"); use `${inputs.self}/subdir`. 20260720-153613
- `edit-the-worktree-not-the-cwd` (x1): the shell cwd resets to the main
  checkout between Bash calls, so Edit/Read on a sprout branch must use the
  absolute worktree path, not the main-checkout one. 20260720-152451
- `rule-and-example-must-agree` (x1): re-read a rule and its examples together
  before committing - a spec said items end with `(manual: ...)` while every
  example led with a bare `manual:`. 20260720-152457
- `document-where-the-reader-reads` (x1): a convention that makes a mechanism
  reliable belongs in the doc its user loads, not the close-out that shipped
  it. 20260720-152508
- `land-from-the-main-checkout` (x2): sprout land is its own call from the
  main checkout, never the tail of a worktree chain - the guard refuses, but
  each refusal is a wasted retry. 20260720-152438, 20260720-152508

## Pending promotions (3+ occurrences, user decides)

(none yet)
