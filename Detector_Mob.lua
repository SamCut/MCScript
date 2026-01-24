-- Find all detectors on the network
local detectors = { peripheral.find("environment_detector") }

if #detectors == 0 then
    print("Error: No detectors found!")
    return
end

-- Sort detectors by name so the order doesn't jump around on the screen
table.sort(detectors, function(a, b) 
    return peripheral.getName(a) < peripheral.getName(b) 
end)

while true do
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.yellow)
    print("--- BLOOD POD VITALS ---")
    print("------------------------")

    for i, d in ipairs(detectors) do
        local entities = d.scanEntities(4)
        local alive = false
        
        for _, e in pairs(entities) do
            -- Using your verified "Unemployed" name check
            if e.name == "Unemployed" then
                alive = true
                break
            end
        end

        -- Display the sequential "Villager #"
        term.setCursorPos(1, i + 2)
        term.setTextColor(colors.white)
        write("Villager " .. i .. ": ")

        if alive then
            term.setTextColor(colors.green)
            print("[ ALIVE ]")
        else
            term.setTextColor(colors.red)
            print("[ DEAD ]")
            -- Trigger an alarm if any one of them dies
            redstone.setOutput("back", true)
        end
    end

    term.setTextColor(colors.white)
    sleep(2)
end