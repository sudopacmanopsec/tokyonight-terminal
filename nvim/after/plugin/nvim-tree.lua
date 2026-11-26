local ok, nvim_tree = pcall(require, "nvim-tree")
if not ok then
    return
end

nvim_tree.setup({
    view = {
        width = 30,
        side = "left",
    },
    update_focused_file = {
        enable = true, -- highlights the current open file in the tree
    },
    renderer = {
        group_empty = true, -- collapses empty single-child folders
    },
})
