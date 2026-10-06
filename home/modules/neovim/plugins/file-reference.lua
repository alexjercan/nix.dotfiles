local function prompt_pi(visual)
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
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "prompt"
  vim.fn.prompt_setprompt(buf, "Prompt: ")

  local width = math.max(1, math.min(80, vim.o.columns - 4))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = 1,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - 3) / 2),
    style = "minimal",
    border = "rounded",
    title = reference,
    title_pos = "center",
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.fn.prompt_setcallback(buf, function(text)
    close()
    text = vim.trim(text)
    if text == "" then
      return
    end
    local location = name .. ":" .. first
    if visual then
      location = location .. "-" .. last
    end
    require("pi_nvim_bridge").send(text .. "\n\n" .. location)
  end)

  vim.keymap.set({ "i", "n" }, "<Esc>", close, { buffer = buf })
  vim.cmd.startinsert()
end

vim.keymap.set("n", "<leader>n", function() prompt_pi(false) end, { desc = "Prompt Pi about file and line" })
vim.keymap.set("x", "<leader>n", function() prompt_pi(true) end, { desc = "Prompt Pi about file and line range" })
