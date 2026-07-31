{pkgs, ...}: {
  home.packages = with pkgs; [
    audacity
    blender
    ffmpeg
    gimp
    inkscape
    kdePackages.kdenlive
    mpv
    mupdf
    obs-studio
  ];
}
