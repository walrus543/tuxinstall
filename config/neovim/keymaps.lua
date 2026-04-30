return {
  -- Keymaps pour Telescope (après son installation)
    "nvim-telescope/telescope.nvim",
    keys = {
      -- <Space>ff = find files
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      
      -- Bonus utiles :
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",   desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers"   },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Help Tags" },
    },
    opts = {
      pickers = {
        find_files = {
          find_command = {
            "fd",
            "--type", "f",
            "--extension", "txt",
            "--extension", "log",
            "--extension", "sh",
            "--extension", "xml"
           -- "--hidden",       -- inclut fichiers cachés si besoin
           -- "--no-ignore-vcs" -- ignore .gitignore
          },
        },
      },
    },
}
