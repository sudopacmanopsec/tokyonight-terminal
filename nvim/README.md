# nvim config

Clone straight into place and run:

```sh
git clone <this-repo-url> ~/.config/nvim
nvim
```

Plugins bootstrap themselves on first launch (needs `git` + internet).

If you already have a config: `mv ~/.config/nvim ~/.config/nvim.bak` first.

## Layout

```
init.lua                  entry point
lua/config/options.lua    options
lua/config/keymaps.lua    keymaps
lua/config/lazy.lua       lazy.nvim bootstrap
lua/plugins/              plugin specs
examples/zshrc.example    reference zshrc, not installed by anything
```

`examples/zshrc.example` is only an example. Nothing here copies or sources it;
take what you want from it into your own `~/.zshrc`.
