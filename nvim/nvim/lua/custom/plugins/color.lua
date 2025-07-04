return {
	-- List all themes here, all as lazy
	{ "folke/tokyonight.nvim", lazy = true },
	{ "martinsione/darkplus.nvim", lazy = true },
	{ "ellisonleao/gruvbox.nvim", lazy = true },
	{ "morhetz/gruvbox", lazy = false },
	{ "catppuccin/nvim", name = "catppuccin", lazy = true },

	{
		"nvim-lua/plenary.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			vim.cmd.colorscheme(vim.g.colorscheme or "catppuccin")
		end,
	},
}
