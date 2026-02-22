return { -- Autoformat
	"stevearc/conform.nvim",
	branch = "master",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
	},
	opts = {
		notify_on_error = false,
		format_on_save = function(bufnr)
			local disable_filetypes = {}
			local lsp_format_opt = disable_filetypes[vim.bo[bufnr].filetype] and "never" or "fallback"
			return {
				timeout_ms = 500,
				lsp_format = lsp_format_opt,
			}
		end,
		formatters_by_ft = {
			-- Maintain all original language configurations
			lua = { "stylua" },
			python = { "isort", "black" },
			javascript = {
				stop_after_first = true,
				"eslint",
				"prettierd",
				"prettier",
			},
			typescript = {
				stop_after_first = true,
				"eslint",
				"prettierd",
				"prettier",
			},
			typescriptreact = {
				stop_after_first = true,
				"eslint",
				"prettierd",
				"prettier",
			},
			json = { "jq", "prettierd", "prettier" },
			jsonc = { "prettierd", "prettier" },

			-- Enhanced C/C++ configuration
			c = { "clang-format" },
			cpp = { "clang-format" },
		},
		formatters = {
			-- Add clang-format configuration while preserving existing formatters
			["clang-format"] = {
				command = "clang-format",
				args = {
					"--style=file",
					"--fallback-style=llvm",
					"-assume-filename=$FILENAME",
				},
			},
		},
	},
	config = function(_, opts)
		-- Ensure clang-format is installed via Mason
		require("mason-tool-installer").setup({
			ensure_installed = { "clang-format" },
		})
		require("conform").setup(opts)
	end,
}
