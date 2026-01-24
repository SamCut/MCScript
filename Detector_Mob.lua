local scanner = peripheral.find("geo_scanner")

while true do
    term.clear()
    term.setCursorPos(1,1)
    
    -- The first '8' is radius. 
    -- The FIRST 'true' tells it to scan for ENTITIES.
    -- The SECOND 'true' (if supported) tells it to ignore blocks.
    local results = scanner.scan(8, true) 
    local found = false
    
    if results then
        for _, obj in pairs(results) do
            -- We check 'name' and 'type' because different mods label mobs differently
            local id = (obj.type or obj.name or ""):lower()
            
            if id:find("villager") then
                found = true
                break
            end
        end
    end
    
    if found then
        print("STATUS: VILLAGER SPOTTED")
    else
        print("STATUS: EMPTY / NOT SEEN")
    end
    
    sleep(2) -- Cooldown for the scanner
end