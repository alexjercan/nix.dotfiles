# Adjust AI usage bar limits

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: config, i3

Show only weekly remaining usage by default. Clicking each custom block cycles to
its five-hour limit, labeled `CLD5` or `CDX5`, and another click returns to the
weekly value.

Codex windows are selected by their declared duration instead of unstable
primary/secondary positions. Cache each provider response for 10 minutes so
switching windows does not issue another API request. Keep stale successful data
when refresh fails, and wait 5 minutes before retrying a failed request.

Verification:

- `nix build .#homeConfigurations.alex.activationPackage --no-link`
- Live helper calls returned the expected `CLD`, `CLD5`, `CDX`, and `CDX5`
  labels. The current Codex API response has no five-hour general limit, so
  `CDX5` correctly reports `?`.
- Seeded-cache tests confirmed that weekly and five-hour views reuse one response.
- A recent failure marker suppresses another request and returns `?` when no
  successful cached response exists.
