return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local null_ls = require("null-ls")

		-- Define sources individually for better error handling
		local formatting = null_ls.builtins.formatting
		local diagnostics = null_ls.builtins.diagnostics
		local code_actions = null_ls.builtins.code_actions

		-- Define sources array
		local sources = {
			-- Formatting
			formatting.prettier.with({
				filetypes = { "vue", "markdown", "typescript", "typescriptreact" },
			}),
			formatting.stylua,
			formatting.black,
			formatting.autopep8,
		}

		-- Add diagnostics sources if they exist
		if diagnostics then
			if diagnostics.eslint then
				table.insert(
					sources,
					diagnostics.eslint.with({
						condition = function(utils)
							return utils.root_has_file(".eslintrc.json")
						end,
					})
				)
			end

			if diagnostics.flake8 then
				table.insert(sources, diagnostics.flake8)
			end

			if diagnostics.mypy then
				table.insert(sources, diagnostics.mypy)
			end
		end

		-- Add code action sources if they exist
		if code_actions and code_actions.eslint then
			table.insert(sources, code_actions.eslint)
		end

		-- Setup with the assembled sources
		null_ls.setup({
			sources = sources,
		})
	end,
}
