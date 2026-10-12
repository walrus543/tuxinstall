return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,          -- doit être chargé tout de suite
        priority = 1000,       -- thème = très haut
        config = function()
        require("catppuccin").setup({
            flavour = "mocha",  -- ou "latte", "frappe", "macchiato"
            background = {      -- optionnel
                light = "latte",
                dark = "mocha",
            },
            transparent_background = true, -- ou true si tu veux fond transparent
            -- ... autres options selon ton goût
        })
        vim.cmd.colorscheme "catppuccin"
        end,
    }
}
