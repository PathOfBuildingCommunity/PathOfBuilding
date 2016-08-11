-- Path of Building
--
-- Class: Item DB
-- Item DB control
--
local launch, main = ...

local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max

local ItemDBClass = common.NewClass("ItemDB", function(self, x, y, width, height, itemsMain, db)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.itemsMain = itemsMain
	self.db = db
	self.sortControl = { 
		NAME = { key = "name", order = 1, dir = "ASCEND", func = function(a,b) return a:gsub("^The ","") < b:gsub("^The ","") end }
	}
	self.scrollBar = common.New("ScrollBarControl", 0, 0, 16, height - 2, 32)
	self.controls = { }
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
	self.controls.slot = common.New("DropDownControl", function()local x,y=self:GetPos()return x end, function()local x,y=self:GetPos()return y-40 end, 95, 18, self.slotList, function()
		self:BuildOrderList()
	end)
	self.controls.type = common.New("DropDownControl", function()local x,y=self:GetPos()return x+97 end, function()local x,y=self:GetPos()return y-40 end, 135, 18, self.typeList, function()
		self:BuildOrderList()
	end)
	self.controls.league = common.New("DropDownControl", function()local x,y=self:GetPos()return x+97+137 end, function()local x,y=self:GetPos()return y-40 end, 126, 18, self.leagueList, function()
		self:BuildOrderList()
	end)
	self.controls.search = common.New("EditControl", function()local x,y=self:GetPos()return x end, function()local x,y=self:GetPos()return y-20 end, 258, 18, "", "Search", "[ %w+]")
	self.controls.searchMode = common.New("DropDownControl", function()local x,y=self:GetPos()return x+width-100 end, function()local x,y=self:GetPos()return y-20 end, 100, 18, { "Anywhere", "Names", "Modifiers" }, function()
		self:BuildOrderList()
	end)
	self:BuildSortOrder()
	self:BuildOrderList()
end)

function ItemDBClass:GetPos()
	return type(self.x) == "function" and self:x() or self.x,
		   type(self.y) == "function" and self:y() or self.y
end

function ItemDBClass:DoesItemMatchFilters(item)
	if self.controls.slot.sel > 1 then
		if self.itemsMain:GetPrimarySlotForItem(item) ~= self.slotList[self.controls.slot.sel] then
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
	local searchStr = self.controls.search.edit.buf:lower()
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
	for _, control in pairs(self.controls) do
		if control:IsMouseOver() then
			return true
		end
	end
	local x, y = self:GetPos()
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= x and cursorY >= y and cursorX < x + self.width and cursorY < y + self.height
end

function ItemDBClass:Draw(viewPort)
	for _, control in pairs(self.controls) do
		control:Draw(viewPort)
	end
	local list = self.db.list
	self:BuildOrderList()
	local orderList = self.orderList
	local x, y = self:GetPos()
	if self.itemsMain.selControl == self then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, self.width, self.height)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + 1, self.width - 2, self.height - 2)
	self.scrollBar.x = x + self.width - 17
	self.scrollBar.y = y + 1
	self.scrollBar:SetContentHeight(#orderList * 16, self.height - 4)
	self.scrollBar:Draw()
	SetViewport(x + 2, y + 2, self.width - 18, self.height - 4)
	local ttItem, ttY, ttWidth
	for index, item in pairs(orderList) do
		local itemY = 16 * (index - 1) - self.scrollBar.offset
		local nameWidth = DrawStringWidth(16, "VAR", item.name)
		if not self.scrollBar.dragging and (not self.itemsMain.selControl or self.itemsMain.selControl == self or self.itemsMain.selControl == self.controls.search) then
			local cursorX, cursorY = GetCursorPos()
			local relX = cursorX - (x + 2)
			local relY = cursorY - (y + 2)
			if relX >= 0 and relX < self.width - 17 and relY >= 0 and relY >= itemY and relY < self.height - 2 and relY < itemY + 16 then
				ttItem = item
				ttWidth = m_max(nameWidth + 8, relX)
				ttY = itemY + y + 2
			end
		end
		if item == ttItem or item == self.selItem then
			if self.itemsMain.selControl == self then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.5, 0.5, 0.5)
			end
			DrawImage(nil, 0, itemY, self.width - 20, 16)
			SetDrawColor(0.15, 0.15, 0.15)
			DrawImage(nil, 0, itemY + 1, self.width - 20, 14)		
		end
		SetDrawColor(data.colorCodes[item.rarity])
		DrawString(0, itemY, "LEFT", 16, "VAR", item.name)
	end
	SetViewport()
	if ttItem then
		self.itemsMain:AddItemTooltip(ttItem, true)
		SetDrawLayer(nil, 100)
		main:DrawTooltip(x + 2, ttY, ttWidth, 16, viewPort, data.colorCodes[ttItem.rarity], true)
		SetDrawLayer(nil, 0)
	end
end

function ItemDBClass:OnKeyDown(key, doubleClick)
	if self.scrollBar:IsMouseOver() then
		return self.scrollBar:OnKeyDown(key)
	end
	for _, control in pairs(self.controls) do
		if control:IsMouseOver() then
			return control:OnKeyDown(key)
		end
	end
	if not self:IsMouseOver() then
		return
	end
	if key == "LEFTBUTTON" then
		self.selItem = nil
		local x, y = self:GetPos()
		local cursorX, cursorY = GetCursorPos()
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + self.width - 18 and cursorY < y + self.height - 2 then
			local index = math.floor((cursorY - y - 2 + self.scrollBar.offset) / 16) + 1
			local selItem = self.orderList[index]
			if selItem then
				self.selItem = selItem
				self.selIndex = index
				if doubleClick then
					self.itemsMain:CreateDisplayItemFromRaw(selItem.raw)
				end
			end
		end
	end
	return self
end

function ItemDBClass:OnKeyUp(key)
	if key == "WHEELDOWN" then
		self.scrollBar:Scroll(1)
	elseif key == "WHEELUP" then
		self.scrollBar:Scroll(-1)
	elseif self.selItem then
		--[[if key == "BACK" or key == "DELETE" then
			launch:ShowPrompt(0, 0, 0, "Are you sure you want to delete:\n"..self.selItem.name.."\n\nPress Y to confirm.", function(key)
				if key == "y" then
					self.db.list[self.selItem.id] = nil
					self.selItem = nil
				end
				return true
			end)
		end]]
	end
	return self
end