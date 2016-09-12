-- Path of Building
--
-- Class: Gem Select
-- Gem selection combobox
--

local launch, main = ...

local t_insert = table.insert
local t_sort = table.sort
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local GemSelectClass = common.NewClass("GemSelectControl", "EditControl", function(self, anchor, x, y, width, height, changeFunc)
	self.EditControl(anchor, x, y, width, height)
	self.controls.scrollBar = common.New("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, -1, 0, 16, 0, (height - 4) * 4)
	self.controls.scrollBar.y = function()
		local width, height = self:GetSize()
		return height + 1
	end
	self.controls.scrollBar.height = function()
		return (height - 4) * m_min(#self.list, 10) + 2
	end
	self.controls.scrollBar.shown = function()
		return self.dropped and self.controls.scrollBar.enabled
	end
	self.list = { }
	self.gemChangeFunc = changeFunc
	self.changeFunc = function()
		self.dropped = true
		self.selIndex = 0
		self:BuildList()
		self.gemChangeFunc(self.buf)
	end
end)

function GemSelectClass:BuildList()
	self.controls.scrollBar.offset = 0
	wipeTable(self.list)
	self.searchStr = self.buf
	if self.searchStr:match("%S") then
		-- Search for gem name using increasingly broad search patterns
		local patternList = {
			"^ "..self.searchStr:gsub("%a", function(a) return "["..a:upper()..a:lower().."]" end).."$", -- Exact match (case-insensitive)
			"^"..self.searchStr:gsub("%a", " %0%%l+").."$", -- Simple abbreviation ("CtF" -> "Cold to Fire")
			"^"..self.searchStr:gsub(" ",""):gsub("%l", "%%l*%0").."%l+$", -- Abbreviated words ("CldFr" -> "Cold to Fire")
			"^"..self.searchStr:gsub(" ",""):gsub("%a", ".*%0"), -- Global abbreviation ("CtoF" -> "Cold to Fire")
			"^"..self.searchStr:gsub(" ",""):gsub("%a", function(a) return ".*".."["..a:upper()..a:lower().."]" end), -- Case insensitive global abbreviation ("ctof" -> "Cold to Fire")
		}
		for i, pattern in ipairs(patternList) do
			for name in pairs(data.gems) do
				if name ~= "_default" and (" "..name):match(pattern) then
					t_insert(self.list, name)
				end
			end
			if self.list[1] then
				break
			end
		end
	else
		for name in pairs(data.gems) do
			if name ~= "_default" then
				t_insert(self.list, name)
			end
		end
	end
	if not self.list[1] then
		self.list[1] = "<No matches>"
	end
	t_sort(self.list)
end

function GemSelectClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	if self:GetMouseOverControl() then
		return true
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	local dropExtra = self.dropped and (height - 4) * m_min(#self.list, 10) + 2 or 0
	local mOver = cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height + dropExtra
	local mOverComp
	if mOver then
		if cursorY < y + height then
			mOverComp = "BODY"
		else
			mOverComp = "DROP"
		end
	end
	return mOver, mOverComp
end

function GemSelectClass:Draw(viewPort)
	self.EditControl:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local enabled = self:IsEnabled()
	local mOver, mOverComp = self:IsMouseOver()
	local dropHeight = (height - 4) * m_min(#self.list, 10)
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension((height - 4) * #self.list, dropHeight)
	if self.dropped then
		SetDrawLayer(nil, 5)
		SetDrawColor(1, 1, 1)
		DrawImage(nil, x, y + height, width, dropHeight + 4)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, x + 1, y + height + 1, width - 2, dropHeight + 2)
		SetDrawLayer(nil, 0)
	end
	if self.dropped then
		SetDrawLayer(nil, 5)
		local cursorX, cursorY = GetCursorPos()
		self.hoverSel = mOver and math.floor((cursorY - y - height + scrollBar.offset) / (height - 4)) + 1
		if self.hoverSel and self.hoverSel < 1 then
			self.hoverSel = nil
		end
		SetViewport(x + 2, y + height + 2, width - 4, dropHeight)
		local minIndex = m_floor(scrollBar.offset / 16 + 1)
		local maxIndex = m_min(m_floor((scrollBar.offset + dropHeight) / 16 + 1), #self.list)
		for index = minIndex, maxIndex do
			local y = (index - 1) * (height - 4) - scrollBar.offset
			if index == self.hoverSel or index == self.selIndex then
				SetDrawColor(0.33, 0.33, 0.33)
				DrawImage(nil, 0, y, width - 4, height - 4)
			end
			SetDrawColor(1, 1, 1)
			local gemData = data.gems[self.list[index]]
			if gemData then
				if gemData.strength then
					SetDrawColor(data.colorCodes.STRENGTH)
				elseif gemData.dexterity then
					SetDrawColor(data.colorCodes.DEXTERITY)
				elseif gemData.intelligence then
					SetDrawColor(data.colorCodes.INTELLIGENCE)
				end
			end
			DrawString(0, y, "LEFT", height - 4, "VAR", self.list[index])
		end
		SetViewport()
		self:DrawControls(viewPort)
		SetDrawLayer(nil, 0)
	end
end

function GemSelectClass:OnFocusGained()
	self.EditControl:OnFocusGained()
	if not self.dropped then
		self.dropped = true
		self.selIndex = 0
		self:BuildList()
	end
end

function GemSelectClass:OnFocusLost()
	self.dropped = false
end

function GemSelectClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		self.selControl = mOverControl
		return mOverControl:OnKeyDown(key) and self
	else
		self.selControl = nil
	end
	if self.dropped then
		if key:match("BUTTON") and not self:IsMouseOver() then
			self.dropped = false
			return
		end
		if key == "LEFTBUTTON" then
			if self.hoverSel and data.gems[self.list[self.hoverSel]] then
				self.dropped = false
				self:SetText(self.list[self.hoverSel])
				self.gemChangeFunc(self.buf)
				return self
			end
		elseif key == "RETURN" then
			self.dropped = false
			return self
		elseif key == "WHEELUP" then
			self.controls.scrollBar:Scroll(-1)
		elseif key == "WHEELDOWN" then
			self.controls.scrollBar:Scroll(1)
		elseif key == "DOWN" then
			if self.selIndex < #self.list then
				self.selIndex = self.selIndex + 1
				self:SetText(self.list[self.selIndex])
				self.gemChangeFunc(self.buf)
			end
		elseif key == "UP" then
			if self.selIndex > 0 then
				self.selIndex = self.selIndex - 1
				if self.selIndex == 0 then
					self:SetText(self.searchStr)
				else
					self:SetText(self.list[self.selIndex])
				end
				self.gemChangeFunc(self.buf)
			end
		end
	end
	local newSel = self.EditControl:OnKeyDown(key, doubleClick)
	return newSel == self.EditControl and self or newSel
end

function GemSelectClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if self.selControl then
		local newSel = self.selControl:OnKeyUp(key)
		if newSel then
			return self
		else
			self.selControl = nil
		end
	end
	local newSel = self.EditControl:OnKeyUp(key)
	return newSel == self.EditControl and self or newSel
end