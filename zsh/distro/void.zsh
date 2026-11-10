# ==============================================================================
# distro/void.zsh :: Void Linux (xbps + runit)
# ==============================================================================

# xbps
alias xi='sudo xbps-install'
alias xu='sudo xbps-install -Su'     # full system update
alias xr='sudo xbps-remove -R'       # remove + unused deps
alias xs='xbps-query -Rs'            # search repos
alias xinfo='xbps-query -RS'         # package info
alias xl='xbps-query -m'             # manually installed
alias xf='xbps-query -f'             # files in a package
alias xorph='sudo xbps-remove -o'    # remove orphans
alias xclean='sudo xbps-remove -O'   # clear cache

# runit
alias svs='sudo sv status /var/service/*'
alias svr='sudo sv restart'
sven()  { sudo ln -s "/etc/sv/$1" /var/service/; }   # enable:  sven bluetoothd
svdis() { sudo rm "/var/service/$1"; }               # disable: svdis bluetoothd
