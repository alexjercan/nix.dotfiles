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

    # Agent CLIs ship releases faster than nixpkgs packages them. The
    # `shared-nixpkgs` overlay adds a `pkgs.llm-agents` namespace instead of
    # shadowing the nixpkgs attributes, so both sets stay reachable.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tatr = {
      url = "github:alexjercan/tatr/v3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./flake);
}
