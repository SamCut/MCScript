local dfpwm = require("cc.audio.dfpwm")

-- Wrap peripheral.find in {} to catch ALL attached speakers into a table
local speakers = { peripheral.find("speaker") }

local audioFile = "/higher.dfpwm"

-- Quick check to ensure speakers exist
if #speakers == 0 then
    print("No speakers found attached!")
    return
end

local function playMusic()
    local decoder = dfpwm.make_decoder()
    local file = io.open(audioFile, "rb")
    
    if not file then return print("File not found") end

    while true do
        local chunk = file:read(8 * 1024) 
        if not chunk then break end
        
        local buffer = decoder(chunk)
        
        -- SYNC LOGIC:
        -- We must ensure every single speaker accepts this chunk before moving to the next.
        -- We track which speakers have finished for this specific chunk.
        local chunk_accepted = {} 
        local count_accepted = 0

        -- Keep trying until all speakers have accepted the buffer
        while count_accepted < #speakers do
            for i, speaker in ipairs(speakers) do
                -- If this speaker hasn't accepted the chunk yet, try to play
                if not chunk_accepted[i] then
                    -- playAudio returns true if successful, false if buffer is full
                    if speaker.playAudio(buffer, 3.0) then
                        chunk_accepted[i] = true
                        count_accepted = count_accepted + 1
                    end
                end
            end

            -- If we are still waiting on some speakers, wait for an event before looping again
            if count_accepted < #speakers then
                os.pullEvent("speaker_audio_empty")
            end
        end
    end
    file:close()
end

while true do
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.white)
    write("***CREED AUDIO ONLINE***")
    
    -- Display how many speakers are connected
    term.setCursorPos(1,3)
    term.setTextColor(colors.gray)
    write("Speakers connected: " .. #speakers)

    os.pullEvent("redstone")
    if rs.getInput("back") then
        term.setCursorPos(1,2)
        term.setTextColor(colors.red)
        write("take me higher")
        playMusic()
    end
end