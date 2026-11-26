local actions = require("telescope.actions")

require("telescope").setup({
    defaults = {
        mappings = {
            i = {
                ["<C-k>"] = actions.move_selection_previous,
                ["<C-j>"] = actions.move_selection_next,
                ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            },
        },
    },
})

local builtin = require("telescope.builtin")
local state = require("telescope.state")

-- Resume the cached file finder, or create it on first use.
vim.keymap.set("n", "<leader>p", function()
    local cached = state.get_global_key("cached_pickers") or {}

    for i, picker in ipairs(cached) do
        if picker.prompt_title == "Find Files" then
            builtin.resume({ cache_index = i })
            return
        end
    end

    builtin.find_files()
end, { desc = "Resume file finder" })

vim.keymap.set("n", "<leader>fo", builtin.oldfiles)
vim.keymap.set("n", "<leader>fq", builtin.quickfix)

vim.keymap.set("n", "<leader>fh", builtin.help_tags, {
    desc = "Telescope help tags",
})

vim.keymap.set("n", "<leader>fm", function()
    builtin.man_pages({ sections = { "ALL" } })
end, { desc = "Telescope man pages" })

vim.keymap.set("n", "<leader>fb", builtin.buffers, {
    desc = "Telescope buffers",
})

vim.keymap.set("n", "<leader>fg", function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)

vim.keymap.set("n", "<leader>fc", function()
    builtin.grep_string({ search = vim.fn.expand("%:t:r") })
end, { desc = "Find current file" })

vim.keymap.set("n", "<leader>fs", function()
    builtin.grep_string({})
end, { desc = "Find current string" })

vim.keymap.set("n", "<leader>fi", function()
    builtin.find_files({ cwd = vim.fn.expand("~/.config/nvim/") })
end)
