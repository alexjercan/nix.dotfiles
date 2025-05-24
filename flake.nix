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
    dzgui-nix = {
        url = "github:lelgenio/dzgui-nix";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixvim,
    ...
  } @ inputs: let
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
      extraSpecialArgs.dzgui = inputs.dzgui-nix;

      modules = [
        ./home.nix
      ];
    };
  };
}
