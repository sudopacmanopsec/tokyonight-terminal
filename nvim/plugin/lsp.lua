
-- LSP defaults
vim.lsp.config("*", {
    root_markers = { ".git" },
})

-- Completion capabilities
local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")

local capabilities = ok
    and cmp_lsp.default_capabilities()
    or vim.lsp.protocol.make_client_capabilities()

-- Diagnostics
vim.diagnostic.config({
    virtual_text = {
        spacing = 4,
        source = "if_many",
    },

    severity_sort = true,
    update_in_insert = false,
    underline = true,

    float = {
        style = "minimal",
        border = "rounded",
        source = "if_many",
        header = "",
        prefix = "",
        max_width = 80,
        max_height = 24,
    },

    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "✘",
            [vim.diagnostic.severity.WARN] = "▲",
            [vim.diagnostic.severity.HINT] = "⚑",
            [vim.diagnostic.severity.INFO] = "»",
        },
    },
})

-- LSP attachment
local lsp_group = vim.api.nvim_create_augroup("my.lsp", {
    clear = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = lsp_group,

    callback = function(args)
        local client = assert(
            vim.lsp.get_client_by_id(args.data.client_id)
        )

        local buf = args.buf

        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, {
                buffer = buf,
                silent = true,
                desc = desc,
            })
        end

        -- Navigation
        map("n", "K", function()
            vim.lsp.buf.hover({
                border = "rounded",
                max_width = 80,
                max_height = 24,
            })
        end, "LSP Hover")

        map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
        map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
        map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
        map("n", "go", vim.lsp.buf.type_definition, "Go to Type Definition")
        map("n", "gr", vim.lsp.buf.references, "Find References")

        -- Information
        map("n", "gs", function()
            vim.lsp.buf.signature_help({
                border = "rounded",
                max_width = 80,
                max_height = 24,
            })
        end, "Signature Help")

        map("n", "gl", vim.diagnostic.open_float, "Line Diagnostics")

        -- Diagnostic navigation
        map("n", "[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
        map("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")

        -- Actions
        map("n", "<F2>", vim.lsp.buf.rename, "Rename")

        map({ "n", "x" }, "<F3>", function()
            vim.lsp.buf.format({
                async = true,
            })
        end, "Format")

        map("n", "<F4>", vim.lsp.buf.code_action, "Code Action")

        -- Inlay hints
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, {
                bufnr = buf,
            })
        end

        -- Document highlighting
        if client:supports_method("textDocument/documentHighlight") then
            local highlight_group = vim.api.nvim_create_augroup(
                "my.lsp.highlight." .. buf,
                { clear = true }
            )

            vim.api.nvim_create_autocmd("CursorHold", {
                group = highlight_group,
                buffer = buf,
                callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd(
                { "CursorMoved", "CursorMovedI" },
                {
                    group = highlight_group,
                    buffer = buf,
                    callback = vim.lsp.buf.clear_references,
                }
            )
        end

        -- Automatic formatting on save
        local excluded_filetypes = {
            php = true,
            c = true,
            cpp = true,
        }

        if client:supports_method("textDocument/formatting")
            and not excluded_filetypes[vim.bo[buf].filetype]
        then
            local format_group = vim.api.nvim_create_augroup(
                "my.lsp.format." .. buf,
                { clear = true }
            )

            vim.api.nvim_create_autocmd("BufWritePre", {
                group = format_group,
                buffer = buf,

                callback = function()
                    vim.lsp.buf.format({
                        bufnr = buf,
                        id = client.id,
                        async = false,
                        timeout_ms = 1000,
                    })
                end,
            })
        end
    end,
})

-- LSP detach cleanup
vim.api.nvim_create_autocmd("LspDetach", {
    group = lsp_group,

    callback = function(args)
        local buf = args.buf

        vim.api.nvim_clear_autocmds({
            group = vim.api.nvim_create_augroup(
                "my.lsp.highlight." .. buf,
                { clear = false }
            ),
            buffer = buf,
        })

        vim.api.nvim_clear_autocmds({
            group = vim.api.nvim_create_augroup(
                "my.lsp.format." .. buf,
                { clear = false }
            ),
            buffer = buf,
        })

        vim.lsp.buf.clear_references()
    end,
})

-- Lua
vim.lsp.config["luals"] = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
    capabilities = capabilities,

    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },

            diagnostics = {
                globals = { "vim" },
            },

            workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
            },

            telemetry = {
                enable = false,
            },
        },
    },
}

-- CSS
vim.lsp.config["cssls"] = {
    cmd = { "vscode-css-language-server", "--stdio" },
    filetypes = { "css", "scss", "less" },
    root_markers = { "package.json", ".git" },
    capabilities = capabilities,

    settings = {
        css = { validate = true },
        scss = { validate = true },
        less = { validate = true },
    },
}

-- PHP
vim.lsp.config["phpls"] = {
    cmd = { "intelephense", "--stdio" },
    filetypes = { "php" },
    root_markers = { "composer.json", ".git" },
    capabilities = capabilities,

    settings = {
        intelephense = {
            files = {
                maxSize = 5000000,
            },
        },
    },
}

