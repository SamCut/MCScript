local TARGET = "villager"

while true do
    local scanners = { peripheral.find("geo_scanner") }
    term.clear()
    term.setCursorPos(1,1)
    print("--- MONITORING [" .. #scanners .. "] ---")

    for _, scanner in ipairs(scanners) do
        -- The 'true' here is the "Barely Anything" change that actually matters:
        -- It forces the scanner to look for ENTITIES, not just blocks.
        local results = scanner.scan(8, true) 
        local found = false
        
        if results then
            for _, obj in pairs(results) do
                -- Check for species/type
                local name = (obj.name or ""):lower()
                local type = (obj.type or ""):lower()

                if name:find(TARGET) or type:find(TARGET) then
                    found = true
                    break
                end
            end
        end

        local status = found and "OK" or "EMPTY"
        print(peripheral.getName(scanner) .. ": " .. status)
    end

    sleep(3) -- Prevent cooldown crash
end