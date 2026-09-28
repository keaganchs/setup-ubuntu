-- LaTeX: VimTeX (compile with latexmk, view in Zathura), UltiSnips with Gilles
-- Castel's snippets (UltiSnips/tex.snippets), and TeXpresso for live preview.
-- The binaries come from packages/latex.sh, packages/texpresso.sh and
-- packages/nvim-python.sh.

-- UltiSnips is a python plugin, so nvim needs a python3 with pynvim. Point it
-- at the venv packages/nvim-python.sh builds rather than whichever python3 is
-- first on PATH, which may not have pynvim (or may be upgraded out from under it).
local nvim_python = vim.fn.expand("~/.local/share/nvim-python/bin/python3")
if vim.fn.executable(nvim_python) == 1 then
    vim.g.python3_host_prog = nvim_python
end

-- VimTeX. Its mappings sit under <localleader>, which is left at the default
-- backslash: \ll toggles continuous compilation, \lv forward-searches in
-- Zathura, \le opens the error list. Ctrl-click in Zathura jumps back here.
vim.g.tex_flavor = "latex"
vim.g.vimtex_view_method = "zathura"
-- Collect errors in the quickfix list without popping it open on every save.
vim.g.vimtex_quickfix_mode = 0

-- Read when the plugin loads, so these have to be set before it's packadd-ed.
vim.g.UltiSnipsExpandTrigger = "<tab>"
vim.g.UltiSnipsJumpForwardTrigger = "<tab>"
vim.g.UltiSnipsJumpBackwardTrigger = "<s-tab>"

-- UltiSnips starts nvim's python host when it loads, which is ~300ms -- most of
-- nvim's startup time if paid on every launch. It's only used for TeX, so it's
-- installed here but not put on the runtimepath until the first TeX buffer.
-- Its mappings and autocmds are global, so loading it mid-session is fine.
vim.pack.add({ "https://github.com/SirVer/ultisnips" }, { load = function() end })
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "tex", "plaintex" },
    once = true,
    callback = function()
        vim.cmd.packadd("ultisnips")
    end,
})

vim.pack.add({
    "https://github.com/lervag/vimtex",
    -- Defines :TeXpresso once a .tex buffer opens; `:TeXpresso %` starts the
    -- viewer on the current file.
    "https://github.com/let-def/texpresso.vim",
})
