-- Path of Building
--
-- Class: Notable DB
-- Notable DB control.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_sort = table.sort
local m_max = math.max
local m_floor = math.floor
local m_huge = math.huge
local s_format = string.format

---@param node table
---@return boolean
local function IsAnointableNode(node)
	return node.type == "Notable" and node.recipe and #node.recipe >= 1
end

---@class NotableDBControl : ListControl
local NotableDBClass = newClass("NotableDBControl", "ListControl", function(self, anchor, x, y, width, height, itemsTab, db, dbType)
	self.ListControl(anchor, x, y, width, height, 16, "VERTICAL", false)
	self.itemsTab = itemsTab
	self.db = db
	self.dbType = dbType
	self.dragTargetList = { }
	self.sortControl = {
		NAME = { key = "dn", dir = "ASCEND", func = function(a,b) return a < b end },
		STAT = { key = "measuredPower", dir = "DESCEND" },
	}
	self.sortDropList = { }
	self.sortOrder = { }
	self.sortMode = "NAME"
	self.controls.sort = new("DropDownControl", {"BOTTOMLEFT",self,"TOPLEFT"}, 0, -22, 360, 18, self.sortDropList, function(index, value)
		self:SetSortMode(value.sortMode)
	end)
	self.controls.search = new("EditControl", {"BOTTOMLEFT",self,"TOPLEFT"}, 0, -2, 258, 18, "", "Search", "%c", 100, function()
		self.listBuildFlag = true
	end)
	self.controls.searchMode = new("DropDownControl", {"LEFT",self.controls.search,"RIGHT"}, 2, 0, 100, 18, { "Anywhere", "Names", "Modifiers" }, function(index, value)
		self.listBuildFlag = true
	end)
	self:BuildSortOrder()
	self.listBuildFlag = true
end)

---@param node table @The notable node to check
---@return boolean @Whether the notable matches the type and search filters.
function NotableDBClass:DoesNotableMatchFilters(node)
	if not IsAnointableNode(node) then
		return false
	end

	local searchStr = self.controls.search.buf:lower()
	if searchStr:match("%S") then
		local found = false
		local mode = self.controls.searchMode.selIndex
		if mode == 1 or mode == 2 then
			if node.dn:lower():find(searchStr, 1, true) then
				found = true
			end
		end
		if mode == 1 or mode == 3 then
			for _, line in ipairs(node.sd) do
				if line:lower():find(searchStr, 1, true) then
					found = true
					break
				end
			end
		end
		if not found then
			return false
		end
	end
	return true
end

---@param sortMode table
function NotableDBClass:SetSortMode(sortMode)
	self.sortMode = sortMode
	self:BuildSortOrder()
	self.listBuildFlag = true
end

function NotableDBClass:BuildSortOrder()
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
		self.controls.sort.selIndex = 1
		self.controls.sort:SelByValue(self.sortMode, "sortMode")
		self.sortDetail = self.controls.sort.list[self.controls.sort.selIndex]
	end
	if self.sortDetail and self.sortDetail.stat then
		t_insert(self.sortOrder, self.sortControl.STAT)
	end
	t_insert(self.sortOrder, self.sortControl.NAME)
end

function NotableDBClass:CalculatePowerStat(selection, original, modified)
	if modified.Minion then
		original = original.Minion
		modified = modified.Minion
	end
	local originalValue = original[selection.stat] or 0
	local modifiedValue = modified[selection.stat] or 0
	if selection.transform then
		originalValue = selection.transform(originalValue)
		modifiedValue = selection.transform(modifiedValue)
	end
	return originalValue - modifiedValue
end

