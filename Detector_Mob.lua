while true do
    local scanners = { peripheral.find("geo_scanner") }
    term.clear()
    term.setCursorPos(1,1)
    print("--- POD MONITORING [" .. #scanners .. "] ---")

    for i, scanner in ipairs(scanners) do
        local name = peripheral.getName(scanner)
        -- Increased radius to 8 to reach the pod
        local entities = scanner.scan(8) 
        local found = false
        
        if entities then
            for _, entity in pairs(entities) do
                -- This debug line helps find the exact name if 'Villager' fails
                -- print("Saw: " .. tostring(entity.name)) 

                if entity.name and entity.name:lower():find("villager") then
                    found = true
                    break
                end
            end
        end

        local status = found and "OK" or "EMPTY"
        print(name .. ": " .. status)
    end

    sleep(3)
end