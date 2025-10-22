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
            local rustAnalyzerSettings = vim.lsp.get_clients({ name = "rust_analyzer" })[1].config.settings
            if rustAnalyzerSettings ~= nil then
              rustAnalyzerSettings["rust-analyzer"].cargo.features = opts.fargs
              vim.lsp.enable('rust_analyzer', false)
              vim.lsp.config('rust_analyzer', { settings = rustAnalyzerSettings })
              vim.lsp.enable('rust_analyzer')
            end
          end,
          { desc = 'Set rust-analyzer features to the provided list', nargs = '*' }
        )

        vim.api.nvim_create_user_command(
          'FtList',
          function(opts)
            local rustAnalyzerSettings = vim.lsp.get_clients({ name = "rust_analyzer" })[1].config.settings
            if rustAnalyzerSettings == 'all' then
              print("all features enabled")
            elseif rustAnalyzerSettings ~= nil then
              print('['..table.concat(rustAnalyzerSettings["rust-analyzer"].cargo.features, ', ')..']')
            end
          end,
          { desc = "List rust-analyzer active features.", nargs = 0 }
        )
    '';
  };
}
