local detector = peripheral.find("playerDetector")

while true do
    term.clear()
    term.setCursorPos(1,1)
    
    -- This function is the ONLY one in AP that sees villagers in 1.21
    local entities = detector.getEntitiesInRange(5)
    local found = false
    
    if entities then
        for _, name in pairs(entities) do
            -- Mobs are returned as strings like "minecraft:villager"
            if name:find("villager") then
                found = true
                break
            end
        end
    end
    
    if found then
        print("STATUS: VILLAGER ALIVE")
    else
        print("!!! ALERT: VILLAGER GONE !!!")
    end
    
    sleep(2)
end