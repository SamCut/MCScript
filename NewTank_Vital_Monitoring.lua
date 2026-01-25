-- =============================================
-- CONFIGURATION
-- =============================================
-- Fallback capacity if a tank doesn't report its own size
local FALLBACK_CAPACITY = 16000 

-- Where the vital list starts (Row 11 gives space for the blood UI)
local VITALS_START_Y = 11 
-- How wide each villager column is (e.g., "V1: [ALIVE]" is ~12 chars)
local COL_WIDTH = 14 

-- =============================================
-- PERIPHERAL SETUP
-- =============================================
local mon = peripheral.find("monitor")
local detectors = { peripheral.find("environment_detector") }

if not mon then error("Error: Monitor not found!") end

table.sort(detectors, function(a, b) 
    return peripheral.getName(a) < peripheral.getName(b) 
end)

-- =============================================
-- STATE MANAGEMENT (CACHING)
-- =============================================
-- We store the last valid read here to prevent flickering if a read fails briefly
local tankCache = {} 

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- Find unique tanks, prioritizing Valves
local function findUniqueTanks()
    local foundTanks = {}
    local seenNames = {}

    local function addTanks(typeStr)
        local periphs = { peripheral.find(typeStr) }
        for _, p in ipairs(periphs) do
            local name = peripheral.getName(p)
            -- Deduplication: Only add if we haven't seen this name
            if not seenNames[name] then
                -- Filter: Explicitly ignore "dynamic_tank" (structural blocks)
                -- We only want "valve" or generic storage
                if not name:find("dynamic_tank") then
                    seenNames[name] = true
                    table.insert(foundTanks, p)
                end
            end
        end
    end

    -- 1. Look for Generic Fluid Storage (often wraps valves correctly)
    addTanks("fluid_storage")
    -- 2. Look specifically for Mekanism Valves (if generic missed them)
    addTanks("mekanism:dynamic_valve") 
    
    return foundTanks
end

local function formatNumber(n)
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function drawBar(percent)
    local w, h = mon.getSize()
    local barWidth = w - 2
    local filledWidth = math.floor((percent / 100) * barWidth)
    
    if filledWidth > barWidth then filledWidth = barWidth end
    
    mon.setCursorPos(2, 8)
    mon.setBackgroundColor(colors.gray)
    mon.write(string.rep(" ", barWidth))
    
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
print("Blood Monitor Running...")
print("System Stabilized.")

