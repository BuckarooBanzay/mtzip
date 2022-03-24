local MP = minetest.get_modpath(minetest.get_current_modname())
local bootstrap = loadfile(MP.."/bootstrap.lua")()
mtzip = bootstrap(MP)