local CAPACITY_PER_TANK = 16000
local mon = peripheral.find("monitor")

if not mon then
    print("Error: Monitor not found!")
    return
end

local function drawBar(percent)
    local w, h = mon.getSize()
    local barWidth = w - 9
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
    mon.setTextColor(colors.red)
    mon.write("--- BLOOD MONITORING SYSTEM ---")

    if #tanks > 0 then
local percent = (currentAmount / totalMax) * 100
        
        -- FORMATTING: 16 char labels + 8 char values fits a 3x2 monitor perfectly
        local lbl = 16
        local val = 8

        mon.setCursorPos(2, 3)
        mon.write(string.format("%-"..lbl.."s %"..val.."d", "Tanks Detected:", #tanks))
        
        mon.setCursorPos(2, 4)
        -- Converting mB to Buckets (B) to keep the strings shorter
        mon.write(string.format("%-"..lbl.."s %"..val.."d B", "Current Amount:", currentAmount / 1000))
        
        mon.setCursorPos(2, 5)
        mon.write(string.format("%-"..lbl.."s %"..val.."d B", "Max Capacity:", totalMax / 1000))
        
        mon.setCursorPos(2, 6)
        mon.write(string.format("%-"..lbl.."s %"..val..".1f%%", "Fill Level:", percent))
        
        drawBar(percent)
    else
        mon.setCursorPos(2, 4)
        mon.setTextColor(colors.red)
        mon.write("NO TANKS DETECTED")
    end

    sleep(1)
end