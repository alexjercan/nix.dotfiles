# Refactor home.packages into topical modules

- STATUS: CLOSED
- PRIORITY: 20
- TAGS: chore, nix, refactor

## Story

home/alex/default.nix has one big flat `home.packages` list (davinci-resolve next
to ripgrep next to wesnoth). Everything ELSE in the repo is modularized under
home/modules/, so this list is the odd one out. Split it into topical modules
(e.g. media, dev, desktop) to match the repo's style.

## Steps

- [x] Investigate a sensible grouping (media / dev-tools / desktop / cli) and
      whether some packages already belong to an existing module.
- [x] Move packages into home/modules/<group>/default.nix files, imported from
      home/alex/default.nix.
- [x] `nix flake check` green; built home closure lists the same package set as
      before (diff the paths).

## Resolution

Split the flat `home.packages` list (home/alex/default.nix) into a new
`home/modules/packages/` parent module with seven topical sub-files, imported
via one `"${modulesPath}/packages"` entry:

- cli.nix     - bat, btop, dua, dust, fastfetch, fd, fzf, jq, rar, ripgrep,
                unzip, xclip, zip, hello
- dev.nix     - ast-grep, cmake, gh, graphviz, llama-cpp, macros, openssl,
                poetry, tatr
- media.nix   - audacity, blender, davinci-resolve, ffmpeg, gimp, inkscape,
                kdePackages.kdenlive, mpv, mupdf, obs-studio
- apps.nix    - brave, chromium (override), discord, firefox, libreoffice-qt
- games.nix   - prismlauncher, wesnoth
- desktop.nix - dconf, feh, i3lock, libnotify, lxappearance,
                networkmanager-openvpn, networkmanagerapplet, nitrogen, openvpn,
                pcmanfm, pw-volume, pwvucontrol, scrot, virt-manager
- fonts.nix   - iosevka (+ moved `fonts.fontconfig.enable` here)

Removed 3 redundant duplicates that a feature module already provides: `dunst`
(services.dunst), `kitty` (programs.kitty), `i3status-rust`
(programs.i3status-rust). They remain in the closure once each via those modules.

### Proof (pure refactor - identical package set)

- Sorted-unique package names in `config.home.packages`: 103 before, 103 after,
  `diff` empty (IDENTICAL SET). `dunst`/`kitty`/`i3status-rust` each present once
  after (were twice before).
- `config.home.path` outPath differs (qla7... -> lrqp...) ONLY because dropping
  the 3 duplicate entries changes the buildEnv `paths` arg multiset; the
  realized unique path set is unchanged (that is what the name-set diff proves).
- `nix flake check --no-build` green.

### Gotcha hit

New module files were untracked, so flake eval (which only sees git-tracked
files via inputs.self) failed with "path .../modules/packages does not exist".
Fixed by `git add`ing the files before eval. Recorded as a lesson candidate.

## Notes

- Pure refactor: the resulting package set must be identical - prove it by
  diffing the closure before/after. (Done: 103 == 103, empty diff.)
- home/alex/default.nix still uses the `../modules` path literal (modulesPath);
  a separate concern from the flake `${inputs.self}` GC-root pattern, left as-is.
