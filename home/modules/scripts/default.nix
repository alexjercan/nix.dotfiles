{...}: let
  rootPath = "~/personal/the-den";
in {
  imports = [
    ./today.nix
    ./daily.nix
    ./sprout.nix
  ];

  today = {
    enable = true;
    inherit rootPath;
  };

  daily = {
    enable = true;
    inherit rootPath;
  };
}
