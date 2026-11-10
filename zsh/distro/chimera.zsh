# ==============================================================================
# distro/chimera.zsh :: Chimera Linux (apk + dinit)
# Chimera ships doas by default. If you use sudo instead, replace "doas" with "sudo".
# ==============================================================================

# apk
alias api='doas apk add'                                  # install
alias apu='doas apk update && doas apk upgrade --available'  # full system update
alias apr='doas apk del'                                  # remove
alias aps='apk search'                                    # search repos
alias apl='apk list --installed'                          # installed packages
alias apf='apk info -L'                                   # files in a package
alias apw='apk info -W'                                   # which package owns a file
alias apc='doas apk cache clean'                          # clear cache

# dinit
alias svs='doas dinitctl list'
svr()   { doas dinitctl restart "$1"; }                   # svr bluetoothd
sven()  { doas dinitctl enable "$1"; }                    # enable (and start)
svdis() { doas dinitctl stop "$1"; doas dinitctl disable "$1"; }  # stop + disable
