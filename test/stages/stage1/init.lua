print("Stage 1: creating a zip file")

local f = io.open(minetest.get_worldpath() .. "/stage1.zip", "w")
local z = mtzip.zip(f)

z:add("test.txt", "abcdefghijklmnopqrstuvwxyz")
z:close()


minetest.request_shutdown("success")