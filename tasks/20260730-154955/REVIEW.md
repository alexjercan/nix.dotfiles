# Review: Integrate guarded flow lifecycle and lesson decisions

- TASK: 20260730-154955
- BRANCH: feature/guarded-flow-lifecycle

## Round 1

- REVIEWER: out-of-context (three lanes - behavior and proofs; correctness of
  the new shell rule; design, standards and docs. Lanes were opened because
  the skills ship to `~/.claude/skills`, `~/.agents/skills` and
  `~/.codex/skills`, so the diff is shared infrastructure reaching beyond this
  repository, and `direct-state-edit` is a new gate contract.)
- VERDICT: REQUEST_CHANGES

R1.2 through R1.7 are six symptoms of one thing: `direct-state-edit` was
written as a chain of independent greps and never tested in the
false-positive direction. They are filed separately because each names a
distinct concrete change, but they want one redesign, not six patches.

- [x] R1.1 (BLOCKER) tasks/20260730-154955/TASK.md:124 - the close-out cites
  "593 insertions(+)" and claims the figure was re-read AFTER the block was
  appended. It was not: the real figure is 596
  (`git diff --shortstat master...HEAD` and the merge-base form both agree,
  with the only uncommitted change being the FLOW STEP marker, net 0). 593 was
  read before the Edit that corrected the number, so the paragraph narrating
  `counts-come-from-the-diff` reproduced it a second time. Change 593 to 596,
  re-read after editing, and bump `counts-come-from-the-diff` in LESSONS.md
  rather than correcting it silently.
  - Response: fixed. The real figure is 596; the close-out now states it, says it was re-read after the edit that changed it, and names the miscount. `counts-come-from-the-diff` bumped to x4 in LESSONS.md with 20260730-154955 added and the recurrence described, rather than corrected silently.

- [x] R1.2 (BLOCKER) home/modules/agents/skills/check.sh:405 - `EXEMPT_RE`
  matches the bare tokens `tatr` and `never` anywhere in the sentence, which
  exempts the exact shape the rule exists to catch. All silent:
  `If \`tatr flow\` is unavailable, set FLOW STEP: WORKING in TASK.md by hand.`;
  `When tatr is unavailable, set FLOW STEP: WORKING in TASK.md yourself.`;
  `The reviewer never edits it; the closer sets STATUS: CLOSED in TASK.md by
  hand.` Measured over the real corpus, 17 of 39 marker/disposition sentences
  in the flow family already hit `EXEMPT_RE`, so the rule is blind on 44% of
  the text it claims to quantify over. Require the tool to be adjacent to the
  verb (`` `tatr [a-z]+` `` as the clause subject, or `tatr [a-z]+
  (writes|sets|flips)`), and scope the negation exemption to a negated edit
  verb (`(do not|never|don't) [a-z ]{0,12}(edit|write|set|type|hand-edit)`)
  instead of the bare word. Add a self-test case planting a `tatr`-naming
  fallback sentence and asserting the rule still fires.
  - Response: fixed. Exemption is now keyed on ROLE, not presence: the tool must be the clause SUBJECT (`(^ |, )tatr <verb>` within five tokens of an edit verb) or the named INSTRUMENT (`with|via|using|through tatr <verb>`), and the negation exemption must attach to the edit verb (`(do not|does not|never|cannot|not) [a-z]{0,3 words} <verb>`). All three probe sentences now fire; two are self-test cases (marker-edit-tatr-fallback, marker-edit-past-a-negation).

- [x] R1.3 (BLOCKER) home/modules/agents/skills/check.sh:400 -
  `EDIT_VERB_RE` omits the most natural imperatives for this action, so the
  rule is silent on the phrasings most likely to be written. All silent:
  `Update FLOW STEP: DONE in TASK.md by hand.`; `Add FLOW STEP: DONE to
  TASK.md by hand.`; `Append the PLAN STATUS line to TASK.md manually.`;
  `Replace PLAN STATUS with APPROVED by hand.`; `Record PLAN STATUS: APPROVED
  in TASK.md yourself.`; `Bump PLAN STATUS to APPROVED by hand.`; `Record the
  RETIRE disposition in the ledger by hand.` Add at least
  `update|add|append|record|replace|insert|bump|overwrite|fill|toggle|correct`
  with their `-s` forms, and one self-test case per verb family so the list
  cannot silently regress.
  - Response: fixed. Verb list extended with update/add/append/record/replace/insert/bump/overwrite/fill/toggle/correct and their -s forms. Three self-test cases added (marker-edit-verb-update, -record, -append); all seven of your probe sentences now fire.

