# Review: Add tatr-native wayfinding, web research, and retained prototypes

- TASK: 20260730-142540
- BRANCH: feature/wayfinding-research-prototypes

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MINOR) home/modules/agents/skills/spike/SKILL.md:106 - the Step
  requires the `## Load on demand` conditions to name all four mode words, but
  the research condition read "external or current facts settle it, or mixed
  evidence" and never contained the word `research`; only the target filename
  did, and `spike-research.fixture` passed on `external`, so nothing guarded
  the clause. Reword the condition to lead with "research settles it".
  - Response: reworded. The reviewer then noted the word was present but still
    unguarded, since `research` also appears in the target filename. Fixed at
    the mechanism instead: `spike-research.fixture` now declares
    `when: research` alone, and `pointer_condition` strips everything from the
    arrow onward, so the filename cannot satisfy it. Deleting "research
    settles it" now fails `condition-misses-branch`. The vocabulary the
    narrowed `when:` no longer covers (external, current facts, logic, UI
    prototype, mixed evidence) moved to a new `spike_mode_router` content case.
- [x] R1.2 (MINOR) home/modules/agents/skills/fixtures/run.sh:159 - a
  `content/` case with neither `requires:` nor `forbids:` passed and printed
  `fixture <name>: ok`. Since content cases back DoD proofs, a vacuous one is
  a green proof that asserts nothing. Fail `bad-fixture` when both lists are
  empty.
  - Response: guard added after the file resolution. Verified against a case
    omitting the keys and one with empty values; both now exit 1.
- [x] R1.3 (MINOR) home/modules/agents/skills/check.sh:127 - `section_of`
  treated every `^## ` line as a heading, including ones inside fenced code
  blocks, so a content case could be satisfied by an illustrative template
  rather than a normative rule. Make it fence-aware.
  - Response: `section_of` now toggles a fence flag and ignores `## ` inside
    one. The probe that previously matched `epic.md`'s markdown template
    (`section: Fog`) now reports `bad-fixture: no '## Fog' section`. Fence
    lines inside a real section are still printed, so section text is
    unchanged for every existing case.
- [x] R1.4 (MINOR) AGENTS.md:51 - the Check suite entry documented
  `--self-test` and `--rules` but not the `--fixture <case>` form that every
  DoD proof on this task uses. Add it.
  - Response: added, and the following sentence narrowed to "runs the bare and
    `--self-test` forms", which is what `flake/checks-skills.nix` does.
- [x] R1.5 (NIT) AGENTS.md:23 - "Examples and prototypes: none retained."
  contradicts the resolution order `spike/prototype.md` teaches, whose default
  is `tasks/<id>/prototype/`.
  - Response: reworded to "none in-tree; a spike's exploratory prototype is
    retained under `tasks/<id>/prototype/`".
- [x] R1.6 (NIT) tasks/20260730-142540/TASK.md:134 - the close-out's diff
  numbers were taken before the close-out block itself was appended.
  - Response: corrected, but the first correction mixed two snapshots and came
    back as R2.1. See there.

Verification the reviewer performed: `nix flake check` bare and `--no-build`,
`check.sh`, `--self-test`, `sprout-test.sh`, `tatr check --ledger LESSONS.md`,
and all seven `cmd:` proofs verbatim. It mutation-tested all five DoD fixtures
in scratch copies - each went red naming exactly the dropped element - and
independently reproduced the close-out's claim that `tatr check` tolerates
`## Fog` and `## Out of Scope` on an Epic.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

- [x] R2.1 (NIT) tasks/20260730-142540/TASK.md:134 - the corrected line read
  "20 files changed, 579 insertions, 99 deletions", mixing the post-fix file
  count with the pre-fix line counts; no diff produces that triple. State the
  numbers a real diff reports.
  - Response: the close-out now cites `git diff ecd57cf..0343f8b --shortstat`
    by commit - 20 files, 600 insertions, 102 deletions - and says explicitly
    that the round-2 fix and the records committed after it are outside that
    number, so the figure stops going stale with every later commit.

Re-verification for round 2: R1.1 through R1.5 confirmed RESOLVED against the
new diff, R1.6 reopened as R2.1. No existing content fixture changed behavior
under the fence-aware `section_of`; all five still pass and resolve the same
sections. Canonical checks re-run clean: the gate (9 skills, 179 flow-family
description words), `--self-test` (39 cases, 32 of 32 rules), `sprout-test.sh`
14/14, `tatr check --ledger LESSONS.md`, `nix flake check`, and every `cmd:`
proof.

Pending USER checks, not resolved by this APPROVE:

- The task's `manual:` DoD item - run one real spike that retains a prototype
  and confirm the prototype still runs from its recorded command after the
  spike closes. Now carried on the parent Epic 20260730-153122's
  `## Manual Acceptance` list, per tasks/20260730-142540/DECISION.md.
