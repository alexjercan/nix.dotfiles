# Adopt flow v2: move ledger to root, create repo AGENTS.md flow pointer

- STATUS: CLOSED
- PRIORITY: 85
- TAGS: chore, process

## Story

As a repo in the flow ecosystem, I want the v2 /flow conventions in place -
root LESSONS.md ledger, clean tatr check, AGENTS.md pointing at /flow - so
development here compounds the same way as everywhere else. Part of the
six-repo adoption goal (umbrella: nix.dotfiles tasks/20260720-171807).

## Steps

- [x] Ledger at the root: move docs/LESSONS.md to LESSONS.md (git mv) - or
      create it from the lessons-skill format if the repo has none - then
      run the doc-surface sweep for every reference to the old path
      (AGENTS.md, README, scripts, CI guards, wiki pages) and update them.
      Bring the ledger to format: bare counts until promotion, a
      "## Pending promotions (3+ occurrences, user decides)" section;
      move unpromoted (x3)+ entries there; keep existing PROMOTED/absorbed
      annotations as they are.
      (As executed: the ledger was already in format - bare counts, a
      Pending promotions section holding the one unpromoted (x3) entry,
      PROMOTED annotation kept - so only the git mv was needed there. The
      old-path references lived not in AGENTS.md/README/scripts/CI but in
      the flow-family skill sources this repo owns; see close-out.)
- [x] Fix tatr check findings best-effort, assuming recorded work was done
      properly where the record supports it:
      - closed-unchecked: tick Steps boxes whose close-out notes or landed
        commits evidence the work shipped; genuinely unshipped steps stay
        unticked and go on the residue list;
      - closed-not-approved: normalize nonstandard-but-approving verdict
        lines (e.g. "Verdict: APPROVE", "**APPROVE**") to
        "- VERDICT: APPROVE"; a review that really ended unapproved goes on
        the residue list untouched;
      - bad-severity: map to the nearest of BLOCKER/MAJOR/MINOR/NIT
        (LOW -> MINOR, NOTE/INFO/OBSERVATION -> NIT, FIXED -> the severity
        it had, keeping any "fixed in-review" note in the text), recording
        the mapping in the close-out.
      (As executed: tatr check was already clean - exit 0, no findings -
      so no ticks, verdict normalizations or severity mappings were
      needed. Residue list: empty.)
- [x] AGENTS.md: add or refresh a "Development flow" section stating: /flow
      drives development here (plan/work/review/compound via tatr tasks,
      sprout worktrees, out-of-context round-1 reviews, DoD proofs with
      test:/cmd:/manual: notation); LESSONS.md at the repo root is the
      lessons ledger, read before starting any task; `tatr check` (plus
      `--ledger LESSONS.md`) is the conformance gate. Keep the section
      short; do not restructure the rest of the file.
      (As executed: the repo had NO root AGENTS.md - the file at
      home/modules/agents/AGENTS.md is the deployed global one and was
      left alone - so a short repo-root AGENTS.md was created: what the
      repo is, the Development flow section as specified, the check
      suite, and a skills-are-a-doc-surface note.)
- [x] Verify: tatr check exit 0 (or residue listed in the close-out),
      tatr check --ledger LESSONS.md exit 0, and the repo's own check
      suite still green.

## Definition of Done

- LESSONS.md at the repo root, old docs/ path gone, no stale references
  (cmd: test -f LESSONS.md && test ! -f docs/LESSONS.md && ! git grep -n "docs/LESSONS" -- ':!tasks' ':!home/modules/agents/skills/lessons')
  (proof amended: the original blanket grep also matched tasks/ history
  files - preserved verbatim by design - and the lessons skill's
  intentional root-then-docs search-order line, neither of which is a
  stale reference; the amended sweep excludes exactly those two.)
- tatr check clean or residue documented (cmd: /home/alex/personal/tatr/tatr check;
  manual: user reviews the residue list at the goal's Finish)
- ledger lints clean (cmd: /home/alex/personal/tatr/tatr check --ledger LESSONS.md)
- AGENTS.md names /flow and LESSONS.md (cmd: grep -n "flow\|LESSONS.md" AGENTS.md)

## Notes

- Use the tatr binary at /home/alex/personal/tatr/tatr (the installed one
  may predate the check subcommand).
- Preserve history honestly: normalizations keep meaning; ticks record
  verifiably shipped work only (linter-adoption cleanup, per the precedent
  in tatr's own 20260720-152503).

## Close-out (2026-07-20, branch chore/flow-v2-adoption)

What shipped:

- git mv docs/LESSONS.md -> LESSONS.md; the now-empty docs/ removed. The
  ledger needed no format work: bare counts, the "## Pending promotions
  (3+ occurrences, user decides)" section with the sole unpromoted (x3)
  entry (dry-run-in-a-scratch-repo), and PROMOTED annotations were
  already in place.
- Old-path sweep: this repo is the SOURCE of the flow skills, so the
  hardcoded docs/LESSONS.md mentions lived in the skill files. Updated,
  keeping skill semantics generic for any repo:
  - home/modules/agents/skills/flow/SKILL.md step 3.1: read the ledger at
    the repo root, or wherever the lessons skill's search order finds it;
  - home/modules/agents/skills/flow/SKILL.md Finish: --ledger path is
    "usually the repo-root LESSONS.md";
  - home/modules/agents/skills/compound/SKILL.md step 5: same
    root-preferred phrasing, create-at-root if missing.
  Deliberately unchanged: the lessons skill's root-then-docs search order
  (that fallback is the mechanism, not a stale path) and all tasks/*
  history files (RETRO/TASK/GOAL mentions stay as written).
- tatr check: already clean; exit 0 before and after. No closed-unchecked,
  closed-not-approved or bad-severity findings existed, so the step's
  remediation playbook had nothing to act on. Residue: none.
- AGENTS.md: created at the repo root (none existed; the deployed global
  one at home/modules/agents/AGENTS.md untouched). Sections: what the
  repo is, Development flow (/flow, tatr tasks, sprout worktrees,
  out-of-context round-1 reviews, DoD proofs, root LESSONS.md read before
  any task, /home/alex/personal/tatr/tatr check + --ledger LESSONS.md as
  the gate), the check suite, and the skills-as-doc-surface rule.

Verification (all in the worktree):

- /home/alex/personal/tatr/tatr check -> exit 0
- /home/alex/personal/tatr/tatr check --ledger LESSONS.md -> exit 0
- bash home/modules/scripts/sprout-test.sh -> passed: 14, failed: 0
- nix flake check --no-build -> "all checks passed!"
- DoD sweep (amended, see DoD note): git grep for docs/LESSONS excluding
  tasks/ and the lessons skill -> no matches; grep -n "flow\|LESSONS.md"
  AGENTS.md -> matches on both.

Deviations from the plan as written: DoD sweep cmd amended (blanket grep
would flag preserved history and the lessons skill's own fallback); step 2
was a no-op because check was already clean; step 3 was a create, not a
refresh.
