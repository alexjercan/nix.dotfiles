# GUI applications: browsers, chat, office.
{pkgs, ...}: {
  home.packages = with pkgs; [
    brave
    (chromium.override {commandLineArgs = "--enable-features=Vulkan --use-angle=vulkan --enable-unsafe-webgpu";})
    discord
    firefox
    libreoffice-qt
  ];
}
