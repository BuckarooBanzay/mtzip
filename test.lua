
local f = io.open("out.zip")

print("Test: " .. f:read(1))

print("Size: " .. f:seek("end"))

