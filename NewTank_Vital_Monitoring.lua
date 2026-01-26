-- =============================================
-- CONFIGURATION
-- =============================================
local VITALS_START_Y = 11 
local COL_WIDTH = 14 
local DEBUG_MODE = true -- Look at the computer terminal to see what it finds

-- FILTER: Ignore tanks smaller than this (in mB)
-- 4000 mB = 4 Buckets. This filters out pipes and machine buffers
-- Your Blood Pods are 16000 mB, so they will be detected.
local MIN_CAPACITY = 4000 

-- =============================================
-- PERIPHERAL SETUP
-- =============================================
local mon = peripheral.find("monitor")
local detectors = { peripheral.find("environment_detector") }

if not mon then error("Error: Monitor not found!") end

-- Sort detectors to keep Villager order consistent
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

-- =============================================
-- MAIN LOOP
-- =============================================
while true do
    local w, h = mon.getSize()

    -- --- PART 1: UNIVERSAL TANK DETECTION ---
    local currentAmount = 0
    local totalMax = 0
    local tankCount = 0
    
    if DEBUG_MODE then
        term.clear()
        term.setCursorPos(1,1)
        print("--- DEBUG: SCANNING PERIPHERALS ---")
    end

    -- Get list of ALL connected peripherals
    local allPeripherals = peripheral.getNames()

    for _, pName in ipairs(allPeripherals) do
        -- Skip known non-tank peripherals to save time/errors
        local pType = peripheral.getType(pName)
        if pType ~= "monitor" and pType ~= "modem" and 
           pType ~= "computer" and pType ~= "environment_detector" and
           pType ~= "drive" and pType ~= "printer" then
            
            -- Wrap the peripheral
            local p = peripheral.wrap(pName)
            
            -- Check if it has a .tanks() method (is it a fluid container?)
            if p and p.tanks then
                -- Wrap in pcall to safely read data without crashing if a block is glitchy
                local success, tankData = pcall(p.tanks)
                
                if success and tankData then
                    -- Some blocks have multiple internal tanks
                    for _, info in pairs(tankData) do
                        local cap = info.capacity or 0
                        local amt = info.amount or 0
                        
                        -- FILTER: Only count if capacity is > MIN_CAPACITY (4 Buckets)
                        -- This ignores pipes/machines that cause the "fluctuating cap" bug
                        if cap >= MIN_CAPACITY then
                            currentAmount = currentAmount + amt
                            totalMax = totalMax + cap
                            tankCount = tankCount + 1
                            
                            if DEBUG_MODE then
                                print(string.format("Found: %s (%d/%d mB)", pName, amt, cap))
                            end
                        end
                    end
                end
            end
        end
    end

    -- Fallback to avoid division by zero
    if totalMax == 0 then totalMax = 1 end

    -- --- PART 2: VITALS SCANNING ---
    local vitalsData = {}
    local alarmTriggered = false
    
    for i, d in ipairs(detectors) do
        local entities = d.scanEntities(4)
        local alive = false
        
        for _, e in pairs(entities) do
            if e.name == "Unemployed" or e.name == "Villager" then
                alive = true
                break
            end
        end

        if not alive then alarmTriggered = true end
        table.insert(vitalsData, { id = i, isAlive = alive })
    end

    redstone.setOutput("back", alarmTriggered)

    -- --- PART 3: MONITOR DISPLAY ---
    mon.clear()
    mon.setTextScale(1)
    
    -- Header
    mon.setCursorPos(1, 1)
    mon.setTextColor(colors.red)
    mon.write("-- BLOOD MONITORING SYSTEM --")
    
    if tankCount > 0 then
        local percent = (currentAmount / totalMax) * 100
        local L, V = 15, 7
        
        -- Convert to Buckets (divide by 1000)
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
        mon.setCursorPos(3, 5)
        mon.setTextColor(colors.gray)
        mon.write("See Terminal for Debug")
    end

    -- Vitals Grid
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.yellow)
    mon.setCursorPos(1, 9) 
    mon.write(string.rep("-", w))
    mon.setCursorPos(2, 10)
    mon.write("POD STATUS:")

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