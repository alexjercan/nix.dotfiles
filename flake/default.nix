{inputs, ...}: {
  systems = ["x86_64-linux"];

  imports = [
    ./nixos-configurations.nix
    ./home-configurations.nix
  ];

  flake.homeModules.agents = ../home/modules/agents/module.nix;
  flake.extensions.x86_64-linux =
    builtins.mapAttrs (_: ext: ext.extension)
    (import ../home/modules/agents/pi/extensions {
      pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
    });

  flake.themes.gruber-darker = inputs.self + "/home/modules/agents/pi/themes/gruber-darker.json";

  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [inputs.llm-agents.overlays.shared-nixpkgs];
    };
    sourceRoot = inputs.self + "/home/modules/agents";
    i3Module = inputs.self + "/home/modules/i3";
    scufrisI3Module = inputs.self + "/home/modules/scufris/i3.nix";
    piExtensions = import ../home/modules/agents/pi/extensions {inherit pkgs;};
    agentPackages = {
      inherit (pkgs.llm-agents) agent-browser claude-code codex opencode pi;
      plannotator = piExtensions.plannotator.binary;
    };
    homeModule = ../home/modules/agents/module.nix;
  in {
    packages = agentPackages;
    checks = import ../home/modules/agents/checks.nix {
      inherit pkgs homeModule i3Module scufrisI3Module;
      inherit sourceRoot;
      scufrisModule = inputs.scufris.homeModules.default;
      scufrisRevision = inputs.scufris.rev;
      packages = agentPackages;
      extensions = builtins.mapAttrs (_: ext: ext.extension) piExtensions;
      home-manager = inputs.home-manager;
    };
  };
}
