-- Path of Building
--
-- Class: Minion Search List
-- Minion list control with search field. Cannot be mutable.
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local s_format = string.format

local MinionSearchListClass = newClass("MinionSearchListControl", "MinionListControl", function(self, anchor, rect, data, list, dest)
	self.MinionListControl(anchor, rect, data, list, dest)	
	self.unfilteredList = copyTable(list)
	self.isMutable = false

	self.controls.searchText = new("EditControl", {"BOTTOMLEFT",self,"TOPLEFT"}, {0, -2, 128, 18}, "", "Search", "%c", 100, function(buf)
		self:ListFilterChanged(buf, self.controls.searchModeDropDown.selIndex)
	end, nil, nil, true)	
	
	self.controls.searchModeDropDown = new("DropDownControl", {"LEFT",self.controls.searchText,"RIGHT"}, {2, 0, 60, 18}, { "Names", "Skills", "Both"}, function(index, value)
		self:ListFilterChanged(self.controls.searchText.buf, index)
	end)

	self.labelPositionOffset = {0, -20}
	if dest then
		self.controls.add.y = self.controls.add.y - 20
	else
		self.controls.delete.y = self.controls.add.y - 20
	end

end)

function MinionSearchListClass:DoesEntryMatchFilters(searchStr, minionId, filterMode)
	if filterMode == 1 or filterMode == 3 then
		local err, match = PCall(string.matchOrPattern, self.data.minions[minionId].name:lower(), searchStr)
		if not err and match then
			return true
		end
	end
	if filterMode == 2 or filterMode == 3 then
		for _, skillId in ipairs(self.data.minions[minionId].skillList) do
			if self.data.skills[skillId] then
				local err, match = PCall(string.matchOrPattern, self.data.skills[skillId].name:lower(), searchStr)
				if not err and match then
					return true
				end
			end
		end
	end
	return false
end

function MinionSearchListClass:ListFilterChanged(buf, filterMode)
	local searchStr = buf:lower():gsub("[%-%.%+%[%]%$%^%%%?%*]", "%%%0")
	if searchStr:match("%S") then
		local filteredList = { }
		for _, minionId in pairs(self.unfilteredList) do
			if self:DoesEntryMatchFilters(searchStr, minionId, filterMode) then
				t_insert(filteredList, minionId)
			end
		end
		self.list = filteredList
		self:SelectIndex(1)
	else
		self.list = self.unfilteredList
	end
end
