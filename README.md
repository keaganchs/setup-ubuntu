# setup-ubuntu

Dotfiles and a setup script for a new Ubuntu installation.

## Setup

```sh
git clone --recursive https://github.com/keaganchs/setup-ubuntu.git ~/.dotfiles
bash ~/.dotfiles/install.sh
```

If you forgot `--recursive`, `install.sh` fetches the submodules itself.

Running `install.sh` again is safe — every step checks whether its work is
already done, so a re-run reinstalls nothing and never appends a duplicate line
to `~/.bashrc`. To redo just one thing, name it:

```sh
bash ~/.dotfiles/install.sh nvim tmux
```

Already-running programs keep the config they started with, so after a re-run
that changed something: `prefix + r` in tmux, and reopen nvim.

### Without root

`install.sh` needs `sudo` for apt packages and the system audio tweak. Without
it, the script says so and asks whether to continue with only the steps that
work unprivileged — shell config, nvim, the tmux/nvim configs, fzf/fd/rg/gh,
node, uv, conda and the fonts. To skip the prompt on a non-interactive machine:

```sh
NO_SUDO=1 bash ~/.dotfiles/install.sh
```

Anything skipped is listed at the end of the run.

## Layout

- `install.sh` — entry point: wires up the shell, installs the tool configs,
  then runs each `packages/*.sh` script.
- `lib/common.sh` — helpers every script shares (`apt_install`,
  `append_once`, `copy_config`, `install_release_bin`, ...). All of them are
  no-ops when their work is already done, and `install_release_bin` will
  smoke-test a downloaded binary before letting it replace anything, if given a
  command to run it with.
- `bash/` — shell config. `~/.bashrc` stays a real, untracked file; `install.sh`
  adds a single `source` line pointing at `bash/bashrc.sh`, which sources the
  rest. Anything installers append to `~/.bashrc` directly (conda init, brew
  shellenv) stays local and untracked.
- `git/gitconfig` — tracked git settings, pulled into `~/.gitconfig` via
  `include.path` so name, email and credentials stay off GitHub.
- `packages/` — one script per tool, each safe to re-run. Scripts that can't do
  anything useful without root carry a `# requires-sudo` line and get skipped in
  unprivileged runs.
- `config/nvim`, `config/tmux` — copied into `~/.config/<tool>`, since that's
  where those tools require their config to live. The repo is the source of
  truth: edit here and re-run `install.sh` to apply. `copy_config` only writes
  the files the repo owns (what `git ls-files` reports, so `.gitignore` decides)
  and never deletes anything else in the destination, which is what lets tpm's
  plugin checkouts and nvim's plugin lockfile live alongside them.
- `scripts/git-credentials.sh` — one-time interactive GPG + `pass` setup for
  storing the GitHub token encrypted. `install.sh` offers to run it when git has
  no global identity yet.

