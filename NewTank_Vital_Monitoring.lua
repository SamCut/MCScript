-- =============================================
-- CONFIGURATION
-- =============================================
local DEBUG_MODE = false 

local VITALS_START_Y = 11 
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
-- STATE MANAGEMENT
-- =============================================
local tankCache = {} 

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

local function formatNumber(n)
    if not n then return "0" end
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function drawBar(percent)
    local w, h = mon.getSize()
    if w < 2 then return end 

    local barWidth = w - 2
    local filledWidth = math.floor((percent / 100) * barWidth)
    if filledWidth > barWidth then filledWidth = barWidth end
    if filledWidth < 0 then filledWidth = 0 end
    
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
-- TANK SCANNING LOGIC
-- =============================================
local function findUniqueTanks()
    local foundTanks = {}
    local seenNames = {}

    -- Helper to safely add peripherals by type
    local function addByType(typeStr)
        local periphs = { peripheral.find(typeStr) }
        for _, p in ipairs(periphs) do
            local name = peripheral.getName(p)
            if not seenNames[name] then
                seenNames[name] = true
                table.insert(foundTanks, p)
            end
        end
    end

    -- 1. Generic Fluid Storage (Drums, etc)
    addByType("fluid_storage")
    
    -- 2. Mekanism Dynamic Tanks (The specific type you mentioned)
    -- This covers "mekanism:dynamic_tank_x"
    addByType("mekanism:dynamic_tank")
    
    -- 3. Valves (Just in case the type differs from the name)
    addByType("mekanism:dynamic_valve")

    return foundTanks
end

local function readTankData(tank)
    local tCap, tAmt = 0, 0
    local readSuccess = false
    
    -- METHOD 1: .tanks() (Modern CC)
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

    -- METHOD 2: .getTankInfo() (Standard Mekanism)
    -- I restored this as it is critical for many Mek versions
    if not readSuccess and tank.getTankInfo then
         local success, info = pcall(tank.getTankInfo)
         if success then
             -- Sometimes returns a single table, sometimes a list of tables
             if info.capacity then 
                 tAmt = info.amount or 0
                 tCap = info.capacity or 0
             else
                 for _, sub in pairs(info) do
                     tAmt = tAmt + (sub.amount or 0)
                     tCap = tCap + (sub.capacity or 0)
                 end
             end
             if tCap > 0 then readSuccess = true end
         end
    end

    -- METHOD 3: .getTanks() (Mekanism v10+)
    if not readSuccess and tank.getTanks then
        local success, result = pcall(tank.getTanks)
        if success then
            if type(result) == "table" then
                for _, tData in pairs(result) do
                    tAmt = tAmt + (tData.amount or 0)
                    tCap = tCap + (tData.capacity or 0)
                end
            elseif type(result) == "number" and result > 0 then
                for i = 1, result do
                    local lvl = 0
                    if tank.getTankLevel then lvl = tank.getTankLevel(i) or 0 end
                    local cap = 0
                    if tank.getTankCapacity then cap = tank.getTankCapacity(i) or 0 end
                    tAmt = tAmt + lvl
                    tCap = tCap + cap
                end
            end
            if tCap > 0 then readSuccess = true end
        end
    end

    -- METHOD 4: .getFluid() / .getTankProperties() (Legacy/Modded)
    if not readSuccess then
        -- try getFluid
        if tank.getFluid then
             local success, info = pcall(tank.getFluid)
             if success and type(info) == "table" then
                 tAmt = info.amount or 0
                 tCap = info.capacity or 0
                 if tCap > 0 then readSuccess = true end
             end
        end
        -- try getTankProperties
        if not readSuccess and tank.getTankProperties then
            local success, props = pcall(tank.getTankProperties)
             if success and type(props) == "table" then
                 if props[1] then 
                     for _, prop in pairs(props) do
                         local c = prop.contents
                         if c then tAmt = tAmt + (c.amount or 0) end
                         tCap = tCap + (prop.capacity or 0)
                     end
                 else
                     local c = props.contents
                     if c then tAmt = c.amount or 0 end
                     tCap = props.capacity or 0
                 end
                 if tCap > 0 then readSuccess = true end
             end
        end
    end

    return readSuccess, tAmt, tCap
end

-- =============================================
-- MAIN LOOP
-- =============================================
print("Monitor Initialized.")
print("Scanning for 'mekanism:dynamic_tank'...")

while true do
    -- Catch-all error handler
    local status, err = pcall(function()
        local w, h = mon.getSize()
        
        -- 1. Find Tanks
        local tanks = findUniqueTanks()
        local currentAmount = 0
        local totalMax = 0
        local validTankCount = 0
        
        -- 2. Read Data & Cache
        for _, tank in ipairs(tanks) do
            local name = peripheral.getName(tank)
            local success, amt, cap = readTankData(tank)
            
            if success and cap > 0 then
                -- Valid read: update cache and totals
                tankCache[name] = { amt = amt, cap = cap }
                currentAmount = currentAmount + amt
                totalMax = totalMax + cap
                validTankCount = validTankCount + 1
            elseif tankCache[name] then
                -- Invalid read (flicker): use cache
                currentAmount = currentAmount + tankCache[name].amt
                totalMax = totalMax + tankCache[name].cap
                validTankCount = validTankCount + 1
            end
        end

        -- 3. Draw Monitor
        mon.clear()
        mon.setTextScale(1)
        
        if DEBUG_MODE and validTankCount == 0 then
            mon.setCursorPos(1,1)
            mon.write("DEBUG: No Tanks Reading")
            mon.setCursorPos(1,2)
            mon.write("Found Peripherals: " .. #tanks)
        else
            -- Vitals Scan
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

            -- Header
            mon.setCursorPos(1, 1)
            mon.setTextColor(colors.red)
            mon.write("-- BLOOD MONITORING SYSTEM --")
            
            local percent = 0
            if totalMax > 0 then percent = (currentAmount / totalMax) * 100 end
            
            local L, V = 12, 10 
            local amountB = currentAmount / 1000
            local maxB = totalMax / 1000

            mon.setCursorPos(3, 3)
            mon.setTextColor(colors.white)
            mon.write(string.format("%-"..L.."s %"..V.."s", "Tanks:", tostring(validTankCount)))
            
            mon.setCursorPos(3, 4)
            mon.write(string.format("%-"..L.."s %"..V.."s B", "Current:", formatNumber(amountB)))
            
            mon.setCursorPos(3, 5)
            mon.write(string.format("%-"..L.."s %"..V.."s B", "Max Cap:", formatNumber(maxB)))
            
            mon.setCursorPos(3, 6)
            mon.write(string.format("%-"..L.."s %"..V..".1f%%", "Fill:", percent))
            
            drawBar(percent)

            -- Pod Status
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
        end
        
        -- Terminal Status
        term.clear()
        term.setCursorPos(1,1)
        print("Status: RUNNING")
        print("Tanks Found: " .. #tanks)
        print("Valid Reads: " .. validTankCount)
        print("Total: " .. formatNumber(currentAmount/1000) .. " B")

    end) 

    if not status then
        print("Error: " .. tostring(err))
    end

    sleep(2) 
end