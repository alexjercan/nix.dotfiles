# Deploy calculated food entry through Home Manager

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: dashboardd, today, macros, home-manager

Deploy the local macros JSON CLI and Today's calculated food widget through the existing Home Manager dashboardd service.

## Requirements

- Use local macros.nvim and Today inputs until releases exist.
- Make Today's macros input follow the root macros.nvim input.
- Set the dashboard service's food database path explicitly.
- Build and apply Alex's Home Manager activation package.
- Verify live search against the real database without writing a food entry.

## Definition of Done

- dashboardd.service uses the new Today package and remains active.
- The packaged backend resolves the macros executable from its Nix closure.
- Food search returns candidates from the real database.
- The health endpoint remains available on loopback port 7331.

## Implementation

- Replaced macros.nvim's release input with its local JSON CLI checkout.
- Made Today's macros input follow the root macros.nvim input.
- Set `MACROS_DATABASE` to Alex's existing Neovim food database in the
  dashboardd user service.
- Updated the local Today lock and applied the Home Manager generation.

## Verification

- `nix flake check -L`: passed.
- `nix build .#homeConfigurations.alex.activationPackage --no-link -L`:
  passed.
- `home-manager switch --flake .#alex`: passed and restarted dashboardd.
- Service: active, enabled, healthy, and running all five existing Today
  instances from the new package.
- Catalog: Today exposes five variants.
- Read-only real database search: `chick` returned `chicken breast raw (g)` and
  `Chicken Breast (g)` through the packaged backend and macros closure.
