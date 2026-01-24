local detector = peripheral.find("environment_detector")

-- Comprehensive list of villager professions in ATM 10
local villagerProfessions = {
    ["Unemployed"] = true, ["Nitwit"] = true, ["Armorer"] = true,
    ["Butcher"] = true, ["Cartographer"] = true, ["Cleric"] = true,
    ["Farmer"] = true, ["Fisherman"] = true, ["Fletcher"] = true,
    ["Leatherworker"] = true, ["Librarian"] = true, ["Mason"] = true,
    ["Shepherd"] = true, ["Toolsmith"] = true, ["Weaponsmith"] = true
}

local RANGE = 8

while true do
    term.clear()
    term.setCursorPos(1,1)
    
    local entities = detector.scanEntities(RANGE)
    local found = false
    local currentJob = "None"

    for _, entity in pairs(entities) do
        -- Check if the entity's name matches any profession in our list
        if villagerProfessions[entity.name] then
            found = true
            currentJob = entity.name
            break
        end
    end

    if found then
        term.setTextColor(colors.green)
        print("STATUS: VILLAGER ALIVE")
        term.setTextColor(colors.white)
        print("Profession: " .. currentJob)
        redstone.setOutput("back", false) -- Turn off alarm
    else
        term.setTextColor(colors.red)
        print("ALERT: VILLAGER GONE!")
        term.setTextColor(colors.white)
        print("No living villager within " .. RANGE .. " blocks.")
        redstone.setOutput("back", true) -- Trigger alarm/spawner
    end

    sleep(2) -- Check every 2 seconds to reduce lag
end