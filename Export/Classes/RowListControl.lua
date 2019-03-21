-- Dat View
--
-- Class: Row List
-- Row list control.
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove

local RowListClass = newClass("RowListControl", "ListControl", function(self, anchor, x, y, width, height)
	self.ListControl(anchor, x, y, width, height, 14, true, false, { })
	self.colLabels = true
end)

function RowListClass:BuildColumns()
	wipeTable(self.colList)
	self.colList[1] = { width = 50, label = "#", font = "FIXED" }
	for _, specCol in ipairs(main.curDatFile.spec) do
		t_insert(self.colList, { width = specCol.width, label = specCol.name, font = function() return IsKeyDown("CTRL") and "FIXED" or "VAR" end })
	end
	local short = main.curDatFile.rowSize - main.curDatFile.specSize
	if short > 0 then
		t_insert(self.colList, { width = short * DrawStringWidth(self.rowHeight, "FIXED", "00 "), font = "FIXED" })
	end
end

function RowListClass:GetRowValue(column, index, row)
	if column == 1 then
		return string.format("%5d", index)
	end
	if not main.curDatFile.spec[column - 1] or IsKeyDown("CTRL") then
		local out = { main.curDatFile:ReadCellRaw(index, column - 1) }
		for i, b in ipairs(out) do
			out[i] = string.format("%02X", b)
		end
		return table.concat(out, main.curDatFile.spec[column - 1] and "" or " ")
	else
		local data = main.curDatFile:ReadCellText(index, column - 1)
		if type(data) == "table" then
			for i, v in ipairs(data) do
				data[i] = tostring(v)
			end
			return table.concat(data, ", ")
		else
			return tostring(data)
		end
	end
end
