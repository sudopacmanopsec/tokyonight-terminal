vim.cmd.colorscheme("tokyonight")
vim.cmd("hi Directory guibg=NONE")
vim.cmd("hi SignColumn guibg=NONE")
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })

local hooks = require("ibl.hooks")

hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "IblIndent", { fg = "#3d59a1" })
    vim.api.nvim_set_hl(0, "IblScope", { fg = "#41a6b5" })
end)

require("ibl").setup({
    indent = { char = "│", highlight = "IblIndent" },
    scope = {
        char = "│",
        highlight = "IblScope",
        show_start = false,
        show_end = false,
    },
})

