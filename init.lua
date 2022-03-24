local MP = minetest.get_modpath(minetest.get_current_modname())
local common = loadfile(MP.."/common.lua")()
local crc32 = loadfile(MP.."/crc32.lua")()

mtzip = {
    crc32 = crc32,
    common = common,
    unzip = loadfile(MP.."/unzip.lua")(common, crc32),
    zip = loadfile(MP.."/zip.lua")(common, crc32)
}