function NotableDBClass:ListBuilder()
	local list = { }
	for id, node in pairs(self.db) do
		if self:DoesNotableMatchFilters(node) then
			t_insert(list, node)
		end
	end

	if self.sortDetail and self.sortDetail.stat then -- stat-based
		local cache = { }
		local infinites = { }
		local start = GetTime()
		local calcFunc = self.itemsTab.build.calcsTab:GetMiscCalculator()
		local itemType = self.itemsTab.displayItem.base.type
		local storedGlobalCacheDPSView = GlobalCache.useFullDPS
		GlobalCache.useFullDPS = GlobalCache.numActiveSkillInFullDPS > 0
		local calcBase = calcFunc({ repSlotName = itemType, repItem = self.itemsTab:anointItem(nil) }, {})
		self.sortMaxPower = 0
		for nodeIndex, node in ipairs(list) do
			node.measuredPower = 0
			if node.modKey ~= "" then
				local output = calcFunc({ repSlotName = itemType, repItem = self.itemsTab:anointItem(node) }, {})
				node.measuredPower = self:CalculatePowerStat(self.sortDetail, output, calcBase)
				if node.measuredPower == m_huge then
					t_insert(infinites, node)
				else
					self.sortMaxPower = m_max(self.sortMaxPower, node.measuredPower)
				end
			end
			local now = GetTime()
			if now - start > 50 then
				self.defaultText = "^7Sorting... ("..m_floor(nodeIndex/#list*100).."%)"
				coroutine.yield()
				start = now
			end
		end
		GlobalCache.useFullDPS = storedGlobalCacheDPSView
		
		if #infinites > 0 then
			self.sortMaxPower = self.sortMaxPower * 2
			for _, node in ipairs(infinites) do
				node.measuredPower = self.sortMaxPower
			end
		end
	end

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
	self.defaultText = "^7No notables found that match those filters."
end

---@param viewPort table<string, number>
function NotableDBClass:Draw(viewPort)
	if self.itemsTab.build.outputRevision ~= self.listOutputRevision then
		self.listBuildFlag = true
	end
	if self.listBuildFlag then
		self.listBuildFlag = false
		wipeTable(self.list)
		self.listBuilder = coroutine.create(self.ListBuilder)
		self.listOutputRevision = self.itemsTab.build.outputRevision
	end
	if self.listBuilder then
		local res, errMsg = coroutine.resume(self.listBuilder, self)
		if launch.devMode and not res then
			error(errMsg)
		end
		if coroutine.status(self.listBuilder) == "dead" then
			self.listBuilder = nil
		end
	end
	self.ListControl.Draw(self, viewPort)
end

---@param column number
---@param index number
---@param node table
---@return string
function NotableDBClass:GetRowValue(column, index, node)
	if column == 1 then
		if self.sortDetail and self.sortDetail.stat then
			if self.sortMaxPower and self.sortMaxPower > 0 and node.measuredPower and node.measuredPower > 0 then
				local scaledPower = node.measuredPower / self.sortMaxPower
				local powerRed = scaledPower * (0xFF - 0x80) + 0x80
				local powerColor = s_format("^x%X8080", powerRed)
				return powerColor..node.dn
			else
				return "^x808080"..node.dn
			end
		else
			return colorCodes.CRAFTED..node.dn
		end
	end
end

---@param tooltip Tooltip
---@param index number
---@param node table
function NotableDBClass:AddValueTooltip(tooltip, index, node)
	local dropdownDropped = self.controls.type and self.controls.type.dropped or self.controls.sort.dropped or self.controls.searchMode.dropped
	if dropdownDropped or (main.popups[1] and main.popups[1].title ~= "Anoint Item") then
		tooltip:Clear()
		return
	end
	if tooltip:CheckForUpdate(node, self.itemsTab.displayItem) then
		-- Node name
		self.itemsTab.socketViewer:AddNodeName(tooltip, node, self.itemsTab.build)

		-- Node description
		if node.sd[1] then
			tooltip:AddLine(16, "")
			for i, line in ipairs(node.sd) do
				tooltip:AddLine(16, ((node.mods[i].extra or not node.mods[i].list) and colorCodes.UNSUPPORTED or colorCodes.MAGIC)..line)
			end
		end

		-- Reminder text
		if node.reminderText then
			tooltip:AddSeparator(14)
			for _, line in ipairs(node.reminderText) do
				tooltip:AddLine(14, "^xA0A080"..line)
			end
		end

		-- Comparison
		tooltip:AddSeparator(14)
		self.itemsTab:AppendAnointTooltip(tooltip, node)
	end
end

---@param index number
---@param node table
function NotableDBClass:GetDragValue(index, node)
	return "Node", node
end

---@param index number
---@param node table
---@param doubleClick boolean
function NotableDBClass:OnSelClick(index, node, doubleClick)
	-- Do nothing
end

---@param index number
---@param node table
function NotableDBClass:OnSelCopy(index, node)
	Copy(item.dn)
end