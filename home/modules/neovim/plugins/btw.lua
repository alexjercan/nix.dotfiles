local M = {}

function M.show(question, answer)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split("# BTW\n\n" .. question .. "\n\n---\n\n" .. answer, "\n", { plain = true }))
  vim.bo[buf].modifiable = false
  local width = math.max(1, math.min(100, vim.o.columns - 4))
  local height = math.max(1, math.min(30, vim.o.lines - 6))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    style = "minimal",
    border = "rounded",
    title = "BTW: read-only answer (q close)",
  })
  vim.wo[win].wrap = true
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close, { buffer = buf })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf })
end

function M.ask(question)
  require("pi_nvim_bridge").ask(question, function(answer)
    M.show(question, answer)
  end)
end

return M
