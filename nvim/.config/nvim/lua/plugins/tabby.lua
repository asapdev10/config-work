return {
    "nanozuki/tabby.nvim",
    lazy = true,
    event = "VeryLazy",
    config = function()
        require('tabby').setup({
            line = function(line)
                return {
                    line.tabs().foreach(function(tab)
                        local name = tab.name()
                        if name and string.find(name:lower(), "zsh") then
                            name = "zsh"
                        elseif name and string.find(name:lower(), "bash") then
                            name = "bash"
                        elseif name and string.find(name:lower(), "pwsh") then
                            name = "pwsh"
                        else
                            name = "code"
                        end
                        return {
                            " ",
                            tab.number(),
                            " ",
                            name,
                            " ",
                            hl = tab.is_current() and "TabLineSel" or "TabLine",
                            margin = ""
                        }
                    end),
                    hl = "TabLineFill",
                }
            end,
        })
    end,
}
