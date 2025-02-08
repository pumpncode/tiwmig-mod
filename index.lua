-- == FUNCTION: Food Joker "consumption"
local tiwmig_food_eat = function(card)
    -- Taken from Cavendish, ExampleJokersMod (Steamodded example mods)
    G.E_MANAGER:add_event(Event({
        func = function()
            -- Play sound and be all bouncy and stuff
            play_sound('tarot1')
            card.T.r = -0.2
            card:juice_up(0.3, 0.4)
            card.states.drag.is = true
            card.children.center.pinch.x = true
            -- Destroy the card
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.3,
                blockable = false,
                func = function()
                    G.jokers:remove_card(card)
                    card:remove()
                    card = nil
                    return true;
                end
            }))
            return true
        end
    }))
end

-- == FUNCTION: Localized Joker name shorthand
local tiwmig_get_j_name = function(joker_key)
    if not G.localization.descriptions.Joker[joker_key] then return joker_key end
    return G.localization.descriptions.Joker[joker_key].name
end

-- == FUNCTION: Poutine components fusion
-- card and target are card objects, sum is string (key of Joker)
local tiwmig_poutine_fusion = function(card, target, sum)
    local card_edition   = card.edition and card.edition.type
    local target_edition = target.edition and target.edition.type
    local sum_edition = {}

    --[[
    Edition priority:
    - Negative, if either card or target are
    - Polychrome, if either card or target are
    - Holo, if either card or target are
    - Foil, if either card or target are
    - Target's edition
    - Card's edition
    For modded edition support
    ]]
    if card_edition == "negative" or target_edition == "negative" then
        sum_edition.negative = true
    elseif card_edition == "polychrome" or target_edition == "polychrome" then
        sum_edition.polychrome = true
    elseif card_edition == "holo" or target_edition == "holo" then
        sum_edition.holo = true
    elseif card_edition == "foil" or target_edition == "foil" then
        sum_edition.foil = true
    elseif target_edition ~= nil then sum_edition[target_edition] = true
    elseif card_edition ~= nil then sum_edition[card_edition] = true
    end

    -- Pause before doing the fusion for extra oompf
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 1,
        blockable = false,
        func = function()
            tiwmig_food_eat(card)
            tiwmig_food_eat(target)
            SMODS.add_card{
                key = sum,
                edition = sum_edition,
                no_edition = true
            }
            return true
        end
    }))
end

-- == ATLAS: Mod icon
SMODS.Atlas { key = "modicon",
    path = "tiwmig_mod_icon.png",
    px = "34", py = "34",
}

-- == ATLAS: Placeholders
SMODS.Atlas { key = "Placeholders",
    path = "tiwmig_placeholders.png",
    px = "71", py = "95",
}
local placeholders = {
    joker = {x=0, y=0}
}

-- == ATLAS: Joker atlas
SMODS.Atlas { key = "Joker atlas",
    path = "tiwmig_joker_atlas.png",
    px = "71", py = "95",
}

-- == JOKER: Generic Brand Joker, j_tiwmig_generic_brand
SMODS.Joker { key = "generic_brand",
    config = { 
        extra = {
            discount = 0.30,
        },
        joker_count = 0, -- More reliable way to count the number of this Joker on hand
    },

    loc_vars = function(self, info_queue, card)
        -- "All shop prices are #1#% off (rounded up)"
        return {vars = {
            card.ability.extra.discount*100 -- #1#
        }}
    end,

    atlas = "Joker atlas",
    pos = {x=0, y=0},

    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,

    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    
    -- This is what sets the cost; setting as separate function to reduce amount copypasted
    ability_function = function(self)
        -- Formula: base_cost*( (1-discount)^joker_count ), rounded up
        local function discount_group(group)
            if group and group.cards then for k,v in pairs(group.cards) do
                v.cost = math.ceil(v.base_cost*((1-self.config.extra.discount)^self.config.joker_count))
            end end
        end
        -- With the above function we can just call it repeatedly for each group with minimal copypasting
        discount_group(G.shop_jokers)
        discount_group(G.shop_booster)
        discount_group(G.shop_vouchers)
    end,

    -- Set *self* joker_count, not card, to keep proper count
    add_to_deck = function(self, card, from_debuff)
        self.config.joker_count = self.config.joker_count + 1
        self.ability_function(self) -- See? Less copypasting for the same effect -every time-
    end,

    remove_from_deck = function(self, card, from_debuff)
        self.config.joker_count = self.config.joker_count - 1
        self.ability_function(self)
    end,

    calculate = function(self, card, context)
        -- [tiwmig_load_shop] is a custom Joker context, implemented in lovely.toml
        if context.reroll_shop or context.tiwmig_load_shop then
            self.ability_function(self)
        end
    end
}

