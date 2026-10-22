return {
    "echasnovski/mini.move",
    version = "*",
    keys = {
        { "<A-Down>", desc = "Déplacer vers le bas" },
        { "<A-Up>", desc = "Déplacer vers le haut" },
        { "<A-Left>", desc = "Déplacer à gauche (visuel)" },
        { "<A-Right>", desc = "Déplacer à droite (visuel)" },
    },
    opts = {
        mappings = {
            -- Déplacer la ligne courante en mode normal
            line_down = "<A-Down>",
            line_up = "<A-Up>",
            -- Déplacer le bloc sélectionné en mode visuel
            left = "<A-Left>",
            right = "<A-Right>",
            down = "<A-Down>",
            up = "<A-Up>",
        },
    },
}
