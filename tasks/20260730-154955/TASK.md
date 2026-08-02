# Integrate guarded flow lifecycle and lesson decisions

- PRIORITY: 75
- TAGS: feature, skills, flow, lessons
- KIND: STORY
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE
- PARENT: 20260730-153122

## Story

As a flow user, I want the orchestrator and phase skills to use tatr's
transactional lifecycle and mandatory lesson decision gate, so prompt prose
cannot bypass plan, review, retro, close, or promotion requirements.

## Steps

- [x] Write the failing proofs FIRST: content fixtures under
      `skills/fixtures/content/` for the five names the Definition of Done
      gives (`flow_no_direct_state_edits` over `lessons/ledger.md` and
      `compound/SKILL.md`, `flow_transactional_lifecycle`, `flow_phase_resume`,
      `flow_lesson_decision_gate`, `flow_lesson_dispositions`), plus the
      `direct-state-edit` sabotage cases in `skills/fixtures/selftest.sh`.
      Several fixtures may share one `name:`; `--fixture <name>` runs them all.
      Confirm each is RED for the right reason before writing prose - and where
      one is GREEN on arrival because it guards behavior a previous task
      already landed, prove it can fail by sabotaging its target instead, and
      say which.
      Amended mid-work: the original text said "six content fixtures" while
      listing five names, and asserted every case would start red. Fifteen
      fixture files carry the five names. Four of the five were red on
      arrival; `flow_transactional_lifecycle` was green, and each of its four
      cases was proven falsifiable by sabotage (see the close-out).
      Amended again in round 2: the user deleted the fixture suite, so the
      artifacts this step produced no longer exist. It stays ticked because it
      WAS done and its findings drove the rule rewrite; the addendum records
      what went and what survived.
- [x] Add the `direct-state-edit` rule to `skills/check.sh`: for every
      `FLOW_FAMILY` skill's `*.md`, an imperative telling the agent to write
      `STATUS:`, `FLOW STEP:`, `PLAN STATUS:` or a ledger disposition
      annotation by hand is a finding. Per-file fixtures cannot see a marker
      edit added to a file no fixture names; the rule iterates the family, and
      `--self-test` proves it can fire (`tasks/20260730-154955/DECISION.md`).
      Amended in round 2: `--self-test` is gone with the fixtures, so nothing
      proves the rule can fire any more. The rule itself was rewritten after
      round 1 found it blind on 17 of 39 real sentences, and verified by hand
      over 33 probe sentences in both directions.
- [x] Rewrite `lessons/ledger.md` `## Count annotations` and
      `## The promotion order` onto the released grammar: the four dispositions
      PROMOTE, DEFER, RETIRE and ABSORBED, recorded by
      `tatr ledger -s <slug> -D <disposition>` with its `-t`/`-R`/`-T` payload,
      never by hand-editing the parens. State that the grammar is validated
      only under `## Pending promotions`, and that a DEFER records the count it
      was taken at, so a later bump past that count re-raises the decision.
      Currently 524 words against the 1000-word reference budget.
- [x] Rewrite `lessons/SKILL.md` step 5 as the disposition gate: list pending
      entries with `tatr ledger`, ask the user with the platform's user-input
      mechanism when it has one and plain prose otherwise, record the answer
      through `tatr ledger`, and route PROMOTE to a normal planned tatr task
      that takes the usual out-of-context review. 555 of 800 words used.
- [x] Rewrite `compound/SKILL.md` step 6 to record and count only: counts stay
      bare, the entry moves to `## Pending promotions` at three, and compound
      never writes a disposition, promotes into a tool, template, AGENTS.md or
      skill, nor asks for the decision - that is Finish's gate. 609 of 800.
- [x] Update `flow/SKILL.md` Finish so the pending-promotion disposition gate
      is named before `lessons` is invoked. The router body is 483 of its 500
      words, so trade words out rather than appending; the detail belongs in
      `lessons/ledger.md`, which Finish already reaches through `lessons`.
- [x] Update `flow/resume.md` to derive the next phase from
      `tatr show`/`tatr context <id> --phase resume` structured state and to
      request only that phase's packet, keeping the FLOW STEP table as the
      step-to-skill dispatch it already is. Confirm no step tells a session to
      edit a marker back into place by hand.
