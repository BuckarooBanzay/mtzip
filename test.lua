
local eocd_sig = string.char(80, 75, 5, 6)
local cd_sig = string.char(80, 75, 1, 2)

local function compare_bytes(b1, o1, b2, o2, len)
	for i=1,len do
		if b1:byte(i+o1) ~= b2:byte(i+o2) then
			return false
		end
	end

	return true
end

local function read_uint32(data, offset)
	return (
		string.byte(data,1+offset) +
		(string.byte(data,2+offset) * 256) +
		(string.byte(data,3+offset) * 256 * 256) +
		(string.byte(data,4+offset) * 256 * 256 * 256)
	)
end

local function read_uint16(data, offset)
	return (
		string.byte(data,1+offset) +
		(string.byte(data,2+offset) * 256)
	)
end

-- End of central directory record (EOCD)
local function read_eocd(data, offset)
	if not compare_bytes(data, offset, eocd_sig, 0, 4) then
		return false, "invalid eocd signature"
	end

	return true, {
		cd_size = read_uint32(data, offset+12),
		cd_offset = read_uint32(data, offset+16),
		cd_count = read_uint16(data, offset+8)
	}
end

-- Central directory file header
local function read_cd(data, offset)
	if not compare_bytes(data, offset, cd_sig, 0, 4) then
		return false, "invalid cd signature"
	end

	local name_len = read_uint16(data, offset+28)
	local extra_len = read_uint16(data, offset+30)
	local comment_len = read_uint16(data, offset+32)

	return true, {
		version = read_uint16(data, offset+4),
		version_needed = read_uint16(data, offset+6),
		compression = read_uint16(data, offset+10),
		mtime = read_uint16(data, offset+12),
		mdate = read_uint16(data, offset+14),
		crc32 = read_uint32(data, offset+16),
		compressed_size = read_uint32(data, offset+20),
		uncompressed_size = read_uint32(data, offset+24),
		file_offset = read_uint32(data, offset+42),
		name = data:sub(offset+46+1, offset+46+name_len),
		header_len = 46+name_len+extra_len+comment_len
	}
end


local f = io.open("out.zip")

local size = f:seek("end")
print("Zip size: " .. size)

f:seek("set", size - 22)
local data = f:read(22)
local success, result = read_eocd(data, 0)
if success then
	print("Size: " .. result.cd_size .. " Offset: " .. result.cd_offset .. " count: " .. result.cd_count)
else
	print("error: " .. result)
	return
end

f:seek("set", result.cd_offset)
data = f:read(result.cd_size)
local offset = 0
for i=1,result.cd_count do
	success, result = read_cd(data, offset)
	if success then
		print("---")
		print("Version: " .. result.version .. " needed: " .. result.version_needed)
		print("mtime: " .. result.mtime .. " mdate: " .. result.mdate .. " crc32: " .. result.crc32)
		print("file-offset: " .. result.file_offset .. " compression: " .. result.compression)
		print("compr: " .. result.compressed_size .. " uncompr: " .. result.uncompressed_size)
		print("name: " .. result.name .. " header_len: " .. result.header_len)

		offset = offset + result.header_len
	else
		print("error: " .. result)
	end
end