local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- Highlight when yanking (copying) text
autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = augroup,
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Open help windows on the right
autocmd("FileType", {
  group = augroup,
  pattern = "help",
  callback = function()
    vim.cmd.wincmd("L")
  end,
})

-- Restore cursor position when reopening a file
autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Filetype indentation: Python uses 4 spaces
autocmd("FileType", {
  group = augroup,
  pattern = { "python" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Filetype indentation: web/config filetypes use 2 spaces
autocmd("FileType", {
  group = augroup,
  pattern = { "javascript", "typescript", "json", "html", "css", "lua", "markdown" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- JSON: override <leader>gf to format with jq
autocmd("FileType", {
  group = augroup,
  pattern = "json",
  callback = function()
    vim.keymap.set("n", "<leader>gf", function()
      vim.cmd("%!jq .")
    end, { buffer = true, desc = "Format JSON with jq" })
  end,
})

-- Terminal: auto-close buffer when process exits cleanly
autocmd("TermClose", {
  group = augroup,
  callback = function()
    if vim.v.event.status == 0 then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(0) then
          vim.api.nvim_buf_delete(0, {})
        end
      end)
    end
  end,
})

-- Terminal: minimal UI on open
autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.statusline = " %-8{%v:lua.vim.fn.mode()%} %= %l:%c"
  end,
})

-- Quickfix: close on enter, no line numbers
autocmd("FileType", {
  group = augroup,
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR>:cclose<CR>", { buffer = true, noremap = true, silent = true })
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})

-- Auto-resize splits when Neovim window is resized
autocmd("VimResized", {
  group = augroup,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Ensure undo directory exists
local undodir = vim.uv.os_homedir() .. "/.vim/undodir"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end


autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.sidescroll = 0
    vim.opt_local.sidescrolloff = 0
    vim.opt_local.scrolloff = 0  -- also prevents vertical jump issues
  end,
})

-- Per-tab buffer history: record each buffer visit into vim.t.buf_history
autocmd("BufEnter", {
  group = augroup,
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local bt = vim.bo[buf].buftype
    -- Skip special/scratch buffers
    if bt == 'nofile' or bt == 'prompt' or bt == 'quickfix' then return end
    -- For file buffers, require a name
    if bt == '' and vim.api.nvim_buf_get_name(buf) == '' then return end

    local history = vim.t.buf_history or {}
    if history[#history] == buf then return end
    table.insert(history, buf)
    if #history > 50 then table.remove(history, 1) end
    vim.t.buf_history = history
  end,
})
