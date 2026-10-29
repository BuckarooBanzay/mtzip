local MP = core.get_modpath(core.get_current_modname())

local includes = {
    "common.lua",
    "crc32.lua",
    "unzip.lua",
    "zip.lua"
}

for _, filename in ipairs(includes) do
    dofile(MP .. "/" .. filename)
    if core.register_mapgen_script then
        core.register_mapgen_script(MP .. "/" .. filename)
    end
end

if core.get_modpath("mtt") then
    dofile(MP .. "/mtt.lua")
    if core.register_mapgen_script then
        core.register_mapgen_script(MP .. "/mtt.async.lua")
    end
end