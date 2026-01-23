local MAX_CAPACITY = 16000
local mon = peripheral.find("monitor")

if not mon then
    print("Error: Monitor not found!")
    return
end

-- Function to draw the solid red bar
local function drawBar(percent)
    local w, h = mon.getSize()
    local barWidth = w - 4
    local filledWidth = math.floor((percent / 100) * barWidth)
    
    -- Draw Background (Gray)
    mon.setCursorPos(2, 7)
    mon.setBackgroundColor(colors.gray)
    mon.write(string.rep(" ", barWidth))
    
    -- Draw Fill (Red)
    if filledWidth > 0 then
        mon.setCursorPos(2, 7)
        mon.setBackgroundColor(colors.red)
        mon.write(string.rep(" ", filledWidth))
    end
    mon.setBackgroundColor(colors.black)
end

while true do
    -- Re-scan for the tank every loop so it doesn't crash if it blips
    local tank = peripheral.find("fluid_storage")
    
    if tank then
        local success, tanks = pcall(tank.tanks)
        local info = (success and tanks) and tanks[1] or nil
        
        mon.clear()
        mon.setTextScale(1)
        mon.setCursorPos(1, 1)
        mon.setTextColor(colors.yellow)
        mon.write("--- BLOOD MONITOR ---")
        mon.setTextColor(colors.white)

        if info then
            local amount = info.amount or 0
            local percent = (amount / MAX_CAPACITY) * 100
            
            mon.setCursorPos(2, 3)
            mon.write("Fluid: " .. (info.name or "Blood"))
            mon.setCursorPos(2, 4)
            mon.write("Level: " .. amount .. " mB")
            mon.setCursorPos(2, 5)
            mon.write(string.format("Fill:  %.1f%%", percent))
            
            drawBar(percent)
        else
            mon.setCursorPos(2, 4)
            mon.setTextColor(colors.red)
            mon.write("TANK DATA EMPTY")
        end
    else
        -- If the tank is missing, show a warning instead of crashing
        mon.clear()
        mon.setCursorPos(1, 1)
        mon.setTextColor(colors.red)
        mon.write("!! DISCONNECTED !!")
        mon.setCursorPos(1, 2)
        mon.write("Check modems/wires.")
    end

    sleep(1) -- Refresh rate
end