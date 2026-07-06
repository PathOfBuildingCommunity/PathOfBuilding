-- Path of Building
--
-- Class: Item DB
-- Item DB control.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_max = math.max
local m_floor = math.floor


local ItemDBClass = newClass("ItemDBControl", "ListControl", function(self, anchor, rect, itemsTab, db, dbType)
	self.ListControl(anchor, rect, 16, "VERTICAL", false)
	self.itemsTab = itemsTab
	self.db = db
	self.dbType = dbType
	self.dragTargetList = { }
	self.sortControl = { 
		NAME = { key = "name", dir = "ASCEND", func = function(a,b) return a:gsub("^The ","") < b:gsub("^The ","") end },
		STAT = { key = "measuredPower", dir = "DESCEND" },
	}
	self.sortDropList = { }
	self.sortOrder = { }
	self.sortMode = "NAME"
	self.leaguesAndTypesLoaded = false
	self.leagueList = { "Any league", "No league" }
	self.typeList = { "Any type", "Armour", "Jewellery", "One Handed Melee", "Two Handed Melee" }
	self.slotList = { "Any slot", "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring", "Belt", "Jewel", "Flask", "Graft 1", "Graft 2" }
	local baseY = dbType == "RARE" and -22 or -62
	self.controls.slot = new("DropDownControl", {"BOTTOMLEFT",self,"TOPLEFT"}, {0, baseY, 179, 18}, self.slotList, function(index, value)
		self.listBuildFlag = true
	end)
	self.controls.type = new("DropDownControl", {"LEFT",self.controls.slot,"RIGHT"}, {2, 0, 179, 18}, self.typeList, function(index, value)
		self.listBuildFlag = true
	end)
	if dbType == "UNIQUE" then
		self.controls.sort = new("DropDownControl", {"BOTTOMLEFT",self,"TOPLEFT"}, {0, baseY + 20, 179, 18}, self.sortDropList, function(index, value)
			self:SetSortMode(value.sortMode)
		end)
		self.controls.league = new("DropDownControl", {"LEFT",self.controls.sort,"RIGHT"}, {2, 0, 179, 18}, self.leagueList, function(index, value)
			self.listBuildFlag = true
		end)
		self.controls.requirement = new("DropDownControl", {"LEFT",self.controls.sort,"BOTTOMLEFT"}, {0, 11, 179, 18}, { "Any requirements", "Current level", "Current attributes", "Current useable" }, function(index, value)
			self.listBuildFlag = true
		end)
		self.controls.obtainable = new("DropDownControl", {"LEFT",self.controls.requirement,"RIGHT"}, {2, 0, 179, 18}, { "Obtainable", "Any source", "Unobtainable", "Vendor Recipe", "Upgraded", "Boss Item", "Corruption"}, function(index, value)
			self.listBuildFlag = true
		end)
	end
	self.controls.search = new("EditControl", {"BOTTOMLEFT",self,"TOPLEFT"}, {0, -2, 258, 18}, "", "Search", "%c", 100, function()
		self.listBuildFlag = true
	end, nil, nil, true)
	self.controls.searchMode = new("DropDownControl", {"LEFT",self.controls.search,"RIGHT"}, {2, 0, 100, 18}, { "Anywhere", "Names", "Modifiers" }, function(index, value)
		self.listBuildFlag = true
	end)
	self:BuildSortOrder()
	self.listBuildFlag = true
end)

function ItemDBClass:LoadLeaguesAndTypes()
	local leagueFlag = { }
	local typeFlag = { }
	for _, item in pairs(self.db.list) do
		if item.league then
			for leagueName in item.league:gmatch(" ?([%w ]+),?") do
				leagueFlag[leagueName] = true
			end
		end
		typeFlag[item.type] = true
	end
	for leagueName in pairsSortByKey(leagueFlag) do
		t_insert(self.leagueList, leagueName)
	end
	for type in pairsSortByKey(typeFlag) do
		t_insert(self.typeList, type)
	end
	self.leaguesAndTypesLoaded = true
end

