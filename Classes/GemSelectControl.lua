-- Path of Building
--
-- Class: Gem Select
-- Gem selection combobox
--

local t_insert = table.insert
local t_sort = table.sort
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local GemSelectClass = newClass("GemSelectControl", "EditControl", function(self, anchor, x, y, width, height, skillsTab, index, changeFunc)
	self.EditControl(anchor, x, y, width, height, nil, nil, "^ %a'")
	self.controls.scrollBar = new("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, -1, 0, 18, 0, (height - 4) * 4)
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
	self.gems = skillsTab.build.data.gems
	self.index = index
	self.gemChangeFunc = changeFunc
	self.list = { }
	self.changeFunc = function()
		if not self.dropped then
			self.dropped = true
			self:UpdateSortCache()
		end
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
			for gemId, gemData in pairs(self.gems) do
				if not added[gemId] and (" "..gemData.name:lower()):match(pattern) then
					t_insert(matchList, gemId)
					added[gemId] = true
				end
			end
			self:SortGemList(matchList)
			for _, gemId in ipairs(matchList) do
				t_insert(self.list, gemId)
			end
		end
		local tagName = self.searchStr:match("^%s*(%a+)%s*$")
		if tagName then
			local matchList = { }
			if tagName == "active" then
				tagName = "active_skill"
			end
			for gemId, gemData in pairs(self.gems) do
				if not added[gemId] and gemData.tags[tagName:lower()] == true then
					t_insert(matchList, gemId)
					added[gemId] = true
				end
			end
			self:SortGemList(matchList)
			for _, gemId in ipairs(matchList) do
				t_insert(self.list, gemId)
			end
		end
	else
		for gemId, gemData in pairs(self.gems) do
			t_insert(self.list, gemId)
		end
		self:SortGemList(self.list)
	end
	if not self.list[1] then
		self.list[1] = ""
		self.noMatches = true
	else
		self.noMatches = false
	end
end

function GemSelectClass:UpdateSortCache()
	local sortCache = self.sortCache
	if sortCache and sortCache.socketGroup == self.skillsTab.displayGroup and sortCache.gemInstance == self.skillsTab.displayGroup.gemList[self.index] and 
	  sortCache.outputRevision == self.skillsTab.build.outputRevision and sortCache.defaultLevel == self.skillsTab.defaultGemLevel and sortCache.defaultQuality == self.skillsTab.defaultGemQuality then
		return
	end
	sortCache = {
		socketGroup = self.skillsTab.displayGroup,
		gemInstance = self.skillsTab.displayGroup.gemList[self.index],
		outputRevision = self.skillsTab.build.outputRevision,
		defaultLevel = self.skillsTab.defaultGemLevel,
		defaultQuality = self.skillsTab.defaultGemQuality,
		canSupport = { },
		dps = { },
		dpsColor = { },
	}
	self.sortCache = sortCache
	if self.skillsTab.displayGroup.displaySkillList and self.skillsTab.displayGroup.displaySkillList[1] then
		for gemId, gemData in pairs(self.gems) do
			if gemData.grantedEffect.support then
				for _, activeSkill in ipairs(self.skillsTab.displayGroup.displaySkillList) do
					if calcLib.canGrantedEffectSupportActiveSkill(gemData.grantedEffect, activeSkill) then
						sortCache.canSupport[gemId] = true
						break
					end
				end
			end
		end
	end
	local calcFunc, calcBase = self.skillsTab.build.calcsTab:GetMiscCalculator(self.build)
	local baseDPS = calcBase.Minion and calcBase.Minion.CombinedDPS or calcBase.CombinedDPS
	for gemId, gemData in pairs(self.gems) do
		sortCache.dps[gemId] = baseDPS
		if sortCache.canSupport[gemId] or gemData.grantedEffect.hasGlobalEffect then
			local gemList = self.skillsTab.displayGroup.gemList
			local oldGem
			if gemList[self.index] then
				oldGem = copyTable(gemList[self.index], true)
			else
				gemList[self.index] = { level = self.skillsTab.defaultGemLevel or 20, quality = self.skillsTab.defaultGemQuality or 0, enabled = true, enableGlobal1 = true }
			end
			local gemInstance = gemList[self.index]
			if gemInstance.gemData and gemInstance.gemData.defaultLevel ~= gemData.defaultLevel then
				gemInstance.level = self.skillsTab.defaultGemLevel or 20
			end
			gemInstance.gemData = gemData
			if not gemData.grantedEffect.levels[gemInstance.level] then
				gemInstance.level = gemData.defaultLevel
			end
			local output = calcFunc()
			if oldGem then
				gemInstance.gemData = oldGem.gemData
				gemInstance.level = oldGem.level
			else
				gemList[self.index] = nil
			end
			sortCache.dps[gemId] = output.Minion and output.Minion.CombinedDPS or output.CombinedDPS
		end
		if sortCache.dps[gemId] > baseDPS then
			sortCache.dpsColor[gemId] = "^x228866"
		elseif sortCache.dps[gemId] < baseDPS then
			sortCache.dpsColor[gemId] = "^xFF4422"
		else
			sortCache.dpsColor[gemId] = "^xFFFF66"
		end
	end
end

function GemSelectClass:SortGemList(gemList)
	local sortCache = self.sortCache
	t_sort(gemList, function(a, b)
		if sortCache.canSupport[a] == sortCache.canSupport[b] then
			if self.skillsTab.sortGemsByDPS and sortCache.dps[a] ~= sortCache.dps[b] then
				return sortCache.dps[a] > sortCache.dps[b]
			else
				return a < b
			end
		else
			return sortCache.canSupport[a]
		end
	end)
end

function GemSelectClass:UpdateGem(setText, addUndo)
	local gemId = self.list[m_max(self.selIndex, 1)]
	if self.buf:match("%S") and self.gems[gemId] then
		self.gemId = gemId
	else
		self.gemId = nil
	end
	self.gemName = self.gemId and self.gems[self.gemId].name or ""
	if setText then	
		self:SetText(self.gemName)
	end
	self.gemChangeFunc(self.gemId, addUndo and self.gemName ~= self.initialBuf)
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
		if self.hoverSel and not self.gems[self.list[self.hoverSel]] then
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
			local gemId = self.list[index]
			local gemData = self.gems[gemId]
			if gemData then
				if gemData.grantedEffect.color == 1 then
					SetDrawColor(colorCodes.STRENGTH)
				elseif gemData.grantedEffect.color == 2 then
					SetDrawColor(colorCodes.DEXTERITY)
				elseif gemData.grantedEffect.color == 3 then
					SetDrawColor(colorCodes.INTELLIGENCE)
				end
			end
			DrawString(0, y, "LEFT", height - 4, "VAR", gemData and gemData.name or "<No matches>")
			if gemData then
				if gemData.grantedEffect.support and self.skillsTab.displayGroup.displaySkillList then
					for _, activeSkill in ipairs(self.skillsTab.displayGroup.displaySkillList) do
						if calcLib.canGrantedEffectSupportActiveSkill(gemData.grantedEffect, activeSkill) then
							SetDrawColor(self.sortCache.dpsColor[gemId])
							main:DrawCheckMark(width - 4 - height / 2 - (scrollBar.enabled and 18 or 0), y + (height - 4) / 2, (height - 4) * 0.8)
							break
						end
					end
				elseif gemData.grantedEffect.hasGlobalEffect then
					SetDrawColor(self.sortCache.dpsColor[gemId])
					DrawString(width - 4 - height / 2 - (scrollBar.enabled and 18 or 0), y - 2, "CENTER_X", height, "VAR", "+")
				end
			end
		end
		SetViewport()
		self:DrawControls(viewPort)
		if self.hoverSel then
			local calcFunc, calcBase = self.skillsTab.build.calcsTab:GetMiscCalculator(self.build)
			if calcFunc then
				self.tooltip:Clear()
				local gemList = self.skillsTab.displayGroup.gemList
				local gemData = self.gems[self.list[self.hoverSel]]
				local oldGem
				if gemList[self.index] then
					oldGem = copyTable(gemList[self.index], true)
				else
					gemList[self.index] = { level = self.skillsTab.defaultGemLevel or 20, quality = self.skillsTab.defaultGemQuality or 0, enabled = true, enableGlobal1 = true }
				end
				local gemInstance = gemList[self.index]
				if gemInstance.gemData and gemInstance.gemData.defaultLevel ~= gemData.defaultLevel then
					gemData.level = self.skillsTab.defaultGemLevel or 20
				end
				gemInstance.gemData = gemData
				if not gemData.grantedEffect.levels[gemInstance.level] then
					gemInstance.level = gemData.defaultLevel
				end
				local output = calcFunc()
				if oldGem then
					gemInstance.gemData = oldGem.gemData
					gemInstance.level = oldGem.level
				else
					gemList[self.index] = nil
				end
				self.skillsTab.build:AddStatComparesToTooltip(self.tooltip, calcBase, output, "^7Selecting this gem will give you:")
				self.tooltip:Draw(x, y + height + 2 + (self.hoverSel - 1) * (height - 4) - scrollBar.offset, width, height - 4, viewPort)
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
			if thisGem and hoverGem and thisGem.enabled and hoverGem.enabled and thisGem.gemData and hoverGem.gemData and
			  (self:CheckSupporting(thisGem, hoverGem) or self:CheckSupporting(hoverGem, thisGem)) then
			   SetDrawColor(0.33, 1, 0.33, 0.25)
			   DrawImage(nil, x, y, width, height)
			end
		end
		if mOver and (not self.skillsTab.selControl or self.skillsTab.selControl._className ~= "GemSelectControl" or not self.skillsTab.selControl.dropped) then
			local gemInstance = self.skillsTab.displayGroup.gemList[self.index]
			if gemInstance and gemInstance.gemData then
				SetDrawLayer(nil, 10)
				self.tooltip:Clear()
				self:AddGemTooltip(gemInstance)
				self.tooltip:Draw(x, y, width, height, viewPort)
				SetDrawLayer(nil, 0)
			end
		end
	end
end

function GemSelectClass:CheckSupporting(gemA, gemB)
	return (gemA.gemData.grantedEffect.support and not gemB.gemData.grantedEffect.support and gemA.supportEffect and gemA.supportEffect.isSupporting and gemA.supportEffect.isSupporting[gemB]) or
		(gemA.gemData.secondaryGrantedEffect and gemA.gemData.secondaryGrantedEffect.support and not gemB.gemData.grantedEffect.support and gemA.supportEffect and gemA.supportEffect.isSupporting and gemA.supportEffect.isSupporting[gemB])
end

function GemSelectClass:AddGemTooltip(gemInstance)
	self.tooltip.center = true
	self.tooltip.color = colorCodes.GEM
	if gemInstance.gemData.secondaryGrantedEffect and not gemInstance.gemData.secondaryGrantedEffect.support then
		local grantedEffect = gemInstance.gemData.secondaryGrantedEffect
		local grantedEffectVaal = gemInstance.gemData.grantedEffect
		self.tooltip:AddLine(20, colorCodes.GEM..grantedEffect.name)
		self.tooltip:AddSeparator(10)
		self.tooltip:AddLine(16, "^x7F7F7F"..gemInstance.gemData.tagString)
		self:AddCommonGemInfo(gemInstance, grantedEffect, true)
		self.tooltip:AddSeparator(10)
		self.tooltip:AddLine(20, colorCodes.GEM..grantedEffectVaal.name)
		self.tooltip:AddSeparator(10)
		self:AddCommonGemInfo(gemInstance, grantedEffectVaal)
	else
		local grantedEffect = gemInstance.gemData.grantedEffect
		self.tooltip:AddLine(20, colorCodes.GEM..grantedEffect.name)
		self.tooltip:AddSeparator(10)
		self.tooltip:AddLine(16, "^x7F7F7F"..gemInstance.gemData.tagString)
		self:AddCommonGemInfo(gemInstance, grantedEffect, true)
	end
end

function GemSelectClass:AddCommonGemInfo(gemInstance, grantedEffect, addReq)
	local displayInstance = gemInstance.displayEffect or gemInstance
	local grantedEffectLevel = grantedEffect.levels[displayInstance.level]
	if addReq then
		self.tooltip:AddLine(16, string.format("^x7F7F7FLevel: ^7%d%s",
			gemInstance.level, 
			(displayInstance.level > gemInstance.level) and " ("..colorCodes.MAGIC.."+"..(displayInstance.level - gemInstance.level).."^7)" or ""
		))
	end
	if grantedEffect.support then
		if grantedEffectLevel.manaMultiplier then
			self.tooltip:AddLine(16, string.format("^x7F7F7FMana Multiplier: ^7%d%%", grantedEffectLevel.manaMultiplier + 100))
		end
		if grantedEffectLevel.manaCostOverride then
			self.tooltip:AddLine(16, string.format("^x7F7F7FMana Reservation Override: ^7%d%%", grantedEffectLevel.manaCostOverride))
		end
		if grantedEffectLevel.cooldown then
			self.tooltip:AddLine(16, string.format("^x7F7F7FCooldown Time: ^7%.2f sec", grantedEffectLevel.cooldown))
		end
	else
		if grantedEffectLevel.manaCost then
			if grantedEffect.skillTypes[SkillType.ManaCostReserved] then
				if grantedEffect.skillTypes[SkillType.ManaCostPercent] then
					self.tooltip:AddLine(16, string.format("^x7F7F7FMana Reserved: ^7%d%%", grantedEffectLevel.manaCost))
				else
					self.tooltip:AddLine(16, string.format("^x7F7F7FMana Reserved: ^7%d", grantedEffectLevel.manaCost))
				end
			else
				self.tooltip:AddLine(16, string.format("^x7F7F7FMana Cost: ^7%d", grantedEffectLevel.manaCost))
			end
		end
		if grantedEffectLevel.cooldown then
			self.tooltip:AddLine(16, string.format("^x7F7F7FCooldown Time: ^7%.2f sec", grantedEffectLevel.cooldown))
		end
		if not gemInstance.gemData.tags.attack then
			if grantedEffect.castTime > 0 then
				self.tooltip:AddLine(16, string.format("^x7F7F7FCast Time: ^7%.2f sec", grantedEffect.castTime))
			else
				self.tooltip:AddLine(16, "^x7F7F7FCast Time: ^7Instant")
			end
			if grantedEffectLevel.critChance then
				self.tooltip:AddLine(16, string.format("^x7F7F7FCritical Strike Chance: ^7%.2f%%", grantedEffectLevel.critChance))
			end
		end
		if grantedEffectLevel.damageEffectiveness then
			self.tooltip:AddLine(16, string.format("^x7F7F7FEffectiveness of Added Damage: ^7%d%%", grantedEffectLevel.damageEffectiveness * 100))
		end
	end
	if addReq and displayInstance.quality > 0 then
		self.tooltip:AddLine(16, string.format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%^7%s",
			gemInstance.quality,
			(displayInstance.quality > gemInstance.quality) and " ("..colorCodes.MAGIC.."+"..(displayInstance.quality - gemInstance.quality).."^7)" or ""
		))
	end
	self.tooltip:AddSeparator(10)
	if addReq then
		self.skillsTab.build:AddRequirementsToTooltip(self.tooltip, gemInstance.reqLevel, gemInstance.reqStr, gemInstance.reqDex, gemInstance.reqInt)
	end
	if grantedEffect.description then
		local wrap = main:WrapString(grantedEffect.description, 16, m_max(DrawStringWidth(16, "VAR", gemInstance.gemData.tagString), 400))
		for _, line in ipairs(wrap) do
			self.tooltip:AddLine(16, colorCodes.GEM..line)
		end
	end
	if self.skillsTab.build.data.describeStats then
		self.tooltip:AddSeparator(10)
		local stats = calcLib.buildSkillInstanceStats(displayInstance, grantedEffect)
		if grantedEffectLevel.baseMultiplier then
			stats["active_skill_attack_damage_final_permyriad"] = (grantedEffectLevel.baseMultiplier - 1) * 10000
		end
		local descriptions = self.skillsTab.build.data.describeStats(stats, grantedEffect.statDescriptionScope)
		for _, line in ipairs(descriptions) do
			self.tooltip:AddLine(16, colorCodes.MAGIC..line)
		end
	end
end

function GemSelectClass:OnFocusGained()
	self.EditControl:OnFocusGained()
	self.dropped = true
	self.selIndex = 0
	self:UpdateSortCache()
	self:BuildList("")
	for index, gemId in pairs(self.list) do
		if self.gems[gemId].name == self.buf then
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
			if self.hoverSel and self.gems[self.list[self.hoverSel]] then
				self.dropped = false
				self.selIndex = self.hoverSel
				self:SetText(self.gems[self.list[self.selIndex]].name)
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
				self:SetText(self.gems[self.list[self.selIndex]].name)
				self:UpdateGem()
				self:ScrollSelIntoView()
			end
		elseif key == "UP" then
			if self.selIndex > 0 and not self.noMatches then
				self.selIndex = self.selIndex - 1
				if self.selIndex == 0 then
					self:SetText(self.searchStr)
				else
					self:SetText(self.gems[self.list[self.selIndex]].name)
				end
				self:UpdateGem()
				self:ScrollSelIntoView()
			end
		end
	elseif key == "RETURN" or key == "RIGHTBUTTON" then
		self.dropped = true
		self:UpdateSortCache()
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