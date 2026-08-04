# Add conditional parallel planning and review lanes

- PRIORITY: 65
- TAGS: feature, skills, flow, parallel, review
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE
- PARENT: 20260730-153122

## Story

As a flow user, I want bounded independent planning and review lanes only when
risk or uncertainty warrants them, so difficult work gains fresh perspectives
without paying parallel context cost on ordinary tasks.

## Steps

All paths are relative to `home/modules/agents/skills/`.

- [x] Confirm the two mechanisms this plan rests on before writing prose
      against them. First, that `check.sh --fixture <case>` runs EVERY case
      whose `name:` matches, across all four kinds (`fixtures/run.sh` comments
      say so; `fx_skip` plus the `fixtures_matched` counter is the code to
      read) - one DoD proof below deliberately spans many cases under one
      name (`parallel_lane_selection` ended at 15). Second, that a disclosure `when:` list is split on WHITESPACE into
      independent substring tests (`for w in $when` in `run_fixtures`), so each
      token must be unique to the pointer it selects. Record both as one line
      each in Notes; if either is false, stop and re-plan the proofs.
- [x] Write `tasks/20260730-154958/DECISION.md` (`tatr scaffold` it): lane
      behavior is proved STRUCTURALLY over the skill texts, as
      20260730-142533 and 20260730-142540 already decided for this suite, and
      each phase's lanes reference states its OWN resource rule rather than one
      shared file, because a reference is per-skill and one level deep and a
      verbatim shared paragraph trips `duplicated-paragraph`. Name the rejected
      alternatives (a lane-executing harness; a single shared `lanes.md`) and
      the constraint that killed each.
- [x] Write the failing fixtures FIRST and confirm each is red for the right
      reason. Under `fixtures/content/`: `parallel_lane_selection` (one case
      per lanes file), `parallel_plan_isolation`, `parallel_plan_synthesis`,
      `parallel_review_aggregation`, and `parallel_resource_guards` (one case
      per lanes file). Under `fixtures/disclosure/`: one `loads: lanes.md` case
      per trigger token (`plan-lanes-<token>.fixture`,
      `review-lanes-<token>.fixture`) - the first draft used one case per skill
      listing every token, which a `when:` list cannot assert because it is an
      OR; see the Close-out. That satisfies `no-disclosure-fixture`. Plus
      `plan-ordinary.fixture` and `review-ordinary.fixture` whose `when:` names
      ordinary/routine work and which `forbid` `lanes.md` - that pair guards the
      words: it fails if a condition is ever reworded to name ordinary or
      routine work, and it cannot see a condition widened in other words
      (R1.2). Name every disclosure and
      content case that backs a single criterion with the SAME `name:` as that
      criterion's proof. Write the emptiest case first: a `requires:` list is narrowed to
      the one load-bearing token per rule, never a list of alternatives any one
      of which satisfies it.
- [x] Verify no new `fail` slug is introduced (the cases reuse
      `missing-content-element`, `not-loadable`, `condition-misses-branch`,
      `leaks-on-unrelated-branch`), so `check.sh`'s `RULES` array and
      `fixtures/selftest.sh` are unchanged. If a new slug does turn out to be
      needed, it gets a sabotage case in `selftest.sh` in the same step.
- [x] Write `plan/lanes.md` (at or under 1000 words): the deterministic
      selection rule (default ONE planner; open lanes only for a load-bearing
      fork, independent domains, an Epic too large for one context, or an
      explicit request); the identical read-only context packet each lane
      receives, built from `tatr context <id> --phase plan` and carrying no
      other lane's conclusions and no implementing narrative; the three lane
      roles (minimal end-to-end, deep interface, migration and risk); one
      bounded output cap per lane stated as a number; the synthesis rule that
      ONE plan and ONE `DECISION.md` persist while candidate scratch is
      discarded and only a concise rejected-alternative rationale survives; and
      the planning-phase resource rule (lanes are read-only and share the
      checkout, they never sprout).