-- == JOKER: Bag of Chips, j_tiwmig_bag_of_chips
SMODS.Joker { key = "bag_of_chips",
    config = {
        extra = {
            multiplier = 2,
        },
    },


    atlas = "Joker atlas",
    pos = {x=1, y=0},

    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,

    calculate = function(self, card, context)
        -- G.STATE of 1 is SELECTING_HAND, i.e. when you're selecting a hand
        if context.selling_self and G.STATE == 1 then
            play_sound('highlight2', 1 + math.random()*0.1, 0.7)
            card:juice_up()
            G.E_MANAGER:add_event(Event({
                trigger = "ease",
                ref_table = G.GAME,
                ref_value = "chips",
                ease_to = card.ability.multiplier*G.GAME.chips,
                func = (function(t) return math.floor(t) end)
            }))
            G.E_MANAGER:add_event(Event({
                func = function()
                    play_sound('chips2')
                    if (G.GAME.chips >= G.GAME.blind.chips) then
                        G.STATE = G.STATES.HAND_PLAYED
                        G.STATE_COMPLETE = true
                        end_round()
                    end
                    return true
                end
            }))
        end
    end,
}

-- == JOKER: French Fries, j_tiwmig_french_fries
SMODS.Joker { key = "french_fries",
    config = {
        extra = {
            chips = 50,
            countdown = 5, -- hands
        },
    },

    loc_vars = function(self, info_queue, card)
        -- "+#1# Chips for the next #2# hands; combines with #3# or #4#"
        return {vars = {
            card.ability.extra.chips,     -- #1#
            card.ability.extra.countdown, -- #2#
            tiwmig_get_j_name("j_tiwmig_gravy"),        -- #3#
            tiwmig_get_j_name("j_tiwmig_cheese_curds"), -- #4#
        }}
    end,

    atlas = "Joker atlas",
    pos = {x=0, y=1},

    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,

    in_pool = function(self, args)
        return not (
            #SMODS.find_card("j_tiwmig_french_fries") > 0 or
            #SMODS.find_card("j_tiwmig_frite_sauce") > 0 or 
            #SMODS.find_card("j_tiwmig_chips_n_cheese") > 0 or
            #SMODS.find_card("j_tiwmig_poutine") > 0
        )
    end,


    add_to_deck = function(self, card, from_debuff)
        if #SMODS.find_card("j_tiwmig_gravy") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_gravy")[1], "j_tiwmig_frite_sauce")
        elseif #SMODS.find_card("j_tiwmig_cheese_curds") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_cheese_curds")[1], "j_tiwmig_chips_n_cheese")
        elseif #SMODS.find_card("j_tiwmig_cheesy_gravy") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_cheesy_gravy")[1], "j_tiwmig_poutine")
        end
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
            }
        end

        if context.after then
            if card.ability.extra.countdown - 1 <= 0 then
                tiwmig_food_eat(card) -- Function to apply eaten effect (includes self-deletion)
                return {
                    message = localize('k_tiwmig_poutine_eaten'),
                    colour = G.C.CHIPS
                }
            else
                card.ability.extra.countdown = card.ability.extra.countdown - 1
                return {
                    message = localize('k_tiwmig_poutine_eating'),
                    colour = G.C.CHIPS
                }
            end
        end
    end,
}

