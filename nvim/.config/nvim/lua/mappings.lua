-- Keybindings — follows ~/lab/notes/projects/keymaps.md
-- Namespaces: f find · s search · r replace · w window · c copy · x transforms · g git
-- Ctrl = editor structural · Alt = owned by the multiplexer (zellij) · Leader = Space

local map = vim.keymap.set

-- fzf-lua lazy handle
local fzf = setmetatable({}, {
  __index = function(_, k) return require("fzf-lua")[k] end,
})

--------------------------------------------------------------------------------
-- Files & app (Ctrl)
--------------------------------------------------------------------------------
map("n", "<C-s>", ":w<CR>", { desc = "save" })
map("i", "<C-s>", "<Esc>:w<CR>", { desc = "save" })
map("n", "<C-q>", ":qa<CR>", { desc = "quit all" })
map("n", "<C-x>q", ":qa!<CR>", { desc = "quit (force)" })

-- C-x x: close current buffer; C-x k: keep current, close all others
map("n", "<C-x>x", function()
  local current_buf = vim.api.nvim_get_current_buf()
  local buftype = vim.bo.buftype

  -- If this is the only buffer in the tab, open a blank one first
  local tab_bufs = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_loaded(buf) then tab_bufs[buf] = true end
  end
  if vim.tbl_count(tab_bufs) == 1 then vim.cmd("enew") end

  if buftype == "terminal" then
    vim.cmd("bdelete! " .. current_buf)
  else
    vim.cmd("bdelete " .. current_buf)
  end
end, { desc = "close current buffer" })

map("n", "<C-x>k", function()
  local current_buf = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current_buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, {})
    end
  end
end, { desc = "keep current buffer, close others" })

--------------------------------------------------------------------------------
-- Windows (Ctrl) — split nav + resize (Ctrl-hjkl; zellij owns Alt-hjkl for panes)
--------------------------------------------------------------------------------
map("n", "<C-h>", "<C-w>h", { desc = "window left" })
map("n", "<C-l>", "<C-w>l", { desc = "window right" })
map("n", "<C-j>", "<C-w>j", { desc = "window down" })
map("n", "<C-k>", "<C-w>k", { desc = "window up" })
map("n", "<C-Up>", ":resize +2<CR>", { desc = "height +" })
map("n", "<C-Down>", ":resize -2<CR>", { desc = "height -" })
map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "width -" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "width +" })

