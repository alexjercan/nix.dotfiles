{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  dashboardd = inputs.dashboardd.packages.${system}.dashboardd;
  todayWidget = inputs.today.packages.${system}.dashboardd-widget;
  widgetPath = lib.makeSearchPath "share/dashboardd/widgets" [
    dashboardd
    todayWidget
  ];
in {
  home.packages = [dashboardd];

  systemd.user.services.dashboardd = {
    Unit = {
      Description = "Local dashboard";
      After = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${dashboardd}/bin/dashboardd";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [
        "DASHBOARDD_PORT=7331"
        "DASHBOARDD_WIDGET_PATH=${widgetPath}"
        "DEN_PATH=${config.home.homeDirectory}/personal/the-den"
      ];
    };

    Install.WantedBy = ["default.target"];
  };
}
