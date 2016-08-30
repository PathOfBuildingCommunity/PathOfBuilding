-- Path of Building
--
-- Class: Item DB
-- Item DB control.
--
local launch, main = ...

local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local ItemDBClass = common.NewClass("ItemDB", "Control", "ControlHost", function(self, anchor, x, y, width, height, itemsTab, db)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.itemsTab = itemsTab
	self.db = db
	self.sortControl = { 
		NAME = { key = "name", order = 1, dir = "ASCEND", func = function(a,b) return a:gsub("^The ","") < b:gsub("^The ","") end }
	}
	self.controls.scrollBar = common.New("ScrollBarControl", {"RIGHT",self,"RIGHT"}, -1, 0, 16, 0, 32)
	self.controls.scrollBar.height = function()
		local width, height = self:GetSize()
		return height - 2
	end
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
	self.slotList = { "Any slot", "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Ring", "Belt", "Jewel" }
	self.controls.slot = common.New("DropDownControl", {"BOTTOMLEFT",self,"TOPLEFT"}, 0, -22, 95, 18, self.slotList, function()
		self:BuildOrderList()
	end)
	self.controls.type = common.New("DropDownControl", {"LEFT",self.controls.slot,"RIGHT"}, 2, 0, 135, 18, self.typeList, function()
		self:BuildOrderList()
	end)
	self.controls.league = common.New("DropDownControl", {"LEFT",self.controls.type,"RIGHT"}, 2, 0, 126, 18, self.leagueList, function()
		self:BuildOrderList()
	end)
	self.controls.league.shown = function()
		return #self.leagueList > 2
	end
	self.controls.search = common.New("EditControl", {"BOTTOMLEFT",self,"TOPLEFT"}, 0, -2, 258, 18, "", "Search", "[%C]")
	self.controls.searchMode = common.New("DropDownControl", {"LEFT",self.controls.search,"RIGHT"}, 2, 0, 100, 18, { "Anywhere", "Names", "Modifiers" }, function()
		self:BuildOrderList()
	end)
	self:BuildSortOrder()
	self:BuildOrderList()
end)

function ItemDBClass:DoesItemMatchFilters(item)
	if self.controls.slot.sel > 1 then
		if itemLib.getPrimarySlotForItem(item) ~= self.slotList[self.controls.slot.sel] then
			return false
		end
	end
	if self.controls.type.sel > 1 then
		if item.type ~= self.typeList[self.controls.type.sel] then
			return false
		end
	end
	if self.controls.league.sel > 1 then
		if (self.controls.league.sel == 2 and item.league) or (self.controls.league.sel > 2 and (not item.league or not item.league:match(self.leagueList[self.controls.league.sel]))) then
			return false
		end
	end
	local searchStr = self.controls.search.buf:lower()
	if searchStr:match("%S") then
		local found = false
		local mode = self.controls.searchMode.sel
		if mode == 1 or mode == 2 then
			if item.name:lower():match(searchStr) then
				found = true
			end
		end
		if mode == 1 or mode == 3 then
			for _, line in pairs(item.modLines) do
				if line.line:lower():match(searchStr) then
					found = true
					break
				end
			end
			if not found then
				searchStr = searchStr:gsub(" ","")
				for modName in pairs(item.baseModList) do
					if modName:lower():gsub("_",""):match(searchStr) then
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

function ItemDBClass:BuildOrderList()
	self.orderList = wipeTable(self.orderList)
	for id, item in pairs(self.db.list) do
		if self:DoesItemMatchFilters(item) then
			t_insert(self.orderList, item)
		end
	end
	table.sort(self.orderList, function(a, b)
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

function ItemDBClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	if self:GetMouseOverControl() then
		return true
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
end

function ItemDBClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local list = self.db.list
	local orderList = self.orderList
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension(#orderList * 16, height - 4)
	if self.hasFocus then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	self:DrawControls(viewPort)
	SetViewport(x + 2, y + 2, width - 20, height - 4)
	local ttItem, ttY, ttWidth
	local minIndex = m_floor(scrollBar.offset / 16 + 1)
	local maxIndex = m_min(m_floor((scrollBar.offset + height) / 16 + 1), #orderList)
	for index = minIndex, maxIndex do
		local item = orderList[index]
		local itemY = 16 * (index - 1) - scrollBar.offset
		local nameWidth = DrawStringWidth(16, "VAR", item.name)
		if not scrollBar.dragging and (not self.itemsTab.selControl or self.hasFocus or self.controls.search.hasFocus) then
			local cursorX, cursorY = GetCursorPos()
			local relX = cursorX - (x + 2)
			local relY = cursorY - (y + 2)
			if relX >= 0 and relX < width - 17 and relY >= 0 and relY >= itemY and relY < height - 2 and relY < itemY + 16 then
				ttItem = item
				ttWidth = m_max(nameWidth + 8, relX)
				ttY = itemY + y + 2
			end
		end
		if item == ttItem or item == self.selItem then
			if self.hasFocus then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.5, 0.5, 0.5)
			end
			DrawImage(nil, 0, itemY, width - 20, 16)
			SetDrawColor(0.15, 0.15, 0.15)
			DrawImage(nil, 0, itemY + 1, width - 20, 14)		
		end
		SetDrawColor(data.colorCodes[item.rarity])
		DrawString(0, itemY, "LEFT", 16, "VAR", item.name)
	end
	SetViewport()
	if ttItem then
		self.itemsTab:AddItemTooltip(ttItem, nil, true)
		SetDrawLayer(nil, 100)
		main:DrawTooltip(x + 2, ttY, ttWidth, 16, viewPort, data.colorCodes[ttItem.rarity], true)
		SetDrawLayer(nil, 0)
	end
end

function ItemDBClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key)
	end
	if not self:IsMouseOver() and key:match("BUTTON") then
		return
	end
	if key == "LEFTBUTTON" then
		self.selItem = nil
		local x, y = self:GetPos()
		local width, height = self:GetSize()
		local cursorX, cursorY = GetCursorPos()
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
			local index = m_floor((cursorY - y - 2 + self.controls.scrollBar.offset) / 16) + 1
			local selItem = self.orderList[index]
			if selItem then
				self.selItem = selItem
				self.selIndex = index
				if doubleClick then
					self.itemsTab:CreateDisplayItemFromRaw(selItem.raw)
				end
			end
		end
	elseif key == "c" and IsKeyDown("CTRL") then
		if self.selItem then
			Copy(self.selItem.raw)
		end
	end
	return self
end

function ItemDBClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "WHEELDOWN" then
		self.controls.scrollBar:Scroll(1)
	elseif key == "WHEELUP" then
		self.controls.scrollBar:Scroll(-1)
	end
	return self
end