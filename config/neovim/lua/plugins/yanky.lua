return {
  "gbprod/yanky.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("yanky").setup({
      ring = {
        history_length = 20,    -- nombre d'éléments dans l'historique
        storage = "shada",
        -- "shada" : persistance entre les sessions
        -- création de ~/.local/state/nvim/shada/main.shada
        -- "memory" : historique de session uniquement
        sync_with_numbered_registers = true,
      },
      highlight = {
        on_put = true,          -- flash visuel au moment du collage
        on_yank = true,         -- flash visuel au moment de la copie
        timer = 200,
      },
    })

    -- Intégration Telescope
    require("telescope").load_extension("yank_history")
  end,

  keys = {
    -- Remplace p/P par la version yanky (même comportement + historique)
    { "p",  "<Plug>(YankyPutAfter)",         mode = { "n", "x" }, desc = "Yanky put after" },
    { "P",  "<Plug>(YankyPutBefore)",        mode = { "n", "x" }, desc = "Yanky put before" },
    { "gp", "<Plug>(YankyGPutAfter)",        mode = { "n", "x" }, desc = "Yanky gput after" },
    { "gP", "<Plug>(YankyGPutBefore)",       mode = { "n", "x" }, desc = "Yanky gput before" },

    -- Cycler dans l'historique APRÈS avoir collé
    { "<C-p>", "<Plug>(YankyCycleForward)",  desc = "Yanky cycle forward" },
    { "<C-n>", "<Plug>(YankyCycleBackward)", desc = "Yanky cycle backward" },

    -- Ouvrir l'historique dans Telescope
    { "<leader>fy", "<cmd>Telescope yank_history<cr>", desc = "Yank history" },
  },
}
