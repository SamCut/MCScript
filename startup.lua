local speaker = peripheral.find("speaker")
if not speaker then error("No speaker found!") end

-- 'pling' captures the 90s House Piano/Synth vibe
local inst = "pling"
local vol = 1.0

-- Key Pitches (F Minor scale for Note Blocks):
-- F=5, Ab=8, Bb=10, C=12, Eb=15, F_high=17
local chorus = {
    -- "Ski-ba-bop-ba-dop-bop"
    {17, 0.05}, {17, 0.05}, {15, 0.05}, {17, 0.1},  -- Ski-ba-bop-ba
    {20, 0.05}, {17, 0.05}, {15, 0.05}, {12, 0.1},  -- dop-bop-bop-da
    {15, 0.1},  {17, 0.2},                          -- Bop!
    
    {0, 0.2}, -- Short breath
    
    -- "Ba-da-ba-da-ba-be bop bop bodda bope"
    {17, 0.05}, {15, 0.05}, {17, 0.05}, {15, 0.05}, {17, 0.05}, 
    {12, 0.1}, {10, 0.1}, {12, 0.1}, {5, 0.4}
}

local function playScatman()
    for _, note in ipairs(chorus) do
        local pitch = note[1]
        local delay = note[2]
        if pitch > 0 then
            speaker.playNote(inst, vol, pitch)
        end
        -- Minecraft ticks are 0.05s, so we use that as our base
        sleep(delay)
    end
end

print("Scatman Doorbell v2: THE CHORUS")
print("Waiting for signal on BACK side...")

while true do
    os.pullEvent("redstone")
    if rs.getInput("back") then
        print("Bop-ba-dop-bop!")
        playScatman()
        sleep(1) -- Short cooldown
    end
end