return {
  "folke/which-key.nvim",
  lazy = true,
  event = "VeryLazy",
  keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g" },
  cmd = "WhichKey",
  opts = function()
    return {}
  end
}
