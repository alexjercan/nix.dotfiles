# Audio / video / graphics creation and playback.
{pkgs, ...}: {
  home.packages = with pkgs; [
    audacity
    blender
    davinci-resolve
    ffmpeg
    gimp
    inkscape
    kdePackages.kdenlive
    mpv
    mupdf
    obs-studio
  ];
}
