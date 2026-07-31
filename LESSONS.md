# Lessons ledger

One or two lines per lesson: slug, one sentence, an occurrence count, and a
task id or two. /compound and /lessons append new lessons or bump counts; two
lines is the cap. At three occurrences a lesson moves to Pending promotions.

## Process lessons

- `test-the-quiet-direction` (x1): a checker suite that only ever proves rules
  CAN fire says nothing about what they flag wrongly - `direct-state-edit`
  passed five sabotage cases while being blind to 17 of 39 real sentences and
  flagging ordinary descriptive prose. Pair every rule with a case asserting
  the gate stays CLEAN on correct input. 20260730-154955
- `measure-must-survive-recording` (x1): a number written into the file it
  measures is invalidated by writing it - a close-out diff stat moved three
  times, twice because the block quoting it grew and once because the review
  round verifying it was committed. Pick a scope the act of recording cannot
  change (here: exclude `tasks/`), and name the command so a reader
  re-derives instead of trusting. 20260730-154955
- `exempt-on-structure-not-on-a-token` (x1): an exemption keyed on a bare word
  anywhere in the scope inverts itself - exempting any clause containing
  `tatr` or `never` excused "if `tatr flow` is unavailable, set FLOW STEP by
  hand", the likeliest real violation. Key it on the token's ROLE (subject,
  instrument, attached negation), not its presence. 20260730-154955
- `degenerate-case-before-real-cases` (x1): a new checker or assertion FORMAT
  gets designed from the cases its author is about to write, so the degenerate
  ones stay invisible - a content fixture with no assertions printed `ok`, and
  a section matcher accepted a heading inside a fenced example. Write the
  emptiest and the decoration-satisfied case first; this is separate from
  proving each rule can fire. 20260730-142540
- `line-breaks-are-load-bearing` (x2): a checker that matches raw text sees the
  line breaks too - two content assertions were red against a file that DID
  state the rule, because the phrase wrapped, and a pointer condition lost half
  its words to the same wrap, and a budget-tight rewrite left an article
  orphaned at a line end. Normalize whitespace in the matcher; reflow the
  paragraph you edited. 20260730-154958, 20260731-125123
- `fix-touches-its-neighbours` (x2): a prose fix that satisfies its finding can
  contradict a section the finding never named, and the sweep for the others
  inherits the phrasing in front of you - `item already carries` could not match
  the third copy saying `list already carries`. Re-read every rule sharing the
  actor or ordering, and sweep the CONCEPT with alternatives. 20260730-154958, 20260730-155003
- `narrow-the-guard-to-the-word` (x2): an assertion listing several acceptable
  alternatives proves only that ONE held - a fixture matched on `external`
  while the `research` clause it guarded could be deleted, and a disclosure
  `when:` list of seven triggers survived deleting six. One element per case
  when the checker ORs them. 20260730-142540, 20260730-154958
- `compute-coverage-dont-claim-it` (x1): "21 rules proven able to fail" was 20
  of 26, and "runs in CI" described a script nothing ran; derive a
  completeness claim from the artifact and fail on the gap. 20260730-142533
- `refactor-by-rule-not-by-section` (x1): cutting prose by heading or word
  budget drops rules that merely shared a block with filler - four incident
  rules went that way; extract every imperative first, then check each is
  present, moved, or deliberately retired. 20260730-142533
- `split-files-need-isolated-phases` (x2): progressive disclosure saves
  context only when unused branches remain unread or phases use fresh contexts;
  reading every split file in one session merely defers the same cost. 20260730-142052, 20260730-142533
- `task-close-contracts-must-compose` (x1): a task-specific workflow that
  closes a task must also produce the generic records required by `tatr check`;
  spike currently omits review and retro from its close path. 20260730-142052
- `out-of-context-review-pass` (x6, PROMOTED 2026-07-20 -> review skill
  round-1 default): the fresh-context reviewer found what the implementing
  session could not see (an unfailable test; a docs-only loophole; a
  whitespace hole in a validator; a conformance gate that checked a hardcoded
  list; a record claiming more than its mechanism proves; a new rule blind on
  44% of its own corpus while passing every sabotage its author wrote). 20260720-152433, 20260720-152438, 20260720-152503, 20260730-142533, 20260730-154958, 20260730-154955
- `commit-before-every-sabotage` (x1): the A/B commit-first rule applies per
  sabotage, not per task - a restore reverted uncommitted review fixes. 20260720-152433
- `scripted-replace-asserts-match` (x1): str.replace edits silently no-op on a
  one-char mismatch; assert the match and re-read the artifact. 20260720-152433
- `baseline-dod-proofs` (x2): run each DoD cmd: proof against the base branch
  at plan time - once it was already broken on master, once eight of nine were
  already GREEN, which turned a planned re-do into a confirm-and-reconcile and
  stopped the diff claiming another commit's work. 20260720-152433, 20260730-155003
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
- `flake-path-literal-string-coercion` (x2): coercing a `../subdir` path
  literal to a string in a flake (interpolation or `builtins.readDir`) copies
  it to the store as a floating non-GC-root `<hash>-subdir` that GC orphans
  against the eval cache ("path is not valid"); use `${inputs.self}/subdir`.
  Latent until the directory's CONTENT changes, so the fix outlives the file
  it was found in. 20260720-153613, 20260730-142540
