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
    if w < 2 then return end -- Safety for tiny monitors

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
-- DEBUG / DIAGNOSTIC SCREEN
-- =============================================
local function drawDebugScreen(candidates)
    mon.clear()
    mon.setTextScale(0.5) 
    mon.setCursorPos(1,1)
    mon.setTextColor(colors.orange)
    mon.write("DEBUG MODE - PERIPHERAL LIST")
    mon.setCursorPos(1,2)
    mon.setTextColor(colors.white)
    mon.write("Set DEBUG_MODE=false to hide.")
    
    local y = 4
    if #candidates == 0 then
        mon.setCursorPos(1, y)
        mon.setTextColor(colors.red)
        mon.write("NO PERIPHERALS FOUND!")
        mon.setCursorPos(1, y+1)
        mon.write("Check Modem RED light & Cables.")
    else
        for _, info in ipairs(candidates) do
            mon.setCursorPos(1, y)
            
            if info.isTank then
                mon.setTextColor(colors.green)
            elseif info.name:find("valve") or info.name:find("tank") then
                 mon.setTextColor(colors.red) 
            else
                mon.setTextColor(colors.gray)
            end
            
            local str = string.format("%s | Cap:%s", info.name, info.cap or "?")
            mon.write(str)
            
            y = y + 1
            if y > 35 then break end 
        end
    end
end

-- =============================================
-- TANK SCANNING LOGIC
-- =============================================
local function scanAndReadTanks()
    local allNames = peripheral.getNames()
    local validTanks = {} 
    local debugList = {} 
    
    local totalAmt = 0
    local totalCap = 0
    
    for _, name in ipairs(allNames) do
        -- Simplified filter: Only ignore obvious non-tanks
        if not name:find("monitor") and 
           not name:find("detector") and 
           not name:find("modem") and 
           name ~= "back" and name ~= "front" and name ~= "top" and name ~= "bottom" then
            
            -- SAFE WRAPPING: pcall prevents crashes if peripheral disconnects
            local pcallSuccess, p = pcall(peripheral.wrap, name)
            
            if pcallSuccess and p then
                local tCap, tAmt = 0, 0
                local readSuccess = false
                local pType = "unknown"
                pcall(function() pType = peripheral.getType(p) end)

                -- METHOD 1: .tanks() (Standard)
                if not readSuccess and p.tanks then 
                    local success, data = pcall(p.tanks)
                    if success and data and #data > 0 then
                        for _, tInfo in pairs(data) do
                             tAmt = tAmt + (tInfo.amount or 0)
                             tCap = tCap + (tInfo.capacity or 0)
                        end
                        if tCap > 0 then readSuccess = true end
                    end
                end

                -- METHOD 2: .getTanks() (Mekanism v10)
                if not readSuccess and p.getTanks then
                    local success, result = pcall(p.getTanks)
                    if success then
                        if type(result) == "table" then
                            for _, tData in pairs(result) do
                                tAmt = tAmt + (tData.amount or 0)
                                tCap = tCap + (tData.capacity or 0)
                            end
                        elseif type(result) == "number" and result > 0 then
                            for i = 1, result do
                                local lvl = 0
                                if p.getTankLevel then lvl = p.getTankLevel(i) or 0 end
                                local cap = 0
                                if p.getTankCapacity then cap = p.getTankCapacity(i) or 0 end
                                tAmt = tAmt + lvl
                                tCap = tCap + cap
                            end
                        end
                        if tCap > 0 then readSuccess = true end
                    end
                end
                
                -- METHOD 3: .getFluid()
                if not readSuccess and p.getFluid then
                     local success, info = pcall(p.getFluid)
                     if success and type(info) == "table" then
                         tAmt = info.amount or 0
                         tCap = info.capacity or 0
                         if tCap > 0 then readSuccess = true end
                     end
                end

                -- METHOD 4: .getTankProperties()
                if not readSuccess and p.getTankProperties then
                    local success, props = pcall(p.getTankProperties)
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

                -- CACHE LOGIC
                if readSuccess and tCap > 0 then
                    tankCache[name] = { cap = tCap, amt = tAmt }
                elseif tankCache[name] then
                    tCap = tankCache[name].cap
                    tAmt = tankCache[name].amt
                    readSuccess = true 
                end

                table.insert(debugList, {
                    name = name,
                    type = pType,
                    cap = tCap,
                    isTank = readSuccess
                })

                if readSuccess and tCap > 0 then
                    totalAmt = totalAmt + tAmt
                    totalCap = totalCap + tCap
                    table.insert(validTanks, p)
                end
            end -- end pcall success
        end
    end
    
    return validTanks, totalAmt, totalCap, debugList
end

-- =============================================
-- MAIN LOOP
-- =============================================
print("System Initializing...")
mon.clear()
mon.setCursorPos(1,1)
mon.write("Initializing...")

while true do
    -- Catch-all error handler for the main loop
    local status, err = pcall(function()
        local w, h = mon.getSize()
        
        -- Scan
        local tanks, currentAmount, totalMax, debugList = scanAndReadTanks()
        
        -- Logic to decide between Debug and Standard screens
        local showDebug = false
        if DEBUG_MODE then showDebug = true end
        if #tanks == 0 then showDebug = true end
        
        if showDebug then
             drawDebugScreen(debugList)
             -- Print to terminal so user knows it's working
             term.clear()
             term.setCursorPos(1,1)
             print("Status: DEBUG MODE (No tanks or forced)")
             print("Tanks Found: " .. #tanks)
        else
            -- >>> STANDARD MODE <<<
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

            -- DRAWING
            mon.clear()
            mon.setTextScale(1)
            
            mon.setCursorPos(1, 1)
            mon.setTextColor(colors.red)
            mon.write("-- BLOOD MONITORING SYSTEM --")
            
            local percent = 0
            if totalMax > 0 then percent = (currentAmount / totalMax) * 100 end
            
            local L, V = 12, 10 
            local amountB = currentAmount / 1000
            local maxB = totalMax / 1000

            mon.setCursorPos(3, 3)
            mon.write(string.format("%-"..L.."s %"..V.."s", "Tanks:", tostring(#tanks)))
            
            mon.setCursorPos(3, 4)
            mon.write(string.format("%-"..L.."s %"..V.."s B", "Current:", formatNumber(amountB)))
            
            mon.setCursorPos(3, 5)
            mon.write(string.format("%-"..L.."s %"..V.."s B", "Max Cap:", formatNumber(maxB)))
            
            mon.setCursorPos(3, 6)
            mon.write(string.format("%-"..L.."s %"..V..".1f%%", "Fill:", percent))
            
            drawBar(percent)

            -- Vitals Grid
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
            
            -- Print to terminal
            term.clear()
            term.setCursorPos(1,1)
            print("Status: RUNNING")
            print("Tanks: " .. #tanks)
            print("Current: " .. math.floor(amountB) .. " B")
        end
    end) -- End pcall

    if not status then
        print("CRASH ERROR: " .. tostring(err))
        mon.clear()
        mon.setCursorPos(1,1)
        mon.write("SCRIPT CRASHED!")
        mon.setCursorPos(1,2)
        mon.write("See Terminal.")
    end

    sleep(2) 
end