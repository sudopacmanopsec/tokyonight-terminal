
-- Custom Tree-sitter functionality

-- Query directives
local function case_directive(transform)
    return function(match, _, bufnr, pred, metadata)
        local id = pred[2]
        if type(id) ~= "number" then return end

        local nodes = match[id]
        if not nodes then return end
        if type(nodes) ~= "table" then nodes = { nodes } end

        local node = nodes[1]
        if not node then return end

        metadata[id] = metadata[id] or {}

        local text = vim.treesitter.get_node_text(node, bufnr, {
            metadata = metadata[id],
        }) or ""

        metadata[id].text = transform(text)
    end
end

vim.treesitter.query.add_directive(
    "downcase!",
    case_directive(string.lower),
    { force = true }
)

vim.treesitter.query.add_directive(
    "upcase!",
    case_directive(string.upper),
    { force = true }
)

-- Start Tree-sitter when a buffer enters a filetype.
vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        pcall(vim.treesitter.start, args.buf)
    end,
})

-- Find the smallest matching function range containing the cursor.
local function select_function(capture)
    local bufnr = vim.api.nvim_get_current_buf()

    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then
        vim.notify("No Tree-sitter parser available", vim.log.levels.WARN)
        return
    end

    local lang = parser:lang()

    local query_ok, query = pcall(
        vim.treesitter.query.get,
        lang,
        "textobjects"
    )

    if not query_ok or not query then
        vim.notify(
            "No textobjects query available for " .. lang,
            vim.log.levels.WARN
        )
        return
    end

    local parse_ok, trees = pcall(parser.parse, parser)
    if not parse_ok or not trees or not trees[1] then return end

    local root = trees[1]:root()

    local cursor = vim.api.nvim_win_get_cursor(0)
    local crow = cursor[1] - 1
    local ccol = cursor[2]

    local best
    local best_size

    for _, match in query:iter_matches(root, bufnr, 0, -1, { all = true }) do
        for id, nodes in pairs(match) do
            if query.captures[id] == capture then
                if type(nodes) ~= "table" then
                    nodes = { nodes }
                end

                for _, node in ipairs(nodes) do
                    local sr, sc, er, ec = node:range()

                    local contains =
                        (sr < crow or (sr == crow and sc <= ccol))
                        and
                        (er > crow or (er == crow and ec >= ccol))

                    if contains then
                        local size = (er - sr) * 1000000 + (ec - sc)

                        if not best_size or size < best_size then
                            best_size = size
                            best = { sr, sc, er, ec }
                        end
                    end
                end
            end
        end
    end

    if not best then
        vim.notify("No enclosing function found", vim.log.levels.INFO)
        return
    end

    local sr, sc, er, ec = unpack(best)

    -- Select the node using an exclusive end position.
    vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
    vim.cmd("normal! v")

    if er == sr then
        vim.api.nvim_win_set_cursor(0, { er + 1, math.max(sc, ec - 1) })
    else
        vim.api.nvim_win_set_cursor(0, { er + 1, math.max(0, ec - 1) })
    end
end

vim.keymap.set({ "x", "o" }, "af", function()
    select_function("function.outer")
end, {
    desc = "Around function",
})

vim.keymap.set({ "x", "o" }, "if", function()
    select_function("function.inner")
end, {
    desc = "Inside function",
})

