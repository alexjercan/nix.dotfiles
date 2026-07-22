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

    # Deliberately NOT `follows`-ing nixpkgs: nixvim is tested against its own
    # pinned nixpkgs revision, and upstream explicitly recommends against
    # `inputs.nixpkgs.follows` ("you opt out of guarantees provided by these
    # tests"). Leaving it un-followed pulls a second nixpkgs into the eval but
    # keeps nixvim on the revision it was validated against.
    nixvim = {
      url = "github:nix-community/nixvim";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
    scufris = {
      url = "github:alexjercan/scufris";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./flake);
}
