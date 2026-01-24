rednet.open("back") -- Modem is usually on the back of pocket computers
local hostID = 12 -- REMEMBER: Change this to your main computer's ID!
local password = "apple"

while true do
    term.clear()
    term.setCursorPos(1,1)
    print("--- Blood Pod Remote ---")
    print("1. Enable Pods")
    print("2. Purge Pods")
    print("3. Exit Remote")
    print("----------------------")
    
    write("Select option: ")
    local input = read()
    local cmd = ""

    if input == "1" or input == "enable" then
        cmd = "enable"
    elseif input == "2" or input == "purge" then
        cmd = "purge"
    elseif input == "3" or input == "exit" then
        print("Exiting...")
        sleep(0.5)
        break -- Breaks the loop and ends the program
    else
        print("Invalid option.")
        sleep(1)
    end

    -- If a command was set (and we aren't exiting), send it
    if cmd ~= "" then
        print("Sending signal...")
        rednet.send(hostID, password .. ":" .. cmd)
        
        -- Wait for confirmation
        local senderId, reply = rednet.receive(2)
        if reply then
            print("Server: " .. reply)
        else
            print("Error: No response from base.")
        end
        print("Press Enter to continue...")
        read()
    end
end