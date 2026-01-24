while true do
    -- Use the snake_case type found in your logs
    local scanners = { peripheral.find("geo_scanner") }
    
    term.clear()
    term.setCursorPos(1,1)
    print("--- POD MONITORING [" .. #scanners .. "] ---")

    for i, scanner in ipairs(scanners) do
        local name = peripheral.getName(scanner)
        
        -- CHANGE: 'scanEntities' is now just 'scan' in 1.21
        local entities = scanner.scan(4) 
        local found = false
        
        if entities then
            for _, entity in pairs(entities) do
                -- In some versions, 'name' might be 'type' or 'displayName'
                if entity.name and entity.name:find("Villager") then
                    found = true
                    break
                end
            end
        end

        local status = found and "OK" or "EMPTY"
        print(name .. ": " .. status)
    end

    -- Keep the 3s sleep to avoid scanner cooldown errors
    sleep(3)
end