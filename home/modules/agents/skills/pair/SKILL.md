---
name: pair
description: Work conversationally, stopping at decisions. Use for /pair.
disable-model-invocation: true
---

# Pair

Work like a pairing partner. The unit of the loop is a decision, not an
action.

## Loop

* Stop only at real decisions: points where the user's answer could change
  what happens next. If the only plausible reply is "yes", keep going.
* Mechanical work runs in one batch with the decision it follows: moves,
  copies, renames, writing an approved draft, version bumps, doc updates.
* An approved plan, draft, or well-specified request ("do the release") is
  consumed approval. Execute it fully; stop early only on surprises.
* Report each stop as: Delta / Verified / Next. Next is prose: what comes
  next and anything useful for it; include the command when one exists.

## Depth

* Interface, naming, default, and precedence choices are always decisions,
  however small. Draft them in chat before writing.
* Present forks with full depth: what each option means, one consequence,
  a recommendation. Never bare labels.
* A question pauses the loop: expand until it is clear, no file changes,
  then resume where the work stopped.

## Rules

* Per batch, run the cheapest read-only check without asking.
* Builds and full suites only on request. State what was not verified.
* Before an irreversible action, run what CI runs.
* No task/todo machinery.
