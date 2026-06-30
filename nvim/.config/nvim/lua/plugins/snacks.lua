-- Mirrors the shell fzf cockpit (~/lab/config/bash/.bashrc.d/fzf.bash):
-- find/grep show hidden + git-ignored files by default, with this prune list
-- keeping package/build dirs out. Keep this list in sync with FZF_PRUNE_DIRS.
local prune = {
  ".git", "node_modules", "vendor", ".venv", "venv",
  "target", "dist", "build", ".next", ".cache",
}

return {
  "folke/snacks.nvim",
  event = "VeryLazy",
  opts = {
    picker = {
      enabled = true,
      sources = {
        -- hidden: show dot-paths · ignored: include git-ignored (.env.prod etc)
        -- toggle in-picker with <a-h> (hidden) and <a-i> (ignored)
        files = { hidden = true, ignored = true, exclude = prune },
        grep = { hidden = true, ignored = true, exclude = prune },
      },
    },
  },
}