-- == JOKER: Gravy, j_tiwmig_gravy
SMODS.Joker { key = "gravy",
    config = {
        extra = {
            mult = 8,
            countdown = 5 -- hands
        }
    },

    loc_vars = function(self, info_queue, card)
        -- "+#1# Mult for the next #2# hands; combines with #3# or #4#"
        return {vars = {
            card.ability.extra.mult,      -- #1#
            card.ability.extra.countdown, -- #2#
            tiwmig_get_j_name("j_tiwmig_cheese_curds"), -- #3#
            tiwmig_get_j_name("j_tiwmig_french_fries"), -- #4#
        }}
    end,

    atlas = "Joker atlas",
    pos = {x=1, y=1},

    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,

    in_pool = function(self, args)
        return not (
            #SMODS.find_card("j_tiwmig_gravy") > 0 or
            #SMODS.find_card("j_tiwmig_cheesy_gravy") > 0 or 
            #SMODS.find_card("j_tiwmig_frite_sauce") > 0 or
            #SMODS.find_card("j_tiwmig_poutine") > 0
        )
    end,

    add_to_deck = function(self, card, from_debuff)
        if #SMODS.find_card("j_tiwmig_cheese_curds") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_cheese_curds")[1], "j_tiwmig_cheesy_gravy")
        elseif #SMODS.find_card("j_tiwmig_french_fries") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_french_fries")[1], "j_tiwmig_frite_sauce")
        elseif #SMODS.find_card("j_tiwmig_chips_n_cheese") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_chips_n_cheese")[1], "j_tiwmig_poutine")
        end
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = card.ability.extra.mult,
            }
        end

        if context.after then
            if card.ability.extra.countdown - 1 <= 0 then
                tiwmig_food_eat(card) -- Function to apply eaten effect (includes self-deletion)
                return {
                    message = localize('k_tiwmig_poutine_eaten'),
                    colour = G.C.MULT
                }
            else
                card.ability.extra.countdown = card.ability.extra.countdown - 1
                return {
                    message = localize('k_tiwmig_poutine_eating'),
                    colour = G.C.MULT
                }
            end
        end
    end,
}

-- == JOKER: Cheese Curds, j_tiwmig_cheese_curds
SMODS.Joker { key = "cheese_curds",
    config = {
        extra = {
            cash = 2,
            countdown = 5, -- hands
        },
    },

    loc_vars = function(self, info_queue, card)
        -- "+$#1# for the next #2# hands; combines with #3# or #4#"
        return {vars = {
            card.ability.extra.cash,      -- #1#
            card.ability.extra.countdown, -- #2#
            tiwmig_get_j_name("j_tiwmig_french_fries"), -- #3#
            tiwmig_get_j_name("j_tiwmig_gravy"),        -- #4#
        }}
    end,

    atlas = "Joker atlas",
    pos = {x=2, y=1},

    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,

    in_pool = function(self, args)
        return not (
            #SMODS.find_card("j_tiwmig_cheese_curds") > 0 or
            #SMODS.find_card("j_tiwmig_chips_n_cheese") > 0 or 
            #SMODS.find_card("j_tiwmig_cheesy_gravy") > 0 or
            #SMODS.find_card("j_tiwmig_poutine") > 0
        )
    end,

    add_to_deck = function(self, card, from_debuff)
        if #SMODS.find_card("j_tiwmig_french_fries") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_french_fries")[1], "j_tiwmig_chips_n_cheese")
        elseif #SMODS.find_card("j_tiwmig_gravy") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_gravy")[1], "j_tiwmig_cheesy_gravy")
        elseif #SMODS.find_card("j_tiwmig_frite_sauce") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_frite_sauce")[1], "j_tiwmig_poutine")
        end
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            -- Taken from To Do List source
            return {
                dollars = card.ability.extra.cash,
            }
        end

        if context.after then
            if card.ability.extra.countdown - 1 <= 0 then
                tiwmig_food_eat(card) -- Function to apply eaten effect (includes self-deletion)
                return {
                    message = localize('k_tiwmig_poutine_eaten'),
                    colour = G.C.MONEY
                }
            else
                card.ability.extra.countdown = card.ability.extra.countdown - 1
                return {
                    message = localize('k_tiwmig_poutine_eating'),
                    colour = G.C.MONEY
                }
            end
        end
    end,
}

