-- ~/.config/vis/keybindings.lua
local leader = '<Space>'

local function remap(mode, lhs, rhs)
    vis:unmap(mode, lhs)
    vis:map(mode, lhs, rhs)
end

-- Move selected lines down/up (Visual mode)
remap(vis.modes.VISUAL, 'J', ':><Enter>')
remap(vis.modes.VISUAL, 'K', ':<<Enter>')

-- Center cursor on search and half-page jumps (using vis actions to avoid loops)
remap(vis.modes.NORMAL, 'n', '<vis-search-repeat-forward>zz')
remap(vis.modes.NORMAL, 'N', '<vis-search-repeat-backward>zz')
remap(vis.modes.NORMAL, '<C-d>', '<vis-window-halfpage-down>zz')
remap(vis.modes.NORMAL, '<C-u>', '<vis-window-halfpage-up>zz')

-- Delete to black-hole register ("_) without overwriting clipboard
remap(vis.modes.NORMAL, leader .. 'd', '"_d')
remap(vis.modes.VISUAL, leader .. 'd', '"_d')
remap(vis.modes.VISUAL, leader .. 'p', '"_dP')

-- Esc navigation
remap(vis.modes.INSERT, '<C-c>', '<Escape>')
remap(vis.modes.INSERT, '<C-w>', '<Escape>lwi')
remap(vis.modes.INSERT, '<C-e>', '<Escape>lei')
remap(vis.modes.INSERT, '<C-b>', '<Escape>bi')

-- Prevent Ctrl+Z from suspending vis into the background
remap(vis.modes.NORMAL, '<C-z>', function() end)
remap(vis.modes.INSERT, '<C-z>', function() end)
remap(vis.modes.VISUAL, '<C-z>', function() end)

-- Insert-mode movement (Ctrl + h/j/k/l and Ctrl + w/b/e)
remap(vis.modes.INSERT, '<C-h>', '<vis-motion-char-prev>')
remap(vis.modes.INSERT, '<C-j>', '<vis-motion-line-down>')
remap(vis.modes.INSERT, '<C-k>', '<vis-motion-line-up>')
remap(vis.modes.INSERT, '<C-l>', '<vis-motion-char-next>')

remap(vis.modes.INSERT, '<C-w>', '<vis-motion-word-start-next>')
remap(vis.modes.INSERT, '<C-b>', '<vis-motion-word-start-prev>')
remap(vis.modes.INSERT, '<C-e>', '<vis-motion-word-end-next>')

-- Big WORD movement in Insert mode (via foot [text-bindings])
remap(vis.modes.INSERT, '<C-S-w>', '<vis-motion-bigword-start-next>')
remap(vis.modes.INSERT, '<C-S-b>', '<vis-motion-bigword-start-prev>')
remap(vis.modes.INSERT, '<C-S-e>', '<vis-motion-bigword-end-next>')

-- Disable arrow keys across Normal, Insert, and Visual modes (using an empty function)
for _, mode in ipairs({ vis.modes.NORMAL, vis.modes.INSERT, vis.modes.VISUAL }) do
    remap(mode, '<Up>', function() end)
    remap(mode, '<Down>', function() end)
    remap(mode, '<Left>', function() end)
    remap(mode, '<Right>', function() end)
end

-- Disable unused Q binding
remap(vis.modes.NORMAL, 'Q', function() end)

-- Backspace
remap(vis.modes.INSERT, '<Backspace>', '<vis-delete-char-prev>')

-- Wayland clipboard (requires wl-clipboard installed)
remap(vis.modes.NORMAL, leader .. 'p', ':< wl-paste<Enter>')
remap(vis.modes.VISUAL, leader .. 'y', ':> wl-copy<Enter>')

-- External commands & shell helpers
remap(vis.modes.NORMAL, leader .. 'x', ':!chmod +x "$vis_filepath"<Enter>')
remap(vis.modes.NORMAL, leader .. 'cc', ':!php-cs-fixer fix "$vis_filepath" --using-cache=no<Enter>')
remap(vis.modes.NORMAL, leader .. 'mm', ':!make<Enter>')

-- File picker
remap(vis.modes.NORMAL, leader .. 'cd', ':e .<Enter>')
