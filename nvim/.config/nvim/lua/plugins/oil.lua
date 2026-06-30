return {
  "stevearc/oil.nvim",
  name = "oil",
  lazy = true,
  keys = {
    -- { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
  },
  cmd = "Oil",
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require("oil").setup()
  end
}
