# Retro: Add an unattended afk flow runner

- TASK: 20260802-132348
- BRANCH: feature/afk-flow-runner
- REVIEW ROUNDS: 1

## What went well

The "marker routes, state asserts" rule is what made the whole thing testable.
Because every decision is cross-checked against `tatr` and `git`, the fake
`claude` shim in `afk-test.sh` only has to mutate durable state - it never has
to imitate a model. That is why an integration suite for an LLM supervisor runs
in 15 seconds with no quota spent, and why the sabotage runs could prove each
guard load-bearing.

Round 1 came back APPROVE with three MINOR findings and a NIT. The
out-of-context reviewer re-ran the full DoD suite and independently mutated
four guards; each mutation turned exactly one case red, which is the evidence
that made a one-round APPROVE honest rather than lucky.

The `sprout` shape (plain `.sh` + `writeShellApplication` wrapper + hand-run
`*-test.sh`) transferred with no friction and needed no new convention.

## What went wrong

The plan under-specified where authority lives, and it did so twice in the same
direction:

- Its audit-log example implied scraping Claude's prose for `FLOW`, `COMMIT`
  and `CHECKS PASS` lines. That looked sound because the example was written as
  illustrative output, not as a contract - but an example of output IS a
  contract about where the output comes from. The runner derives all of it from
  `tatr` and `git` instead.
- Step 6 enumerated `runtimeInputs` without `pkgs.tatr`, even though Step 4
  required cross-checking `tatr show`. The dependency list was written from the
  engine's needs, not from the checks' needs.

Both were caught and fixed in WORKING, so they cost design time rather than
review rework. Breadth is not a concern here: ~1200 added lines is one CLI plus
the harness that proves it, and the runner is not independently landable
without that harness.

Three findings survived to review, all MINOR and all about the same seam: the
injected PROTOCOL's status vocabulary versus `flow/SKILL.md`'s `## Output`
contract (`SPIKED` handled in code but absent from the protocol; the AGENTS.md
paragraph describing the coupling inaccurately; the one untested guard on that
path). A plan that had named the two vocabularies and their mapping explicitly
would have collapsed all three.

The hardest debugging was not the runner: `test_interrupt_kills_recorded_pid`
failed for a long time because a background job in a non-interactive shell
inherits SIGINT ignored and so cannot trap it, and because backgrounding
through a shell function puts `$!` on the subshell rather than the runner. Two
shell facts, not an afk bug.

## What to improve next time

When a plan contains an example of a tool's OUTPUT, add one line per output
field naming its source. That single question would have caught both plan gaps
before Step 1.

When a new component consumes another component's documented contract, the plan
should name the contract's vocabulary and the consumer's vocabulary side by
side. Every review finding this round lived in that gap.

Context: no compaction or threshold event is recorded for the working session.
The review ran in a fresh context that started at REVIEWING, which is the
out-of-context reviewer handoff working exactly as `review/rounds.md` intends -
no extra subagent was needed or spawned.

One process failure in this phase, unrelated to the code: `knowledge add`
defaults `--repo` to the current directory, so the first four writes silently
created a shadow `lessons/` tree inside the nix.dotfiles checkout instead of
the central repository. It was caught by `git status`, the stray tree was
deleted, and the writes were redone with an explicit `--repo`. Three of the
four were bumps to existing lessons, which also requires passing the existing
body verbatim - `add` rejects a differing body rather than treating it as an
edit.

## Action items

- R1.1-R1.4 are carried by follow-up task 20260802-143129; they are MINOR and
  do not block landing.
- Consider showing `--repo` explicitly in the `knowledge` skill's command
  block, since its default of `$PWD` fails silently rather than loudly.
- The real end-to-end run against a live Claude stays a pending manual check,
  blocked by the account's weekly rate limit. Until it runs, two assumptions
  are open: that `claude -p "/flow <id>"` resolves the repository skill, and
  that a gate surfaces as an ended turn once `AskUserQuestion` is denied.
