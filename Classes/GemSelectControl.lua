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

local GemSelectClass = common.NewClass("GemSelectControl", "EditControl", function(self, anchor, x, y, width, height, skillsTab, index, changeFunc)
	self.EditControl(anchor, x, y, width, height, nil, nil, "^ %a'")
	self.controls.scrollBar = common.New("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, -1, 0, 18, 0, (height - 4) * 4)
	self.controls.scrollBar.y = function()
		local width, height = self:GetSize()
		return height + 1
	end
	self.controls.scrollBar.height = function()
		return (height - 4) * m_min(#self.list, 15) + 2
	end
	self.controls.scrollBar.shown = function()
		return self.dropped and self.controls.scrollBar.enabled
	end
	self.skillsTab = skillsTab
	self.index = index
	self.gemChangeFunc = changeFunc
	self.list = { }
	self.changeFunc = function()
		self.dropped = true
		self.selIndex = 0
		self:BuildList(self.buf)
		self:UpdateGem()
	end
end)

function GemSelectClass:BuildList(buf)
	self.controls.scrollBar.offset = 0
	wipeTable(self.list)
	self.searchStr = buf
	if self.searchStr:match("%S") then
		-- Search for gem name using increasingly broad search patterns
		local patternList = {
			"^ "..self.searchStr:lower().."$", -- Exact match
			"^"..self.searchStr:lower():gsub("%a", " %0%%l+").."$", -- Simple abbreviation ("CtF" -> "Cold to Fire")
			"^ "..self.searchStr:lower(), -- Starts with
			self.searchStr:lower(), -- Contains
		}
		local added = { }
		for i, pattern in ipairs(patternList) do
			local matchList = { }
			for name, grantedEffect in pairs(self.skillsTab.build.data.gems) do
				if not added[name] and (" "..name:lower()):match(pattern) then
					t_insert(matchList, name)
					added[name] = true
				end
			end
			t_sort(matchList)
			for _, name in ipairs(matchList) do
				t_insert(self.list, name)
			end
		end
		local tagName = self.searchStr:match("^%s*(%a+)%s*$")
		if tagName then
			local matchList = { }
			for name, grantedEffect in pairs(self.skillsTab.build.data.gems) do
				if not added[name] and grantedEffect.gemTags[tagName:lower()] == true then
					t_insert(matchList, name)
					added[name] = true
				end
			end
			t_sort(matchList)
			for _, name in ipairs(matchList) do
				t_insert(self.list, name)
			end
		end
	else
		for name, grantedEffect in pairs(self.skillsTab.build.data.gems) do
			t_insert(self.list, name)
		end
		t_sort(self.list)
	end
	if not self.list[1] then
		self.list[1] = "<No matches>"
		self.noMatches = true
	else
		self.noMatches = false
	end
end

function GemSelectClass:UpdateGem(setText, addUndo)
	local gemName = self.list[m_max(self.selIndex, 1)]
	if self.buf:match("%S") and self.skillsTab.build.data.gems[gemName] then
		self.gemName = gemName
	else
		self.gemName = ""
	end
	if setText then	
		self:SetText(self.gemName)
	end
	self.gemChangeFunc(self.gemName, addUndo and self.gemName ~= self.initialBuf)
end

function GemSelectClass:ScrollSelIntoView()
	local width, height = self:GetSize()
	local scrollBar = self.controls.scrollBar
	local dropHeight = (height - 4) * m_min(#self.list, 15)
	scrollBar:SetContentDimension((height - 4) * #self.list, dropHeight)
	scrollBar:ScrollIntoView((self.selIndex - 2) * (height - 4), 3 * (height - 4))
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
	local dropExtra = self.dropped and (height - 4) * m_min(#self.list, 15) + 2 or 0
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
	local dropHeight = (height - 4) * m_min(#self.list, 15)
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
		self.hoverSel = mOverComp == "DROP" and math.floor((cursorY - y - height + scrollBar.offset) / (height - 4)) + 1
		if self.hoverSel and not self.skillsTab.build.data.gems[self.list[self.hoverSel]] then
			self.hoverSel = nil
		end
		SetViewport(x + 2, y + height + 2, width - 4, dropHeight)
		local minIndex = m_floor(scrollBar.offset / 16 + 1)
		local maxIndex = m_min(m_floor((scrollBar.offset + dropHeight) / 16 + 1), #self.list)
		for index = minIndex, maxIndex do
			local y = (index - 1) * (height - 4) - scrollBar.offset
			if index == self.hoverSel or index == self.selIndex or (index == 1 and self.selIndex == 0) then
				SetDrawColor(0.33, 0.33, 0.33)
				DrawImage(nil, 0, y, width - 4, height - 4)
			end
			SetDrawColor(1, 1, 1)
			local grantedEffect = self.skillsTab.build.data.gems[self.list[index]]
			if grantedEffect then
				if grantedEffect.color == 1 then
					SetDrawColor(colorCodes.STRENGTH)
				elseif grantedEffect.color == 2 then
					SetDrawColor(colorCodes.DEXTERITY)
				elseif grantedEffect.color == 3 then
					SetDrawColor(colorCodes.INTELLIGENCE)
				end
			end
			DrawString(0, y, "LEFT", height - 4, "VAR", self.list[index])
			if grantedEffect and grantedEffect.support and self.skillsTab.displayGroup.displaySkillList then
				local gem = { grantedEffect = grantedEffect }
				for _, activeSkill in ipairs(self.skillsTab.displayGroup.displaySkillList) do
					if calcLib.gemCanSupport(gem, activeSkill) then
						SetDrawColor(0.33, 1, 0.33)
						main:DrawCheckMark(width - 4 - height / 2 - (scrollBar.enabled and 18 or 0), y + (height - 4) / 2, (height - 4) * 0.8)
						break
					end
				end
			end
		end
		SetViewport()
		self:DrawControls(viewPort)
		if self.hoverSel then
			local calcFunc, calcBase = self.skillsTab.build.calcsTab:GetMiscCalculator(self.build)
			if calcFunc then
				local gemList = self.skillsTab.displayGroup.gemList
				local oldGem
				if gemList[self.index] then
					oldGem = copyTable(gemList[self.index], true)
				else
					gemList[self.index] = { level = 20, quality = 0, enabled = true }
				end
				local gem = gemList[self.index]
				gem.grantedEffect = self.skillsTab.build.data.gems[self.list[self.hoverSel]]
				if not gem.grantedEffect.levels[gem.level] then
					gem.level = gem.grantedEffect.defaultLevel
				end
				local output = calcFunc()
				if oldGem then
					gem.grantedEffect = oldGem.grantedEffect
					gem.level = oldGem.level
				else
					gemList[self.index] = nil
				end
				self.skillsTab.build:AddStatComparesToTooltip(calcBase, output, "^7Selecting this gem will give you:")
				main:DrawTooltip(x, y + height + 2 + (self.hoverSel - 1) * (height - 4) - scrollBar.offset, width, height - 4, viewPort)
			end
		end
		SetDrawLayer(nil, 0)
	else
		local hoverControl 
		if self.skillsTab.selControl and self.skillsTab.selControl._className == "GemSelectControl" then
			hoverControl = self.skillsTab.selControl
		else
			hoverControl = self.skillsTab:GetMouseOverControl()
		end
		if hoverControl and hoverControl._className == "GemSelectControl" then
			local thisGem = self.skillsTab.displayGroup.gemList[self.index]
			local hoverGem = self.skillsTab.displayGroup.gemList[hoverControl.index]
			if thisGem and hoverGem and thisGem.enabled and hoverGem.enabled and thisGem.grantedEffect and hoverGem.grantedEffect and
			  ((hoverGem.grantedEffect.support and not thisGem.grantedEffect.support and hoverGem.displayGem and hoverGem.displayGem.isSupporting[thisGem.grantedEffect.name]) or
			   (thisGem.grantedEffect.support and not hoverGem.grantedEffect.support and thisGem.displayGem and thisGem.displayGem.isSupporting[hoverGem.grantedEffect.name])) then
			   SetDrawColor(0.33, 1, 0.33, 0.25)
			   DrawImage(nil, x, y, width, height)
			end
		end
		if mOver then
			local gem = self.skillsTab.displayGroup.gemList[self.index]
			if gem and gem.grantedEffect then
				SetDrawLayer(nil, 10)
				main:AddTooltipLine(20, colorCodes.GEM..gem.grantedEffect.name)
				main:AddTooltipSeparator(10)
				main:AddTooltipLine(16, "^x7F7F7F"..gem.grantedEffect.gemTagString)
				main:AddTooltipSeparator(10)
				self.skillsTab.build:AddRequirementsToTooltip(gem.reqLevel, gem.reqStr, gem.reqDex, gem.reqInt)
				if gem.grantedEffect.description then
					local wrap = main:WrapString(gem.grantedEffect.description, 16, m_max(DrawStringWidth(16, "VAR", gem.grantedEffect.gemTagString), 400))
					for _, line in ipairs(wrap) do
						main:AddTooltipLine(16, colorCodes.GEM..line)
					end
				end
				main:DrawTooltip(x, y, width, height, viewPort, colorCodes.GEM, true)
				SetDrawLayer(nil, 0)
			end
		end
	end
end

function GemSelectClass:OnFocusGained()
	self.EditControl:OnFocusGained()
	self.dropped = true
	self.selIndex = 0
	self:BuildList("")
	for index, name in pairs(self.list) do
		if name == self.buf then
			self.selIndex = index
			self:ScrollSelIntoView()
			break
		end
	end
	self.initialBuf = self.buf
	self.initialIndex = self.selIndex
end

function GemSelectClass:OnFocusLost()
	if self.dropped then
		self.dropped = false
		if self.noMatches then
			self:SetText("")
		end
		self:UpdateGem(true, true)
	end
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
			return
		end
		if key == "LEFTBUTTON" then
			if self.hoverSel and self.skillsTab.build.data.gems[self.list[self.hoverSel]] then
				self.dropped = false
				self.selIndex = self.hoverSel
				self:SetText(self.list[self.selIndex])
				self:UpdateGem(false, true)
				return self
			end
		elseif key == "RETURN" then
			self.dropped = false
			if self.noMatches then
				self:SetText("")
			end
			self.selIndex = m_max(self.selIndex, 1)
			self:UpdateGem(true, true)
			return self
		elseif key == "ESCAPE" then
			self.dropped = false
			self:BuildList("")
			self.buf = self.initialBuf
			self.selIndex = self.initialIndex
			self:UpdateGem(false, true)
			return
		elseif key == "WHEELUP" then
			self.controls.scrollBar:Scroll(-1)
		elseif key == "WHEELDOWN" then
			self.controls.scrollBar:Scroll(1)
		elseif key == "DOWN" then
			if self.selIndex < #self.list and not self.noMatches then
				self.selIndex = self.selIndex + 1
				self:SetText(self.list[self.selIndex])
				self:UpdateGem()
				self:ScrollSelIntoView()
			end
		elseif key == "UP" then
			if self.selIndex > 0 and not self.noMatches then
				self.selIndex = self.selIndex - 1
				if self.selIndex == 0 then
					self:SetText(self.searchStr)
				else
					self:SetText(self.list[self.selIndex])
				end
				self:UpdateGem()
				self:ScrollSelIntoView()
			end
		end
	elseif key == "RETURN" or key == "RIGHTBUTTON" then
		self.dropped = true
		self.initialIndex = self.selIndex
		self.initialBuf = self.buf
		return self
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