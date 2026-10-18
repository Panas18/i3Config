return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = { markdown = { "markdownlint" } }

      local group = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = group,
        callback = function(event)
          if vim.bo[event.buf].buftype ~= "" then
            return
          end
          -- Optional lint tools must never abort a file-open autocommand.
          lint.try_lint(nil, {
            ignore_errors = true,
            filter = function(linter)
              local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
              return vim.fn.executable(cmd) == 1
            end,
          })
        end,
      })
    end,
  },
}
