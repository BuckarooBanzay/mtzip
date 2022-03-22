local common, crc32 = ...

local ZippedFile = {}
local ZippedFile_mt = { __index = ZippedFile }

local function zip(file)
    local self = {
        entries = {},
        file = file
    }
    return setmetatable(self, ZippedFile_mt)
end

function ZippedFile:add(filename, data)
    self.entries[filename] = data
end

function ZippedFile:close()
    -- TODO: write headers/data
end

return zip