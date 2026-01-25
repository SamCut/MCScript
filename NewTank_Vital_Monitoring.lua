-- =============================================
-- CONFIGURATION
-- =============================================
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
-- HELPER FUNCTIONS
-- =============================================

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
-- DEBUG / DIAGNOSTIC SCREEN
-- =============================================
-- Draws a raw list of what the computer actually sees
local function drawDebugScreen(candidates)
    mon.clear()
    mon.setTextScale(0.5) -- Small text to fit more info
    mon.setCursorPos(1,1)
    mon.setTextColor(colors.orange)
    mon.write("DIAGNOSTIC MODE - NO VALID TANKS")
    mon.setCursorPos(1,2)
    mon.setTextColor(colors.white)
    mon.write("Checking connections...")
    
    local y = 4
    if #candidates == 0 then
        mon.setCursorPos(1, y)
        mon.setTextColor(colors.red)
        mon.write("NO PERIPHERALS FOUND!")
        mon.setCursorPos(1, y+1)
        mon.write("Check Wired Modems (Must be RED)")
    else
        for _, info in ipairs(candidates) do
            mon.setCursorPos(1, y)
            if info.isTank then
                mon.setTextColor(colors.green)
            else
                mon.setTextColor(colors.gray)
            end
            
            -- Format: "name | type | Cap: 1000"
            local str = string.format("%s | %s | Cap:%s", info.name, info.type, info.cap or "?")
            mon.write(str)
            
            y = y + 1
            if y > 30 then break end -- Stop if screen full
        end
    end
end

-- =============================================
-- TANK SCANNING LOGIC
-- =============================================
local function scanAndReadTanks()
    local allNames = peripheral.getNames()
    local validTanks = {} -- Tanks that have fluid data
    local debugList = {}  -- Everything we found (for debug screen)
    
    local totalAmt = 0
    local totalCap = 0
    
    for _, name in ipairs(allNames) do
        -- Skip standard non-tank peripherals to clean up debug list
        if not name:find("monitor") and 
           not name:find("detector") and 
           not name:find("modem") and 
           name ~= "back" and name ~= "front" and name ~= "top" and name ~= "bottom" then
            
            local p = peripheral.wrap(name)
            local pType = peripheral.getType(p)
            local tCap, tAmt = 0, 0
            local readSuccess = false

            -- ATTEMPT 1: Standard .tanks()
            if not readSuccess and p.tanks then 
                local success, data = pcall(p.tanks)
                if success and data and #data > 0 then
                    for _, tInfo in pairs(data) do
                         tAmt = tAmt + (tInfo.amount or 0)
                         tCap = tCap + (tInfo.capacity or 0)
                    end
                    readSuccess = true
                end
            end

            -- ATTEMPT 2: Mekanism .getTanks()
            if not readSuccess and p.getTanks then
                local success, result = pcall(p.getTanks)
                if success then
                    if type(result) == "table" then
                        for _, tData in pairs(result) do
                            tAmt = tAmt + (tData.amount or 0)
                            tCap = tCap + (tData.capacity or 0)
                        end
                        readSuccess = true
                    elseif type(result) == "number" and result > 0 then
                        for i = 1, result do
                            local lvl = 0
                            if p.getTankLevel then lvl = p.getTankLevel(i) or 0 end
                            local cap = 0
                            if p.getTankCapacity then cap = p.getTankCapacity(i) or 0 end
                            tAmt = tAmt + lvl
                            tCap = tCap + cap
                        end
                        readSuccess = true
                    end
                end
            end
            
            -- ATTEMPT 3: getFluidTankProperties (Older versions)
            if not readSuccess and p.getFluidTankProperties then
                local success, props = pcall(p.getFluidTankProperties)
                if success and type(props) == "table" then
                    for _, prop in pairs(props) do
                        local contents = prop.contents
                        if contents then tAmt = tAmt + (contents.amount or 0) end
                        tCap = tCap + (prop.capacity or 0)
                    end
                    readSuccess = true
                end
            end

            -- Store info for Debug Screen
            table.insert(debugList, {
                name = name,
                type = pType,
                cap = tCap,
                isTank = (tCap > 0)
            })

            -- Add to totals if it's a valid tank
            if tCap > 0 then
                totalAmt = totalAmt + tAmt
                totalCap = totalCap + tCap
                table.insert(validTanks, p)
            end
        end
    end
    
    return validTanks, totalAmt, totalCap, debugList
end

-- =============================================
-- MAIN LOOP
-- =============================================
print("Monitor running...")

while true do
    local w, h = mon.getSize()
    
    -- Scan everything
    local tanks, currentAmount, totalMax, debugList = scanAndReadTanks()
    
    if #tanks == 0 then
        -- >>> DIAGNOSTIC MODE <<<
        drawDebugScreen(debugList)
    else
        -- >>> STANDARD MODE <<<
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
    end

    sleep(2) 
end