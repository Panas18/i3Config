return {
	"github/copilot.vim",
	config = function()
		vim.g.copilot_no_tab_map = true
		vim.g.copilot_assume_mapped = true
		vim.g.copilot_filetypes = {
			lua = true,
			python = true,
			javascript = true,
			typescript = true,
			jsx = true,
			tsx = true,
			markdown = true,
		}

		-- Alt+l accepts AI suggestions; Tab remains available for normal completion.
		vim.keymap.set("i", "<M-l>", "copilot#Accept()", {
			expr = true,
			replace_keycodes = false,
			silent = true,
			noremap = true,
			desc = "Accept Copilot suggestion",
		})

		-- Next suggestion with Ctrl+j
		vim.keymap.set("i", "<C-j>", "<Plug>(copilot-next)", { noremap = false })
		-- Previous suggestion with Ctrl+k
		vim.keymap.set("i", "<C-k>", "<Plug>(copilot-previous)", { noremap = false })
		-- Dismiss suggestion with Ctrl+]
		vim.keymap.set("i", "<C-]>", "<Plug>(copilot-dismiss)", { noremap = false })
	end,
}
