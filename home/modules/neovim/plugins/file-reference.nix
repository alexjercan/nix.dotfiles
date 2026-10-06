{...}: {
  programs.nixvim.extraConfigLua = ''
    local function copy_file_reference(visual)
      local name = vim.api.nvim_buf_get_name(0)
      if name == "" then
        vim.notify("No filename to copy", vim.log.levels.WARN)
        return
      end

      local path = vim.fn.fnamemodify(name, ":.")
      local first = vim.fn.line(".")
      local last = first
      if visual then
        last = vim.fn.line("v")
        first, last = math.min(first, last), math.max(first, last)
      end

      local reference = path .. ":" .. first
      if visual then
        reference = reference .. "-" .. last
      end
      vim.fn.setreg("+", reference)
      vim.notify("Copied " .. reference)
    end

    vim.keymap.set("n", "<leader>n", function() copy_file_reference(false) end, { desc = "Copy file and line" })
    vim.keymap.set("x", "<leader>n", function() copy_file_reference(true) end, { desc = "Copy file and line range" })
  '';
}
