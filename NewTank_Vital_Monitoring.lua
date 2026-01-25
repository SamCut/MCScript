-- =============================================
-- CONFIGURATION
-- =============================================
-- Where the vital list starts (Row 10 gives space for the blood UI)
local VITALS_START_Y = 11 
-- How wide each villager column is (e.g., "V1: [ALIVE]" is ~12 chars)
local COL_WIDTH = 14 

-- =============================================
-- PERIPHERAL SETUP
-- =============================================
local mon = peripheral.find("monitor")
local detectors = { peripheral.find("environment_detector") }

if not mon then error("Error: Monitor not found!") end

-- Sort detectors by name to ensure "Villager 1" stays at position 1
table.sort(detectors, function(a, b) 
    return peripheral.getName(a) < peripheral.getName(b) 
end)

-- =============================================
-- HELPER FUNCTIONS
-- =============================================
local function drawBar(percent)
    local w, h = mon.getSize()
    local barWidth = w - 2
    
    -- Safety clamp for percentage
    if percent < 0 then percent = 0 end
    if percent > 100 then percent = 100 end

    local filledWidth = math.floor((percent / 100) * barWidth)
    
    -- Background (Gray)
    mon.setCursorPos(2, 8)
    mon.setBackgroundColor(colors.gray)
    mon.write(string.rep(" ", barWidth))
    
    -- Fill (Red)
    if filledWidth > 0 then
        mon.setCursorPos(2, 8)
        mon.setBackgroundColor(colors.red)
        mon.write(string.rep(" ", filledWidth))
    end
    mon.setBackgroundColor(colors.black)
end

-- =============================================
-- MAIN LOOP
-- =============================================
while true do
    local w, h = mon.getSize()

    -- --- PART 1: FLUID LOGIC (UNIVERSAL DETECTION) ---
    local currentAmount = 0
    local totalMax = 0
    local tankCount = 0

    -- improved logic: scan ALL peripherals. 
    -- If it has a .tanks() method, it's a tank. 
    -- This works for "fluid_storage", "tank", "dynamic_tank", etc.
    local allPeripherals = peripheral.getNames()
    
    for _, name in ipairs(allPeripherals) do
        -- Skip the monitor and detectors to save processing time
        if peripheral.getType(name) ~= "monitor" and peripheral.getType(name) ~= "environment_detector" and peripheral.getType(name) ~= "modem" then
            local p = peripheral.wrap(name)
            
            -- Check if this peripheral has fluid capabilities
            if p and p.tanks then
                tankCount = tankCount + 1
                local tankData = p.tanks()
                
                -- Iterate through all internal tanks (some blocks have multiple)
                if tankData then
                    for _, info in pairs(tankData) do
                        if info then
                            currentAmount = currentAmount + (info.amount or 0)
                            -- Use dynamic capacity, fallback to 16000 (16B) if nil
                            totalMax = totalMax + (info.capacity or 16000)
                        end
                    end
                end
            end
        end
    end

    -- Prevent division by zero if nothing is connected
    if totalMax == 0 then totalMax = 1 end

    -- --- PART 2: VITALS SCANNING ---
    local vitalsData = {}
    local alarmTriggered = false
    
    for i, d in ipairs(detectors) do
        local entities = d.scanEntities(4)
        local alive = false
        
        for _, e in pairs(entities) do
            -- Check for Unemployed or standard Villager
            if e.name == "Unemployed" or e.name == "Villager" then
                alive = true
                break
            end
        end

        if not alive then alarmTriggered = true end
        table.insert(vitalsData, { id = i, isAlive = alive })
    end

    -- Handle Redstone Alarm (Back of computer)
    redstone.setOutput("back", alarmTriggered)

    -- --- PART 3: DRAWING TO MONITOR ---
    mon.clear()
    mon.setTextScale(1)
    
    -- >> Draw Header & Blood Stats
    mon.setCursorPos(1, 1)
    mon.setTextColor(colors.red)
    mon.write("-- BLOOD MONITORING SYSTEM --")
    
    if tankCount > 0 then
        local percent = (currentAmount / totalMax) * 100
        local L, V = 15, 7 -- Layout spacing
        
        -- Formatting helper for large numbers (mB to Buckets)
        local currB = math.floor(currentAmount / 1000)
        local maxB = math.floor(totalMax / 1000)

        mon.setCursorPos(3, 3)
        mon.write(string.format("%-"..L.."s %"..V.."d", "Sources:", tankCount))
        mon.setCursorPos(3, 4)
        mon.write(string.format("%-"..L.."s %"..V.."d B", "Current:", currB))
        mon.setCursorPos(3, 5)
        mon.write(string.format("%-"..L.."s %"..V.."d B", "Max Cap:", maxB))
        mon.setCursorPos(3, 6)
        mon.write(string.format("%-"..L.."s %"..V..".1f%%", "Fill:", percent))
        
        drawBar(percent)
    else
        mon.setCursorPos(3, 4)
        mon.setTextColor(colors.red)
        mon.write("NO TANKS DETECTED")
    end

    -- >> Draw Vitals Grid
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.yellow)
    mon.setCursorPos(1, 9) 
    mon.write(string.rep("-", w))
    mon.setCursorPos(2, 10)
    mon.write("POD STATUS:")

    -- Dynamic Grid Logic
    local currentX = 2
    local currentY = VITALS_START_Y
    
    for _, v in ipairs(vitalsData) do
        mon.setCursorPos(currentX, currentY)
        
        mon.setTextColor(colors.white)
        mon.write("V" .. v.id .. ":")
        
        if v.isAlive then
            mon.setTextColor(colors.green)
            mon.write("[OK]")
        else
            mon.setTextColor(colors.red)
            mon.write("[DEAD]")
        end
        
        currentY = currentY + 1
        
        if currentY > h then
            currentY = VITALS_START_Y
            currentX = currentX + COL_WIDTH
        end

        if currentX > w then break end
    end

    sleep(2)
end