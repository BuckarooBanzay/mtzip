
print("Stage 1: reading a zip file")

local filename = minetest.get_modpath("mtzip") .. "/spec/out2.zip"
local f = io.open(filename)
local z = mtzip.unzip(f)
local cd = z:get_entry("crc32.lua")
print(dump(cd))

local data = z:get("crc32.lua", true)
print("len: " .. #data)

print("Stage 2: creating a zip file")

local f = io.open(minetest.get_worldpath() .. "/stage1.zip", "w")
local z = mtzip.zip(f)

z:add("test.txt", "abcdefghijklmnopqrstuvwxyz")
z:close()


minetest.request_shutdown("success")