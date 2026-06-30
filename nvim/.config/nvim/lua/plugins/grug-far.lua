return {
  "MagicDuck/grug-far.nvim",
  cmd = "GrugFar",
  keys = {
    {
      "<leader>rr",
      function()
        require("grug-far").open({
          prefills = { search = vim.fn.expand("<cword>") },
        })
      end,
      mode = "n",
      desc = "Replace (word under cursor)",
    },
    {
      "<leader>rr",
      function()
        local sel = require("utilities").get_visual_selection()
        require("grug-far").open({ prefills = { search = sel } })
      end,
      mode = "v",
      desc = "Replace (selection)",
    },
    {
      "<leader>rR",
      function()
        require("grug-far").open()
      end,
      mode = "n",
      desc = "Replace (blank)",
    },
  },
  opts = {},
}
