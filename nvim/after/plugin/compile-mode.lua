---@type CompileModeOpts
vim.g.compile_mode = {
    default_command = {
        c = "clang -Wall -Wextra -o %< % && ./%<",
        zig = "zig run %",
        rust = "cargo run",
        go = "go run %",
    },
    bang_expansion = true,
    input_word_completion = true,
    auto_jump_to_first_error = true,
    autosave = true,
}

vim.keymap.set("n", "<leader>cc", "<cmd>Compile<cr>", { desc = "Compile & run prompt" })
vim.keymap.set("n", "<leader>cr", "<cmd>Recompile<cr>", { desc = "Recompile & run" })
vim.keymap.set("n", "]e", "<cmd>NextError<cr>", { desc = "Next compile error" })
vim.keymap.set("n", "[e", "<cmd>PrevError<cr>", { desc = "Previous compile error" })

