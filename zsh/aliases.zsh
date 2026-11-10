# ==============================================================================
# aliases.zsh :: everyday aliases + helpers
# Package and service aliases are distro-specific and live in distro/*.zsh
# ==============================================================================

# ---- files / system ------------------------------------------------------------
if (( $+commands[eza] )); then
  alias ls='eza'
  alias ll='eza -lah'          # add --git if your eza was built with git support
else
  alias ls='ls --color=auto'
  alias ll='ls -lah'
fi
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias ip='ip -c'
alias df='df -h'
alias free='free -h'
alias v='nvim'

# ---- git -----------------------------------------------------------------------
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gd='git diff'
alias gl='git log --oneline --graph -15'

# ---- desktop reloads (mako / waybar) -------------------------------------------
alias mkr='makoctl reload'
alias wbr='pkill waybar; waybar &>/dev/null & disown'

# ---- tmux and nvim helpers (they use the files install.sh puts in place) ---------
alias t='tmux new -As main'                    # attach to "main", or create it
alias tmh='less -R ~/.config/tmux/help.txt'    # tmux cheat sheet, no nvim needed
nvh() {                                        # nvim keybind cheat sheet, closes with q
  nvim --cmd 'let g:workflow_stdin=1' -c KeyHelp -c 'autocmd WinClosed * ++once qa'
}
playground() {                                 # practice file: a fresh copy every time
  local d=~/.cache/nvim-playground
  mkdir -p "$d" && cp ~/.local/share/nvim-playground.txt "$d/nvim-playground.txt" || {
    print -u2 "playground: run install.sh first"; return 1
  }
  (cd "$d" && nvim nvim-playground.txt)
}

# ---- cfg <name>: edit a config file; cfg zsh also reloads your zshrc -------------
typeset -gA _tn_cfg=(
  zsh    $HOME/.zshrc
  nvim   $HOME/.config/nvim/init.lua
  tmux   $HOME/.config/tmux/tmux.conf
  foot   $HOME/.config/foot/foot.ini
  mako   $HOME/.config/mako/config
  waybar $HOME/.config/waybar/config.jsonc
  wbcss  $HOME/.config/waybar/style.css
  mango  $HOME/.config/mango/config.conf
)
cfg() {
  local f=${_tn_cfg[$1]} ed=${EDITOR:-nvim}
  [[ -z $f ]] && { print "cfg: ${(kj:|:)_tn_cfg}"; return 1 }
  ${=ed} "$f" && [[ $1 == zsh ]] && source ~/.zshrc
}
_tn_cfg_complete() { compadd -- ${(k)_tn_cfg} }
(( $+functions[compdef] )) && compdef _tn_cfg_complete cfg

# ---- tn-doctor: what is loaded, what is missing ----------------------------------
tn-doctor() {
  local c
  local ok=$'\e[32mok\e[0m' no=$'\e[31mNO\e[0m'
  print "distro: ${TN_DISTRO:-unknown}    zsh $ZSH_VERSION    TERM=$TERM"
  print "\n-- zsh plugins --"
  (( $+functions[_zsh_highlight] ))         && print "$ok  zsh-syntax-highlighting  ${TN_PLUGIN_SRC[zsh-syntax-highlighting]:-(loaded by your own zshrc)}" || print "$no  zsh-syntax-highlighting"
  (( $+functions[_zsh_autosuggest_start] )) && print "$ok  zsh-autosuggestions      ${TN_PLUGIN_SRC[zsh-autosuggestions]:-(loaded by your own zshrc)}"     || print "$no  zsh-autosuggestions"
  (( $+functions[fzf-tab-complete] ))       && print "$ok  fzf-tab"                                                                                       || print "$no  fzf-tab"
  print "\n-- commands --"
  for c in git fzf fd rg bat eza nvim tmux starship wl-copy; do
    (( $+commands[$c] )) && print "$ok  $c" || print "$no  $c"
  done
  print "\n-- terminal and files --"
  infocmp "$TERM" >/dev/null 2>&1 && print "$ok  terminfo for $TERM" || print "$no  no terminfo for $TERM (backspace and clear will misbehave)"
  [[ -r ~/.config/tmux/help.txt ]]            && print "$ok  tmux help file"     || print "$no  ~/.config/tmux/help.txt (run install.sh)"
  [[ -r ~/.local/share/nvim-playground.txt ]] && print "$ok  playground file"    || print "$no  ~/.local/share/nvim-playground.txt (run install.sh)"
}
