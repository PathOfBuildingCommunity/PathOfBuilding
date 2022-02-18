-- Dat View
--
-- Class: Row List
-- Row list control.
--
local ipairs = ipairs
local t_insert = table.insert

local RowListClass = newClass("RowListControl", "ListControl", function(self, anchor, x, y, width, height)
	self.ListControl(anchor, x, y, width, height, 14, "HORIZONTAL", false, { })
	self.colLabels = true
end)

function RowListClass:BuildRows(filter)
	wipeTable(self.list)
	local filterFunc
	main.controls.filterError.label = ""
	if filter:match("%S") then
		local error
		filterFunc, error = loadstring([[
			return ]]..filter..[[
		]])
		if error then
			main.controls.filterError.label = "^7"..error
		end
	end
	for rowIndex, row in ipairs(main.curDatFile.rows) do
		if filterFunc then
			setfenv(filterFunc, main.curDatFile:GetRowByIndex(rowIndex))
			local status, result = pcall(filterFunc)
			if status then
				if result then
					t_insert(self.list, rowIndex)
				end
			else
				main.controls.filterError.label = string.format("^7Row %d: %s", rowIndex, result)
				return
			end
		else
			t_insert(self.list, rowIndex)
		end
	end
end

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
		return string.format("%5d", row)
	end
	if not main.curDatFile.spec[column - 1] or IsKeyDown("CTRL") then
		local out = { main.curDatFile:ReadCellRaw(row, column - 1) }
		for i, b in ipairs(out) do
			out[i] = string.format("%02X", b)
		end
		return table.concat(out, main.curDatFile.spec[column - 1] and "" or " ")
	else
		local data = main.curDatFile:ReadCellText(row, column - 1)
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
