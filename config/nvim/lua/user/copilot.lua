vim.pack.add({ "https://github.com/github/copilot.vim" })
vim.keymap.set("i", "<M-CR>", 'copilot#Accept("\\<CR>")', {
	expr = true,
	replace_keycodes = false,
})
vim.g.copilot_no_tab_map = true
