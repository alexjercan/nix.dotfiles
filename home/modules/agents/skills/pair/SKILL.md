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
* Never stop where the only plausible reply is "next". A commit inside an
  approved sequence is not a stop; continue to the next slice unless the
  user must playtest or review it.
* Mechanical work runs in one batch with the decision it follows: moves,
  copies, renames, writing an approved draft, version bumps, doc updates.
* An approved plan, draft, or well-specified request ("do the release") is
  consumed approval. Execute it fully; stop early only on surprises.
* Report each stop as: Delta / Verified / Next. Next is prose: what comes
  next and anything useful for it; include the command when one exists.
* The report appears only at stops. Between tool batches, narrate in at
  most one plain sentence, or not at all.
* A stop that contains a fork ends with the question, alone on the last
  line.

## Depth

* Interface, naming, default, and precedence choices are always decisions,
  however small. Draft them in chat before writing.
* Present forks with full depth: what each option means, one consequence,
  a recommendation. Never bare labels.
* In design stops, give each decision point its own heading or code block,
  so annotations can target it.
* Record an accepted design in the task notes before implementing it.
  Approval targets the record, not chat, and survives compaction.
* A question pauses the loop: expand until it is clear, no file changes,
  then resume where the work stopped.

## Rules

* Per batch, run the cheapest read-only check without asking.
* Builds and full suites only on request. State what was not verified.
* Before an irreversible action, run what CI runs.
* After a context compaction, re-read this skill file before the next stop.
* No task/todo machinery.
