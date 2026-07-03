# Retro: Skills for `daily` and `today` as agent CLI tools

- TASK: 20260703-203418
- BRANCH: agent-daily-today (kept on branch, not merged - per the run's scope)
- REVIEW ROUNDS: 1 (APPROVE)

See `tasks/20260703-203418/{TASK,REVIEW}.md`. Process notes only.

## What went well

- Writing the docs LAST, after both scripts shipped, meant the command tables
  and exit codes came straight from the built binaries' `--help` instead of
  from intent - no drift between skill and tool. The dependency ordering in the
  plan (skills depend on today+daily) paid for itself.
- Confirmed the skills wiring by reading `agents/default.nix` and doing a real
  `nix eval` of the home config, rather than assuming the recursive source
  "probably" picks up new dirs.

## What went wrong

- Nothing notable. The task was mechanical once the tools were final.

## What to improve next time

- Keep documenting agent-facing tools with an explicit "traps" note (here:
  "never run `today` with no flags - it opens $EDITOR"; "don't scrape `daily`
  markdown, use `--json`"). The most useful line in a tool skill is often the
  one that stops an agent from the obvious wrong move.

## Action items

- [ ] None. Follow-up 20260703-205034 (double `Today` marker) still stands and
      may warrant a doc tweak once resolved.
