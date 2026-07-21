{
  description = "My NixOS/home-manager configuration.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tatr = {
      url = "github:alexjercan/tatr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    today = {
      url = "github:alexjercan/today";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    macros-nvim = {
      url = "github:alexjercan/macros.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The local scufris is now the source of truth (replaces the old
    # github:alexjercan/scufris-bot); published at github:alexjercan/scufris.
    scufris = {
      url = "github:alexjercan/scufris";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./flake);
}
