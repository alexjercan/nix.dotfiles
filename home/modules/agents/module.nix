{
  piModule,
  sourceRoot ? ./.,
}: {pkgs, ...}: let
  agentPackages = import ./packages.nix {inherit pkgs sourceRoot;};

  # Extension modules are discovered from the directory names, so a new
  # extension needs no wiring outside its own folder. `pkgs` stays out of this
  # list: forcing a module argument while the imports are resolved recurses.
  entries = builtins.readDir (sourceRoot + "/pi-extensions");
  extensionModules =
    map (name: import (./pi-extensions + "/${name}/module.nix") {inherit sourceRoot;})
    (builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries));
in {
  imports =
    [
      piModule
      (import ./core.nix {inherit agentPackages;})
      ./pi.nix
      ./tools.nix
      (import ./themes/module.nix {inherit sourceRoot;})
    ]
    ++ extensionModules;
}
