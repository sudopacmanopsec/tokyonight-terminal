
-- TonyContext
-- Multi-level sticky Tree-sitter context.
--
-- Features:
--   * Nested function, class, struct and namespace context
--   * Configurable node types per language
--   * Multiple context lines
--   * Automatic updates on scrolling, editing and resizing
--   * Incremental Tree-sitter parsing
--   * Safe handling of missing parsers and invalid windows
--
-- Toggle:
--   <leader>th  hide
--   <leader>tu  show

local M = {
    enabled = true,
    max_lines = 5,
}

local ctx_buf
local ctx_win
local target_win
local last_signature

local namespace = vim.api.nvim_create_namespace("TonyContext")

-- ------------------------------------------------------------
-- Configuration
-- ------------------------------------------------------------

-- Common node types shared by multiple grammars.
local COMMON_TYPES = {
    function_definition = true,
    function_declaration = true,
    function_expression = true,
    arrow_function = true,
    method_definition = true,
    method_declaration = true,
    function_item = true,

    class_declaration = true,
    class_definition = true,
    interface_declaration = true,

    namespace_definition = true,
    namespace_declaration = true,

    struct_item = true,
    enum_item = true,
    impl_item = true,
    trait_item = true,

    module_definition = true,
    module = true,
}

-- Language-specific additions.
-- Add node names here when a grammar uses different names.
local LANGUAGE_TYPES = {
    c = {
        function_definition = true,
        struct_specifier = true,
        union_specifier = true,
    },

    cpp = {
        function_definition = true,
        class_specifier = true,
        struct_specifier = true,
        namespace_definition = true,
        lambda_expression = true,
    },

    php = {
        function_definition = true,
        method_declaration = true,
        class_declaration = true,
        trait_declaration = true,
        interface_declaration = true,
        namespace_definition = true,
    },

    lua = {
        function_declaration = true,
        function_definition = true,
    },

    rust = {
        function_item = true,
        impl_item = true,
        trait_item = true,
        struct_item = true,
        enum_item = true,
        mod_item = true,
    },

    javascript = {
        function_declaration = true,
        generator_function_declaration = true,
        function_expression = true,
        arrow_function = true,
        method_definition = true,
        class_declaration = true,
        lexical_declaration = false,
    },

    typescript = {
        function_declaration = true,
        function_expression = true,
        arrow_function = true,
        method_definition = true,
        class_declaration = true,
        interface_declaration = true,
        type_alias_declaration = true,
    },

    tsx = {
        function_declaration = true,
        function_expression = true,
        arrow_function = true,
        method_definition = true,
        class_declaration = true,
    },

    go = {
        function_declaration = true,
        method_declaration = true,
        type_declaration = true,
    },

    zig = {
        function_declaration = true,
        fn_proto = true,
        container_declaration = true,
    },

    nix = {
        function_expression = true,
        attrset_expression = true,
    },

    d = {
        function_declaration = true,
        class_declaration = true,
        struct_declaration = true,
        interface_declaration = true,
        template_declaration = true,
    },

    haskell = {
        ["function"] = true,
        data_type = true,
        class = true,
        instance = true,
    },
}

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------

local function close_context()
    if ctx_win and vim.api.nvim_win_is_valid(ctx_win) then
        pcall(vim.api.nvim_win_close, ctx_win, true)
    end

    ctx_win = nil
    target_win = nil
    last_signature = nil
end

local function get_scope_types(lang)
    local types = vim.tbl_extend(
        "force",
        {},
        COMMON_TYPES,
        LANGUAGE_TYPES[lang] or {}
    )

    -- Allow user-defined extensions.
    local custom = vim.g.tonycontext_scope_types

    if type(custom) == "table" and type(custom[lang]) == "table" then
        vim.tbl_extend("force", types, custom[lang])
    end

    return types
end

local function get_parser(bufnr)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)

    if not ok or not parser then
        return nil
    end

    local parsed, trees = pcall(function()
        return parser:parse()
    end)

    if not parsed or not trees or not trees[1] then
        return nil
    end

    return parser
end

