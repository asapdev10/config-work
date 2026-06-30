return {
  "j-morano/buffer_manager.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = { { "=", desc = "buffer manager" } },
  config = function()
    require("buffer_manager").setup({ short_file_names = true })
    local bmui = require("buffer_manager.ui")
    vim.keymap.set("n", "=", bmui.toggle_quick_menu, { desc = "buffer manager" })
  end,
}
