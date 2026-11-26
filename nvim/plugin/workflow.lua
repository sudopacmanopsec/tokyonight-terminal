-- ~/.config/nvim/plugin/workflow.lua
-- Drop-in for tonybanters/nvim. Does NOT touch his plugin manager or any of his files.
--   * NvChad-style startup dashboard (pure Lua, no plugin)
--   * VSCode-style: quick open, command palette, project grep, new/rename/copy/delete file
-- Uses Telescope (already in his config) when present, with a plain fallback if not.
-- Files in plugin/ are sourced automatically after init.lua, so leader is already set.

if vim.g.loaded_workflow then return end
vim.g.loaded_workflow = true

local uv = vim.uv or vim.loop
local WARN, ERROR = vim.log.levels.WARN, vim.log.levels.ERROR

-- ------------------------------------------------------------------ settings
local cfg = {
    icons = false,         -- set true if your terminal font is a Nerd Font
    vscode_ctrl_p = false, -- true = <C-p> opens quick-open (this overrides his Harpoon <C-p>)
    button_width = 40,
    header = {
        "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
        "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
        "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
        "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
        "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
        "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
    },
}

local M = {}

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "workflow" })
end

-- ------------------------------------------------------------------ finders
local function telescope(picker, opts, dropdown)
    local ok, builtin = pcall(require, "telescope.builtin")
    if not ok or not builtin[picker] then return false end
    opts = opts or {}
    if dropdown then
        local okt, themes = pcall(require, "telescope.themes")
        if okt then opts = themes.get_dropdown(vim.tbl_extend("force", { previewer = false }, opts)) end
    end
    builtin[picker](opts)
    return true
end

-- VSCode Ctrl+P
function M.quick_open()
    if telescope("find_files", {
            hidden = true,
            prompt_title = "Go to file",
            file_ignore_patterns = { "^%.git/", "node_modules/" },
        }, true) then
        return
    end

    -- fallback without telescope
    local files = vim.fn.systemlist("fd --type f --hidden --exclude .git")
    if vim.v.shell_error ~= 0 then
        files = vim.fn.systemlist("find . -type f -not -path '*/.git/*'")
    end
    vim.ui.select(files, { prompt = "Go to file" }, function(choice)
        if choice then vim.cmd.edit(vim.fn.fnameescape(choice)) end
    end)
end

-- VSCode Ctrl+Shift+P
function M.palette()
    if not telescope("commands", { prompt_title = "Command palette" }, true) then
        vim.api.nvim_feedkeys(":", "n", false)
    end
end

-- VSCode Ctrl+Shift+F
function M.grep()
    if not telescope("live_grep", { prompt_title = "Search in project" }) then
        notify("Project search needs telescope.nvim + ripgrep", WARN)
    end
end

function M.recent()
    if not telescope("oldfiles", { prompt_title = "Recent files" }, true) then
        vim.cmd("browse oldfiles")
    end
end

function M.config()
    local dir = vim.fn.stdpath("config")
    if not telescope("find_files", { cwd = dir, prompt_title = "Neovim config" }, true) then
        vim.cmd.edit(vim.fn.fnameescape(dir .. "/init.lua"))
    end
end

-- ------------------------------------------------------------ file maker
local function clean(input)
    input = vim.trim(input)
    return (input:gsub("^~", vim.env.HOME or "~"))
end

local function current_file()
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" or vim.bo.buftype ~= "" then return nil end
    return name
end

-- create "a/b/c.lua" (dirs made automatically) or "a/b/" (folder only)
local function create(input)
    if not input or vim.trim(input) == "" then return end
    input = clean(input)
    local is_dir = input:sub(-1) == "/"
    local path = vim.fn.fnamemodify(input, ":p")

    if is_dir then
        local ok, err = pcall(vim.fn.mkdir, path, "p")
        if ok then notify("Created folder " .. vim.fn.fnamemodify(path, ":~:.")) else notify(tostring(err), ERROR) end
        return
    end

    local ok, err = pcall(vim.fn.mkdir, vim.fn.fnamemodify(path, ":h"), "p")
    if not ok then return notify(tostring(err), ERROR) end
    if not uv.fs_stat(path) then
        local fd = uv.fs_open(path, "a", 420) -- 0644
        if fd then uv.fs_close(fd) end
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.new_file()
    local cur = current_file()
    local base = cur and vim.fn.fnamemodify(cur, ":p:h") or vim.fn.getcwd()
    local rel = vim.fn.fnamemodify(base, ":.")
    local default = (rel == "." or rel == "") and "" or (rel .. "/")
    vim.ui.input({ prompt = "New (end with / for folder): ", default = default, completion = "file" }, create)
