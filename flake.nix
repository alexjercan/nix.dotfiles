{
  description = "My NixOS/home-manager configuration.";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
        url = "github:nix-community/nix-index-database";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixvim,
    nix-index-database,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;

      config = {
        allowUnfree = true;
      };
    };
  in {
    nixosConfigurations.main = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
      ];
    };

    homeConfigurations.alex = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs.nixvim = nixvim;

      modules = [
        ./home.nix
        nix-index-database.homeModules.default
      ];
    };
  };
}
