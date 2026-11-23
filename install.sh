#!/usr/bin/env bash
# ==============================================================================
# tokyonight-terminal installer: the nvim extras + the tmux config.
#
#   ./install.sh           copy the files into place
#   ./install.sh --link    symlink them instead (edit the repo, changes apply at once)
#
# It NEVER touches zsh: no ~/.zshrc, no ~/.config/zsh. The zsh/ folder is a set of
# modules you copy yourself (see README.md). Existing files are never overwritten,
# they are moved aside as <file>.bak-<time>.
# ==============================================================================
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stamp=$(date +%Y%m%d-%H%M%S)
mode=copy

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*"; }

for arg in "$@"; do
  case $arg in
    --link) mode=link ;;
    -h|--help) sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
  esac
done

# put <path inside the repo> <destination>
put() {
  local src="$repo/$1" dest=$2
  mkdir -p "$(dirname "$dest")"
  if [[ $mode == link && -L $dest && $(readlink -f "$dest") == "$(readlink -f "$src")" ]]; then
    say "already linked  $dest"; return
  fi
  if [[ -e $dest || -L $dest ]]; then
    if [[ $mode == copy && -f $dest && ! -L $dest ]] && cmp -s "$src" "$dest"; then
      say "unchanged      $dest"; return
    fi
    mv "$dest" "$dest.bak-$stamp"
    say "backed up      $dest -> $dest.bak-$stamp"
  fi
  if [[ $mode == link ]]; then ln -s "$src" "$dest"; say "linked         $dest"
  else cp "$src" "$dest"; say "wrote          $dest"; fi
}

command -v git >/dev/null || { echo "git is required (Gentoo: emerge dev-vcs/git, Void: xbps-install git)" >&2; exit 1; }

# ---- nvim: tonybanters' config is the base, and is never overwritten -------------
if [[ -d $HOME/.config/nvim ]]; then
  say "found ~/.config/nvim, leaving it as it is"
else
  say "cloning tonybanters/nvim into ~/.config/nvim"
  git clone https://github.com/tonybanters/nvim "$HOME/.config/nvim"
fi
put nvim/plugin/workflow.lua  "$HOME/.config/nvim/plugin/workflow.lua"
put nvim/plugin/helppages.lua "$HOME/.config/nvim/plugin/helppages.lua"
put nvim/after/plugin/compile-mode.lua "$HOME/.config/nvim/after/plugin/compile-mode.lua"
put nvim/after/plugin/dap.lua "$HOME/.config/nvim/after/plugin/dap.lua"
put nvim/after/plugin/gitsigns.lua "$HOME/.config/nvim/after/plugin/gitsigns.lua"
put nvim/after/plugin/which-key.lua "$HOME/.config/nvim/after/plugin/which-key.lua"
put nvim/after/plugin/dev.lua "$HOME/.config/nvim/after/plugin/dev.lua"
put nvim/after/plugin/colors.lua "$HOME/.config/nvim/after/plugin/colors.lua"
put nvim/after/plugin/completion.lua "$HOME/.config/nvim/after/plugin/completion.lua"
put nvim/lua/plugin-list.lua "$HOME/.config/nvim/lua/plugin-list.lua"
put nvim/plugin/lsp.lua      "$HOME/.config/nvim/plugin/lsp.lua"
put nvim/plugin/quickformat.lua "$HOME/.config/nvim/plugin/quickformat.lua"
put nvim/plugin/tonycontext.lua "$HOME/.config/nvim/plugin/tonycontext.lua"
put nvim/plugin/tonysitter.lua "$HOME/.config/nvim/plugin/tonysitter.lua"
put nvim/lua/manage.lua "$HOME/.config/nvim/lua/manage.lua"
put nvim/queries/zig/indents.scm "$HOME/.config/nvim/queries/zig/indents.scm"

# ---- tmux --------------------------------------------------------------------------
put tmux/tmux.conf "$HOME/.config/tmux/tmux.conf"
put tmux/help.txt  "$HOME/.config/tmux/help.txt"
put tmux/tmux-fzf "$HOME/.local/bin/tmux-fzf"; chmod +x "$HOME/.local/bin/tmux-fzf"

# ---- practice file (the `playground` command from zsh/aliases.zsh opens a fresh copy)
put practice/nvim-playground.txt "$HOME/.local/share/nvim-playground.txt"

# ---- checks ------------------------------------------------------------------------
say "checking what nvim and tmux need"
missing=()
for c in nvim tmux rg fd fzf wl-copy less; do
  command -v "$c" >/dev/null 2>&1 || missing+=("$c")
done
if ((${#missing[@]})); then
  warn "missing: ${missing[*]}   (package lists are in README.md)"
else
  say "all commands found"
fi

if command -v nvim >/dev/null 2>&1; then
  maj=0 min=0
  read -r maj min < <(nvim --version | sed -n '1s/^NVIM v\([0-9]*\)\.\([0-9]*\).*/\1 \2/p') || true
  if ((maj == 0 && min > 0 && min < 11)); then
    warn "nvim is 0.$min and his config wants 0.11+ (see Dependencies in README.md)"
  fi
fi

cat <<'MSG'

Done. nvim and tmux are set up. zsh was NOT touched.
  - run nvim once and let his plugin manager finish installing, then restart it
  - tmux kill-server ; tmux          (or reload with: Ctrl+space then r)
  - zsh add-on (optional, copy-only): see "zsh add-on" in README.md
MSG