-- JavaScript / TypeScript
vim.lsp.config["ts_ls"] = {
    cmd = { "typescript-language-server", "--stdio" },

    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
    },

    root_markers = {
        "package.json",
        "tsconfig.json",
        "jsconfig.json",
        ".git",
    },

    capabilities = capabilities,

    settings = {
        completions = {
            completeFunctionCalls = true,
        },
    },
}

-- Zig
vim.lsp.config["zls"] = {
    cmd = { "zls" },
    filetypes = { "zig", "zir" },
    root_markers = { "zls.json", "build.zig", ".git" },
    capabilities = capabilities,

    settings = {
        zls = {
            enable_build_on_save = true,
            build_on_save_step = "install",
            warn_style = false,
            enable_snippets = true,
        },
    },
}

-- Nix
vim.lsp.config["nil_ls"] = {
    cmd = { "nil" },
    filetypes = { "nix" },
    root_markers = { "flake.nix", "default.nix", ".git" },
    capabilities = capabilities,

    settings = {
        ["nil"] = {
            formatting = {
                command = { "alejandra" },
            },
        },
    },
}

-- Rust
vim.lsp.config["rust_analyzer"] = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json" },
    single_file_support = true,
    capabilities = capabilities,

    settings = {
        ["rust-analyzer"] = {
            cargo = {
                allFeatures = true,
            },

            rustfmt = {
                extraArgs = {},
            },
        },
    },

    before_init = function(init_params, config)
        if config.settings and config.settings["rust-analyzer"] then
            init_params.initializationOptions =
                config.settings["rust-analyzer"]
        end
    end,

    handlers = {
        ["window/showMessage"] = function(err, result, ctx, config)
            if result
                and result.message
                and result.message:find("Failed to discover workspace")
            then
                return
            end

            return vim.lsp.handlers["window/showMessage"](
                err,
                result,
                ctx,
                config
            )
        end,
    },
}

-- C / C++
vim.lsp.config["clangd"] = {
    cmd = {
        "clangd",
        "--background-index",
        "--header-insertion=never",
        "--completion-style=detailed",
        "--function-arg-placeholders=0",
        "--query-driver=/usr/bin/clang*,/usr/bin/cc,/usr/bin/c++",
    },

    filetypes = {
        "c",
        "cpp",
        "objc",
        "objcpp",
    },

    root_markers = {
        "compile_commands.json",
        ".clangd",
        "configure.ac",
        "Makefile",
        ".git",
    },

    capabilities = capabilities,
}

-- C3
vim.lsp.config["c3lsp"] = {
    cmd = { "c3-lsp" },
    filetypes = { "c3" },
    root_markers = { "project.json", ".git" },
    capabilities = capabilities,
}

-- D
vim.lsp.config["serve_d"] = {
    cmd = { "serve-d" },
    filetypes = { "d" },
    root_markers = { "dub.sdl", "dub.json", ".git" },
    capabilities = capabilities,
}

-- JSON
vim.lsp.config["jsonls"] = {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    root_markers = { "package.json", ".git", "config.jsonc" },
    capabilities = capabilities,
}

-- Haskell
vim.lsp.config["hls"] = {
    cmd = { "haskell-language-server-wrapper", "--lsp" },
    filetypes = { "haskell", "lhaskell" },

    root_markers = {
        "stack.yaml",
        "cabal.project",
        "package.yaml",
        "*.cabal",
        "hie.yaml",
        ".git",
    },

    capabilities = capabilities,

    settings = {
        haskell = {
            formattingProvider = "fourmolu",

            plugin = {
                semanticTokens = {
                    globalOn = false,
                },
            },
        },
    },
}

-- Go
vim.lsp.config["gopls"] = {
    cmd = { "gopls" },

    filetypes = {
        "go",
        "gomod",
        "gowork",
        "gotmpl",
    },

    root_markers = {
        "go.mod",
        "go.work",
        ".git",
    },

    capabilities = capabilities,

    settings = {
        gopls = {
            analyses = {
                unusedparams = false,
                ST1003 = false,
                ST1000 = false,
            },

            staticcheck = true,
        },
    },
}

-- Templ
vim.lsp.config["templ"] = {
    cmd = { "templ", "lsp" },
    filetypes = { "templ" },
    root_markers = { "go.mod", ".git" },
    capabilities = capabilities,
}

-- Filetypes
vim.filetype.add({
    extension = {
        h = "c",
        c3 = "c3",
        d = "d",
        templ = "templ",
    },
})

-- Enable language servers
local servers = {
    "luals",
    "cssls",
    "phpls",
    "ts_ls",
    "zls",
    "nil_ls",
    "rust_analyzer",
    "clangd",
    "c3lsp",
    "serve_d",
    "jsonls",
    "hls",
    "gopls",
    "templ",
}

for _, server in ipairs(servers) do
    vim.lsp.enable(server)
end