-- == JOKER: Frite Sauce, j_tiwmig_frite_sauce
SMODS.Joker { key = "frite_sauce",
    config = {
        extra = {
            chips = 75,
            mult = 12,
            countdown = 8, -- hands
        },
    },

    loc_vars = function(self, info_queue, card)
        -- "+#1# Chips and +#2# Mult for the next #3# hands; combines with #4#"
        return {vars = {
            card.ability.extra.chips,     -- #1#
            card.ability.extra.mult,      -- #2#
            card.ability.extra.countdown, -- #3#
            tiwmig_get_j_name("j_tiwmig_cheese_curds"), -- #4#
        }}
    end,

    atlas = "Joker atlas",
    pos = {x=0, y=2},

    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,

    in_pool = function(self, args)
        return false
    end,

    add_to_deck = function(self, card, from_debuff)
        if #SMODS.find_card("j_tiwmig_cheese_curds") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_cheese_curds")[1], "j_tiwmig_poutine")
        end
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
                mult = card.ability.extra.mult,
            }
        end

        if context.after then
            if card.ability.extra.countdown - 1 <= 0 then
                tiwmig_food_eat(card) -- Function to apply eaten effect (includes self-deletion)
                return {
                    message = localize('k_tiwmig_poutine_eaten'),
                    colour = G.C.CHIPS
                }
            else
                card.ability.extra.countdown = card.ability.extra.countdown - 1
                return {
                    message = localize('k_tiwmig_poutine_eating'),
                    colour = G.C.CHIPS
                }
            end
        end
    end,
}

-- == JOKER: Cheesy Gravy, j_tiwmig_cheesy_gravy
SMODS.Joker { key = "cheesy_gravy",
    config = {
        extra = {
            mult = 12,
            cash = 3,
            countdown = 8, -- hands
        },
    },

    loc_vars = function(self, info_queue, card)
        -- "+#1# Mult and earn $#2# for the next #3# hands; combines with #4#"
        return {vars = {
            card.ability.extra.mult,     -- #1#
            card.ability.extra.cash,     -- #2#
            card.ability.extra.countdown, -- #3#
            tiwmig_get_j_name("j_tiwmig_french_fries"), -- #4#
        }}
    end,

    atlas = "Joker atlas",
    pos = {x=1, y=2},

    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,

    in_pool = function(self, args)
        return false
    end,

    add_to_deck = function(self, card, from_debuff)
        if #SMODS.find_card("j_tiwmig_french_fries") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_french_fries")[1], "j_tiwmig_poutine")
        end
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            -- Taken from To Do List source
            ease_dollars(card.ability.cash)
            G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.cash
            G.E_MANAGER:add_event(Event({func = (function() G.GAME.dollar_buffer = 0; return true end)}))
            return {
                mult = card.ability.extra.mult,
                dollars = card.ability.extra.cash,
            }
        end

        if context.after then
            if card.ability.extra.countdown - 1 <= 0 then
                tiwmig_food_eat(card) -- Function to apply eaten effect (includes self-deletion)
                return {
                    message = localize('k_tiwmig_poutine_eaten'),
                    colour = G.C.MULT
                }
            else
                card.ability.extra.countdown = card.ability.extra.countdown - 1
                return {
                    message = localize('k_tiwmig_poutine_eating'),
                    colour = G.C.MULT
                }
            end
        end
    end,
}

