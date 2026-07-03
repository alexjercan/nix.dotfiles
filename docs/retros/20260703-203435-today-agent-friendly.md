# Retro: Make the `today` script agent-friendly

- TASK: 20260703-203435
- BRANCH: agent-daily-today (kept on branch, not merged - per the run's scope)
- REVIEW ROUNDS: 1 (APPROVE)

See `tasks/20260703-203435/{TASK,REVIEW}.md`. Process notes only.

## What went well

- Built a render + real-build harness before touching the script. The render
  step (`$$`/`''${` transforms + interpolation substitution) gave a fast local
  loop, and `lib.evalModules` + `writeShellApplication` gave a faithful
  shellcheck-passing build without standing up the whole home-manager config.
  That combination caught the escaping rules early.
- Applied the standing retro lesson ("test from the real usage site"): every
  agent-facing path (`--create`, `--path`, first-entry, missing template, bad
  flag) was exercised against a fixture den, not just eyeballed.
- Found and fixed a latent bug (`$${DEN_PATH%/}`) that was only visible once I
  checked how nix actually renders the string, rather than assuming.

## What went wrong

- Initial confusion about nix indented-string `$$` escaping cost a couple of
  probe commands. Resolved by reading the already-rendered installed script in
  the profile - ground truth beats reasoning about escape rules.
- The three planned tasks collided on tatr's second-granularity IDs when
  created in one batch; two were silently overwritten. Had to recreate them in
  separate calls.

## What to improve next time

- When creating multiple tatr tasks in one go, space them out (separate calls)
  or tatr needs sub-second / collision-safe IDs. Worth a tatr follow-up if it
  recurs.
- For nix-embedded scripts, confirm the rendering rule (`$$` stays literal,
  `''${` escapes) up front from a built/installed artifact before writing bash
  with `${...}`.

## Action items

- [ ] Watch for tatr same-second ID collisions; if it bites a third time, file
      a tatr issue for collision-safe IDs.
- [ ] Carry-over placement in `templator` (double `Today` header) is a possible
      real bug - decide during the `daily` task whether it needs its own task.
