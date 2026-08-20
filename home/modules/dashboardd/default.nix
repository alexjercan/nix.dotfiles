{
  config,
  inputs,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  todayWidget = inputs.today.packages.${system}.dashboardd-widget;
  widgetEnvironment = {
    DEN_PATH = "${config.home.homeDirectory}/personal/the-den";
    MACROS_DATABASE = "${config.home.homeDirectory}/.local/share/nvim/macros.csv";
  };
in {
  imports = [inputs.dashboardd.homeManagerModules.default];

  xdg.configFile."dashboardd/config.toml".source = ./config.toml;

  programs.dashboardd = {
    enable = true;
    port = 8000;
    widgetPackages = [todayWidget];
    environment = widgetEnvironment // {
      DASHBOARDD_HOST = "0.0.0.0";
    };
  };

  programs.dashboardd-desktop = {
    enable = true;
    widgetPackages = [todayWidget];
    environment = widgetEnvironment;
  };
}
