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
      url = "github:alexjercan/tatr/v0.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-knowledge = {
      url = "git+file:///home/alex/personal/agent-knowledge?rev=7726b1cfc62201d53c4378bf18baff0e1d3f2ab8";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    today = {
      url = "github:alexjercan/today/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    macros-nvim = {
      url = "github:alexjercan/macros.nvim/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    scufris = {
      # DELIBERATELY tracking master instead of the release tag this normally
      # pins: `nixosModules.scufris-hostd` (the privileged host helper wired up
      # in hosts/nixos) exists only on master and does not ship until v0.2.0.
      # Re-pin to `github:alexjercan/scufris/v0.2.0` once that is released - a
      # floating input moves the whole app on every `nix flake update`, not just
      # the helper being tested.
      # Releases: https://github.com/alexjercan/scufris/releases
      url = "github:alexjercan/scufris";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./flake);
}
