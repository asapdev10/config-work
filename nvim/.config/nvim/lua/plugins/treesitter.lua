-- nvim-treesitter, `main` branch (the rewritten API; `master` is deprecated on
-- Neovim 0.11+). Key differences from the old config:
--   * no `require("nvim-treesitter.configs").setup{}` — that module is gone
--   * no `ensure_installed` / `auto_install` / `highlight` opts table
--   * parsers are installed explicitly via `.install{}`
--   * highlighting is started per-buffer with core `vim.treesitter.start()`
-- Requires the `tree-sitter` CLI + a C compiler on PATH to build parsers
-- (installed via the Brewfile: `tree-sitter`; `cc` ships with Xcode CLT).
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,        -- main-branch docs advise against lazy-loading treesitter
  build = ":TSUpdate",
  config = function()
    -- Parsers to keep installed. markdown + markdown_inline are required by
    -- render-markdown.nvim; the rest match the old ensure_installed list.
    -- Add languages here (or run `:TSInstall <lang>`) — there is no auto_install
    -- on the main branch.
    require("nvim-treesitter").install({
      "typescript",
      "tsx",
      "xml",
      "markdown",
      "markdown_inline",
    })

    -- The main branch no longer manages a `highlight` module, so we start
    -- treesitter ourselves for any buffer whose filetype has an available
    -- parser. This also honours `vim.treesitter.language.register` mappings
    -- (e.g. xaml -> xml in vim_options.lua).
    local function start(buf)
      local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
      if lang and vim.treesitter.language.add(lang) then
        vim.treesitter.start(buf, lang)
      end
    end

    vim.api.nvim_create_autocmd("FileType", {
      callback = function(ev)
        start(ev.buf)
      end,
    })

    -- Apply to the buffer already open before this plugin finished loading.
    start(vim.api.nvim_get_current_buf())
  end,
}
