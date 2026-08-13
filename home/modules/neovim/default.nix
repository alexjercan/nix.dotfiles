{nixvim, ...}: {
  imports = [
    nixvim.homeModules.nixvim
    ./remap.nix
    ./set.nix
    ./autocmd.nix
    ./extra
    ./plugins
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimdiffAlias = true;

    viAlias = true;
    vimAlias = true;

    extraConfigLua = ''
      vim.api.nvim_create_user_command(
        'FtSet',
        function(opts)
          local client = vim.lsp.get_clients({ name = "rust_analyzer" })[1]
          if client == nil then
            return
          end
          local settings = client.config.settings or {}
          settings["rust-analyzer"] = settings["rust-analyzer"] or {}
          settings["rust-analyzer"].cargo = settings["rust-analyzer"].cargo or {}
          settings["rust-analyzer"].cargo.features = opts.fargs
          vim.lsp.enable('rust_analyzer', false)
          vim.lsp.config('rust_analyzer', { settings = settings })
          vim.lsp.enable('rust_analyzer')
        end,
        { desc = 'Set rust-analyzer features to the provided list', nargs = '*' }
      )

      vim.api.nvim_create_user_command(
        'FtList',
        function(opts)
          local client = vim.lsp.get_clients({ name = "rust_analyzer" })[1]
          if client == nil then
            return
          end
          local settings = client.config.settings or {}
          local cargo = settings["rust-analyzer"] and settings["rust-analyzer"].cargo or {}
          if cargo.features == 'all' then
            print("all features enabled")
          else
            print('['..table.concat(cargo.features or {}, ', ')..']')
          end
        end,
        { desc = "List rust-analyzer active features.", nargs = 0 }
      )
    '';
  };
}
