vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 5

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "latex", "tex", "markdown", "text" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.breakindent = true
        vim.opt_local.breakindentopt = "shift:2,min:20"
        vim.opt_local.linebreak = true
        -- Optional: makes navigation easier on wrapped lines
        vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, buffer = true })
        vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, buffer = true })
        vim.keymap.set('v', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, buffer = true })
        vim.keymap.set('v', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, buffer = true })
    end,
})

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4

vim.opt.clipboard = "unnamedplus"
vim.opt.winborder = "rounded"
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank({ timeout = 200 })
    end,
})

vim.keymap.set("n", "<leader>so", ":update<CR> :source<CR>")
vim.keymap.set("n", "<leader>w", ":write<CR>")
vim.keymap.set("n", "<leader>q", ":quit<CR>")
vim.keymap.set("n", "<leader>%", ":vs<CR>")
vim.keymap.set("n", '<leader>"', ":sp<CR>")

vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("i", "kj", "<Esc>")

vim.pack.add({ "https://github.com/christoomey/vim-tmux-navigator" })
-- Alt, not Ctrl, to match tmux.conf: Ctrl-h is the byte a terminal sends for
-- Ctrl-Backspace, which is a word delete here rather than a pane move.
vim.keymap.set("n", "<M-h>", "<cmd>TmuxNavigateLeft<CR>")
vim.keymap.set("n", "<M-j>", "<cmd>TmuxNavigateDown<CR>")
vim.keymap.set("n", "<M-k>", "<cmd>TmuxNavigateUp<CR>")
vim.keymap.set("n", "<M-l>", "<cmd>TmuxNavigateRight<CR>")

-- Ctrl-Backspace deletes the word before the cursor. <C-h> is what the terminal
-- sends for it; nvim's own default for <C-h> in insert mode is a plain
-- backspace, which Backspace itself already does.
vim.keymap.set("i", "<C-h>", "<C-w>")
vim.keymap.set("c", "<C-h>", "<C-w>")

require("user/colorscheme")
require("user/oil")
require("user/copilot")
require("user/lsp")
require("user/treesitter")
require("user/telescope")
require("user/yazi")
require("user/markdown")
require("user/dressing")
require("user/conform")
require("user/teamtype")
require("user/latex")
