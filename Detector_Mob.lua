-- Find all detectors and put them in a table
local detectors = { peripheral.find("environment_detector") }

if #detectors == 0 then
    print("Error: No detectors found! Check your modems.")
    return
end

print("Monitoring " .. #detectors .. " pods...")

while true do
    term.clear()
    term.setCursorPos(1,1)
    print("--- GLOBAL POD STATUS ---")
    print("-------------------------")

    for i, d in ipairs(detectors) do
        -- Get the network name (e.g., environment_detector_0)
        local name = peripheral.getName(d)
        local entities = d.scanEntities(4) -- Small range since it's 1-per-pod
        
        local alive = false
        for _, e in pairs(entities) do
            if e.name == "Unemployed" then
                alive = true
                break
            end
        end

        -- Print status for this specific pod
        term.setCursorPos(1, i + 2)
        if alive then
            term.setTextColor(colors.green)
            print(name .. ": [ OK ]")
        else
            term.setTextColor(colors.red)
            print(name .. ": [ MISSING ]")
            -- Optional: You can trigger redstone on a per-pod basis 
            -- if the computer is touching the pod's redstone input.
        end
    end

    term.setTextColor(colors.white)
    sleep(2)
end