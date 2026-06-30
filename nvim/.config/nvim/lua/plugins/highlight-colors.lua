return {
  'brenoprata10/nvim-highlight-colors',
  name = "nvim-highlight-colors",
  -- Previously loaded only as a blink.cmp dependency; trigger it on its own now.
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-highlight-colors").setup({})
  end,
}