end

function M.rename()
    local old = current_file()
    if not old then return notify("No file in this buffer", WARN) end
    local oldbuf = vim.api.nvim_get_current_buf()
    vim.ui.input({ prompt = "Rename to: ", default = vim.fn.fnamemodify(old, ":."), completion = "file" },
        function(input)
            if not input or vim.trim(input) == "" then return end
            local new = vim.fn.fnamemodify(clean(input), ":p")
            if new == old then return end
            if uv.fs_stat(new) then return notify("Already exists: " .. vim.fn.fnamemodify(new, ":~:."), WARN) end
            vim.cmd("silent! update")
            vim.fn.mkdir(vim.fn.fnamemodify(new, ":h"), "p")
            local ok, err = uv.fs_rename(old, new)
            if not ok then return notify("Rename failed: " .. tostring(err), ERROR) end
            vim.cmd.edit(vim.fn.fnameescape(new))
            pcall(vim.api.nvim_buf_delete, oldbuf, { force = true })
        end)
end

function M.copy()
    local old = current_file()
    if not old then return notify("No file in this buffer", WARN) end
    vim.ui.input({ prompt = "Copy to: ", default = vim.fn.fnamemodify(old, ":."), completion = "file" }, function(input)
        if not input or vim.trim(input) == "" then return end
        local new = vim.fn.fnamemodify(clean(input), ":p")
        if new == old then return end
        if uv.fs_stat(new) then return notify("Already exists: " .. vim.fn.fnamemodify(new, ":~:."), WARN) end
        vim.cmd("silent! update")
        vim.fn.mkdir(vim.fn.fnamemodify(new, ":h"), "p")
        local ok, err = uv.fs_copyfile(old, new)
        if not ok then return notify("Copy failed: " .. tostring(err), ERROR) end
        vim.cmd.edit(vim.fn.fnameescape(new))
    end)
end

function M.delete()
    local file = current_file()
    if not file then return notify("No file in this buffer", WARN) end
    local name = vim.fn.fnamemodify(file, ":~:.")
    if vim.fn.confirm("Delete " .. name .. "?", "&Yes\n&No", 2) ~= 1 then return end
    local buf = vim.api.nvim_get_current_buf()
    local others = vim.tbl_filter(function(b)
        return b ~= buf and vim.bo[b].buflisted
    end, vim.api.nvim_list_bufs())
    if #others > 0 then vim.api.nvim_set_current_buf(others[1]) else vim.cmd.enew() end
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    local ok, err = uv.fs_unlink(file)
    if ok then notify("Deleted " .. name) else notify("Delete failed: " .. tostring(err), ERROR) end
end

-- ------------------------------------------------------------ dashboard
local ns = vim.api.nvim_create_namespace("workflow_dashboard")
local state = { rows = {} }

local function set_hl()
    local set = vim.api.nvim_set_hl
    set(0, "DashHeader", { fg = "#7aa2f7", bold = true })
    set(0, "DashBorder", { fg = "#3b4261" })
    set(0, "DashIcon", { fg = "#bb9af7" })
    set(0, "DashLabel", { fg = "#c0caf5" })
    set(0, "DashKey", { fg = "#565f89" })
    set(0, "DashFooter", { fg = "#565f89", italic = true })
end

local function icon(code, fallback)
    return cfg.icons and vim.fn.nr2char(code) or fallback
end

