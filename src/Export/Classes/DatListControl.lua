-- Dat View
--
-- Class: Dat List
-- Dat list control.
--
local DatListClass = newClass("DatListControl", "ListControl", function(self, anchor, x, y, width, height)
	self.ListControl(anchor, x, y, width, height, 14, "VERTICAL", false, main.datFileList)
end)

function DatListClass:GetRowValue(column, index, datFile)
	if column == 1 then
		return "^7"..datFile.name
	end
end

function DatListClass:OnSelect(index, datFile)
	main:SetCurrentDat(datFile)
end

function DatListClass:OnAnyKeyDown(key)
	if key:match("%a") then
		for i = 1, #self.list do
			local valIndex = ((self.selIndex or 1) - 1 + i) % #self.list + 1
			local val = self.list[valIndex]
			if val.name:sub(1, 1):lower() == key:lower() then
				self:SelectIndex(valIndex)
				return
			end
		end
	end
end
