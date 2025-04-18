-- return {
-- 	"jose-elias-alvarez/null-ls.nvim",
--
-- 	config = function()
-- 		-- Require null-ls
-- 		local null_ls = require("null-ls")
--
-- 		-- Setup null-ls with sources for formatting, diagnostics, and code actions
-- 		null_ls.setup({
-- 			debug = true, -- Set to true for debugging output, optional
--
-- 			sources = {
-- 				-- Formatters
-- 				null_ls.builtins.formatting.prettier.with({
-- 					extra_filetypes = { "vue", "yaml", "markdown", "typescript", "typescriptreact" }, -- Add TypeScript and React filetypes
-- 				}),
-- 				null_ls.builtins.formatting.stylua, -- Lua formatter
-- 				null_ls.builtins.formatting.black, -- Python formatter
-- 				null_ls.builtins.formatting.autopep8, -- Python formatter
--
-- 				-- Linters
-- 				null_ls.builtins.diagnostics.eslint.with({
-- 					condition = function(utils)
-- 						return utils.root_has_file(".eslintrc.json") -- Run eslint only if .eslintrc.json exists
-- 					end,
-- 				}),
-- 				null_ls.builtins.diagnostics.flake8, -- Python linter
-- 				null_ls.builtins.diagnostics.mypy, -- Python type checker
--
-- 				-- TypeScript-related Sources
-- 				-- Linter and code actions for TypeScript
-- 				null_ls.builtins.diagnostics.eslint.with({
-- 					condition = function(utils)
-- 						return utils.root_has_file(".eslintrc.json") -- Run eslint for TypeScript if .eslintrc.json exists
-- 					end,
-- 				}),
-- 				null_ls.builtins.code_actions.eslint, -- Code actions for TypeScript
--
-- 				-- TypeScript formatting with prettier
-- 				null_ls.builtins.formatting.prettier.with({
-- 					filetypes = { "typescript", "typescriptreact" }, -- Enable prettier for TypeScript
-- 				}),
--
-- 				-- You can add additional code actions or linters as needed
-- 			},
--
-- 			-- Optional: Configure formatting on save, diagnostics, etc.
-- 			-- on_attach = function(client, bufnr)
-- 			-- 	-- Set up key mappings, for example, formatting
-- 			-- 	vim.api.nvim_buf_set_keymap(
-- 			-- 		bufnr,
-- 			-- 		"n",
-- 			-- 		"<leader>f",
-- 			-- 		":lua vim.lsp.buf.formatting_sync()<CR>",
-- 			-- 		{ noremap = true, silent = true }
-- 			-- 	)
-- 			-- 	-- You can add custom mappings for code actions or other LSP commands here
-- 			-- end,
-- 		})
-- 	end,
-- }
