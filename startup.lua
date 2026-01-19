local speaker = peripheral.find("speaker")
if not speaker then error("No speaker found!") end

-- 'pling' is perfect for that 90s synth-pop sound
local inst = "pling" 
local vol = 1.0

-- Melody: {pitch, delay}
-- 15=G, 18=Bb, 20=C, 13=F, 10=D
local scatman = {
    {15, 0.1}, {18, 0.1}, {15, 0.1}, {18, 0.1}, {20, 0.1}, {18, 0.1}, {15, 0.1}, {13, 0.1},
    {15, 0.4}, -- Pause/Hold
    {15, 0.1}, {18, 0.1}, {15, 0.1}, {18, 0.1}, {20, 0.1}, {18, 0.1}, {15, 0.1}, {13, 0.1},
    {10, 0.4}, -- Lower note
    -- The fast scat part
    {15, 0.05}, {15, 0.05}, {18, 0.05}, {15, 0.05}, {20, 0.1}, {15, 0.1}, {13, 0.2}
}

print("Scatman Doorbell Active!")

while true do
    os.pullEvent("redstone")
    if rs.getInput("back") then -- Change to your button's side
        print("I'm the Scatman!")
        for _, n in ipairs(scatman) do
            if n[1] > 0 then speaker.playNote(inst, vol, n[1]) end
            sleep(n[2])
        end
        sleep(2) -- Prevent spam
    end
end