- `sops-dotenv-decrypts-whole-file` (x2): a sops-nix secret with
  `format = "dotenv"` decrypts the ENTIRE file as that secret's value and
  IGNORES `key` (`sops-install-secrets/main.go`, same for ini/binary), so it
  can never yield a raw single-value file. Wrapping it in a template that
  re-prepends `KEY=${placeholder}` doubles the line and the Telegram API 404s.
  A secret two consumers need at different granularities must be yaml/json:
  per-key secrets for the raw file, a template for the env file. 20260722-113105, 20260730-190929

- `rule-and-example-must-agree` (x2): re-read a rule and its examples together
  before committing - a format example has twice modeled the mistake its rule
  forbids. 20260720-152457, 20260720-152514
- `run-every-documented-command` (x1): in a doc whose content IS commands, a
  command reads as illustration and escapes the habit that would falsify it -
  nine of thirteen findings were commands written by analogy and never run
  (`^[^/]*` as the `//` twin of a tested `#` pattern; "re-run without `-E`",
  which cannot filter differently since the ERE is a valid BRE). A FIX is a new
  command and inherits the same untested status. 20260731-094537
- `dry-run-cases-come-from-the-reader` (x1): a dry-run scoped to the example
  that produced the rule only confirms the author - `#` comments in nix passed
  while markdown headings, shell scripts, URLs and string literals each broke
  the documented command. Enumerate the file types the READER will aim it at.
  20260731-094537
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
- `claim-only-verified-state` (x1): a REVIEW.md Response claimed a scripted
  fix that had silently aborted; re-run the exposing check before writing
  the claim. 20260720-171836
- `sprout-inherits-committed-head` (x1): a new worktree contains only what is
  committed on HEAD - commit the plan before sprouting. 20260704-134842
- `read-secret-keys-not-assume` (x1): derive a secret's variable NAMES from the
  actual secret file's keys (names only), not from a nearby code comment/config -
  a dummy PoC used `SCUFRIS_OPENAI_API_KEY` from a comment when the real env held
  only `SCUFRIS_TELEGRAM_BOT_TOKEN`. 20260722-221356
- `inputs-self-needs-tracked-file` (x1): a `${inputs.self}/<path>` reference
  resolves against the git tree, so a newly-created file is invisible to
  `nix flake check`/build until `git add`ed - stage new referenced files before
  the first eval. 20260722-214112
- `build-just-the-package` (x2): verify a script module by nix-building only
  its package via the flake's nixpkgs, not a full home-manager rebuild.
  20260703-104437, 20260720-152433
- `dod-grep-excludes-task-records` (x6, PROMOTED 2026-07-31 -> plan skill DoD
  guidance): a blanket no-stale-references grep self-matches the task's own
  record, and equally the prose the same diff writes about the thing removed;
  the guidance now excludes `tasks/` by directory AND comments by pattern.
  20260720-171855, 20260720-171910, 20260720-171902, 20260720-171843, 20260720-171836, 20260720-220044, 20260730-190929
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
- `one-request-one-task` (x1) -> flow skill: default /flow planning updates the
  active task instead of creating an umbrella/child pair, unless the user asks
  for an epic, sprint, version, release, or multi-feature container.
  20260725-110435
- `untested-guarantee-comment` (x1): a comment claiming a tool VALIDATES or
  REJECTS something is a testable claim, and one written while designing the
  mechanism records a hope - sops-nix's `validateSopsFiles` only hashes the
  file, it never checks keys. Test it in the same edit or write "should". 20260730-190929
- `test-harness-exit-code` (x1): the pipe-eats-the-exit-code rule applies to
  the SCAFFOLDING too - a helper ending in `| head` always returns 0, which
  reported two working assertions as broken. Capture `e=$?` on the producing
  line. 20260730-190929
- `checkout-head-not-index` (x1): `git checkout -- <file>` restores from the
  INDEX, so a helper that runs `git add` first makes the restore a silent
  no-op and leaks the sabotage into the next test. Use `git checkout HEAD --`. 20260730-190929
- `never-assert-anothers-confirmation` (x1) -> review skill: a record that
  exists to hold another party's judgement must never be written on their
  behalf - a review checkbox was ticked and REVIEW.md made to say the
  out-of-context reviewer had confirmed the fix BEFORE it was asked; asked, it
  refused, and the fix was in fact incomplete. Same defect class as
  self-ticking a `manual:` proof. Ask; the round trip is cheap. 20260730-155003
- `assert-the-seam-you-just-created` (x1): when a design's accepted cost is a
  value duplicated across two evaluations/configs, write the agreement as a
  build-failing check, not a "keep in sync" comment - here it then caught
  three further defects that review would have had to find by reading. 20260730-190929
- `workaround-invalidates-the-tool-doc` (x1): a step that hand-edits state a
  tool is documented to own makes that documentation stale, and the diff's doc
  sweep will not catch it - the sweep is scoped to the files being edited, and
  the workaround by definition touches one that is not. `lessons/ledger.md`
  claimed `tatr ledger` performs the PROMOTE -> PROMOTED transition; folding an
  entry by hand proved it has no such flag. 20260731-125123
- `write-the-sabotage-first` (x3, PROMOTED 2026-07-31 -> plan skill
  proofs reference): a proof nothing has broken is unfalsifiable, and SIZE is
  no exemption - a one-line `grep -c` stayed green with five of six rows
  deleted, and two more blind proofs shipped (one matching two lines at once,
  one already green on master). Sabotage at PLAN time; both would have died
  before a branch existed. 20260730-142533, 20260730-155003, 20260731-094537

## Pending promotions (3+ occurrences, user decides)
