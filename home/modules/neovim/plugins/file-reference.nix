{...}: {
  programs.nixvim = {
    extraConfigLua = builtins.readFile ./file-reference.lua;
    extraFiles."lua/pi_nvim_bridge.lua".source = ./pi-bridge.lua;
    extraFiles."lua/pi_queue.lua".source = ./pi-queue.lua;
    extraFiles."lua/pi_btw.lua".source = ./btw.lua;
  };
}
