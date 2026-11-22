
local function reformat_parenthesized_content()
    local bufnr = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1]

    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    if not line then return end

    -- Find the first opening parenthesis.
    local open = line:find("%(")
    if not open then
        vim.notify("No opening parenthesis found", vim.log.levels.ERROR)
        return
    end

    -- Find its matching closing parenthesis.
    local depth = 0
    local quote = nil
    local escaped = false
    local close = nil

    for i = open, #line do
        local char = line:sub(i, i)

        if quote then
            if escaped then
                escaped = false
            elseif char == "\\" then
                escaped = true
            elseif char == quote then
                quote = nil
            end
        elseif char == '"' or char == "'" or char == "`" then
            quote = char
        elseif char == "(" then
            depth = depth + 1
        elseif char == ")" then
            depth = depth - 1

            if depth == 0 then
                close = i
                break
            end
        end
    end

    if not close then
        vim.notify("No matching closing parenthesis found", vim.log.levels.ERROR)
        return
    end

    local prefix = line:sub(1, open - 1)
    local content = line:sub(open + 1, close - 1)
    local suffix = line:sub(close + 1)

    -- Split only on commas at the top level.
    local parts = {}
    local start = 1
    depth = 0
    quote = nil
    escaped = false

    for i = 1, #content do
        local char = content:sub(i, i)

        if quote then
            if escaped then
                escaped = false
            elseif char == "\\" then
                escaped = true
            elseif char == quote then
                quote = nil
            end
        elseif char == '"' or char == "'" or char == "`" then
            quote = char
        elseif char == "(" or char == "{" or char == "[" then
            depth = depth + 1
        elseif char == ")" or char == "}" or char == "]" then
            depth = depth - 1
        elseif char == "," and depth == 0 then
            parts[#parts + 1] = vim.trim(content:sub(start, i - 1))
            start = i + 1
        end
    end

    local last = vim.trim(content:sub(start))

    if last ~= "" then
        parts[#parts + 1] = last
    end

    if #parts == 0 then
        vim.notify("No comma-separated content found", vim.log.levels.ERROR)
        return
    end

    -- Build the reformatted lines.
    local new_lines = {
        prefix .. "(",
    }

    for i, part in ipairs(parts) do
        local comma = i < #parts and "," or ""
        new_lines[#new_lines + 1] = "        " .. part .. comma
    end

    new_lines[#new_lines + 1] = "    )" .. suffix

    vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, new_lines)
end

vim.keymap.set("n", "<leader>qq", reformat_parenthesized_content, {
    desc = "Reformat parenthesized content",
})

