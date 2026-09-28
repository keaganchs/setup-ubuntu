-- yazi.nvim: open the yazi file manager (packages/yazi.sh) in a floating
-- window, on the current file. Files opened there come back into this nvim.
--
-- plenary, its one hard dependency, is already installed by user/telescope.lua,
-- which also gives yazi.nvim its directory search.
vim.pack.add({ "https://github.com/mikavilpas/yazi.nvim" })

require("yazi").setup({
    -- Leave directories to oil.nvim, which is already the editor for those.
    open_for_directories = false,
    keymaps = { show_help = "<f1>" },
})

vim.keymap.set({ "n", "v" }, "<leader>-", "<cmd>Yazi<cr>", { desc = "Open yazi at the current file" })
vim.keymap.set("n", "<leader>cw", "<cmd>Yazi cwd<cr>", { desc = "Open yazi in the working directory" })
vim.keymap.set("n", "<C-Up>", "<cmd>Yazi toggle<cr>", { desc = "Resume the last yazi session" })
