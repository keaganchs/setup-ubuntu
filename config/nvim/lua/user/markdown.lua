-- markdown-preview.nvim: :MarkdownPreview renders the current buffer in the
-- browser and live-updates as you type. <leader>mp toggles it in a markdown
-- buffer.
--
-- The plugin ships without its preview server; it has to be fetched (or built
-- from app/ with yarn) after the plugin is installed or updated. The hook is
-- registered before vim.pack.add so it also fires on a first install, and it
-- loads the plugin itself because PackChanged for an install runs before the
-- plugin's own code is on the runtimepath.
vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
        local d = ev.data
        if d.spec.name ~= "markdown-preview.nvim" then
            return
        end
        if d.kind ~= "install" and d.kind ~= "update" then
            return
        end
        if not d.active then
            vim.cmd.packadd("markdown-preview.nvim")
        end
        vim.fn["mkdp#util#install"]()
    end,
})

vim.pack.add({ "https://github.com/iamcco/markdown-preview.nvim" })

-- Only markdown, rather than the plugin's default of also claiming .mdx and
-- similar; and leave the preview tab open when switching away from the buffer.
vim.g.mkdp_filetypes = { "markdown" }
vim.g.mkdp_auto_close = 0

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function(ev)
        vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>",
            { buffer = ev.buf, desc = "Toggle markdown preview in the browser" })
    end,
})
