return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		build = "make tiktoken",
		opts = {
			debug = false,
			window = {
				layout = "float",
				relative = "cursor",
				width = 0.8,
				height = 0.8,
			},
			model = "auto", -- Auto-select best available model
			auto_follow_cursor = true,
			show_help = true,
			properties = {
				conciseness = "concise",
			},
		},
		config = function(_, opts)
			require("CopilotChat").setup(opts)

			-- Keymaps for CopilotChat
			vim.keymap.set("n", "<leader>cc", ":CopilotChat<CR>", { noremap = true, silent = true, desc = "Open Copilot Chat" })
			vim.keymap.set("n", "<leader>ce", ":CopilotChatExplain<CR>",
				{ noremap = true, silent = true, desc = "Explain code" })
			vim.keymap.set("n", "<leader>cr", ":CopilotChatReview<CR>", { noremap = true, silent = true, desc = "Review code" })
			vim.keymap.set("n", "<leader>cf", ":CopilotChatFix<CR>", { noremap = true, silent = true, desc = "Fix code" })
			vim.keymap.set("n", "<leader>co", ":CopilotChatOptimize<CR>",
				{ noremap = true, silent = true, desc = "Optimize code" })
			vim.keymap.set("n", "<leader>cd", ":CopilotChatDocs<CR>",
				{ noremap = true, silent = true, desc = "Generate documentation" })
			vim.keymap.set("n", "<leader>ct", ":CopilotChatTests<CR>",
				{ noremap = true, silent = true, desc = "Generate tests" })
			vim.keymap.set("n", "<leader>cq", ":CopilotChatToggle<CR>",
				{ noremap = true, silent = true, desc = "Toggle Copilot Chat" })

			-- Visual mode keymaps
			vim.keymap.set("v", "<leader>cc", ":CopilotChat<CR>", { noremap = true, silent = true, desc = "Open Copilot Chat" })
			vim.keymap.set("v", "<leader>ce", ":CopilotChatExplain<CR>",
				{ noremap = true, silent = true, desc = "Explain selection" })
			vim.keymap.set("v", "<leader>cr", ":CopilotChatReview<CR>",
				{ noremap = true, silent = true, desc = "Review selection" })
			vim.keymap.set("v", "<leader>cf", ":CopilotChatFix<CR>", { noremap = true, silent = true, desc = "Fix selection" })
		end,
	},
}
