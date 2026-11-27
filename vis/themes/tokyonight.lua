local lexers                   = vis.lexers

-- Official folke/tokyonight.nvim (Night) palette + transparent background
local colors                   = {
    bg_dark   = '#16161e',
    bg_hl     = '#292e42',
    fg        = '#c0caf5',
    fg_dark   = '#a9b1d6',
    fg_gutter = '#3b4261',
    comment   = '#565f89',
    cyan      = '#7dcfff',
    blue      = '#7aa2f7',
    blue1     = '#2ac3de',
    blue2     = '#0db9d7',
    blue5     = '#89ddff',
    blue7     = '#394b70',
    purple    = '#9d7cd8',
    magenta   = '#bb9af7',
    magenta2  = '#ff007c',
    green     = '#9ece6a',
    green1    = '#73daca',
    teal      = '#1abc9c',
    yellow    = '#e0af68',
    orange    = '#ff9e64',
    red       = '#f7768e',
}

-- Transparent backgrounds (matches vim.api.nvim_set_hl(0, "Normal", { bg = "none" }))
lexers.STYLE_DEFAULT           = 'fore:' .. colors.fg .. ',back:default'
lexers.STYLE_NOTHING           = 'back:default'

-- Match Neovim Tree-sitter token hierarchy
lexers.STYLE_CLASS             = 'fore:' .. colors.blue1
lexers.STYLE_COMMENT           = 'fore:' .. colors.comment .. ',italics'
lexers.STYLE_CONSTANT          = 'fore:' .. colors.orange
lexers.STYLE_DEFINITION        = 'fore:' .. colors.blue
lexers.STYLE_ERROR             = 'fore:' .. colors.red .. ',italics'
lexers.STYLE_FUNCTION          = 'fore:' .. colors.blue
lexers.STYLE_KEYWORD           = 'fore:' .. colors.magenta .. ',italics'
lexers.STYLE_LABEL             = 'fore:' .. colors.blue
lexers.STYLE_NUMBER            = 'fore:' .. colors.orange
lexers.STYLE_OPERATOR          = 'fore:' .. colors.blue5
lexers.STYLE_REGEX             = 'fore:' .. colors.blue5
lexers.STYLE_STRING            = 'fore:' .. colors.green
lexers.STYLE_PREPROCESSOR      = 'fore:' .. colors.cyan
lexers.STYLE_TAG               = 'fore:' .. colors.magenta
lexers.STYLE_TYPE              = 'fore:' .. colors.blue1
lexers.STYLE_VARIABLE          = 'fore:' .. colors.fg
lexers.STYLE_IDENTIFIER        = 'fore:' .. colors.fg    -- Crisp @variable white instead of teal
lexers.STYLE_EMBEDDED          = 'fore:' .. colors.blue5 -- Format specifiers (%s\n) & interpolations
lexers.STYLE_WHITESPACE        = 'fore:' .. colors.fg_gutter

-- Gutter, cursor, & selection
lexers.STYLE_LINENUMBER        = 'fore:' .. colors.fg_gutter .. ',back:default'
lexers.STYLE_LINENUMBER_CURSOR = 'fore:' .. colors.orange .. ',back:' .. colors.bg_hl .. ',bold'

-- White cursor with reverse video so the character underneath
-- retains its original syntax-highlighted foreground.
lexers.STYLE_CURSOR            = 'fore:#ffffff,back:default,reverse'
lexers.STYLE_CURSOR_PRIMARY    = 'fore:#ffffff,back:default,reverse'

lexers.STYLE_CURSOR_LINE       = 'back:' .. colors.bg_hl
lexers.STYLE_COLOR_COLUMN      = 'back:' .. colors.bg_hl
lexers.STYLE_SELECTION         = 'back:' .. colors.blue7
