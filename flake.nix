{
  description = "My NixOS/home-manager configuration.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dzgui-nix = {
      # url of this repository, may change in the future
      url = "github:lelgenio/dzgui-nix";
      # save storage by not having duplicates of packages
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
        inputs.dzgui-nix.nixosModules.default
        {programs.dzgui.enable = true;}
      ];
    };

    homeConfigurations.alex = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs.nixvim = nixvim;

      modules = [
        ./home.nix
      ];
    };
  };
}
