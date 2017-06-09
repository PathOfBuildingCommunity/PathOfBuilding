-- Path of Building
--
-- Class: Item DB
-- Item DB control.
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert

local ItemDBClass = common.NewClass("ItemDB", "ListControl", function(self, anchor, x, y, width, height, itemsTab, db)
	self.ListControl(anchor, x, y, width, height, 16, false)
	self.itemsTab = itemsTab
	self.db = db
	self.defaultText = "^7No items found that match those filters."
	self.dragTargetList = { }
	self.sortControl = { 
		NAME = { key = "name", order = 1, dir = "ASCEND", func = function(a,b) return a:gsub("^The ","") < b:gsub("^The ","") end }
	}
	local leagueFlag = { }
	local typeFlag = { }
	for _, item in pairs(db.list) do
		if item.league then
			for leagueName in item.league:gmatch(" ?([%w ]+),?") do
				leagueFlag[leagueName] = true
			end
		end
		typeFlag[item.type] = true
	end
	self.leagueList = { }
	for leagueName in pairs(leagueFlag) do
		t_insert(self.leagueList, leagueName)
	end
	table.sort(self.leagueList)
	t_insert(self.leagueList, 1, "Any league")
	t_insert(self.leagueList, 2, "No league")
	self.typeList = { }
	for type in pairs(typeFlag) do
		t_insert(self.typeList, type)
	end
	table.sort(self.typeList)
	t_insert(self.typeList, 1, "Any type")
	t_insert(self.typeList, 2, "Armour")
	t_insert(self.typeList, 3, "Jewellery")
	t_insert(self.typeList, 4, "One Handed Melee")
	t_insert(self.typeList, 5, "Two Handed Melee")
	self.slotList = { "Any slot", "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring", "Belt", "Jewel" }
	self.controls.slot = common.New("DropDownControl", {"BOTTOMLEFT",self,"TOPLEFT"}, 0, -22, 95, 18, self.slotList, function(index, value)
		self:BuildList()
	end)
	self.controls.type = common.New("DropDownControl", {"LEFT",self.controls.slot,"RIGHT"}, 2, 0, 135, 18, self.typeList, function(index, value)
		self:BuildList()
	end)
	self.controls.league = common.New("DropDownControl", {"LEFT",self.controls.type,"RIGHT"}, 2, 0, 126, 18, self.leagueList, function(index, value)
		self:BuildList()
	end)
	self.controls.league.shown = function()
		return #self.leagueList > 2
	end
	self.controls.search = common.New("EditControl", {"BOTTOMLEFT",self,"TOPLEFT"}, 0, -2, 258, 18, "", "Search", "%c", 100, function()
		self:BuildList()
	end)
	self.controls.searchMode = common.New("DropDownControl", {"LEFT",self.controls.search,"RIGHT"}, 2, 0, 100, 18, { "Anywhere", "Names", "Modifiers" }, function(index, value)
		self:BuildList()
	end)
	self:BuildSortOrder()
	self:BuildList()
end)

