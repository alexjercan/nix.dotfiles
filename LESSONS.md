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
- `narrow-the-guard-to-the-word` (x2): an assertion listing several acceptable
  alternatives proves only that ONE held - a fixture matched on `external`
  while the `research` clause it guarded could be deleted, and a disclosure
  `when:` list of seven triggers survived deleting six. One element per case
  when the checker ORs them. 20260730-142540, 20260730-154958
- `compute-coverage-dont-claim-it` (x1): "21 rules proven able to fail" was 20
  of 26, and "runs in CI" described a script nothing ran; derive a
  completeness claim from the artifact and fail on the gap. 20260730-142533
- `measure-the-empty-structure` (x1): a formatting choice can dominate a size
  budget - a markdown table costs four words per row in pipes alone, so the
  first correct draft was 414 words against a 300-word cap and the cuts that
  followed came out of rules, not padding. Price the empty structure before
  concluding the content is what is over. 20260731-142934
- `split-files-need-isolated-phases` (x2): progressive disclosure saves
  context only when unused branches remain unread or phases use fresh contexts;
  reading every split file in one session merely defers the same cost. 20260730-142052, 20260730-142533
- `task-close-contracts-must-compose` (x1): a task-specific workflow that
  closes a task must also produce the generic records required by `tatr check`;
  spike currently omits review and retro from its close path. 20260730-142052
- `out-of-context-review-pass` (x10, PROMOTED 2026-07-20 -> review skill
  round-1 default): the fresh-context reviewer found what the implementing
  session could not see (an unfailable test; a docs-only loophole; a
  whitespace hole in a validator; a conformance gate that checked a hardcoded
  list; a record claiming more than its mechanism proves; a new rule blind on
  44% of its own corpus while passing every sabotage its author wrote; a
  routing legend that stated the opposite of what the tool it routed does; a
  DoD proof blind to half its own criterion; a rule the author had aligned
  across two files, which reads as agreement to the aligner and as duplication
  to a stranger; a de-duplication that left a pointer stub, which is a
  duplicate plus an extra hop).
  20260720-152433, 20260720-152438, 20260720-152503, 20260730-142533, 20260730-154958, 20260730-154955, 20260731-142934, 20260731-142000, 20260731-174343, 20260731-174352
- `scripted-replace-asserts-match` (x1): str.replace edits silently no-op on a
  one-char mismatch; assert the match and re-read the artifact. 20260720-152433
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
- `run-every-documented-command` (x2): run docs as written; analogy created
  nine broken commands once, then compaction turned executable `sprout show`
  guidance into a path-printing no-op. A fix is also untested until run.
  20260731-094537, 20260731-133122
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
- `claim-only-verified-state` (x2): a REVIEW.md Response claimed a scripted
  fix that had silently aborted, and a close-out recorded `nix flake check` as
  unrunnable in this sandbox when it runs and passes; re-run the exposing
  check before writing the claim, including a "could not run here" one.
  20260720-171836, 20260731-163120
- `sprout-inherits-committed-head` (x2): a new worktree contains only what is
  committed on HEAD - commit the plan before sprouting. 20260704-134842,
  20260801-155024
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
- `edit-the-worktree-not-the-cwd` (x5, PROMOTED 2026-07-20 -> work skill sprout
  step): the shell cwd resets between Bash calls - drive edits/git/`tatr` by
  absolute worktree path (`git -C`, `tatr -r`), never chain cross-repo git in
  one call (two GOAL ticks committed from the wrong repo; then three
  `tatr flow` calls run in the main checkout, which the promoted prose misses
  because it says "edit/git" and a record command is neither).
  20260720-152451, 20260720-171902, 20260720-171843, 20260720-220130,
  20260731-150849, 20260801-155024
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
- `run-the-new-rule-against-its-own-diff` (x1): a change that introduces a
  rule is that rule's first test case - the commit adding "keep comments that
  guard a value" deleted a header guarding a home-manager file collision.
  20260731-163120
- `a-rule-and-its-exception-ship-together` (x1) -> work skill: every surface
  stating a rule states its exception, or the half-stated surface is the one
  obeyed - AGENTS.md carried both the prune and guard clauses while
  `work/SKILL.md`, the surface loaded during implementation, carried only
  prune. 20260731-163120
- `untested-guarantee-comment` (x2): prose asserting what a tool does is a
  testable claim, and one written from the design or from neighbouring docs
  records a hope - `validateSopsFiles` only hashes the file, and a flow legend
  called `--to` a non-default edge when a bare `tatr flow` walks those same
  edges. Run it, or write "should". 20260730-190929, 20260731-142934
- `fix-touches-its-neighbours` (x3, PROMOTED 2026-07-31 -> review skill Docs
  dimension): prose edits repeatedly broke neighboring contracts and left
  stale references; review now re-reads the neighboring rules and sweeps
  changed concepts and cross-references after a prose or contract edit.
  20260730-154958, 20260730-155003, 20260731-133122
- `a-content-shaped-step-is-a-criterion` (x1): a plan Step that spells out a
  sentence ("Keep findings in REVIEW, change facts in TASK...") gets discharged
  by PASTING that sentence, and the check that the file already satisfied it
  never happens - the result was a restatement shipped into the very file that
  forbids restatement. Ask what the Step wants to be TRUE, then check whether
  it already is. 20260731-174415
- `a-new-heading-reparents-what-follows` (x1): inserting a section heading
  changes the scope of every paragraph below it up to the next heading, and the
  diff shows nothing - a file-wide "do not duplicate prose across records" rule
  silently became a Diagnose-only rule with its own lines untouched. Re-read
  the whole section after adding a heading. 20260731-174415
