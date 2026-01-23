local tank = peripheral.find("fluid_storage")
local mon = peripheral.find("monitor")
local MAX_CAPACITY = 16000

if not mon then
    print("Error: Monitor not found!")
    return
end

mon.setTextScale(1) -- Smaller text allows for a bigger graphical bar

local function drawProgressBar(x, y, width, percent)
    local filledWidth = math.floor((percent / 100) * width)
    
    -- Draw the background/empty part of the bar (Gray)
    mon.setCursorPos(x, y)
    mon.setBackgroundColor(colors.gray)
    mon.write(string.rep(" ", width))
    
    -- Draw the filled part (Red)
    if filledWidth > 0 then
        mon.setCursorPos(x, y)
        mon.setBackgroundColor(colors.red)
        mon.write(string.rep(" ", filledWidth))
    end
    
    -- Reset to black for text
    mon.setBackgroundColor(colors.black)
end

local lastAmount = -1

while true do
    local info = tank.tanks()[1]
    local currentAmount = info and info.amount or 0
    local fluidName = info and info.name or "Empty"
    local percent = (currentAmount / MAX_CAPACITY) * 100

    if currentAmount ~= lastAmount then
        mon.clear()
        
        -- Header
        mon.setCursorPos(1, 2)
        mon.setTextColor(colors.yellow)
        mon.write("--- BLOOD STORAGE SYSTEM ---")
        
        -- Text Info
        mon.setTextColor(colors.white)
        mon.setCursorPos(2, 4)
        mon.write("Fluid:  " .. fluidName)
        mon.setCursorPos(2, 5)
        mon.write("Amount: " .. currentAmount .. " / " .. MAX_CAPACITY .. " mB")
        
        -- The Graphical Bar
        -- Parameters: x, y, width, percentage
        drawProgressBar(2, 7, 25, percent)
        
        -- Percentage Label
        mon.setCursorPos(2, 8)
        mon.setTextColor(percent < 15 and colors.red or colors.green)
        mon.write(string.format("%.1f%% Full", percent))
        
        lastAmount = currentAmount
    end

    sleep(1)
end