-- =============================================
-- CONFIGURATION
-- =============================================
-- Set to true to force the debug list to show
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
-- DATA READING LOGIC
-- =============================================
local function readTankData(tank)
    local tCap, tAmt = 0, 0
    local readSuccess = false
    
    -- METHOD 1: .tanks() (Modern CC Standard)
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

    -- METHOD 2: .getTankInfo() (Critical for Mekanism Valves)
    if not readSuccess and tank.getTankInfo then
         local success, info = pcall(tank.getTankInfo)
         if success then
             -- Returns either {capacity=...} OR { {capacity=...} }
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

    return readSuccess, tAmt, tCap
end

local function scanAndReadTanks()
    -- Get EVERY connected peripheral name
    local allNames = peripheral.getNames()
    local validTanks = {} 
    local debugList = {} 
    
    local totalAmt = 0
    local totalCap = 0
    
    for _, name in ipairs(allNames) do
        -- Filter: Look for keywords in the name to identify potential tanks
        -- We include "mekanism" specifically because you mentioned "mekanism:dynamic_tank_x"
        local lowerName = string.lower(name)
        if (lowerName:find("tank") or lowerName:find("valve") or 
            lowerName:find("fluid") or lowerName:find("mekanism") or 
            lowerName:find("storage")) and 
           not lowerName:find("monitor") and 
           not lowerName:find("detector") and 
           not lowerName:find("drive") and 
           not lowerName:find("printer") and
           not lowerName:find("modem") then
            
            local p = peripheral.wrap(name)
            if p then
                local success, amt, cap = readTankData(p)
                
                -- CACHING: If read fails (0), try to use last known good value
                if success and cap > 0 then
                    tankCache[name] = { amt = amt, cap = cap }
                elseif tankCache[name] then
                    amt = tankCache[name].amt
                    cap = tankCache[name].cap
                    success = true -- Treat cached data as success
                end

                -- Log for debug screen
                table.insert(debugList, {
                    name = name,
                    success = success,
                    cap = cap,
                    amt = amt
                })

                if success and cap > 0 then
                    totalAmt = totalAmt + amt
                    totalCap = totalCap + cap
                    table.insert(validTanks, p)
                end
            end
        end
    end
    
    return validTanks, totalAmt, totalCap, debugList
end

-- =============================================
-- MAIN LOOP
-- =============================================
print("Monitor Initialized.")
print("Scanning peripherals...")

while true do
    -- Pcall wrapper to prevent script crash on disconnect
    local status, err = pcall(function()
        local w, h = mon.getSize()
        
        -- 1. Scan everything
        local tanks, currentAmount, totalMax, debugList = scanAndReadTanks()
        
        -- 2. Determine View Mode
        local showDebug = false
        if DEBUG_MODE then showDebug = true end
        if #tanks == 0 then showDebug = true end -- Auto-show debug if no tanks work
        
        mon.clear()
        mon.setTextScale(1)

        if showDebug then
            -- >>> DEBUG VIEW <<<
            mon.setTextScale(0.5)
            mon.setCursorPos(1,1)
            mon.setTextColor(colors.orange)
            mon.write("DEBUG: NO VALID TANKS DETECTED")
            mon.setCursorPos(1,2)
            mon.setTextColor(colors.white)
            mon.write("Checking: " .. tostring(#debugList) .. " peripherals...")
            
            local y = 4
            if #debugList == 0 then
                mon.setCursorPos(1,y)
                mon.setTextColor(colors.red)
                mon.write("No 'tank' or 'valve' peripherals found.")
                mon.setCursorPos(1,y+1)
                mon.write("Check Wired Modems (Must be RED).")
            else
                for _, info in ipairs(debugList) do
                    mon.setCursorPos(1,y)
                    if info.cap > 0 then
                        mon.setTextColor(colors.green)
                    else
                        mon.setTextColor(colors.red)
                    end
                    
                    local str = string.format("%s | Cap: %s", info.name, formatNumber(info.cap))
                    mon.write(str)
                    y = y + 1
                    if y > 35 then break end
                end
            end
            
            -- Also print to terminal
            term.clear()
            term.setCursorPos(1,1)
            print("DEBUG MODE ACTIVE")
            print("Found " .. #debugList .. " potential tanks.")
        else
            -- >>> STANDARD VIEW <<<
            
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
            mon.write(string.format("%-"..L.."s %"..V.."s", "Tanks:", tostring(#tanks)))
            
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
            
            -- Terminal Status
            term.clear()
            term.setCursorPos(1,1)
            print("System Running.")
            print("Tanks: " .. #tanks)
            print("Total: " .. formatNumber(currentAmount/1000) .. " B")
        end
    end) 

    if not status then
        print("Error: " .. tostring(err))
    end

    sleep(2) 
end