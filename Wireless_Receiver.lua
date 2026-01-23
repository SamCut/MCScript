rednet.open("top")
local wireSide = "front" -- The side where the multi-colored cable is
local password = "apple"

-- Initial state: both lamps off
local status = {
    red = false,
    blue = false
}

print("Listening for 'red' or 'blue'...")

while true do
    local id, msg = rednet.receive()
    local pass, cmd = msg:match("([^:]+):(.+)")

    if pass == password then
        cmd = cmd:lower()

        if status[cmd] ~= nil then
            -- Toggle the current state (true becomes false, vice versa)
            status[cmd] = not status[cmd]
            
            -- Calculate the combined output
            local output = 0
            if status.red then output = colors.combine(output, colors.red) end
            if status.blue then output = colors.combine(output, colors.blue) end
            
            -- Send the signal to the Bundled Cable
            rs.setBundledOutput(wireSide, output)
            
            print("Command Received: " .. cmd)
            print("Status - Red: " .. tostring(status.red) .. " | Blue: " .. tostring(status.blue))
        else
            print("Unknown command from ID " .. id .. ": " .. cmd)
        end
    end
end