local function render(buf, win, idx)
    local width = vim.api.nvim_win_get_width(win)
    local height = vim.api.nvim_win_get_height(win)
    local L = vim.g.mapleader == " " and "SPC" or (vim.g.mapleader or "\\")

    local btns = {
        { icon = icon(0xf002, "›"), label = "Find file", key = L .. " p", action = M.quick_open },
        { icon = icon(0xf1da, "›"), label = "Recent files", key = L .. " fo", action = M.recent },
        { icon = icon(0xf0b0, "›"), label = "Find word", key = L .. " /", action = M.grep },
        { icon = icon(0xf067, "›"), label = "New file", key = L .. " nn", action = M.new_file },
        { icon = icon(0xf013, "›"), label = "Config", key = L .. " fi", action = M.config },
        { icon = icon(0xf011, "›"), label = "Quit", key = "q", action = function() vim.cmd.qall() end },
    }

    local lines, marks = {}, {}
    state.rows = {}

    local function add(parts)
        local text = ""
        for _, p in ipairs(parts) do text = text .. p[1] end
        local pad = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
        local col = pad
        for _, p in ipairs(parts) do
            if p[2] then marks[#marks + 1] = { #lines, p[2], col, col + #p[1] } end
            col = col + #p[1]
        end
        lines[#lines + 1] = string.rep(" ", pad) .. text
        return #lines, pad
    end

    local content_h = #cfg.header + 1 + (#btns + 2) + 2
    for _ = 1, math.max(0, math.floor((height - content_h) / 2) - 1) do lines[#lines + 1] = "" end

    local hw = 0
    for _, l in ipairs(cfg.header) do hw = math.max(hw, vim.fn.strdisplaywidth(l)) end
    for _, l in ipairs(cfg.header) do
        add({ { l .. string.rep(" ", hw - vim.fn.strdisplaywidth(l)), "DashHeader" } })
    end
    add({ { "" } })

    local inner = cfg.button_width - 2
    add({ { "╭" .. string.rep("─", inner) .. "╮", "DashBorder" } })
    for _, b in ipairs(btns) do
        local left = " " .. b.icon .. "  " .. b.label
        local right = b.key .. " "
        local gap = math.max(1, inner - vim.fn.strdisplaywidth(left) - vim.fn.strdisplaywidth(right))
        local lnum, pad = add({
            { "│", "DashBorder" },
            { " " .. b.icon, "DashIcon" },
            { "  " .. b.label, "DashLabel" },
            { string.rep(" ", gap) },
            { right, "DashKey" },
            { "│", "DashBorder" },
        })
        state.rows[#state.rows + 1] = { lnum = lnum, col = pad + 4, action = b.action }
    end
    add({ { "╰" .. string.rep("─", inner) .. "╯", "DashBorder" } })

    local v = vim.version()
    add({ { "" } })
    add({ { string.format("nvim v%d.%d.%d  ·  %s", v.major, v.minor, v.patch,
        vim.fn.fnamemodify(vim.fn.getcwd(), ":~")), "DashFooter" } })

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for _, m in ipairs(marks) do
        vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[3], { end_col = m[4], hl_group = m[2] })
    end

    local r = state.rows[idx or 1] or state.rows[1]
    pcall(vim.api.nvim_win_set_cursor, win, { r.lnum, r.col })
end

local function current_idx()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    for i, r in ipairs(state.rows) do
        if r.lnum == lnum then return i end
    end
    return 1
end

local function move(dir)
    local i = ((current_idx() - 1 + dir) % #state.rows) + 1
    local r = state.rows[i]
    vim.api.nvim_win_set_cursor(0, { r.lnum, r.col })
end

local dash_win_opts = {
    number = false,
    relativenumber = false,
    cursorline = true,
    signcolumn = "no",
    foldcolumn = "0",
    list = false,
    colorcolumn = "",
    spell = false,
    statuscolumn = "",
    fillchars = "eob: ",
}

function M.dashboard()
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified or vim.bo[buf].buftype ~= "" then
        if vim.bo[buf].modified then return notify("Save the buffer first", WARN) end
        vim.cmd.enew()
        buf = vim.api.nvim_get_current_buf()
    end
    local win = vim.api.nvim_get_current_win()

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].buflisted = false
    vim.bo[buf].filetype = "dashboard"

    local saved = {}
    for k, v in pairs(dash_win_opts) do
        local ok, old = pcall(function() return vim.wo[win][k] end)
        if ok then
            saved[k] = old
            pcall(function() vim.wo[win][k] = v end)
        end
    end
    vim.api.nvim_create_autocmd("BufWinLeave", {
        buffer = buf,
        once = true,
        callback = function()
            if vim.api.nvim_win_is_valid(win) then
                for k, v in pairs(saved) do pcall(function() vim.wo[win][k] = v end) end
            end
        end,
    })

    set_hl()
    render(buf, win, 1)

    vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
        buffer = buf,
        callback = function()
            if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
                render(buf, win, current_idx())
            end
        end,
    })

    local o = { buffer = buf, silent = true, nowait = true }
    vim.keymap.set("n", "j", function() move(1) end, o)
    vim.keymap.set("n", "k", function() move(-1) end, o)
    vim.keymap.set("n", "<Down>", function() move(1) end, o)
    vim.keymap.set("n", "<Up>", function() move(-1) end, o)
    vim.keymap.set("n", "<CR>", function() state.rows[current_idx()].action() end, o)
    vim.keymap.set("n", "q", "<cmd>qall<cr>", o)
end

-- show on startup only for a bare `nvim` (no files, not piped stdin)
vim.api.nvim_create_autocmd("StdinReadPre", { callback = function() vim.g.workflow_stdin = true end })
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if #vim.api.nvim_list_uis() == 0 or vim.fn.argc() > 0 or vim.g.workflow_stdin then return end
        local b = vim.api.nvim_get_current_buf()
        if vim.fn.line2byte("$") ~= -1 or vim.api.nvim_buf_get_name(b) ~= "" or vim.bo[b].modified then return end
        M.dashboard()
    end,
})
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
set_hl()

