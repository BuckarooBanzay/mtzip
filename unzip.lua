local read_uint16, read_uint32, insert = mtzip.read_uint16, mtzip.read_uint32, table.insert

-- Local file header
local function read_local_file_header(data, offset)
	if not mtzip.compare_bytes(data, offset, mtzip.lfh_sig, 0, 4) then
		return nil, "invalid local file header signature"
	end

	local name_len = read_uint16(data, offset+26)
	local extra_len = read_uint16(data, offset+28)

	return {
		header_len = 30+name_len+extra_len,
		compression = read_uint16(data, offset+8)
	}
end

-- End of central directory record (EOCD)
local function read_eocd(data, offset)
	if not mtzip.compare_bytes(data, offset, mtzip.eocd_sig, 0, 4) then
		return nil, "invalid eocd signature"
	end

	return {
		cd_size = read_uint32(data, offset+12),
		cd_offset = read_uint32(data, offset+16),
		cd_count = read_uint16(data, offset+8)
	}
end

-- Central directory file header
local function read_cd(data, offset)
	if not mtzip.compare_bytes(data, offset, mtzip.cd_sig, 0, 4) then
		return nil, "invalid cd signature"
	end

	local time = read_uint16(data, offset+12)
	local date = read_uint16(data, offset+14)
	local name_len = read_uint16(data, offset+28)
	local extra_len = read_uint16(data, offset+30)
	local comment_len = read_uint16(data, offset+32)

	return {
		version = read_uint16(data, offset+4),
		version_needed = read_uint16(data, offset+6),
		compression = read_uint16(data, offset+10),
		mtime = mtzip.fromDosTime(date, time),
		crc32 = read_uint32(data, offset+16),
		compressed_size = read_uint32(data, offset+20),
		uncompressed_size = read_uint32(data, offset+24),
		file_offset = read_uint32(data, offset+42),
		name = data:sub(offset+46+1, offset+46+name_len),
		extra_len = extra_len,
		comment_len = comment_len,
		header_len = 46+name_len+extra_len+comment_len
	}
end

-- searches backwards for the eocd record, returns its data or nil, err
local function find_eocd(file)
	local size = file:seek("end")
	if not size or size < mtzip.eocd_min_size then
		return nil, "file too small to be a zip archive"
	end

	local tail_len = math.min(size, mtzip.eocd_min_size + mtzip.eocd_max_comment)
	file:seek("set", size - tail_len)
	local tail = file:read(tail_len)
	if not tail then
		return nil, "could not read end of file"
	end

	for pos = #tail - mtzip.eocd_min_size, 0, -1 do
		if mtzip.compare_bytes(tail, pos, mtzip.eocd_sig, 0, 4) then
			return tail:sub(pos+1, pos+mtzip.eocd_min_size)
		end
	end
	return nil, "invalid eocd signature"
end

local UnzippedFile = {}
local UnzippedFile_mt = { __index = UnzippedFile }

function mtzip.unzip(file)
	if not file then
		return nil, "file is nil"
	end
	local data, find_err_msg = find_eocd(file)
	if not data then
		return nil, find_err_msg
	end
	-- read eocd
	local eocd, err_msg = read_eocd(data, 0)
	if not eocd then
		return nil, err_msg
	end
	if eocd.cd_count == mtzip.max_uint16 or eocd.cd_size == mtzip.max_uint32 or eocd.cd_offset == mtzip.max_uint32 then
		return nil, "zip64 is not supported"
	end

	-- read cd
	file:seek("set", eocd.cd_offset)
	data = file:read(eocd.cd_size)
	if not data or #data ~= eocd.cd_size then
		return nil, "could not read central directory"
	end

	-- filename -> cd
	local entries = {}

	-- read all entries from the cd
	local offset = 0
	for _=1,eocd.cd_count do
		if offset + 46 > #data then
			return nil, "central directory truncated"
		end
		local cd, cd_err_msg = read_cd(data, offset)
		if not cd then
			return nil, cd_err_msg
		end
		if cd.compressed_size == mtzip.max_uint32 or cd.uncompressed_size == mtzip.max_uint32
			or cd.file_offset == mtzip.max_uint32 then
			return nil, "zip64 is not supported: '" .. cd.name .. "'"
		end
		entries[cd.name] = cd
		offset = offset + cd.header_len
	end

	local self = {
		entries = entries,
		file = file
	}
	return setmetatable(self, UnzippedFile_mt)
end

function UnzippedFile:get_entry(filename)
	return self.entries[filename]
end

function UnzippedFile:get(filename, verify)
	local cd = self.entries[filename]
	if not cd then
		return nil, "no such file: '" .. filename .. "'"
	end

	self.file:seek("set", cd.file_offset)
	local header_data = self.file:read(30)
	if not header_data or #header_data < 30 then
		return nil, "could not read local file header"
	end
	local header, err_msg = read_local_file_header(header_data, 0)
	if not header then
		return nil, err_msg
	end

	local data = ""
	if cd.compressed_size > 0 then
		self.file:seek("set", cd.file_offset+header.header_len)
		data = self.file:read(cd.compressed_size)
		if not data or #data ~= cd.compressed_size then
			return nil, "could not read file data: '" .. filename .. "'"
		end
	end

	if header.compression == mtzip.compression_flag_deflate then
		if cd.compressed_size > 0 then
			data = core.decompress(mtzip.zlib_header .. data, "deflate")
			if not data then
				return nil, "decompression failed: '" .. filename .. "'"
			end
		end
	elseif header.compression ~= mtzip.compression_flag_none then
		return nil, "unsupported compression type: " .. header.compression
	end

	if verify then
		local crc = mtzip.crc32(data)
		if crc ~= cd.crc32 then
			return nil, "checksum mismatch, calculated: '"..crc.."' expected: '"..cd.crc32.."'"
		end
	end

	return data
end

function UnzippedFile:list()
	local list = {}
	for k in pairs(self.entries) do
		insert(list, k)
	end
	table.sort(list)
	return list
end
