-- Smart Dynamic Tank Monitor
-- Automatically adapts to the data structure returned by the tank.

local tankName = "dynamic_valve_0" -- Default, will auto-detect if not found
local monitorSide = nil -- Change to "top", "left", etc. if using an external monitor

-- Utilities
local function formatNum(n)
    if not n then return "0" end
    return tostring(n):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
end

local function clear(out)
    out.clear()
    out.setCursorPos(1,1)
end

local function findPeripheral()
    -- specific search for valve or tank
    local names = peripheral.getNames()
    for _, name in ipairs(names) do
        if name:find("valve") or name:find("dynamic") or name:find("tank") then
            return name
        end
    end
    return nil -- failed
end

-- Main Logic
local output = term.current()
if monitorSide and peripheral.isPresent(monitorSide) then
    output = peripheral.wrap(monitorSide)
    output.setTextScale(1) -- adjust if needed
end

local function getTankData(p)
    -- Try specific Mekanism/Fluid variations
    local info = nil
    
    -- Attempt 1: getTankInfo() (Standard)
    if p.getTankInfo then
        local status, res = pcall(p.getTankInfo)
        if status and res then info = res end
    end

    -- Attempt 2: getTankInfo(1) (Indexed access)
    if not info and p.getTankInfo then
        local status, res = pcall(p.getTankInfo, 1)
        if status and res then info = res end
    end
    
    -- Attempt 3: tanks() (Newer Mekanism)
    if not info and p.tanks then
        local status, res = pcall(p.tanks)
        if status and res then info = res end
    end

    -- Normalize Data
    -- We want: { name="Water", amount=1000, capacity=2000 }
    local normalized = { name = "Empty", amount = 0, capacity = 0 }

    if not info then return normalized end

    -- Unwrap if it's a table of tables (standard getTankInfo returns { [1]={...} })
    local dataNode = info
    if info[1] and type(info[1]) == "table" then
        dataNode = info[1]
    end

    -- Dynamic Key Search (Fixes "calling it wrong" by finding the actual keys)
    if type(dataNode) == "table" then
        -- Find Amount
        if dataNode.amount then normalized.amount = dataNode.amount
        elseif dataNode.stored then normalized.amount = dataNode.stored
        elseif dataNode.qty then normalized.amount = dataNode.qty
        elseif dataNode.level then normalized.amount = dataNode.level
        end

        -- Find Capacity
        if dataNode.capacity then normalized.capacity = dataNode.capacity
        elseif dataNode.limit then normalized.capacity = dataNode.limit
        elseif dataNode.max then normalized.capacity = dataNode.max
        end

        -- Find Name
        if dataNode.name then normalized.name = dataNode.name
        elseif dataNode.fluid then normalized.name = dataNode.fluid
        elseif dataNode.rawName then normalized.name = dataNode.rawName
        elseif dataNode.label then normalized.name = dataNode.label
        end
    end

    return normalized
end

-- Setup
clear(output)
print("Initializing Monitor...")
local pName = findPeripheral()

if not pName then
    print("Error: No tank/valve found.")
    print("Please connect a modem to the Valve.")
    return
end

local tank = peripheral.wrap(pName)
print("Connected to: " .. pName)
sleep(1)

-- Loop
while true do
    local data = getTankData(tank)
    
    clear(output)
    output.setCursorPos(1, 1)
    output.write("Tank: " .. pName)
    
    output.setCursorPos(1, 3)
    output.write("Fluid: " .. (data.name or "Empty"))
    
    output.setCursorPos(1, 4)
    output.write("Level: " .. formatNum(data.amount) .. " mB")
    
    output.setCursorPos(1, 5)
    output.write("Max:   " .. formatNum(data.capacity) .. " mB")

    -- Progress Bar
    local w, h = output.getSize()
    if data.capacity > 0 then
        local pct = data.amount / data.capacity
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
        output.write("Status: Empty / Offline")
    end

    sleep(0.5)
end