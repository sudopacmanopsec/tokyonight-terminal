# ==============================================================================
# interactive.zsh :: completion menu (fzf-tab) + Tokyo Night colors + quick file tools
#
#   Tab             fuzzy completion popup, with previews for cd and files
#   nf a/b/c.txt    make the folders + file, then open it   (nf dir/ = folder only)
#   nf              no arguments: pick a folder with fzf, then type a file name
#   Ctrl+P          fuzzy-open files (Tab selects several)
#   Ctrl+F          live grep the project, jump to the matching line
#
# Needs fzf (and git once, to fetch fzf-tab). fd, ripgrep, bat and eza are optional
# but nicer. Safe to source on its own. Does not touch history, prompt or options.
# ==============================================================================

: ${EDITOR:=nvim}
export EDITOR
export VISUAL=${VISUAL:-$EDITOR} SUDO_EDITOR=${SUDO_EDITOR:-$EDITOR}

# ---- Tokyo Night palette, shared by fzf-tab and the pickers --------------------
typeset -g TN_FZF_COLORS="bg+:#283457,bg:#1a1b26,spinner:#bb9af7,hl:#7dcfff,\
fg:#c0caf5,header:#9ece6a,info:#0db9d7,pointer:#7dcfff,\
marker:#9ece6a,fg+:#c0caf5,prompt:#7dcfff,hl+:#7dcfff,border:#3b4261"
typeset -ga TN_FZF_OPTS=(--height=40% --layout=reverse --border=rounded "--color=$TN_FZF_COLORS")

# plain `fzf` gets the theme too, unless you already set FZF_DEFAULT_OPTS yourself
: ${FZF_DEFAULT_OPTS:=${(j: :)TN_FZF_OPTS}}
export FZF_DEFAULT_OPTS

# preview commands, using the nicer tool when it is installed
typeset -g _tn_cat='cat' _tn_ls='ls -1 --color=always'
(( $+commands[bat] )) && _tn_cat='bat --color=always --style=numbers --line-range=:300'
(( $+commands[eza] )) && _tn_ls='eza -1 --color=always'

