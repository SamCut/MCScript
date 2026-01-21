-- Peripherals Setup
local speaker = peripheral.find("speaker")
local detector = peripheral.find("playerDetector")
local dfpwm = require("dfpwm")

-- Configuration
local fileName = "AMERICA.dfpwm"
local detectionRange = 10 -- Blocks
local cooldownSeconds = 135 -- 2 minutes and 15 seconds

if not speaker then error("No speaker found!") end
if not detector then error("No player detector found!") end
if not fs.exists(fileName) then error("File " .. fileName .. " not found!") end

local decoder = dfpwm.make_decoder()

local function playSong()
    local file = io.open(fileName, "rb")
    term.clear()
    term.setCursorPos(1,1)
    
    -- Get player names in range
    local players = detector.getPlayersInRange(detectionRange)
    local playerName = players[1] or "Someone"

    print("--- Security System ---")
    print("Detected: " .. playerName)
    print("Status: Playing " .. fileName)
    print("Cooldown active: " .. cooldownSeconds .. "s")

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
print("System Online. Waiting for players...")

while true do
    -- Check for players
    if detector.isPlayerInRange(detectionRange) then
        playSong()
        -- Lock the script until cooldown is over
        sleep(cooldownSeconds)
        term.clear()
        term.setCursorPos(1,1)
        print("Cooldown finished. Waiting for players...")
    end
    
    -- Check every second to save CPU
    sleep(1)
end