-- Dat View
--
-- Class: Spec Col List
-- Spec column list control.
--
local t_remove = table.remove

local SpecColListClass = newClass("SpecColListControl", "ListControl", function(self, anchor, x, y, width, height)
	self.ListControl(anchor, x, y, width, height, 14, "VERTICAL", true)
end)

function SpecColListClass:GetRowValue(column, index, specCol)
	if column == 1 then
		return #specCol.name > 0 and ("^7"..specCol.name) or "???"
	end
end

function SpecColListClass:OnSelect(index, specCol)
	main:SetCurrentCol(index)
end

function SpecColListClass:OnOrderChange()
	main.curDatFile:OnSpecChanged()
	main.controls.rowList:BuildColumns()
end

function SpecColListClass:OnSelDelete(index, specCol)
	t_remove(self.list, index)
	main:SetCurrentCol()
	main.curDatFile:OnSpecChanged()
	main.controls.rowList:BuildColumns()
end
