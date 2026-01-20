local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local audioFile = "/doornoise.dfpwm"
local detector = peripheral.find("player_detector")
local doorSide = "back" 
local range = 8

-- Table to keep track of who is currently in range
local activePlayers = {}

term.clear()
term.setCursorPos(1,1)
print("=== SACRIFICIAL SECURITY SYSTEM V1.1 ===")

if not detector then
    print("STATUS: ERROR - Detector not found!")
    return
end

print("STATUS: INITIALIZING...")
print("RANGE: " .. range .. " blocks")
sleep(1)

local function playDoorNoise()
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

-- Helper function to check if a name is in a list
local function isNameInList(name, list)
    for _, value in ipairs(list) do
        if value == name then return true end
    end
    return false
end

while true do
    -- Get the current list of players within range
    local detectedNow = detector.getPlayersInRange(range)
    local timestamp = "[" .. textutils.formatTime(os.time(), true) .. "] "

    -- 1. Check for NEW players (Entered)
    for _, name in ipairs(detectedNow) do
        if not isNameInList(name, activePlayers) then
            print(timestamp .. "ENTERED: " .. name)
            table.insert(activePlayers, name)
        end
    end

    -- 2. Check for players who LEFT
    for i = #activePlayers, 1, -1 do
        local name = activePlayers[i]
        if not isNameInList(name, detectedNow) then
            print(timestamp .. "LEFT:    " .. name)
            table.remove(activePlayers, i)
        end
    end

    -- 3. Door Control Logic
    if #activePlayers > 0 then
        -- Someone is here! Keep the door open.
        if redstone.getOutput(doorSide) == false then
            redstone.setOutput(doorSide, true)
            playDoorNoise()
            print("STATUS: SECURE ACCESS GRANTED")
        end
    else
        -- Area is empty. Close the door.
        if redstone.getOutput(doorSide) == true then
            redstone.setOutput(doorSide, false)
            playDoorNoise()
            print("STATUS: AREA CLEAR - LOCKING DOWN")
        end
    end

    sleep(0.5) -- Fast enough to catch sprinters, slow enough to prevent lag
end