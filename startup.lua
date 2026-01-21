local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local detector = peripheral.find("playerDetector")

-- Configuration
local audioFile = "/AMERICA.dfpwm"
local detectionRange = 10
local cooldownSeconds = 135 -- 2 minutes and 15 seconds

-- Safety checks
if not speaker then error("No speaker found!") end
if not detector then error("No player detector found!") end
if not fs.exists(audioFile) then error("File " .. audioFile .. " not found!") end

local function playAmerica(triggerSource)
    local decoder = dfpwm.make_decoder()
    local file = io.open(audioFile, "rb")
    
    -- Clear and print status
    term.clear()
    term.setCursorPos(1,1)
    print("--- Security System ---")
    print("Trigger: " .. triggerSource)
    print("Status: Playing AMERICA.dfpwm")
    print("Cooldown: 2:15 active")

    -- Audio playback loop (8kb chunks for stability)
    while true do
        local chunk = file:read(8 * 1024) 
        if not chunk then break end
        
        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    
    file:close()
    
    -- Wait for the remainder of the cooldown after the song finishes
    -- Note: The song itself takes time to play, so we sleep for the 
    -- cooldown period to ensure no overlap.
    sleep(cooldownSeconds)
    
    term.clear()
    term.setCursorPos(1,1)
    print("System Online. Waiting for triggers...")
end

-- Main Monitoring Loop
term.clear()
term.setCursorPos(1,1)
print("System Online. Waiting for triggers...")

while true do
    local triggered = false
    local name = ""

    -- 1. Check Player Detector
    if detector.isPlayerInRange(detectionRange) then
        local players = detector.getPlayersInRange(detectionRange)
        if #players > 0 then
            -- Get the name of the first player found
            name = players[1].name or players[1]
            triggered = true
        end
    
    -- 2. Check Redstone at the back
    elseif rs.getInput("back") then
        name = "Redstone Signal (Back)"
        triggered = true
    end

    -- If either triggered, play the song
    if triggered then
        playAmerica(name)
    end

    -- Small sleep to prevent computer from crashing (yield error)
    sleep(0.5)
end