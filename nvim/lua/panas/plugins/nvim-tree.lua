local status, nvimtree = pcall(require, "nvim-tree")
if not status then
  return
end

-- recommended settings from nvim-tree documentation
vim.g.load = 1
vim.g.loaded_netrwPlugin = 1

vim.cmd([[ highlight NvimTreeIndentMarker guifg=#3FC5FF ]])

nvimtree.setup({
  open_on_setup = true,
  view = {
    adaptive_size = true
  },
  renderer = {
    icons = {
      glyphs = {
        folder = {
          arrow_closed = "",
          arrow_open = "",
        },
      },
    },
  },
  actions = {
    open_file = {
      window_picker = {
        enable  = false,
      },
    },
  },
})
