-- Use find() so you don't have to worry about the exact network ID
local detector = peripheral.find("environment_detector")

-- Safety check: Stop the program if it's not connected
if not detector then
    print("Error: Environment Detector not found on network!")
    print("Make sure the modem on the detector is RED (Right-Click it).")
    return
end

local TARGET = "minecraft:villager"
local RADIUS = 8

while true do
    term.clear()
    term.setCursorPos(1,1)
    
    -- Check if the function exists (sometimes it's scanEntities, sometimes scan)
    local entities = {}
    if detector.scanEntities then
        entities = detector.scanEntities(RADIUS)
    else
        print("Function 'scanEntities' not found. Checking for 'scan'...")
        entities = detector.scan(RADIUS)
    end

    local alive = false
    for _, entity in pairs(entities) do
        if entity.type == TARGET then
            alive = true
            print("Villager: ALIVE")
            if entity.health then print("Health: " .. entity.health) end
        end
    end

    if not alive then
        print("ALERT: VILLAGER IS DEAD")
        -- Optional: redstone.setOutput("top", true)
    end

    sleep(2)
end