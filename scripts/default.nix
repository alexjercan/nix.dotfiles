{...}: let
  rootPath = "~/personal/the-den";
in {
  imports = [
    ./today.nix
    ./daily.nix
    ./weight.nix
    ./note.nix
  ];

  today = {
    enable = true;
    inherit rootPath;
  };

  daily = {
    enable = true;
    inherit rootPath;
  };

  weight = {
    enable = true;
    inherit rootPath;
  };

  note = {
    enable = true;
    inherit rootPath;
  };
}
