local harpoon = require("harpoon")

harpoon:setup()

local map = vim.keymap.set

-- Add current file
map("n", "<leader>a", function()
    harpoon:list():add({
        value = vim.fn.expand("%:p"),
    })
end, { desc = "Harpoon: add file" })

-- Open Harpoon's native quick menu
map("n", "<C-e>", function()
    harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon: quick menu" })

-- Previous / next marked file
map("n", "<C-p>", function()
    harpoon:list():prev()
end, { desc = "Harpoon: previous file" })

map("n", "<C-n>", function()
    harpoon:list():next()
end, { desc = "Harpoon: next file" })

-- Jump directly to a marked file
for i = 1, 4 do
    map("n", "<leader>" .. i, function()
        harpoon:list():select(i)
    end, { desc = "Harpoon: file " .. i })
end

-- Telescope integration
map("n", "<leader>fl", function()
    local conf = require("telescope.config").values
    local themes = require("telescope.themes")
    local finders = require("telescope.finders")
    local pickers = require("telescope.pickers")

    local file_paths = {}

    for _, item in ipairs(harpoon:list().items) do
        table.insert(file_paths, item.value)
    end

    if #file_paths == 0 then
        vim.notify("Harpoon list is empty", vim.log.levels.INFO)
        return
    end

    pickers.new(themes.get_ivy({
        prompt_title = "Harpoon working list",
    }), {
        finder = finders.new_table({
            results = file_paths,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
    }):find()
end, { desc = "Harpoon: search working list" })
