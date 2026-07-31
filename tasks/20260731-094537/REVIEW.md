# Review: Widen absence-proof grep guidance to exclude prose about the removal

- TASK: 20260731-094537
- BRANCH: feature/absence-proof-comments

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/agents/skills/plan/proofs.md:56 - the `^[^/]*`
  variant offered for `//` languages is wrong: `[^/]*` stops at ANY slash, not
  just a comment opener, so paths, imports and URLs hide real hits. Over
  `let oldname = 1; // gone`, `// oldname was here` and
  `const url = "http://x/oldname";`, `grep -rnE '^[^/]*oldname'` prints only
  line 1 and silently drops the genuine reference on line 3. Drop the `^[^/]*`
  form rather than replacing it with a cleverer regex.
  - Response: dropped. The bullet now names `^[^/]*` as the trap it is - "it
    stops at the slash in any path or URL, hiding real code" - and tells the
    reader to exclude by path for other comment syntaxes rather than invent a
    regex.
- [x] R1.2 (MAJOR) home/modules/agents/skills/plan/proofs.md:55 - the caveat
  covers only `//` languages and never says the pattern is invalid where `#`
  is not a comment marker. Markdown is the case that matters here: the
  section's own first fence greps `docs/`, and this repo's whole doc surface
  is `.md`. Over a file containing `# oldname API` and `## oldname migration`,
  the documented command drops both - real stale references reported as
  absent. State that the pattern applies only where `#` starts a comment, and
  that doc trees are scoped by directory or `--include` instead.
  - Response: done. The first bullet says the filter holds only where `#`
    STARTS a comment and names the markdown heading as a real hit it hides;
    the second says to scope doc trees by directory or `--include`, not by
    this pattern.
- [x] R1.3 (MAJOR) home/modules/agents/skills/plan/proofs.md:55 - "keeps a hit
  only where the token appears before any `#`" is stated as a benefit with no
  mention of its false-green half: any earlier `#` on the line, including
  inside a string, hides a genuine code hit
  (`cfg = { color = "#fff", mod = oldname }` drops). Name the failure mode and
  tell the author to compare the filtered hits against the unfiltered
  `grep -rn oldname .` once, so a dropped code line is caught at plan time.
  - Response: done. The same bullet names the string-literal case and requires
    reading the unfiltered `grep -rn oldname .` once to confirm everything the
    filter drops is prose. A new DoD item pins it.
- [x] R1.4 (MINOR) home/modules/agents/skills/plan/proofs.md:57 - "a
  `| grep -v` tail would report the filter's exit code instead of the search's"
  is true but misleading for an ABSENCE proof, where the filter's exit code has
  the wanted polarity (1 when nothing survives). The real hazard is that
  `grep -rn oldname nosuchdir/ | grep -v ...` also exits 1, so a misaimed
  search reads as green. Restate the reason as "the tail hides a search that
  ran wrong - a mistyped path exits 1 and reads as absent".
  - Response: done, adopted almost verbatim; the DoD proof for this clause now
    greps `reads as absent` rather than the withdrawn wording.
- [x] R1.5 (NIT) home/modules/agents/skills/plan/proofs.md:51 - the repo-wide
  form greps `.` without `--exclude-dir=.git`, so commit messages under `.git`
  can produce a false red on exactly the removal being proved. Add
  `--exclude-dir=.git` alongside `--exclude-dir=tasks`.
  - Response: done. Kept despite this machine's ugrep skipping dot-directories,
    because the reference is read by sessions whose `grep` may be GNU.

Verification, in-session pass. R1.1, R1.2 and R1.3 were re-derived here from
scratch files rather than adopted: each documented pattern drops the case the
finding names. All seven proofs from `tatr proofs 20260731-094537` run green in
the worktree; `check.sh` is clean at 22 rules, `tatr check --ledger LESSONS.md`
is clean, `sprout-test.sh` is 14/14, and bare `nix flake check` passes.

R1.5 is adopted with a correction the out-of-context reviewer could not have
known to make: `grep` on this machine is ugrep 7.5.0, which skips
dot-directories under `-r` by default, so `grep -rn oldname .git/` finds
nothing here while the same command under GNU grep matches
`.git/COMMIT_EDITMSG`. The finding is right for any reader whose `grep` is GNU,
which is the audience a skill reference is written for, so the exclusion goes
in.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

R1.1 through R1.5 were each re-derived against the new text by the round-1
reviewer and are ticked above on its confirmation. The three findings below are
new, all MINOR or NIT, so the verdict is APPROVE; they were fixed anyway.

- [x] R2.1 (MINOR) tasks/20260731-094537/TASK.md:51 - the DoD proof for the
  `//` clause, ``grep -n "\^\[\^/\]\*"``, does not discriminate the defect it
  was written for: replacing the warning with the round-1 wrong advice,
  "Use `^[^/]*` where comments are `//`", leaves it green, because both
  wordings contain the token. It goes red only on outright deletion. Pin the
  warning's polarity instead, e.g. ``grep -n "Do not invent the equivalent"``.
  - Response: done, the proof now greps `Do not invent the equivalent`. Mutation
    re-run in-session: under the inverted advice the old proof stays green
    (rc=0) and the new one goes red (rc=1).
- [x] R2.2 (MINOR) home/modules/agents/skills/plan/proofs.md:51 - the copyable
  fence still greps `.`, which includes markdown, while the bullet below it
  says doc trees must be scoped by directory or `--include`. Run verbatim over
  a tree with a `docs/g.md`, it prints the prose line and silently drops
  `# oldname API` and `## oldname migration` - exactly the case R1.2 named. Make
  the fence show the scoping it prescribes.
  - Response: done. The filtered fence line now carries `--include='*.nix'`, so
    the pattern is only ever applied to files whose `#` starts a comment, and
    the unscoped repo-wide form is no longer the copyable one.
