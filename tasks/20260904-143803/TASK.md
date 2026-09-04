# Investigate Scufris gateway outage

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: scufris

## Goal

Trace the failed remote surface gateway from the live unit through the pinned
Home Manager modules and generation history. Keep only the smallest proven
nix.dotfiles correction. Do not activate it.

## Findings

- Generation 917 was healthy with ai-tools-api bound to `127.0.0.1:10300` and
  the gateway consuming `http://127.0.0.1:10300`.
- Generation 918 intentionally changed the API bind address to `0.0.0.0` for
  LAN and tailnet access. It also changed the gateway consumer URL to
  `http://0.0.0.0:10300`. The Scufris package did not change between these
  generations.
- The pinned Scufris module defaults `programs.scufris.aiToolsApi.baseUrl` from
  `services.ai-tools-api.host` and `port` whenever that provider option exists.
  It then passes the shared base URL to the gateway's `--ai-tools-api` argument.
- `programs.scufris.aiToolsApi.enable = false` disables only the fallback
  `scufris-ai-tools-api.service` managed by Scufris. It does not disable API
  consumers and does not prevent the shared URL default from reading the
  separate provider configuration.
- The explicit desktop URL kept desktop transcription on loopback. There is no
  gateway-specific URL option. The gateway consumes the top-level shared URL.
- `0.0.0.0` is a valid server wildcard bind address. It is not a valid client
  destination for Scufris. The gateway intentionally accepts only an HTTP base
  URL whose host is a loopback IP or `localhost`.

## Correction

Set the shared Scufris API base URL to `http://127.0.0.1:10300`. Keep API
management disabled in Scufris. Let the desktop inherit that same shared URL.
The separate ai-tools-api service remains enabled and bound to `0.0.0.0`.

## Verification

- Current non-activating evaluation gives `aiToolsApi.enable = false`, shared
  and desktop base URLs of `http://127.0.0.1:10300`, provider host `0.0.0.0`,
  and a gateway command ending in
  `--ai-tools-api http://127.0.0.1:10300`.
- The live API listens on `0.0.0.0:10300`; loopback HTTP access returns 200.
  No process listens on gateway port 10440 while its live unit rejects the
  wildcard destination.
- Alejandra formatting, Nix parse, selected Home Manager evaluations, and
  `git diff --check` passed. No generation was built or activated, and no
  service was changed.

## Upstream

The Scufris module conflates `services.ai-tools-api.host`, documented by that
module as an API bind address, with an advertised client base URL. Its shared
URL default should remain loopback or use a separate provider client URL. It
also tests provider option availability rather than provider enablement when it
selects the provider-derived default. The immediate explicit override belongs
in nix.dotfiles; the default derivation should be corrected separately in
Scufris, not in ai-tools-api.
