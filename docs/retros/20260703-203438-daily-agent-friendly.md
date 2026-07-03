# Retro: Make the `daily` script agent-friendly

- TASK: 20260703-203438
- BRANCH: agent-daily-today (kept on branch, not merged - per the run's scope)
- REVIEW ROUNDS: 1 (APPROVE)

See `tasks/20260703-203438/{TASK,REVIEW}.md`. Process notes only.

## What went well

- The render + `evalModules` harness built for the `today` task paid off
  immediately: no new setup, just point it at `daily.nix`. Building the real
  derivation gave a genuine shellcheck gate for a ~1100-line script, which
  matters far more here than for the small `today` script.
- The many identical stream/exit-code redirects (11 arg errors, 10 "no entry"
  messages, 9 confirmations) were applied with one audited `sed` and then
  reviewed line-by-line via `git diff` before trusting it - fast and safe,
  where 30 hand-edits would have been error-prone.
- Reached for `jq` for JSON instead of hand-rolling string concatenation, so
  quoting/escaping of task text and habit names is correct by construction.
- Refactoring macros into a shared `macros_values` killed a latent
  divergence risk (two copies of the totals math) rather than adding a third.

## What went wrong

- Nothing broke, but I could not confirm the double-`Today`-marker interaction
  because the real den template is outside this environment. Rather than guess
  a fix, filed it as task 20260703-205034 with an explicit "inspect first"
  step.

## What to improve next time

- For bulk mechanical edits to a source file, `sed` + `git diff` audit is the
  right tool; reserve the line editor for the genuinely unique changes (the
  new functions, dispatch wiring). This kept the diff reviewable.
- When a behavior depends on data I can't see (the production template), make
  the uncertainty a tracked task with a verification step, not a silent
  assumption baked into code.

## Action items

- [ ] Resolve follow-up 20260703-205034 (double `Today` marker) against the
      real template before relying on `daily --json` task completeness.
