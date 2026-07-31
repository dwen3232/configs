-- Setup for Mason and all of its adapters
return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "jay-babu/mason-nvim-dap.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")
    local mason_tool_installer = require("mason-tool-installer")
    local mason_dap = require("mason-nvim-dap")

    -- enable mason and configure icons
    mason.setup({
      PATH = "append",
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    -- https://github.com/williamboman/mason-lspconfig.nvim
    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed = {
        "ts_ls",
        "eslint",
        "html",
        "cssls",
        "tailwindcss",
        "lua_ls",
        "pyright",
        "rust_analyzer",
        "gopls",
        "sqlls",
        "bashls",
        "dockerls",
        "ols",
      },
      -- auto-install configured servers (with lspconfig)
      automatic_installation = true, -- not the same as ensure_installed
    })

    -- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
    -- can use both Mason and LspConfig names
    mason_tool_installer.setup({
      ensure_installed = {
        "actionlint",
        "prettier",
        "stylua",
        "ruff",
        "golangci-lint",
        "gofumpt",
        "mypy",
        "tflint",
        "tfsec",
        "hadolint",
        "jsonlint",
        "sqlfluff",
      },
    })

    mason_dap.setup({
      ensure_installed = { "python", "js" },
    })
  end,
}