function ItemDBClass:DoesItemMatchFilters(item)
	if self.controls.slot.selIndex > 1 then
		local primarySlot = itemLib.getPrimarySlotForItem(item)
		if primarySlot ~= self.slotList[self.controls.slot.selIndex] and primarySlot:gsub(" %d","") ~= self.slotList[self.controls.slot.selIndex] then
			return false
		end
	end
	local typeSel = self.controls.type.selIndex
	if typeSel > 1 then
		if typeSel == 2 then
			if not item.base.armour then
				return false
			end
		elseif typeSel == 3 then
			if not (item.type == "Amulet" or item.type == "Ring" or item.type == "Belt") then
				return false
			end
		elseif typeSel == 4 or typeSel == 5 then
			local weaponInfo = self.itemsTab.build.data.weaponTypeInfo[item.type]
			if not (weaponInfo and weaponInfo.melee and ((typeSel == 4 and weaponInfo.oneHand) or (typeSel == 5 and not weaponInfo.oneHand))) then 
				return false
			end
		elseif item.type ~= self.typeList[typeSel] then
			return false
		end
	end
	if self.controls.league.selIndex > 1 then
		if (self.controls.league.selIndex == 2 and item.league) or (self.controls.league.selIndex > 2 and (not item.league or not item.league:match(self.leagueList[self.controls.league.selIndex]))) then
			return false
		end
	end
	local searchStr = self.controls.search.buf:lower()
	if searchStr:match("%S") then
		local found = false
		local mode = self.controls.searchMode.selIndex
		if mode == 1 or mode == 2 then
			if item.name:lower():find(searchStr, 1, true) then
				found = true
			end
		end
		if mode == 1 or mode == 3 then
			for _, line in pairs(item.modLines) do
				if line.line:lower():find(searchStr, 1, true) then
					found = true
					break
				end
			end
			if not found then
				searchStr = searchStr:gsub(" ","")
				for i, mod in ipairs(item.baseModList) do
					if mod.name:lower():find(searchStr, 1, true) then
						found = true
						break
					end
				end
			end
		end
		if not found then
			return false
		end
	end
	return true
end

function ItemDBClass:BuildSortOrder()
	self.sortOrder = wipeTable(self.sortOrder)
	for field, data in pairs(self.sortControl) do
		t_insert(self.sortOrder, data)
	end
	table.sort(self.sortOrder, function(a, b)
		return a.order < b.order
	end)
end

function ItemDBClass:BuildList()
	wipeTable(self.list)
	for id, item in pairs(self.db.list) do
		if self:DoesItemMatchFilters(item) then
			t_insert(self.list, item)
		end
	end
	table.sort(self.list, function(a, b)
		for _, data in ipairs(self.sortOrder) do
			local aVal = a[data.key]
			local bVal = b[data.key]
			if aVal ~= bVal then
				if data.dir == "DESCEND" then
					if data.func then
						return data.func(bVal, aVal)
					else
						return bVal < aVal
					end
				else
					if data.func then
						return data.func(aVal, bVal)
					else
						return aVal < bVal
					end
				end
			end
		end
	end)
end

function ItemDBClass:GetRowValue(column, index, item)
	if column == 1 then
		return colorCodes[item.rarity] .. item.name
	end
end

function ItemDBClass:AddValueTooltip(index, item)
	if not main.popups[1] then
		self.itemsTab:AddItemTooltip(item, nil, true)
		return colorCodes[item.rarity], true
	end
end

function ItemDBClass:GetDragValue(index, item)
	return "Item", item
end

function ItemDBClass:OnSelClick(index, item, doubleClick)
	if IsKeyDown("CTRL") then
		-- Add item
		local newItem = itemLib.makeItemFromRaw(self.itemsTab.build.targetVersion, item.raw)
		itemLib.normaliseQuality(newItem)
		self.itemsTab:AddItem(newItem, true)

		-- Equip item if able
		local slotName = itemLib.getPrimarySlotForItem(newItem)
		if slotName and self.itemsTab.slots[slotName] then
			if self.itemsTab.slots[slotName].weaponSet == 1 and self.itemsTab.useSecondWeaponSet then
				-- Redirect to second weapon set
				slotName = slotName .. " Swap"
			end
			if IsKeyDown("SHIFT") then
				-- Redirect to second slot if possible
				local altSlot = slotName:gsub("1","2")
				if self.itemsTab:IsItemValidForSlot(newItem, altSlot) then
					slotName = altSlot
				end
			end
			self.itemsTab.slots[slotName]:SetSelItemId(newItem.id)
		end

		self.itemsTab:PopulateSlots()
		self.itemsTab:AddUndoState()
		self.itemsTab.build.buildFlag = true
	elseif doubleClick then
		self.itemsTab:CreateDisplayItemFromRaw(item.raw, true)
	end
end

function ItemDBClass:OnSelCopy(index, item)
	Copy(item.raw:gsub("\n","\r\n"))
end