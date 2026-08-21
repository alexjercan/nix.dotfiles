{
  piModule,
  sourceRoot ? ./.,
}: {pkgs, ...}: let
  agentPackages = import ./packages.nix {inherit pkgs sourceRoot;};
  piExtensions = import ./pi-extensions {inherit pkgs sourceRoot;};
in {
  imports = [
    piModule
    (import ./core.nix {inherit agentPackages;})
    ./pi.nix
    (import ./voice-stt.nix {inherit piExtensions;})
    (import ./tools.nix {
      inherit agentPackages;
      toolSkills.knowledge = sourceRoot + "/skills/knowledge";
    })
  ];
}
