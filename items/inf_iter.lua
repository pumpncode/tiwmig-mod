-- == EVENT: Iterate through all Jokers repeatedly

-- Iterate through all Jokers in groups of G_TWMG.inf_j_iter.group_size
local tiwmig_inf_j_iter = function()
    -- G.STATE == 2 is the main scoring sequence
    if not (G and G.jokers and G.jokers.cards) or G.STATE == 2 then
        G_TWMG.inf_j_iter.index = 0
        return
    end

    if #G.jokers.cards < 1 or (G_TWMG.inf_j_iter.index*G_TWMG.inf_j_iter.group_size + 1) > #G.jokers.cards then
        G_TWMG.inf_j_iter.index = 0
        return
    end

    for offset = 1, G_TWMG.inf_j_iter.group_size do
        local i = G_TWMG.inf_j_iter.index*G_TWMG.inf_j_iter.group_size + offset
        if i > #G.jokers.cards then
            G_TWMG.inf_j_iter.index = 0
            return
        end
        
        -- G_TWMG.inf_j_iter.funcs is where all the code for joker iteration takes place in
        for _,v in pairs(G_TWMG.inf_j_iter.funcs) do v(i) end

    end

    G_TWMG.inf_j_iter.index = G_TWMG.inf_j_iter.index + 1
end

-- Iterate through all Collection Jokers
local tiwmig_inf_collection_j_iter = function()
    if not (G and G.your_collection) then return end
    for _,row in ipairs(G.your_collection) do if row.cards then
        local joker_c = row.cards
        -- START
        for i=1,#joker_c do
            if i > 1 and joker_c[i-1].label == "j_tiwmig_commenting_out" and not joker_c[i-1].debuff then
                SMODS.debuff_card(joker_c[i], true, "tiwmig_commenting_out")
            else
                SMODS.debuff_card(joker_c[i], false, "tiwmig_commenting_out")
            end
        end
        -- END
    end end
end

local tiwmig_inf_iter_event
tiwmig_inf_iter_event = Event {
    blockable = false,
    blocking = false,
    pause_force = false,
    no_delete = true,
    trigger = "after",
    delay = 0,
    timer = "REAL",
    func = function()
        tiwmig_inf_collection_j_iter()
        tiwmig_inf_j_iter()
        tiwmig_inf_iter_event.start_timer = false
    end
}
G.E_MANAGER:add_event(tiwmig_inf_iter_event)