-- Peripherals Setup
local speaker = peripheral.find("speaker")
local detector = peripheral.find("playerDetector")

-- Modern versions of CC use the 'cc.audio' prefix
local dfpwm = require("cc.audio.dfpwm")

-- Configuration
local fileName = "AMERICA.dfpwm"
local detectionRange = 10 
local cooldownSeconds = 135 

-- Safety checks
if not speaker then error("No speaker found!") end
if not detector then error("No player detector found!") end
if not fs.exists(fileName) then 
    -- If file is on the disk, we check /disk/AMERICA.dfpwm
    if fs.exists("/disk/"..fileName) then
        fileName = "/disk/"..fileName
    else
        error("File " .. fileName .. " not found! Ensure it's on the computer or disk.") 
    end
end

local decoder = dfpwm.make_decoder()

local function playSong()
    local file = io.open(fileName, "rb")
    term.clear()
    term.setCursorPos(1,1)
    
    -- Get player names
    local players = detector.getPlayersInRange(detectionRange)
    local playerName = "Someone"
    if #players > 0 then
        playerName = players[1].name or players[1]
    end

    print("--- Security System ---")
    print("Detected: " .. playerName)
    print("Status: Playing " .. fileName)
    print("Cooldown active: 2:15")

    -- Audio playback loop
    for chunk in file:lines(16 * 1024) do
        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    
    file:close()
end

-- Main Loop
term.clear()
term.setCursorPos(1,1)
print("System Online. Waiting for players...")

while true do
    if detector.isPlayerInRange(detectionRange) then
        playSong()
        sleep(cooldownSeconds)
        term.clear()
        term.setCursorPos(1,1)
        print("Cooldown finished. Waiting for players...")
    end
    sleep(1)
end