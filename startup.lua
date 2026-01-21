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

while true do
    os.pullEvent("redstone")
    if rs.getInput("back") then
        playAmerica()
    end
end