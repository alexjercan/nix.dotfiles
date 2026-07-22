# Retro: Investigate sops-nix vs agenix, write recommendation

- TASK: 20260722-113105
- BRANCH: chore/secrets-research (landed 47dfb9b)
- REVIEW ROUNDS: 1 (out-of-context, APPROVE)

## What went well

- Grounding the research in the repo BEFORE reaching for the web: reading
  home/alex/default.nix and flake/home-configurations.nix first meant the
  comparison was about "one environmentFile secret consumed by a standalone-HM
  user service", not a generic sops-vs-agenix listicle. The out-of-context
  reviewer confirmed every grounding claim (scufris HM module :186,
  environmentFile :127, standalone homeManagerConfiguration :17) held.
- The out-of-context reviewer on a docs-only-but-substantive diff earned its
  keep: it fact-checked the load-bearing tool claims against the upstream
  READMEs and surfaced the symmetric-key nuance (R1.2) that made the agenix
  runner-up case fairer. A recommendation doc is exactly the kind of "docs that
  define a future decision" the review skill calls substantive.

## What went wrong

- tatr check failed on close with `closed-unchecked`: the task's optional PoC
  Step sat unchecked on a CLOSED task. Root cause: an "Optional: do X" step has
  no honest checkbox state when X is consciously NOT done - ticking it lies,
  leaving it unticked trips conformance. The fix was to reword the step to the
  disposition that WAS completed ("optional PoC dispositioned: deferred to a
  user gate") and check that. Caught by the mechanical gate, not by me, at
  close time rather than at plan time.

## What to improve next time

- Write optional/conditional steps as a DECISION to be made, not an action that
  may or may not happen: "Decide whether to do the PoC (do it / defer with
  reason)" is always checkable on close; "Optional: do the PoC" is not. This
  keeps investigation tasks conformance-clean without dishonest ticks.

## Action items

- [x] Reworded the optional PoC step to a dispositioned decision (this task).
- [ ] PoC gate is a live user decision, tracked as a conditional task in the
      umbrella GOAL.md (20260722-212330); a tatr task is created only if the
      user opts in. Not a code follow-up yet by design.
