-- =============================================
-- CONFIGURATION
-- =============================================
local VITALS_START_Y = 11 
local COL_WIDTH = 14 
-- Toggle this to true to see exactly what is being found on the monitor
local SHOW_DEBUG_ON_MONITOR = true 

-- FILTER: Ignore tanks smaller than this (in mB)
-- 4000 mB = 4 Buckets. This filters out pipes and machine buffers
local MIN_CAPACITY = 4000 

-- =============================================
-- PERIPHERAL SETUP
-- =============================================
local mon = peripheral.find("monitor")
local detectors = { peripheral.find("environment_detector") }

if not mon then error("Error: Monitor not found!") end

-- Sort detectors
table.sort(detectors, function(a, b) 
    return peripheral.getName(a) < peripheral.getName(b) 
end)

-- =============================================
-- HELPER FUNCTIONS
-- =============================================
local function drawBar(percent)
    local w, h = mon.getSize()
    local barWidth = w - 2
    if percent < 0 then percent = 0 end
    if percent > 100 then percent = 100 end

    local filledWidth = math.floor((percent / 100) * barWidth)
    
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

-- Force tank data into a standard list format { {amount=...}, {amount=...} }
local function normalizeTankData(data)
    if not data then return {} end
    
    -- CASE 1: It's already a sequential list (Standard CC)
    if data[1] then return data end
    
    -- CASE 2: It's a single tank object (Direct wrapper)
    if type(data) == "table" and (data.amount or data.capacity) then
        return { data }
    end
    
    -- CASE 3: It's a key-value map (Mekanism sometimes does this)
    local list = {}
    for k, v in pairs(data) do
        if type(v) == "table" and (v.amount or v.capacity) then
            table.insert(list, v)
        end
    end
    return list
end

-- =============================================
-- MAIN LOOP
-- =============================================
while true do
    local w, h = mon.getSize()
    mon.clear()
    mon.setTextScale(1)

    -- --- PART 1: UNIVERSAL TANK DETECTION ---
    local currentAmount = 0
    local totalMax = 0
    local tankCount = 0
    local debugLog = {} -- Store debug info for display

    local allPeripherals = peripheral.getNames()

    for _, pName in ipairs(allPeripherals) do
        local pType = peripheral.getType(pName)
        
        -- Skip known non-fluid peripherals
        if pType ~= "monitor" and pType ~= "modem" and 
           pType ~= "computer" and pType ~= "environment_detector" and
           pType ~= "drive" and pType ~= "printer" and pType ~= "speaker" then
            
            local p = peripheral.wrap(pName)
            local rawData = nil
            
            -- Try Method A: .tanks() (Standard)
            if p.tanks then
                local success, data = pcall(p.tanks)
                if success then rawData = data end
            end
            
            -- Try Method B: .getTankInfo() (Older/Mod specific)
            if not rawData and p.getTankInfo then
                local success, data = pcall(p.getTankInfo)
                if success then rawData = data end
            end

            -- Process Data
            if rawData then
                local cleanList = normalizeTankData(rawData)
                local validFound = false
                
                for _, info in pairs(cleanList) do
                    local cap = info.capacity or 0
                    local amt = info.amount or 0
                    
                    if cap >= MIN_CAPACITY then
                        currentAmount = currentAmount + amt
                        totalMax = totalMax + cap
                        validFound = true
                    else
                        table.insert(debugLog, string.format("Skip: %s (<%d)", pName, MIN_CAPACITY))
                    end
                end
                
                if validFound then
                    tankCount = tankCount + 1
                    table.insert(debugLog, string.format("OK: %s", pName))
                end
            else
                 -- Only log as "No Data" if it wasn't skipped by the type filter
                 -- table.insert(debugLog, string.format("No Data: %s", pName))
            end
        end
    end

    if totalMax == 0 then totalMax = 1 end

    -- --- PART 2: DISPLAY LOGIC ---
    
    mon.setCursorPos(1, 1)
    mon.setTextColor(colors.red)
    mon.write("-- BLOOD MONITORING SYSTEM --")
    
    if tankCount > 0 then
        -- SHOW NORMAL UI
        local percent = (currentAmount / totalMax) * 100
        local L, V = 15, 7
        
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
        -- SHOW ERROR UI
        mon.setCursorPos(3, 3)
        mon.setTextColor(colors.red)
        mon.write("NO TANKS FOUND")
        
        if SHOW_DEBUG_ON_MONITOR then
            mon.setTextColor(colors.gray)
            local row = 4
            mon.setCursorPos(1, row)
            mon.write("Debug Info:")
            row = row + 1
            
            if #debugLog == 0 then
                 mon.setCursorPos(1, row)
                 mon.write("No candidates detected.")
            else
                for _, msg in ipairs(debugLog) do
                    if row < h - 2 then -- Leave room for bottom bar
                        mon.setCursorPos(1, row)
                        mon.write(msg)
                        row = row + 1
                    end
                end
            end
        end
    end

    -- --- PART 3: VITALS SCANNING ---
    -- (This part remains the same)
    local vitalsData = {}
    local alarmTriggered = false
    
    for i, d in ipairs(detectors) do
        local entities = d.scanEntities(4)
        local alive = false
        for _, e in pairs(entities) do
            if e.name == "Unemployed" or e.name == "Villager" then
                alive = true; break
            end
        end
        if not alive then alarmTriggered = true end
        table.insert(vitalsData, { id = i, isAlive = alive })
    end
    redstone.setOutput("back", alarmTriggered)

    -- Separator
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.yellow)
    mon.setCursorPos(1, 9) 
    mon.write(string.rep("-", w))
    mon.setCursorPos(2, 10)
    mon.write("POD STATUS:")

    -- Vitals Grid
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
            currentY = VITALS_START_Y; currentX = currentX + COL_WIDTH
        end
        if currentX > w then break end
    end

    sleep(2)
end