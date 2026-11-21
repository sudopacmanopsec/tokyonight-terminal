local gs = require("gitsigns")

gs.setup({
    signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
    },

    signcolumn = true,
    numhl = false,
    linehl = false,
    word_diff = false,

    current_line_blame = false,

    watch_gitdir = {
        follow_files = true,
    },

    preview_config = {
        border = "rounded",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
    },
})

-- Navigation
vim.keymap.set("n", "]c", gs.next_hunk, {
    desc = "Next Git hunk",
})

vim.keymap.set("n", "[c", gs.prev_hunk, {
    desc = "Previous Git hunk",
})

-- Hunk actions
vim.keymap.set("n", "<leader>hs", gs.stage_hunk, {
    desc = "Stage Git hunk",
})

vim.keymap.set("n", "<leader>hr", gs.reset_hunk, {
    desc = "Reset Git hunk",
})

vim.keymap.set("n", "<leader>hp", gs.preview_hunk, {
    desc = "Preview Git hunk",
})

-- Git information
vim.keymap.set("n", "<leader>hb", gs.blame_line, {
    desc = "Git blame line",
})

vim.keymap.set("n", "<leader>hd", gs.diffthis, {
    desc = "Diff current file",
})

vim.keymap.set("n", "<leader>hD", function()
    gs.diffthis("~")
end, {
    desc = "Diff against previous revision",
})
