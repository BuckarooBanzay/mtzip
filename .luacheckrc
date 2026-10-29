globals = {
	"mtzip"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"core",
	"vector", "ItemStack",
	"dump", "dump2",
	"VoxelArea",

	-- testing
	"mtt"
}
