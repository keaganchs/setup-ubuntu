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

- `install.sh` — entry point: wires up the shell, links the tool configs, then
  runs each `packages/*.sh` script.
- `lib/common.sh` — helpers every script shares (`apt_install`, `link`,
  `append_once`, `install_release_bin`, ...). All of them are no-ops when their
  work is already done.
- `bash/` — shell config. `~/.bashrc` stays a real, untracked file; `install.sh`
  adds a single `source` line pointing at `bash/bashrc.sh`, which sources the
  rest. Anything installers append to `~/.bashrc` directly (conda init, brew
  shellenv) stays local and untracked.
- `git/gitconfig` — tracked git settings, pulled into `~/.gitconfig` via
  `include.path` so name, email and credentials stay off GitHub.
- `packages/` — one script per tool, each safe to re-run. Scripts that can't do
  anything useful without root carry a `# requires-sudo` line and get skipped in
  unprivileged runs.
- `config/nvim`, `config/tmux` — symlinked to `~/.config/<tool>`, since that's
  where those tools require their config to live.
- `scripts/git-credentials.sh` — one-time interactive GPG + `pass` setup for
  storing the GitHub token encrypted. `install.sh` offers to run it when git has
  no global identity yet.

The nvim and tmux configs are adapted from
[huterguier/nvim](https://github.com/huterguier/nvim) and
[huterguier/tmux](https://github.com/huterguier/tmux) (the nvim lua namespace is
`user/` rather than `huterguier/`). They're vendored, not submoduled, so they can
be edited in place. The one submodule is
[tpm](https://github.com/tmux-plugins/tpm) at `config/tmux/plugins/tpm`; the
plugins tpm installs next to it are gitignored.

## Notes

- **Existing configs are moved aside, not overwritten.** If `~/.config/nvim` or
  `~/.config/tmux` already exists, `install.sh` renames it to
  `<name>.backup.<timestamp>` and warns.
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
- **First nvim launch** downloads plugins via `vim.pack` and Mason; give it a
  minute. `tree-sitter` and node are installed for it beforehand.
- **tmux plugins** are installed by `packages/tmux.sh`. Inside tmux, `prefix + I`
  (prefix is `Ctrl-Space`) re-runs that by hand.
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
  - *Muted accents.* Catppuccin's pastels are tuned for `#1e1e2e` and read as
    neon against `#0c1418`, so each is knocked back to ×0.55 HSL saturation and
    −5pp lightness. They can't go much further: the dark glyph sits *on* these
    blocks, and the red is already the worst case at 7.39:1. To retune, edit the
    accent rows in `RECOLOUR` — every value there is a plain hex pair.

  Both passes are no-ops once applied, so re-sourcing `tmux.conf` is safe. The
  two custom segment scripts carry the same colours inline, since their output
  is generated at render time and never passes through the substitution.
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
