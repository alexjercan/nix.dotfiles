{...}: {
  programs.nixvim = {
    extraConfigLua = builtins.readFile ./file-reference.lua;
    extraFiles."lua/pi_nvim_bridge.lua".source = ./pi-bridge.lua;
  };
}
