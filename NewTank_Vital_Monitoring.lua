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
local tankCache = {} 

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- NEW: Universal Scanner
-- Scans ALL connected peripherals and checks if they have tank functions
local function scanForTanks()
    local candidates = {}
    local allPeripherals = peripheral.getNames()
    
    -- Debug: Print what we see to local console
    term.clear()
    term.setCursorPos(1,1)
    print("--- DIAGNOSTIC MODE ---")
    print("Connected Peripherals:")
    
    for _, name in ipairs(allPeripherals) do
        -- Skip known non-tanks to save processing
        if name ~= "back" and name ~= "front" and name ~= "top" and 
           not name:find("monitor") and 
           not name:find("detector") and 
           not name:find("modem") then
            
            local p = peripheral.wrap(name)
            if p then
                -- DUCK TYPING: If it walks like a tank, it's a tank.
                -- Check if it has ANY common fluid methods
                if p.tanks or p.getTanks or p.getTankLevel or p.getTankInfo or p.getFluid or p.getCapacity then
                    table.insert(candidates, p)
                    print(" [TANK] " .. name) -- Mark as valid tank
                else
                    print(" [OTHER] " .. name) -- Connected, but not a tank
                end
            end
        else
            -- Print excluded peripherals just so user knows they are seen
            if not name:find("modem") then -- modems spam the list
                 print(" [SYS] " .. name)
            end
        end
    end
    
    if #candidates == 0 then
        print("\nWARNING: No tank-like peripherals found!")
        print("Ensure modems on Valves are RED.")
    end
    
    return candidates
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
print("\nStarting Monitor Loop...")

while true do
    local w, h = mon.getSize()

    -- --- PART 1: FLUID LOGIC ---
    -- Using the new scanner
    local tanks = scanForTanks()
    
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

        -- CACHE LOGIC
        if readSuccess and tCap > 1000 then
            tankCache[tName] = { cap = tCap, amt = tAmt }
            tanksFoundCount = tanksFoundCount + 1
        elseif tankCache[tName] then
            -- Use cache if read failed
            tCap = tankCache[tName].cap
            tAmt = tankCache[tName].amt
            tanksFoundCount = tanksFoundCount + 1
        else
            tCap = 0
            tAmt = 0
        end

        currentAmount = currentAmount + tAmt
        totalMax = totalMax + tCap
    end

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
        mon.write("See Local Term for Info")
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