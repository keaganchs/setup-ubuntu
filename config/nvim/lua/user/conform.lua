vim.pack.add({ "https://github.com/stevearc/conform.nvim" })
require("conform").setup({
    formatters_by_ft = {
        python = { "isort", "black" },
    },
    format_on_save = {
        timeout_ms = 1000,
        lsp_fallback = true,
    },
})
