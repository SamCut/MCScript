-- =============================================
-- CONFIGURATION
-- =============================================
local CAPACITY_PER_TANK = 16000
-- Where the vital list starts (Row 10 gives space for the blood UI)
local VITALS_START_Y = 11 
-- How wide each villager column is (e.g., "V1:OK" is ~6 chars, so 8 is safe)
local COL_WIDTH = 8

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

-- 1. Helper for Dynamic Valves (From dynamic_tank_reader.lua)
local function findAllValves()
    local names = peripheral.getNames()
    local valves = {}
    -- STRICT SEARCH: Look for "dynamicValve" (case-sensitive)
    for _, name in ipairs(names) do
        if name:find("dynamicValve") then
            table.insert(valves, name)
        end
    end
    return valves
end

-- 2. Helper to get data from a single valve
local function getTankData(p)
    local data = { amount = 0, capacity = 0 }
    
    -- Get Stored Amount
    if p.getStored then
        local ok, res = pcall(p.getStored)
        if ok and type(res) == "table" and res.amount then
            data.amount = res.amount
        elseif ok and type(res) == "number" then
            data.amount = res
        end
    end

    -- Get Capacity
    if p.getTankCapacity then
        local ok, res = pcall(p.getTankCapacity)
        if ok and type(res) == "number" then
            data.capacity = res
        end
    end

    return data
end

-- 3. Draw Bar Helper
local function drawBar(percent)
    local w, h = mon.getSize()
    local barWidth = w - 2
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

    -- --- PART 1: FLUID LOGIC (MERGED) ---
    local currentAmount = 0
    local totalMax = 0
    local tankCount = 0

    -- A. Process Standard Fluid Storage Tanks
    local standardTanks = { peripheral.find("fluid_storage") }
    tankCount = tankCount + #standardTanks
    totalMax = totalMax + (#standardTanks * CAPACITY_PER_TANK)
    
    for i = 1, #standardTanks do
        -- Check if tanks() method exists and returns data
        if standardTanks[i].tanks then
            local tInfo = standardTanks[i].tanks()
            if tInfo and tInfo[1] and tInfo[1].amount then
                currentAmount = currentAmount + tInfo[1].amount
            end
        end
    end

    -- B. Process Dynamic Tanks (New Logic)
    local valveNames = findAllValves()
    tankCount = tankCount + #valveNames
    
    for _, name in ipairs(valveNames) do
        local valve = peripheral.wrap(name)
        if valve then
            local data = getTankData(valve)
            currentAmount = currentAmount + data.amount
            totalMax = totalMax + data.capacity
        end
    end

    -- --- PART 2: VITALS SCANNING ---
    local vitalsData = {}
    local alarmTriggered = false
    
    for i, d in ipairs(detectors) do
        local entities = d.scanEntities(4)
        local alive = false
        
        for _, e in pairs(entities) do
            -- Check for Unemployed villager
            if e.name == "Unemployed" then
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
    
    -- Show stats if ANY tank is found (Standard OR Dynamic)
    if tankCount > 0 then
        local percent = 0
        if totalMax > 0 then
            percent = (currentAmount / totalMax) * 100
        end

        local L, V = 15, 7 -- Layout spacing
        
        mon.setCursorPos(3, 3)
        mon.write(string.format("%-"..L.."s %"..V.."d", "Sources:", tankCount))
        mon.setCursorPos(3, 4)
        mon.write(string.format("%-"..L.."s %"..V.."d B", "Current:", currentAmount / 1000))
        mon.setCursorPos(3, 5)
        mon.write(string.format("%-"..L.."s %"..V.."d B", "Max Cap:", totalMax / 1000))
        mon.setCursorPos(3, 6)
        mon.write(string.format("%-"..L.."s %"..V..".1f%%", "Fill:", percent))
        
        drawBar(percent)
    else
        mon.setCursorPos(3, 4)
        mon.setTextColor(colors.red)
        mon.write("NO TANKS DETECTED")
    end

    -- >> Draw Vitals Grid
    -- Draw a separator line
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
        
        -- Compact Label: "V1"
        mon.setTextColor(colors.white)
        mon.write("V" .. v.id)
        
        -- Compact Status: ":OK" or ":XX"
        if v.isAlive then
            mon.setTextColor(colors.green)
            mon.write(":OK")
        else
            mon.setTextColor(colors.red)
            mon.write(":XX")
        end
        
        -- Move Cursor Logic
        currentY = currentY + 1
        
        -- If we hit the bottom of the monitor, move to new column
        if currentY > h then
            currentY = VITALS_START_Y
            currentX = currentX + COL_WIDTH
        end

        -- Stop drawing if we run off the right side of the screen
        if currentX > w then break end
    end

    sleep(2) -- Refresh every 2 seconds to reduce lag
end