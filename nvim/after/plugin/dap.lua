local dap = require("dap")

-- Debugging keybindings
vim.keymap.set("n", "<F5>", dap.continue, {
    desc = "Start / Continue debugging",
})

vim.keymap.set("n", "<F10>", dap.step_over, {
    desc = "Step over",
})

vim.keymap.set("n", "<F11>", dap.step_into, {
    desc = "Step into",
})

vim.keymap.set("n", "<F12>", dap.step_out, {
    desc = "Step out",
})

vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, {
    desc = "Toggle breakpoint",
})

vim.keymap.set("n", "<leader>dr", dap.repl.open, {
    desc = "Open debug REPL",
})

vim.keymap.set("n", "<leader>dq", dap.terminate, {
    desc = "Terminate debugging",
})

-- DAP signs
vim.fn.sign_define("DapBreakpoint", {
    text = "●",
    texthl = "DiagnosticError",
})

vim.fn.sign_define("DapStopped", {
    text = "▶",
    texthl = "DiagnosticWarn",
})

vim.fn.sign_define("DapBreakpointRejected", {
    text = "○",
    texthl = "DiagnosticError",
})
