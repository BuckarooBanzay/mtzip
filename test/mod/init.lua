
print("Test: reading a simple zip file")
local filename = minetest.get_modpath("mtzip") .. "/spec/out2.zip"
local f = io.open(filename)
local z = mtzip.unzip(f)
local data = z:get("crc32.lua", true)
f:close()
assert(#data == 5996, "content-length mismatch")

print("Test: reading a bx-exported zip file")
filename = minetest.get_modpath("mtzip") .. "/spec/scifi_lamp_small.zip"
f = io.open(filename)
z = mtzip.unzip(f)
assert(z:get_entry("schema.json") ~= nil, "schema.json not found")
assert(z:get_entry("schemapart_0_0_0.json") ~= nil, "schemapart_0_0_0.json not found")
data = z:get("mods.json", true)
local mods = minetest.parse_json(data)
assert(#mods == 1, "mods.json list count wrong")
f:close()

print("Test: creating a zip file")
f = io.open(minetest.get_worldpath() .. "/stage1.zip", "w")
z = mtzip.zip(f)
z:add("test.txt", "abcdefghijklmnopqrstuvwxyz")
z:close()

-- done
minetest.request_shutdown("success")