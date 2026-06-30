return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha", -- ensures you're using mocha as base
			color_overrides = {
				mocha = {
					-- base = "#13131f",
					base = "#0d0d14",
					-- blue = "#89b4fa",
					blue = "#73b7ff",
					crust = "#11111b",
					flamingo = "#f2cdcd",
					-- green = "#a6e3a1", 
					green = "#a1eb9b",
					lavender = "#b4befe",
					mantle = "#181825",
					maroon = "#eba0ac",
					mauve = "#cba6f7",
					overlay0 = "#6c7086",
					overlay1 = "#7f849c",
					overlay2 = "#9399b2",
					-- peach = "#fab387",
					peach = "#ffb485",
					pink = "#f5c2e7",
					red = "#f38ba8",
					rosewater = "#f5e0dc",
					sapphire = "#74c7ec",
					sky = "#89dceb",
					subtext0 = "#a6adc8",
					-- subtext0 = "#ff3636",
					subtext1 = "#bac2de",
					-- subtext1 = "#ff3636",
					surface0 = "#313244",
					surface1 = "#45475a",
					surface2 = "#585b70",
					teal = "#94e2d5",
					text = "#ebedf5",
					-- text = "#ff3636",
					yellow = "#f9e2af",
				},
			},
		})
		vim.cmd.colorscheme("catppuccin")
	end,
}