-- ------------------------------------------------------------ sidebar (netrw tree)
-- NvChad/VSCode-style left sidebar built on netrw, so no plugin and no manager changes.
local function sidebar_win()
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "netrw" then return w end
    end
end

function M.sidebar()
    vim.g.netrw_banner = 0       -- NOTE: these are global, so :Ex gets the same look
    vim.g.netrw_liststyle = 3    -- tree view
    vim.g.netrw_winsize = 25     -- 25% width
    vim.g.netrw_altv = 1
    vim.g.netrw_browse_split = 4 -- open files in the previous window, keep the tree
    if sidebar_win() then
        vim.cmd.NvimTreeToggle() -- toggle closed
    else
        vim.cmd.NvimTreeToggle(vim.fn.fnameescape(vim.fn.getcwd()))
    end
end

-- nvim-tree-like keys inside the sidebar (netrw natives stay: d = new folder, D = delete)
vim.api.nvim_create_autocmd("FileType", {
    pattern = "netrw",
    callback = function(ev)
        local o = { buffer = ev.buf, remap = true, silent = true, nowait = true }
        vim.keymap.set("n", "a", "%", o)    -- new file (in the folder under the cursor)
        vim.keymap.set("n", "r", "R", o)    -- rename
        vim.keymap.set("n", "l", "<CR>", o) -- open file / expand folder
        vim.keymap.set("n", "h", "-", o)    -- up a directory
        vim.keymap.set("n", "q", "<cmd>NvimTreeToggle<cr>", { buffer = ev.buf, silent = true, nowait = true })
    end,
})

-- ------------------------------------------------------------ commands & keys

vim.api.nvim_create_user_command("Nf", function(o)
    if o.args == "" then
        M.new_file()
    else
        create(o.args)
    end
end, { nargs = "?", complete = "file", desc = "New file/folder" })

vim.api.nvim_create_user_command("Dash", M.dashboard, {
    desc = "Open dashboard",
})

-- Only register mappings if the key is currently unused.
local function map_if_free(mode, lhs, rhs, opts)
    local modes = type(mode) == "table" and mode or { mode }

    for _, m in ipairs(modes) do
        if vim.fn.maparg(lhs, m) ~= "" then
            return
        end
    end

    vim.keymap.set(mode, lhs, rhs, opts)
end

map_if_free("n", "<leader>p", M.quick_open, {
    desc = "Go to file",
})
map_if_free("n", "<leader>P", M.palette, {
    desc = "Command palette",
})
map_if_free("n", "<leader>/", M.grep, {
    desc = "Search in project",
})
map_if_free("n", "<leader>nn", M.new_file, {
    desc = "New file / folder",
})
map_if_free("n", "<leader>nr", M.rename, {
    desc = "Rename file",
})
map_if_free("n", "<leader>nc", M.copy, {
    desc = "Copy file",
})
map_if_free("n", "<leader>nd", M.delete, {
    desc = "Delete file",
})
map_if_free("n", "<leader>e", M.sidebar, {
    desc = "Toggle file sidebar",
})
map_if_free("n", "<leader>D", M.dashboard, {
    desc = "Dashboard",
})
map_if_free({ "n", "i" }, "<C-s>", "<cmd>write<cr>", {
    desc = "Save",
})

if cfg.vscode_ctrl_p then
    map_if_free("n", "<C-p>", M.quick_open, {
        desc = "Go to file",
    })
end
