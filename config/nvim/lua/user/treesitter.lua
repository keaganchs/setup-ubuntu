vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })

require('nvim-treesitter').install { 'python', 'rust', 'javascript', 'zig' }

vim.api.nvim_create_autocmd('FileType', {
    pattern = { '*' }, -- Or specify specific filetypes like { 'python', 'lua' }
    callback = function(ev)
        -- VimTeX's syntax does the highlighting for TeX: the snippets decide
        -- whether they're in math mode by asking it, which fails under treesitter.
        if vim.tbl_contains({ "tex", "plaintex", "bib" }, ev.match) then
            return
        end
        pcall(vim.treesitter.start)
    end,
})
