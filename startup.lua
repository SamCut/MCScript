local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
-- This will now be 'nil' instead of crashing if the block is missing
local detector = peripheral.find("player_detector") 

-- Configuration
local audioFile = "/disk/AMERICA.dfpwm"
if not fs.exists(audioFile) then audioFile = "/AMERICA.dfpwm" end

local detectionRange = 10
local cooldownSeconds = 135 -- 2 minutes and 15 seconds
local lastStartTime = 0

if not speaker then error("No speaker found! System cannot play audio.") end

local function playSong(triggerSource)
    local decoder = dfpwm.make_decoder()
    local file = io.open(audioFile, "rb")
    if not file then return print("Error: File not found!") end

    lastStartTime = os.epoch("utc") / 1000 -- Mark start time
    
    term.clear()
    term.setCursorPos(1,1)
    print("--- OIL WELL AUDIO SYSTEM ---")
    print("Trigger: " .. triggerSource)
    print("Status: PLAYING (Turn OFF redstone to Kill)")

    -- Audio chunk loop (8kb chunks)
    while true do
        -- KILL SWITCH: If redstone at the back goes OFF, stop immediately
        if not rs.getInput("back") then
            print("Redstone Cut: Stopping Audio.")
            break
        end

        local chunk = file:read(8 * 1024) --
        if not chunk then break end
        
        local buffer = decoder(chunk)
        
        -- Wait for speaker to be ready
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty") --
        end
    end
    
    file:close()
    
    -- Overlap Prevention: Calculate remaining time in the 2:15 window
    local currentTime = os.epoch("utc") / 1000
    local elapsed = currentTime - lastStartTime
    local remaining = cooldownSeconds - elapsed
    
    if remaining > 0 then
        print("Cooldown: " .. math.floor(remaining) .. "s remaining...")
        sleep(remaining)
    end
end

-- Main Monitoring Loop
term.clear()
term.setCursorPos(1,1)
print("OIL WELL SYSTEM ONLINE")
if detector then print("Detector: ACTIVE") else print("Detector: NOT FOUND (Redstone Only)") end

while true do
    local shouldPlay = false
    local reason = ""

    -- 1. Check Redstone (Back)
    if rs.getInput("back") then
        reason = "Redstone Input"
        shouldPlay = true
    end

    -- 2. Check Player Detector (Only if it exists)
    if not shouldPlay and detector then
        local players = detector.getPlayersInRange(detectionRange)
        if #players > 0 then
            reason = "Player Detected"
            shouldPlay = true
        end
    end

    -- 3. Check Cooldown before starting
    if shouldPlay then
        local now = os.epoch("utc") / 1000
        if (now - lastStartTime) >= cooldownSeconds then
            playSong(reason)
        end
    end

    sleep(1) -- Check once per second to stay efficient
end