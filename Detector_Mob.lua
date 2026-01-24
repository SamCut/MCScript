local scanner = peripheral.find("geoScanner")

while true do
    term.clear()
    term.setCursorPos(1,1)
    
    -- Scan a 2-block radius around the scanner
    local entities = scanner.scanEntities(2)
    local found = false
    
    for _, entity in pairs(entities) do
        -- Check if the entity is a Villager
        if entity.name == "Villager" then
            found = true
            break
        end
    end
    
    if found then
        print("STATUS: Villager is ALIVE")
    else
        print("!!! ALERT: VILLAGER DEAD !!!")
        -- If you have a Chat Box, you can add chat.say("Emergency!") here
    end
    
    sleep(5) -- Checks every 5 seconds
end