vim.pack.add({ "https://github.com/stevearc/dressing.nvim" })
require("dressing").setup({
    input = { start_in_insert = false, insert_only = false },
})
