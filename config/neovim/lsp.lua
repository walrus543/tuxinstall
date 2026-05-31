return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = { "yamlls" },
    })

    -- Nouvelle API Neovim 0.11+
    vim.lsp.config("yamlls", {
      settings = {
        yaml = {
          schemaStore = {
            enable = true,
            url = "https://www.schemastore.org/api/json/catalog.json",
          },
          validate = true,
          completion = true,
          hover = true,
        },
      },
    })

    vim.lsp.enable("yamlls")
  end,
}
