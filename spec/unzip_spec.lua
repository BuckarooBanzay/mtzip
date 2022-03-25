require("mineunit")

mineunit("core")
mineunit("default/functions")

sourcefile("init")

describe("mtzip.unzip", function()
	it("unzip smoketests", function()
		assert.not_nil(mtzip.unzip)
		assert.equals("function", type(mtzip.unzip))
	end)

	it("extracts the uncompressed test-archive", function()
		local f = io.open("spec/out.zip")
		assert.not_nil(f)

		local z = mtzip.unzip(f)
		assert.not_nil(z)
		assert.equals("table", type(z))
		assert.equals("function", type(z.get))
		assert.equals("function", type(z.list))

		local cd = z:get_entry("test.txt")
		assert.not_nil(cd)
		assert.equals(5, cd.uncompressed_size)

		local data = z:get("test.txt", true)
		assert.not_nil(data)
		assert.equals("test\n", data)

		data = z:get("xyz.txt", true)
		assert.not_nil(data)
		assert.equals("abc\n", data)

		local list = z:list()
		assert.not_nil(list)
		assert.equals(2, #list)
	end)

	--[[ Does not work without minetest.compress/uncompress
	it("extracts the compressed test-archive", function()
		local f = io.open("spec/out2.zip")
		assert.not_nil(f)

		local z = mtzip.unzip(f)
		local cd = z:get_entry("crc32.lua")
		assert.equals(5996, cd.uncompressed_size)

		local data = z:get("crc32.lua", true)
		assert.equals(5996, #data)
	end)
	--]]
end)

