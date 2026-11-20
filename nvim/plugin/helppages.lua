-- ~/.config/nvim/plugin/helppages.lua
-- Drop-in cheat-sheet popups. Touches none of tonybanters' files or his plugin manager.
--   :KeyHelp   or <leader>hk   nvim keybinds (read from his config), Telescope, Harpoon, LSP
--   :TmuxHelp  or <leader>ht   tmux cheat sheet (reads ~/.config/tmux/help.txt)
-- In the popup: j/k/Ctrl+d/Ctrl+u scroll, / searches, q or <Esc> closes.

if vim.g.loaded_helppages then return end
vim.g.loaded_helppages = true

local M = {}
local ns = vim.api.nvim_create_namespace("helppages")

local function set_hl()
  local set = vim.api.nvim_set_hl
  set(0, "HelpHead", { fg = "#7aa2f7", bold = true })
  set(0, "HelpKey", { fg = "#bb9af7" })
  set(0, "HelpDesc", { fg = "#c0caf5" })
  set(0, "HelpDim", { fg = "#565f89", italic = true })
  set(0, "HelpBorder", { fg = "#7aa2f7" })
  set(0, "HelpNormal", { fg = "#c0caf5", bg = "#1a1b26" })
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

local function leader_label()
  local l = vim.g.mapleader
  if l == nil then return "\\" end
  if l == " " then return "SPC " end
  return l
end

-- marks are {line0, hl_group, col_start, col_end}
local function float(title, lines, marks)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[3], { end_col = m[4], hl_group = m[2] })
  end
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = math.max(40, math.min(96, vim.o.columns - 6))
  local height = math.max(8, math.min(#lines, vim.o.lines - 6))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    title = " " .. title .. " ",
    title_pos = "center",
  })
  vim.wo[win].winhighlight = "Normal:HelpNormal,FloatBorder:HelpBorder,FloatTitle:HelpHead"
  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false

  for _, k in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", k, "<cmd>close<cr>", { buffer = buf, nowait = true, silent = true })
  end
end

-- ------------------------------------------------------------------ nvim page
local sections = {
  { "Workflow  (workflow.lua)", {
    { "<leader>p", "Go to file (VSCode Ctrl+P)" },
    { "<leader>P", "Command palette" },
    { "<leader>/", "Search in the whole project" },
    { "<leader>nn", "New file or folder (a/b/c.lua, end with / for a folder)" },
    { "<leader>nr", "Rename current file" },
    { "<leader>nc", "Copy current file" },
    { "<leader>nd", "Delete current file (asks first)" },
    { "<leader>e", "Toggle file sidebar" },
    { "<leader>D", "Open the dashboard" },
    { "Ctrl+s", "Save (normal + insert mode)" },
    { ":Nf path", "Same as the zsh nf: make folders + file, then open it" },
  } },
  { "File sidebar keys", {
    { "a", "New file (in the folder under the cursor)" },
    { "d", "New folder" },
    { "r", "Rename" },
    { "D", "Delete" },
    { "l / Enter", "Open file / expand folder" },
    { "h", "Up a directory" },
    { "q", "Close the sidebar" },
  } },
  { "Telescope", {
    { "<leader>ff", "Find files" },
    { "<leader>fo", "Recent files" },
    { "<leader>fb", "Open buffers" },
    { "<leader>fg", "Grep: type a string, then pick a match" },
    { "<leader>fs", "Grep the word under the cursor" },
    { "<leader>fc", "Grep for this file's name (no extension)" },
    { "<leader>fi", "Find files in your nvim config" },
    { "<leader>fq", "Quickfix list" },
    { "<leader>fh", "Help tags" },
    { "<leader>fm", "Man pages" },
  } },
  { "Inside a Telescope window", {
    { "Ctrl+j / Ctrl+k", "Next / previous result (Ctrl+n / Ctrl+p work too)" },
    { "Enter", "Open" },
    { "Ctrl+x / Ctrl+v", "Open in horizontal / vertical split" },
    { "Ctrl+t", "Open in a new tab" },
    { "Tab", "Select several results" },
    { "Ctrl+q", "Send results to the quickfix list and open it" },
    { "Ctrl+u / Ctrl+d", "Scroll the preview" },
    { "Esc / Ctrl+c", "Close" },
    { "Ctrl+/  (insert)  ?  (normal)", "Show every Telescope mapping" },
  } },
  { "Harpoon  (pin the files you jump between)", {
    { "<leader>a", "Add the current file to the Harpoon list" },
    { "Ctrl+e", "Toggle the Harpoon menu" },
    { "Ctrl+p / Ctrl+n", "Previous / next Harpoon mark" },
    { "<leader>fl", "Harpoon list in Telescope" },
    { "In the menu", "Edit it like a buffer: dd removes a line, moving lines reorders, Enter opens" },
  } },
  { "LSP  (once a language server is attached)", {
    { "K", "Hover info" },
    { "gd / gD", "Go to definition / declaration" },
    { "gi / go", "Go to implementation / type definition" },
    { "gr", "References" },
    { "gs", "Signature help" },
    { "gl", "Diagnostics in a float" },
    { "F2", "Rename symbol" },
    { "F3", "Format code (normal + visual)" },
    { "F4", "Code actions" },
  } },
  { "Editing", {
    { "J  (normal)", "Join lines, cursor stays put" },
    { "J / K  (visual)", "Move the selected block down / up" },
    { "af / if  (visual, operator)", "Select around / inside the current function" },
    { "<leader>d", "Delete without touching the register" },
    { "<leader>p  (visual)", "Paste without overwriting the register" },
    { "<leader>y", "Yank to the system clipboard over OSC52 (works over ssh)" },
    { "<leader>s", "Replace the word under the cursor on this line" },
    { "<leader>qq", "Split the arguments in (...) onto separate lines" },
    { "<leader>dg", "Generate a doc comment for the function below" },
    { "<leader>cc", "Run php-cs-fixer on the file" },
    { "<leader>x", "chmod +x the current file" },
    { "Ctrl+c  (insert)", "Leave insert mode" },
  } },
  { "Moving and searching", {
    { "Ctrl+d / Ctrl+u", "Half page down / up, cursor stays centred" },
    { "n / N", "Next / previous search match, centred" },
    { "Q", "Disabled (no Ex mode)" },
  } },
  { "Quickfix and location list", {
    { "Ctrl+j / Ctrl+k", "Next / previous quickfix entry" },
    { "<leader>co / <leader>cl", "Open / close the quickfix list" },
    { "<leader>cn / <leader>cp", "Next / previous quickfix entry" },
    { "<leader>k / <leader>j", "Next / previous location-list entry" },
    { "<leader>mm", "Run make" },
  } },
  { "Everything else", {
    { "<leader>cd", "Open :Ex (netrw)" },
    { "<leader>ft", "Floating terminal (Esc Esc leaves terminal mode)" },
    { "<leader>u", "Toggle Undotree" },
    { "<leader>th / <leader>tu", "Hide / show the sticky function header" },
    { "<leader>li", "LSP info (:checkhealth vim.lsp)" },
    { "<leader>rl", "Reload the nvim config" },
    { "<leader><leader>", "Source the current file" },
  } },
}

