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
	self:sortSourceList()
	self.unfilteredList = copyTable(list)
	self.isMutable = false

	self.controls.searchText = new("EditControl", {"BOTTOMLEFT",self,"TOPLEFT"}, {0, -2, 148, 18}, "", "Search", "%c", 100, function(buf)
		self:ListFilterChanged(buf, self.controls.searchModeDropDown.selIndex)
		self:sortSourceList()
	end, nil, nil, true)

	self.controls.searchModeDropDown = new("DropDownControl", {"LEFT",self.controls.searchText,"RIGHT"}, {2, 0, 60, 18}, { "Names", "Skills", "Both"}, function(index, value)
		self:ListFilterChanged(self.controls.searchText.buf, index)
		self:sortSourceList()
	end)
	self.controls.sortModeDropDown = new("DropDownControl", {"BOTTOMRIGHT", self.controls.searchModeDropDown, "TOPRIGHT"}, {0, -2, self.width, 18}, {
		"Sort by Names",
		"Sort by Life + ES",
		"Sort by Life",
		"Sort by Energy Shield",
		"Sort by Attack Speed",
		"Sort by Base Damage",
		"Sort by Fire Resistance",
		"Sort by Cold Resistance",
		"Sort by Lightning Resistance",
		"Sort by Chaos Resistance",
		"Sort by Total Resistance",
		"Sort by Movement Speed",
	}, function(index, value)
			self:sortSourceList()
	end)

	self.labelPositionOffset = {0, -40}
	if dest then
		self.controls.add.y = self.controls.add.y - 40
	else
		self.controls.delete.y = self.controls.add.y - 40
	end

end)

function MinionSearchListClass:sortSourceList()
	local sortFields = {
		[1] = { field = "name", asc = true },
		[2] = { field = "totalHitPoints", asc = false },
		[3] = { field = "life", asc = false },
		[4] = { field = "energyShield", asc = false },
		[5] = { field = "attackTime", asc = true },
		[6] = { field = "damage", asc = false },
		[7] = { field = "fireResist", asc = false },
		[8] = { field = "coldResist", asc = false },
		[9] = { field = "lightningResist", asc = false },
		[10] = { field = "chaosResist", asc = false },
		[11] = { field = "totalResist", asc = false },
		[12] = { field = "baseMovementSpeed", asc = false },
	}
	local sortModeIndex = self.controls.sortModeDropDown and self.controls.sortModeDropDown.selIndex or 1
	local sortOption = sortFields[sortModeIndex]
	if sortOption then
		table.sort(self.list, function(a, b)
			local minionA = self.data.minions[a]
			local minionB = self.data.minions[b]
			local valueA = minionA[sortOption.field]
			local valueB = minionB[sortOption.field]
			if sortOption.field == "life" then
				valueA = minionA.life
				valueB = minionB.life
			elseif sortOption.field == "totalHitPoints" then
				valueA = minionA.life + (((minionA.energyShield or 0) * (data.gameConstants["EnergyShieldRatioOfLife"]) / 100) * minionA.life)
				valueB = minionB.life + (((minionB.energyShield or 0) * (data.gameConstants["EnergyShieldRatioOfLife"]) / 100) * minionB.life)
			elseif sortOption.field == "energyShield" then
				valueA = ((minionA.energyShield or 0) * (data.gameConstants["EnergyShieldRatioOfLife"]) / 100) * minionA.life
				valueB = ((minionB.energyShield or 0) * (data.gameConstants["EnergyShieldRatioOfLife"]) / 100) * minionB.life
			elseif sortOption.field == "totalResist" then
				valueA = (minionA.fireResist or 0) + (minionA.coldResist or 0) + (minionA.lightningResist or 0) + (minionA.chaosResist or 0)
				valueB = (minionB.fireResist or 0) + (minionB.coldResist or 0) + (minionB.lightningResist or 0) + (minionB.chaosResist or 0)
			end
			if valueA == valueB then
				return minionA.name < minionB.name
			else
				if sortOption.asc then
					return valueA < valueB
				else
					return valueA > valueB
				end
			end
		end)
	end
end

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
