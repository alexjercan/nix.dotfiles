{inputs, ...}: {
  systems = ["x86_64-linux"];

  imports = [
    ./nixos-configurations.nix
    ./home-configurations.nix
  ];

  flake.homeModules.agents = import ../home/modules/agents/module.nix {
    piModule = inputs.pi.homeModules.default;
    sourceRoot = inputs.self + "/home/modules/agents";
  };
  flake.extensions.x86_64-linux = import ../home/modules/agents/pi-extensions {
    pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
    sourceRoot = inputs.self + "/home/modules/agents";
  };

  flake.themes.gruber-darker = inputs.self + "/home/modules/agents/themes/gruber-darker.json";

  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    sourceRoot = inputs.self + "/home/modules/agents";
    i3Module = inputs.self + "/home/modules/i3";
    localPackages = import ../home/modules/agents/packages.nix {inherit pkgs sourceRoot;};
    piExtensions = import ../home/modules/agents/pi-extensions {inherit pkgs sourceRoot;};
    agentPackages =
      localPackages
      // {
        inherit (pkgs) agent-browser claude-code codex opencode;
        pi = inputs.pi.packages.${system}.default;
      };
    homeModule = import ../home/modules/agents/module.nix {
      piModule = inputs.pi.homeModules.default;
      inherit sourceRoot;
    };
  in {
    packages = agentPackages;
    checks = import ../home/modules/agents/checks.nix {
      inherit pkgs homeModule i3Module;
      inherit sourceRoot;
      scufrisModule = inputs.scufris.homeModules.default;
      scufrisRevision = inputs.scufris.rev;
      packages = agentPackages;
      extensions = piExtensions;
      home-manager = inputs.home-manager;
    };
  };
}
