
local pos = { x=0, y=0, z=0 }
mtt.emerge_area(pos, pos)

mtt.register("timestamp parsing", function(callback)
    local date = 21621
    local time = 23636
    local o = mtzip.fromDosTime(date, time)

    local d2, t2 = mtzip.toDosTime(o)
    assert(date == d2)
    assert(time == t2)
    callback()
end)

mtt.register("creates valid checksums", function(callback)
    local crc = mtzip.crc32("teststr")
    assert(615670416 == crc)
    callback()
end)

mtt.register("reading a simple zip file", function(callback)
    local filename = core.get_modpath("mtzip") .. "/test/out2.zip"
    local f = io.open(filename, "rb")
    local z = mtzip.unzip(f)
    local data = z:get("crc32.lua", true)
    f:close()
    assert(#data == 5996, "content-length mismatch")
    callback()
end)

mtt.register("reading a bx-exported zip file", function(callback)
    local filename = core.get_modpath("mtzip") .. "/test/scifi_lamp_small.zip"
    local f = io.open(filename, "rb")
    local z = mtzip.unzip(f)
    assert(z:get_entry("schema.json") ~= nil, "schema.json not found")
    assert(z:get_entry("schemapart_0_0_0.json") ~= nil, "schemapart_0_0_0.json not found")
    local data = z:get("mods.json", true)
    local mods = core.parse_json(data)
    assert(#mods == 1, "mods.json list count wrong")

    local list = z:list()
    assert(#list == 3)

    f:close()
    callback()
end)

local function roundtrip(opts, content)
    local filename = core.get_worldpath() .. "/roundtrip.zip"
    local f = assert(io.open(filename, "wb"))
    local z = mtzip.zip(f)
    assert(z:add("a.txt", content, opts))
    assert(z:add("b.txt", "second", opts))
    assert(z:add("empty.txt", "", opts))
    assert(z:close())
    f:close()

    f = assert(io.open(filename, "rb"))
    local uz, err = mtzip.unzip(f)
    assert(uz, err)
    local data, get_err = uz:get("a.txt", true)
    assert(data == content, get_err)
    assert(uz:get("b.txt", true) == "second")
    assert(uz:get("empty.txt", true) == "")
    assert(table.concat(uz:list(), ",") == "a.txt,b.txt,empty.txt")
    f:close()
end

mtt.register("zip roundtrip, compressed", function(callback)
    roundtrip(nil, string.rep("abcdefghijklmnopqrstuvwxyz", 100))
    callback()
end)

mtt.register("zip roundtrip, uncompressed", function(callback)
    roundtrip({ disable_compression = true }, "abcdefghijklmnopqrstuvwxyz")
    callback()
end)

mtt.register("dos time with odd seconds and old years", function(callback)
    for sec = 0, 59 do
        local d, t = mtzip.toDosTime({ year = 2024, month = 5, day = 17, hour = 13, min = 37, sec = sec })
        assert(d == math.floor(d) and t == math.floor(t))
        assert(mtzip.fromDosTime(d, t).sec == sec - (sec % 2))
    end
    local d = mtzip.toDosTime({ year = 1970, month = 1, day = 1, hour = 0, min = 0, sec = 0 })
    assert(mtzip.fromDosTime(d, 0).year == 1980)
    callback()
end)

mtt.register("compressed data is raw deflate (no zlib trailer)", function(callback)
    local filename = core.get_worldpath() .. "/raw.zip"
    local f = assert(io.open(filename, "wb"))
    local z = mtzip.zip(f)
    local content = "abcdefghijklmnopqrstuvwxyz"
    assert(z:add("x.txt", content))
    assert(z:close())
    f:close()

    f = assert(io.open(filename, "rb"))
    local uz = assert(mtzip.unzip(f))
    local expected = core.compress(content, "deflate", 9):sub(3, -5)
    assert(uz:get_entry("x.txt").compressed_size == #expected)
    f:close()
    callback()
end)

mtt.register("duplicate and ordered entries", function(callback)
    local filename = core.get_worldpath() .. "/dup.zip"
    local f = assert(io.open(filename, "wb"))
    local z = mtzip.zip(f)
    assert(z:add("a", "1"))
    assert(z:add("b", "2"))
    assert(z:add("a", "3"))
    assert(z:close())
    assert(not z:add("c", "4"), "add after close must fail")
    assert(not z:close(), "double close must fail")
    f:close()

    f = assert(io.open(filename, "rb"))
    local uz = assert(mtzip.unzip(f))
    assert(#uz:list() == 2)
    assert(uz:get("a", true) == "3")
    f:close()
    callback()
end)

mtt.register("zip with an archive comment", function(callback)
    local filename = core.get_worldpath() .. "/comment.zip"
    local f = assert(io.open(filename, "wb"))
    local z = mtzip.zip(f)
    assert(z:add("a.txt", "hello"))
    assert(z:close())
    f:close()

    -- patch the comment-length field and append a comment
    f = assert(io.open(filename, "rb"))
    local raw = f:read("*a")
    f:close()
    raw = raw:sub(1, -3) .. string.char(7, 0) .. "comment"
    f = assert(io.open(filename, "wb"))
    f:write(raw)
    f:close()

    f = assert(io.open(filename, "rb"))
    local uz, err = mtzip.unzip(f)
    assert(uz, err)
    assert(uz:get("a.txt", true) == "hello")
    f:close()
    callback()
end)

mtt.register("invalid archives are rejected", function(callback)
    local filename = core.get_worldpath() .. "/invalid.zip"
    local f = assert(io.open(filename, "wb"))
    f:write("tiny")
    f:close()

    f = assert(io.open(filename, "rb"))
    local uz, err = mtzip.unzip(f)
    assert(uz == nil and err)
    f:close()

    f = assert(io.open(filename, "wb"))
    f:write(string.rep("x", 100))
    f:close()

    f = assert(io.open(filename, "rb"))
    uz, err = mtzip.unzip(f)
    assert(uz == nil and err)
    f:close()
    callback()
end)

mtt.register("zip64 markers are rejected", function(callback)
    local filename = core.get_worldpath() .. "/zip64.zip"
    local f = assert(io.open(filename, "wb"))
    local z = mtzip.zip(f)
    assert(z:add("a.txt", "hello"))
    assert(z:close())
    f:close()

    f = assert(io.open(filename, "rb"))
    local raw = f:read("*a")
    f:close()
    -- set the cd-offset in the eocd to 0xffffffff
    raw = raw:sub(1, -7) .. string.rep(string.char(0xFF), 4) .. raw:sub(-2)
    f = assert(io.open(filename, "wb"))
    f:write(raw)
    f:close()

    f = assert(io.open(filename, "rb"))
    local uz, err = mtzip.unzip(f)
    assert(uz == nil and err:find("zip64"))
    f:close()
    callback()
end)
