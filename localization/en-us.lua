return { -------- START OF ENTIRE RETURNED TABLE
descriptions = {
---- START OF DESCRIPTIONS

Joker = { -- START OF JOKERS
    j_tiwmig_generic_brand = {
        name = "Generic Brand Joker",
        text = {
            "All shop prices",
            "are {C:attention}#1#%{} off",
            "{C:inactive}(rounded up){}",
        }
    },
    j_tiwmig_bag_of_chips = {
        name = "Bag of Chips",
        text = {
            "Sell this card to",
            "double {C:attention}round score{}"
        }
    },
    j_tiwmig_french_fries = {
        name = "French Fries",
        text = {
            "{C:blue}+#1#{} Chips for the",
            "next {C:attention}#2#{} hands",
            "Automatically combines with",
            "{C:attention}#3#{} or {C:attention}#4#{}"
        }
    },
    j_tiwmig_gravy = {
        name = "Gravy",
        text = {
            "{C:red}+#1#{} Mult for the",
            "next {C:attention}#2#{} hands",
            "Automatically combines with",
            "{C:attention}#3#{} or {C:attention}#4#{}"
        }
    },
    j_tiwmig_cheese_curds = {
        name = "Cheese Curds",
        text = {
            "Earn {C:money}$#1#{} for the",
            "next {C:attention}#2#{} hands",
            "Automatically combines with",
            "{C:attention}#3#{} or {C:attention}#4#{}"
        }
    },
    j_tiwmig_frite_sauce = {
        name = "Frite Sauce",
        text = {
            "{C:blue}+#1#{} Chips and",
            "{C:red}+#2#{} Mult for the",
            "next {C:attention}#3#{} hands",
            "Automatically combines",
            "with {C:attention}#4#{}"
        }
    },
    j_tiwmig_cheesy_gravy = {
        name = "Cheesy Gravy",
        text = {
            "{C:red}+#1#{} Mult and",
            "earn {C:money}$#2#{} for the",
            "next {C:attention}#3#{} hands",
            "Automatically combines",
            "with {C:attention}#4#{}"
        }
    },
    j_tiwmig_chips_n_cheese = {
        name = "Chips n' Cheese",
        text = {
            "Earn {C:money}$#1#{} and",
            "{C:blue}+#2#{} for the",
            "next {C:attention}#3#{} hands",
            "Automatically combines",
            "with {C:attention}#4#{}"
        }
    },
    j_tiwmig_poutine = {
        name = "Poutine",
        text = {
            "{C:blue}+#1#{} Chips, {C:red}+#2#{} Mult,",
            "and earn {C:money}$#3#{} for the",
            "next {C:attention}#4#{} hands"
        }
    },
    j_tiwmig_egg = {
        name = '"egg"',
        text = {
            "{C:blue}+#1#{} Chips",
            [[{C:inactive,s:0.8}"hey, it's "egg""{}]],
        }
    },
    j_tiwmig_shotgun = {
        name = "Shotgun",
        text = {
            "2-#1# {C:inactive}blank{} and {C:red}live{} shells are",
            "loaded in a random sequence",
            "Shoot on play; only {C:red}live{}",
            "shells give {X:mult,C:white}X#2#{} Mult",
            "{s:0.1,C:white}----",
            "{s:0.7,C:inactive}#3# blank shell#4#. {s:0.7,C:red}#5# live.",
            "{C:red}#6# shells remain{}"
        }
    },
    j_tiwmig_large_small_boulder = {
        name = "Large Boulder the Size of a Small Boulder",
        text = {
            "All {C:attention}cards{} are",
            "considered by Jokers",
            "as {C:blue}also {C:attention}one rank lower",
            "{C:inactive}(2 -> A -> K)"
        }
    },
    j_tiwmig_commenting_out = {
        name = "Commenting Out",
        text = {
            "Debuffs the {C:attention}Joker{}",
            "to the right"
        }
    }
}, -- END OF JOKERS

---- END OF DESCRIPTIONS
},
misc = {
---- START OF MISC

dictionary = {
    k_tiwmig_poutine_eating = "Eating...",
    k_tiwmig_poutine_eaten = "Eaten!",
    k_tiwmig_shotgun_blank = "Blank..."
},

v_dictionary = {
    k_tiwmig_shotgun_load_live  = "#1# live round#2#.",
    k_tiwmig_shotgun_load_blank = "#1# blank#2#."
},

---- END OF MISC
}
} -------- END OF ENTIRE RETURNED TABLE