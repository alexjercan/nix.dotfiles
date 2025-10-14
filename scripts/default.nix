{...}: {
  imports = [
    ./today.nix
    ./daily.nix
    ./weight.nix
  ];

  today = {
    enable = true;
    rootPath = "~/personal/the-den/";
  };

  daily = {
    enable = true;
    rootPath = "~/personal/the-den/";
  };

  weight = {
    enable = true;
    rootPath = "~/personal/the-den/";
  };
}
