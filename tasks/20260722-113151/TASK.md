# Clean up hyprland module cruft (shadow block, dup capslock bind, wlogout style)

- STATUS: CLOSED
- PRIORITY: 25
- TAGS: chore, nix

## Story

home/modules/hyprland/default.nix has accumulated small cruft:
- an empty `shadow = {};` block,
- the Caps-Lock -> discord passthrough appears twice (once as `bindn`, once in
  `bind` as `,Caps_Lock,pass,class:^(discord)$`),
- `wlogout` style is commented out with `FIXME: images not working`.

hyprland is the rice/secondary WM (i3 is my daily driver), and some of this is
genuinely finicky on hyprland, so this is low priority and needs care.

## Steps

- [x] Remove the empty `shadow = {};` block if it has no effect.
- [x] De-duplicate the Caps-Lock/discord passthrough (keep the one that works).
- [x] Resolve the wlogout style FIXME: either fix the icon paths or delete the
      dead commented-out `style = ./wlogout-style.css;` and its assets.

## Resolution

All three items done. Owner confirmed the Caps/discord PTT never worked and
asked for a best-effort fix to test later, so this is closed with the code
cleaned up and the runtime unknowns documented in-line.

- DONE: removed the empty `decoration.shadow = {};` block. Behavior-neutral (an
  empty override sets nothing, identical to the default). `nix flake check` green.
- DONE (best effort, untested on hyprland): consolidated the Caps/discord
  passthrough to ONE binding. Deleted the malformed `bindn = ["CAPS, less,
  pass, ^discord$"]` (invalid `CAPS` modmask, wrong `less` key, bare regex) and
  kept the single `bind = ", Caps_Lock, pass, class:^(discord)$"`. Added an
  in-line comment listing why it likely never worked and what to check when
  testing: (1) Discord's real window class vs the case-sensitive
  `class:^(discord)$` (`hyprctl clients`), (2) Discord's own PTT keybind must
  match, (3) Caps_Lock is a LOCKING key so it delivers unclean press/release -
  neutralize via `input { kb_options = "caps:none"; }` or use a spare non-lock
  key. Left as Caps_Lock per the existing intent.
- DONE: fixed the wlogout "images not working" FIXME. Root cause: GTK CSS does
  not expand `~` in `url()`, so `url("~/.local/share/wlogout-icons/...")` never
  resolved. Changed the CSS paths to an `@icondir@` sentinel and now generate
  the stylesheet via `pkgs.writeText` + `builtins.replaceStrings`, substituting
  the icons' absolute nix store path (`${./wlogout-icons}`). Re-enabled
  `programs.wlogout.style`. Verified the generated CSS resolves to
  `/nix/store/...-wlogout-icons/lock.png` (absolute, GTK-resolvable). Rendering
  itself still to be eyeballed on a hyprland session.

## Notes

- Test on hyprland after each change - the caps/discord passthrough is the
  fragile bit. (Caps/discord and wlogout rendering are best-effort, pending an
  eyeball test by the owner.)
