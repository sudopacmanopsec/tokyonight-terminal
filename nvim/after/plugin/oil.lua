require("oil").setup({
    default_file_explorer = true,

    columns = {
        "icon",
    },

    win_options = {
        wrap = false,
        number = false,
        relativenumber = false,
        signcolumn = "no",
        cursorline = true,
        cursorcolumn = false,
        foldcolumn = "0",
    },

    view_options = {
        show_hidden = true,
        natural_order = true,
        case_insensitive = true,
        sort = {
            { "type", "asc" },
            { "name", "asc" },
        },
    },

    float = {
        padding = 2,
        max_width = 100,
        max_height = 30,
        border = "rounded",
    },

    keymaps = {
        ["q"] = "actions.close",
        ["<C-h>"] = false,
        ["<C-l>"] = false,
    },
})

-- Open parent directory
vim.keymap.set("n", "-", "<CMD>Oil<CR>", {
    desc = "Open file explorer",
})

-- Open Oil in a floating window
vim.keymap.set("n", "<leader>r", function()
    require("oil").open_float()
end, {
    desc = "Open floating file explorer",
})

-- Find files and reveal their location in Oil
vim.keymap.set("n", "<leader>sf", function()
    require("telescope.builtin").find_files({
        hidden = true,
        attach_mappings = function(_, map)
            map("i", "<C-o>", function(prompt_bufnr)
                local entry = require("telescope.actions.state").get_selected_entry()
                require("telescope.actions").close(prompt_bufnr)

                if entry then
                    require("oil").open(vim.fn.fnamemodify(entry.path, ":h"))
                    vim.schedule(function()
                        local name = vim.fn.fnamemodify(entry.path, ":t")
                        local line = vim.fn.search("^" .. vim.pesc(name) .. "$", "nw")
                        if line > 0 then
                            vim.api.nvim_win_set_cursor(0, { line, 0 })
                        end
                    end)
                end
            end)
            return true
        end,
    })
end, { desc = "Search files and reveal in Oil" })
