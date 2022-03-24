require("mineunit")

mineunit("core")
mineunit("default/functions")

sourcefile("init")

describe("mtzip.common", function()
	it("common smoketests", function()
		assert.not_nil(mtzip.common)
		assert.equals("table", type(mtzip.common))
	end)

    it("timestamp parsing", function()
        local date = 21621
        local time = 23636
        local o = mtzip.common.fromDosTime(date, time)

        local d2, t2 = mtzip.common.toDosTime(o)
        assert.equals(date, d2)
        assert.equals(time, t2)
    end)
end)