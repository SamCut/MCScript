-- Configuration
local songFile = "AMERICA.dfpwm"
local cooldownTime = 135 -- 2 minutes 15 seconds in seconds
local side = "back" -- Redstone input side

-- Initialize variables
local cooldownEnd = 0
local speaker = peripheral.find("speaker")
local playerDetector = peripheral.find("playerDetector")

-- Function to play the dfpwm file
local function playSong()
    if not speaker then
        print("No speaker found!")
        return false
    end
    
    if not fs.exists(songFile) then
        print("Song file not found: " .. songFile)
        return false
    end
    
    local file = fs.open(songFile, "rb")
    local dfpwm = require("dfpwm")
    local decoder = dfpwm.make_decoder()
    
    while true do
        local chunk = file.read(16 * 1024)
        if not chunk then break end
        
        local buffer = decoder(chunk)
        
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    
    file.close()
    return true
end

-- Main program loop
while true do
    local currentTime = os.time()
    
    -- Check if redstone signal is received and cooldown is over
    if rs.getInput(side) and currentTime >= cooldownEnd then
        -- Detect players
        local players = {}
        if playerDetector then
            players = playerDetector.getPlayersInRange()
        end
        
        -- Clear screen and print player info
        term.clear()
        term.setCursorPos(1, 1)
        
        if #players > 0 then
            print("Player detected: " .. table.concat(players, ", "))
        else
            print("Redstone signal detected!")
        end
        
        print("Now playing: " .. songFile)
        
        -- Set cooldown end time
        cooldownEnd = currentTime + cooldownTime
        
        -- Play the song in the background
        parallel.waitForAll(
            function()
                playSong()
            end,
            function()
                -- Show cooldown progress
                while currentTime < cooldownEnd do
                    local remaining = cooldownEnd - currentTime
                    local minutes = math.floor(remaining / 60)
                    local seconds = remaining % 60
                    term.setCursorPos(1, 4)
                    term.clearLine()
                    print(string.format("Cooldown: %d:%02d", minutes, seconds))
                    sleep(1)
                    currentTime = os.time()
                end
                
                term.setCursorPos(1, 4)
                term.clearLine()
                print("Ready for next play")
            end
        )
    end
    
    sleep(0.5) -- Check redstone state every 0.5 seconds
end