function ItemDBClass:DoesItemMatchFilters(item)
	if self.controls.slot.selIndex > 1 then
		local primarySlot = item:GetPrimarySlot()
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
	if self.dbType == "UNIQUE" and self.controls.league.selIndex > 1 then
		if (self.controls.league.selIndex == 2 and item.league) or (self.controls.league.selIndex > 2 and (not item.league or not item.league:match(self.leagueList[self.controls.league.selIndex]))) then
			return false
		end
	end
	if self.dbType == "UNIQUE" and self.controls.obtainable.selIndex ~= 2 then
		local source = item.source or ""
		local obtainable = not (source == "No longer obtainable" or (item.league and item.league == "Race Events"))
		if (self.controls.obtainable.selIndex == 1 and not obtainable) or (self.controls.obtainable.selIndex == 3 and obtainable) then
			return false
		elseif (self.controls.obtainable.selIndex == 4 and not (source == "Vendor Recipe")) then
			return false
		elseif (self.controls.obtainable.selIndex == 5 and not (string.match(source, "Upgraded from"))) then
			return false
		elseif (self.controls.obtainable.selIndex == 6 and not (string.match(source, "Drops from unique"))) then
			return false
		elseif (self.controls.obtainable.selIndex == 7 and not (string.match(source, "Vaal Orb"))) then
			return false
		end
	end
	if self.dbType == "UNIQUE" and self.controls.requirement.selIndex > 1 then
		if (self.controls.requirement.selIndex == 2 or self.controls.requirement.selIndex == 4) and item.requirements.level and item.requirements.level > self.itemsTab.build.characterLevel then
			return false
		end
		if self.controls.requirement.selIndex > 2 and item.requirements and (item.requirements.strMod > self.itemsTab.build.calcsTab.mainOutput.Str or item.requirements.dexMod > self.itemsTab.build.calcsTab.mainOutput.Dex or item.requirements.intMod > self.itemsTab.build.calcsTab.mainOutput.Int) then
			return false
		end
	end
	local searchStr = self.controls.search.buf:lower():gsub("[%-%.%+%[%]%$%^%%%?%*]", "%%%0")
	if searchStr:match("%S") then
		local found = false
		local mode = self.controls.searchMode.selIndex
		if mode == 1 or mode == 2 then
			local err, match = PCall(string.matchOrPattern, item.name:lower(), searchStr)
			if not err and match then
				found = true
			end
		end
		if mode == 1 or mode == 3 then
			for _, line in pairs(item.enchantModLines) do
				local err, match = PCall(string.matchOrPattern, line.line:lower(), searchStr)
				if not err and match then
					found = true
					break
				end
			end
			for _, line in pairs(item.implicitModLines) do
				local err, match = PCall(string.matchOrPattern, line.line:lower(), searchStr)
				if not err and match then
					found = true
					break
				end
			end
			for _, line in pairs(item.explicitModLines) do
				local err, match = PCall(string.matchOrPattern, line.line:lower(), searchStr)
				if not err and match then
					found = true
					break
				end
			end
			if not found then
				searchStr = searchStr:gsub(" ","")
				for i, mod in ipairs(item.baseModList) do
					local err, match = PCall(string.matchOrPattern, mod.name:lower(), searchStr)
					if not err and match then
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

function ItemDBClass:SetSortMode(sortMode)
	self.sortMode = sortMode
	self:BuildSortOrder()
	self.listBuildFlag = true
end

function ItemDBClass:BuildSortOrder()
	wipeTable(self.sortDropList)
	for id,stat in pairs(data.powerStatList) do
		if not stat.ignoreForItems then
			t_insert(self.sortDropList, {
				label="Sort by "..stat.label,
				sortMode=stat.itemField or stat.stat,
				itemField=stat.itemField,
				stat=stat.stat,
				transform=stat.transform,
			})
		end
	end
	wipeTable(self.sortOrder)
	if self.controls.sort then
		self.controls.sort:CheckDroppedWidth(true)
		self.controls.sort.selIndex = 1
		self.controls.sort:SelByValue(self.sortMode, "sortMode")
		self.sortDetail = self.controls.sort.list[self.controls.sort.selIndex]
	end
	if self.sortDetail and self.sortDetail.stat then
		t_insert(self.sortOrder, self.sortControl.STAT)
	end
	t_insert(self.sortOrder, self.sortControl.NAME)
end

function ItemDBClass:BuildFilteredList()
	local list = { }
	for id, item in pairs(self.db.list) do
		if self:DoesItemMatchFilters(item) then
			t_insert(list, item)
		end
	end
	return list
end