- [x] R1.4 (MAJOR) home/modules/agents/skills/check.sh:419 - operator
  precedence in `(\($DISPOSITION_RE\)?.*ledger)` is wrong. Alternation binds
  looser than the surrounding literals, so the branch expands to `\(PROMOTE` |
  `DEFER` | `RETIRE` | `ABSORBED\)?.*ledger`. Verified: `the DEFER date is
  fine` MATCHES with no ledger context anywhere, while `write PROMOTE into the
  ledger` does not match at all. Wrap the alternation:
  `\(?($DISPOSITION_RE)\)?.*ledger` - which flips both results correctly. The
  self-test case at fixtures/selftest.sh:187 passes only via the bare-`DEFER`
  branch, so it never covered the ledger-ordering path; add a
  `PROMOTE`-into-the-ledger case.
  - Response: fixed. The alternation is parenthesised as `[^a-z](promote|defer|retire|absorbed)[^a-z]` with `ledger` required separately, so `the DEFER date is fine` no longer matches and `Write PROMOTE into the ledger by hand.` does. Added the disposition-edit-promote self-test case for the ledger-ordering path.

- [x] R1.5 (MAJOR) home/modules/agents/skills/check.sh:401 - `in TASK\.md`,
  `into the task` and `directly` describe LOCATION and TIMING, not agency, so
  ordinary descriptive prose is flagged. Both FIRED: `Each phase writes its
  own FLOW STEP into the task before it hands back.`; `The compound phase
  marks the task STATUS: CLOSED directly after the retro.` Drop `in TASK\.md`
  and `into the task`, require `directly` to sit next to the verb, and keep
  `by hand|hand-edit|yourself|manually`. The deeper gap: `--self-test` only
  ever proves a rule CAN fire, so nothing in the suite tests the quiet
  direction. Add at least one negative case asserting `check.sh` stays clean
  on correct descriptive prose.
  - Response: fixed. `in TASK.md` and `into the task` dropped; `directly` now only counts within two tokens of the verb. All four of your prose sentences are clean. Added `expect_clean` to the self-test harness plus four negative cases - the suite now tests the quiet direction at all.

- [x] R1.6 (MAJOR) home/modules/agents/skills/check.sh:410 - `sentences_of`
  splits only on `[.!?] `, but markdown headings and list items carry no
  terminal punctuation, so a whole block collapses into one pseudo-sentence.
  Appending a marker bullet to `spike/SKILL.md` fired the rule but reported
  the offending text as `## Load on demand - locating the ledger, its format,
  or a promotion or retirement decision`, attributing the violation to an
  unrelated pointer line. That is both a false-positive surface and an
  unactionable message. Also split on blank lines and on line starts matching
  `^(#{1,6} |[-*] |[0-9]+\. )`, report the matched marker/verb substring
  rather than the first 90 characters, and add a self-test case whose sabotage
  is a bullet so the scoping is proven.
  - Response: fixed. Replaced the tr/sed/grep chain with one awk pass that splits on sentence punctuation, the semicolon, blank lines, and heading/list starts, joining wrapped lines first. The message now reports the offending clause itself. Added marker-edit-in-a-bullet.

