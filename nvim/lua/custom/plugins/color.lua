return {
  { "folke/tokyonight.nvim", lazy = true },
  { "martinsione/darkplus.nvim", lazy = true },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "morhetz/gruvbox", lazy = true },
  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000,
    opts = { flavour = "mocha" },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme(vim.g.colorscheme or "catppuccin")
    end,
  },
}
