while true do
    -- Find the scanner (geo_scanner_1 in your images)
    local scanners = { peripheral.find("geo_scanner") }
    
    term.clear()
    term.setCursorPos(1,1)
    print("--- MONITORING [" .. #scanners .. "] ---")

    for _, scanner in ipairs(scanners) do
        -- CRITICAL CHANGE: The 'true' tells the scanner to find ENTITIES
        -- If this is missing, you only see blackstone bricks!
        local results = scanner.scan(8, true) 
        local found = false
        
        if results then
            for _, obj in pairs(results) do
                -- We check 'type' because 'name' is often for blocks
                local check = (obj.type or obj.name or ""):lower()
                
                if check:find("villager") then
                    found = true
                    break
                end
            end
        end

        local status = found and "OK" or "EMPTY"
        print(peripheral.getName(scanner) .. ": " .. status)
    end

    -- Cooldown is ~2 seconds in 1.21
    sleep(3)
end