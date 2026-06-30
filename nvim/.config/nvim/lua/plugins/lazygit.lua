-- lua/plugins/lazygit.lua

local project_roots = { "~/lab" }

local function pick_lazygit()
  local fd = vim.fn.exepath("fd")
  if fd == "" then
    vim.notify("<leader>gg: fd not found", vim.log.levels.ERROR)
    return
  end

  local args = { fd, "-H", "--type", "d", "--max-depth", "5", "-g", ".git" }
  for _, root in ipairs(project_roots) do
    table.insert(args, vim.fn.expand(root))
  end

  local results = vim.fn.systemlist(args)
  local repos = vim.tbl_map(function(p)
    p = p:gsub("\r$", "")
    return (p:gsub("[/\\]%.git[/\\]?$", ""))
  end, results)

  if #repos == 0 then
    vim.notify("No git repos found", vim.log.levels.WARN)
    return
  end

  require("fzf-lua").fzf_exec(repos, {
    prompt = "Git repo> ",
    winopts = { height = 0.4, width = 0.6 },
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          require("lazygit").lazygit(selected[1])
        end
      end,
    },
  })
end

return {
  "kdheepak/lazygit.nvim",
  lazy = true,
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>gg", pick_lazygit, desc = "LazyGit (repo picker over ~/lab)" },
  },
}
