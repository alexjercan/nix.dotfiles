# Run dashboardd with Today through Home Manager

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: dashboardd, today, nix, home-manager

Integrate packaged dashboardd and the local Today widget package into Alex's Home Manager configuration.

## Requirements

- Add dashboardd as a pinned flake input.
- Use the local Today checkout until its widget release exists.
- Compose built-in and Today widget roots with `lib.makeSearchPath`.
- Run dashboardd as a persistent user service on loopback port 7331.
- Use `~/personal/the-den` through `DEN_PATH`.
- Keep dashboard state in dashboardd's standard XDG state location.
- Verify the flake and Home Manager activation package.

## Definition of Done

- Home Manager installs dashboardd.
- `dashboardd.service` starts successfully.
- Dashboardd discovers the Today widget and its five variants.
- The health endpoint responds on `127.0.0.1:7331`.

## Implementation

- Pinned dashboardd at `e68a4acdd73b5be73883f4fa435db26a2f16cbab`.
- Replaced Today's release input with the local checkout and made its
  dashboardd input follow the root pin. This is development wiring until a
  Today widget release exists.
- Added `home/modules/dashboardd/default.nix` and imported it for Alex.
- Composed the dashboardd package and Today package widget roots without
  copying either package tree.
- Installed and enabled `dashboardd.service` through Home Manager.

## Verification

- `nix flake check -L`: passed.
- `nix build .#homeConfigurations.alex.activationPackage --no-link -L`:
  passed.
- `home-manager switch --flake .#alex`: passed and started the service.
- `systemctl --user status dashboardd.service`: active and enabled.
- `GET http://127.0.0.1:7331/health`: succeeded.
- Runtime log: discovered nine widgets from the built-in and Today roots.
- Runtime catalog: Today exposes Tasks, Habits, Macros, Weight, and Upcoming
  with the expected dimensions and Focus support.
