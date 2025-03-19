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
                delay = 1,
                ref_table = G.GAME,
                ref_value = "chips",
                ease_to = card.ability.extra.multiplier*G.GAME.chips,
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
            G_TWMG.get_j_name("j_tiwmig_gravy"),        -- #3#
            G_TWMG.get_j_name("j_tiwmig_cheese_curds"), -- #4#
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
        G_TWMG.define_poutine_fusions(card, {
            {"j_tiwmig_gravy", "j_tiwmig_frite_sauce"},
            {"j_tiwmig_cheese_curds", "j_tiwmig_chips_n_cheese"},
            {"j_tiwmig_cheesy_gravy", "j_tiwmig_poutine"}
        })
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
            }
        end

        if context.after then
            if card.ability.extra.countdown - 1 <= 0 then
                G_TWMG.food_eat(card) -- Function to apply eaten effect (includes self-deletion)
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
            G_TWMG.get_j_name("j_tiwmig_cheese_curds"), -- #3#
            G_TWMG.get_j_name("j_tiwmig_french_fries"), -- #4#
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
        G_TWMG.define_poutine_fusions(card, {
            {"j_tiwmig_cheese_curds", "j_tiwmig_cheesy_gravy"},
            {"j_tiwmig_french_fries", "j_tiwmig_frite_sauce"},
            {"j_tiwmig_chips_n_cheese", "j_tiwmig_poutine"}
        })
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = card.ability.extra.mult,
            }
        end

        if context.after then
            if card.ability.extra.countdown - 1 <= 0 then
                G_TWMG.food_eat(card) -- Function to apply eaten effect (includes self-deletion)
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
            G_TWMG.get_j_name("j_tiwmig_french_fries"), -- #3#
            G_TWMG.get_j_name("j_tiwmig_gravy"),        -- #4#
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
        G_TWMG.define_poutine_fusions(card, {
            {"j_tiwmig_french_fries", "j_tiwmig_chips_n_cheese"},
            {"j_tiwmig_gravy", "j_tiwmig_cheesy_gravy"},
            {"j_tiwmig_frite_sauce", "j_tiwmig_poutine"}
        })
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
                G_TWMG.food_eat(card) -- Function to apply eaten effect (includes self-deletion)
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
            G_TWMG.get_j_name("j_tiwmig_cheese_curds"), -- #4#
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
        G_TWMG.define_poutine_fusions(card, {
            {"j_tiwmig_cheese_curds", "j_tiwmig_poutine"}
        })
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
                G_TWMG.food_eat(card) -- Function to apply eaten effect (includes self-deletion)
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
            G_TWMG.get_j_name("j_tiwmig_french_fries"), -- #4#
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
        G_TWMG.define_poutine_fusions(card, {
            {"j_tiwmig_french_fries", "j_tiwmig_poutine"}
        })
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
                G_TWMG.food_eat(card) -- Function to apply eaten effect (includes self-deletion)
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
            G_TWMG.get_j_name("j_tiwmig_gravy"), -- #4#
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
        G_TWMG.define_poutine_fusions(card, {
            {"j_tiwmig_gravy", "j_tiwmig_poutine"}
        })
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
                G_TWMG.food_eat(card) -- Function to apply eaten effect (includes self-deletion)
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
                G_TWMG.food_eat(card) -- Function to apply eaten effect (includes self-deletion)
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

-- == JOKER: "egg", j_tiwmig_egg
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

