local speaker = peripheral.find("speaker")
if not speaker then error("No speaker found!") end

local inst = "bit"

-- Axel F / Crazy Frog Melody
local melody = {
    {10, 0.4}, {13, 0.2}, {10, 0.2}, {10, 0.2}, {15, 0.2}, {10, 0.2}, {8, 0.4},
    {0, 0.4},
    {10, 0.4}, {17, 0.2}, {10, 0.2}, {10, 0.2}, {18, 0.2}, {17, 0.2}, {13, 0.4},
    {0, 0.4},
    -- Part 3: The fast finish
    {10, 0.2}, {17, 0.2}, {22, 0.2}, {10, 0.2}, {8, 0.2}, {8, 0.2}, {5, 0.2}, {12, 0.2}, {10, 0.6}
}

print("Crazy Frog Doorbell Ready!")

while true do
    os.pullEvent("redstone")
    if rs.getInput("back") then -- Adjust side as needed
        for _, n in ipairs(melody) do
            if n[1] > 0 then speaker.playNote(inst, 1.0, n[1]) end
            sleep(n[2])
        end
        sleep(2) -- Spams protection
    end
end