- [x] R1.7 (MINOR) home/modules/agents/skills/check.sh:401 - requiring a
  `BY_HAND_RE` conjunct at all means a bare imperative passes: `Set the FLOW
  STEP to WORKING before starting.` and `Write PLAN STATUS: APPROVED once the
  user agrees.` are both silent, and neither names a tool. Once R1.2's
  attribution test exists, the by-hand phrase should stop being mandatory: a
  sentence with a marker and an edit verb and NO tool attribution is the
  violation. Filed MINOR only because it cannot be fixed before R1.2 and R1.5
  without a false-positive explosion.
  - Response: fixed, and it did not need to wait: with role-based attribution in place the by-hand phrase is no longer mandatory. Agency is now an imperative BARE verb at the clause head or chained after and/then/or, or an explicit by-hand phrase. `Set the FLOW STEP to WORKING before starting.` fires (marker-edit-bare-imperative); `The Step list changes STATUS: OPEN in TASK.md as the work proceeds.` stays clean, because `changes` is third person.

- [x] R1.8 (MINOR) home/modules/agents/skills/check.sh:422 - `|| true` covers
  the whole pipeline including `sentences_of`, so an unreadable or missing
  file yields empty `hits` and passes silently; with `set -uo pipefail` and no
  `-e`, nothing else notices. Guard the file first
  (`[ -r "$f" ] || { fail "$rel" direct-state-edit "unreadable"; continue; }`)
  and keep `|| true` on the final `grep -v` only.
  - Response: fixed. The file is checked with `[ -r ]` first and an unreadable one now fails as `direct-state-edit: not readable, so the rule cannot clear it`. The remaining `|| true` is gone entirely - awk needs none.

- [x] R1.9 (MINOR) home/modules/agents/skills/flow/SKILL.md:56 - "Finish asks
  for those, never assumes them" makes flow the actor that asks, but
  lessons/SKILL.md:53-60 makes `lessons` the actor, and flow/SKILL.md:7 says
  flow "dispatches phases; it never restates their rules". Reword to "then
  invoke `lessons`, which settles every pending promotion with the user.
  `tatr check --ledger <ledger>` must exit 0, which it cannot while one is
  undecided."
  - Response: fixed, with your wording. Finish now reads "then invoke `lessons`, which settles every pending promotion with the user", so `lessons` is the actor and flow only dispatches. AGENTS.md was cut back too (see R1.14).

- [x] R1.10 (MINOR) home/modules/agents/skills/compound/SKILL.md:55 - "the
  gate belongs to flow's Finish" contradicts lessons/SKILL.md's own frontmatter
  trigger ("for `/lessons`, at a flow Finish, or before a release"): a
  standalone `/lessons` or a release pass settles dispositions with no flow
  around. Reword to "the gate belongs to `lessons`, which flow's Finish and a
  release pass both run".
  - Response: fixed, with your wording: "the gate belongs to `lessons`, which flow's Finish and a release pass both run".

- [x] R1.11 (MINOR) home/modules/agents/skills/lessons/ledger.md:58 - the
  grammar describes a decided entry "moved back to its own section" with an
  applied marker, but never says WHO moves it or WHEN a `PROMOTE -> <task-id>`
  becomes `PROMOTED -> <target>`. LESSONS.md:169 and 182 are the live
  instance: both PROMOTEs now sit in Pending with no documented exit. Add one
  sentence naming the transition, matching the step already written in
  tasks/20260731-094537/TASK.md.
  - Response: fixed. A new paragraph states that a disposition is an ANSWER, not a completion: the entry stays in Pending until the promoting task lands, and that task's own last step records the outcome through `tatr ledger`, which applies the `PROMOTED` marker and moves it out. A PROMOTE whose task never lands stays visible as pending work.

- [x] R1.12 (MINOR) home/modules/agents/skills/lessons/ledger.md:17 - the
  Format preamble still says counts "stay bare until a lifecycle event
  annotates them", which the new section contradicts for Pending entries,
  where a bare count is `promotion-awaiting-decision`, a blocking error rather
  than the resting state. Scope the preamble: bare is the resting state
  OUTSIDE Pending; inside Pending it is an unanswered question.
  - Response: fixed. The Format preamble now scopes itself: bare is the resting state OUTSIDE Pending; inside it a bare count is an unanswered question that fails as `promotion-awaiting-decision`.

