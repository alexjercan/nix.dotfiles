import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

const plugins = resolve("home/modules/neovim/plugins");

test("BTW renders the question and answer in a scrollable read-only popup", () => {
  const temp = mkdtempSync(join(tmpdir(), "pi-btw-popup-test-"));
  const script = join(temp, "test.lua");
  writeFileSync(script, `
    local ok, err = xpcall(function()
      package.preload.pi_nvim_bridge = function() return { ask = function(question, callback)
        assert(question == "Why?\\n\\n/code.ts:4")
        callback("Because.\\n" .. string.rep("More detail\\n", 80))
      end } end
      local btw = dofile(${JSON.stringify(join(plugins, "btw.lua"))})
      btw.ask("Why?\\n\\n/code.ts:4")
      assert(vim.bo.filetype == "markdown")
      assert(vim.bo.modifiable == false)
      local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\\n")
      assert(text:find("Why?", 1, true))
      assert(text:find("Because.", 1, true))
      assert(vim.api.nvim_buf_line_count(0) > vim.api.nvim_win_get_height(0))
      vim.cmd("normal! G")
      assert(vim.fn.line(".") > 30)
      local win = vim.api.nvim_get_current_win()
      vim.fn.maparg("q", "n", false, true).callback()
      assert(not vim.api.nvim_win_is_valid(win))
    end, debug.traceback)
    if not ok then io.stderr:write(err); vim.cmd("cquit 1") end
  `);
  try {
    const result = spawnSync("nvim", ["--headless", "-u", "NONE", "-i", "NONE", "-c", `luafile ${script}`, "-c", "qa!"], { encoding: "utf8", timeout: 10000 });
    assert.equal(result.status, 0, result.stderr);
  } finally {
    rmSync(temp, { recursive: true, force: true });
  }
});

test("editable project queue persists, batches, and retains failed or edited drafts", () => {
  const temp = mkdtempSync(join(tmpdir(), "pi-queue-test-"));
  mkdirSync(join(temp, "project", ".git"), { recursive: true });
  mkdirSync(join(temp, "other"));
  const setup = `
    vim.g.mapleader = " "
    vim.opt.rtp:append(${JSON.stringify(temp)})
    package.preload.pi_queue = function() return dofile(${JSON.stringify(join(plugins, "pi-queue.lua"))}) end
    vim.cmd.cd(${JSON.stringify(join(temp, "project"))})
    local sent, accept, finish
    package.preload.pi_nvim_bridge = function() return { send = function(message, accepted, finished)
      sent, accept, finish = message, accepted, finished
    end } end
    local queue = require("pi_queue")
    local function send()
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do
        if map.lhs == " n" then map.callback(); return end
      end
      error("Missing send mapping")
    end
    local function text() return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\\n") end
  `;
  const run = (body: string) => {
    const script = join(temp, "test.lua");
    writeFileSync(script, `local ok, err = xpcall(function() ${setup}\n${body}\nend, debug.traceback)
      if not ok then io.stderr:write(err); vim.cmd("cquit 1") end`);
    const result = spawnSync("nvim", ["--headless", "-u", "NONE", "-i", "NONE", "-c", `luafile ${script}`, "-c", "qa!"], {
      encoding: "utf8", timeout: 10000, env: { ...process.env, XDG_STATE_HOME: join(temp, "state") },
    });
    assert.equal(result.status, 0, result.stderr);
  };
  try {
    run(`
      queue.add(queue.project(), "First comment\\n\\n/tmp/a.lua:3-5")
      queue.add(queue.project(), "Second comment\\n\\nFolder: /tmp/src")
      queue.open()
      assert(text():find("First comment", 1, true))
      assert(text():find("Second comment", 1, true))
      vim.api.nvim_buf_set_lines(0, 0, 1, false, { "Edited comment" })
    `);
    run(`
      queue.open()
      assert(text():find("Edited comment", 1, true), "Draft did not survive restart")
      local draft = text()
      send()
      assert(sent == draft, "Batch must be sent as one message")
      finish() -- Rejected/disconnected: keep draft.
      assert(text() == draft)
      send()
      queue.add(queue.project(), "Appended while sending")
      accept()
      finish()
      assert(not text():find("Edited comment", 1, true))
      assert(text():find("Appended while sending", 1, true))
      send()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Changed during send" })
      accept()
      finish()
      assert(text() == "Changed during send")
      send()
      accept()
      finish()
      assert(text() == "")
      vim.cmd.cd(${JSON.stringify(join(temp, "other"))})
      queue.open()
      assert(text() == "", "Queues must be project-specific")
    `);
  } finally {
    rmSync(temp, { recursive: true, force: true });
  }
});

test("line/range and netrw file/folder comments always queue without sending", () => {
  const temp = mkdtempSync(join(tmpdir(), "pi-reference-test-"));
  mkdirSync(join(temp, "folder"));
  writeFileSync(join(temp, "a file.lua"), "one\ntwo\nthree\n");
  const script = join(temp, "test.lua");
  writeFileSync(script, `
    local ok, err = xpcall(function()
      vim.g.mapleader = " "
      local queued, prompt, question
      package.preload.pi_queue = function() return {
        project = function() return "project" end,
        add = function(project, message) assert(project == "project"); queued = message end,
      } end
      package.preload.pi_nvim_bridge = function() error("Comments must not contact Pi directly") end
      package.preload.pi_btw = function() return { ask = function(message) question = message end } end
      vim.fn.prompt_setcallback = function(_, callback) prompt = callback end
      dofile(${JSON.stringify(join(plugins, "file-reference.lua"))})
      local function invoke(mode, key)
        vim.fn.maparg(" " .. key, mode, false, true).callback()
        prompt("Please review")
      end
      vim.cmd.edit(${JSON.stringify(join(temp, "a file.lua"))})
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      invoke("n", "n")
      assert(queued:find("a file.lua:2", 1, true))
      invoke("n", "b")
      assert(question:find("a file.lua:2", 1, true))
      assert(vim.fn.maparg(" m", "n") == "", "Old queue mapping must be removed")
      assert(vim.fn.maparg(" m", "x") == "", "Old visual queue mapping must be removed")
      vim.cmd("normal! ggVjj")
      invoke("x", "n")
      assert(queued:find("a file.lua:1-3", 1, true))
      vim.cmd("normal! ggVjj")
      invoke("x", "b")
      assert(question:find("a file.lua:1-3", 1, true))
      vim.cmd("normal! \\27")
      vim.cmd("enew!")
      vim.api.nvim_buf_set_name(0, ${JSON.stringify(temp)})
      vim.bo.filetype = "netrw"
      vim.b.netrw_curdir = ${JSON.stringify(temp)}
      vim.b.netrw_liststyle = 0
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a file.lua", "folder/" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      invoke("n", "n")
      assert(queued == "Please review\\n\\nFile: " .. ${JSON.stringify(join(temp, "a file.lua"))})
      vim.cmd("normal! ggVj")
      invoke("x", "n")
      assert(queued:find("File: " .. ${JSON.stringify(join(temp, "a file.lua"))}, 1, true))
      assert(queued:find("Folder: " .. ${JSON.stringify(join(temp, "folder"))}, 1, true))
    end, debug.traceback)
    if not ok then io.stderr:write(err); vim.cmd("cquit 1") end
  `);
  try {
    const result = spawnSync("nvim", ["--headless", "-u", "NONE", "-i", "NONE", "-c", `luafile ${script}`, "-c", "qa!"], { encoding: "utf8", timeout: 10000 });
    assert.equal(result.status, 0, result.stderr);
  } finally {
    rmSync(temp, { recursive: true, force: true });
  }
});
