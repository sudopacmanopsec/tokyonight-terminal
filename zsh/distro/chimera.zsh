# Chimera Linux: apk (package manager), dinit (init), doas (sudo replacement).
# Sourced by load.zsh when /etc/os-release says ID=chimera.

# ---- apk ---------------------------------------------------------------------
alias aa='doas apk add'                                      # install
alias au='doas apk update && doas apk upgrade --available'   # full system update
alias ar='doas apk del'                                      # remove
alias as='apk search'                                        # search repos
alias al='apk list --installed'                              # installed packages
alias af='apk info -L'                                       # files in a package
alias aw='apk info -W'                                       # which package owns a file
alias ac='doas apk cache clean'                              # clear cache

# ---- dinit -------------------------------------------------------------------
alias svs='doas dinitctl list'
svr()   { doas dinitctl restart "$1"; }                      # svr bluetoothd
sven()  { doas dinitctl enable "$1"; }                       # enable (and start)
svdis() { doas dinitctl stop "$1"; doas dinitctl disable "$1"; }  # stop + disable

# ---- doas --------------------------------------------------------------------
alias sudo='doas'