- [x] R1.13 (MINOR) home/modules/agents/skills/README.md:106 - the doc sweep
  missed the README. AGENTS.md gained `direct-state-edit`, but README's
  "check.sh owns the skill TEXTS: budgets, the reference graph, substituted
  typographic glyphs, the invocation policy, duplicated paragraphs, and the
  fixtures" still enumerates the old rule set, and README is where AGENTS.md
  sends readers for skill conventions. Add the rule with its one-line meaning.
  - Response: fixed. README's rule list now names `direct-state-edit` with its meaning, and records that `--self-test`'s negative cases prove the gate stays clean on correct prose.

- [x] R1.14 (MINOR) AGENTS.md:31 - the global `## Agent workflow` rule is
  "one line each, detail behind ONE pointer", but the lessons-ledger bullet
  grew to five lines restating ledger.md's grammar, so the same rule now lives
  in three files. Cut to one line plus the pointer.
  - Response: fixed. Cut to one line plus the pointer, using your wording.

- [x] R1.15 (MINOR) tasks/20260730-154955/DECISION.md:67 - the Consequences
  predict the exemption path as future work ("It will also need a deliberate
  exemption path"), but `EXEMPT_RE` shipped in this diff and is far broader
  than "descriptive prose" (R1.2). "The self-test's uncovered-rules report
  makes a vacuous rule impossible to land" also overstates: it proves the rule
  fires on five hand-picked sabotages that all avoid the exemption tokens.
  Rewrite the Harder paragraph to state the exemption exists, name its terms,
  and record its false-negative surface.
  - Response: fixed. The Consequences now state that the exemption SHIPPED, name its exact terms, record that coverage is not non-vacuity (citing this round's 17-of-39 blindness), and name the remaining known cost - agency is decided from surface grammar, so a violation written as a bullet continuation can still read as description.

- [x] R1.16 (MINOR)
  home/modules/agents/skills/fixtures/content/lesson_decision_gate_flow.fixture:4
  - the DoD criterion is "a threshold lesson blocks Finish until the user
  disposition is recorded", but the fixture asserts only the bare substring
  `disposition` anywhere in flow/SKILL.md. The behavior IS delivered; the
  assertion is just far weaker than the criterion. Tighten to the load-bearing
  clause, e.g. `requires: tatr check --ledger, must exit 0, lacks the user's
  disposition`.
  - Response: fixed. The fixture now requires `tatr check --ledger`, `must exit 0` and `lacks the user's disposition`.

- [x] R1.17 (MINOR)
  home/modules/agents/skills/fixtures/content/lesson_dispositions_defer.fixture:5
  - the DoD's second clause ("DEFER/RETIRE/ABSORBED cache the answer and do
  not ask again") is asserted by no case; the five fixtures require only the
  four disposition words plus `out-of-context review`. Add
  `requires: cached, not raised again` so the caching half is proven.
  - Response: fixed. `lesson_dispositions_defer.fixture` now requires `DEFER`, `cached` and `not raised again`, and ledger.md states the caching clause for DEFER, RETIRE and ABSORBED explicitly.

- [x] R1.18 (NIT) LESSONS.md:169 - the reflowed entry runs to ~109 columns
  where the rest of the file wraps at ~78, and the id list landed mid-sentence
  ("falling back to the close-out template. 20260720-171843, ...:"), reading
  as a dangling fragment. Rewrap and put the ids at the end of the entry as
  the format example does.
  - Response: fixed. Both entries rewrapped to the file's ~78 columns and the id list moved to the end of the entry, as the format example does.

- [x] R1.19 (NIT) home/modules/agents/skills/check.sh:418 - the rule spawns
  two `tr`s, a `sed` and four `grep`s per markdown file: ~1.1s added to
  `check.sh` (7.4s vs 6.4s on master) and ~48s to `--self-test`, now 5m31s.
  One `awk` would pay that back.
  - Response: fixed by the R1.6 rewrite: one awk pass replaces two `tr`s, a `sed` and four `grep`s per file. `check.sh` now runs in ~7.0s where the round-1 form took ~7.4s, against a ~6.4s master baseline, so the rule's own cost fell from ~1.0s to ~0.6s. The self-test grew to 57 cases because 12 were added, not because each got slower.

- [x] R1.20 (NIT) home/modules/agents/skills/check.sh:410 -
  `sed 's/\([.!?]\) /\1\n/g'` relies on GNU sed's `\n` in the replacement.
  BSD/macOS sed inserts a literal `n`, silently merging every sentence into
  one line and turning the rule into a whole-file matcher rather than an
  error. Use `awk` if the gate is ever expected to run off NixOS.
  - Response: fixed by the same rewrite - there is no `sed` in the rule any more. The awk `match`/`substr` split is POSIX and behaves identically off GNU.

Verified by the in-session pass (re-derived, not adopted):

- Every claim in R1.1 through R1.6 was reproduced independently in a scratch
  copy before being filed; the lanes' probe results all held.
- `check.sh` clean (9 skills, 179 description words); `--self-test` exit 0
  with 44 sabotage cases and 33 of 33 rules covered; all five DoD fixtures ok
  with 2, 4, 2, 2 and 5 cases - each matching the close-out's numbers.
- `tatr check` and `tatr check --ledger LESSONS.md` exit 0 on the branch, and
  the Notes' base-branch claim holds: on master the same command exits 1 with
  exactly the two findings named.
- `nix flake check` BARE and `--no-build` both pass; the primary ran these,
  since AGENTS.md records that `--no-build` proves nothing about assertions.
- `sprout-test.sh`: passed 14, failed 0.
- Both PROMOTE targets exist, so no dangling promotion.
- The behavior lane could not confirm that a human answered Step 8's
  disposition question. The primary confirms it: both PROMOTE answers came
  from the user through the platform's user-input mechanism, and neither was
  invented.

Not verified:

- Whether whitespace normalization could let a future `requires:` be satisfied
  across a code-fence boundary. Plausible from the code; no case could be
  constructed against the current fixture set, so it is not filed.

## Round 2

- REVIEWER: in-session (the user directed a scope change mid-round; this round
  records it and its consequences for round 1, and does not issue a verdict on
  new implementation work)
- VERDICT: REQUEST_CHANGES

The user removed the fixture suite: `home/modules/agents/skills/fixtures/` is
deleted, along with `--fixture`, `--self-test` and the twelve rules that only
the fixture runner emitted. The stated reason is that it took too long to run
and was hard to iterate on. That is a scope decision, not a finding, so it is
recorded here rather than filed.

What it does to round 1:

- R1.5, R1.16, R1.17, R1.19 and R1.20 are now MOOT. Their fixes shipped and
  were then deleted with the harness: the four `expect_clean` negative cases,
  the two tightened fixtures, and the sed/perf concerns that only applied to
  code that no longer exists.
- R1.1 through R1.4 and R1.6 through R1.15 stand as fixed. The
  `direct-state-edit` rewrite survives in full, including clause segmentation,
  role-based attribution and the expanded verb list - it never depended on the
  fixture harness.
- The falsifiability guarantee is GONE. Nothing now proves a rule in check.sh
  can fail. `direct-state-edit` was verified by hand across 33 probe sentences
  in both directions before the removal, but that evidence is a transcript,
  not a check, and the next edit to the rule has nothing holding it.
- The task's Definition of Done was rewritten: five `test:` proofs named
  fixture cases with no runner left. Each is restated as a grep or command, or
  as the one `manual:` item that only a reader can settle.

- [x] R2.1 (MAJOR) home/modules/agents/skills/check.sh:1 - with `--self-test`
  gone, `RULES` is now an unverified claim: nothing checks that every declared
  slug is still emitted by the source, or that a rule can fire at all. The
  round-1 self-test caught exactly this class (it found `direct-state-edit`
  blind on 44% of the corpus while passing five sabotages). Either drop the
  `RULES` array and `--rules` so the gate stops claiming an inventory it does
  not verify, or keep a single cheap assertion that every declared slug
  appears in a `fail` call in the file. The second is about ten lines and
  costs no runtime.
  - Response: fixed, taking the second option. `check.sh` section 9 now checks
    the inventory in BOTH directions: every declared slug must appear in a
    reporting call, and every reported slug must be declared. Verified by
    sabotage - adding a `ghost-rule` to RULES reports "declared in RULES but
    nothing reports it", and deleting `duplicated-paragraph` from RULES
    reports "reported but missing from RULES". Two gotchas worth recording:
    the extractor first matched a phrase inside its OWN finding message
    ("no fail call emits it"), so comment lines are stripped and the messages
    avoid the matched words; and `router-body-budget`/`phase-body-budget` are
    selected at runtime, so they stay declared exceptions. The clean line now
    prints the rule count.

- [ ] R2.2 (MINOR) tasks/20260730-153122/TASK.md - the parent Epic's
  `## Done Means` still names fixture-backed proofs that can no longer run:
  criterion 3 (test: `test_epic_frontier`), criterion 5
  (test: `parallel_lane_selection`), and criterion 4's "skill evaluation
  harness". Criterion 2 (`bash check.sh`) still holds. The Epic cannot reach
  its own Done Means as written, so it needs the same rewrite this task's DoD
  just took, before Finish.
  - Response: not this branch's problem and not fixed here - the Epic is task
    20260730-153122 and rewriting its Done Means inside this diff would widen
    the scope past one task. Raised for the Epic's own Finish, where the
    manual acceptance items are already batched. Filed as task
    20260731-104819 so it cannot be forgotten, per the review skill's rule
    that a finding this branch will not fix becomes a task whose ID goes on
    the Response line.

Verified after the removal:

- `bash check.sh` clean in ~2.7s, down from ~7.0s.
- `check.sh --rules` lists 22 rules; the two runtime-selected budget rules are
  the only declared-but-not-literally-emitted entries, as before.
- `check.sh --self-test` now exits 2 with "unknown argument", so a stale
  invocation fails loudly rather than reading as a pass.
- `tatr check` and `tatr check --ledger LESSONS.md` exit 0.
- `sprout-test.sh`: passed 14, failed 0.
- `nix flake check` BARE: all checks passed, with `skills-conformance` no
  longer invoking `--self-test`.
- All seven rewritten DoD proofs run green; the `manual:` item is pending the
  user.

## Round 3

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

Verdicts on the earlier rounds: R1.1-R1.15, R1.17-R1.20 and R2.1 confirmed
FIXED; R1.16 MOOT (its fixture died with the harness); R2.2 deferred to task
20260731-104819. The reviewer corrected round 2's own bookkeeping: R1.19 and
R1.20 are genuinely fixed rather than moot, because the sed/tr/grep chain is
gone and the rule is one awk pass, and R1.5's false-positive defect is fixed
in code even though its `expect_clean` guard died.

- [x] R3.1 (BLOCKER) tasks/20260730-154955/TASK.md:304 - the addendum's diff
  stat claims "87 files changed, 462 insertions(+), 1035 deletions(-) against
  the base, read AFTER this block was written". `git diff --shortstat
  master...HEAD` gives 78/1152/925 on a clean worktree. No form of the command
  produces 462/1035. Fifth occurrence of `counts-come-from-the-diff`, inside
  the close-out that narrates the fourth.
  - Response: fixed, and the diagnosis is worse than a stale read. 462/1035
    came from `git diff --cached --shortstat`, which measures the INDEX
    against the PREVIOUS COMMIT, not the branch against its base - so the
    number answered a different question entirely, and the "87" was the file
    count of one commit. The block now cites `git diff --shortstat
    master...HEAD` by name, was written with placeholder digits, committed,
    then filled in and amended - an amend that changes only digits cannot
    change the line counts it reports, and the figure was re-read afterwards
    to confirm. `counts-come-from-the-diff` bumped to x5 with all three
    instances described.

- [x] R3.2 (MINOR) flake/checks-skills.nix:82 - the comment claims "every
  deployed name is a real skill directory", but the only assertion checking
  that direction was the `grep -qx fixtures` guard this round deleted. A typo
  in `localSkills` now builds green.
  - Response: fixed by restoring the check rather than weakening the comment.
    The first attempt was VACUOUS and I caught it by sabotage before shipping:
    it filtered deployed entries by `source | startswith($src)`, but the
    module deploys `./skills + "/<name>"`, which nix copies to its own store
    path per skill, so nothing in `deployedDetail` points inside the tree and
    the filter matched zero entries. The shipped test uses on-disk presence
    instead: a deployed name whose path EXISTS but is not a directory holding
    a SKILL.md is the drift, while a name with no path at all is a tool-owned
    skill (tatr) and is legitimate. Proven by sabotage - adding a `bogus`
    directory with no SKILL.md and listing it in `localSkills` now fails with
    "bogus is deployed but .../skills/bogus is not a skill directory", where
    the first attempt built green.

- [x] R3.3 (MINOR) flake/checks-skills.nix:5 - the header edit left a
  duplicated, self-contradicting sentence and a 118-column line.
  - Response: fixed; the stale clause is gone and the paragraph rewrapped.

- [x] R3.4 (MINOR) tasks/20260730-154955/TASK.md:108 - the third DoD proof's
  second conjunct is case-sensitive against `The three forms:`, so it is green
  on master and would stay green if the removed annotation forms were restored
  verbatim. Only the first conjunct does any work.
  - Response: fixed, now `grep -qi`. Verified falsifiable: the whole proof is
    green on the branch and red against master's `ledger.md`, so both
    conjuncts now carry weight.

- [x] R3.5 (MINOR) tasks/20260730-154955/TASK.md:256 - "the eleven rules"
  precedes a list of twelve, and REVIEW.md:306 says "lists 19 rules" where it
  lists 22.
  - Response: fixed both. Counted from the artifact rather than by hand:
    `comm -23` between master's and the branch's `--rules` output gives
    exactly twelve removed slugs, and `--rules | wc -l` gives 22.

- [x] R3.6 (NIT) tasks/20260730-154955/TASK.md:228 - the `### Evidence rig`
  block still presents `--self-test` and `--fixture` as this task's evidence,
  and a Note still cites `skills/fixtures/run.sh` as the authority.
  - Response: fixed. The heading is marked SUPERSEDED with a pointer to the
    addendum and a line saying both commands now exit 2; the Note is rewritten
    to say the claim it made is no longer backed by anything automated.

## Round 4

- REVIEWER: out-of-context
- VERDICT: APPROVE

R3.1 through R3.6 all confirmed FIXED, each re-derived rather than taken at
its word: the named diff command reproduces its digits exactly, the reverse
deployment assertion was read for vacuity and found live, proof 3 is green on
the branch and red on master with BOTH conjuncts independently red, and the
rule counts recount to 22 declared with exactly 12 removed.

The reviewer also confirmed the round-3 diff-stat exclusion is honest rather
than evasive: the command is quoted in full so any reader reproduces it, the
superseded full-scope figure is still named in the same block, and the stated
failure mode is real - the unscoped figure had already moved again by the time
round 3 was committed.

- [x] R4.1 (NIT) LESSONS.md:188 - the round-3 rewrite of
  `counts-come-from-the-diff` left one 103-column prose line mid-sentence,
  reintroducing the wrap defect R1.18 fixed. The file's other long lines are
  trailing task-id lists, which its own format example sanctions.
  - Response: fixed; the entry is rewrapped to under 80 columns and
    `tatr check --ledger` still passes. Ticked by the round's own reviewer
    standard: it is a NIT the reviewer already recommended APPROVE over, and
    the fix is a reflow with no behavior to re-verify.

Noted but not filed by the reviewer, and left as-is deliberately: the reverse
deployment loop reads `deployed-claude` only, though `deployed-agents` is
built from the same `localSkills` list, so the two lists cannot diverge in a
way this loop would miss.

Pending USER checks, which APPROVE does not resolve:

- DoD item 6 (`manual:`) - read `flow/SKILL.md` Finish, `lessons/SKILL.md`
  step 5 and `compound/SKILL.md` step 6 together and confirm one actor asks
  for the disposition, one tool records it, and compound does neither.
