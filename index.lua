-- Loading features
SMODS.current_mod.optional_features = {
    retrigger_joker = true
}

-- == SECTION: Based on code from `Cryptid.lua`, Cryptid mod
-- Global object for various important features
if not G_TWMG then G_TWMG = {} end

local files = NFS.getDirectoryItems(SMODS.current_mod.path .. "items")
for _, file in ipairs(files) do
    print("[TIWMIG] Loading item file " .. file)
    local f, err = SMODS.load_file("items/" .. file)
    if err then
        error(err)
    end
    f()
end
-- == SECTION END

-- == Card:calculate_joker value interception (many thanks to Airtoum for the idea and code for this)
local calc_joker_func = Card.calculate_joker -- preserving previous iteration of calculate_joker

function Card:calculate_joker(context) -- THIS is what will be called by various events instead
    local return_value = calc_joker_func(self, context)

    if not return_value then
        -- Large-Small Boulder
            -- Rank-based Jokers should only trigger once per card;
            -- this conditional catches the lower-rank case, if the default-rank case does not result in anything
        if (context.other_card and 
            context.other_card.base and 
            context.other_card.base.id and 
            #SMODS.find_card("j_tiwmig_large_small_boulder") > 0
        ) then
            local oc = context.other_card
            oc.base.id = oc.base.id == 2 and 14 or math.max(oc.base.id - 1, 2)
            return_value = calc_joker_func(self, context)
            oc.base.id = oc.base.id == 14 and 2 or math.min(oc.base.id + 1, 14)
            
        elseif (context.scoring_hand and
            #SMODS.find_card("j_tiwmig_large_small_boulder") > 0
        ) then
            for i = 1, #context.scoring_hand do
                local oc = context.scoring_hand[i]
                oc.base.id = oc.base.id == 2 and 14 or math.max(oc.base.id - 1, 2)
            end
            return_value = calc_joker_func(self, context)
            for i = 1, #context.scoring_hand do
                local oc = context.scoring_hand[i]
                oc.base.id = oc.base.id == 14 and 2 or math.min(oc.base.id + 1, 14)
            end
        end
    end

    return return_value
end