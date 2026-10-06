local M = {}

local function tmux(args)
  local output = vim.fn.systemlist(vim.list_extend({ "tmux" }, args))
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return output
end

local function target_socket()
  if not vim.env.TMUX_PANE then
    return nil, "Neovim is not in tmux"
  end
  local current = tmux({ "display-message", "-p", "-t", vim.env.TMUX_PANE, "#{session_id}" })
  if not current or not current[1] or current[1] == "" then
    return nil, "Cannot find the current tmux session"
  end
  local panes = tmux({ "list-panes", "-t", current[1] .. ":2", "-F", "#{pane_id}" })
  if not panes then
    return nil, "No tmux window 2 in this session"
  end

  local sockets = {}
  for _, pane in ipairs(panes) do
    local option = tmux({ "show-options", "-p", "-v", "-t", pane, "@pi_nvim_socket" })
    if option and option[1] and option[1] ~= "" then
      table.insert(sockets, option[1])
    end
  end
  if #sockets ~= 1 then
    return nil, #sockets == 0 and "No Pi bridge in tmux window 2" or "Multiple Pi bridges in tmux window 2"
  end
  return sockets[1]
end

local function progress()
  local width = math.min(26, math.max(1, vim.o.columns - 4))
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = 1,
    row = math.max(0, vim.o.lines - 5),
    col = math.max(0, vim.o.columns - width - 2),
    style = "minimal",
    border = "rounded",
    focusable = false,
    title = "Pi",
  })
  local timer = vim.uv.new_timer()
  local frames = { "|", "/", "-", "\\" }
  local frame = 0
  local state = "sending"
  local function draw()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    frame = frame % #frames + 1
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { frames[frame] .. " " .. state })
  end
  draw()
  timer:start(120, 120, vim.schedule_wrap(draw))
  return function(next_state)
    if next_state then
      state = next_state
      draw()
      return
    end
    timer:stop()
    timer:close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
end

function M.send(message)
  local path, err = target_socket()
  if not path then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local set_progress = progress()
  local pipe = vim.uv.new_pipe(false)
  local finished = false
  local buffer = ""
  local id = tostring(vim.uv.hrtime())
  local function finish(error_message)
    if finished then
      return
    end
    finished = true
    pipe:close()
    set_progress()
    if error_message then
      vim.notify(error_message, vim.log.levels.ERROR)
    else
      vim.notify("Pi finished")
    end
  end

  pipe:connect(path, function(connect_error)
    if connect_error then
      vim.schedule(function() finish("Cannot connect to Pi: " .. connect_error) end)
      return
    end
    pipe:read_start(function(read_error, chunk)
      if read_error or not chunk then
        vim.schedule(function() finish(read_error or "Pi bridge disconnected") end)
        return
      end
      buffer = buffer .. chunk
      while true do
        local newline = buffer:find("\n", 1, true)
        if not newline then
          break
        end
        local line = buffer:sub(1, newline - 1)
        buffer = buffer:sub(newline + 1)
        local ok, response = pcall(vim.json.decode, line)
        vim.schedule(function()
          if finished then
            return
          end
          if not ok or type(response) ~= "table" or (response.id and response.id ~= id) then
            finish("Invalid Pi bridge response")
          elseif response.status == "running" or response.status == "queued" then
            set_progress(response.status)
          elseif response.status == "done" then
            finish()
          elseif response.status == "error" then
            finish(response.error or "Pi rejected the prompt")
          else
            finish("Unknown Pi bridge response")
          end
        end)
      end
    end)
    pipe:write(vim.json.encode({ id = id, message = message }) .. "\n")
  end)
end

return M
