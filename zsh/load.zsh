# ==============================================================================
# tokyonight-terminal :: load.zsh
#
# The ONE line to add at the BOTTOM of your own ~/.zshrc:
#
#     source ~/.config/zsh/tn/load.zsh
#
# This is an add-on. It never edits or replaces your zshrc, your prompt, your
# history or your options. Delete that line and everything is gone.
#
# Order matters and is handled here:
#   interactive.zsh  completion + fzf-tab + Ctrl+P / Ctrl+F / nf
#   aliases.zsh      everyday aliases and helpers (t, tmh, nvh, playground, cfg, tn-doctor)
#   distro/<id>.zsh  package + service aliases for your distro (void, gentoo)
#   plugins.zsh      autosuggestions, then syntax-highlighting LAST
#
# Distro is read from /etc/os-release. To force it, set this before the source line:
#     TN_DISTRO=gentoo
# ==============================================================================

# directory this file lives in (works wherever you copied it)
typeset -g TN_DIR=${${(%):-%N}:A:h}

if [[ -z ${TN_DISTRO:-} && -r /etc/os-release ]]; then
  typeset -g TN_DISTRO=${${(M)${(f)"$(</etc/os-release)"}:#ID=*}#ID=}
  TN_DISTRO=${TN_DISTRO//[\"\']/}
fi

source $TN_DIR/interactive.zsh
source $TN_DIR/aliases.zsh
[[ -n ${TN_DISTRO:-} && -r $TN_DIR/distro/$TN_DISTRO.zsh ]] && source $TN_DIR/distro/$TN_DISTRO.zsh
source $TN_DIR/plugins.zsh
