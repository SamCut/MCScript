-- Dynamic Tank Monitor & Inspector
-- Run this on your Computer or Advanced Computer

local function clear()
    term.clear()
    term.setCursorPos(1,1)
end

-- 1. SCANNING PHASE
clear()
print("--- Peripheral Scanner ---")
print("Scanning wired network...")

local peripList = peripheral.getNames()
local tankName = nil
local candidates = {}

print("\nConnected Peripherals:")
for _, name in ipairs(peripList) do
    local type = peripheral.getType(name)
    print(" - " .. name .. " (" .. type .. ")")
    
    -- Look for keywords common to Mekanism or other tanks
    if name:find("dynamic") or name:find("valve") or name:find("tank") then
        table.insert(candidates, name)
    end
end

print("\n--------------------------")

-- 2. SELECTION PHASE
if #candidates == 1 then
    tankName = candidates[1]
    print("Auto-detected tank: " .. tankName)
    print("Press [Enter] to accept, or type a different name:")
    local input = read()
    if input ~= "" then tankName = input end
elseif #candidates > 1 then
    print("Multiple likely candidates found:")
    for i, name in ipairs(candidates) do
        print(i .. ". " .. name)
    end
    write("Enter the name of the tank to monitor: ")
    tankName = read()
else
    print("No obvious tanks found.")
    write("Please enter the peripheral name manually: ")
    tankName = read()
end

local tank = peripheral.wrap(tankName)

if not tank then
    print("\nError: Could not connect to '" .. tankName .. "'")
    print("Check your wired modem connection.")
    return
end

-- 3. INSPECTION PHASE (Debugging Data)
clear()
print("--- Connected to: " .. tankName .. " ---")
print("Available Data Methods:")
local methods = peripheral.getMethods(tankName)
local methodStr = ""
for _, method in ipairs(methods) do
    -- Highlight useful methods
    if method:find("Stored") or method:find("Capacity") or method:find("tanks") then
        methodStr = methodStr .. "[" .. method .. "] "
    else
        methodStr = methodStr .. method .. " "
    end
end
print(methodStr)
print("\n(Press any key to start monitoring...)")
os.pullEvent("key")

-- 4. MONITORING PHASE
while true do
    clear()
    print("--- Tank Monitor: " .. tankName .. " ---")
    print("Press Ctrl+T to exit")
    print("")

    local stored = 0
    local capacity = 0
    local fluidName = "Empty"
    local rawData = "No standard data found"

    -- Try typical Mekanism methods
    -- Method 1: Modern Mekanism (tanks() returns a table)
    if tank.tanks then
        local t = tank.tanks()
        if t and t[1] then
            stored = t[1].amount
            capacity = t[1].capacity or 0 -- sometimes capacity is separate
            fluidName = t[1].name
            rawData = textutils.serialize(t[1])
        end
    end

    -- Method 2: Direct access (getStored / getCapacity)
    if tank.getStored then
        stored = tank.getStored()
    end
    if tank.getCapacity then
        capacity = tank.getCapacity()
    end
    
    -- Method 3: Old school (getTankInfo)
    if (stored == 0) and tank.getTankInfo then
        local info = tank.getTankInfo()
        if info and info[1] then
            stored = info[1].amount
            capacity = info[1].capacity
            fluidName = info[1].name
        end
    end

    -- DISPLAY LOGIC
    print("Fluid Type: " .. fluidName)
    
    -- Format numbers with commas for readability
    local function formatNum(n)
        return tostring(n):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
    end

    print("Stored:     " .. formatNum(stored) .. " mB")
    print("Capacity:   " .. formatNum(capacity) .. " mB")

    if capacity > 0 then
        local percent = (stored / capacity) * 100
        print("Fill Level: " .. math.floor(percent * 10) / 10 .. "%")
        
        -- Draw Progress Bar
        local w, h = term.getSize()
        local barWidth = w - 4
        local filled = math.floor((stored / capacity) * barWidth)
        
        term.setCursorPos(2, 8)
        write("[")
        term.setTextColor(colors.lime)
        write(string.rep("|", filled))
        term.setTextColor(colors.gray)
        write(string.rep("-", barWidth - filled))
        term.setTextColor(colors.white)
        write("]")
    else
        print("\nWarning: Capacity is 0 or unreadable.")
        print("Try inspecting methods listed earlier.")
    end

    sleep(0.5)
end