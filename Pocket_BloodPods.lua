rednet.open("back") -- Pocket computers usually have modems on the back
local hostID = 12 -- CHANGE THIS to the ID of your Pod Computer
local password = "apple"

print("Blood Pod Remote")
print("1. Enable Pods")
print("2. Purge Pods")

while true do
    write("Command: ")
    local input = read()
    local cmd = ""

    if input == "1" or input == "enable" then
        cmd = "enable"
    elseif input == "2" or input == "purge" then
        cmd = "purge"
    else
        print("Invalid option.")
    end

    if cmd ~= "" then
        print("Sending signal...")
        -- Sends "apple:enable" or "apple:purge"
        rednet.send(hostID, password .. ":" .. cmd)
        
        -- Wait for confirmation from the main computer
        local senderId, reply = rednet.receive(2)
        if reply then
            print("Server: " .. reply)
        else
            print("No response from server.")
        end
    end
end