- `a-green-gate-licenses-only-what-it-inspects` (x1): citing a passing checker
  as evidence a convention holds requires reading the rule - `reference-too-deep`
  only tests nesting INSIDE one skill directory, so a cross-skill pointer chain
  cleared `check.sh` while breaking the "one level deep" convention the README
  states. The gate proved shape, not the property assumed. 20260731-174352
- `quote-a-gate-with-the-gates-own-rig` (x1): a measurement quoted against a
  gate must come from the gate's extractor, not a plausible equivalent - a
  close-out reported a skill body at 336/400 from `wc -w` on the whole file
  while `check.sh` strips frontmatter first and measures 306. 20260731-142000
- `test-harness-exit-code` (x2): the pipe-eats-the-exit-code rule applies to
  the SCAFFOLDING too, and to any command substitution between the command and
  `$?` - a helper ending in `| head` reported two working assertions as broken,
  then `echo "... $(basename $f) -> $?"` reported six sabotaged proofs as
  surviving. Capture `e=$?` on the producing line, before any string that
  interpolates. 20260730-190929, 20260731-174348
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

- `proof-must-cover-its-conjunct` (x3, PROMOTE 2026-08-01 -> 20260801-184046): one DoD item needs one independently
  sabotageable claim; broad proof scopes have passed from neighboring files or
  clauses three times. Promotion order audit: tools and templates cannot infer
  semantic conjuncts safely, so sharpen `plan/proofs.md` to require splitting
  them before writing file/section-scoped commands.
  20260720-152519, 20260731-142000, 20260801-155024

- `sweep-for-restatement-not-just-contradiction` (x3, PROMOTE 2026-07-31 -> 20260731-205300): a doc sweep that only
  asks "does anything now contradict this?" cannot see a second copy - the
  same sizing rule shipped in `plan/SKILL.md` and `flow/epic.md` in two
  vocabularies, and the author had ALIGNED them on purpose, which is why it
  read as agreement. `check.sh`'s duplicated-paragraph rule is verbatim-only,
  so the paraphrased case has no gate. Ask both questions, and fix a
  restatement by DELETING the copy - shrinking it to a pointer stub is a
  duplicate plus an extra hop, which review then rejected as a two-hop load.
  A third time the restatement landed in the file whose own subject is not
  duplicating records, two screens from the rule it copied. Promotion order
  audit: no tool can see a PARAPHRASE (duplicated-paragraph is verbatim-only)
  and no template owns prose, so the candidate is a review/sweep rule - ask
  what now RESTATES this, not only what contradicts it.
  20260731-174343, 20260731-174352, 20260731-174415

- `commit-before-every-sabotage` (x3, PROMOTE 2026-07-31 -> 20260731-202400): the A/B commit-first rule applies per
  sabotage, not per task - a restore reverted uncommitted review fixes, then a
  sabotage loop run before committing restored the FEATURE state over them and
  reported three meaningless passes, then `git checkout HEAD --` wiped a fresh
  edit a third time. The restore target is HEAD, so whatever is uncommitted is
  exactly what the restore destroys, and the loop then reports green. Promotion
  order audit: a TOOL owns this cleanly - any sabotage helper can refuse to run
  while `git status --porcelain` is non-empty, which prevents the failure
  instead of asking the operator to remember it. Skill prose has now failed to
  prevent it three times.
  20260720-152433, 20260731-142000, 20260731-174343

- `baseline-dod-proofs` (x3, PROMOTE 2026-07-31 -> 20260731-202400): run each DoD cmd: proof against the base branch
  at plan time - once it was already broken on master, once eight of nine were
  already GREEN, and a third time a proof token that read as distinctive
  (`independent`) already matched a file three directories away, so the proof
  was green before the Story existed. A token is distinctive in the
  REPOSITORY, not in the sentence the planner is imagining. Promotion order
  audit: a TOOL can own this outright - running each `cmd:` proof against the
  base branch and reporting the already-green ones is mechanical, needs no
  judgement, and belongs next to `tatr proofs`. Skill prose is the fallback if
  the tool change is out of reach.
  20260720-152433, 20260730-155003, 20260731-174348

- `line-breaks-are-load-bearing` (x4, PROMOTE 2026-07-31 -> 20260731-152845): a checker that matches raw text sees the
  line breaks too, and an edit that changes a line's length leaves the rest of
  the paragraph ragged - two content assertions were red against a file that
  DID state the rule, a pointer condition lost half its words to a wrap, a
  budget-tight rewrite orphaned an article at a line end, and a one-line
  rewrap left an 8-character orphan line mid-paragraph. Normalize whitespace
  in the matcher; reflow the paragraph you edited. Promotion order audit: a
  TOOL can own the second half - an 80-column check over the skill markdown in
  `home/modules/agents/skills/check.sh` would catch every ragged reflow with
  no reviewer, which is strictly better than more prose asking for care. A
  fourth occurrence widens it past reflow: a DoD grep never matched its target
  because the phrase it guarded wrapped mid-clause, so the line break silently
  voided a proof.
  20260730-154958, 20260731-125123, 20260731-150849, 20260731-142000

- `refactor-by-rule-not-by-section` (x4, PROMOTE 2026-07-31 -> 20260731-150130): budget refactors need a
  source-faithful imperative inventory; section cuts dropped four rules once,
  paraphrasing then reversed one and missed triggers, and compression to a word
  cap silently retired four rule words that only review caught. Promotion order
  audit: no tool can tell a rule word from a filler word, and no template owns
  prose, so the candidate is skill prose - a plan or work rule to inventory the
  imperatives before a size-driven rewrite and diff the inventory after.
  A fourth occurrence: compressing a rule to fit a word cap dropped
  "Generality" from the plan's concept budget while `review/dimensions.md`
  still fails a diff for "generality no Step names".
  20260730-142533, 20260731-133122, 20260731-142934, 20260731-174343
