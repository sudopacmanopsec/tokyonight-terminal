# tokyonight-terminal

A Tokyo Night terminal workflow for **zsh + tmux + Neovim**, built on top of
[tonybanters/nvim](https://github.com/tonybanters/nvim). Nothing here replaces your
setup: the nvim files are drop-ins, the tmux config is its own file, and the zsh part is a set of
modules that you **copy and source yourself**.

| Part | What you get | How it gets there |
|---|---|---|
| `nvim/` | NvChad-style dashboard, VSCode-style quick open / palette / project search, file maker (new, rename, copy, delete), and two cheat-sheet popups (`:KeyHelp`, `:TmuxHelp`) | `./install.sh` |
| `tmux/` | tonybanters' tmux config, `Ctrl+A` prefix, vim-style panes, cheat sheet via `tmh` | `./install.sh` |
| `practice/` | `nvim-playground.txt`, a file of guided exercises | `./install.sh` |
| `zsh/` | fzf-tab with Tokyo Night colors, `nf` file maker, `Ctrl+P` / `Ctrl+F` pickers, aliases, plugin loader that cannot fail silently | **copy it yourself** (below) |

## Install nvim + tmux

```sh
git clone https://github.com/sudopacmanopsec/tokyonight-terminal.git
cd tokyonight-terminal
./install.sh            # or ./install.sh --link  to symlink instead of copy
```

- If `~/.config/nvim` does not exist it clones tonybanters' config there. If it exists, it is left alone.
- Files that already exist are moved to `<file>.bak-<time>`, never overwritten.
- **zsh is never touched by the installer.**

## zsh add-on (copy-only)

The installer does not install this. Copy the folder, then add one line to your own `~/.zshrc`:

```sh
mkdir -p ~/.config/zsh/tn
cp -r zsh/. ~/.config/zsh/tn/
echo 'source ~/.config/zsh/tn/load.zsh' >> ~/.zshrc     # keep it as the LAST line
```

Open a new terminal. Remove the line to undo everything. What `load.zsh` does, in order:

| File | Purpose |
|---|---|
| `interactive.zsh` | completion, fzf-tab (cloned on first use), `nf`, `Ctrl+P`, `Ctrl+F` |
| `aliases.zsh` | `ls`/`ll` (eza), git, `t`, `tmh`, `nvh`, `playground`, `cfg`, `tn-doctor` |
| `distro/<id>.zsh` | package and service aliases: `arch.zsh` (pacman, systemd), `chimera.zsh` (apk, dinit), `gentoo.zsh` (portage, OpenRC) or `void.zsh` (xbps, runit), picked from `/etc/os-release` |
| `plugins.zsh` | zsh-autosuggestions, then zsh-syntax-highlighting last |

Your own prompt (starship, p10k, ...), history and options are not touched. If your zshrc already
loads the autosuggestions or syntax-highlighting plugins, they are skipped, never loaded twice.
Any other distro simply gets no distro file. You can also copy a single file, for example only `distro/gentoo.zsh`, and source just that.

## Dependencies

Same tools on every distro: `git zsh fzf fd bat ripgrep eza neovim tmux wl-clipboard`, plus
`zsh-autosuggestions` and `zsh-syntax-highlighting` (if they are missing, the zsh add-on clones them itself), and
`starship` if you want that prompt. Neovim must be **0.11 or newer** (tonybanters' config needs it).

**Arch**

```sh
sudo pacman -S --needed git zsh fzf fd bat ripgrep eza neovim tmux starship wl-clipboard \
  zsh-autosuggestions zsh-syntax-highlighting
```

**Gentoo**

```sh
sudo emerge -av --noreplace \
  dev-vcs/git app-shells/zsh app-shells/fzf sys-apps/fd sys-apps/bat sys-apps/ripgrep \
  sys-apps/eza app-editors/neovim app-misc/tmux gui-apps/wl-clipboard app-shells/starship \
  app-shells/zsh-autosuggestions app-shells/zsh-syntax-highlighting app-portage/gentoolkit
```

Stable amd64 neovim is already 0.11.x, so no keyword changes are needed. If emerge says an atom does not exist,
search with `emerge -s name` or `eix name`.

**Void**

```sh
sudo xbps-install -S zsh git fzf fd bat ripgrep eza neovim tmux starship \
  zsh-autosuggestions zsh-syntax-highlighting wl-clipboard ncurses-term foot-terminfo
```

`ncurses-term` provides the `tmux-256color` terminfo entry. Without it, backspace and `clear` misbehave inside tmux.

**Chimera**

Most of these live in Chimera's `user` repository, so enable it first:

```sh
doas apk add chimera-repo-user
doas apk add git zsh fzf fd bat ripgrep eza neovim tmux starship wl-clipboard zsh-syntax-highlighting
```

`zsh-autosuggestions` is not packaged there, so the zsh add-on clones it on first start (needs git and network).
Neovim in the `user` repo is 0.12.x, which is fine. The aliases use `doas`, Chimera's default.

**His language servers** (optional, from his README): `lua-language-server` from your package manager, then
`npm install -g vscode-langservers-extracted intelephense typescript-language-server typescript`.

What needs what: `ripgrep` is for project search (`Space /`, `Ctrl+F`), `fzf` for fzf-tab, the pickers,
`wl-clipboard` for copying out of tmux on Wayland, `fd`, `bat` and `eza` for speed and previews
(everything has a plain fallback).

## Keys at a glance

Leader is **Space**. `:KeyHelp` / `Space h k` shows the full sheet inside nvim, `tmh` shows tmux's.

| Where | Key | Does |
|---|---|---|
| nvim | `Space p` | go to file |
| nvim | `Space /` | search the project |
| nvim | `Space P` | command palette |
| nvim | `Space n n` | new file or folder (`a/b/c.lua`, trailing `/` for a folder) |
| nvim | `Space n r` / `n c` / `n d` | rename / copy / delete the current file |
| nvim | `Space e` | file sidebar |
| nvim | `Ctrl+s` | save |
| tmux | `Ctrl+A` | prefix |
| tmux | `prefix` `\|` / `-` | split right / down |
| tmux | `Alt+h j k l` | move between panes, no prefix |
| tmux | `Alt+1..9` | jump to window |
| tmux | `tmh` | cheat sheet |
| zsh | `Ctrl+P` / `Ctrl+F` | open file / grep the project |
| zsh | `nf a/b/c.txt` | make folders and file, open it |
| zsh | `t` / `tmh` / `nvh` / `playground` | tmux session / tmux help / nvim help / practice file |

## Troubleshooting

- **Syntax highlighting does nothing.** Run `tn-doctor`. It shows whether the plugin is loaded and from where. If it says `NO`, the
  plugin file was not at any of the usual paths and the clone fallback failed (it needs git and network on first start).
  Find the real path with `equery files zsh-syntax-highlighting | grep '\.zsh$'` (Gentoo) or `xbps-query -f zsh-syntax-highlighting` (Void).
- **Backspace prints a space, `clear` says unknown terminal type.** The terminfo entry for your `$TERM` is missing. `tn-doctor`
  reports it. Install `ncurses-term` (Void), or check `equery uses gui-apps/foot` for a terminfo flag (Gentoo).
- **`Ctrl+P` no longer shows previous history in zsh.** That is the price of the file picker. Use the Up arrow.
- **nvim `Space p` does nothing.** Run `:verbose map <leader>p`. In his config `<leader>p` is only mapped in visual mode, so
  normal mode is free.

## Undo

```sh
rm ~/.config/nvim/plugin/workflow.lua ~/.config/nvim/plugin/helppages.lua   # nvim extras
rm ~/.config/tmux/tmux.conf ~/.config/tmux/help.txt                         # back to default tmux
# zsh: delete the `source ~/.config/zsh/tn/load.zsh` line from ~/.zshrc
```

Backups of anything the installer replaced sit next to the originals as `<file>.bak-<time>`.

## Credits

tmux config from [tonybanters/tmux-btw](https://github.com/tonybanters/tmux-btw).