- [x] Repair the two live `tatr check --ledger LESSONS.md` findings in
      `LESSONS.md`: reflow the `counts-come-from-the-diff` entry so its count
      group closes its paren (`bad-disposition`), then obtain and record the
      user's disposition for it and for `dod-grep-excludes-task-records` (x6)
      through `tatr ledger` (`promotion-awaiting-decision`). Ask through the
      same gate this task builds; do not invent the answers.
- [x] Update `AGENTS.md` (`## Agent workflow`, `## Check suite`) and every
      affected skill cross-reference, then run the full suite: `check.sh`,
      `tatr check --ledger LESSONS.md`, `nix flake check`, `sprout-test.sh`.
      Amended in round 2: `check.sh --self-test` dropped from the suite (it no
      longer exists), and `nix flake check` runs BARE rather than `--no-build`,
      because AGENTS.md records that `--no-build` proves nothing about the
      checks' assertions. The cross-reference sweep also covered
      `flake/checks-skills.nix`, `home/modules/agents/default.nix` and
      `skills/README.md`, which all described the removed fixtures.

## Definition of Done

Rewritten mid-work: the user removed the fixture suite (see `## Round 2` in
REVIEW.md), so the five `test:` proofs that named fixture cases no longer have
a runner. Each is restated as the grep or command that still settles it, or as
a `manual:` item where only a reader can.

- The `direct-state-edit` rule is live over the whole flow family and the gate
  is clean (cmd: `bash home/modules/agents/skills/check.sh`).
- No flow-family skill orders a lifecycle marker or a ledger disposition
  written by hand. This is what `direct-state-edit` enforces, so the proof is
  that the rule EXISTS and is declared, not just that the tree is quiet
  (cmd: `bash home/modules/agents/skills/check.sh --rules | grep -x
  direct-state-edit`).
- `lessons/ledger.md` documents `tatr ledger` as the disposition's only writer
  and no longer documents the hand-composed annotation forms
  (cmd: `grep -q 'tatr ledger -s' home/modules/agents/skills/lessons/ledger.md
  && ! grep -qi 'the three forms'
  home/modules/agents/skills/lessons/ledger.md`).
- A threshold lesson blocks the finish gate until the user's disposition is
  recorded, and both live entries carry one
  (cmd: `tatr check --ledger LESSONS.md`).
- PROMOTE creates or references a real task; a dangling one is a finding
  (cmd: `tatr ledger`, whose two rows must name existing task IDs, which
  `tatr check --ledger` verifies as `dangling-promotion-task`).
- The three files that share the disposition gate agree on who does what
  (manual: read `flow/SKILL.md` Finish, `lessons/SKILL.md` step 5 and
  `compound/SKILL.md` step 6 together and confirm one actor asks, one tool
  records, and compound does neither).
