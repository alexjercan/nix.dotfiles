# Add conditional parallel planning and review lanes

- STATUS: OPEN
- PRIORITY: 65
- TAGS: feature, skills, flow, parallel, review
- KIND: STORY
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED
- PARENT: 20260730-153122

## Story

As a flow user, I want bounded independent planning and review lanes only when
risk or uncertainty warrants them, so difficult work gains fresh perspectives
without paying parallel context cost on ordinary tasks.

## Steps

All paths are relative to `home/modules/agents/skills/`.

- [ ] Confirm the two mechanisms this plan rests on before writing prose
      against them. First, that `check.sh --fixture <case>` runs EVERY case
      whose `name:` matches, across all four kinds (`fixtures/run.sh` comments
      say so; `fx_skip` plus the `fixtures_matched` counter is the code to
      read) - one DoD proof below deliberately spans four cases under one
      name. Second, that a disclosure `when:` list is split on WHITESPACE into
      independent substring tests (`for w in $when` in `run_fixtures`), so each
      token must be unique to the pointer it selects. Record both as one line
      each in Notes; if either is false, stop and re-plan the proofs.
- [ ] Write `tasks/20260730-154958/DECISION.md` (`tatr scaffold` it): lane
      behavior is proved STRUCTURALLY over the skill texts, as
      20260730-142533 and 20260730-142540 already decided for this suite, and
      each phase's lanes reference states its OWN resource rule rather than one
      shared file, because a reference is per-skill and one level deep and a
      verbatim shared paragraph trips `duplicated-paragraph`. Name the rejected
      alternatives (a lane-executing harness; a single shared `lanes.md`) and
      the constraint that killed each.
- [ ] Write the failing fixtures FIRST and confirm each is red for the right
      reason. Under `fixtures/content/`: `parallel_lane_selection` (one case
      per lanes file), `parallel_plan_isolation`, `parallel_plan_synthesis`,
      `parallel_review_aggregation`, and `parallel_resource_guards` (one case
      per lanes file). Under `fixtures/disclosure/`: `plan-lanes.fixture` and
      `review-lanes.fixture` (`loads: lanes.md`, satisfying
      `no-disclosure-fixture`), plus `plan-ordinary.fixture` and
      `review-ordinary.fixture` whose `when:` names ordinary/routine work and
      which `forbid` `lanes.md` - that pair is what proves ordinary work cannot
      reach the lanes. Name every one of these six disclosure/content cases
      that back a single criterion with the SAME `name:` as that criterion's
      proof. Write the emptiest case first: a `requires:` list is narrowed to
      the one load-bearing token per rule, never a list of alternatives any one
      of which satisfies it.
- [ ] Verify no new `fail` slug is introduced (the cases reuse
      `missing-content-element`, `not-loadable`, `condition-misses-branch`,
      `leaks-on-unrelated-branch`), so `check.sh`'s `RULES` array and
      `fixtures/selftest.sh` are unchanged. If a new slug does turn out to be
      needed, it gets a sabotage case in `selftest.sh` in the same step.
- [ ] Write `plan/lanes.md` (at or under 1000 words): the deterministic
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
- [ ] Write `review/lanes.md` (at or under 1000 words): the selection rule
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
- [ ] Add the `## Load on demand` pointer in `plan/SKILL.md` and
      `review/SKILL.md`, each condition naming its branch in words on the
      arrow's own line, with no token that also appears in a sibling pointer's
      condition or in the ordinary-work fixtures' `when:` lists. Both bodies
      stay at or under 800 words.
- [ ] Correct `review/rounds.md`: "the out-of-context reviewer is the suite's
      only subagent" is now false. Restate it as the DEFAULT single reviewer,
      point at the lanes reference in prose WITHOUT an arrow-plus-backtick
      pointer (that would trip `reference-too-deep`), and keep the existing
      handoff bounds as the per-lane bounds so the two files do not restate the
      same paragraph.
- [ ] Sweep the doc surface in the same task: `README.md` gains the two new
      references and the lane rules' location; the repo `AGENTS.md` gets the
      lane policy only if it contradicts something already written there. Grep
      `--exclude-dir=tasks` for prose still claiming a single reviewer or a
      single planner, and exclude comment lines from the absence grep.
- [ ] Run the full gate: `bash home/modules/agents/skills/check.sh`,
      `bash home/modules/agents/skills/check.sh --self-test`,
      `tatr check --ledger LESSONS.md`, and `nix flake check`.

## Definition of Done

- Ordinary work reaches one lane and high-risk work reaches only the
  applicable lanes: both lanes files state the default-one rule and their own
  trigger list, and the ordinary-work disclosure cases prove the `lanes.md`
  pointer condition does not fire on ordinary work
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
- Read-only lanes share a checkout, writers get distinct sprout worktrees, and
  build-output-mutating checks are serialized
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
