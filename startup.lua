local speaker = peripheral.find("speaker")
if not speaker then error("No speaker found!") end

local inst = "bit" -- Cleaner synth sound to prevent overlapping muddy tones
local vol = 1.0

-- Pitch Reference: 5=F, 8=Ab, 10=Bb, 12=C, 15=Eb, 17=F(high), 20=Ab(high)
local melody = {
    -- "Ski-ba-bop-ba-dop-bop"
    {17, 0.15}, {17, 0.1}, {15, 0.1}, {17, 0.1},  -- Ski-ba-bop-ba
    {20, 0.15}, {17, 0.15},                       -- dop-bop
    
    {0, 0.2}, -- The "breath" before the big scat
    
    -- "Ba-da-ba-da-ba-BEE bop bop"
    {17, 0.1}, {15, 0.1}, {17, 0.1}, {15, 0.1}, {17, 0.1}, -- Ba-da-ba-da-ba
    {22, 0.2},                                             -- BEE (The high note!)
    {17, 0.15}, {15, 0.15}, {12, 0.3},                     -- bop bop bope
}

local function playScatman()
    for _, note in ipairs(melody) do
        local pitch = note[1]
        local delay = note[2]
        
        if pitch > 0 then
            speaker.playNote(inst, vol, pitch)
        end
        -- Using 0.1 as a minimum prevents the "rushed/overlapping" feel
        sleep(delay)
    end
end

print("Scatman Doorbell v3: Focused on the 'BEE'")
while true do
    os.pullEvent("redstone")
    if rs.getInput("back") then
        playScatman()
        sleep(2) -- Cooldown
    end
end