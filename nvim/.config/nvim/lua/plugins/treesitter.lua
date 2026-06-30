return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
  build = ":TSUpdate",
  opts = {
    auto_install = true,
    ensure_installed = { "typescript", "tsx", "xml" },
    highlight = {
      enable = true,
    },
  },
}