function M.keys()
  local L = leader_label()
  local lines, marks = { "" }, {}
  for _, s in ipairs(sections) do
    local head = "  " .. s[1]
    marks[#marks + 1] = { #lines, "HelpHead", 0, #head }
    lines[#lines + 1] = head
    for _, row in ipairs(s[2]) do
      local key = (row[1]:gsub("<leader>", L))
      local pad = string.rep(" ", math.max(2, 26 - vim.fn.strdisplaywidth(key)))
      local line = "    " .. key .. pad .. row[2]
      marks[#marks + 1] = { #lines, "HelpKey", 4, 4 + #key }
      marks[#marks + 1] = { #lines, "HelpDesc", 4 + #key + #pad, #line }
      lines[#lines + 1] = line
    end
    lines[#lines + 1] = ""
  end
  local foot = ("  q / Esc close   ·   / search   ·   %s tmux help"):format(L .. "ht")
  marks[#marks + 1] = { #lines, "HelpDim", 0, #foot }
  lines[#lines + 1] = foot
  float("nvim keybinds", lines, marks)
end

-- ------------------------------------------------------------------ tmux page
function M.tmux()
  local path = vim.fn.expand("~/.config/tmux/help.txt")
  local f = io.open(path, "r")
  if not f then
    return vim.notify("Missing " .. path .. " (run install.sh from the repo)", vim.log.levels.WARN, { title = "helppages" })
  end
  local lines, marks = { "" }, {}
  for l in f:lines() do
    local i = #lines
    if l:match("^==") then
      l = "  " .. l  -- indent headings like everything else
      marks[#marks + 1] = { i, "HelpHead", 0, #l }
    else
      local pre, key, gap = l:match("^(%s+)(%S.-)(%s%s+)%S")
      if pre then
        marks[#marks + 1] = { i, "HelpKey", #pre, #pre + #key }
        marks[#marks + 1] = { i, "HelpDesc", #pre + #key + #gap, #l }
      elseif #l > 0 then
        marks[#marks + 1] = { i, "HelpDim", 0, #l }
      end
    end
    lines[#lines + 1] = l
  end
  f:close()
  local foot = "  q / Esc close   ·   / search   ·   tmux: run tmh"
  lines[#lines + 1] = ""
  marks[#marks + 1] = { #lines, "HelpDim", 0, #foot }
  lines[#lines + 1] = foot
  float("tmux cheat sheet", lines, marks)
end

vim.api.nvim_create_user_command("KeyHelp", M.keys, { desc = "nvim keybind cheat sheet" })
vim.api.nvim_create_user_command("TmuxHelp", M.tmux, { desc = "tmux cheat sheet" })
vim.keymap.set("n", "<leader>hk", M.keys, { desc = "nvim keybind help" })
vim.keymap.set("n", "<leader>ht", M.tmux, { desc = "tmux help" })
