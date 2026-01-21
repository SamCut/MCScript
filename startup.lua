-- 1. Correct Library Path (Matches your working Scatman script)
local dfpwm = require("cc.audio.dfpwm")

-- 2. Correct Peripheral Names (Matched to your specific 'Found these' list)
local speaker = peripheral.find("speaker")
local detector = peripheral.find("player_detector") -- FIXED: Added underscore

-- Configuration
local audioFile = "/disk/AMERICA.dfpwm"
local detectionRange = 10
local cooldownSeconds = 135 -- 2 minutes, 15 seconds

-- Safety check
if not speaker or not detector then
    error("Peripheral Error! Make sure the Speaker and Player Detector are attached.")
end

local function playSong(triggerSource)
    local decoder = dfpwm.make_decoder()
    local file = io.open(audioFile, "rb")
    
    if not file then 
        print("Error: Could not find " .. audioFile)
        return 
    end

    term.clear()
    term.setCursorPos(1,1)
    print("--- PATRIOTIC DEFENSE SYSTEM ---")
    print("Detected: " .. triggerSource)
    print("Playing: AMERICA.dfpwm")
    print("Cooldown active: 2:15")

    -- Your working 8kb chunk logic
    while true do
        local chunk = file:read(8 * 1024) 
        if not chunk then break end
        
        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    
    file:close()
    
    -- Wait for the 2:15 cooldown to ensure no overlap
    sleep(cooldownSeconds)
    
    term.clear()
    term.setCursorPos(1,1)
    print("System Ready. Waiting for players or redstone...")
end

-- Main Loop
term.clear()
term.setCursorPos(1,1)
print("System Online. Monitoring triggers...")

while true do
    local triggerFound = false
    local sourceName = ""

    -- 1. Check Player Detector
    -- Using 'getPlayersInRange' which returns a list of players
    local players = detector.getPlayersInRange(detectionRange)
    if #players > 0 then
        sourceName = players[1] -- Use the first player's name
        triggerFound = true
    
    -- 2. Check Redstone at the back
    elseif rs.getInput("back") then
        sourceName = "Redstone Signal"
        triggerFound = true
    end

    if triggerFound then
        playSong(sourceName)
    end

    sleep(0.5) -- Safety sleep
end