-- ~/.config/vis/lsp.lua

local ok, lspc = pcall(require, 'plugins/vis-lspc')
if not ok then
    vis:info('vis-lspc plugin not found')
    return
end

lspc.autostart = true
lspc.highlight_diagnostics = false
lspc.show_message = 'message'
lspc.menu_cmd = 'vis-menu -l 10'
lspc.confirm_cmd = 'vis-menu'
lspc.logging = true

-- ==========================================
-- KEYBINDINGS
-- ==========================================

local function remap(mode, lhs, rhs)
    vis:unmap(mode, lhs)
    vis:map(mode, lhs, rhs)
end

-- ==========================================
-- LANGUAGE SERVERS
-- ==========================================

local clangd_cfg = {
    name = 'clangd',
    cmd = 'clangd --background-index --header-insertion=never --completion-style=bundled --function-arg-placeholders=0',
}

local servers = {
    lua        = { name = 'luals', cmd = 'lua-language-server' },
    css        = { name = 'cssls', cmd = 'vscode-css-language-server --stdio' },
    php        = { name = 'phpls', cmd = 'intelephense --stdio' },
    javascript = { name = 'ts_ls', cmd = 'typescript-language-server --stdio' },
    typescript = { name = 'ts_ls', cmd = 'typescript-language-server --stdio' },
    zig        = { name = 'zls', cmd = 'zls' },
    nix        = { name = 'nil_ls', cmd = 'nil' },
    python     = { name = 'pylsp', cmd = 'pylsp' },
    rust       = { name = 'rust_analyzer', cmd = 'rust-analyzer' },
    c          = clangd_cfg,
    ansi_c     = clangd_cfg,
    cpp        = clangd_cfg,
    d          = { name = 'serve_d', cmd = 'serve-d' },
    json       = { name = 'jsonls', cmd = 'vscode-json-language-server --stdio' },
    haskell    = { name = 'hls', cmd = 'haskell-language-server-wrapper --lsp' },
    go         = { name = 'gopls', cmd = 'gopls' },
}

for lang, cfg in pairs(servers) do
    lspc.ls_map[lang] = cfg
end

-- ==========================================
-- COMPLETION
-- ==========================================

remap(vis.modes.INSERT, '<C-Space>', '<Escape>:lspc-completion<Enter>a')
remap(vis.modes.INSERT, '<C-@>', '<Escape>:lspc-completion<Enter>a')
remap(vis.modes.INSERT, '<C-n>', '<Escape>:lspc-completion<Enter>a')

-- ==========================================
-- NAVIGATION
-- ==========================================

remap(vis.modes.NORMAL, 'K', ':lspc-hover<Enter>')
remap(vis.modes.NORMAL, 'gd', ':lspc-definition<Enter>')
remap(vis.modes.NORMAL, 'gD', ':lspc-declaration<Enter>')
remap(vis.modes.NORMAL, 'gi', ':lspc-implementation<Enter>')
remap(vis.modes.NORMAL, 'go', ':lspc-type-definition<Enter>')
remap(vis.modes.NORMAL, 'gr', ':lspc-references<Enter>')

-- ==========================================
-- INFORMATION & DIAGNOSTICS
-- ==========================================

remap(vis.modes.NORMAL, 'gs', ':lspc-signature-help<Enter>')
remap(vis.modes.NORMAL, 'gl', ':lspc-show-diagnostics<Enter>')
remap(vis.modes.NORMAL, '[d', ':lspc-prev-diagnostic<Enter>')
remap(vis.modes.NORMAL, ']d', ':lspc-next-diagnostic<Enter>')

-- ==========================================
-- ACTIONS
-- ==========================================

remap(vis.modes.NORMAL, '<F2>', ':lspc-rename ')
remap(vis.modes.NORMAL, '<F3>', ':lspc-format<Enter>')
remap(vis.modes.VISUAL, '<F3>', ':lspc-format<Enter>')
remap(vis.modes.NORMAL, '<F4>', ':lspc-code-action<Enter>')
