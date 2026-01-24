while true do
    -- Find all scanners by type 'geo_scanner'
    local scanners = { peripheral.find("geo_scanner") }
    
    term.clear()
    term.setCursorPos(1,1)
    print("--- POD MONITORING [" .. #scanners .. "] ---")

    for i, scanner in ipairs(scanners) do
        local name = peripheral.getName(scanner)
        -- Use a larger radius (8) to ensure it reaches the pod from the computer
        local results = scanner.scan(8) 
        local found = false
        
        if results then
            for _, obj in pairs(results) do
                -- Check for both 'type' and 'name' fields
                -- Many 1.21 entities store their species in 'type'
                local check = (obj.type or obj.name or ""):lower()
                
                if check:find("villager") then
                    found = true
                    -- Uncomment the next line once to see exactly what the scanner calls it
                    -- print("SUCCESS: Found " .. check)
                    break
                end
            end
        end

        local status = found and "OK" or "EMPTY"
        print(name .. ": " .. status)
    end

    -- Scanners have a 2-3 second cooldown; don't scan too fast!
    sleep(3)
end