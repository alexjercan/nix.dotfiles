# Retro: Keep agent code comments minimal

- TASK: 20260731-163120
- BRANCH: master
- REVIEW ROUNDS: 2

## What went well

- The user's own read of the working set caught the over-prune before review
  did, and naming one concrete example (the Home Manager `stateVersion`
  warning) defined the whole class faster than any abstract criterion would
  have.
- The out-of-context reviewer independently reran every DoD proof and refuted
  a close-out claim the implementation context had accepted as settled.
- Re-deriving two of the reviewer's claims before accepting them was what
  surfaced the severity error: the reviewer graded everything MINOR/NIT and
  returned APPROVE, and the three findings that actually mattered only became
  visible once the primary checked them against the task's own spec.

## What went wrong

- The diff violated the rule it was adding. It deleted the
  `packages/default.nix` header, which guarded a real home-manager file
  collision, in the same commit that told agents to keep guard comments. The
  failed decision was to treat "file-header comment above an imports list" as
  a shape, so the audit classified by position rather than by reading what the
  comment claimed. That seemed sound because most such headers in this repo
  genuinely were labels, and it had already been right eight or nine times in
  a row on the package modules.
- The rule shipped in halves. AGENTS.md got both the prune clause and the
  guard clause; `work/SKILL.md` got only the prune clause. That is the surface
  agents actually load while implementing, so the incomplete half was the one
  that mattered, and it reproduced the exact defect the task existed to fix.
- The close-out asserted `nix flake check` could not run because the nix
  daemon socket was unreachable. It runs and passes. The environment failure
  was real at some earlier moment, but it was written down as a standing
  limitation and never retried.
- Deleting a comment emptied its container: `displayManager.sessionCommands`
  was left as a bare `''`/`''` block because the comment had been the entire
  body.

## What to improve next time

- When a change introduces a rule, run the rule against the change's own diff
  before asking for review. Here that single check would have caught two of
  the three MAJORs.
- A rule with an exception is one unit. Every surface that states the rule
  states the exception, or the surface that omits it is the one that gets
  obeyed.
- A "could not run in this environment" note is a claim with a cheap retry.
  Retry it at close-out time instead of carrying it forward.
- For a deletion-only diff, the DoD proved the unwanted lines were gone but
  nothing could fail if a needed line went with them. An absence proof needs a
  presence proof beside it.

## Action items

- No follow-up task. Every finding was fixed in round 1's fix commit
  (`f9a2888`), and the general lessons are in the ledger.
- One-off, kept here: deleting a comment that is the sole body of a block
  leaves dead config behind; check the container after removing its contents.
