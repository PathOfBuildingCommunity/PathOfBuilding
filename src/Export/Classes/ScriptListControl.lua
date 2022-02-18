-- Dat View
--
-- Class: Script List
-- Script list control.
--
local ScriptListClass = newClass("ScriptListControl", "ListControl", function(self, anchor, x, y, width, height)
	self.ListControl(anchor, x, y, width, height, 16, "VERTICAL", false, main.scriptList)
end)

function ScriptListClass:GetRowValue(column, index, script)
	if column == 1 then
		return "^7"..script
	end
end

function ScriptListClass:OnSelClick(index, script, doubleClick)
	if doubleClick then
		local errMsg = PLoadModule("Scripts/"..script..".lua")
		if errMsg then
			print(errMsg)
		end
	end
end
