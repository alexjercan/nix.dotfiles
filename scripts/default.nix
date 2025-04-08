{...}: {
  imports = [
    ./today.nix
    ./daily.nix
  ];

  today = {
    enable = true;
    rootPath = "~/personal/the-den/";
  };

  daily = {
    enable = true;
    rootPath = "~/personal/the-den/";
  };
}
