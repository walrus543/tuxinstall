return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",  -- version stable
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",  -- icônes (optionnel)
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",  -- lazy loading sur commande
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle Neo-tree" },
    { "<leader>o", "<cmd>Neotree focus<CR>",  desc = "Focus Neo-tree" },
  },
  opts = {},  -- config par défaut (suffisante)
}
