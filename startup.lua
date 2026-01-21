local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local detector = peripheral.find("player_detector")

-- Use your specific file
local audioFile = "/disk/AMERICA.dfpwm"

local function playAmerica()
    local decoder = dfpwm.make_decoder()
    local file = io.open(audioFile, "rb")
    
    if not file then return print("File not found") end

    term.clear()
    term.setCursorPos(1,1)
    print("OIL WELL AUDIO: PLAYING")

    -- Exact audio loop from your working Scatman script
    while true do
        local chunk = file:read(8 * 1024)
        if not chunk then break end
        
        local buffer = decoder(chunk)
        
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    file:close()
end

-- Main Loop matching your Scatman structure
while true do
    term.clear()
    term.setCursorPos(1,1)
    print("OIL WELL SYSTEM ONLINE")
    print("Waiting for trigger...")

    -- Wait for a signal change
    os.pullEvent("redstone")
    
    local triggered = false

    -- Check Redstone first (matching your working script)
    if rs.getInput("back") then
        triggered = true
    -- Check Detector as a backup
    elseif detector then
        local players = detector.getPlayersInRange(10)
        if #players > 0 then
            triggered = true
        end
    end

    if triggered then
        playAmerica()
    end
end