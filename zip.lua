local char, write_uint16, write_uint32 = string.char, mtzip.write_uint16, mtzip.write_uint32

local ZippedFile = {}
local ZippedFile_mt = { __index = ZippedFile }

function mtzip.zip(file)
	local self = {
		headers = {},
		names = {}, -- insertion order
		closed = false,
		file = file
	}
	return setmetatable(self, ZippedFile_mt)
end

local function write_file(file, filename, data, opts)
	opts = opts or {}

	local offset = file:seek("end")
	if not offset or offset > mtzip.max_uint32 then
		return nil, "archive too large (zip64 is not supported)"
	end
	if #filename > mtzip.max_uint16 then
		return nil, "filename too long"
	end
	local compressed = false
	local date, time = mtzip.toDosTime(os.date("*t"))
	local crc = mtzip.crc32(data)

	local uncompressed_size = #data
	if not opts.disable_compression then
		compressed = true
		data = core.compress(data, "deflate", 9)
		if not data or #data < 6 then
			return nil, "compression failed"
		end
		-- strip the 2-byte zlib header and the 4-byte adler32 trailer to get raw deflate data
		data = string.sub(data, 3, -5)
	end
	local compressed_size = #data
	if uncompressed_size >= mtzip.max_uint32 or compressed_size >= mtzip.max_uint32 then
		return nil, "file too large (zip64 is not supported)"
	end
	file:write(mtzip.lfh_sig)
	file:write(char(0x0A, 0x00)) -- Version needed to extract (minimum)
	file:write(char(0x00, 0x00)) -- General purpose bit flag

	if compressed then
		file:write(char(0x08, 0x00))
	else
		file:write(char(0x00, 0x00))
	end

	file:write(write_uint16(time)) --File last modification time
	file:write(write_uint16(date)) --File last modification date

	file:write(write_uint32(crc))
	file:write(write_uint32(compressed_size))
	file:write(write_uint32(uncompressed_size))

	file:write(write_uint16(#filename)) -- File name length (n)
	file:write(char(0x00, 0x00)) -- Extra field length (m)
	file:write(filename)

	file:write(data)

	return {
		-- header-data
		crc = crc,
		compressed_size = compressed_size,
		uncompressed_size = uncompressed_size,
		compressed = compressed,
		time = time,
		date = date,
		offset = offset
	}
end

local function write_cd(file, filename, header_data)
	file:write(mtzip.cd_sig)
	file:write(char(0x00, 0x00)) -- Version made by
	file:write(char(0x0A, 0x00)) -- Version needed to extract (minimum)
	file:write(char(0x00, 0x00)) -- General purpose bit flag

	if header_data.compressed then
		file:write(string.char(0x08, 0x00))
	else
		file:write(string.char(0x00, 0x00))
	end

	file:write(write_uint16(header_data.time)) --File last modification time
	file:write(write_uint16(header_data.date)) --File last modification date

	file:write(write_uint32(header_data.crc))
	file:write(write_uint32(header_data.compressed_size))
	file:write(write_uint32(header_data.uncompressed_size))

	file:write(write_uint16(#filename)) -- File name length (n)
	file:write(char(0x00, 0x00)) -- Extra field length (m)
	file:write(char(0x00, 0x00)) -- File comment length (k)
	file:write(char(0x00, 0x00)) -- Disk number where file starts
	file:write(char(0x00, 0x00)) -- Internal file attributes
	file:write(char(0x00, 0x00, 0x00, 0x00)) -- External file attributes
	file:write(write_uint32(header_data.offset+0)) -- Relative offset of local file header
	file:write(filename)

	return 46 + #filename
end

local function write_eocd(file, count, offset, cd_size)
	file:write(mtzip.eocd_sig)
	file:write(char(0x00, 0x00)) -- Number of this disk (or 0xffff for ZIP64)
	file:write(char(0x00, 0x00)) -- Disk where central directory starts (or 0xffff for ZIP64)
	file:write(write_uint16(count)) -- Number of central directory records on this disk (or 0xffff for ZIP64)
	file:write(write_uint16(count)) -- Total number of central directory records (or 0xffff for ZIP64)
	file:write(write_uint32(cd_size)) -- Size of central directory (bytes) (or 0xffffffff for ZIP64)
	file:write(write_uint32(offset)) -- Offset of start of central directory
	file:write(char(0x00, 0x00)) -- Comment length (n)
end

function ZippedFile:add(filename, data, opts)
	if self.closed then
		return false, "archive already closed"
	end
	if not self.headers[filename] and #self.names >= mtzip.max_uint16 then
		return false, "too many entries (zip64 is not supported)"
	end
	local header_data, err_msg = write_file(self.file, filename, data, opts)
	if not header_data then
		return false, err_msg
	end
	if not self.headers[filename] then
		table.insert(self.names, filename)
	end
	self.headers[filename] = header_data
	return true
end

function ZippedFile:close()
	if self.closed then
		return false, "archive already closed"
	end
	-- offset of cd
	local offset = self.file:seek("end")
	if not offset or offset > mtzip.max_uint32 then
		return false, "archive too large (zip64 is not supported)"
	end
	self.closed = true
	local cd_size = 0
	local count = 0
	for _, filename in ipairs(self.names) do
		cd_size = cd_size + write_cd(self.file, filename, self.headers[filename])
		count = count + 1
	end
	write_eocd(self.file, count, offset, cd_size)
	return true
end