-- == JOKER: Shotgun, j_tiwmig_shotgun
SMODS.Joker { key = "shotgun",
    config = {
        extra = {
            xmult = 4,
            chamber = {},
            maxshells = 8,
            initialshells = {live=0,blank=0}
        }
    },

    loc_vars = function(self, info_queue, card)
        -- "2-#1# blank and live shells are loaded;"
        -- "Shoot on play; only live shells give X#2# Mult;"
        -- "#3# live round#4#. #5# blanks."
        -- "#6# shells remain"
        return {vars = {
            card.ability.extra.maxshells, -- #1#
            card.ability.extra.xmult,     -- #2#
            card.ability.extra.initialshells.blank, -- #3#
            card.ability.extra.initialshells.blank ~= 1 and "s" or "", -- #4#
            card.ability.extra.initialshells.live, -- #5#
            #card.ability.extra.chamber,  -- #6#
        }}
    end,

    atlas = "Joker atlas",
    pos = {x=3,y=1},
    display_size = { w = 71*1.3, h = 95*1.3 },

    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.setting_blind and #card.ability.extra.chamber < 1 then
            -- round(a) = floor(0.5 + a)
            -- number between 2 and shells = round(rng*(shells-2)) + 2
            local total_shells = math.floor(0.5 + pseudoseed('shotgun')*(card.ability.extra.maxshells - 2)) + 2
            local shell_count = {
                live = math.ceil(total_shells/2),
                blank = math.floor(total_shells/2)
            }

            --[[

            -- The difference between blanks and lives can be up to 3
            -- These conditionals just allow lives to increase
            if shell_count.blank > 1 and pseudoseed('shotgun1') > 0.5 then
                shell_count.live = shell_count.live + 1
                shell_count.blank = shell_count.blank - 1
            end
            if shell_count.blank > 1 and pseudoseed('shotgun2') > 0.5 then
                shell_count.live = shell_count.live + 1
                shell_count.blank = shell_count.blank - 1
            end

            ]]

            -- For the messages
            local shell_count_copy = {
                live = shell_count.live,
                blank = shell_count.blank
            }

            while shell_count.live + shell_count.blank > 0 do
                -- Note down which of live and blank is max, and which is min
                local max_shell = math.max(
                    shell_count.live,
                    shell_count.blank
                ) == shell_count.live and "live" or "blank"
                local min_shell = max_shell == "live" and "blank" or "live"
                local shell = ""

                -- Randomly pick between live and blank
                -- We do it this way so that if one of the shells is empty,
                -- we pick the shell that's not empty *always*
                if pseudoseed('loading')*(shell_count.live + shell_count.blank) < shell_count[max_shell] then
                    shell = max_shell
                else
                    shell = min_shell
                end

                -- One shell is taken from either pile and loaded into the chamber
                shell_count[shell] = shell_count[shell] - 1
                card.ability.extra.chamber[#card.ability.extra.chamber+1] = shell == "live" and 1 or 0
            end

            -- Debug note: shells go from 8, 7, 6... 3, 2, 1
            -- print(card.ability.extra.chamber)
            card.ability.extra.initialshells = shell_count_copy

            --[[ How many live shells?
            G.E_MANAGER:add_event(Event({
                blockable = false,
                func = function()
                    attention_text({
                        text = localize{type='variable',key='k_tiwmig_shotgun_load_live',vars={
                            shell_count_copy.live,
                            shell_count_copy.live > 1 and "s" or "" -- Add "s" for plural
                        }},
                        scale = 0.75, 
                        hold = 1.5,
                        backdrop_colour = G.C.RED,
                        align = 'tm',
                        major = card,
                        offset = {x = 0, y = 0.33*G.CARD_H}
                    })
                    play_sound('generic1', 1, 0.75)
                    return true
                end
            }))]]

            --[[ How many blanks?
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 1.75,
                blockable = false,
                func = function() 
                    attention_text({
                        text = localize{type='variable',key='k_tiwmig_shotgun_load_blank',vars={
                            shell_count_copy.blank,
                            shell_count_copy.blank > 1 and "s" or "" -- Add "s" for plural
                        }},
                        scale = 0.75, 
                        hold = 1.5,
                        backdrop_colour = G.C.GREY,
                        align = 'tm',
                        major = card,
                        offset = {x = 0, y = 0.66*G.CARD_H}
                    })
                    play_sound('generic1', 1, 0.75)
                    return true
                end
            }))]]

            -- "Load" each bullet into the shotgun
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                blockable = false,
                func = function()
                    for x = 1, total_shells do
                        G.E_MANAGER:add_event(Event({
                            delay = 0.35,
                            trigger = "after",
                            func = function()
                                card:juice_up()
                                play_sound('generic1', 1, 0.75)
                                return true
                            end
                        }))
                    end
                    return true
                end
            }))
        elseif context.joker_main and #card.ability.extra.chamber > 0 then
            -- Going from max to 1 (backwards), stating here for debug's sake
            local shell = card.ability.extra.chamber[#card.ability.extra.chamber]
            card.ability.extra.chamber[#card.ability.extra.chamber] = nil
            
            if shell == 1 then
                return {
                    xmult = card.ability.extra.xmult
                }
            else
                return {
                    message = localize("k_tiwmig_shotgun_blank"),
                    colour = G.C.GREY
                }
            end
        end
    end,
}

-- == JOKER: Large Boulder the Size of a Small Boulder, j_tiwmig_large_small_boulder
SMODS.Joker { key = "large_small_boulder",
    -- This Joker's effect is most evident in section 3 of lovely.toml
    config = {
        extra = {},
    },

    loc_vars = function(self, info_queue, card)
        -- "All cards are considered one rank lower"
        return {vars = {}}
    end,

    atlas = "Joker atlas",
    pos = {x=3,y=2},

    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
}

-- == JOKER: Commenting Out, j_tiwmig_commenting_out
SMODS.Joker { key = "commenting_out",
    config = {
        extra = {
            disabled_joker = nil,
            uid = ''
        },
    },

    loc_vars = function(self, info_queue, card)
        -- "Disables the Joker to the right"
        return {vars = {}}
    end,

    atlas = "Joker atlas",
    pos = {x=0, y=3},

    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    add_to_deck = function(self, card, from_debuff)
        card.ability.extra.uid = 'tiwmig_commenting_out_' .. tostring(math.random())
        local my_pos = nil
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i] == card then
                my_pos = i
                break
            end
        end
        if my_pos and G.jokers.cards[my_pos+1] then
            SMODS.debuff_card(G.jokers.cards[my_pos+1], true, card.ability.extra.uid)
            card.ability.extra.disabled_joker = G.jokers.cards[my_pos+1]
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        if card.ability.extra.disabled_joker then
            SMODS.debuff_card(card.ability.extra.disabled_joker, false, card.ability.extra.uid)
        end
    end,

    update = function(self, card, dt) if G.jokers then
        local my_pos = nil
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i] == card then
                my_pos = i
                break
            end
        end
        if my_pos and G.jokers.cards[my_pos+1] and not card.debuff then
            if card.ability.extra.disabled_joker and G.jokers.cards[my_pos+1] ~= card.ability.extra.disabled_joker then
                SMODS.debuff_card(card.ability.extra.disabled_joker, false, card.ability.extra.uid)
            end
            card.ability.extra.disabled_joker = G.jokers.cards[my_pos+1]
            SMODS.debuff_card(card.ability.extra.disabled_joker, true, card.ability.extra.uid)
        elseif card.ability.extra.disabled_joker then
            SMODS.debuff_card(card.ability.extra.disabled_joker, false, card.ability.extra.uid)
        end
    end end
}

