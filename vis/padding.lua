-- ~/.config/vis/padding.lua
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
    vis:command('set numberwidth 5')
    vis:command('set cursorline')
    vis:command('set colorcolumn 0')
end)
