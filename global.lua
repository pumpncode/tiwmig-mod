-- == VARIABLES
G_TWMG.max_card_layers = 5
-- For the infinite Joker iterator
G_TWMG.inf_j_iter = {
    index = 0,
    group_size = 5
}

-- All functions in this table must take i, the Joker index
G_TWMG.inf_j_iter.funcs = {
    tiwmig = function(i)
        local joker_c = G.jokers.cards
        
        if i > 1 and joker_c[i-1].label == "j_tiwmig_commenting_out" and not joker_c[i-1].debuff then
            SMODS.debuff_card(G.jokers.cards[i], true, "tiwmig_commenting_out")
        else
            SMODS.debuff_card(G.jokers.cards[i], false, "tiwmig_commenting_out")
        end
    end,
}

-- == FUNCTION: standardized card layer names
G_TWMG.layer_name = function(type, id)
    return "tiwmig_" .. type .. "_layer_" .. tostring(id)
end

-- == FUNCTION: Localized Joker name shorthand
G_TWMG.get_j_name = function(joker_key)
    if not G.localization.descriptions.Joker[joker_key] then return joker_key end
    return G.localization.descriptions.Joker[joker_key].name
end

-- == FUNCTION: Food Joker "consumption"
G_TWMG.food_eat = function(card)
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

-- == FUNCTION: Poutine components fusion
-- card and target are card objects, sum is string (key of Joker)
G_TWMG.poutine_fusion = function(card, target, sum)
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
            G_TWMG.food_eat(card)   -- Using food_eat for convenience
            G_TWMG.food_eat(target)
            SMODS.add_card{
                key = sum,
                edition = sum_edition,
                no_edition = true
            }
            return true
        end
    }))
end

-- == FUNCTION: Poutine fusion macro
G_TWMG.define_poutine_fusions = function(card, recipe_table)
    -- This system grants higher priority to items of lower index
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.25, -- Delay needed to account for split moment that both cards are not debuffed (mainly from Commented Out)
        blockable = false,
        func = function ()
            for __,recipe in ipairs(recipe_table) do
                local other_card_id  = recipe[1]
                local result_card_id = recipe[2]
                if (
                    #SMODS.find_card(other_card_id) > 0 and not (
                        card.debuff or 
                        SMODS.find_card(other_card_id)[1].debuff or
                        card.ability.extra.being_fused or
                        SMODS.find_card(other_card_id)[1].ability.extra.being_fused
                    )
                ) then
                    card.ability.extra.being_fused = true
                    SMODS.find_card(other_card_id)[1].ability.extra.being_fused = true
                    G_TWMG.poutine_fusion(card, SMODS.find_card(other_card_id)[1], result_card_id)
                end
            end
            return true
        end
    }))
end