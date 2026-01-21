local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

local audioFile = "/AMERICA.dfpwm"

local function playScatman()
    local decoder = dfpwm.make_decoder()
    -- Open file with 'rb' (read binary)
    local file = io.open(audioFile, "rb")
    
    if not file then return print("File not found") end

    -- Using a smaller 8kb chunk instead of 16kb can stop screeching
    while true do
        local chunk = file:read(8 * 1024) 
        if not chunk then break end
        
        local buffer = decoder(chunk)
        
        -- This ensures the speaker is actually ready before pushing more data
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    file:close()
end

while true do
    os.pullEvent("redstone")
    if rs.getInput("back") then
        playScatman()
    end
end