-- ~/.config/nvim/lua/plugins/bigfile.lua
return {
  "LunarVim/bigfile.nvim",
  event = "BufReadPre",  -- Ensures the plugin loads before opening files
  opts = {
    filesize = 2,        -- Size in MiB; files larger than this trigger bigfile
    pattern = { "*" },   -- Apply to all files
    features = {
      "indent_blankline",
      "illuminate",
      "lsp",
      "treesitter",
      "syntax",
      "matchparen",
      "vimopts",
      "filetype",
    },
  },
}
