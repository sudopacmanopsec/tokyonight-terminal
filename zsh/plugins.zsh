# ==============================================================================
# plugins.zsh :: zsh-autosuggestions, then zsh-syntax-highlighting (must be LAST)
#
# For each plugin, in this order:
#   1. already loaded (for example by your own zshrc)?  -> leave it alone
#   2. installed by your package manager?               -> use that copy
#   3. otherwise                                        -> clone it once into
#                                                          ~/.config/zsh/plugins/ and use that
# Nothing fails silently any more: a plugin that cannot be loaded prints a message,
# and `tn-doctor` shows where each one came from.
# ==============================================================================

typeset -gA TN_PLUGIN_SRC                      # plugin name -> file it was loaded from
typeset -g  TN_PLUGIN_DIR=${TN_PLUGIN_DIR:-$HOME/.config/zsh/plugins}

# _tn_plugin <name> <github owner/repo> <function that exists once it is loaded>
_tn_plugin() {
  local name=$1 repo=$2 probe=$3 d f
  (( $+functions[$probe] )) && return 0        # already loaded, never load twice

  for d in /usr/share/zsh/site-contrib /usr/share/zsh/plugins /usr/share $TN_PLUGIN_DIR; do
    f=$d/$name/$name.zsh
    [[ -r $f ]] && { source $f; TN_PLUGIN_SRC[$name]=$f; return 0 }
  done

  if (( $+commands[git] )); then
    print -P "%F{blue}tn:%f $name not found, cloning it into ${TN_PLUGIN_DIR//\%/%%} ..."
    mkdir -p $TN_PLUGIN_DIR
    if GIT_TERMINAL_PROMPT=0 git clone --depth 1 -q https://github.com/$repo $TN_PLUGIN_DIR/$name 2>/dev/null &&
       [[ -r $TN_PLUGIN_DIR/$name/$name.zsh ]]; then
      source $TN_PLUGIN_DIR/$name/$name.zsh
      TN_PLUGIN_SRC[$name]=$TN_PLUGIN_DIR/$name/$name.zsh
      return 0
    fi
  fi
  print -P "%F{red}tn:%f could not load $name (not installed, and the clone failed). Run: tn-doctor" >&2
  return 1
}

# ---- Tokyo Night colors (set BEFORE the plugins load) ------------------------------
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[function]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#bb9af7,italic'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f7768e'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[path]='fg=#c0caf5,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#7dcfff'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#89ddff'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#565f89'

_tn_plugin zsh-autosuggestions     zsh-users/zsh-autosuggestions     _zsh_autosuggest_start
_tn_plugin zsh-syntax-highlighting zsh-users/zsh-syntax-highlighting _zsh_highlight   # keep this last
unfunction _tn_plugin
