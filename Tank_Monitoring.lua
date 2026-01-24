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
        
        -- ALIGNMENT: 15 char labels + 7 char values keeps everything 
        -- away from the right-hand bezel of a 3x2 monitor.
        local L = 15
        local V = 7

        mon.setCursorPos(3, 3)
        mon.write(string.format("%-"..L.."s %"..V.."d", "Tanks:", #tanks))
        
        mon.setCursorPos(3, 4)
        mon.write(string.format("%-"..L.."s %"..V.."d B", "Current:", currentAmount / 1000))
        
        mon.setCursorPos(3, 5)
        mon.write(string.format("%-"..L.."s %"..V.."d B", "Max Cap:", totalMax / 1000))
        
        mon.setCursorPos(3, 6)
        mon.write(string.format("%-"..L.."s %"..V..".1f%%", "Fill:", percent))
        
        drawBar(percent)
    else
        mon.setCursorPos(2, 4)
        mon.setTextColor(colors.red)
        mon.write("NO TANKS DETECTED")
    end

    sleep(1)
end