local SMALL_TANK_CAPACITY = 16000
local mon = peripheral.find("monitor")

if not mon then
    print("Error: Monitor not found!")
    return
end

local function drawBar(percent)
    local w, h = mon.getSize()
    local barWidth = w - 2
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
    -- 1. Find ALL tanks (Standard + Dynamic)
    local allTanks = {}
    
    -- Add standard fluid_storage
    for _, tank in pairs({ peripheral.find("fluid_storage") }) do
        table.insert(allTanks, tank)
    end
    
    -- Add Mekanism dynamic tanks
    -- We search for both common type names just in case
    for _, tank in pairs({ peripheral.find("dynamic_tank") }) do
        table.insert(allTanks, tank)
    end
    for _, tank in pairs({ peripheral.find("mekanism:dynamic_tank") }) do
        table.insert(allTanks, tank)
    end

    local currentAmount = 0
    local totalMax = 0
    local fluidName = "Empty"

    -- 2. Calculate totals
    for _, tank in pairs(allTanks) do
        -- A. Determine Capacity for this specific tank
        local thisCapacity = SMALL_TANK_CAPACITY
        
        -- If the tank is smart (Mekanism) it tells us its capacity
        if tank.getCapacity then
            thisCapacity = tank.getCapacity() 
        end
        totalMax = totalMax + thisCapacity

        -- B. Determine Fluid Level
        -- We use pcall just in case a tank is malformed or busy
        if tank.tanks then
            local data = tank.tanks()
            if data and data[1] then
                currentAmount = currentAmount + data[1].amount
                if data[1].amount > 0 then
                    fluidName = data[1].name
                end
            end
        end
    end

    -- 3. Update the Monitor
    mon.clear()
    mon.setTextScale(1)
    mon.setCursorPos(1, 1)
    mon.setTextColor(colors.red)
    mon.write("-- BLOOD MONITORING SYSTEM --")

    if #allTanks > 0 then
        local percent = 0
        if totalMax > 0 then
            percent = (currentAmount / totalMax) * 100
        end
        
        -- ALIGNMENT
        local L = 15
        local V = 7

        mon.setCursorPos(3, 3)
        mon.write(string.format("%-"..L.."s %"..V.."d", "Tanks:", #allTanks))
        
        mon.setCursorPos(3, 4)
        mon.write(string.format("%-"..L.."s %"..V.."d B", "Current:", math.floor(currentAmount / 1000)))
        
        mon.setCursorPos(3, 5)
        mon.write(string.format("%-"..L.."s %"..V.."d B", "Max Cap:", math.floor(totalMax / 1000)))
        
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