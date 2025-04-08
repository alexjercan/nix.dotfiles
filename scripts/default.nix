{...}: {
  imports = [
    ./today.nix
  ];

  today = {
    enable = true;
    rootPath = "~/personal/the-den/";
  };
}