local function get_scopes(bufnr, win)
    local parser = get_parser(bufnr)

    if not parser then
        return {}
    end

    local lang = parser:lang()
    local scope_types = get_scope_types(lang)

    local cursor = vim.api.nvim_win_get_cursor(win)
    local row = cursor[1] - 1
    local col = cursor[2]

    local ok, node = pcall(vim.treesitter.get_node, {
        bufnr = bufnr,
        pos = { row, col },
    })

    if not ok or not node then
        return {}
    end

    local top_visible = vim.fn.line("w0", win) - 1

    local scopes = {}
    local seen_rows = {}

    -- Walk from the innermost node towards the root.
    while node do
        local node_type = node:type()

        if scope_types[node_type] then
            local sr, sc, er, ec = node:range()

            -- Only display scopes that start above the viewport.
            if sr < top_visible and not seen_rows[sr] then
                local line = vim.api.nvim_buf_get_lines(
                    bufnr,
                    sr,
                    sr + 1,
                    false
                )[1]

                if line and vim.trim(line) ~= "" then
                    seen_rows[sr] = true

                    table.insert(scopes, {
                        row = sr,
                        col = sc,
                        end_row = er,
                        end_col = ec,
                        text = vim.trim(line),
                        type = node_type,
                    })
                end
            end
        end

        node = node:parent()
    end

    -- Reverse so the outermost scope appears first.
    local ordered = {}

    for i = #scopes, 1, -1 do
        ordered[#ordered + 1] = scopes[i]
    end

    -- Keep the nearest enclosing scopes when there are too many.
    while #ordered > M.max_lines do
        table.remove(ordered, 1)
    end

    return ordered
end

local function make_signature(scopes, bufnr, win, width)
    local parts = {
        tostring(bufnr),
        tostring(win),
        tostring(width),
    }

    for _, scope in ipairs(scopes) do
        parts[#parts + 1] = tostring(scope.row)
        parts[#parts + 1] = scope.text
    end

    return table.concat(parts, "\0")
end

-- ------------------------------------------------------------
-- Rendering
-- ------------------------------------------------------------

local function ensure_buffer()
    if ctx_buf and vim.api.nvim_buf_is_valid(ctx_buf) then
        return ctx_buf
    end

    ctx_buf = vim.api.nvim_create_buf(false, true)

    vim.bo[ctx_buf].buftype = "nofile"
    vim.bo[ctx_buf].bufhidden = "hide"
    vim.bo[ctx_buf].swapfile = false
    vim.bo[ctx_buf].modifiable = false
    vim.bo[ctx_buf].filetype = ""

    return ctx_buf
end

local function render(scopes, bufnr, win)
    local width = vim.api.nvim_win_get_width(win)
    local height = math.min(#scopes, M.max_lines)

    if height == 0 then
        close_context()
        return
    end

    local signature = make_signature(scopes, bufnr, win, width)

    if signature == last_signature
        and ctx_win
        and vim.api.nvim_win_is_valid(ctx_win)
    then
        return
    end

    -- A context window belongs to one target window.
    if target_win and target_win ~= win then
        close_context()
    end

    local buf = ensure_buffer()

    local lines = {}

    for _, scope in ipairs(scopes) do
        lines[#lines + 1] = scope.text
    end

    vim.bo[buf].modifiable = true

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.api.nvim_buf_clear_namespace(
        buf,
        namespace,
        0,
        -1
    )

    for i = 0, #lines - 1 do
        vim.api.nvim_buf_set_extmark(buf, namespace, i, 0, {
            line_hl_group = "TonyContextLine",
        })
    end

    vim.bo[buf].modifiable = false

    local config = {
        relative = "win",
        win = win,
        row = 0,
        col = 0,
        width = width,
        height = height,
        focusable = false,
        mouse = false,
        style = "minimal",
        zindex = 50,
    }

    if ctx_win and vim.api.nvim_win_is_valid(ctx_win) then
        local ok = pcall(vim.api.nvim_win_set_config, ctx_win, config)

        if not ok then
            close_context()
        end
    end

    if not ctx_win then
        ctx_win = vim.api.nvim_open_win(buf, false, config)

        vim.wo[ctx_win].wrap = false
        vim.wo[ctx_win].number = false
        vim.wo[ctx_win].relativenumber = false
        vim.wo[ctx_win].cursorline = false
        vim.wo[ctx_win].signcolumn = "no"
        vim.wo[ctx_win].foldcolumn = "0"
        vim.wo[ctx_win].winhighlight =
            "Normal:TonyContext,NormalFloat:TonyContext"
    end

    target_win = win
    last_signature = signature
end

-- ------------------------------------------------------------
-- Main update
-- ------------------------------------------------------------

local function update_context()
    if not M.enabled then
        close_context()
        return
    end

    local win = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_win_get_buf(win)

    if not vim.api.nvim_buf_is_valid(bufnr)
        or not vim.bo[bufnr].buflisted
        or vim.bo[bufnr].buftype ~= ""
        or not vim.api.nvim_buf_is_loaded(bufnr)
    then
        close_context()
        return
    end

    local scopes = get_scopes(bufnr, win)

    if #scopes == 0 then
        close_context()
        return
    end

    render(scopes, bufnr, win)
end

-- ------------------------------------------------------------
-- Highlighting
-- ------------------------------------------------------------

vim.api.nvim_set_hl(0, "TonyContext", {
    link = "NormalFloat",
    default = true,
})

vim.api.nvim_set_hl(0, "TonyContextLine", {
    link = "CursorLine",
    default = true,
})

-- ------------------------------------------------------------
-- Autocommands
-- ------------------------------------------------------------

local group = vim.api.nvim_create_augroup("TonyContext", {
    clear = true,
})

vim.api.nvim_create_autocmd({
    "CursorMoved",
    "CursorMovedI",
    "WinScrolled",
    "BufEnter",
    "WinEnter",
    "TextChanged",
    "TextChangedI",
    "VimResized",
}, {
    group = group,
    callback = update_context,
})

vim.api.nvim_create_autocmd({
    "BufLeave",
    "WinLeave",
}, {
    group = group,
    callback = close_context,
})

-- ------------------------------------------------------------
-- Commands and keybindings
-- ------------------------------------------------------------

vim.keymap.set("n", "<leader>th", function()
    M.enabled = false
    close_context()
end, {
    desc = "Hide Tree-sitter context",
})

vim.keymap.set("n", "<leader>tu", function()
    M.enabled = true
    update_context()
end, {
    desc = "Show Tree-sitter context",
})

vim.api.nvim_create_user_command("TonyContextToggle", function()
    M.enabled = not M.enabled

    if M.enabled then
        update_context()
    else
        close_context()
    end
end, {
    desc = "Toggle Tree-sitter context",
})

vim.api.nvim_create_user_command("TonyContextUpdate", update_context, {
    desc = "Update Tree-sitter context",
})

return M

