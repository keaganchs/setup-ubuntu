-- VS Code's default dark theme (Dark Modern), on a dark blue background.
--
-- vscode.nvim carries VS Code's own syntax palette -- #569CD6 keywords,
-- #CE9178 strings, #4EC9B0 types, #DCDCAA functions, #6A9955 comments -- and
-- maps it onto treesitter captures and LSP semantic tokens, so the per-language
-- highlighting lands where VS Code puts it rather than where a generic vim
-- syntax file would.
vim.pack.add({ "https://github.com/Mofiqul/vscode.nvim" })

-- The editor background: the terminal's #0c1418 (hue 200, saturation 33%)
-- lightened enough to read as a distinct surface inside the terminal and the
-- tmux bar. That is the same rule for every chrome colour below -- each of
-- VS Code's neutral greys keeps its lightness and takes the terminal's hue and
-- saturation -- and it lands the editor background at almost exactly the
-- luminance of VS Code's own #1F1F1F, so the syntax colours keep the contrast
-- they were designed with (#D4D4D4 text is 11.0:1, #6A9955 comments 5.0:1).
--
-- Greys that carry *text* (line numbers, inactive splits, the cursor, ghost
-- text) are deliberately not in this table: VS Code leaves them neutral.
local background = {
    vscBack = "#152229", -- editor background
    vscTabCurrent = "#152229",
    vscTabOther = "#1E323C",
    vscTabOutside = "#192A32",
    vscLeftDark = "#192A32", -- sidebars, and telescope/oil panes
    vscLeftMid = "#253D49", -- status line
    vscPopupBack = "#15242B", -- floats: hover, diagnostics, completion
    vscPopupHighlightGray = "#27414E", -- selected completion item
    vscCursorDarkDark = "#17262D", -- cursorline
    vscSplitDark = "#2D4C5B", -- window separators
    vscSplitThumb = "#2C4958",
    vscContext = "#2B4755", -- indent guides
    vscFoldBackground = "#1E313B",
}

require("vscode").setup({
    style = "dark",
    color_overrides = background,
})

vim.o.background = "dark"
vim.cmd.colorscheme("vscode")