- Repository conformance and flake evaluation pass
  (cmd: `tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- Parent Epic: 20260730-153122.
- Depends on tatr: 20260730-154657, 20260730-154745, 20260730-154756.
- Depends on nix.dotfiles: 20260730-142533.
- Base-branch proof state at plan time: `check.sh` clean (9 skills),
  `nix flake check --no-build` "all checks passed", and
  `tatr check --ledger LESSONS.md` RED with exactly `bad-disposition`
  (counts-come-from-the-diff) and `promotion-awaiting-decision`
  (dod-grep-excludes-task-records). The last proof is red BEFORE the work and
  green after, which is what makes it a criterion rather than decoration.
- The lockfile already moved tatr to `cd8b33d` (the released `tatr ledger`);
  that staged `flake.lock` edit belongs to this task's commit.
- No skill currently instructs a hand edit of STATUS, FLOW STEP or PLAN
  STATUS - `tatr flow` is already the only writer after 20260730-142533. The
  live gap is the ledger disposition text in `lessons/ledger.md`, which still
  documents three hand-written annotation forms. The rest of Step 1 is a
  regression guard, not a migration.
- `tatr` exposes no `plan`, `start`, `advance`, `review-loop` or `close`
  verbs; the released surface is `tatr flow --to <step>` plus `claim`,
  `release`, `frontier`, `context`, `proofs`, `scaffold` and `ledger`. The
  Story's verb names are aspirational and the Steps use the real ones.
- Assumption to double-check: the epic's `## Manual Acceptance` owns whether a
  live agent OBEYS the gate. Written when the fixtures existed and they were
  structural proofs over the skill texts; round 2 deleted them, so nothing
  automated makes that claim any more.

## Close-out

Diff stats are recorded in the round-2 addendum at the end of this file, taken
after the last edit rather than before it. The two figures written here during
round 1 - 496, then 593 - were both read before the block that quotes them was
finished, which is `counts-come-from-the-diff` recurring twice inside the
close-out that narrates it. Round 1's reviewer caught the second; the lesson
is bumped to x4 and promoted to 20260731-094524.

### What changed and why

The Story asked for a migration off hand-edited flow markers. The code did not
need one: `tatr flow` has been the only writer of `STATUS`, `FLOW STEP` and
`PLAN STATUS` since 20260730-142533, and the grep sweep at plan time found no
skill instructing otherwise. The one live violation was `lessons/ledger.md`,
which still documented three hand-composed count annotations. So the work
split into a real migration (the ledger grammar) and a regression guard (the
markers).

- `lessons/ledger.md` `## Count annotations` became `## Recording a
  disposition`: the four answers, `tatr ledger -s <slug> -D <disposition>`
  with its `-t`/`-R`/`-T` payload as the only writer, Pending-only validation,
  the count-based DEFER re-raise, and the four `tatr check --ledger` findings.
  `## Shrink-on-absorb` and `## Retirement` were rewritten onto the same verb.
  524 -> 842 words, inside the 1000-word reference budget.
- `lessons/SKILL.md` step 5 became the disposition gate: list with
  `tatr ledger`, ask via the platform's user-input mechanism, record through
  the tool, route a PROMOTE to a planned task that takes the normal
  out-of-context review. `## Output` now reports dispositions rather than
  "awaiting" ones.
- `compound/SKILL.md` step 6 records and counts only, and explicitly does not
  ask for the decision - Finish owns it, so a multi-task flow asks once at the
  end instead of once per retro.
- `flow/SKILL.md` Finish names the gate. The router was at 483/500 words, so
  three unrelated phrases were tightened to pay for it rather than appending.
- `flow/resume.md` now derives the next phase from `tatr show`'s structured
  state and asks for only that phase's packet.
- `check.sh` gained the `direct-state-edit` rule over `FLOW_FAMILY`, with five
  sabotage cases. `fixtures/run.sh` content matching now normalizes whitespace.
- `LESSONS.md`: the malformed `counts-come-from-the-diff` count group was
  reflowed, and both pending promotions were settled by the user as PROMOTE,
  recorded through `tatr ledger` against two new tasks (20260731-094524,
  20260731-094537).

### Alternatives considered

`DECISION.md` records the main fork: content fixtures alone (blind to a file
no fixture names), a rule alone (not singly runnable, cannot assert positive
vocabulary), or a fifth fixture kind with a glob (new machinery for one
criterion). Both mechanisms shipped, each doing what only it can.

The `direct-state-edit` rule deliberately does NOT treat a bare `STATUS:` as a
marker: `DECISION.md` and `SPIKE.md` carry their own `- STATUS:` field, and
matching it flagged `plan/decision.md`'s legitimate supersede instructions.
Only the flow lifecycle's own values (OPEN, IN_PROGRESS, CLOSED) count.

### Difficulties and how they were diagnosed

The `flow_transactional_lifecycle` fixture was GREEN the moment it was
written, because it guards behavior 20260730-142533 already delivered. Rather
than tick a proof that had never failed, each of its four cases was sabotaged
in a scratch copy. Three fired; the fourth did not, and the reason was
`line-breaks-are-load-bearing`: the phrase "do not hand-edit TASK.md around
it" WRAPS in `work/SKILL.md`, so the `sed` never matched and the sabotage
silently no-opped. That is the same failure mode the ledger already records,
and it had been fixed only for `pointer_condition`, not for content matching.
Fixing the matcher (whitespace normalization in `run.sh`) was therefore part
of the work, not a detour; a `perl -0p` wrap-aware sabotage then fired.

`tatr context <id> --phase PLANNING` was rejected: the phase vocabulary is
lowercase (`understand`, `plan`, `work`, ...), not the FLOW STEP names.

Moving the plan artifacts into the sprout needed care: the worktree branches
from committed HEAD, so the approved TASK.md, DECISION.md and the `flake.lock`
bump were copied over and the main checkout restored, per
`sprout-inherits-committed-head`.

### Evidence rig (SUPERSEDED - see the round 2 addendum)

The two commands below no longer exist: `--self-test` and `--fixture` were
removed with the fixture suite in round 2, and both now exit 2. The results
were true when recorded and are kept as history, not as instructions.

- `bash check.sh` - clean, 9 skills, 179 description words.
- `bash check.sh --self-test` - 44 sabotage cases, 33 of 33 rules covered.
- `check.sh --fixture <name>` for all five DoD names - ok (2, 4, 2, 2 and 5
  cases respectively).
- `tatr check` and `tatr check --ledger LESSONS.md` - exit 0 (the latter was
  RED on the base branch with the two findings this task fixed).
- `bash home/modules/scripts/sprout-test.sh` - passed 14, failed 0.
- `nix flake check` BARE - "all checks passed"; `--no-build` also 0. AGENTS.md
  warns `--no-build` proves nothing about the assertions, so the bare form is
  the one that actually ran `skills-conformance`.

### Self-reflection

The plan's grep sweep is what kept this honest: it turned a Story that read as
a large migration into a small one plus a guard, and that reframing is in the
Notes rather than discovered mid-build. Worth repeating.

What to do differently: the falsifiability check should have been part of
writing each fixture, not a step taken after noticing one was green. Writing a
proof and immediately sabotaging its target is cheap; assuming "it is red now,
so it can fail" only works for the ones that happen to start red.

## Round 2 addendum: the fixture suite was removed

Mid-review the user removed `home/modules/agents/skills/fixtures/` outright,
with `--fixture` and `--self-test`, on the grounds that it ran too slowly and
was hard to iterate on. That is a scope decision, and it reshaped this task.

What went with it: the four fixture kinds, the sabotage harness, the twelve
rules only the fixture runner emitted (`bad-fixture`, `not-loadable`,
`condition-misses-branch`, `leaks-on-unrelated-branch`, `wrong-policy`,
`description-misses-trigger`, `codex-parity`, `no-disclosure-fixture`,
`missing-output-limit`, `missing-output-element`, `missing-content-element`,
`forbidden-content-element`), and the `expect_clean` negative cases added
earlier in the same review round.

What survived, and why it was worth building anyway: the `direct-state-edit`
rewrite. Round 1's three lanes found the first version blind on 17 of 39 real
marker sentences while passing all five of its own sabotages, plus a regex
precedence bug and false positives on ordinary descriptive prose. The rewrite
is one awk pass with clause segmentation, role-based tool attribution and
imperative-mood agency detection, verified across 33 probe sentences in both
directions. None of that depended on the harness.

Two things were added back deliberately:

- `missing-output-contract` as a real check.sh rule. A missing `## Output`
  section counts zero words, so the budget alone waved it through - and it
  immediately found that `sprout/SKILL.md` has none. `sprout` is a worktree
  CLI rather than a dispatched phase, so it is scoped out of the rule.
- `stale-rule-inventory`, answering this round's own R2.1. Without the
  self-test, `RULES` was an unverified claim; the gate now checks in both
  directions that every declared slug is reported and every reported slug is
  declared. It is a spelling check, not a falsifiability one, and the file
  says so.

The honest cost: nothing now proves a check.sh rule can FAIL. The gate is
~2.7s instead of ~7.0s and every rule is structural. Whether a reference still
states the rule it carries is a review question now.

The Definition of Done above was rewritten for the same reason - five `test:`
proofs named fixture cases with no runner left.

### Final verification

- `bash check.sh` - clean, 9 skills, 22 rules, 179 description words.
- `check.sh --self-test` - exits 2, "unknown argument", so a stale invocation
  fails loudly rather than reading as a pass.
- `stale-rule-inventory` proven both ways by sabotage in a scratch copy.
- `tatr check` and `tatr check --ledger LESSONS.md` - exit 0.
- `bash home/modules/scripts/sprout-test.sh` - passed 14, failed 0.
- `nix flake check` BARE - all checks passed.
- One `manual:` DoD item is open and belongs to the user.

### Diff stats

72 files changed, 367 insertions(+), 897 deletions(-)
(`git diff --shortstat master...HEAD -- . ':(exclude)tasks'`).

The exclusion is the point, not a dodge. A figure counting `tasks/` goes stale
the instant it is written, because appending the very review round that checks
it adds lines to the diff it measures - which is exactly what happened when
the corrected 78/1188/929 was invalidated by committing round 3. Scoping to
the code and docs gives a number that survives being recorded.

Three earlier figures here were wrong: 496 and 593 were read before the block
quoting them was finished, and 462/1035 came from `git diff --cached
--shortstat`, which measures the INDEX against the PREVIOUS COMMIT rather than
the branch against its base - a different question with a plausible-looking
answer. Rounds 1 and 3 caught them. `counts-come-from-the-diff` is now x5.
