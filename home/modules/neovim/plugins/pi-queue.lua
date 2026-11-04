local M = {}
local queues = {}

function M.project()
  local cwd = vim.fn.getcwd()
  return vim.fs.root(cwd, ".git") or cwd
end

local function queue(project)
  if queues[project] then
    return queues[project]
  end
  local directory = vim.fn.stdpath("state") .. "/pi-queues"
  vim.fn.mkdir(directory, "p", 448)
  local path = directory .. "/" .. vim.fn.sha256(project) .. ".md"
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "pi-queue://" .. project)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  if vim.fn.filereadable(path) == 1 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.readfile(path))
  end
  local state = { buf = buf }
  queues[project] = state

  function state.save()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local temporary = path .. "." .. vim.fn.getpid() .. ".tmp"
    local ok, err = pcall(function()
      vim.fn.writefile(lines, temporary)
      vim.fn.setfperm(temporary, "rw-------")
      assert(vim.uv.fs_rename(temporary, path))
    end)
    if not ok then
      vim.notify("Cannot save Pi queue: " .. tostring(err), vim.log.levels.ERROR)
    end
    return ok
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave" }, {
    buffer = buf,
    callback = function() state.save() end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", { callback = function() state.save() end })
  vim.keymap.set("n", "<leader>n", function()
    if state.sending then
      vim.notify("Pi queue is already sending", vim.log.levels.WARN)
      return
    end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local message = table.concat(lines, "\n")
    if vim.trim(message) == "" then
      vim.notify("Pi queue is empty")
      return
    end
    if not state.save() then
      return
    end
    state.sending = true
    require("pi_nvim_bridge").send(message, function()
      local current = vim.api.nvim_buf_get_lines(buf, 0, #lines, false)
      if vim.deep_equal(current, lines) then
        vim.api.nvim_buf_set_lines(buf, 0, #lines, false, {})
        state.save()
      else
        vim.notify("Pi accepted the draft. Queue changed during send; kept the edited draft.", vim.log.levels.WARN)
      end
    end, function() state.sending = false end)
  end, { buffer = buf, desc = "Send Pi queue" })
  return state
end

function M.add(project, message)
  local state = queue(project)
  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  if #lines == 1 and lines[1] == "" then
    lines = {}
  else
    table.insert(lines, "")
    table.insert(lines, "---")
    table.insert(lines, "")
  end
  vim.list_extend(lines, vim.split(message, "\n", { plain = true }))
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  if state.save() then
    vim.notify("Comment queued for Pi")
  end
end

function M.open()
  local state = queue(M.project())
  for _, win in ipairs(vim.fn.win_findbuf(state.buf)) do
    vim.api.nvim_set_current_win(win)
    return
  end
  local width = math.max(1, math.min(100, vim.o.columns - 4))
  local height = math.max(1, math.min(30, vim.o.lines - 6))
  local win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    style = "minimal",
    border = "rounded",
    title = "Pi queue: <leader>n send, q close",
  })
  vim.wo[win].wrap = true
  vim.keymap.set("n", "q", function()
    if state.save() and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = state.buf, desc = "Close Pi queue" })
end

return M
