-- =============================================
-- CONFIGURATION
-- =============================================
-- Fallback capacity if a tank doesn't report its own size (e.g. standard drums)
local FALLBACK_CAPACITY = 16000 

-- Where the vital list starts (Row 11 gives space for the blood UI)
local VITALS_START_Y = 11 
-- How wide each villager column is (e.g., "V1: [ALIVE]" is ~12 chars)
local COL_WIDTH = 14 

-- =============================================
-- PERIPHERAL SETUP
-- =============================================
local mon = peripheral.find("monitor")
-- We find detectors immediately
local detectors = { peripheral.find("environment_detector") }

if not mon then error("Error: Monitor not found!") end

-- Sort detectors by name to ensure "Villager 1" stays at position 1
table.sort(detectors, function(a, b) 
    return peripheral.getName(a) < peripheral.getName(b) 
end)

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- Find all tanks (generic and specific) and remove duplicates
local function findUniqueTanks()
    local foundTanks = {}
    local seenNames = {}

    local function addTanks(typeStr)
        local periphs = { peripheral.find(typeStr) }
        for _, p in ipairs(periphs) do
            local name = peripheral.getName(p)
            if not seenNames[name] then
                seenNames[name] = true
                table.insert(foundTanks, p)
            end
        end
    end

    -- Add generic fluid storage
    addTanks("fluid_storage")
    -- Add specific Mekanism types (Dynamic Valves are distinct from Tanks)
    addTanks("mekanism:dynamic_tank")
    addTanks("mekanism:dynamic_valve")
    
    return foundTanks
end

local function formatNumber(n)
    -- Formats a number with commas (e.g., 10000 -> 10,000)
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function drawBar(percent)
    local w, h = mon.getSize()
    local barWidth = w - 2
    local filledWidth = math.floor((percent / 100) * barWidth)
    
    -- Limit filledWidth to barWidth (prevents overflow on >100%)
    if filledWidth > barWidth then filledWidth = barWidth end
    
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

    -- --- PART 1: FLUID LOGIC ---
    -- We scan for tanks every loop in case you break/place blocks
    local tanks = findUniqueTanks()
    
    local currentAmount = 0
    local totalMax = 0
    
    for _, tank in ipairs(tanks) do
        local tankInfoFound = false
        
        -- Method 1: Generic peripheral.call("tanks") - Standard CC
        -- This works for most basic mods
        if tank.tanks then 
            local success, data = pcall(tank.tanks)
            if success and data and #data > 0 then
                for _, tInfo in pairs(data) do
                     currentAmount = currentAmount + (tInfo.amount or 0)
                     totalMax = totalMax + (tInfo.capacity or FALLBACK_CAPACITY)
                     tankInfoFound = true
                end
            end
        end

        -- Method 2: Mekanism Specific (getTanks, getTankLevel, getTankCapacity)
        -- Mekanism valves often don't work with Method 1, so we force this check if Method 1 found nothing.
        if not tankInfoFound and tank.getTanks then
            -- Mekanism usually reports the number of internal tanks
            local success, count = pcall(tank.getTanks)
            if success and type(count) == "number" and count > 0 then
                for i = 1, count do
                     local lvl = 0
                     if tank.getTankLevel then lvl = tank.getTankLevel(i) end
                     
                     local cap = 0
                     if tank.getTankCapacity then cap = tank.getTankCapacity(i) end
                     
                     -- If capacity is 0, it might be an issue, but usually Dynamic Tanks report correctly here
                     if cap > 0 then
                        currentAmount = currentAmount + lvl
                        totalMax = totalMax + cap
                        tankInfoFound = true
                     end
                end
            end
        end

        -- Method 3: Simple getCapacity/getAmount (Older mods or simple blocks)
        if not tankInfoFound then
            local cap = 0
            if tank.getCapacity then cap = tank.getCapacity() end
            
            local amt = 0
            if tank.getAmount then amt = tank.getAmount() 
            elseif tank.getStored then 
                 local s = tank.getStored()
                 -- Handle if getStored returns a table or number
                 if type(s) == "table" then amt = s.amount or 0 else amt = s or 0 end
            end
            
            if cap > 0 then
                totalMax = totalMax + cap
                currentAmount = currentAmount + amt
                tankInfoFound = true
            end
        end

        -- Fallback: If we still have no info
        if not tankInfoFound then
            -- We ONLY add fallback capacity if it's NOT a Mekanism block.
            -- Mekanism blocks that fail to read are usually just structural wall blocks
            -- and adding capacity for them creates "ghost" tanks.
            local name = peripheral.getName(tank)
            if not name:find("mekanism") then
                totalMax = totalMax + FALLBACK_CAPACITY
            end
        end
    end

    -- Avoid division by zero if no tanks are connected
    if totalMax == 0 then totalMax = 1 end

    -- --- PART 2: VITALS SCANNING ---
    local vitalsData = {}
    local alarmTriggered = false
    
    for i, d in ipairs(detectors) do
        local entities = d.scanEntities(4)
        local alive = false
        
        if entities then
            for _, e in pairs(entities) do
                -- Check for Unemployed villager or just "Villager" depending on mod
                if e.name == "Unemployed" or e.name == "Villager" then
                    alive = true
                    break
                end
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
    
    if #tanks > 0 then
        local percent = (currentAmount / totalMax) * 100
        -- Increased V from 7 to 10 to handle large Dynamic Tank numbers
        local L, V = 12, 10 
        
        -- Formatting helper to handle Buckets (divide by 1000)
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
        
        -- Label: "V1:", "V2:", etc.
        mon.setTextColor(colors.white)
        mon.write("V" .. v.id .. ":")
        
        -- Status: [OK] or [DEAD]
        if v.isAlive then
            mon.setTextColor(colors.green)
            mon.write("[OK]")
        else
            mon.setTextColor(colors.red)
            mon.write("[DEAD]")
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