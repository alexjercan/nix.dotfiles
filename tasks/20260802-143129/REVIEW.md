# Review: Address the afk runner's round-1 review findings

- TASK: 20260802-143129
- BRANCH: fix/afk-round1-followups

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/agents/skills/work/SKILL.md:15 - the sweep
  names `-r <task-root>` here but nothing in this skill says what
  `<task-root>` is, and its referent CHANGES between step 1 and step 2: at
  step 1 no worktree exists, so it is the main checkout; at step 2 the
  preceding `sprout new` makes the new worktree the owner. The only text that
  defines the term is `flow/resume.md:24-28`, which a standalone `/work`
  session never loads. A reader who resolves the placeholder to main after
  sprouting reproduces exactly the wrong-checkout write that reopened this
  task, and `unrooted-tatr-call` cannot catch it - the call is rooted, just
  rooted wrong. Name the referent at the transition: change step 2's trailing
  clause to "the new worktree is `<task-root>`; use absolute paths for every
  edit/git/tatr call." (Body is 394 of 400 words, so keep the edit inside the
  clause it replaces.)
  - Response: fixed. `work/SKILL.md:18-19` now reads "The new worktree becomes
    `<task-root>`. Shell cwd does not persist: use absolute paths for every
    edit/git/tatr call." Took "becomes" over the suggested "is" to mark the
    change of referent, and dropped "worktree" from the paths clause since the
    sentence before it now establishes which tree. Body 398 of 400.
- [x] R1.2 (MINOR) home/modules/agents/skills/flow/SKILL.md:11 - the reworded
  opener sends the existing-ID path to `resume.md` to select `<task-root>`,
  then hands the NEW-ID path `tatr -r <task-root> context <id>` - a
  placeholder that path is never told how to resolve, and `resume.md` is
  explicitly the existing-ID branch. A new ID has no worktree, so say so:
  "For a new ID, `<task-root>` is the main checkout; read ...". Body is 298 of
  300 words, so reclaim the words inside the same sentence.
  - Response: fixed. `flow/SKILL.md:10-12` now reads "For an existing ID,
    `resume.md` selects `<task-root>`; a new ID has none, so use the main
    checkout." Cut "load" and "before reading state" to pay for it; the
    `Load on demand` table already routes an existing ID to `resume.md`. Body
    299 of 300.
- [x] R1.3 (NIT) home/modules/agents/skills/check.sh:73 - the exemption note
  says `frontier`, `claim` and `release` "either predate the record or
  quantify over the whole tree", but `flow/epic.md:26,40,42` calls all three
  with a task ID (`tatr frontier <epic-id>`, `tatr claim <id>`,
  `tatr release <id> --force`). Only `frontier` is genuinely tree-wide.
  Either reword the note to name the real reason each is out (claims live in
  `TATR_CLAIMS_DIR`, not the checkout) or pull `claim`/`release` into
  `TATR_ID_SUBS`.
  - Response: fixed by rewording, not by widening the rule. `check.sh:72-74`
    now splits the three reasons: `new` predates the record; `ls`, `frontier`
    and `claims` quantify over the whole tree; `claim` and `release` write
    `TATR_CLAIMS_DIR`, not the checkout. Adding them to `TATR_ID_SUBS` would
    demand a root the claim path never reads.

Process signal: the task was reopened mid-flight and roughly doubled - the
planned scope was four review follow-ups plus a `--repo` note; the delivered
diff also adds a new `check.sh` rule and rewrites 25 command sites across 15
skill files. The reopening is well recorded in TASK.md and the trigger was a
real failure inside this task's own run, so this is not a finding. It is worth
the retro's attention as an argument for splitting a discovered systemic fix
into its own task rather than growing the one that surfaced it.

Verified independently: all 10 `tatr proofs` commands run green from the
worktree, including the falsification proof; `afk-test.sh` 9/9,
`sprout-test.sh` 16/16, `check.sh` clean (8 skills, 23 rules), `tatr check`
clean, `nix flake check` 6/6. Re-derived the load-bearing two-line-window
claim by wrapping `tatr` away from `flow` in a temp copy of `flow/gates.md` -
the rule reports it once, at the starting line. Re-derived the `AGENTS.md`
vocabulary split against `afk.sh:404-447` (all seven statuses branch there;
`grep -rn ROTATE` over the skills tree returns nothing, so afk's own
vocabulary really is afk-only). Confirmed the goal-mode test reaches
`afk.sh:393` - it is the only path with `TASK_ID` empty.

No open `manual:` proofs.

## Round 2

- REVIEWER: in-session (round 2 is three prose edits, 12 changed lines across
  two skill bodies and one comment, each a direct answer to a round-1 finding
  this same reviewer wrote; nothing new was designed or implemented)
- VERDICT: APPROVE

All three round-1 findings verified fixed and ticked above. Verified, not
inferred:

- R1.1 `work/SKILL.md:18-19` names the sprout as `<task-root>` inside step 2,
  after `sprout new` and before the transition it governs - the ordering the
  finding asked for. Budget 398 of 400.
- R1.2 `flow/SKILL.md:10-12` gives the new-ID path its own referent. Budget
  299 of 300. The dropped "load" does not orphan `resume.md`: the
  `Load on demand` table still routes an existing ID to it.
- R1.3 `check.sh:72-74` now separates the three exemption reasons, and
  `TATR_ID_SUBS` is unchanged, so no proof depending on the rule's scope
  moves. Confirmed `tatr claim`/`release` are absent from every flow-family
  command site except `flow/epic.md:40,42`, which the reworded note covers.

Re-ran after the fixes: `check.sh` clean (8 skills, 23 rules); the
falsification proof still reports `unrooted-tatr-call`; `--rules` still lists
it; `afk-test.sh` 9/9; `sprout-test.sh` 16/16; `tatr check` clean;
`nix flake check` 6/6. Tree clean at 8f868b6.

No open `manual:` proofs.
