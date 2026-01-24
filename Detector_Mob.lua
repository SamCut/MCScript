-- This finds the reader over the network
local reader = peripheral.find("block_reader")

while true do
    term.clear()
    term.setCursorPos(1,1)
    
    local data = reader.getBlockData()
    
    if data then
        -- This line prints the block name it's currently looking at
        print("Looking at: " .. (data.name or "Unknown"))
        
        local info = textutils.serialize(data):lower()
        
        -- If it sees the villager standing in that block, it triggers
        if info:find("villager") then
            print("VILLAGER: [ FOUND ]")
        else
            print("VILLAGER: [ NOT SEEN ]")
        end
    else
        print("ERROR: Reader is not facing a valid block.")
    end
    
    sleep(1)
end