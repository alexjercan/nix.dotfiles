{inputs, ...}: {
  programs.nixvim = {
    imports = [inputs.stack-lang-c.nixvimModules.default];

    stack = {
      syntax.enable = true;
      lsp.enable = true;
      lsp.config.root_markers = [".git"];
    };
  };
}
