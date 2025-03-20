-- Loading features
SMODS.current_mod.optional_features = {
    retrigger_joker = true
}

-- == SECTION: Based on code from `Cryptid.lua`, Cryptid mod
-- Global object for various important features
if not G_TWMG then G_TWMG = {} end
local f,err = SMODS.load_file("global.lua")
if err then error(err) end
f()

-- Load other files
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