The nvim and tmux configs are adapted from
[huterguier/nvim](https://github.com/huterguier/nvim) and
[huterguier/tmux](https://github.com/huterguier/tmux) (the nvim lua namespace is
`user/` rather than `huterguier/`). They're vendored, not submoduled, so they can
be edited in place. The one submodule is
[tpm](https://github.com/tmux-plugins/tpm) at `config/tmux/plugins/tpm`; the
plugins tpm installs next to it are gitignored. tpm is the one thing under
`config/` that is cloned rather than copied — `packages/tmux.sh` clones it to
`~/.config/tmux/plugins/tpm` and checks out the revision the submodule pins,
because tpm decides which plugins are already installed by running `git remote`
in each plugin directory and a copy without a `.git` reads as uninstalled.

## Notes

- **Local edits are backed up, not overwritten.** A file in `~/.config/<tool>`
  that differs from the repo's copy is saved as `<file>.backup.<timestamp>`
  before being replaced, and the run says which files those were. To keep such a
  change, copy it back into `config/<tool>` and commit it. Files the repo does
  not ship are never touched. (An older `~/.config/nvim` or `~/.config/tmux`
  that is a *symlink* — how this repo used to install — is simply removed on the
  next run, since its contents live in whichever checkout it pointed at.)
- **Moving the clone doesn't leave a broken shell behind.** The three wiring
  points — the `source` line in `~/.bashrc`, the `$include` in `~/.inputrc` and
  git's `include.path` — are rewritten to point at whichever checkout you ran
  `install.sh` from, replacing the same directive aimed at a different one. Only
  lines this repo writes are touched. Without that, moving or re-cloning the
  dotfiles left the old path in place, and since it is a `source` of a file that
  no longer exists, every new shell (and every new tmux pane) opened with
  `bash: .../bash/bashrc.sh: No such file or directory`.
- **A running tmux server does not re-read its config.** The server is a daemon
  that outlives every terminal window, so closing and reopening the terminal
  changes nothing: it only replaces the client. After `install.sh` updates
  `tmux.conf`, apply it with `prefix + r` (or `tmux source-file
  ~/.config/tmux/tmux.conf`), which re-styles every session in place. Killing
  the server would also work but takes your sessions with it.
- **A running nvim does not re-read its config either.** Quit and reopen it, or
  use `:restart`.
- **Where things land.** Tools that publish a current upstream binary (nvim, rg,
  fd, fzf, gh, tree-sitter, uv) are installed under `~/.local` rather than from
  apt — apt's versions lag, and this keeps them working without root. `bash/exports.sh`
  puts `~/.local/bin` and `~/.local/share/*/bin` on `PATH`.
- **Desktop settings** that live in dconf rather than a file are applied with
  `gsettings`: `packages/gnome-keybindings.sh` binds the terminal to `Super+T`
  (replacing GNOME's `Ctrl+Alt+T`) and warns if the accelerator is already taken.
  Add more bindings to the `BINDINGS` table at the top of that script.
  `packages/gnome-terminal.sh` owns the terminal profile — font, background
  `#0c1418`, foreground, and the palette. It compares colours by parsed value,
  so a profile GNOME stored as `rgb(12,20,24)` isn't needlessly rewritten.
- **The blue at palette index 4** is Ubuntu's `#12488b` lightened to `#1e6fd9`,
  taking it from 2.06:1 to 3.84:1 against the background. `bold-is-bright` is
  pinned off so bash's `\033[1;34m` — the prompt's cwd and `ls`'s directories —
  renders from index 4 rather than the bright index 12, which is left at its
  stock `#2a7bde`.
- **Anki** has no apt package; `packages/anki.sh` uses the official `.tar.zst`
  and its bundled `install.sh`, which honours `$PREFIX` — `/usr/local` as root,
  `~/.local` otherwise. The download is ~185MB, so the installed version is
  recorded in `$PREFIX/share/anki/.installed-version` and a re-run only
  re-downloads when upstream has a newer release. Unprivileged installs skip
  Anki's Qt/X11 dependency step; if it won't launch, those libs are the reason.
- **Discord and VS Code come from .deb/apt**, not snap: the snaps are sandboxed
  away from things like screen sharing, and `snap install` has no `-y`.
- **nvim's colours are VS Code's.** `config/nvim/lua/user/colorscheme.lua`
  loads [vscode.nvim](https://github.com/Mofiqul/vscode.nvim), which carries the
  Dark Modern syntax palette — `#569CD6` keywords, `#C586C0` control flow,
  `#CE9178` strings, `#4EC9B0` types, `#DCDCAA` functions, `#6A9955` comments —
  and maps it onto treesitter captures and LSP semantic tokens, so per-language
  highlighting lands where VS Code puts it rather than where a generic vim
  syntax file would. The background is the one thing overridden: each neutral
  grey in the theme's chrome keeps its lightness and takes the terminal
  background's hue and saturation (200°, 33%), which puts the editor at
  `#152229` — `#0c1418` lightened enough to read as its own surface inside the
  terminal and the tmux bar. That lands within a hair of VS Code's own `#1F1F1F`
  in luminance, so the syntax colours keep the contrast they were designed with
  (`#D4D4D4` text at 11.0:1, `#6A9955` comments at 5.0:1). Greys that carry
  *text* — line numbers, inactive splits, ghost text — stay neutral, as they are
  in VS Code.
- **LaTeX in nvim** has two previewers. [VimTeX](https://github.com/lervag/vimtex)
  compiles with latexmk and shows the PDF in Zathura: `\ll` starts continuous
  compilation, `\lv` jumps Zathura to the cursor, and Ctrl-click in Zathura jumps
  back. [TeXpresso](https://github.com/let-def/texpresso) re-renders as you type,
  without saving: `:TeXpresso %`. It has no release binaries, so
  `packages/texpresso.sh` builds it in `~/.local/src/texpresso` and installs
  `texpresso` and `texpresso-xetex` side by side in `~/.local/bin`. A re-run
  skips it if both are there; delete them to rebuild from upstream.
  [UltiSnips](https://github.com/SirVer/ultisnips) expands
  [Gilles Castel's snippets](https://github.com/gillescastel/latex-snippets),
  vendored in `config/nvim/UltiSnips/tex.snippets`, with Tab. Many of them fire
  on their own, like `mk` for inline math or `//` for `\frac`. UltiSnips is Python,
  so `packages/nvim-python.sh` builds a venv with pynvim at
  `~/.local/share/nvim-python`. It uses the system python, not Homebrew's,
  because a Homebrew upgrade breaks any venv built on its python. Starting
  that python costs ~300ms, so UltiSnips is only loaded when the first TeX
  buffer opens, not at startup. The snippets
  check for math mode by asking VimTeX's syntax engine, so
  `lua/user/treesitter.lua` doesn't start treesitter on TeX buffers. Don't add
  `latex` to its parser list.
- **yazi** is the terminal file manager, installed by `packages/yazi.sh` from
  the upstream release into `~/.local/bin` — both `yazi` and its `ya` CLI, which
  ship in one archive and have to sit together. The script runs the downloaded
  binary before installing it, and falls back from the glibc build to the musl
  one, which is statically linked and so runs on any glibc (the 22.04 problem
  `packages/tree-sitter.sh` describes). Its last step apt-installs the optional
  preview tools (ffmpegthumbnailer, imagemagick, p7zip-full, poppler-utils) and
  only warns if it can't, so an unprivileged run still leaves yazi working.
  In nvim, [yazi.nvim](https://github.com/mikavilpas/yazi.nvim) opens it in a
  float: `<leader>-` at the current file, `<leader>cw` at the working directory,
  `<C-Up>` to resume the last session, and `<F1>` for its help. Directories
  still open in oil.nvim (`open_for_directories` is left off), and plenary, its
  one hard dependency, already comes in with telescope.
- **Markdown preview in the browser.**
  [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim)
  renders the current buffer live at `<leader>mp` (or `:MarkdownPreview`), in a
  markdown buffer. The plugin ships without its preview server, so
  `lua/user/markdown.lua` fetches it on install and on update from a
  `PackChanged` autocmd — registered *before* `vim.pack.add`, since that event
  fires for an install before the plugin is loaded, and it `packadd`s the
  plugin itself to be able to call `mkdp#util#install()`. That download is a
  ~45MB prebuilt binary landing in the plugin's `app/bin`, so the first launch
  on a new machine takes a moment and needs network. If it ever fails, build it
  instead with `cd app && npx --yes yarn install` in the plugin directory.
- **First nvim launch** downloads plugins via `vim.pack` and Mason; give it a
  minute. `tree-sitter` and node are installed for it beforehand.
- **`nvim-pack-lock.json` is written by nvim, and tracked.** It pins every
  plugin's revision, and a fresh machine installs exactly what it lists — which
  is why removing a plugin means dropping it from `init.lua` *and* running
  `:lua vim.pack.del({ 'name' })`, or the lockfile reinstalls it. nvim writes
  its copy in `~/.config/nvim`, so after a plugin update `install.sh` will
  report it as a local edit; copy it back into `config/nvim` to record the new
  revisions.
- **tree-sitter is built from source on older Ubuntu.** nvim-treesitter's main
  branch compiles every parser by shelling out to the tree-sitter CLI, and
  refuses anything older than 0.26.1 — but upstream's linux binary for those
  versions is linked against glibc 2.39, newer than 22.04's 2.35, where it
  installs fine and then dies at the dynamic linker with `version 'GLIBC_2.39'
  not found`. So `packages/tree-sitter.sh` runs the downloaded binary before
  installing it (`install_release_bin` takes a smoke-test command for exactly
  this) and, if it won't start, falls back to `cargo install tree-sitter-cli`,
  installing rustup first when the machine has no cargo. That build takes a few
  minutes and only happens where no usable prebuilt exists; on 24.04 and later
  the release binary is used as before. Neither Homebrew nor npm is a shortcut:
  the formula is a major release behind, and the npm package just unpacks the
  same prebuilt binary. The script's "already installed" test is
  `tree-sitter --version`, not the file existing, so a re-run repairs a broken
  install rather than skipping past it.
- **tmux plugins** are installed by `packages/tmux.sh`. Inside tmux, `prefix + I`
  (prefix is `Ctrl-Space`) re-runs that by hand. Adding one means adding a
  `set -g @plugin` line to `tmux.conf` and re-running `install.sh tmux`: tpm
  clones anything missing and prints "Already installed" for the rest, so the
  step stays a no-op once it has run.
- **Saving a session layout.** [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)
  writes the window and pane arrangement (plus each pane's working directory) to
  `~/.local/share/tmux/resurrect` on `prefix + Ctrl-s`, and rebuilds it on
  `prefix + Ctrl-r` — worth doing before a reboot, since a tmux server does not
  survive one. Saving is manual; there is no timer. That directory is outside
  everything `install.sh` writes, so re-running the installer never disturbs a
  saved layout. The keys are the plugin's defaults and collide with nothing here:
  `Ctrl-s` only reaches the terminal's flow control when it is *not* preceded by
  the prefix, and the reload binding is bare `r`, not `Ctrl-r`.
- **`tmux resume` (or `tmux r`) after a reboot** starts tmux, restores the last
  save and attaches to the session you were in when you saved. It's a bash
  function in `bash/functions.sh` wrapping `config/tmux/scripts/resume.sh`;
  every other `tmux` command passes straight through. If a server is already
  running it just attaches, because restoring into live sessions would only
  duplicate them.
- **The terminal window is sized back too.** The save format has no field for
  it, so `resurrect_save.sh` writes the client's size next to the save as
  `last_size`, and `resume.sh` asks the terminal to resize itself with
  `CSI 8 ; rows ; cols t` — the xterm sequence gnome-terminal honours — before
  restoring. It happens first because tmux builds detached sessions at
  `default-size` and rescales their layouts for the client that attaches;
  rescaling twice shifts pane borders by a cell or two. A terminal that ignores
  the sequence loses nothing: tmux still fits the layouts to the real window.
  The size is a request, not a guarantee — gnome-terminal clamps it to what the
  screen fits, so a layout saved on a bigger monitor comes back a few rows short.
- **Saving is refused for the first 10 seconds after tmux starts.**
  Every save repoints resurrect's `last`, which is what a restore loads. So a
  save made in a fresh server, before the restore has finished or out of habit,
  records one empty session and replaces the layout that was worth keeping.
  `prefix + Ctrl-s` is rebound after tpm to `scripts/resurrect_save.sh`, which
  checks the server's start time and then hands off to the plugin's own save.
  The older saves stay in the directory, so after an accident, point `last` back
  at one: `ln -sf tmux_resurrect_<timestamp>.txt ~/.local/share/tmux/resurrect/last`.
- **Ctrl-Backspace deletes a word, so pane navigation is on Alt.** A terminal
  sends the same byte (`0x08`) for Ctrl-Backspace and for Ctrl-h, and
  gnome-terminal can't separate them even with extended keys (`CSI > 4 ; 2 m`)
  turned on — so one key had to give way. Panes now move with `M-h/M-j/M-k/M-l`
  (given to vim-tmux-navigator as `@vim_navigator_mapping_*` options, since the
  plugin re-binds those keys when tpm loads it), windows with the stock
  `prefix + n` / `prefix + p`, and nothing binds Ctrl-h any more, so it reaches
  the program in the pane: `bash/inputrc` maps it to `backward-kill-word` and
  `config/nvim/init.lua` maps it to `<C-w>` for insert and command mode. Ctrl-w
  still deletes the bigger whitespace-delimited chunk in both.
- **Scrollback is 500 lines, saved, and cleared by `clear`.**
  `@resurrect-capture-pane-contents` puts each pane's scrollback into the save
  (a `pane_contents.tar.gz` beside it), so a restored pane comes back with its
  text instead of empty. `history-limit` is set to 500 *after* tpm, since
  tmux-sensible raises it to 50000 and that much per pane makes for a heavy
  save. tmux fixes the limit when a pane is created, so the new value applies
  to new panes and existing ones keep what they were born with. Clearing also
  clears the history, in both paths: the `clear` function in `bash/functions.sh`
  (for the command) and a `C-l` binding in `tmux.conf` (for the key, which
  readline handles without running anything). Otherwise cleared output would
  still sit in the pane's history and come back through a restore.
- **The Claude usage segment** (`config/tmux/scripts/claude_usage.sh`) shows
  the real percentage from `claude -p "/usage"`, which takes about a second, so
  the status bar only ever reads a cache in `~/.cache/tmux` that a background
  job refreshes every 5 minutes. That job holds `flock` on
  `claude_usage.lock` rather than creating a lock file it deletes in a trap:
  the kernel releases a `flock` however the process dies, while the lock file
  survived a killed refresh and pinned the segment to one stale number for ten
  days. The lock file itself is expected to stay on disk. A number older than
  30 minutes is drawn muted with a `?` instead of the countdown, so a refresh
  that has silently stopped looks wrong rather than current.
- **New panes open where you were.** `prefix + %` and `prefix + "` pass
  `-c "#{pane_current_path}"`, so a split starts in the current pane's directory
  rather than in whatever directory the terminal was launched from. This is
  per-pane state, so it also survives a resurrect restore. `prefix + c` is left
  alone: a new *window* is usually a new task, so it keeps tmux's default of the
  directory the attached client was started in. To change that too, give it the
  same treatment: `bind c new-window -c "#{pane_current_path}"`.
- **Status bar styling.** `config/tmux/scripts/restyle_status.sh` runs after tpm
  and fixes up what the catppuccin theme built:
  - *Separators.* The theme stamps one global `@catppuccin_right_separator` on
    every right-aligned segment. `tmux.conf` sets it to the square cap `█` and
    the script swaps just the first back to the rounded `` — so the
    right-aligned run opens with a curve and every seam inside it is flat.
    Setting the option to an empty string doesn't work: the theme treats empty
    as unset and falls back to its rounded default.
  - *Colours.* Mocha's base `#1e1e2e` becomes the terminal background `#0c1418`,
    and surface0 `#313244` and black4 `#585b70` are re-derived by applying
    mocha's own step off the new base. The theme loads its palette from a file
    inside the plugin directory that tpm overwrites on update, and
    `@catppuccin_flavour` only names a file in that directory, so substituting
    on the built options is what survives a plugin update.
  - *Two accents, not six.* Catppuccin gives every segment its own pastel; the
    bar uses blue `#8facda` for everything at rest and orange `#daab8e` for
    whatever is active or updated — the current window, a window with unread
    output, and the session block while the prefix is held. The accent rows in
    `RECOLOUR` collapse five of catppuccin's six onto those two, keyed by the
    state a segment marks rather than which segment it is. Both are catppuccin's
    own pastels muted for the darker base (HSL saturation ×0.55, lightness
    −5pp): at full strength they read as neon against `#0c1418`, and since the
    dark glyph sits *on* these blocks they can't go much further down either —
    blue is 8.04:1 against that glyph, orange 9.03:1. To retune, edit those rows
    or the `BLUE`/`ORANGE` pair above them.
  - *Unread windows.* `monitor-activity` in `tmux.conf` flags a background
    window that has produced output since you last looked at it, and the script
    rewrites `window-status-format` so that tab's index block takes the orange
    accent while the flag is up. tmux's own `window-status-activity-style` can't
    do it: the theme's format sets the segment's colours inline, and an inline
    `#[bg=...]` beats the style.

  All three passes are no-ops once applied, so re-sourcing `tmux.conf` is safe.
  The two custom segment scripts carry the same colours inline, since their
  output is generated at render time and never passes through the substitution.
- **Fonts** install to `~/.local/share/fonts`, and `packages/fonts.sh` points the
  default GNOME Terminal profile at *FiraCode Nerd Font Mono* via `gsettings`
  (keeping whatever point size the profile had). The dotfiles own the font
  family, so a re-run resets a profile pointed elsewhere. On another terminal,
  set the font by hand — without it the tmux status bar glyphs render as tofu or
  with broken spacing.
- **Why the patched FiraCode.** Upstream [tonsky/FiraCode](https://github.com/tonsky/FiraCode)
  carries no private-use-area icons, so the status bar's  (U+E725) and 󱚝
  (U+F169D) would be tofu. `fonts.sh` installs
  [ryanoasis' patched build](https://github.com/ryanoasis/nerd-fonts) of the same
  typeface instead, and warns if either glyph is missing from what it installed.
  Note that Fira Code ships no italic, and VTE doesn't render ligatures — so
  gnome-terminal shows neither.
- **Newly installed fonts need a terminal restart.** VTE reads the fontconfig
  cache at startup, so a gnome-terminal that was already running when the fonts
  landed won't see them until every window is closed and reopened. tmux can keep
  running — it only passes the bytes through.
