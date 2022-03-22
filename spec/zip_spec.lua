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

        z:add("test.txt", "abcdefghijklmnopqrstuvwxyz")
        z:close()
    end)
end)