# ==============================================================================
# distro/arch.zsh :: Arch Linux (pacman + systemd)
# ==============================================================================

# pacman
alias pmi='sudo pacman -S'                     # install
alias pmu='sudo pacman -Syu'                   # full system update
alias pmr='sudo pacman -Rns'                   # remove + unused deps + configs
alias pms='pacman -Ss'                         # search repos
alias pmq='pacman -Qe'                         # explicitly installed
alias pmf='pacman -Ql'                         # files in a package
alias pmo='sudo pacman -Rns $(pacman -Qdtq)'   # remove orphans
alias pmc='sudo pacman -Sc'                    # clear old cache

# systemd
alias svs='systemctl list-units --type=service --state=running'
svr()   { sudo systemctl restart "$1"; }       # svr bluetooth
sven()  { sudo systemctl enable --now "$1"; }  # enable + start
svdis() { sudo systemctl disable --now "$1"; } # stop + disable