- [x] Write `review/lanes.md` (at or under 1000 words): the selection rule
      (default one out-of-context reviewer; open lanes only for
      security/auth, secrets, persistence or migrations, concurrency, public
      APIs, shared infrastructure, or broad contract changes, and only the
      lanes that apply); the three lane roles (behavior and proofs,
      correctness/security/concurrency, design/standards/docs); the bounded
      per-lane response, findings only, no writes and no commits; the
      aggregation contract - the primary reviewer re-verifies each lane
      finding, deduplicates, assigns the canonical severity, and writes ONE
      numbered round with ONE verdict in `REVIEW.md`, recording lanes on the
      round's `- REVIEWER:` line; and the review-phase resource rule (lanes
      read one worktree read-only; anything that mutates build output is run
      once by the primary, never concurrently).
- [x] Add the `## Load on demand` pointer in `plan/SKILL.md` and
      `review/SKILL.md`, each condition naming its branch in words on the
      arrow's own line, with no token that also appears in a sibling pointer's
      condition or in the ordinary-work fixtures' `when:` lists. Both bodies
      stay at or under 800 words.
- [x] Correct `review/rounds.md`: "the out-of-context reviewer is the suite's
      only subagent" is now false. Restate it as the DEFAULT single reviewer,
      point at the lanes reference in prose WITHOUT an arrow-plus-backtick
      pointer (that would trip `reference-too-deep`), and keep the existing
      handoff bounds as the per-lane bounds so the two files do not restate the
      same paragraph.
- [x] Sweep the doc surface in the same task: `README.md` gains the two new
      references and the lane rules' location; the repo `AGENTS.md` gets the
      lane policy only if it contradicts something already written there. Grep
      `--exclude-dir=tasks` for prose still claiming a single reviewer or a
      single planner, and exclude comment lines from the absence grep.
- [x] Run the full gate: `bash home/modules/agents/skills/check.sh`,
      `bash home/modules/agents/skills/check.sh --self-test`,
      `tatr check --ledger LESSONS.md`, and `nix flake check`.

## Definition of Done

- Ordinary work reaches one lane and high-risk work reaches only the
  applicable lanes: both lanes files state the default-one rule and their own
  trigger list, every trigger word is present in the pointer condition that
  routes it, and the pointer condition never names ordinary or routine work
  (which is a word guard, not a proof that no other wording could reach it)
  (cmd: `bash home/modules/agents/skills/check.sh --fixture parallel_lane_selection`).
- Planning candidates receive an identical read-only context packet without
  each other's conclusions, and each lane's output is capped
  (cmd: `bash home/modules/agents/skills/check.sh --fixture parallel_plan_isolation`).
- Only the chosen plan and a concise rejected-alternative rationale persist;
  candidate scratch is discarded
  (cmd: `bash home/modules/agents/skills/check.sh --fixture parallel_plan_synthesis`).
- Parallel review produces one deduplicated severity-ranked round and one
  verdict after the primary reviewer re-verifies
  (cmd: `bash home/modules/agents/skills/check.sh --fixture parallel_review_aggregation`).
- Read-only lanes share a checkout and never sprout, writing stays in the
  task's own sprout worktree, and build-output-mutating checks are serialized
  (cmd: `bash home/modules/agents/skills/check.sh --fixture parallel_resource_guards`).
- The suite's own gate still passes, including its self-test
  (cmd: `bash home/modules/agents/skills/check.sh --self-test && bash home/modules/agents/skills/check.sh`).
- Repository conformance and flake evaluation pass
  (cmd: `tatr check --ledger LESSONS.md && nix flake check --no-build`).
- On a real high-risk review the lanes stay inside their stated caps and the
  primary's round reads as one deduplicated review rather than three
  concatenated ones. The fixtures prove the skill texts SAY this; no
  deterministic check can observe a live agent obeying it
  (manual: the user runs one lane-selecting review and reads the round).

## Notes

- Parent Epic: 20260730-153122.
- Depends on tatr: 20260730-154740, 20260730-154745.
- Depends on nix.dotfiles: 20260730-142533.
- Baseline at plan time (2026-07-31, master fcbcba2): `check.sh` clean
  (9 skills, 179 flow-family description words), `tatr check --ledger
  LESSONS.md` clean, `nix flake check --no-build` clean. Every `cmd:` proof
  above is therefore red only because its fixture does not exist yet.
