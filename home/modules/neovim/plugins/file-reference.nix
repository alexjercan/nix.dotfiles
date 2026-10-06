{...}: {
  programs.nixvim.extraConfigLua = builtins.readFile ./file-reference.lua;
}
