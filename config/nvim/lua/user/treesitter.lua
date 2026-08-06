vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })

require('nvim-treesitter').install { 'python', 'rust', 'javascript', 'zig' }

vim.api.nvim_create_autocmd('FileType', {
    pattern = { '*' }, -- Or specify specific filetypes like { 'python', 'lua' }
    callback = function()
        pcall(vim.treesitter.start)
    end,
})
