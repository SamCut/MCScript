-- Dynamic Tank Monitor
-- STRICT MODE: Uses ONLY getStored() and getTankCapacity()
-- TARGET: VALVES ONLY (Ignores Tank/Casing blocks)

local tankName = "dynamic_valve_0" -- Default
local monitorSide = nil -- Change to "top", "left", etc. if using an external monitor

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
    -- STRICT SEARCH: Only look for "valve" to ensure we ignore the tank casing
    for _, name in ipairs(names) do
        if name:find("valve") then
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
        name = "Unknown", 
        amount = 0, 
        capacity = 0 
    }
    
    -- 1. Get Stored Data
    -- User confirmed getStored() returns {name="...", amount=...}
    if p.getStored then
        local ok, res = pcall(p.getStored)
        if ok and type(res) == "table" then
            if res.amount then data.amount = res.amount end
            if res.name then data.name = res.name end
        elseif ok and type(res) == "number" then
            -- Just in case it returns a plain number
            data.amount = res
        else
            -- Debug output if it fails
            data.debug_stored_err = tostring(res)
        end
    else
        data.debug_stored_err = "Method missing"
    end

    -- 2. Get Capacity
    -- User confirmed getTankCapacity() exists and has value
    if p.getTankCapacity then
        local ok, res = pcall(p.getTankCapacity)
        if ok and type(res) == "number" then
            data.capacity = res
        else
            data.debug_cap_err = tostring(res)
        end
    else
        data.debug_cap_err = "Method missing"
    end

    return data
end

-- Setup
clear(output)
print("Initializing Monitor (Strict Valve Mode)...")
local pName = findPeripheral()

if not pName then
    print("Error: No 'valve' peripheral found.")
    print("Please ensure the modem is on the VALVE block.")
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

    -- Debug info if methods failed
    if data.debug_stored_err or data.debug_cap_err then
        output.setTextColor(colors.red)
        output.setCursorPos(1, 10)
        output.write("DEBUG ERRORS:")
        if data.debug_stored_err then
            output.setCursorPos(1, 11)
            output.write("getStored: " .. data.debug_stored_err)
        end
        if data.debug_cap_err then
            output.setCursorPos(1, 12)
            output.write("getCap: " .. data.debug_cap_err)
        end
        output.setTextColor(colors.white)
    end

    -- Progress Bar
    local w, h = output.getSize()
    if data.capacity > 0 then
        local pct = data.amount / data.capacity
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
    end

    sleep(0.5)
end