--------------------------------------------------------------------------------
-- Motion (bare + Ctrl)
--------------------------------------------------------------------------------
map("n", "n", "nzzzv", { desc = "next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "prev search result (centered)" })
map("n", "<C-d>", "<C-d>zz", { desc = "half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "half page up (centered)" })
map("n", "J", "mzJ`z", { desc = "join lines, keep cursor" })
map("v", "<", "<gv", { desc = "indent left and reselect" })
map("v", ">", ">gv", { desc = "indent right and reselect" })

-- Black-hole register (don't clobber yank)
map("n", "c", '"_c', { noremap = true })
map("n", "C", '"_C', { noremap = true })
map("n", "x", '"_x', { noremap = true })
map("n", "X", '"_X', { noremap = true })

-- Clear search highlights
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "clear highlights" })

--------------------------------------------------------------------------------
-- Yazi (file manager)
--------------------------------------------------------------------------------
map("n", "-", ":Yazi<CR>", { desc = "yazi at current file" })
map("n", "<leader>-", ":Yazi cwd<CR>", { desc = "yazi in cwd" })

--------------------------------------------------------------------------------
-- f — Find (pickers)
--------------------------------------------------------------------------------
-- Root picker: cwd pinned first, curated roots, then zoxide frecency dirs.
local function root_picker(action)
  local home = vim.uv.os_homedir()
  local roots = {
    vim.fn.getcwd(),
    home,
  }
  for _, dir in ipairs(vim.fn.systemlist("zoxide query -l")) do
    table.insert(roots, dir)
  end

  local seen, list = {}, {}
  for _, dir in ipairs(roots) do
    dir = vim.fs.normalize(dir or "")
    if dir ~= "" and not seen[dir] then
      seen[dir] = true
      table.insert(list, dir)
    end
  end

  fzf.fzf_exec(list, {
    prompt = (action == "grep" and "Grep in ❯ " or "Find in ❯ "),
    actions = {
      ["default"] = function(selected)
        local dir = selected and selected[1]
        if not dir then return end
        if action == "grep" then
          Snacks.picker.grep({ cwd = dir })
        else
          Snacks.picker.files({ cwd = dir })
        end
      end,
    },
  })
end

-- ff/fg: search cwd directly, no folder prompt (mirrors shell fdi/rgi).
map("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "find files (cwd)" })
map("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "find grep (cwd)" })
-- fF/fG: pick a root first (cwd + curated dirs + zoxide), then search there.
map("n", "<leader>fF", function() root_picker("files") end, { desc = "find files (pick root)" })
map("n", "<leader>fG", function() root_picker("grep") end, { desc = "find grep (pick root)" })
map("n", "<leader>fl", function()
  local dir = vim.uv.os_homedir() .. "/lab"
  if vim.fn.isdirectory(dir) == 0 then
    vim.notify("~/lab not found", vim.log.levels.WARN)
    return
  end
  Snacks.picker.files({ cwd = dir })
end, { desc = "find files in ~/lab" })
map("n", "<leader>fo", function() Snacks.picker.recent() end, { desc = "recent files" })
map("n", "<leader>fu", function() Snacks.picker.buffers({ format = "file" }) end, { desc = "open buffers" })
map("n", "<leader>fh", function() Snacks.picker.help() end, { desc = "help tags" })
map("n", "<leader>fk", function() Snacks.picker.keymaps() end, { desc = "keymaps" })

--------------------------------------------------------------------------------
-- s — Search (grep)
--------------------------------------------------------------------------------
map("n", "<leader>sl", function()
  local dir = vim.uv.os_homedir() .. "/lab"
  if vim.fn.isdirectory(dir) == 0 then
    vim.notify("~/lab not found", vim.log.levels.WARN)
    return
  end
  Snacks.picker.grep({ cwd = dir })
end, { desc = "grep in ~/lab" })
map("n", "<leader>sc", function() Snacks.picker.lines() end, { desc = "search current buffer" })

-- r — Replace: see plugins/grug-far.lua (<leader>rr word/selection, <leader>rR blank)

--------------------------------------------------------------------------------
-- w — Window (splits, wrap, number toggles)
--------------------------------------------------------------------------------
map("n", "<leader>wv", ":vsplit<CR>", { desc = "split vertically" })
map("n", "<leader>ws", ":split<CR>", { desc = "split horizontally" })
map("n", "<leader>wr", function()
  vim.wo.wrap = not vim.wo.wrap
  print("Wrap is now " .. (vim.wo.wrap and "ON" or "OFF"))
end, { desc = "toggle wrap" })
map("n", "<leader>wn", "<cmd>set nu!<CR>", { desc = "toggle line numbers" })
map("n", "<leader>wN", "<cmd>set rnu!<CR>", { desc = "toggle relative numbers" })

--------------------------------------------------------------------------------
-- c — Copy
--------------------------------------------------------------------------------
map("n", "<leader>cc", ':let @+ = expand("%:p")<CR>', { silent = true, desc = "copy file path (absolute)" })
map("n", "<leader>cn", ':let @+ = expand("%:t")<CR>', { silent = true, desc = "copy file name" })
map("n", "<leader>cd", function()
  local cwd = vim.fn.getcwd()
  vim.fn.setreg("+", cwd)
  print("Copied current directory: " .. cwd)
end, { desc = "copy cwd" })

--------------------------------------------------------------------------------
-- x — Transforms (visual)
--------------------------------------------------------------------------------
local function csv_to_md()
  local lines = vim.fn.getline("'<", "'>")
  local result = {}
  local is_header = true
  for _, line in ipairs(lines) do
    if line == "" then goto continue end
    local row = "| " .. line:gsub(",", " | ") .. " |"
    table.insert(result, row)
    if is_header then
      table.insert(result, (row:gsub("[^|]+", " --- ")))
      is_header = false
    end
    ::continue::
  end
  vim.api.nvim_win_set_cursor(0, { vim.fn.line("'>"), 0 })
  vim.api.nvim_put(result, "l", true, true)
end

local function md_to_csv()
  local lines = vim.fn.getline("'<", "'>")
  local result = {}
  for _, line in ipairs(lines) do
    if line == "" or line:match("^%s*|%s*[-:]+[-| :]*$") then goto continue end
    local cells = {}
    for cell in (line .. "|"):gmatch("%s*|%s*(.-)%s*|") do
      table.insert(cells, cell)
    end
    if #cells > 0 then table.insert(result, table.concat(cells, ",")) end
    ::continue::
  end
  vim.api.nvim_win_set_cursor(0, { vim.fn.line("'>"), 0 })
  vim.api.nvim_put(result, "l", true, true)
end

local transforms = {
  { name = "CSV → Markdown table", fn = csv_to_md },
  { name = "Markdown table → CSV", fn = md_to_csv },
}

map("v", "<leader>xx", function()
  local names = {}
  local by_name = {}
  for _, t in ipairs(transforms) do
    table.insert(names, t.name)
    by_name[t.name] = t.fn
  end
  fzf.fzf_exec(names, {
    prompt = "Transform ❯ ",
    actions = {
      ["default"] = function(selected)
        local t = selected and by_name[selected[1]]
        if t then t() end
      end,
    },
  })
end, { desc = "transform picker" })

--------------------------------------------------------------------------------
-- g — Git  (<leader>gg = LazyGit, defined in plugins/lazygit.lua)
--------------------------------------------------------------------------------
map("n", "<leader>gc", function() Snacks.picker.git_log() end, { desc = "git commits" })
map("n", "<leader>gs", function() Snacks.picker.git_status() end, { desc = "git status" })

--------------------------------------------------------------------------------
-- Single-key leaders
--------------------------------------------------------------------------------
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })
