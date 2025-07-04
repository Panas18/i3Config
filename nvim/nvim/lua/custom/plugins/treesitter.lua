return {
	-- Treesitter main plugin:
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs", -- sets main module to use for opts
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
				"cpp",
			},
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
		},
	},

	-- Treesitter Context plugin:
	{
		"nvim-treesitter/nvim-treesitter-context",
		opts = {
			enable = true, -- enable this plugin (can be enabled/disabled per filetype)
			throttle = true, -- throttle plugin updates (may improve performance)
			max_lines = 5, -- maximum number of lines for the context window
			patterns = {
				-- patterns to use for TS nodes; adjust as you need:
				default = {
					"function",
					"method",
					"class",
					"for",
					"while",
					"if",
					"switch",
					"case",
				},
			},
		},
	},
}
