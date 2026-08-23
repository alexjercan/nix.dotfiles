{pkgs, ...}: {
  home.packages = with pkgs; [
    ast-grep
    cmake
    gh
    graphviz
    llama-cpp
    openssl
    tatr
    nodejs
  ];
}
