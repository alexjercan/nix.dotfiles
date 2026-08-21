# Internalize agents Home Manager integration

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: agents, home-manager

Collapse the consumed agents.nix integration into the existing
`home/modules/agents` module. Preserve optional enablement. Import reusable
tools, Pi assets, knowledge support, deployment helper, and checks. Remove the
agents flake input and all `inputs.agents` references.

## Implementation

- Added the reusable `programs.agents` implementation below the existing agent
  module. The Alex profile still owns its global instructions and workflow
  skills.
- Internalized the knowledge CLI and skill, Codex skill materializer,
  Plannotator package and Pi extension, and Gruber Darker theme.
- Exported the reusable Home Manager module, tool packages, Pi extension, and
  theme from this flake.
- Added integration checks for enabled and disabled module configurations,
  knowledge operations, Codex materialization, and Plannotator.
- Removed the agents input and its lock graph.

## Decisions

- Keep one profile module and one reusable implementation under
  `home/modules/agents`. Do not add a second top-level module.
- Use paths below `inputs.self`. This prevents garbage collection from
  invalidating copied subpath roots during cached flake evaluation.
- Keep agent enablement opt-in in the reusable module. The Alex profile enables
  all currently used tools explicitly.
- Do not migrate the external repository's release and mdBook publishing
  machinery. It is not part of the consumed integration.

## Verification

- `nix flake check`: passed. Builds module, knowledge, Codex materialization,
  and Plannotator checks.
- `nix build .#homeConfigurations.alex.activationPackage --no-link`: passed.
- `git diff --check`: passed.
- Asset output evaluation: Gruber Darker and Plannotator Pi extension passed.
- `nix fmt`: unavailable because this flake has no formatter output.