-- == JOKER: Chips n' Cheese, j_tiwmig_chips_n_cheese
SMODS.Joker { key = "chips_n_cheese",
    config = {
        extra = {
            cash = 3,
            chips = 75,
            countdown = 8, -- hands
        },
    },

    loc_vars = function(self, info_queue, card)
        -- "Earn $#1# and +#2# Chips for the next #3# hands; combines with #4#"
        return {vars = {
            card.ability.extra.cash,      -- #1#
            card.ability.extra.chips,     -- #2#
            card.ability.extra.countdown, -- #3#
            tiwmig_get_j_name("j_tiwmig_gravy"), -- #4#
        }}
    end,

    atlas = "Joker atlas",
    pos = {x=2, y=2},

    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,

    in_pool = function(self, args)
        return false
    end,

    add_to_deck = function(self, card, from_debuff)
        if #SMODS.find_card("j_tiwmig_gravy") > 0 then
            tiwmig_poutine_fusion(card, SMODS.find_card("j_tiwmig_gravy")[1], "j_tiwmig_poutine")
        end
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            -- Taken from To Do List source
            return {
                dollars = card.ability.extra.cash,
                chips = card.ability.extra.chips,
            }
        end

        if context.after then
            if card.ability.extra.countdown - 1 <= 0 then
                tiwmig_food_eat(card) -- Function to apply eaten effect (includes self-deletion)
                return {
                    message = localize('k_tiwmig_poutine_eaten'),
                    colour = G.C.MONEY
                }
            else
                card.ability.extra.countdown = card.ability.extra.countdown - 1
                return {
                    message = localize('k_tiwmig_poutine_eating'),
                    colour = G.C.MONEY
                }
            end
        end
    end,
}

-- == JOKER: Poutine, j_tiwmig_poutine
SMODS.Joker { key = "poutine",
    config = {
        extra = {
            chips = 100,
            mult = 16,
            cash = 4,
            countdown = 10, -- hands
        },
    },

    loc_vars = function(self, info_queue, card)
        -- "+#1# Chips, +#2# Mult, and earn $#3# for the next #4# hands"
        return {vars = {
            card.ability.extra.chips,     -- #1#
            card.ability.extra.mult,      -- #2#
            card.ability.extra.cash,      -- #3#
            card.ability.extra.countdown, -- #4#
        }}
    end,

    atlas = "Joker atlas",
    pos = {x=2, y=0},

    rarity = 3,
    cost = 4,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,

    in_pool = function(self, args)
        return false
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            -- Taken from To Do List source
            return {
                chips = card.ability.extra.chips,
                mult = card.ability.extra.mult,
                dollars = card.ability.extra.cash
            }
        end

        if context.after then
            if card.ability.extra.countdown - 1 <= 0 then
                tiwmig_food_eat(card) -- Function to apply eaten effect (includes self-deletion)
                return {
                    message = localize('k_tiwmig_poutine_eaten'),
                    colour = G.C.PURPLE
                }
            else
                card.ability.extra.countdown = card.ability.extra.countdown - 1
                return {
                    message = localize('k_tiwmig_poutine_eating'),
                    colour = G.C.PURPLE
                }
            end
        end
    end,
}

-- == JOKER: egg, j_tiwmig_egg
SMODS.Joker { key = "egg",
    config = {
        extra = {
            chips = 9,
        },
    },

    loc_vars = function(self, info_queue, card)
        -- "+#1# Chips"
        return {vars = {
            card.ability.extra.chips, -- #1#
        }}
    end,

    atlas = "Joker atlas",
    pos = {x=3, y=0},

    rarity = 1,
    cost = 2,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.joker_main then return { chips = card.ability.extra.chips } end
    end,
}

--[[ == JOKER: Ruler of Everything, j_tiwmig_ruler_of_everything
SMODS.Joker { key = "ruler_of_everything",
    config = {
        multiplier = 2
    },

    loc_txt = {
        name = "Ruler of Everything",
        text = {
            "#1#,",
            "effect changes {C:attention}every day{}"
        }
    },

    atlas = "Joker atlas",
    pos = {x=0, y=0},

    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
}
]]--