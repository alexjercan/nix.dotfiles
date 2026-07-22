# Development tooling and personal CLIs.
{pkgs, ...}: {
  home.packages = with pkgs; [
    ast-grep
    cmake
    gh
    graphviz
    llama-cpp
    macros
    openssl
    poetry
    tatr
  ];
}
