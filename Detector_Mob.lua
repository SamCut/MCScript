local detector = peripheral.find("environmentDetector")

-- Configuration
local TARGET_TYPE = "minecraft:villager"
local RADIUS = 5 -- Keep this small so you don't detect outside the pod

while true do
    term.clear()
    term.setCursorPos(1,1)
    
    local entities = detector.scanEntities(RADIUS)
    local found = false
    
    for _, entity in pairs(entities) do
        if entity.type == TARGET_TYPE then
            found = true
            print("Villager: ALIVE")
            -- Some versions of the mod don't return health for passives
            if entity.health then
                print("Health: " .. entity.health)
            end
        end
    end
    
    if not found then
        print("ALERT: VILLAGER DEAD OR MISSING")
    end
    
    sleep(2)
end