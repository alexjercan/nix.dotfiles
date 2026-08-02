# Decision: afk: show the session's context token count, colored by budget

- DATE: 20260802-192853
- STATUS: ACCEPTED
- TASK: 20260802-192659
- TAGS: afk, ux, presentation

## Context

`afk run` streams stream-json events and already reports phase, commits and
gates as permanent labelled lines, with color and the spinner as the only
TTY-gated decoration. The request adds one more number - how full the current
session's context is - and the question is where it comes from and where it is
shown without breaking either invariant.

## Decision

The count is the last `assistant` event's `.message.usage` fields summed
(`input_tokens` + `cache_creation_input_tokens` + `cache_read_input_tokens` +
`output_tokens`). That sum is what the model was actually holding on that
turn, which is the number the 120K/180K thresholds are about; a probe of a
trivial headless prompt returned 22499 for a fresh session, matching its
system-prompt load.

It is shown twice: colored on a permanent `tokens  57.6K` line per claude
invocation, and uncolored in the transient spinner. The spinner stays plain
because it is truncated to the terminal width by byte count, and a truncated
escape sequence would leave the terminal colored.

## Alternatives considered

- The `result` event's `.usage`. It carries the same fields, but only once at
  the end, so the spinner could not show a live count and a killed session
  would report nothing. Rejected: strictly less information for the same
  parse.
- Cumulative tokens across the whole run. That is a cost meter, not a context
  meter, and the requested thresholds are context-window thresholds.
  Rejected as answering a different question.
- The maximum seen rather than the latest. Rejected: after a compaction the
  context really does shrink, and a high-water mark would keep the line red
  for a session that is now healthy.
- Coloring the spinner too. Rejected for the truncation hazard above; the
  permanent line carries the color.

## Consequences

Easier: a watching human sees a session approaching its window before it
compacts or stalls, and the number is attributable to a specific invocation.

Harder: `run_claude` now prints as well as drives, so the driver and the
presentation are a little more coupled. The report grows one line per
invocation, including gate resumes. And afk now depends on a usage field
shape that Claude Code owns; if it changes, the count silently disappears
rather than failing loudly - which is the deliberate trade for not letting a
cosmetic field break an unattended run.
