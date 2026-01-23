-- Find any peripheral that can store fluid
local tank = peripheral.find("fluid_storage")

if not tank then
    print("No tank found! Check your connections.")
    return
end

local info = tank.tanks()[1]

if info then
    print("Fluid: " .. (info.name or "Unknown"))
    print("Amount: " .. (info.amount or 0) .. " mB")
    
    -- Check if capacity exists before trying to print it
    if info.capacity then
        print("Capacity: " .. info.capacity .. " mB")
        local percent = (info.amount / info.capacity) * 100
        print(string.format("Fill: %.1f%%", percent))
    else
        print("Capacity: Data not provided by tank")
    end
else
    print("Tank is empty.")
end