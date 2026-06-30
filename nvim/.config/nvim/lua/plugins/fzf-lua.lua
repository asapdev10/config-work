return {
  "ibhagwan/fzf-lua",
  event = "VeryLazy",
  cmd = "FzfLua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {},
  config = function()
    require("fzf-lua").setup {
      -- Window configuration
      winopts = {
        height = 0.85,    -- 85% of screen height
        width = 0.99,     -- 95% of screen width (or use 1.0 for full width)
        row = 0.35,       -- vertical position (center)
        col = 0.50,       -- horizontal position (center)
        border = "rounded",
        preview = {
          border = "border",
          wrap = "nowrap",
          hidden = "nohidden",
          vertical = "down:45%",
          horizontal = "right:50%",
          layout = "flex",
          flip_columns = 120,
        },
      },
      -- Files configuration (using fd)
      files = {
        prompt = "Files❯ ",
        cmd = "fd --type f --hidden --follow --exclude .git",
        -- fd respects .gitignore by default
        -- Press alt-i in the picker to toggle .gitignore
        -- Press alt-h to toggle hidden files
      },
      -- Grep configuration (ripgrep with glob support)
      grep = {
        prompt = "Grep❯ ",
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob=!.git",
        -- Type '--glob *.ext' in search query to filter by file type
        -- Example: "function --glob *.lua" searches only .lua files
        -- Press ctrl-g to toggle between live_grep and grep modes
        -- Press alt-i to toggle .gitignore
      },
    }
  end
}
