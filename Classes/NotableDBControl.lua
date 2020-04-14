-- Path of Building
--
-- Class: Item DB
-- Item DB control.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_sort = table.sort
local m_max = math.max
local m_floor = math.floor

---@param node table
---@return string
local function GetNodeType(node)
	if node.type ~= "Notable" or node.group and not node.recipe then
		return nil
	end
	return node.recipe and "Anointable" or "Cluster"
end

---@class NotableDBControl : ListControl
local NotableDBClass = newClass("NotableDBControl", "ListControl", function(self, anchor, x, y, width, height, itemsTab, db)
	self.ListControl(anchor, x, y, width, height, 16, false, false)
	self.itemsTab = itemsTab
	self.db = db
	self.dragTargetList = { }
	self.sortControl = { 
		NAME = { key = "dn", dir = "ASCEND", func = function(a,b) return a < b end },
		STAT = { key = "measuredPower", dir = "DESCEND" },
	}
	self.sortDropList = { }
	self.sortOrder = { }
	self.sortMode = "NAME"
	local typeFlag = { }
	for _, node in pairs(db) do
		local nodeType = GetNodeType(node)
		if nodeType then
			typeFlag[nodeType] = true
		end
	end
	self.typeList = { }
	for type in pairs(typeFlag) do
		t_insert(self.typeList, type)
	end
	t_sort(self.typeList)
	t_insert(self.typeList, 1, "Any type")
	local baseY = -22
	self.controls.type = new("DropDownControl", {"BOTTOMLEFT",self,"TOPLEFT"}, 0, baseY, 179, 18, self.typeList, function(index, value)
		self.listBuildFlag = true
	end)
	self.controls.sort = new("DropDownControl", {"LEFT",self.controls.type,"RIGHT"}, 2, 0, 179, 18, self.sortDropList, function(index, value)
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
	local nodeType = GetNodeType(node)
	if not nodeType then
		return false
	end

	if self.itemsTab.build.spec.allocNodes[node.id] or self.itemsTab.build.calcsTab.mainEnv.grantedPassives[node.id] then
		return false
	end

	local typeSel = self.controls.type.selIndex
	if typeSel > 1 then
		if nodeType ~= self.typeList[typeSel] then
			return false
		end
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
		local start = GetTime()
		local calcFunc, calcBase = self.itemsTab.build.calcsTab:GetNodeCalculator(self.build)
		for nodeIndex, node in ipairs(list) do
			node.measuredPower = 0
			if node.modKey ~= "" then
				if not cache[node.modKey] then
					cache[node.modKey] = calcFunc({node})
				end
				local output = cache[node.modKey]
				node.measuredPower = self:CalculatePowerStat(self.sortDetail, output, calcBase)
			end
			local now = GetTime()
			if now - start > 50 then
				self.defaultText = "^7Sorting... ("..m_floor(nodeIndex/#list*100).."%)"
				coroutine.yield()
				start = now
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
		local nodeType = GetNodeType(node)
		return (nodeType == "Anointable" and colorCodes.INTELLIGENCE or colorCodes.DEXTERITY) .. node.dn
	end
end

---@param tooltip Tooltip
---@param index number
---@param node table
function NotableDBClass:AddValueTooltip(tooltip, index, node)
	if main.popups[1] then
		tooltip:Clear()
		return
	end
	if tooltip:CheckForUpdate(node, self.itemsTab.build.outputRevision) then
		self.itemsTab:AddNodeTooltip(tooltip, node, self.itemsTab.build)
	end
end

function NotableDBClass:GetDragValue(index, node)
	return "Node", node
end

function NotableDBClass:OnSelClick(index, node, doubleClick)
	-- Do nothing
end

function NotableDBClass:OnSelCopy(index, node)
	Copy(item.dn)
end