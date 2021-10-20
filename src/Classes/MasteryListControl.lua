-- Path of Building
--
-- Class: Mastery effect List
-- Mastery effect list control.
--
local ipairs = ipairs
local t_insert = table.insert
local m_max = math.max
local row_Height = 20

local MasteryListClass = newClass("MasteryListControl", "ListControl", function(self, anchor, x, y, width, height, list, saveButton)
	-- automagical height
	if height == 0 then
		height = (#list * row_Height) + 10
	end
	-- automagical width
	if width == 0 then
		-- do not be smaller than this width
		width = 579
		for j=1,#list do
			width = m_max(width, DrawStringWidth(row_Height, "VAR", list[j].label) + 30)
		end
	end
	self.ListControl(anchor, x, y, width, height, row_Height, false, false, list)
	self.ListControl.controls.scrollBarV.enabled = false
	self.ListControl.controls.scrollBarV.autoHide = false
	self.ListControl:SelectIndex(1)
	self.saveButton = saveButton
	end)


function MasteryListClass:GetRowValue(column, index, mastery)
	if column == 1 then
		return mastery.label
	end
end


function MasteryListClass:GetSelValue(key)
	return self.list[self.selIndex][key]
end


function MasteryListClass:OnSelClick(index, mastery, doubleClick)
	if doubleClick then
		self.saveButton:Click()
	end
end
