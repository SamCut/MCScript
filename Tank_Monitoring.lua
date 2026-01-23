-- Wrap the tank peripheral
local tank = peripheral.find("evilcraft:dark_tank")

if tank then
    local info = tank.tanks()[1] -- Dark Tanks usually have 1 internal tank
    if info then
        print("Fluid: " .. info.name)
        print("Amount: " .. info.amount .. " mB")
        print("Capacity: " .. info.capacity .. " mB")
        
        local percentage = (info.amount / info.capacity) * 100
        print(string.format("Fill Level: %.2f%%", percentage))
    else
        print("Tank is empty.")
    end
else
    print("Dark Tank not found! Check your connections.")
end