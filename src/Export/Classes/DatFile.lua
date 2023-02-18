-- Dat View
--
-- Class: Dat File
-- Dat File
--
local ipairs = ipairs
local t_insert = table.insert
local m_min = math.min

local dataTypes = {
	Bool = {
		size = 1, 
		read = function(b, o, d) 
			return b:byte(o) == 1 
		end,
	}, 
	Int = { 
		size = 4, 
		read = function(b, o, d)
			if o > #b - 3 then return -1337 end
			return bytesToInt(b, o)
		end,
	},
	UInt = { 
		size = 4, 
		read = function(b, o, d)
			if o > #b - 3 then return 1337 end
			return bytesToUInt(b, o)
		end,
	},
	Interval = {
		size = 8,
		read = function(b, o, d)
			if o > #b - 7 then return { 1337, 1337 } end
			return { bytesToInt(b, o), bytesToInt(b, o + 4) }
		end,
	},
	Float = { 
		size = 4, 
		read = function(b, o, d)
			if o > #b - 3 then return -1337 end
			return bytesToFloat(b, o)
		end,
	},
	String = {
		size = 4,
		read = function(b, o, d) 
			if o > #b - 3 then return "<no offset>" end
			local stro = bytesToUInt(b, o)
			if stro > #b - 3 then return "<bad offset>" end
			return convertUTF16to8(b, d + stro)
		end,
	},
	Enum = { 
		size = 4, 
		ref = true,
		read = function(b, o, d)
			if o > #b - 3 then return 1337 end
			return bytesToUInt(b, o)
		end,
	},
	Key = { 
		size = 8, 
		ref = true,
		read = function(b, o, d)
			if o > #b - 7 then return 1337 end
			return bytesToUInt(b, o)
		end,
	},
}

