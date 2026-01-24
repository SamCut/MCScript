-- Hardware Configuration
rednet.open("top") -- Ensure your Wireless Modem is on the top
local wireSide = "back" -- CHANGED: Now outputs to the back where your cable is
local controlColor = colors.red -- This activates the Red wire in the bundle
local password = "apple"

-- Initial State: 0 means no signal (Purged/Off)
rs.setBundledOutput(wireSide, 0) 

print("Blood Pod Control System Online")
print("Output Side: " .. wireSide)
print("Listening for commands...")

while true do
    local id, msg = rednet.receive()
    
    if type(msg) == "string" then
        local pass, cmd = msg:match("([^:]+):(.+)")

        if pass == password then
            cmd = cmd:lower()

            if cmd == "enable" or cmd == "start" then
                -- Turn the Red signal ON
                rs.setBundledOutput(wireSide, controlColor)
                print("[ID: " .. id .. "] STATUS: Pods ENABLED")
                rednet.send(id, "Pods Enabled")

            elseif cmd == "purge" or cmd == "disable" or cmd == "stop" then
                -- Turn the signal OFF
                rs.setBundledOutput(wireSide, 0)
                print("[ID: " .. id .. "] STATUS: Pods PURGED")
                rednet.send(id, "Pods Purged")

            else
                print("[ID: " .. id .. "] Unknown command: " .. cmd)
                rednet.send(id, "Unknown Command")
            end
        end
    end
end