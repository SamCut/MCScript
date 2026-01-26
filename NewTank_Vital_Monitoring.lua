-- Dynamic Tank Monitor
-- Uses specific valve methods: getStored() and getTankCapacity()

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
    local names = peripheral.getNames()
    for _, name in ipairs(names) do
        if name:find("valve") or name:find("dynamic") or name:find("tank") then
            return name
        end
    end
    return nil
end

-- Main Logic
local output = term.current()
if monitorSide and peripheral.isPresent(monitorSide) then
    output = peripheral.wrap(monitorSide)
    output.setTextScale(1)
end

local function getTankData(p)
    local data = { 
        name = "Fluid", 
        amount = 0, 
        capacity = 0 
    }
    
    -- 1. Get Stored Amount (Primary Method)
    if p.getStored then
        local ok, res = pcall(p.getStored)
        if ok and type(res) == "number" then
            data.amount = res
        end
    end

    -- 2. Get Capacity (Primary Method)
    -- Prioritizing getTankCapacity as requested
    if p.getTankCapacity then
        local ok, res = pcall(p.getTankCapacity)
        if ok and type(res) == "number" then
            data.capacity = res
        end
    elseif p.getCapacity then 
        -- Fallback only if getTankCapacity is missing
        local ok, res = pcall(p.getCapacity)
        if ok and type(res) == "number" then
            data.capacity = res
        end
    end

    -- 3. Get Fluid Name (Metadata)
    -- getStored usually returns just a number, so we peek at getTankInfo
    -- ONLY to get the name string, without overwriting the numbers.
    if p.getTankInfo then
        local ok, info = pcall(p.getTankInfo)
        if ok and type(info) == "table" and info[1] then
            if info[1].name then 
                data.name = info[1].name 
            elseif info[1].rawName then
                data.name = info[1].rawName
            end
        end
    end

    return data
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
    output.write("Fluid: " .. data.name)
    
    output.setCursorPos(1, 4)
    output.write("Level: " .. formatNum(data.amount) .. " mB")
    
    output.setCursorPos(1, 5)
    output.write("Max:   " .. formatNum(data.capacity) .. " mB")

    -- Progress Bar
    local w, h = output.getSize()
    if data.capacity > 0 then
        local pct = data.amount / data.capacity
        -- Clamp percentage to 0-1 range to prevent errors
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
        output.write("Status: Capacity Unknown")
    end

    sleep(0.5)
end