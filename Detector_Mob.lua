-- Configuration
local TARGET_MOB = "Villager"
local SCAN_RADIUS = 2 -- Small radius to only see what's in the pod

while true do
    -- 1. Find ALL scanners on the network
    local scanners = { peripheral.find("geoScanner") }
    
    term.clear()
    term.setCursorPos(1,1)
    print("--- POD MONITORING [" .. #scanners .. "] ---")

    for i, scanner in ipairs(scanners) do
        -- 2. Scan for entities at each specific scanner
        local entities = scanner.scanEntities(SCAN_RADIUS)
        local isAlive = false
        
        -- The scanner returns nil if it's on cooldown, so we check first
        if entities then
            for _, entity in pairs(entities) do
                if entity.name == TARGET_MOB then
                    isAlive = true
                    break
                end
            end
        end

        -- 3. Print status for this specific pod
        local status = isAlive and "OK" or "EMPTY"
        -- We use scanner.getNameLocal() or peripheral.getName(scanner) to identify which is which
        print("Pod " .. i .. " (" .. peripheral.getName(scanner) .. "): " .. status)
    end

    -- Scanners have a 2-3 second cooldown in 1.21
    sleep(3)
end