while true do
    local w, h = mon.getSize()

    -- --- PART 1: FLUID LOGIC ---
    local tanks = findUniqueTanks()
    local currentAmount = 0
    local totalMax = 0
    local tanksFoundCount = 0
    
    for _, tank in ipairs(tanks) do
        local tName = peripheral.getName(tank)
        local tCap, tAmt = 0, 0
        local readSuccess = false

        -- ATTEMPT 1: Standard .tanks()
        if not readSuccess and tank.tanks then 
            local success, data = pcall(tank.tanks)
            if success and data and #data > 0 then
                for _, tInfo in pairs(data) do
                     tAmt = tAmt + (tInfo.amount or 0)
                     tCap = tCap + (tInfo.capacity or 0)
                end
                if tCap > 0 then readSuccess = true end
            end
        end

        -- ATTEMPT 2: Mekanism .getTanks()
        if not readSuccess and tank.getTanks then
            local success, result = pcall(tank.getTanks)
            if success then
                -- Scenario A: Returns Table of info
                if type(result) == "table" then
                    for _, tData in pairs(result) do
                        tAmt = tAmt + (tData.amount or 0)
                        tCap = tCap + (tData.capacity or 0)
                    end
                    if tCap > 0 then readSuccess = true end
                
                -- Scenario B: Returns Count of tanks
                elseif type(result) == "number" and result > 0 then
                    for i = 1, result do
                        local lvl = 0
                        if tank.getTankLevel then lvl = tank.getTankLevel(i) or 0 end
                        local cap = 0
                        if tank.getTankCapacity then cap = tank.getTankCapacity(i) or 0 end
                        
                        tAmt = tAmt + lvl
                        tCap = tCap + cap
                    end
                    if tCap > 0 then readSuccess = true end
                end
            end
        end

        -- ATTEMPT 3: Legacy .getCapacity / .getAmount
        if not readSuccess then
            local cap = 0
            if tank.getCapacity then cap = tank.getCapacity() end
            
            local amt = 0
            if tank.getAmount then amt = tank.getAmount() 
            elseif tank.getStored then 
                 local s = tank.getStored()
                 if type(s) == "table" then amt = s.amount or 0 else amt = s or 0 end
            end
            
            if cap > 0 then 
                tCap = cap
                tAmt = amt
                readSuccess = true 
            end
        end

        -- CACHE LOGIC (Fixes Fluctuation)
        if readSuccess and tCap > 1000 then
            -- If read was good and capacity is realistic (> 1 bucket), update cache
            tankCache[tName] = { cap = tCap, amt = tAmt }
            tanksFoundCount = tanksFoundCount + 1
        elseif tankCache[tName] then
            -- If read failed (or returned 0), use last known good value
            tCap = tankCache[tName].cap
            tAmt = tankCache[tName].amt
            tanksFoundCount = tanksFoundCount + 1
        else
            -- If no cache and read failed, ignore this tank
            tCap = 0
            tAmt = 0
        end

        currentAmount = currentAmount + tAmt
        totalMax = totalMax + tCap
    end

    -- Safety: Prevent Div/0
    local displayMax = totalMax
    if displayMax == 0 then displayMax = 1 end

    -- --- PART 2: VITALS SCANNING ---
    local vitalsData = {}
    local alarmTriggered = false
    
    for i, d in ipairs(detectors) do
        local entities = d.scanEntities(4)
        local alive = false
        if entities then
            for _, e in pairs(entities) do
                if e.name == "Unemployed" or e.name == "Villager" then
                    alive = true
                    break
                end
            end
        end
        if not alive then alarmTriggered = true end
        table.insert(vitalsData, { id = i, isAlive = alive })
    end

    redstone.setOutput("back", alarmTriggered)

    -- --- PART 3: DRAWING ---
    mon.clear()
    mon.setTextScale(1)
    
    mon.setCursorPos(1, 1)
    mon.setTextColor(colors.red)
    mon.write("-- BLOOD MONITORING SYSTEM --")
    
    if tanksFoundCount > 0 then
        local percent = (currentAmount / displayMax) * 100
        local L, V = 12, 10 
        
        -- Convert to Buckets (B)
        local amountB = currentAmount / 1000
        local maxB = totalMax / 1000

        mon.setCursorPos(3, 3)
        mon.write(string.format("%-"..L.."s %"..V.."s", "Tanks:", tostring(tanksFoundCount)))
        
        mon.setCursorPos(3, 4)
        mon.write(string.format("%-"..L.."s %"..V.."s B", "Current:", formatNumber(amountB)))
        
        mon.setCursorPos(3, 5)
        mon.write(string.format("%-"..L.."s %"..V.."s B", "Max Cap:", formatNumber(maxB)))
        
        mon.setCursorPos(3, 6)
        mon.write(string.format("%-"..L.."s %"..V..".1f%%", "Fill:", percent))
        
        drawBar(percent)
    else
        mon.setCursorPos(3, 4)
        mon.setTextColor(colors.red)
        mon.write("NO TANKS DETECTED")
        mon.setCursorPos(3, 5)
        mon.setTextColor(colors.white)
        mon.write("Check Valve Modems")
    end

    -- >> Draw Vitals Grid
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.yellow)
    mon.setCursorPos(1, 11) 
    mon.write(string.rep("-", w))
    mon.setCursorPos(2, 12)
    mon.write("POD STATUS:")

    local currentX = 2
    local currentY = 13
    
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
            currentY = 13
            currentX = currentX + COL_WIDTH
        end
        if currentX > w then break end
    end

    sleep(2) 
end