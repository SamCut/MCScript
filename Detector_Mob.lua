while true do
    -- Finds your 'geo_scanner_1'
    local scanners = { peripheral.find("geo_scanner") }
    
    term.clear()
    term.setCursorPos(1,1)
    print("--- POD MONITORING [" .. #scanners .. "] ---")

    for i, scanner in ipairs(scanners) do
        local name = peripheral.getName(scanner)
        -- Radius 8 is good, but let's be thorough
        local results = scanner.scan(8) 
        local found = false
        
        if results then
            for _, obj in pairs(results) do
                -- Debug: Let's check 'type' instead of 'name'
                -- Entities usually have a 'type' field like "minecraft:villager"
                local check = obj.type or obj.name or ""
                
                if check:lower():find("villager") then
                    found = true
                    break
                end
            end
        end

        local status = found and "OK" or "EMPTY"
        -- This will print the scanner name and current status
        print(name .. ": " .. status)
        
        -- If it's EMPTY, we can trigger an alert here later
    end

    sleep(3)
end