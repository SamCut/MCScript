local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

if not speaker then
    error("No speaker found! Attach a speaker to the computer.")
end

local function playAudio()
    local decoder = dfpwm.make_decoder()
    -- Open the file in binary mode
    local file = io.open("scatman.dfpwm", "rb")
    if not file then
        print("Error: scatman.dfpwm not found!")
        return
    end

    print("Playing: Scatman John - 1:18 Drop")
    
    -- Read the file in chunks and stream to the speaker
    while true do
        local chunk = file:read(16 * 1024) -- Read 16kb at a time
        if not chunk then break end
        
        local buffer = decoder(chunk)
        -- This 'while' loop waits if the speaker's internal buffer is full
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    
    file:close()
    print("Done. Waiting for next button press...")
end

-- Main Loop
print("--- SCATMAN DOORBELL SYSTEM ---")
print("Waiting for redstone signal on the BACK...")

while true do
    os.pullEvent("redstone")
    if rs.getInput("back") then
        playAudio()
        sleep(1) -- Prevent double-triggering
    end
end