- [x] R2.3 (NIT) home/modules/agents/skills/plan/proofs.md:60 - the cross-check
  command drops the exclusions the fence established, so it re-imports the
  `tasks/` noise the section exists to remove; the reader has to mentally
  discard an expected drop. Write it as the same command minus only the filter.
  - Response: superseded by R3.1, whose fix delivers what this finding asked
    for - the cross-check now differs from the filtered run by the comment
    filter alone. Confirmed resolved by the reviewer in round 4.

Verification, in-session pass. R2.1 was re-derived by mutating the bullet to
the inverted advice and watching the old proof stay green; R2.2 by running the
fence verbatim over a scratch tree containing `docs/g.md` and watching two real
headings disappear; R2.3 by counting the `tasks/` hits the cross-check
re-imports. All three were confirmed before being adopted, not read off the
findings.

## Round 3

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

R2.1 and R2.2 confirmed resolved and ticked above. R2.3's fix was a no-op and
is superseded by R3.1, so its box stays open.

- [x] R3.1 (MAJOR) home/modules/agents/skills/plan/proofs.md:60 - "Re-run the
  same command without `-E`" is a no-op cross-check: `^[^#]*oldname` is a valid
  BRE meaning exactly what the ERE means, so both runs return the same lines
  and the check can never reveal a hidden hit. Re-derived in-session over a
  scratch `src/a.nix`: with `-E` and without `-E` both print only line 2, while
  the bare token prints all three, including the string-literal line
  `cfg = { color = "#fff"; mod = oldname; }` the filter hides. Tell the reader
  to re-run with the bare token, same flags.
  - Response: done. The bullet now says to cross-check "with the bare token -
    same flags, but searching `oldname` instead of the pattern", and states
    outright that deleting just the `-E` changes nothing. This was my error in
    the R2.3 fix, not the reviewer's.
- [x] R3.2 (MAJOR) home/modules/agents/skills/plan/proofs.md:51 -
  `--include='*.nix'` in the copyable command is repo-specific and silently
  skips every other file type, including the other `#`-comment languages the
  pattern is valid for. Re-derived: with a real stale reference at
  `src/deploy.sh:3`, the documented command never reports it. Write the glob as
  a placeholder the reader must fill and require every extension in play to be
  listed.
  - Response: done. The fence carries `--include='*.<ext>'` and the first
    bullet says to fill in every extension the mechanism could live in
    (`*.nix`, `*.sh`), "or the search skips the file still referencing it".
- [x] R3.3 (MINOR) tasks/20260731-094537/TASK.md:57 - the heading proof
  `grep -n "^## Absence proofs"` matches the pre-change heading too, so it
  never discriminated. Carried from the plan, not introduced by round 2. Pin
  the new wording.
  - Response: done, repinned on `^## Absence proofs must exclude prose`.
- [x] R3.4 (NIT) home/modules/agents/skills/plan/proofs.md:63 - the doc-tree
  bullet dropped its `--include` half while the fence above now relies on
  `--include`. Restore "by directory or `--include`".
  - Response: done.

Verification, in-session pass. R3.1 and R3.2 were both re-run here before being
adopted; R3.1 in particular is confirmed - `grep -rn '^[^#]*oldname'` and
`grep -rn -E '^[^#]*oldname'` return identical output, so the cross-check
written in round 2 was worthless. Three of the four DoD proofs over the prose
moved with the wording they pin.

## Round 4

- REVIEWER: out-of-context
- VERDICT: APPROVE

R3.1 through R3.4 confirmed resolved and ticked above, and R2.3 closed as
superseded by the R3.1 fix. Asked to judge the design as a whole - whether the
`#` pattern still earns its five bullets against simply scoping by directory
and reading the hits - the reviewer answered keep it: directory scoping cannot
exclude a comment INSIDE a source file, which is the case that motivated the
lesson, and a `cmd:` proof needs an exit code rather than a human reading hits.
It filed no finding for it.

- [x] R4.1 (MINOR) home/modules/agents/skills/plan/proofs.md:63 - the
  cross-check works now, but the section never says what to do when it fires: a
  reader who finds the filter hiding a real hit has a proof that reads green
  with the mechanism still present, and no instruction beyond "confirm
  everything the filter drops is prose". Name the fallback.
  - Response: done. The bullet now ends "If the cross-check shows a real hit
    dropped, the pattern is wrong for that token: scope by directory and pin
    the proof on a narrower token instead", and a tenth DoD proof pins it.

Verification, in-session pass. The reviewer mutation-tested the six prose
proofs eight ways this round - including inverting each clause rather than only
deleting it - and each mutation reddened exactly one proof. It could not re-run
`nix flake check` at head 4143e4c; that run was made here before the commit and
passed, and is re-run below after the R4.1 fix.

## Round 5

- REVIEWER: out-of-context
- VERDICT: APPROVE

R4.1 confirmed resolved and ticked above; no findings this round. The reviewer
mutation-tested the tenth proof two ways - deleting the fallback sentence, and
inverting it to "reword the prose until the filter stops matching it", the
exact pressure the section's opening paragraph warns against - and each
reddened that proof alone.

It re-ran every gate at this head, including the bare `nix flake check` it
could not reach in rounds 3 and 4, and confirmed the record side: the ticks
match what it verified, R2.3 is closed as superseded with its reasoning
stated, and the close-out stat block matches the current diff. Nothing outside
`LESSONS.md`, `home/modules/agents/skills/plan/proofs.md` and
`tasks/20260731-094537/` changed across all five rounds.

Still unverifiable by anyone in this loop: whether the six occurrence IDs the
ledger entry cites are genuine. That needs history the reviewer does not have,
and the ticks do not claim it.
