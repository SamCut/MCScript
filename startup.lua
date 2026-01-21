local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local detector = peripheral.find("player_detector")

-- Configuration
local audioFile = "/disk/AMERICA.dfpwm"
if not fs.exists(audioFile) then audioFile = "/AMERICA.dfpwm" end

local cooldownSeconds = 135 -- 2 minutes and 15 seconds
local lastStartTime = 0

-- Audio Function (Matches your working PlayAudio.lua exactly)
local function playSong()
    local decoder = dfpwm.make_decoder()
    local file = io.open(audioFile, "rb")
    
    if not file then 
        print("File not found: " .. audioFile)
        return 
    end

    lastStartTime = os.epoch("utc") / 1000 -- Record the start time NOW
    
    term.clear()
    term.setCursorPos(1,1)
    print("OIL WELL AUDIO: PLAYING")

    -- Your working chunk logic
    while true do
        local chunk = file:read(8 * 1024)
        if not chunk then break end
        
        local buffer = decoder(chunk)
        
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    
    file:close()
    
    -- Calculate remaining cooldown
    local now = os.epoch("utc") / 1000
    local elapsed = now - lastStartTime
    local remaining = cooldownSeconds - elapsed
    
    if remaining > 0 then
        print("Waiting for cooldown: " .. math.floor(remaining) .. "s")
        sleep(remaining)
    end
end

-- Main Loop
term.clear()
term.setCursorPos(1,1)
print("OIL WELL SYSTEM ONLINE")

while true do
    local triggered = false

    -- Trigger 1: Redstone
    if rs.getInput("back") then
        triggered = true
    end

    -- Trigger 2: Player Detector (Optional)
    if not triggered and detector then
        local players = detector.getPlayersInRange(10)
        if #players > 0 then
            triggered = true
        end
    end

    if triggered then
        -- Only play if the cooldown has passed
        local now = os.epoch("utc") / 1000
        if (now - lastStartTime) >= cooldownSeconds then
            playSong()
        end
    end

    sleep(0.5) -- Short wait to prevent lag
end