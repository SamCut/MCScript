rednet.open("back")
local targetID = 12
local myPassword = "apple"

print("Remote Command:")
local cmd = read()

-- Sending as 'password:command'
rednet.send(targetID, myPassword .. ":" .. cmd)
print("Sent!")