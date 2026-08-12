-- Dat View
--
-- Class: Script List
-- Script list control.
--
---@class ScriptListControl: ListControl
local ScriptListClass = newClass("ScriptListControl", "ListControl")

function ScriptListClass:ScriptListControl(anchor, rect)
	self:ListControl(anchor, rect, 16, "VERTICAL", false, main.scriptList)
	return self
end

function ScriptListClass:GetRowValue(column, index, script)
	if column == 1 then
		return "^7"..script
	end
end

function ScriptListClass:OnSelClick(index, script, doubleClick)
	if doubleClick then
		if main.controls.clearAutoClearOutput.state then
			wipeTable(main.scriptOutput)
		end
		local errMsg = PLoadModule("Scripts/"..script..".lua")
		if errMsg then
			print(errMsg)
		end
	end
end
