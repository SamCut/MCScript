-- Deep Peripheral Inspector
-- Use this to "prove" what data is available on the wire.

local function clear()
    term.clear()
    term.setCursorPos(1,1)
end

clear()
print("--- Peripheral Deep Scan ---")

-- 1. LIST PHASE
local peripList = peripheral.getNames()
if #peripList == 0 then
    print("Error: No peripherals detected.")
    print("Check: Is the modem red? Is it connected via cable?")
    return
end

print("Select a peripheral to inspect:")
for i, name in ipairs(peripList) do
    local pType = peripheral.getType(name)
    print(string.format("%d. %s (%s)", i, name, pType))
end

write("\nEnter number: ")
local input = read()
local num = tonumber(input)
local selectedName = peripList[num]

if not selectedName then
    print("Invalid selection.")
    return
end

-- 2. WRAP PHASE
local p = peripheral.wrap(selectedName)
if not p then
    print("Failed to connect to " .. selectedName)
    return
end

-- 3. METHOD DUMP
clear()
print("Inspecting: " .. selectedName)
print("Type: " .. peripheral.getType(selectedName))
print(string.rep("-", 20))

local methods = peripheral.getMethods(selectedName)
table.sort(methods)

print("Exposed Methods:")
textutils.tabulate(methods)

print(string.rep("-", 20))
print("Press [Enter] to probe data values...")
read()

-- 4. DATA PROBE PHASE
-- We will try to run every method that looks like a data getter
-- and print the raw result to screen/file.

print("--- PROBING DATA ---")
local probed = false

-- List of patterns to try executing safely
local safePatterns = {
    "^get", -- getStored, getCapacity, etc.
    "^list", -- list methods
    "^tanks", -- mekanism specific
    "^info" -- generic info
}

for _, method in ipairs(methods) do
    local isSafe = false
    for _, pattern in ipairs(safePatterns) do
        if method:find(pattern) then isSafe = true break end
    end

    if isSafe then
        probed = true
        write(method .. "(): ")
        
        -- Attempt to call it
        local status, result = pcall(p[method])
        
        if status then
            if type(result) == "table" then
                -- formatting table for single line readability
                print(textutils.serialize(result, {compact=true}))
            else
                print(tostring(result))
            end
        else
            print("ERROR (Call failed)")
        end
        sleep(0.1) -- scroll prevention
    end
end

if not probed then
    print("No obvious 'getter' methods found to probe.")
end

print(string.rep("-", 20))
print("Scan Complete.")