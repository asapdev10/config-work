-- lua/plugins/render-markdown.lua
return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons", -- or 'nvim-mini/mini.icons'
  },
  ft = { "markdown" }, -- lazy-load only for markdown files
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    -- Rendered in normal, command, and terminal modes; raw in insert/visual
    render_modes = { "n", "c", "t" },

    heading = {
      -- Full-width colored background per heading level
      width = "full",
      border = false, -- set true for lines above/below headings
    },

    code = {
      style = "full",   -- background + language icon + border
      width = "full",
      border = "hide",  -- "thin" or "thick" are alternatives
    },

    bullet = {
      icons = { "●", "○", "◆", "◇" }, -- per-nesting-level icons
    },

    checkbox = {
      unchecked = { icon = "󰄱 " },
      checked   = { icon = "󰱒 " },
    },

    pipe_table = {
      preset = "round", -- "heavy" | "double" | "round" | "none"
    },
  },
}
