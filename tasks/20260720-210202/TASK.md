# Swap den scripts to the packaged today CLI (add today, drop today/daily.nix, update skills)

- STATUS: CLOSED
- PRIORITY: 40
- TAGS: infra, nix, skills

## Goal

Replace the two old bash journal scripts (`today` + `daily`, in
`home/modules/scripts/{today,daily}.nix`) with the single packaged Python CLI
`today` (github:alexjercan/today), and update the `today`/`daily` agent skills to
the new subcommand surface. After this, there is ONE `today` command with
subcommands; the `daily` binary is gone.

## Packaging / home wiring

1. Add the flake input in `flake.nix` (mirror the `tatr` input):

   ```nix
   today = {
     url = "github:alexjercan/today";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```

2. In `flake/home-configurations.nix`, add `inputs.today.overlays.default` to the
   `overlays = [ ... ];` list (next to `inputs.tatr.overlays.default`). This
   exposes `pkgs.today`.

3. Provide the command in the home config. The new CLI reads the den from
   `--den`, then `$DEN_PATH`, then the default `~/personal/the-den` (which already
   matches today's `rootPath`). Simplest: `home.packages = [ pkgs.today ];` and set
   `home.sessionVariables.DEN_PATH = "/home/alex/personal/the-den";` (use an
   absolute path - the CLI does `Path(env).expanduser()`, but an absolute path is
   unambiguous). Put this where the old `today`/`daily` enablement lived
   (`home/modules/scripts/default.nix`, or a small new module).

## Remove the old scripts

4. Delete `home/modules/scripts/today.nix` and `home/modules/scripts/daily.nix`.
5. In `home/modules/scripts/default.nix`: drop the `./today.nix` / `./daily.nix`
   imports and the `today = { enable = true; ... };` / `daily = { ... };` config
   blocks. Keep `./sprout.nix`. (Verify nothing else references `config.today.*`
   or `config.daily.*`.)

## Update the agent skills

The skills live in `home/modules/agents/skills/{today,daily}/SKILL.md`. Since one
binary now does everything, prefer CONSOLIDATING into the single `today` skill
(read + create + mutate) and retiring the `daily` skill (or make it a one-line
pointer to `today`). Update every command example to the new surface. Mapping:

Old `today`  -> new:
- `today -c/--create`            -> `today create`
- `today -p/--path`              -> `today path`
- `today -t/--template <T>`      -> (dropped; new always uses Templates/daily.md)
- `today <DEN-PATH>`             -> `today --den <PATH>` (or $DEN_PATH)
- bare `today`                   -> still opens $EDITOR (agents must not run it bare)

Old `daily`  -> new:
- `daily --json`                 -> `today show --json`
- `daily --task-entry <T>`       -> `today task add <T>`
- `daily --toggle-task <I>`      -> `today task done <I>`
- `daily --task-remove <I>`      -> `today task rm <I>`
- `daily --task-tomorrow-entry`  -> `today task add <T> --tomorrow`
- `daily --task-tomorrow-remove` -> `today task rm <I> --tomorrow`
- `daily --toggle-habit <H>`     -> `today habit toggle <H>`  (also `today habit list`)
- `daily -m/--macros-entry <T>`  -> `today macros add "what,protein,carbs,fat"` (also bare `today macros`)
- `daily -e/--notes-entry <T>`   -> `today note add <T>`  (tags: `--tag <T>`)
- `daily --weight-entry <V>`     -> `today weight <V>`
- `daily -n/--note <TAG>`        -> `today note list --tag <TAG>`  (NOTE: now day-scoped, not cross-day)
- `daily -w/--weight` (gnuplot plot) -> `today weight` prints a text trend; the
  PNG plot is NOT ported (decide: drop it, or keep a tiny separate plot script).
- `daily -N <N>`                 -> `today -N <N>` (global offset)
- `daily <DEN-PATH>`             -> `today --den <PATH>`

Behavior notes to carry into the skill docs:
- One `today` command, subcommands are non-interactive + `--json`; bare `today`
  opens $EDITOR (agents use subcommands only).
- `note list` is day-scoped (the old `daily -n` searched all files); flag this.
- Only `[ ]`/`[x]` are tasks; other markers (the retired `[~]`) are skipped.
- Macros/weight/note writes are validated (a logged value always reads back).

## Verify / DoD

- (cmd) `nix flake check` on nix.dotfiles is green.
- (cmd) `nix build .#homeConfigurations.alex.activationPackage` (or the repo's
  usual build) succeeds with `today.nix`/`daily.nix` gone.
- (manual) `home-manager switch` (or nixos rebuild) then: `which today` resolves
  to the Nix store package (not the bash script), `which daily` is GONE, and
  `today show --json` / `today path` work against the real den.
- (manual) The updated skills read correctly and every example runs.

## Notes

- Depends on github:alexjercan/today being pushed (done). Bump the flake input
  (`nix flake update today`) if it lags.
- The scufris den MCP tools (scufris tasks/20260720-122514) wrap these `today`
  subcommands - keep the subcommand names stable.
- Reference the today repo's own tasks/20260720-142205 (finalize-nix) which
  exported `flake.overlays.default` for exactly this consumption.

## Done (this branch)

- flake input `today` added + locked; `inputs.today.overlays.default` added to
  the home overlays; `home.packages = [pkgs.today]` + `DEN_PATH` in
  `home/modules/scripts/default.nix`.
- Deleted `home/modules/scripts/{today,daily}.nix` and their enable config.
- Skills consolidated: rewrote `skills/today/SKILL.md` to the full subcommand
  surface (path/create/show + task/habit/weight/macros/note, `show --json`
  shape, behavior notes) and DELETED `skills/daily/` (one binary now does both).
- cmd proofs green: `nix flake check --no-build` passes; `nix build
  github:alexjercan/today#today` builds; packaged binary smoke-tested end to end
  (path/create/habit/weight/macros/note/show --json).

## Deferred to the user (manual)

- `home-manager switch` (or nixos rebuild) to activate: then confirm `which
  today` resolves to the Nix store package, `which daily` is GONE, and `today
  show --json` works against the real den. Batched as the manual-acceptance item.
- Decision left open: the old `daily -w` weight PNG plot is not ported (`today
  weight` gives a text trend only). Left dropped; reopen if the plot is wanted.
