-- Configuration
local tankName = "dynamicValve_1"
local refreshRate = 2 -- Time in seconds between updates

-- Try to connect to the tank
local tank = peripheral.wrap(tankName)

-- Automatic Monitor Detection
-- This looks for any monitor connected to the network or computer
local mon = peripheral.find("monitor")

-- If a monitor is found, set it up
if mon then
    mon.setTextScale(1) -- Adjust this (0.5 to 5) to change text size
    term.redirect(mon)  -- Redirect all output to the monitor
    print("Monitor connected.")
else
    print("No monitor found. Using terminal.")
end

-- Helper function to format numbers (adds commas: 10000 -> 10,000)
local function formatNumber(n)
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):gsub(",(%-?)$", "%1"):reverse()
end

-- Helper function to draw a progress bar
local function drawBar(percent)
    local width, height = term.getSize()
    local barWidth = width - 4 -- Leave some padding
    local filled = math.floor((percent / 100) * barWidth)
    
    -- Set colors if the display supports it
    if term.isColor() then
        term.setBackgroundColor(colors.gray)
        term.write(string.rep(" ", barWidth)) -- Empty bar background
        term.setCursorPos(3, 5) -- Reset to start of bar
        term.setBackgroundColor(colors.blue)
        term.write(string.rep(" ", filled)) -- Filled portion
        term.setBackgroundColor(colors.black) -- Reset background
    else
        -- Black and white fallback
        term.write("[" .. string.rep("#", filled) .. string.rep("-", barWidth - filled) .. "]")
    end
end

-- Main Program Loop
while true do
    -- clear the screen
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    
    if not tank then
        print("Error: Tank '"..tankName.."' not found!")
        print("Check your modem connection.")
    else
        -- COMPATIBILITY FIX: Handle different Mekanism versions
        local amount = 0
        local capacity = 0
        local name = "Empty"
        local hasData = false

        -- Try Modern Method (1.16+)
        if tank.getTanks then
            local data = tank.getTanks()
            if data and data[1] then
                amount = data[1].amount
                capacity = data[1].capacity
                name = data[1].name
                hasData = true
            end
        -- Try Legacy Method (1.12.2 and older)
        elseif tank.getStored and tank.getCapacity then
            amount = tank.getStored()
            capacity = tank.getCapacity()
            hasData = true
            name = "Fluid" -- Default if we can't find a name
            
            -- Try to find the name using getTankInfo (Legacy)
            if tank.getTankInfo then
                local info = tank.getTankInfo()
                if info and info[1] then
                    name = info[1].name
                end
            end
        end
        
        if hasData then
            name = name:gsub("minecraft:", ""):gsub("mekanism:", "")
            local percentage = 0
            
            if capacity > 0 then
                percentage = (amount / capacity) * 100
            end

            -- Display Info
            if term.isColor() then term.setTextColor(colors.yellow) end
            print("Dynamic Tank Monitor")
            if term.isColor() then term.setTextColor(colors.white) end
            print("--------------------")
            
            print("Fluid: " .. name:upper())
            print("Stored: " .. formatNumber(amount) .. " mB")
            print("Max:    " .. formatNumber(capacity) .. " mB")
            
            -- Move cursor for the bar
            term.setCursorPos(3, 7)
            if term.isColor() then term.setTextColor(colors.lime) end
            print(math.floor(percentage) .. "% Full")
            
            term.setCursorPos(3, 5)
            drawBar(percentage)
            
        else
            print("Status: Tank is Empty")
            print("--------------------")
            print("0 / 0 mB")
        end
    end
    
    sleep(refreshRate)
end