# ---- completion system (only if nothing has started it yet) --------------------
# Full rebuild once a day, otherwise the fast cached start.
_tn_compinit() {
  setopt local_options extendedglob
  autoload -Uz compinit
  local dump=${ZDOTDIR:-$HOME}/.zcompdump
  if [[ -n $dump(#qN.mh+24) ]]; then compinit -d $dump; else compinit -C -d $dump; fi
}
(( $+functions[compdef] )) || _tn_compinit
unfunction _tn_compinit

# ---- fzf-tab: installed on first use, then loaded -------------------------------
_tn_fzf_tab() {
  local dir=${TN_FZF_TAB:-$HOME/.config/zsh/fzf-tab}
  if [[ ! -r $dir/fzf-tab.plugin.zsh ]]; then
    (( $+commands[git] )) || { print -P "%F{yellow}tn:%f fzf-tab is missing and git was not found" >&2; return 1 }
    print -P "%F{blue}tn:%f installing fzf-tab into ${dir//\%/%%} ..."
    GIT_TERMINAL_PROMPT=0 git clone --depth 1 -q https://github.com/Aloxaf/fzf-tab $dir 2>/dev/null || {
      print -P "%F{yellow}tn:%f could not clone fzf-tab (offline?), using plain completion" >&2
      return 1
    }
  fi
  source $dir/fzf-tab.plugin.zsh

  zstyle ':completion:*' menu no                              # required by fzf-tab
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'      # case-insensitive
  zstyle ':completion:*:descriptions' format '[%d]'           # group headers
  zstyle ':fzf-tab:*' switch-group '<' '>'                    # < and > switch groups
  zstyle ':fzf-tab:*' fzf-flags "${TN_FZF_OPTS[@]}"
  zstyle ':fzf-tab:*' fzf-bindings 'ctrl-j:down' 'ctrl-k:up' 'tab:accept'
  zstyle ':fzf-tab:complete:cd:*' fzf-preview "$_tn_ls \$realpath"
  zstyle ':fzf-tab:complete:(nvim|vim|v|cat|bat|rm|cp|mv):*' fzf-preview \
    "[[ -d \$realpath ]] && $_tn_ls \$realpath || $_tn_cat \$realpath 2>/dev/null"
}
if (( $+commands[fzf] )); then
  _tn_fzf_tab
else
  print -P "%F{yellow}tn:%f fzf not found: no fzf-tab, Ctrl+P or Ctrl+F (install fzf)" >&2
fi
unfunction _tn_fzf_tab

# ---- helpers that list files and folders, with fallbacks -------------------------
_tn_files() {
  if   (( $+commands[fd] )); then fd --type f --hidden --follow --exclude .git 2>/dev/null
  elif (( $+commands[rg] )); then rg --files --hidden --follow --glob '!.git' 2>/dev/null
  else find . -type f -not -path '*/.git/*' 2>/dev/null | sed 's|^\./||'
  fi
}
_tn_dirs() {
  print -r -- ./
  if (( $+commands[fd] )); then fd --type d --hidden --exclude .git 2>/dev/null
  else find . -mindepth 1 -type d -not -path '*/.git*' 2>/dev/null | sed 's|^\./||'
  fi
}

# ---- nf: make a file (and its folders) and open it --------------------------------
nf() {
  local target
  if (( $# == 0 )); then
    (( $+commands[fzf] )) || { print -u2 "nf: give a path, e.g.  nf src/new.c   (the folder picker needs fzf)"; return 1 }
    local dir
    dir=$(_tn_dirs | fzf "${TN_FZF_OPTS[@]}" --prompt='folder > ' --preview "$_tn_ls {}") || return
    vared -p "new file in ${dir}: " -c target
    [[ -z $target ]] && return
    set -- "${dir%/}/$target"
  fi
  local -a files
  for target in "$@"; do
    if [[ $target == */ ]]; then
      mkdir -p -- "$target" && print -P "%F{green}dir%f  ${target//\%/%%}"
    else
      mkdir -p -- "${target:h}" && { [[ -e $target ]] || : > "$target" }
      files+=("$target")
    fi
  done
  (( ${#files} )) || return 0
  ${=EDITOR} "${files[@]}"
}

# ---- Ctrl+P (open file) and Ctrl+F (grep the project) ------------------------------
_tn_quick_open() {
  local -a sel
  sel=("${(@f)$(_tn_files | fzf "${TN_FZF_OPTS[@]}" --multi --prompt='file > ' --preview "$_tn_cat {}")}")
  zle reset-prompt
  [[ -z ${sel[1]} ]] && return
  BUFFER="$EDITOR ${(j: :)${(@q)sel}}"
  zle accept-line
}

_tn_live_grep() {
  if (( ! $+commands[rg] )); then zle -M 'Ctrl+F needs ripgrep (rg)'; return; fi
  local out file line prev='cat {1}'
  (( $+commands[bat] )) && prev='bat --color=always --highlight-line {2} {1}'
  out=$(rg --line-number --no-heading --smart-case --color=never '' 2>/dev/null |
    fzf "${TN_FZF_OPTS[@]}" --delimiter=: --prompt='grep > ' --preview "$prev" \
        --preview-window='right,60%,+{2}/3') || { zle reset-prompt; return }
  file=${out%%:*}; line=${${out#*:}%%:*}
  zle reset-prompt
  BUFFER="$EDITOR +$line ${(q)file}"
  zle accept-line
}

if [[ -o interactive ]] && (( $+commands[fzf] )); then
  zle -N _tn_quick_open
  zle -N _tn_live_grep
  bindkey '^P' _tn_quick_open     # replaces "previous history" (the Up arrow still works)
  bindkey '^F' _tn_live_grep
fi