--[[ 

-- == JOKER: Prototype, j_tiwmig_prototype
SMODS.Joker { key = "prototype",
    config = {
        extra = {},
    },

    loc_vars = function(self, info_queue, card)
        -- "Retriggers the rightmost Joker; distinct from copying a Joker"
        return {vars = {}}
    end,

    atlas = "Character atlas",
    pos = {x=0,y=0},
    soul_pos = {x=1,y=0},

    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.retrigger_joker_check and not context.retrigger_joker and context.other_card ~= self then
            if context.other_card == G.jokers.cards[#G.jokers.cards] then
                return {
                    message = localize('k_again_ex'),
                    repetitions = 1,
                    card = card
                }
            end
        end
    end,
}

-- == JOKER: Product, j_tiwmig_product
SMODS.Joker { key = "product",
    config = {
        extra = {},
    },

    loc_vars = function(self, info_queue, card)
        -- "Retriggers the left Joker; distinct from copying a Joker"
        return {vars = {}}
    end,

    atlas = "Placeholders",
    pos = G_TWMG.placeholders.joker,

    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.retrigger_joker_check and not context.retrigger_joker and context.other_card ~= self then
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] == card and G.jokers.cards[i-1] and G.jokers.cards[i-1] == context.other_card then
                    return {
                        message = localize('k_again_ex'),
                        repetitions = 1,
                        card = card
                    }
                end
            end
        end
    end,
}

]]--

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