--   "lukas-reineke/indent-blankline.nvim",
--   { "nvim-treesitter/nvim-treesitter", branch = "main" },
--   "p00f/clangd_extensions.nvim",

-- 1. Unbind arrow keys ---------------------------------------------------
for _, mode in ipairs({ "n", "i", "v", "x", "o", "c" }) do
  for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
    vim.keymap.set(mode, key, "<Nop>", { desc = "arrow keys disabled" })
  end
end

-- 2. C / Zig ---------------------------------------------------------------
-- Treesitter parsers (async; needs a C compiler and the `tree-sitter` CLI installed)
local ok_ts, ts = pcall(require, "nvim-treesitter")
if ok_ts and ts.install then
  ts.install({ "c", "cpp", "zig", "make", "cmake" })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "zig" },
    callback = function() pcall(vim.treesitter.start) end,
  })
end

-- clangd extras (source/header switch, AST, type hierarchy)
local ok_cl, clangd = pcall(require, "clangd_extensions")
if ok_cl then
  clangd.setup({})
  vim.keymap.set("n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", { desc = "Switch source/header" })
end

-- Format on save through clangd / zls (no extra plugin needed)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.c", "*.h", "*.cpp", "*.hpp", "*.zig" },
  callback = function() vim.lsp.buf.format({ timeout_ms = 1000 }) end,
})

