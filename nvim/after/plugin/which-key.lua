local wk = require("which-key")

wk.setup({
    preset = "modern",
    delay = 300,

    icons = {
        mappings = true,
        keys = {},
    },

    win = {
        border = "rounded",
        padding = { 1, 2 },
    },

    layout = {
        width = { min = 20 },
        spacing = 3,
    },
})

wk.add({
    { "<leader>h", group = "Git hunks" },
    { "<leader>d", group = "Debug" },
    { "<leader>f", group = "Find" },
    { "<leader>g", group = "Git" },
    { "<leader>w", group = "Window" },
})
