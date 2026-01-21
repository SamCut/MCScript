-- 1. Correct Library Path
local dfpwm = require("cc.audio.dfpwm")

-- 2. Find Peripherals
local speaker = peripheral.find("speaker")
local detector = peripheral.find("playerDetector")

-- Configuration
local audioFile = "/disk/AMERICA.dfpwm"
local detectionRange = 10
local cooldownSeconds = 135 -- 2 minutes, 15 seconds

-- Helper: List all connected peripherals if one is missing
if not speaker or not detector then
    print("Error: Missing Peripherals!")
    print("Found these instead:")
    for _, name in ipairs(peripheral.getNames()) do
        print("- " .. name .. " (" .. peripheral.getType(name) .. ")")
    end
    error("Check the list above and update peripheral names.")
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

    -- 8kb chunks for stability (your working logic)
    while true do
        local chunk = file:read(8 * 1024) 
        if not chunk then break end
        
        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    
    file:close()
    
    -- Wait for the song to finish and the cooldown to pass
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

    -- Check Player Detector
    if detector.isPlayerInRange(detectionRange) then
        local players = detector.getPlayersInRange(detectionRange)
        if #players > 0 then
            -- Handle different mod versions (names vs objects)
            sourceName = type(players[1]) == "table" and players[1].name or players[1]
            triggerFound = true
        end
    
    -- Check Redstone at the back
    elseif rs.getInput("back") then
        sourceName = "Redstone Signal (Back)"
        triggerFound = true
    end

    if triggerFound then
        playSong(sourceName)
    end

    sleep(0.5) -- Prevents "Too long without yielding" error
end