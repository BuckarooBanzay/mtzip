
local f = io.open("out.zip")

local size = f:seek("end")
print("Size: " .. size)

local function read_uint32(f)
	local data = f:read(4)
	return (
		string.byte(data,1) +
		(string.byte(data,2) * 256) +
		(string.byte(data,3) * 256 * 256) +
		(string.byte(data,4) * 256 * 256 * 256)
	)
end

local function read_uint16(f)
	local data = f:read(2)
	return string.byte(data,1) + (string.byte(data,2) * 256)
end

-- End of central directory record (EOCD)
local function read_eocd(f)
	f:seek("set", size - 22)
	local data = f:read(22)
	print("test: " .. string.byte(data,1))
	if string.byte(data,1) ~= 80 or string.byte(data,2) ~= 75 or string.byte(data,3) ~= 5 or string.byte(data,4) ~= 6 then
		return false, "invalid eocd signature"
	end

	f:seek("set", size - 10)
	local cd_size = read_uint32(f)
	local cd_offset = read_uint32(f)

	return true, {
		cd_size = cd_size,
		cd_offset = cd_offset
	}
end

-- Central directory file header
local function read_cd(f, size)
	local data = f:read(size)
	local version = read_uint16(f)
	return true, {
		version = version
	}
end

local success, result = read_eocd(f)
if success then
	print("Size: " .. result.cd_size .. " Offset: " .. result.cd_offset)
else
	print("error: " .. result)
	return
end

f:seek("set", result.cd_offset)
success, result = read_cd(f, result.cd_size)
if success then
	print("Version: " .. result.version)
else
	print("error: " .. result)
end
