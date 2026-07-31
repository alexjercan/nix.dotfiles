{pkgs, ...}: {
  home.packages = with pkgs; [
    ast-grep
    cmake
    gh
    graphviz
    llama-cpp
    macros
    openssl
    tatr
  ];
}
