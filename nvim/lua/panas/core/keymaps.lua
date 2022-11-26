vim.g.mapleader = " "
local keymap = vim.keymap

--genral keymaps
keymap.set("i", "jk", "<ESC>")
keymap.set("n", "<leader>nh", ":nohl<CR>")
keymap.set("n", "x", '"_x')

keymap.set("n", "<leader>sv", "<C-w>v") -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s") -- split window horizontally 
keymap.set("n", "<leader>se", "<C-w>=") -- make split window equal
keymap.set("n", "<leader>sx", ":close<CR>") --  close current split window

keymap.set("n", "<leader>to", ":tabnew<CR>") -- open new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>") -- close tab 
keymap.set("n", "<leader>tn", ":tabn<CR>") -- close tab 
keymap.set("n", "<leader>tp", ":tabp<CR>") -- close tab 

-- plugins keymap

-- vim maxmizer
keymap.set("n", "<leader>sm", ":MaximizerToggle<CR>")

-- nvim tree
keymap.set("n", "<leader>e", ":NvimTreeFocus<CR>")

-- telescope
keymap.set("n", "<C-p>", "<cmd>Telescope find_files<cr>")

keymap.set("n", "<leader>p", ":ToggleTerm<CR>")

keymap.set("n", "<leader>jd", ":JsDoc<CR>")