- Budget headroom measured on master: `plan/SKILL.md` body 619 words and
  `review/SKILL.md` body 622 of the 800-word phase budget; flow-family
  descriptions 179 of 200, and no description changes are planned.
- `check.sh` has no rule that a reference stays under a lane-specific cap;
  the 1000-word `reference-budget` is the only bound on the two new files.
- The `duplicated-paragraph` rule (12+ verbatim words in two files) is the
  live hazard here: `plan/lanes.md`, `review/lanes.md` and `review/rounds.md`
  all describe bounded independent context. Each states its own phase's rule
  in its own words.
- Mechanism confirmed (Step 1a): `check.sh --fixture <name>` runs EVERY case
  with that `name:`, across kinds. Measured by duplicating an existing case and
  seeing `fixture spike_mode_router: ok (2 case(s))`, then `(1 case(s))` after
  removing it. `parallel_lane_selection` now reports 15 cases.
- Mechanism confirmed (Step 1b): a disclosure `when:` is word-split
  (`for w in $when`, unquoted), so each token is an independent substring test
  against the pointer's condition - and the condition is only the text on the
  ARROW's own line. A wrapped condition silently loses its first half; that
  bit the first draft of plan's pointer and is why both new pointers are one
  long line.

## Close-out

What changed: two conditional references, `plan/lanes.md` (selection rule,
identical read-only context packet, three planning angles, a 400-word lane cap,
synthesis into one plan plus one DECISION.md) and `review/lanes.md` (selection
rule, three review angles, the same 400-word cap, and the primary reviewer's
re-verify/deduplicate/one-round/one-verdict contract). Each gained a
`## Load on demand` pointer in its skill, plus thirteen disclosure and seven
content fixture cases. `review/rounds.md` no longer claims the round-1 reviewer
is the suite's only subagent. `README.md` records where the lane rules live and
why they are two files.

Why: `tasks/20260730-154958/DECISION.md`. Lane behavior is proved structurally
over the skill texts, as 20260730-142533 and 20260730-142540 already decided
for this suite; the live behavior is a `manual:` item, not a self-tick.

Difficulties, and how they were diagnosed:

- The first `lanes.md` pointer in `plan/SKILL.md` wrapped onto two lines, which
  put "irreversible" and "independent" on the line ABOVE the arrow.
  `pointer_condition` reads only the arrow's line, so the disclosure case would
  have gone red for a reason unrelated to the rule. Caught by reading the
  extractor rather than by the gate, and fixed by keeping each condition on one
  line.
- Two content assertions failed on their first run - `rejected alternative` and
  `share the checkout` - because the prose wrapped BETWEEN the words. Content
  matching is a substring test over raw text including newlines. Fixed by
  reflowing the two sentences, not by weakening the assertions.
- The first version of the disclosure cases was unfalsifiable. Each listed all
  of a pointer's trigger words in one `when:` (`secrets migrations concurrency
  contract`), and `run_fixtures` accepts the branch when ANY token matches. The
  A/B run proved it: deleting `secrets` from review's pointer condition left
  the case GREEN. Split into one case per trigger token - four for plan, seven
  for review - after which deleting `secrets`, and separately `independent`,
  each turned the proof red on its own token. This is the ledger's
  `narrow-the-guard-to-the-word` in a new place: the `when:` list, not the
  `requires:` list.
- Each new assertion was then A/B'd against the artifact it guards: `never
  sprout`, `re-verifies` and `discard` were each removed in turn and each
  turned its own proof red, and adding `ordinary work` to plan's condition
  tripped `leaks-on-unrelated-branch`. Every sabotage was run against a
  committed tree and reverted with `git checkout HEAD --`.

Self-reflection: writing the eleven fixture cases before any prose worked
exactly as the ledger promises - every one was red for an honest reason
(`not-loadable`, `no such file`) before the files existed, and the two
line-wrap misses were caught by the assertions rather than by a later reader.
The reusable lesson is narrower than "write the test first": an assertion that
matches a multi-word phrase against hard-wrapped prose is testing the line
breaks too, so either the phrase must be short enough not to wrap or the prose
must be written to keep it whole.
