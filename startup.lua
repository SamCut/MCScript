-- 1. Corrected library path for CraftOS 1.9
local dfpwm = require("cc.audio.dfpwm")

-- 2. Find peripherals automatically
local speaker = peripheral.find("speaker")
local detector = peripheral.find("playerDetector")

-- Configuration
local audioFile = "/disk/AMERICA.dfpwm" -- Path for file on the disk
local detectionRange = 10
local cooldownSeconds = 135 -- 2 minutes and 15 seconds

-- Safety checks with helpful messages
if not speaker then error("No Speaker found! Check the top of the PC.") end
if not detector then error("No Player Detector found! Check the right side.") end
if not fs.exists(audioFile) then error("AMERICA.dfpwm not found on disk!") end

local function playSong(triggerSource)
    local decoder = dfpwm.make_decoder()
    local file = io.open(audioFile, "rb")
    
    term.clear()
    term.setCursorPos(1,1)
    print("--- Security System ---")
    print("Triggered by: " .. triggerSource)
    print("Playing: AMERICA.dfpwm")
    print("Cooldown: 2:15 active...")

    -- Use your 8kb chunk logic for stability
    while true do
        local chunk = file:read(8 * 1024) 
        if not chunk then break end
        
        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    
    file:close()
    
    -- Wait the remainder of the cooldown
    sleep(cooldownSeconds)
    
    term.clear()
    term.setCursorPos(1,1)
    print("System Online. Waiting for players or redstone...")
end

-- Main Loop
term.clear()
term.setCursorPos(1,1)
print("System Online. Monitoring triggers...")

while true do
    local triggerFound = false
    local sourceName = ""

    -- Check Player Detector
    if detector.isPlayerInRange(detectionRange) then
        local players = detector.getPlayersInRange(detectionRange)
        if #players > 0 then
            sourceName = players[1].name or players[1]
            triggerFound = true
        end
    
    -- Check Redstone at the back
    elseif rs.getInput("back") then
        sourceName = "Redstone (Back)"
        triggerFound = true
    end

    if triggerFound then
        playSong(sourceName)
    end

    sleep(0.5) -- Prevents "Too long without yielding" error
end