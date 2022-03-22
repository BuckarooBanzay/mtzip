
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

local function write_uint16(v)
	local b1 = v % 256
	local b2 = math.floor(v / 256)
	return string.char(b1, b2)
end

return {
	lfh_sig = string.char(80, 75, 3, 4),
    eocd_sig = string.char(80, 75, 5, 6),
    cd_sig = string.char(80, 75, 1, 2),
	compression_flag_deflate = 8,
	compression_flag_none = 0,
    compare_bytes = compare_bytes,
    read_uint16 = read_uint16,
	write_uint16 = write_uint16,
    read_uint32 = read_uint32
}
