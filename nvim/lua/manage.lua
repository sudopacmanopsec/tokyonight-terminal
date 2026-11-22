local M = {}

local plug_dir = vim.fn.stdpath("data") .. "/plugins"

local function ensure(spec)
    local repo = type(spec) == "string" and spec or spec[1]
    local name = repo:match(".+/(.+)$")
    local path = plug_dir .. "/" .. name

    if not vim.uv.fs_stat(path) then
        vim.fn.mkdir(plug_dir, "p")

        local cmd = { "git", "clone", "--depth=1" }

        if type(spec) == "table" and spec.branch then
            vim.list_extend(cmd, { "-b", spec.branch })
        end

        vim.list_extend(cmd, {
            "https://github.com/" .. repo,
            path,
        })

        print("Installing " .. name .. "...")

        local output = vim.fn.system(cmd)

        if vim.v.shell_error ~= 0 then
            vim.notify(
                "Failed to install " .. name .. ":\n" .. output,
                vim.log.levels.ERROR
            )
            return false
        end
    end

    vim.opt.rtp:prepend(path)
    vim.opt.rtp:append(path .. "/after")

    return true
end

function M.setup()
    for _, spec in ipairs(require("plugin-list")) do
        ensure(spec)
    end
end

return M
