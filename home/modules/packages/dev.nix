{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra
    ast-grep
    cmake
    gcc
    gh
    gnumake
    graphviz
    llama-cpp
    nodejs
    openssl
    python3
    tatr
  ];
}
