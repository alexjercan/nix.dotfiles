{pkgs, ...}: {
  home.packages = with pkgs; [
    (chromium.override {commandLineArgs = "--enable-features=Vulkan --use-angle=vulkan --enable-unsafe-webgpu";})
    discord
    firefox
    libreoffice-qt
  ];
}
