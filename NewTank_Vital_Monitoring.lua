-- Configuration
local peripheralName = "dynamicValve_1"
local refreshRate = 2 -- Seconds between updates

-- Wrap the tank peripheral
local tank = peripheral.wrap(peripheralName)

-- Check if the tank was found
if not tank then
    error("Could not find tank: " .. peripheralName)
end

-- Function to format large numbers (e.g. 1000 -> 1,000)
local function formatNumber(amount)
    local formatted = tostring(amount)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then break end
    end
    return formatted
end

-- Main Loop
while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("=== Dynamic Tank Monitor ===")
    
    -- Attempt to pull tank data
    -- standard CC:Tweaked generic fluid method
    local tanksData = tank.getTanks() 

    if tanksData and tanksData[1] then
        local info = tanksData[1]
        local fluidName = info.name:gsub("minecraft:", ""):gsub("mekanism:", "")
        local amount = info.amount
        local capacity = info.capacity
        
        -- Calculate percentage
        local percentage = 0
        if capacity > 0 then
            percentage = math.floor((amount / capacity) * 100)
        end

        print("")
        print("Fluid: " .. fluidName:upper())
        print("----------------------------")
        print("Stored: " .. formatNumber(amount) .. " mB")
        print("Max:    " .. formatNumber(capacity) .. " mB")
        print("----------------------------")
        print("Status: " .. percentage .. "% Full")
        
        -- Draw a simple text-based progress bar
        local barLength = 20
        local filledLength = math.floor((percentage / 100) * barLength)
        local bar = "[" .. string.rep("#", filledLength) .. string.rep("-", barLength - filledLength) .. "]"
        print("")
        print(bar)

    else
        -- If the table is empty, the tank usually has no fluid
        print("")
        print("Status: Empty / No Fluid")
        print("----------------------------")
        print("0 mB Stored")
    end

    sleep(refreshRate)
end