-- Sort the list and publish it
function ItemDBClass:FinishList(list)
	table.sort(list, function(a, b)
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

	self.list = list
	self.defaultText = "^7No items found that match those filters."
end

function ItemDBClass:ListBuilder()
	local list = self:BuildFilteredList()

	if self.sortDetail and self.sortDetail.stat then -- stat-based
		local useFullDPS = self.sortDetail.stat == "FullDPS"
		local start = GetTime()
		local calcFunc, calcBase = self.itemsTab.build.calcsTab:GetMiscCalculator(self.build)
		for itemIndex, item in ipairs(list) do
			item.measuredPower = PowerCalcTasks.itemdb.measureOne(self.itemsTab, calcFunc, self.sortDetail, self.sortMode, useFullDPS, item)
			local now = GetTime()
			if now - start > 50 then
				self.defaultText = "^7Sorting... ("..m_floor(itemIndex/#list*100).."%)"
				coroutine.yield()
				start = now
			end
		end
	end

	self:FinishList(list)
end

-- Try to run the stat sort on background workers; returns true if a job was
-- launched, false if the caller should use the single-core coroutine instead
function ItemDBClass:LaunchParallelListBuild()
	if not (self.sortDetail and self.sortDetail.stat) or self.db.loading or not ParallelRunner:IsAvailable() then
		return false
	end
	local list = self:BuildFilteredList()
	-- Items are checked against every slot they fit, so weight them higher
	-- than single-calculation candidates
	if not ParallelRunner:ShouldParallelize(#list, 2) then
		return false
	end
	local build = self.itemsTab.build
	local buildXML = build:SaveDB("parallelSort")
	if not buildXML then
		return false
	end
	local useFullDPS = self.sortDetail.stat == "FullDPS"
	local calcFunc, calcBase = build.calcsTab:GetMiscCalculator()
	local names = { }
	for _, item in ipairs(list) do
		t_insert(names, item.name)
	end
	local batches = { }
	for i, nameSlice in ipairs(ParallelRunner:PartitionList(names, ParallelRunner:GetWorkerCount())) do
		batches[i] = { names = nameSlice }
	end
	local job
	job = ParallelRunner:LaunchJob({
		mode = "itemdb",
		buildXML = buildXML,
		common = {
			sortMode = self.sortDetail.sortMode,
			dbType = self.dbType,
		},
		batches = batches,
		total = #list,
		expectedBaseline = PowerCalcTasks.extractBaseline(calcBase, self.sortDetail, useFullDPS),
		onProgress = function(percent)
			self.defaultText = "^7Sorting... ("..percent.."%)"
		end,
		onComplete = function(payloads)
			if self.parallelJob ~= job then
				return
			end
			self.parallelJob = nil
			local powerByName = { }
			for _, payload in pairs(payloads) do
				for name, power in pairs(payload.results or { }) do
					powerByName[name] = PowerCalcTasks.decodeNumber(power)
				end
			end
			for _, item in ipairs(list) do
				item.measuredPower = powerByName[item.name] or 0
			end
			self:FinishList(list)
		end,
		onError = function()
			if self.parallelJob ~= job then
				return
			end
			self.parallelJob = nil
			self.listBuilder = coroutine.create(self.ListBuilder)
		end,
	})
	if not job then
		return false
	end
	self.parallelJob = job
	self.defaultText = "^7Sorting..."
	return true
end

function ItemDBClass:Draw(viewPort)
	if self.itemsTab.build.outputRevision ~= self.listOutputRevision then
		self.listBuildFlag = true
	end
	if self.listBuildFlag then
		self.listBuildFlag = false
		wipeTable(self.list)
		self.listBuilder = nil
		if self.parallelJob then
			-- A rebuild was requested while workers were still running; their
			-- results are stale, so cancel and start over
			self.parallelJob:Cancel()
			self.parallelJob = nil
		end
		self.listOutputRevision = self.itemsTab.build.outputRevision
		if not self:LaunchParallelListBuild() then
			self.listBuilder = coroutine.create(self.ListBuilder)
		end
	end
	if self.listBuilder and not self.db.loading then
		local res, errMsg = coroutine.resume(self.listBuilder, self)
		if launch.devMode and not res then
			error(errMsg)
		end
		if coroutine.status(self.listBuilder) == "dead" then
			self.listBuilder = nil
		end
	end
	if self.db.loading then
		self.defaultText = "^7Loading..."
	elseif not self.leaguesAndTypesLoaded then
		self:LoadLeaguesAndTypes()
	end
	self.ListControl.Draw(self, viewPort)
end

function ItemDBClass:GetRowValue(column, index, item)
	if column == 1 then
		return colorCodes[item.rarity] .. item.name
	end
end

function ItemDBClass:AddValueTooltip(tooltip, index, item)
	if main.popups[1] then
		tooltip:Clear()
		return
	end
	if tooltip:CheckForUpdate(item, IsKeyDown("SHIFT"), launch.devModeAlt, self.itemsTab.build.outputRevision) then
		self.itemsTab:AddItemTooltip(tooltip, item, nil, true)
	end
end

function ItemDBClass:GetDragValue(index, item)
	return "Item", item
end

function ItemDBClass:OnSelClick(index, item, doubleClick)
	if IsKeyDown("CTRL") then
		-- Add item
		local newItem = new("Item", item.raw)
		newItem:NormaliseQuality()
		self.itemsTab:AddItem(newItem, true)

		-- Equip item if able
		local slotName = newItem:GetPrimarySlot()
		if slotName and self.itemsTab.slots[slotName] then
			if self.itemsTab.slots[slotName].weaponSet == 1 and self.itemsTab.activeItemSet.useSecondWeaponSet then
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

function ItemDBClass:OnHoverKeyUp(key)
	if itemLib.wiki.matchesKey(key) then
		local item = self.ListControl:GetHoverValue()
		if item then
			itemLib.wiki.openItem(item)
		end
	end
end