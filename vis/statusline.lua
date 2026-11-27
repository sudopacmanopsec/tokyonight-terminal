-- ~/.config/vis/statusline.lua
local mode_colors = {
    [vis.modes.NORMAL]           = 'fore:#15161e,back:#7aa2f7,bold',
    [vis.modes.OPERATOR_PENDING] = 'fore:#15161e,back:#e0af68,bold',
    [vis.modes.INSERT]           = 'fore:#15161e,back:#9ece6a,bold',
    [vis.modes.VISUAL]           = 'fore:#15161e,back:#bb9af7,bold',
    [vis.modes.VISUAL_LINE]      = 'fore:#15161e,back:#bb9af7,bold',
    [vis.modes.REPLACE]          = 'fore:#15161e,back:#f7768e,bold',
}

local mode_names  = {
    [vis.modes.NORMAL]           = 'NORMAL',
    [vis.modes.OPERATOR_PENDING] = 'NORMAL',
    [vis.modes.INSERT]           = 'INSERT',
    [vis.modes.VISUAL]           = 'VISUAL',
    [vis.modes.VISUAL_LINE]      = 'V-LINE',
    [vis.modes.REPLACE]          = 'REPLACE',
}

local id_mode     = 500
local id_bar      = 501
local id_slate    = 502
local last_mode   = nil

local function sync_styles()
    if vis.mode ~= last_mode then
        last_mode = vis.mode
        local accent = mode_colors[vis.mode] or mode_colors[vis.modes.NORMAL]
        vis.ui:style_define(id_mode, accent)
        vis.ui:style_define(id_bar, 'fore:#a9b1d6,back:#16161e')
        vis.ui:style_define(id_slate, 'fore:#c0caf5,back:#3b4261')
    end
end

vis.events.subscribe(vis.events.WIN_STATUS, function(win)
    sync_styles()

    local mode_label = mode_names[vis.mode] or 'NORMAL'
    local name = win.file.name and win.file.name:match('([^/]+)$') or '[No Name]'
    if win.file.modified then
        name = name .. ' [+]'
    end

    local syntax = win.syntax or 'text'
    local line   = win.selection.line or 1
    local col    = win.selection.col or 1
    local total  = #win.file.lines
    local pct    = (line == 1) and 'Top' or
        ((line >= total) and 'Bot' or string.format('%d%%', math.floor((line / total) * 100)))

    local left   = string.format(' %s  %s ', mode_label, name)
    local right  = string.format(' utf-8 │  │ %s  %s  %d:%d ', syntax, pct, line, col)
    win:status(left, right)
end)

-- Only paint cell positions during UI_DRAW (never call style_define here!)
vis.events.subscribe(vis.events.UI_DRAW, function()
    local win = vis.win
    if not win then return end

    local row               = win.height - 1
    local mode_label        = mode_names[vis.mode] or 'NORMAL'
    local left_end          = #mode_label + 1

    local syntax            = win.syntax or 'text'
    local line              = win.selection.line or 1
    local col               = win.selection.col or 1
    local total             = #win.file.lines
    local pct               = (line == 1) and 'Top' or
        ((line >= total) and 'Bot' or string.format('%d%%', math.floor((line / total) * 100)))

    local mode_block_str    = string.format(' %s  %d:%d ', pct, line, col)
    local slate_block_str   = string.format(' %s ', syntax)

    local mode_block_start  = win.width - #mode_block_str
    local slate_block_start = mode_block_start - #slate_block_str

    for c = 0, win.width - 1 do
        if c <= left_end or c >= mode_block_start then
            win:style_pos(id_mode, c, row)
        elseif c >= slate_block_start then
            win:style_pos(id_slate, c, row)
        else
            win:style_pos(id_bar, c, row)
        end
    end
end)
