-- Hardware Configuration
rednet.open("top")
local wireSide = "front" -- Side with the bundled cable
local controlColor = colors.red -- The color channel connected to the Blood Pods
local password = "apple"

-- Initial State: 0 means no signal (Purged/Off)
rs.setBundledOutput(wireSide, 0) 

print("Blood Pod Control System Online")
print("Listening for 'enable' or 'purge'...")

while true do
    local id, msg = rednet.receive()
    
    -- Ensure message is a string before processing
    if type(msg) == "string" then
        local pass, cmd = msg:match("([^:]+):(.+)")

        if pass == password then
            cmd = cmd:lower()

            if cmd == "enable" or cmd == "start" then
                -- Turn the signal ON
                rs.setBundledOutput(wireSide, controlColor)
                print("[ID: " .. id .. "] STATUS: Pods ENABLED")
                rednet.send(id, "Pods Enabled") -- Confirm to sender

            elseif cmd == "purge" or cmd == "disable" or cmd == "stop" then
                -- Turn the signal OFF (Output 0)
                rs.setBundledOutput(wireSide, 0)
                print("[ID: " .. id .. "] STATUS: Pods PURGED")
                rednet.send(id, "Pods Purged") -- Confirm to sender

            else
                print("[ID: " .. id .. "] Unknown command: " .. cmd)
                rednet.send(id, "Unknown Command")
            end
        else
             print("Authentication failed from ID: " .. id)
        end
    end
end