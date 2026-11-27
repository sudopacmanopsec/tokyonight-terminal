require('vis')

-- Helper to safely require optional plugins without crashing
local function safe_require(mod)
    local ok, err = pcall(require, mod)
    if not ok then
        vis:info('Optional plugin skipped: ' .. mod)
    end
end

-- plugins
safe_require('plugins/vis-commentary')
safe_require('plugins/fzf-mru')
safe_require('plugins/ctags')
safe_require('plugins/cursors')
safe_require('plugins/vis-autoclose')

-- leader lol
leader = '<Space>'

-- Fuzzy file & content search (requires fzf / ripgrep installed)
vis:command_register("fzf", function(argv, force, cur_win, selection, range)
    local out = io.popen("fzf"):read()
    if out then
        if argv[1] then
            vis:command(string.format('e "%s"', out))
        else
            vis:command(string.format('open "%s"', out))
        end
        vis:feedkeys("<vis-redraw>")
    end
end, 'fuzzy file search')

vis:command_register("rg", function(argv, force, cur_win, selection, range)
    local out = io.popen("irg"):read()
    if out then
        if argv[1] then
            vis:command(string.format('e "%s"', out))
        else
            vis:command(string.format('open "%s"', out))
        end
        vis:feedkeys("<vis-redraw>")
    end
end, 'fuzzy file-content search')

vis.events.subscribe(vis.events.INIT, function()
    -- Theme (make sure ~/.config/vis/themes/tokyonight.lua exists)
    vis:command('set theme tokyonight')

    -- Base mappings from the copied config
    vis:map(vis.modes.NORMAL, leader .. 'a', ':rg true<Enter>')
    vis:map(vis.modes.NORMAL, leader .. 'A', ':rg<Enter>')
    vis:map(vis.modes.NORMAL, leader .. 'CC', ':e ~/.config/vis/visrc.lua<Enter>')
    vis:map(vis.modes.NORMAL, leader .. 'e', ':fzf true<Enter>')
    vis:map(vis.modes.NORMAL, leader .. 'o', ':fzf<Enter>')
    vis:map(vis.modes.NORMAL, leader .. 'l', ':set show-newline!<Enter>')
    vis:map(vis.modes.NORMAL, leader .. 'n', ':set numbers!<Enter>')
    vis:map(vis.modes.NORMAL, leader .. 'N', ':set relativenumbers!<Enter>')
    vis:map(vis.modes.NORMAL, leader .. 'q', ':q<Enter>')
    vis:map(vis.modes.NORMAL, leader .. 'Q', ':qa<Enter>')
    vis:map(vis.modes.NORMAL, leader .. 'w', ':x/ +$/ c//<Enter>:w<Enter>')
    vis:map(vis.modes.NORMAL, '<Tab><Tab>', '<vis-window-next>')
    vis:map(vis.modes.NORMAL, leader .. '%', ':vsplit<Enter>')
    vis:map(vis.modes.NORMAL, '] ', function() vis:feedkeys('o<Escape><Up>') end)
    vis:map(vis.modes.NORMAL, '[ ', function() vis:feedkeys('O<Escape><Down>') end)

    -- Word completion from current buffer
    vis:map(vis.modes.INSERT, '<C-x><C-n>', function()
        local tmpfile = '/tmp/vis-complete'
        local fp = io.popen('vis-complete --word >' .. tmpfile, 'w')
        fp:write(vis.win.file:content(0, vis.win.file.size))
        fp:close()
        local f = io.open(tmpfile, 'r')
        local output = f:read()
        if output then
            vis:insert(output)
        end
        f:close()
        vis:feedkeys("<vis-redraw>")
    end)

    -- require files
    require('keybindings')
    require('padding')
    require('statusline')
    require('lsp')
end)

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
    vis:command('set relativenumbers')
    vis:command('set savemethod inplace')
    vis:command('set showtabs')
    vis:command('set autoindent')
    vis:command('set tabwidth 4')
    vis:command('set colorcolumn 0')

    if vis.win.syntax == 'python' then
        vis:command('set expandtab')
    elseif vis.win.syntax == 'yaml' then
        vis:command('set tabwidth 2')
        vis:command('set expandtab')
    end
end)
