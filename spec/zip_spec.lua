require("mineunit")

mineunit("core")
mineunit("default/functions")

sourcefile("init")

describe("mtzip.zip", function()
	it("zip smoketests", function()
		assert.not_nil(mtzip.zip)
		assert.equals("function", type(mtzip.zip))
	end)

	it("creates an archive", function()
		local f = io.open("spec/tmp.zip", "w")
		assert.not_nil(f)

		local z = mtzip.zip(f)
		assert.not_nil(z)

		-- TODO: larger size does not work without minetest.compress/uncompress
		z:add("test.txt", "test123")
		z:close()
	end)
end)