local DatFileClass = newClass("DatFile", function(self, name, raw)
	self.name = name
	self.raw = raw

	if not main.datSpecs[self.name] then
		main.datSpecs[self.name] = { }
	end
	self.spec = main.datSpecs[self.name]

	self.cols = { }
	self.colMap = { }
	self.indexes = { }

	local colMeta = { __index = function(t, key)
		local colIndex = self.colMap[key]
		if not colIndex then
			error("Unknown key "..key.." for "..self.name..".dat")
		end
		t[key] = self:ReadCell(t._rowIndex, colIndex)
		return rawget(t, key)
	end }
	self.rowCache = setmetatable({ }, { __index = function(t, rowIndex)
		if rowIndex < 1 or rowIndex > self.rowCount then
			return
		end
		t[rowIndex] = setmetatable({ _rowIndex = rowIndex }, colMeta)
		return t[rowIndex]
	end })

	self.rows = { }
	self.rowCount = bytesToUInt(self.raw)
	self.dataOffset = self.raw:find("\xBB\xBB\xBB\xBB\xBB\xBB\xBB\xBB", 5, true) or (#self.raw + 1)
	self.rowSize = (self.dataOffset - 5) / self.rowCount
	for i = 1, self.rowCount do
		self.rows[i] = 5 + (i-1) * self.rowSize
	end

	--ConPrintf("Loaded '%s': %d Rows at %d Bytes", self.name, self.rowCount, self.rowSize)

	self:OnSpecChanged()
end)

function DatFileClass:OnSpecChanged()
	wipeTable(self.cols)
	wipeTable(self.colMap)
	wipeTable(self.indexes)
	wipeTable(self.rowCache)
	local offset = 0
	for i, specCol in ipairs(self.spec) do
		local dataType = dataTypes[specCol.type]
		local size = specCol.list and 8 or dataType.size
		self.cols[i] = {
			size = size,
			offset = offset,
			isRef = dataType.ref,
		}
		offset = offset + size
		if #specCol.name > 0 then
			self.colMap[specCol.name] = i
		end
	end
	self.specSize = offset
	self.cols[#self.spec + 1] = {
		size = self.rowSize - offset,
		offset = offset,
	}
end

function DatFileClass:GetRow(key, value)
	local keyIndex = self.colMap[key]
	if not keyIndex then
		error("Unknown key "..key.." for "..self.name..".dat")
	end
	if not self.indexes[key] then
		self.indexes[key] = { }
	end
	for rowIndex = 1, self.rowCount do
		if not self.indexes[key][rowIndex] then
			self.indexes[key][rowIndex] = self:ReadCell(rowIndex, keyIndex)
		end
		if self.indexes[key][rowIndex] == value then
			return self.rowCache[rowIndex]
		end
	end
end

function DatFileClass:GetRowByIndex(rowIndex)
	return self.rowCache[rowIndex]
end

function DatFileClass:Rows()
	local i = 0
	return function()
		i = i + 1
		if i <= self.rowCount then
			return self:GetRowByIndex(i)
		end
	end
end

function DatFileClass:GetRowList(key, value, match)
	local keyIndex = self.colMap[key]
	if not keyIndex then
		error("Unknown key "..key.." for "..self.name..".dat")
	end
	local isList = self.spec[keyIndex].list
	if not self.indexes[key] then
		self.indexes[key] = { }
	end
	local out = { }
	for rowIndex = 1, self.rowCount do
		if not self.indexes[key][rowIndex] then
			self.indexes[key][rowIndex] = self:ReadCell(rowIndex, keyIndex)
		end
		local index = self.indexes[key][rowIndex]
		if isList then
			for _, indexVal in ipairs(index) do
				if (match and indexVal:match(value)) or (not match and indexVal == value) then
					t_insert(out, self.rowCache[rowIndex])
					break
				end
			end
		else
			if (match and index:match(value)) or (not match and index == value) then
				t_insert(out, self.rowCache[rowIndex])
			end
		end
	end
	return out
end

function DatFileClass:ReadCell(rowIndex, colIndex)
	local spec = self.spec[colIndex]
	local col = self.cols[colIndex]
	local base = self.rows[rowIndex] + col.offset
	if spec.list then
		local dataType = dataTypes[spec.type]
		local count = bytesToUInt(self.raw, base)
		local offset = bytesToUInt(self.raw, base + 4) + self.dataOffset
		local out = { }
		for i = 1, m_min(count, 1000) do
			out[i] = self:ReadValue(spec, offset)
			offset = offset + dataType.size
		end
		return out
	else
		return self:ReadValue(spec, base)
	end
end

function DatFileClass:ReadValue(spec, offset)
	local dataType = dataTypes[spec.type]
	local val = dataType.read(self.raw, offset, self.dataOffset)
	if not dataType.ref then
		return val
	end
	if val == 0xFEFEFEFE then
		return
	end
	local other = main.datFileByName[spec.refTo]
	if not other then
		return
	end
	if spec.type == "Enum" and spec.refTo ~= self.name then
		return val
	end
	return other.rowCache[val + 1]
end

function DatFileClass:ReadCellText(rowIndex, colIndex)
	local spec = self.spec[colIndex]
	local col = self.cols[colIndex]
	local base = self.rows[rowIndex] + col.offset
	if spec.list then
		local dataType = dataTypes[spec.type]
		local count = bytesToUInt(self.raw, base)
		local offset = bytesToUInt(self.raw, base + 4) + self.dataOffset
		local out = { }
		for i = 1, m_min(count, 1000) do
			out[i] = self:ReadValueText(spec, offset)
			offset = offset + dataType.size
		end
		return out
	else
		return self:ReadValueText(spec, base)
	end
end

function DatFileClass:ReadValueText(spec, offset)
	local dataType = dataTypes[spec.type]
	local val = dataType.read(self.raw, offset, self.dataOffset)
	if dataType.ref then
		if val == 0xFEFEFEFE then
			return ""
		end
		local other = main.datFileByName[spec.refTo]
		if other then
			local otherRow = other.rows[val + ((spec.type == "Enum" and spec.refTo ~= self.name) and 0 or 1)]
			if not otherRow then
				return "<bad ref #"..val..">"
			end
			if other.spec[1] then
				return other:ReadValueText(other.spec[1], otherRow)
			end
		end
	end
	if spec.type == "Interval" then
		return val[1] == val[2] and val[1] or (val[1] .. " to " .. val[2])
	else
		return val
	end
end

function DatFileClass:ReadCellRaw(rowIndex, colIndex)
	local col = self.cols[colIndex]
	local base = self.rows[rowIndex] + col.offset
	return self.raw:byte(base, base + col.size - 1)
end
