-- Dat View
--
-- Class: GGPK File
-- GGPK File
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove

local GGPKClass = newClass("GGPKFile", function(self, path)
	self.path = path

	self.ggpk = { }
	self:ReadRecord(self.ggpk)
	for i = 1, self.ggpk.numRecord do
		self:ReadRecord(self.ggpk.recordList[i])
	end

	results = self:Find("", "Bundles2")
	if results then
		for index, result in ipairs(results) do
			ConPrintf("\nParsing: %s\n", result.name)
			bundle_results = self:Find(result.name, "")
			for _, b_result in ipairs(bundle_results) do
				if not b_result.dir and b_result.name == '_.index.bin' then
					self:DecodeBundle(b_result.data)
				elseif b_result.dir and b_result.name == "Metadata" then
					ConPrintf("\nParsing Path: %s\n", b_result.fullName)
					meta_results = self:Find(b_result.fullName, "")
				end
			end
		end
	end
end)

function GGPKClass:DecodeBundle(raw)
	local uncompressed_size = bytesToUInt(raw, 1)
	local total_payload_size = bytesToUInt(raw, 5)
	local head_payload_size = bytesToUInt(raw, 9)
	local first_file_encode = bytesToUInt(raw, 13)
	local unknown_01 = bytesToUInt(raw, 17)
	local uncompressed_size_2 = bytesToULong(raw, 21)
	local total_payload_size_2 = bytesToULong(raw, 29)
	local entry_count = bytesToUInt(raw, 37)
	local unknown_02 = bytesToUInt(raw, 41)
	local unknown_03 = bytesToUInt(raw, 45)
	local unknown_04 = bytesToUInt(raw, 49)
	local unknown_05 = bytesToUInt(raw, 53)
	local unknown_06 = bytesToUInt(raw, 57)
	
	ConPrintf("Entry Count: %d", entry_count)
	local sizes = {}
	offset = 61
	for i = 1, entry_count do
		sizes[i] = bytesToUInt(raw, offset + (i-1) * 4)
		--ConPrintf("Entry [%d] - Size: %d", i, sizes[i])
	end

	local output_size = uncompressed_size + 64
	ConPrintf("Output Size: %d", output_size)

	-- DECODE
	local lastEntry = entry_count - 1
	local input_offset = offset + 4*entry_count
	local index = 1
	while index < entry_count do
		local unpacked_size = (index == lastEntry) and (uncompressed_size - (lastEntry * 262144)) or 262144
		ConPrintf("Decompressing [%02d] @ Offset: %d     Size: %d ----> %d", index, input_offset, sizes[index], unpacked_size)
		local dst = {}
		self:Kraken_Decompress(raw, input_offset, sizes[index], dst, unpacked_size)
		index = index + 1
		input_offset = input_offset + sizes[index]
	end
end

function GGPKClass:Kraken_Decompress(data, offset, size, dst, max_size)
	
	local offset = 1
	--[[
	local kraken_hdr = {decoder_type = 0, restart_decoder = false, uncompressed = true, use_checksum = false}
	local dec = {src_used = 0, dst_used = 0, scratch_size = 0, hdr = kraken_hdr}
	while max_size ~= 0 do
		if not self:Kraken_DecodeStep(dec, dst, offset, max_size, data, size) then
			return -1
		end
		if dec['src_used'] == 0 then
			return -1
		end
		break
	end
	--]]
	return offset
end

function GGPKClass:Open()
	if not self.file then
		self.file = io.open(self.path, "rb")
	end
end

function GGPKClass:Close()
	if self.file then
		self.file:close()
		self.file = nil
	end
end

function GGPKClass:ReadRecord(record)
	self:Open()
	self.file:seek("set", record.offset)
	local raw = self.file:read(8)
	record.length = bytesToUInt(raw, 1)
	record.tag = raw:sub(5)
	if record.tag == "GGPK" then
		raw = self.file:read(4)
		local ggpkVersion = bytesToUInt(raw, 1)
		--ConPrintf("GGPK Version: %d\n", ggpkVersion)
		record.numRecord = 2
		raw = self.file:read(record.numRecord * 8)
		record.recordList = { }
		for i = 1, record.numRecord do
			record.recordList[i] = {
				offset = bytesToULong(raw, (i-1) * 8 + 1),
			}
		end
		--ConPrintf("GGPK: %d records", record.numRecord)
	elseif record.tag == "PDIR" then
		raw = self.file:read(40)
		local nameLength = bytesToUInt(raw, 1)
		record.numRecord = bytesToUInt(raw, 5)
		record.hash = raw:sub(9)
		raw = self.file:read(nameLength * 2 + record.numRecord * 12) -- 12 as there is a u32 hash, u64 offset for each record
		record.name = convertUTF16to8(raw)
		record.recordList = { }
		for i = 1, record.numRecord do
			record.recordList[i] = {
				nameHash = bytesToUInt(raw, nameLength * 2 + (i-1) * 12 + 1),
				offset = bytesToULong(raw, nameLength * 2 + (i-1) * 12 + 5),
			}
		end
		ConPrintf("PDIR '%s': %d records", record.name, record.numRecord)
	elseif record.tag == "FILE" then
		raw = self.file:read(36)
		local nameLength = bytesToUInt(raw, 1)
		record.hash = raw:sub(5) -- 32 bytes starting at [4:36]
		record.name = convertUTF16to8(self.file:read(nameLength * 2))
		local headLength = 44 + nameLength * 2 -- 44 = 36 read + (4 for rec_leng + 4 for type) pulled outside of 'if'
		record.dataOffset = record.offset + headLength
		record.dataLength = record.length - headLength
		ConPrintf("FILE '%s': %d bytes", record.name, record.dataLength)
	elseif record.tag == "FREE" then
		record.nextFree = bytesToULong(self.file:read(8))
		ConPrintf("FREE")
	else
		ConPrintf("Unhandled Tag: %s", record.tag)
	end
	record.read = true
end

function GGPKClass:GetRecord(name)
	self:Open()
	local record = self.ggpk.recordList[1]
	for part in name:gmatch("[^\\/]+") do
		if not record.recordList then
			self:ReadRecord(record)
		end
		local hash = murmurHash2(convertUTF8to16(part:lower()))
		local found
		for _, record in ipairs(record.recordList) do
			if record.nameHash == hash then
				found = record
				break
			end
		end
		if not found then
			return 
		end
		record = found
	end
	return record
end

function GGPKClass:ReadFile(name)
	local record = self:GetRecord(name)
	if record then
		if not record.read then
			self:ReadRecord(record)
		end
		if record.tag == "FILE" then
			self.file:seek("set", record.dataOffset)
			return self.file:read(record.dataLength)
		end
	end
end

function GGPKClass:Find(path, name)
	local out = { }
	local dir = self:GetRecord(path)
	if not dir.read then
		self:ReadRecord(dir)
	end
	for _, record in ipairs(dir.recordList) do
		if not record.read then
			self:ReadRecord(record)
		end
		if record.name and record.name:match(name) then
			local result =  { }
			result.name = record.name
			result.dir = record.tag == "PDIR"
			result.fullName = path .. "/" .. record.name
			if record.tag == "FILE" then
				self.file:seek("set", record.dataOffset)
				result.data = self.file:read(record.dataLength)
			end
			t_insert(out, result)
		end
	end
	table.sort(out, function(a,b) return a.name < b.name end)
	return out
end