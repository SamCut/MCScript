local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

local audioFile = "/AMERICA.dfpwm"

local function playMusic()
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
        while not speaker.playAudio(buffer, 3.0) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    file:close()
end

while true do
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.red)
    write("PATRIOT")
    term.setTextColor(colors.white)
    write("AUDIO")
    term.setTextColor(colors.blue)
    print("ONLINE")
    os.pullEvent("redstone")
    if rs.getInput("back") then
        term.clear()
        term.setCursorPos(1,2)
        term.setTextColor(colors.red)
        write("AME")
        term.setTextColor(colors.white)
        write("RI")
        term.setTextColor(colors.blue)
        print("CA")
        playMusic()
    end
end