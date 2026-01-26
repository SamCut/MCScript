-- Dynamic Tank Monitor (Multi-Tank Edition)
-- STRICT MODE: Uses ONLY getStored() and getTankCapacity()
-- TARGET: ALL CONNECTED "dynamicValve" PERIPHERALS
-- Aggregates data from multiple tanks into a single total.

local monitorSide = nil -- Change to "top", "left", etc. if using an external monitor

local function formatNum(n)
    if not n then return "0" end
    return tostring(n):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
end

local function clear(out)
    out.clear()
    out.setCursorPos(1,1)
end

-- Find ALL valves, not just one
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

-- Main Logic
local output = term.current()
if monitorSide and peripheral.isPresent(monitorSide) then
    output = peripheral.wrap(monitorSide)
    output.setTextScale(1)
end

local function getTankData(p)
    local data = { 
        name = "Unknown", 
        amount = 0, 
        capacity = 0 
    }
    
    -- 1. Get Stored Data
    if p.getStored then
        local ok, res = pcall(p.getStored)
        if ok and type(res) == "table" then
            if res.amount then data.amount = res.amount end
            if res.name then data.name = res.name end
        elseif ok and type(res) == "number" then
            data.amount = res
        end
    end

    -- 2. Get Capacity
    if p.getTankCapacity then
        local ok, res = pcall(p.getTankCapacity)
        if ok and type(res) == "number" then
            data.capacity = res
        end
    end

    return data
end

-- Setup
clear(output)
print("Initializing Monitor (Multi-Tank Mode)...")

local valveNames = findAllValves()
if #valveNames == 0 then
    print("Error: No 'dynamicValve' peripherals found.")
    print("Check modems are on the VALVE blocks.")
    print("Found: " .. textutils.serialize(peripheral.getNames()))
    return
end

-- Wrap all found tanks
local tanks = {}
for _, name in ipairs(valveNames) do
    local t = peripheral.wrap(name)
    if t then
        table.insert(tanks, { name = name, peripheral = t })
        print("Connected: " .. name)
    end
end
sleep(1)

-- Loop
while true do
    local totalAmount = 0
    local totalCapacity = 0
    local commonFluidName = "Empty"
    local activeTanks = 0

    -- Aggregate data from all tanks
    for _, tankObj in ipairs(tanks) do
        local data = getTankData(tankObj.peripheral)
        
        totalAmount = totalAmount + data.amount
        totalCapacity = totalCapacity + data.capacity
        
        -- Capture the first valid fluid name found
        if data.name ~= "Unknown" and commonFluidName == "Empty" then
            commonFluidName = data.name
        end
        
        -- Count as active if it has capacity (is formed)
        if data.capacity > 0 then
            activeTanks = activeTanks + 1
        end
    end
    
    clear(output)
    output.setCursorPos(1, 1)
    output.write("System Status: " .. activeTanks .. " Tank(s) Active")
    
    output.setCursorPos(1, 3)
    output.write("Fluid: " .. commonFluidName)
    
    output.setCursorPos(1, 4)
    output.write("Total: " .. formatNum(totalAmount) .. " mB")
    
    output.setCursorPos(1, 5)
    output.write("Max:   " .. formatNum(totalCapacity) .. " mB")

    -- Progress Bar
    local w, h = output.getSize()
    if totalCapacity > 0 then
        local pct = totalAmount / totalCapacity
        if pct > 1 then pct = 1 end
        if pct < 0 then pct = 0 end
        
        local barLen = w - 4
        local fillLen = math.floor(pct * barLen)
        
        output.setCursorPos(1, 7)
        output.write(string.format("Fill:  %.1f%%", pct * 100))
        
        output.setCursorPos(2, 8)
        output.write("[")
        if output.setTextColor then output.setTextColor(colors.lime) end
        output.write(string.rep("|", fillLen))
        if output.setTextColor then output.setTextColor(colors.gray) end
        output.write(string.rep("-", barLen - fillLen))
        if output.setTextColor then output.setTextColor(colors.white) end
        output.write("]")
    else
        output.setCursorPos(1, 7)
        output.write("Status: Total Capacity 0")
    end

    sleep(0.5)
end