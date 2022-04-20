require("mineunit")

mineunit("core")
mineunit("default/functions")

sourcefile("init")

describe("mtzip.crc32", function()
	it("crc smoketests", function()
		assert.not_nil(mtzip.crc32)
		assert.equals("function", type(mtzip.crc32))
	end)

	it("creates valid checksums", function()
		local crc = mtzip.crc32("teststr")
		assert.equals(615670416, crc)
	end)
end)

