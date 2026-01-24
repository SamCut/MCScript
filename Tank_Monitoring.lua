local CAPACITY_PER_TANK = 16000
local mon = peripheral.find("monitor")

if not mon then
    print("Error: Monitor not found!")
    return
end

local function drawBar(percent)
    local w, h = mon.getSize()
    local barWidth = w - 4
    local filledWidth = math.floor((percent / 100) * barWidth)
    
    -- Background (Gray)
    mon.setCursorPos(2, 8)
    mon.setBackgroundColor(colors.gray)
    mon.write(string.rep(" ", barWidth))
    
    -- Fill (Red)
    if filledWidth > 0 then
        mon.setCursorPos(2, 8)
        mon.setBackgroundColor(colors.red)
        mon.write(string.rep(" ", filledWidth))
    end
    mon.setBackgroundColor(colors.black)
end

while true do
    -- 1. Find ALL tanks on the network
    local tanks = { peripheral.find("fluid_storage") }
    local currentAmount = 0
    local totalMax = #tanks * CAPACITY_PER_TANK
    local fluidName = "Empty"

    -- 2. Sum up the blood in every tank found
    for i = 1, #tanks do
        local info = tanks[i].tanks()[1]
        if info and info.amount > 0 then
            currentAmount = currentAmount + info.amount
            fluidName = info.name or fluidName
        end
    end

    -- 3. Update the Monitor
    mon.clear()
    mon.setTextScale(1)
    mon.setCursorPos(1, 1)
    mon.setTextColor(colors.yellow)
    mon.write("--- BLOOD MONITORING SYSTEM ---")
    mon.setTextColor(colors.white)

    if #tanks > 0 then
        local percent = (currentAmount / totalMax) * 100
        
        mon.setCursorPos(2, 3)
        mon.write("Tanks Detected: " .. #tanks)
        mon.setCursorPos(2, 4)
        mon.write("Current Amount:   " .. currentAmount .. " mB")
        mon.setCursorPos(2, 5)
        mon.write("Maxium:      " .. totalMax .. " mB")
        
        mon.setCursorPos(2, 6)
        mon.write(string.format("Fill:           %.1f%%", percent))
        
        drawBar(percent)
    else
        mon.setCursorPos(2, 4)
        mon.setTextColor(colors.red)
        mon.write("NO TANKS DETECTED")
    end

    sleep(1)
end