# Deploy Scufris v2.1.0

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: scufris,deployment

## Goal

Pin immutable Scufris `v2.1.0` and activate it. The release adds the morning
briefing and changes how the service handles an answer nobody asked for.

## Acceptance

- The Scufris input names tag `v2.1.0` and resolves to release commit
  `9e2f1fa83523eeeaa7a802062d27305b404c2c03`.
- `nix flake check -L` and the Home Manager activation package build pass.
- Service, desktop, and gateway units are active after activation, and the
  three Scufris executables report version 2.1.0.
- A morning briefing collects from the declaring projects and reaches the
  conversation window rather than being refused.

## Verification

Activated on 2026-08-31:

- `flake.nix` names `github:alexjercan/scufris2/v2.1.0` and `flake.lock` holds
  rev `9e2f1fa83523eeeaa7a802062d27305b404c2c03`.
- `nix build .#homeConfigurations.alex.activationPackage --no-link` and
  `nix flake check -L` both passed, and `alejandra --check .` is clean.
- `home-manager switch --flake .#alex` restarted the service, desktop, and
  gateway units. All three report active.
- The upstream release is green: the `check`, iOS, and release workflows all
  succeeded, and the tag matched the package version.
- The packaged helper layout is right. `share/scufris/tools/briefing/cli.py`
  exists beside the extensions, and the restarted agent spawned it from that
  path. The working-tree-only path bug is gone.
- The morning ran for real. It collected `personal/scufris2`,
  `personal/the-den`, `personal/nova-protocol`, and `personal/seedzero`, and
  the run reached `delivered` with its prose, manifest, and page written. The
  service logged no refusal.
- Two projects answered with something the envelope could not take:
  nova-protocol sent unterminated JSON, and seedzero sent a headline over 200
  characters. Both were recorded as failed and named, which is the designed
  behaviour, but both guidance files need tightening.
- Startup found a defect. pi runs the `session_start` listeners one after
  another, and the briefing extension awaited the whole collection, so the
  agent reached `agent.sock` only when the sources had finished: started
  17:26:14, connected 17:28:27. Surfaces could not reach it in between.
  Fixed in scufris2 by commit `ec38afb`, which is not in v2.1.0.
- The sources cannot run commands. Both `claude` sources reported that their
  shell calls were denied: nova-protocol could not reach `gh`, and seedzero
  could not reach `python3`, so neither refreshed anything. `--permission-mode
  dontAsk` is already set and `Bash` is allowed, so the denial is the sandbox
  and not the permission mode. A source that needs a command currently answers
  from files alone.

## v2.1.1

The v2.1.0 morning found four defects. Three were fixed upstream and the pin
moved rather than staying on a release that could not do its job.

- A `claude` source ran sandboxed under `dontAsk`, so nova-protocol could not
  reach `gh` and seedzero could not reach `python3`. Both harnesses now answer
  without asking, matching `pi --approve`.
- The envelope reader matched fences against each other, so a body that fenced
  code of its own cut the answer off mid-string. Each block is now read for its
  own end.
- The reader held sources to limits it never stated. A 227 character headline
  lost a whole contribution. The limits are in the prompt now.
- The briefing was collected inside session startup, and pi runs the startup
  listeners one after another, so the agent joined `agent.sock` only when the
  sources had finished.

Verified on 2026-08-31:

- Both sources were asked again with the fixed collector. nova-protocol read CI
  and answered `attention` in 29.4 s; seedzero refreshed the channel and
  answered `ok` in 109.2 s. Headlines were 112 and 143 characters.
- Upstream `check`, iOS, Documentation, and release workflows all succeeded,
  and the source-only Release `Scufris v2.1.1` was created.
- `flake.nix` names `github:alexjercan/scufris2/v2.1.1` and `flake.lock` holds
  rev `51621b927d55969aa10f005e88b108fdaed26e38`.
- `home-manager switch --flake .#alex` restarted the three units, all active.
  The service logged `agent connected` in the same second it started, with no
  grace warning.
- The installed package carries both fixes.

## v2.1.2

The v2.1.1 morning collected cleanly and one source still lost its report: a
quotation mark inside seedzero's body ended the JSON string early, after the
run had already cost 197 seconds. That is the third way a long Markdown body
inside a JSON string has been lost.

- A source that answered badly is asked once more, given its own words and the
  one reason they could not be used, with no tools at all. It may change only
  that.
- Nothing a source does can end a run: an answer nested past the decoder's
  stack, output that is not text, a contribution that cannot be written, and a
  page that cannot be laid out are each recorded rather than raised.

Verified on 2026-08-31:

- The real broken answer was put through the repair run against a real model.
  4507 characters recovered in 26.3 s, against the 197.3 s the first run cost,
  with its findings intact.
- seedzero asked again from scratch answered `ok` in 177.6 s with a 133
  character headline, six facts, and a 3551 character body.
- 50 briefing tests, 276 Python tests, 87 TypeScript tests, 6 Rust suites,
  clippy, shellcheck, alejandra, and `nix flake check -L` all pass.
- Upstream `check`, iOS, Documentation, and release workflows all succeeded,
  and the source-only Release `Scufris v2.1.2` was created.
- `flake.lock` holds rev `7c951f1a775b28f7f6673831bd4a5da93042d492`, the three
  units are active, and the service logged `agent connected` in the same second
  it started.

