# Address the afk runner's round-1 review findings

- STATUS: OPEN
- PRIORITY: 40
- TAGS: agents, flow
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

Round 1 of the afk flow runner review (20260802-132348, REVIEW.md) closed
APPROVE with three MINOR findings and a NIT left open. All three MINORs sit in
one seam: afk's injected PROTOCOL status vocabulary versus the flow skill's
`## Output` contract. Close them together.

- R1.1 `home/modules/scripts/afk.sh:65` - add `SPIKED` to the PROTOCOL status
  list so the branch at afk.sh:442 is reachable by contract.
- R1.2 `AGENTS.md:80` - reword the machine-consumer paragraph: `flow/gates.md`'s
  three approve labels are the shared literal contract; ROTATE/DONE/BLOCKED are
  afk's own vocabulary, defined in the PROTOCOL heredoc.
- R1.3 `home/modules/scripts/afk.sh:390` - cover the "the session reported a
  task with no record" guard in `test_failure_paths`.
- R1.4 (NIT) decide whether `AFK_VERBOSE` stays; keep it as a diagnostic or
  delete afk.sh:241-246 and its usage line.

Also from the retro of 20260802-132348: consider showing `--repo` explicitly in
the `knowledge` skill's command block, since its default of `$PWD` fails
silently by writing a shadow lesson tree into the project checkout.
