{
  piModule,
  sourceRoot ? ./.,
}: {
  pkgs,
  ...
}: let
  agentPackages = import ./packages.nix {inherit pkgs sourceRoot;};
in {
  imports = [
    piModule
    (import ./core.nix {inherit agentPackages;})
    ./pi.nix
    (import ./tools.nix {
      inherit agentPackages;
      toolSkills.knowledge = sourceRoot + "/skills/knowledge";
    })
  ];
}
