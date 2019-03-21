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
end)

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
		record.numRecord = bytesToUInt(raw, 1)
		raw = self.file:read(record.numRecord * 8)
		record.recordList = { }
		for i = 1, record.numRecord do
			record.recordList[i] = {
				offset = bytesToULong(raw, (i-1) * 8 + 1),
			}
		end
--		ConPrintf("GGPK: %d records", record.numRecord)
	elseif record.tag == "PDIR" then
		raw = self.file:read(40)
		local nameLength = bytesToUInt(raw, 1)
		record.numRecord = bytesToUInt(raw, 5)
		record.hash = raw:sub(9)
		raw = self.file:read(nameLength * 2 + record.numRecord * 12)
		record.name = convertUTF16to8(raw)
		record.recordList = { }
		for i = 1, record.numRecord do
			record.recordList[i] = {
				nameHash = bytesToUInt(raw, nameLength * 2 + (i-1) * 12 + 1),
				offset = bytesToULong(raw, nameLength * 2 + (i-1) * 12 + 5),
			}
		end
--		ConPrintf("PDIR '%s': %d records", record.name, record.numRecord)
	elseif record.tag == "FILE" then
		raw = self.file:read(36)
		local nameLength = bytesToUInt(raw, 1)
		record.hash = raw:sub(5)
		record.name = convertUTF16to8(self.file:read(nameLength * 2))
		local headLength = 44 + nameLength * 2
		record.dataOffset = record.offset + headLength
		record.dataLength = record.length - headLength
--		ConPrintf("FILE '%s': %d bytes", record.name, record.dataLength)
	elseif record.tag == "FREE" then
		record.nextFree = bytesToULong(self.file:read(8))
--		ConPrintf("FREE")
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