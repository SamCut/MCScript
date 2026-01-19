local speaker = peripheral.find("speaker")
if not speaker then error("No speaker found!") end

local synth = "bit"      -- The "Scat" voice
local kick = "bassdrum"  -- The 1:18 beat
local vol = 1.0

-- Melody: {Pitch, Delay, PlayKick?}
-- F=17, Eb=15, Ab=20, Bb=22(BEE!)
local beatDrop = {
    -- The "I'm the Scatman" buildup
    {10, 0.2, true}, {12, 0.2, false}, {15, 0.2, true}, {17, 0.4, false},
    
    -- The 1:18 Rapid Scat (Ba-da-ba-da-ba-da-ba-da)
    {17, 0.1, true}, {17, 0.1, false}, {17, 0.1, true}, {17, 0.1, false},
    {17, 0.1, true}, {17, 0.1, false}, {17, 0.1, true}, {17, 0.1, false},
    
    -- THE CLIMAX (1:21) - "Bop-ba-da-BEE!"
    {15, 0.1, true},  -- Ba
    {17, 0.1, false}, -- da
    {20, 0.1, true},  -- ba
    {22, 0.3, false}, -- BEE! (High Bb)
    
    -- Resolution
    {17, 0.1, true}, {15, 0.1, false}, {12, 0.4, true}
}

local function playBeat()
    print("Ski-ba-bop-ba-dop-bop!")
    for _, n in ipairs(beatDrop) do
        local pitch, delay, hitKick = n[1], n[2], n[3]
        
        -- Play the Synth
        speaker.playNote(synth, vol, pitch)
        
        -- Layer the Kick Drum if marked true
        if hitKick then
            speaker.playNote(kick, vol, 1) -- Pitch 1 is a deep thud
        end
        
        sleep(delay)
    end
end

print("Scatman 1:18 'The Beat Drop' Version")
print("Waiting for button on BACK...")

while true do
    os.pullEvent("redstone")
    if rs.getInput("back") then
        playBeat()
        sleep(1.5) -- Cool down
    end
end