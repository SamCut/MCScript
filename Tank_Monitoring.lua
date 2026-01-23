local tank = peripheral.find("fluid_storage")
local MAX_CAPACITY = 16000 -- Hardcoded based on your info

if not tank then
    print("No tank found!")
    return
end

local lastAmount = -1

print("Monitoring Tank... (Press Ctrl+T to stop)")

while true do
    local info = tank.tanks()[1]
    local currentAmount = info and info.amount or 0
    local fluidName = info and info.name or "Empty"

    -- Only update the screen if the fluid level has changed
    if currentAmount ~= lastAmount then
        term.clear()
        term.setCursorPos(1,1)
        
        print("=== Tank Monitor ===")
        print("Fluid:    " .. fluidName)
        print("Amount:   " .. currentAmount .. " mB")
        
        local percent = (currentAmount / MAX_CAPACITY) * 100
        print(string.format("Fill:     %.1f%%", percent))
        
        -- Visual progress bar
        local barWidth = 20
        local filledWidth = math.floor((currentAmount / MAX_CAPACITY) * barWidth)
        local bar = "[" .. string.rep("#", filledWidth) .. string.rep("-", barWidth - filledWidth) .. "]"
        print("\nStatus: " .. bar)

        lastAmount = currentAmount
    end

    sleep(1) -- Check every second
end