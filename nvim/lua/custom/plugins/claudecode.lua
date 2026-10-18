-- Claude Code IDE integration.
--
-- Anthropic ships official extensions for VS Code and JetBrains only. This
-- plugin implements the same WebSocket MCP protocol they use: it runs a local
-- server and writes a lockfile into `~/.claude/ide/`, which is how the CLI's
-- `/ide` command discovers an editor to attach to.
--
-- `claude` resolves to ~/.local/bin/claude (native installer symlink), which is
-- already on PATH, so no `terminal_cmd` override is needed here. If you ever
-- run `claude migrate-installer`, add:
--   opts = { terminal_cmd = vim.fn.expand("~/.claude/local/claude") }
return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	config = true,
	-- `cmd` makes lazy.nvim create command stubs, so `:ClaudeCode` works on a
	-- fresh start. A keys-only spec would defer loading until a <leader>a
	-- mapping is pressed, and the commands would not exist before that.
	cmd = {
		"ClaudeCode",
		"ClaudeCodeFocus",
		"ClaudeCodeSelectModel",
		"ClaudeCodeAdd",
		"ClaudeCodeSend",
		"ClaudeCodeTreeAdd",
		"ClaudeCodeStatus",
		"ClaudeCodeStart",
		"ClaudeCodeStop",
		"ClaudeCodeOpen",
		"ClaudeCodeClose",
		"ClaudeCodeDiffAccept",
		"ClaudeCodeDiffDeny",
		"ClaudeCodeCloseAllDiffs",
	},
	keys = {
		{ "<leader>a", nil, desc = "AI/Claude Code" },
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
		{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
		{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
		{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
		-- Same lhs in normal mode, but only inside a file explorer: adds the
		-- entry under the cursor. neo-tree is the one you use.
		{
			"<leader>as",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file",
			ft = { "neo-tree", "NvimTree", "oil", "minifiles", "netrw", "snacks_picker_list" },
		},
		-- Claude's edits open as a diff in nvim; accept or deny them here.
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	},
}
