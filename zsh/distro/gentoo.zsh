# ==============================================================================
# distro/gentoo.zsh :: Gentoo (portage + OpenRC)
# equery / eclean come from app-portage/gentoolkit
# ==============================================================================

# portage
alias ei='sudo emerge -av'                      # install
alias eu='sudo emerge -avuDN @world'            # full system update
alias esync='sudo emaint sync -a'               # sync the tree
alias er='sudo emerge -avC'                     # remove a package
alias edc='sudo emerge -av --depclean'          # remove orphans / unused deps
alias es='emerge -s'                            # search
alias einfo='emerge -pv'                        # package info (pretend)
alias el='cat /var/lib/portage/world'           # manually installed (world file)
alias ef='equery files'                         # files in a package
alias eb='equery belongs'                       # which package owns a file
alias eclean='sudo eclean-dist -d'              # clear old distfiles
alias ecf='sudo dispatch-conf'                  # merge config file updates
alias epr='sudo emerge -av @preserved-rebuild'  # fix preserved libs
alias enews='eselect news read'

# openrc (systemd users: swap these for systemctl)
alias svs='rc-status'
svr()   { sudo rc-service "$1" restart; }                                   # svr bluetooth
sven()  { sudo rc-update add "$1" default && sudo rc-service "$1" start; }  # enable + start
svdis() { sudo rc-service "$1" stop; sudo rc-update del "$1" default; }     # stop + disable
