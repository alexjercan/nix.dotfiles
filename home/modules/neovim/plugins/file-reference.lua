local function netrw_locations(first, last)
  if (vim.b.netrw_liststyle or vim.w.netrw_liststyle or vim.g.netrw_liststyle or 0) ~= 0 then
    vim.notify("Use netrw thin listing (i) for Pi file comments", vim.log.levels.WARN)
    return
  end
  local directory = vim.b.netrw_curdir
  if not directory or directory:match("^%a+://") then
    vim.notify("Pi comments require a local netrw directory", vim.log.levels.WARN)
    return
  end
  local locations = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, first - 1, last, false)) do
    if line ~= "" and not line:match('^"') then
      local entry = line:gsub("\t %-%->.*$", ""):gsub("[@*]$", "")
      local path = vim.fs.normalize(directory .. "/" .. entry)
      if vim.uv.fs_stat(path) then
        table.insert(locations, (vim.fn.isdirectory(path) == 1 and "Folder: " or "File: ") .. path)
      end
    end
  end
  if #locations == 0 then
    vim.notify("No files or folders selected", vim.log.levels.WARN)
    return
  end
  return table.concat(locations, "\n")
end

local function prompt_pi(visual, btw)
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

  local location
  local reference
  if vim.bo.filetype == "netrw" then
    location = netrw_locations(first, last)
    if not location then
      return
    end
    reference = "Files/folders: " .. (last - first + 1)
  else
    location = name .. ":" .. first .. (visual and ("-" .. last) or "")
    reference = path .. ":" .. first .. (visual and ("-" .. last) or "")
  end
  local project = require("pi_queue").project()
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
    title = (btw and "BTW: " or "Queue: ") .. reference,
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
    local message = text .. "\n\n" .. location
    if btw then
      require("pi_btw").ask(message)
    else
      require("pi_queue").add(project, message)
    end
  end)

  vim.keymap.set({ "i", "n" }, "<Esc>", close, { buffer = buf })
  vim.cmd.startinsert()
end

vim.keymap.set("n", "<leader>n", function() prompt_pi(false) end, { desc = "Queue Pi comment" })
vim.keymap.set("x", "<leader>n", function() prompt_pi(true) end, { desc = "Queue Pi comment on selection" })
vim.keymap.set("n", "<leader>q", function() require("pi_queue").open() end, { desc = "Open Pi comment queue" })
vim.keymap.set("n", "<leader>b", function() prompt_pi(false, true) end, { desc = "Ask Pi a read-only side question" })
vim.keymap.set("x", "<leader>b", function() prompt_pi(true, true) end, { desc = "Ask Pi about selection (read-only)" })
