local common, crc32 = ...

local ZippedFile = {}
local ZippedFile_mt = { __index = ZippedFile }

local function zip(file)
    local self = {
        entries = {},
        headers = {},
        file = file
    }
    return setmetatable(self, ZippedFile_mt)
end

local function write_file(file, filename, data)
    local compressed = false
    local date, time = common.toDosTime(os.date("*t"))

    local uncompressed_size = #data
    if uncompressed_size > 10 then
        compressed = true
        data = minetest.compress(data, "deflate")
    end
    local compressed_size = #data
    file:write(common.lfh_sig)
    file:write(0x0A, 0x00) -- Version needed to extract (minimum)
    file:write(0x00, 0x00) -- General purpose bit flag

    if compressed then
        file:write(0x08, 0x00)
    else
        file:write(0x00, 0x00)
    end

    file:write(common.write_uint16(time)) --File last modification time
    file:write(common.write_uint16(date)) --File last modification date

    -- TODO: 4b crc32
    -- TODO: 4b compressed size
    -- TODO: 4b uncompressed size

    file:write(common.write_uint16(#filename)) -- File name length (n)
    file:write(0x00, 0x00) -- Extra field length (m)
    file:write(filename)

    file:write(data)

    return {
        -- header-data
    }
end

local function write_cd(file, header_data)
    -- TODO
end

local function write_eocd(file, count)
end

function ZippedFile:add(filename, data)
    self.entries[filename] = data
    self.headers[filename] = write_file(self.file, filename, data)
end

function ZippedFile:close()
    -- TODO: write headers/data
end

return zip