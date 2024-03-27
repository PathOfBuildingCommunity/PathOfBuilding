-- Path of Building
--
-- Class: Gem Select
-- Gem selection combobox
--

local t_insert = table.insert
local t_remove = table.remove
local t_sort = table.sort
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local toolTipText = "Prefix tag searches with a colon and exclude tags with a dash. e.g. :fire:lightning:-cold:area"
local altQualMap = {
	["Default"] = "",
	["Alternate1"] = "Anomalous ",
	["Alternate2"] = "Divergent ",
	["Alternate3"] = "Phantasmal ",
}

local GemSelectClass = newClass("GemSelectControl", "EditControl", function(self, anchor, x, y, width, height, skillsTab, index, changeFunc, forceTooltip)
	self.EditControl(anchor, x, y, width, height, nil, nil, "^ %a':-")
	self.controls.scrollBar = new("ScrollBarControl", { "TOPRIGHT", self, "TOPRIGHT" }, -1, 0, 18, 0, (height - 4) * 4)
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
	self.gems = { }
	self:PopulateGemList()
	self.index = index
	self.gemChangeFunc = changeFunc
	self.forceTooltip = forceTooltip
	self.list = { }
	self.mode = ""
	self.changeFunc = function()
		if not self.dropped then
			self.dropped = true
			self:UpdateSortCache()
		end
		self.selIndex = 0
		self:BuildList(self.buf)
		self:UpdateGem()
	end
	self.costs = data.costs
	self.reservationMap = {
		manaReservationFlat = "Mana",
		manaReservationPercent = "ManaPercent",
		lifeReservationFlat = "Life",
		lifeReservationPercent = "LifePercent",
	}
end)

function GemSelectClass:CalcOutputWithThisGem(calcFunc, gemData, qualityId)
	local gemList = self.skillsTab.displayGroup.gemList
	local oldGem
	if gemList[self.index] then
		oldGem = copyTable(gemList[self.index], true)
	else
		gemList[self.index] = {
			level = gemData.naturalMaxLevel,
			qualityId = qualityId,
			quality = self.skillsTab.defaultGemQuality or 0,
			count = 1,
			enabled = true,
			enableGlobal1 = true,
			enableGlobal2 = true,
			gemId = gemData.id,
			nameSpec = gemData.name,
			skillId = gemData.grantedEffectId
		}
	end

	-- Create gemInstance to represent the hovered gem
	local gemInstance = gemList[self.index]
	gemInstance.level = self.skillsTab:ProcessGemLevel(gemData)
	gemInstance.gemData = gemData
	gemInstance.displayEffect = nil
	if gemInstance.qualityId == nil or gemInstance.qualityId == "" then
		gemInstance.qualityId = "Default"
	end
	-- Add hovered gem to tooltip
	self:AddGemTooltip(gemInstance)
	-- Calculate the impact of using this gem
	local output = calcFunc({ }, { allocNodes = true, requirementsItems = true })
	-- Put the original gem back into the list
	if oldGem then
		gemInstance.gemData = oldGem.gemData
		gemInstance.level = oldGem.level
		gemInstance.displayEffect = oldGem.displayEffect
	else
		gemList[self.index] = nil
	end

	return output, gemInstance
end

function GemSelectClass:PopulateGemList()
	wipeTable(self.gems)
	local showAll = self.skillsTab.showSupportGemTypes == "ALL"
	local showAwakened = self.skillsTab.showSupportGemTypes == "AWAKENED"
	local showNormal = self.skillsTab.showSupportGemTypes == "NORMAL"
	local matchLevel = self.skillsTab.defaultGemLevel == "characterLevel"
	local characterLevel = self.skillsTab.build and self.skillsTab.build.characterLevel or 1

	for gemId, gemData in pairs(self.skillsTab.build.data.gems) do
		if (self.sortGemsBy and gemData.tags[self.sortGemsBy] == true or not self.sortGemsBy) then
			local levelRequirement = gemData.grantedEffect.levels[1].levelRequirement or 1
			if characterLevel >= levelRequirement or not matchLevel then
				if (showAwakened or showAll) and gemData.grantedEffect.plusVersionOf then
					self.gems["Default:" .. gemId] = gemData
				elseif showNormal or showAll then
					if self.skillsTab.showAltQualityGems and (self.skillsTab.defaultGemQuality or 0) > 0 then
						for _, altQual in ipairs(self.skillsTab:getGemAltQualityList(gemData)) do
							self.gems[altQual.type .. ":" .. gemId] = gemData
						end
					else
						self.gems["Default:" .. gemId] = gemData
					end
				end
			end
		end
	end
end

function GemSelectClass:GetQualityType(gemId)
	return gemId and gemId:gsub(":.+","") or "Default"
end

function GemSelectClass:FilterSupport(gemId, gemData)
	local showSupportTypes = self.skillsTab.showSupportGemTypes
	return (not gemData.grantedEffect.support
		or showSupportTypes == "ALL"
		or (showSupportTypes == "NORMAL" and not gemData.grantedEffect.plusVersionOf)
		or (showSupportTypes == "AWAKENED" and gemData.grantedEffect.plusVersionOf))
		and (self.skillsTab.showAltQualityGems or (not self.skillsTab.showAltQualityGems and self:GetQualityType(gemId) == "Default"))
end

function GemSelectClass:BuildList(buf)
	local searchTerm = ""
	local tagsList = {}

	self.controls.scrollBar.offset = 0
	wipeTable(self.list)
	self.searchStr = buf .. self.mode
	self.mode = ""
	if #self.searchStr > 0 then
		local added = { }

		-- split the buffer using :
		-- Remove the first entry as the name search term (can be blank)
		tagsList = self.searchStr:split(":")
		searchTerm = tagsList[1]
		t_remove(tagsList, 1)

		-- Search for gem name using increasingly broad search patterns
		local patternList = {
			"^ " .. searchTerm:lower().."$", -- Exact match
			"^" .. searchTerm:lower():gsub("%a", " %0%%l+") .. "$", -- Simple abbreviation ("CtF" -> "Cold to Fire")
			"^ " .. searchTerm:lower(), -- Starts with
			searchTerm:lower(), -- Contains
		}
		for i, pattern in ipairs(patternList) do
			local matchList = { }
			for gemId, gemData in pairs(self.gems) do
				if self:FilterSupport(gemId, gemData) and not added[gemId] and ((" "..gemData.name:lower()):match(pattern) or altQualMap[self:GetQualityType(gemId)]:lower():match(pattern)) then
					addThisGem = true
					if #tagsList > 0 then
						for _, tag in ipairs(tagsList) do
							local tagName = tag:gsub("%s+", ""):lower()
							local negateTag = tagName:sub(1, 1) == "-"
							if negateTag then tagName = tagName:sub(2) end
							if tagName == "active" then
								tagName = "grants_active_skill"
							elseif tagName == "int" then
								tagName = "intelligence"
							elseif tagName == "str" then
								tagName = "strength"
							elseif tagName == "dex" then
								tagName = "dexterity"
							end
							-- for :melee we want to exclude gems that DON'T have this tag
							-- for :-melee we want to exclude gems that DO have this tag
							-- EG: :active:fire:-aura		<-- No Anger (Calming ?)
							if negateTag then
								if gemData.tags[tagName] and gemData.tags[tagName] == true then addThisGem = false end
							else
								if gemData.tags[tagName] == nil or gemData.tags[tagName] == false then addThisGem = false end
							end
						end
					end
					if addThisGem then
						t_insert(matchList, gemId)
						added[gemId] = true
					end
				else
					-- This stanza is to support the original tag search
					-- Name matching above failed, so lets use searchTerm to look for the tagName
					-- aura:cold is now illogical and can't work (:aura:cold is the way to do it)
					if searchTerm == "active" then
						searchTerm = "grants_active_skill"
					elseif searchTerm == "int" then
						searchTerm = "intelligence"
					elseif searchTerm == "str" then
						searchTerm = "strength"
					elseif searchTerm == "dex" then
						searchTerm = "dexterity"
					end
					if self:FilterSupport(gemId, gemData) and not added[gemId] and gemData.tags[searchTerm:lower()] == true then
						t_insert(matchList, gemId)
						added[gemId] = true
					end
				end
			end
			self:SortGemList(matchList)
			for _, gemId in ipairs(matchList) do
				t_insert(self.list, gemId)
			end
		end
	else
		-- nothing in buffer
		for gemId, gemData in pairs(self.gems) do
			if self:FilterSupport(gemId, gemData) then
				t_insert(self.list, gemId)
			end
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
	--local start = GetTime()
	local sortCache = self.sortCache
	local sameSortBy = self.sortGemsBy == self.lastSortGemsBy
	-- Don't update the cache if no settings have changed that would impact the ordering
	if sameSortBy and sortCache and sortCache.socketGroup == self.skillsTab.displayGroup and sortCache.gemInstance == self.skillsTab.displayGroup.gemList[self.index]
		and sortCache.outputRevision == self.skillsTab.build.outputRevision and sortCache.defaultLevel == self.skillsTab.defaultGemLevel
		and (sortCache.characterLevel == self.skillsTab.build.characterLevel or self.skillsTab.defaultGemLevel ~= "characterLevel")
		and sortCache.defaultQuality == self.skillsTab.defaultGemQuality and sortCache.sortType == self.skillsTab.sortGemsByDPSField
		and sortCache.considerAlternates == self.skillsTab.showAltQualityGems and sortCache.considerGemType == self.skillsTab.showSupportGemTypes then
		return
	end

	if not sameSortBy or not sortCache or (sortCache.considerAlternates ~= self.skillsTab.showAltQualityGems or sortCache.considerGemType ~= self.skillsTab.showSupportGemTypes
		or sortCache.defaultQuality ~= self.skillsTab.defaultGemQuality
		or sortCache.defaultLevel ~= self.skillsTab.defaultGemLevel
		or (sortCache.characterLevel ~= self.skillsTab.build.characterLevel and self.skillsTab.defaultGemLevel == "characterLevel")) then
		self.lastSortGemsBy = self.sortGemsBy
		self:PopulateGemList()
	end

	-- Initialize a new sort cache
	sortCache = {
		considerGemType = self.skillsTab.showSupportGemTypes,
		considerAlternates = self.skillsTab.showAltQualityGems,
		socketGroup = self.skillsTab.displayGroup,
		gemInstance = self.skillsTab.displayGroup.gemList[self.index],
		outputRevision = self.skillsTab.build.outputRevision,
		defaultLevel = self.skillsTab.defaultGemLevel,
		defaultQuality = self.skillsTab.defaultGemQuality,
		characterLevel = self.skillsTab.build and self.skillsTab.build.characterLevel or 1,
		canSupport = { },
		dps = { },
		dpsColor = { },
		sortType = self.skillsTab.sortGemsByDPSField
	}
	self.sortCache = sortCache

	-- Determine supports that affect the active skill
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
	-- No active gem exists in the main socket group so check for item provided skills in matching slots
	elseif self.skillsTab.displayGroup.slot then
		for _, group in ipairs(self.skillsTab.socketGroupList) do
			local matchingItemSkillSlot = group.source and group.slot and self.skillsTab.displayGroup.slot == group.slot and group.displaySkillList and group.displaySkillList[1]
			if matchingItemSkillSlot then
				for gemId, gemData in pairs(self.gems) do
					if gemData.grantedEffect.support then
						for _, activeSkill in ipairs(group.displaySkillList) do
							if calcLib.canGrantedEffectSupportActiveSkill(gemData.grantedEffect, activeSkill) then
								sortCache.canSupport[gemId] = true
								break
							end
						end
					end
				end
			end
			for _, crossLinkedSlot in ipairs(group.slot and group.displaySkillList and group.displaySkillList[1] and self.skillsTab.build.calcsTab.mainEnv.crossLinkedSupportGroups[self.skillsTab.displayGroup.slot:gsub(" Swap", "")] or {}) do
				if crossLinkedSlot == group.slot:gsub(" Swap", "") then
					for gemId, gemData in pairs(self.gems) do
						if gemData.grantedEffect.support then
							for _, activeSkill in ipairs(group.displaySkillList) do
								if calcLib.canGrantedEffectSupportActiveSkill(gemData.grantedEffect, activeSkill) then
									sortCache.canSupport[gemId] = true
									break
								end
							end
						end
					end
				end
			end
		end
	end

	local dpsField = self.skillsTab.sortGemsByDPSField
	GlobalCache.useFullDPS = dpsField == "FullDPS"
	local calcFunc, calcBase = self.skillsTab.build.calcsTab:GetMiscCalculator(self.build)
	-- Check for nil because some fields may not be populated, default to 0
	local baseDPS = (dpsField == "FullDPS" and calcBase[dpsField] ~= nil and calcBase[dpsField]) or (calcBase.Minion and calcBase.Minion.CombinedDPS) or (calcBase[dpsField] ~= nil and calcBase[dpsField]) or 0

	for gemId, gemData in pairs(self.gems) do
		sortCache.dps[gemId] = baseDPS
		-- Ignore gems that don't support the active skill
		if sortCache.canSupport[gemId] or gemData.grantedEffect.hasGlobalEffect then
			local output = self:CalcOutputWithThisGem(calcFunc, gemData, self:GetQualityType(gemId))
			-- Check for nil because some fields may not be populated, default to 0
			sortCache.dps[gemId] = (dpsField == "FullDPS" and output[dpsField] ~= nil and output[dpsField]) or (output.Minion and output.Minion.CombinedDPS) or (output[dpsField] ~= nil and output[dpsField]) or 0
		end
		-- Color based on the DPS
		if sortCache.dps[gemId] > baseDPS then
			sortCache.dpsColor[gemId] = "^x228866"
		elseif sortCache.dps[gemId] < baseDPS then
			sortCache.dpsColor[gemId] = "^xFF4422"
		else
			sortCache.dpsColor[gemId] = "^xFFFF66"
		end
	end

	--ConPrintf("Gem Selector time: %d ms", GetTime() - start)
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
	self.gemChangeFunc(self.gemId and self.gemId:gsub("%w+:", ""), self:GetQualityType(self.gemId), addUndo and self.gemName ~= self.initialBuf)
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

function GemSelectClass:Draw(viewPort, noTooltip)
	self.EditControl:Draw(viewPort, noTooltip and not self.forceTooltip)
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
				SetDrawColor(0.2, 0.2, 0.2)
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
			local gemText = gemData and gemData.name or "<No matches>"
			if gemId and gemId ~= "" then
				gemText = altQualMap[self:GetQualityType(gemId)] .. gemText
			end
			DrawString(0, y, "LEFT", height - 4, "VAR", gemText)
			if gemData then
				if gemData.grantedEffect.support and self.sortCache.canSupport[gemId] then
					SetDrawColor(self.sortCache.dpsColor[gemId])
					main:DrawCheckMark(width - 4 - height / 2 - (scrollBar.enabled and 18 or 0), y + (height - 4) / 2, (height - 4) * 0.8)
				elseif gemData.grantedEffect.hasGlobalEffect then
					SetDrawColor(self.sortCache.dpsColor[gemId])
					DrawString(width - 4 - height / 2 - (scrollBar.enabled and 18 or 0), y - 2, "CENTER_X", height, "VAR", "+")
				end
			end
		end
		SetViewport()
		self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)
		if self.hoverSel then
			local calcFunc, calcBase = self.skillsTab.build.calcsTab:GetMiscCalculator(self.build)
			if calcFunc then
				self.tooltip:Clear()
				local output, gemInstance = self:CalcOutputWithThisGem(calcFunc, self.gems[self.list[self.hoverSel]], self:GetQualityType(self.list[self.hoverSel]))
				self.tooltip:AddSeparator(10)
				self.skillsTab.build:AddStatComparesToTooltip(self.tooltip, calcBase, output, "^7Selecting this gem will give you:")
				self.tooltip:Draw(x, y + height + 2 + (self.hoverSel - 1) * (height - 4) - scrollBar.offset, width, height - 4, viewPort)
			end
		end
		SetDrawLayer(nil, 0)
	else
		-- not dropped
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
		if mOver and (not self.skillsTab.selControl or self.skillsTab.selControl._className ~= "GemSelectControl" or not self.skillsTab.selControl.dropped) and (not noTooltip or self.forceTooltip) then
			local gemInstance = self.skillsTab.displayGroup.gemList[self.index]
			local cursorX, cursorY = GetCursorPos()
			self.tooltip:Clear()
			if gemInstance and gemInstance.gemData then
				-- Check valid qualityId, set to 'Default' if missing
				if gemInstance.qualityId == nil or gemInstance.qualityId == "" then
					gemInstance.qualityId = "Default"
				end
				self:AddGemTooltip(gemInstance)
			else
				self.tooltip:AddLine(16, toolTipText)
			end

			colorS = 0.5
			colorA = 0.5
			if cursorX > (x + width - 18) then
				colorS = 1
				self.tooltip:Clear()
				self.tooltip:AddLine(16, "Only show Support gems")
			elseif (cursorX > (x + width - 40) and cursorX < (cursorX + width - 20)) then
				colorA = 1
				self.tooltip:Clear()
				self.tooltip:AddLine(16, "Only show Active gems")
			end

			-- support shortcut
			sx = x + width - 16 - 2
			SetDrawColor(colorS,colorS,colorS)
			DrawImage(nil, sx, y, 16, height)
			SetDrawColor(0,0,0)
			DrawImage(nil, sx+1, y+2, 16-2, height-4)
			SetDrawColor(colorS,colorS,colorS)
			DrawString(sx + 8, y, "CENTER_X", height - 2, "VAR", "S")

			-- active shortcut
			sx = x + width - (16*2) - (2*2)
			SetDrawColor(colorA,colorA,colorA)
			DrawImage(nil, sx, y, 16, height)
			SetDrawColor(0,0,0)
			DrawImage(nil, sx+1, y+2, 16-2, height-4)
			SetDrawColor(colorA,colorA,colorA)
			DrawString(sx + 8, y, "CENTER_X", height - 2, "VAR", "A")


			SetDrawLayer(nil, 10)
			self.tooltip:Draw(x, y, width, height, viewPort)
			SetDrawLayer(nil, 0)
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
	local primary = gemInstance.gemData.grantedEffect
	local secondary = gemInstance.gemData.secondaryGrantedEffect
	if secondary and (not secondary.support or gemInstance.gemData.secondaryEffectName) then
		local grantedEffect = gemInstance.gemData.VaalGem and secondary or primary
		local grantedEffectSecondary = gemInstance.gemData.VaalGem and primary or secondary
		self.tooltip:AddLine(20, colorCodes.GEM .. altQualMap[gemInstance.qualityId]..grantedEffect.name)
		self.tooltip:AddSeparator(10)
		self.tooltip:AddLine(16, "^x7F7F7F" .. gemInstance.gemData.tagString)
		self:AddCommonGemInfo(gemInstance, grantedEffect, true)
		self.tooltip:AddSeparator(10)
		self.tooltip:AddLine(20, colorCodes.GEM .. (gemInstance.gemData.secondaryEffectName or grantedEffectSecondary.name))
		self.tooltip:AddSeparator(10)
		self:AddCommonGemInfo(gemInstance, grantedEffectSecondary)
	else
		local grantedEffect = gemInstance.gemData.grantedEffect
		self.tooltip:AddLine(20, colorCodes.GEM .. altQualMap[gemInstance.qualityId]..grantedEffect.name)
		self.tooltip:AddSeparator(10)
		self.tooltip:AddLine(16, "^x7F7F7F" .. gemInstance.gemData.tagString)
		self:AddCommonGemInfo(gemInstance, grantedEffect, true, secondary and secondary.support and secondary)
	end
end

function GemSelectClass:AddCommonGemInfo(gemInstance, grantedEffect, addReq, mergeStatsFrom)
	local displayInstance = gemInstance.displayEffect or gemInstance
	local grantedEffectLevel = grantedEffect.levels[displayInstance.level] or { }
	if addReq then
		self.tooltip:AddLine(16, string.format("^x7F7F7FLevel: ^7%d%s%s",
			gemInstance.level,
			((displayInstance.level > gemInstance.level) and " (" .. colorCodes.MAGIC .. "+" .. (displayInstance.level - gemInstance.level) .. "^7)") or ((displayInstance.level < gemInstance.level) and " (" .. colorCodes.WARNING .. "-" .. (gemInstance.level - displayInstance.level) .. "^7)") or "",
			(gemInstance.level >= gemInstance.gemData.naturalMaxLevel) and " (Max)" or ""
		))
	end
	if grantedEffect.support then
		if grantedEffectLevel.manaMultiplier then
			self.tooltip:AddLine(16, string.format("^x7F7F7FCost & Reservation Multiplier: ^7%d%%", grantedEffectLevel.manaMultiplier + 100))
		end
		local reservation
		for name, res in pairs(self.reservationMap) do
			if grantedEffectLevel[name] then
				reservation = (reservation and (reservation .. ", ") or "") .. self.costs[isValueInArrayPred(self.costs, function(v) return v.Resource == res end)].ResourceString:gsub("{0}", string.format("%d", grantedEffectLevel[name]))
			end
		end
		if reservation then
			self.tooltip:AddLine(16, "^x7F7F7FReservation Override: ^7"..reservation)
		end
		if grantedEffectLevel.cooldown then
			local string = string.format("^x7F7F7FCooldown Time: ^7%.2f sec", grantedEffectLevel.cooldown)
			if grantedEffectLevel.storedUses and grantedEffectLevel.storedUses > 1 then
				string = string .. string.format(" (%d uses)", grantedEffectLevel.storedUses)
			end
			self.tooltip:AddLine(16, string)
		end
	else
		local reservation
		for name, res in pairs(self.reservationMap) do
			if grantedEffectLevel[name] then
				reservation = (reservation and (reservation..", ") or "") .. self.costs[isValueInArrayPred(self.costs, function(v) return v.Resource == res end)].ResourceString:gsub("{0}", string.format("%d", grantedEffectLevel[name]))
			end
		end
		if reservation then
			self.tooltip:AddLine(16, "^x7F7F7FReservation: ^7" .. reservation)
		end
		local cost
		for _, res in ipairs(self.costs) do
			if grantedEffectLevel.cost and grantedEffectLevel.cost[res.Resource] then
				cost = (cost and (cost..", ") or "") .. res.ResourceString:gsub("{0}", string.format("%g", round(grantedEffectLevel.cost[res.Resource] / res.Divisor, 2)))
			end
		end
		if cost then
			self.tooltip:AddLine(16, "^x7F7F7FCost: ^7"..cost)
		end
		if grantedEffectLevel.cooldown then
			local string = string.format("^x7F7F7FCooldown Time: ^7%.2f sec", grantedEffectLevel.cooldown)
			if grantedEffectLevel.storedUses and grantedEffectLevel.storedUses > 1 then
				string = string .. string.format(" (%d uses)", grantedEffectLevel.storedUses)
			end
			self.tooltip:AddLine(16, string)
		end
		if grantedEffectLevel.vaalStoredUses then
			self.tooltip:AddLine(16, string.format("^x7F7F7FCan Store ^7%d ^x7F7F7FUse (%d Souls)", grantedEffectLevel.vaalStoredUses, grantedEffectLevel.vaalStoredUses * grantedEffectLevel.cost.Soul))
		end
		if grantedEffectLevel.soulPreventionDuration then
			self.tooltip:AddLine(16, string.format("^x7F7F7FSoul Gain Prevention: ^7%d sec", grantedEffectLevel.soulPreventionDuration))
		end
		if gemInstance.gemData.tags.attack then
			if grantedEffectLevel.attackSpeedMultiplier then
				self.tooltip:AddLine(16, string.format("^x7F7F7FAttack Speed: ^7%d%% of base", grantedEffectLevel.attackSpeedMultiplier + 100))
			end
			if grantedEffectLevel.attackTime then
				self.tooltip:AddLine(16, string.format("^x7F7F7FAttack Time: ^7%.2f sec", grantedEffectLevel.attackTime / 1000))
			end
			if grantedEffectLevel.baseMultiplier then
				self.tooltip:AddLine(16, string.format("^x7F7F7FAttack Damage: ^7%g%% of base", grantedEffectLevel.baseMultiplier * 100))
			end
		else
			if grantedEffect.castTime > 0 then
				self.tooltip:AddLine(16, string.format("^x7F7F7FCast Time: ^7%.2f sec", grantedEffect.castTime))
			else
				self.tooltip:AddLine(16, "^x7F7F7FCast Time: ^7Instant")
			end
		end
		if grantedEffectLevel.critChance then
			self.tooltip:AddLine(16, string.format("^x7F7F7FCritical Strike Chance: ^7%.2f%%", grantedEffectLevel.critChance))
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
		local reqLevel = grantedEffect.levels[gemInstance.level] and grantedEffect.levels[gemInstance.level].levelRequirement or 1
		local reqStr = calcLib.getGemStatRequirement(reqLevel, grantedEffect.support, gemInstance.gemData.reqStr)
		local reqDex = calcLib.getGemStatRequirement(reqLevel, grantedEffect.support, gemInstance.gemData.reqDex)
		local reqInt = calcLib.getGemStatRequirement(reqLevel, grantedEffect.support, gemInstance.gemData.reqInt)
		self.skillsTab.build:AddRequirementsToTooltip(self.tooltip, reqLevel, reqStr, reqDex, reqInt)
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
		if mergeStatsFrom then
			for stat, val in pairs(calcLib.buildSkillInstanceStats(displayInstance, mergeStatsFrom)) do
				stats[stat] = (stats[stat] or 0) + val
			end
		end
		local descriptions, lineMap = self.skillsTab.build.data.describeStats(stats, grantedEffect.statDescriptionScope)
		for _, line in ipairs(descriptions) do
			local source = grantedEffect.statMap[lineMap[line]] or self.skillsTab.build.data.skillStatMap[lineMap[line]]
			if source then
				if launch.devModeAlt then
					local devText = lineMap[line]
					if source[1] then
						if not source[1].value then
							source[1].value = lineMap[line]
						end
						devText = modLib.formatMod(source[1])
					end
					line = line .. " ^2" .. devText
				end
				self.tooltip:AddLine(16, colorCodes.MAGIC .. line)
			else
				if launch.devModeAlt then
					line = line .. " ^1" .. lineMap[line]
				end
				self.tooltip:AddLine(16, colorCodes.UNSUPPORTED .. line)
			end
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
		self:UpdateGem(true,true)
	end
end

function GemSelectClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end

	-- for filter overlay buttons
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	-- constrain cursor to the height of the control
	if key == "LEFTBUTTON" and (cursorY > y and cursorY < (y + height)) then
		-- no need to constrain right side of the S overlay as that's outside hover
		if cursorX > (x + width - 18) then
			self.sortGemsBy = "support" -- only need to change sortBy, code will continue to UpdateSortCache
		elseif (cursorX > (x + width - 40) and cursorX < (cursorX + width - 20)) then
			self.sortGemsBy = "grants_active_skill"
		else
			self.sortGemsBy = nil
		end
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
				return
			end
		elseif key == "RETURN" then
			self.dropped = false
			if self.noMatches then
				self:SetText("")
			end
			self.selIndex = m_max(self.selIndex, 1)
			self:UpdateGem(true, true)
			return
		elseif key == "ESCAPE" then
			self.dropped = false
			self:BuildList("")
			self.buf = self.initialBuf
			self.selIndex = self.initialIndex
			self:UpdateGem(false,true)
			return
		elseif self.controls.scrollBar:IsScrollUpKey(key) then
			self.controls.scrollBar:Scroll(-1)
		elseif self.controls.scrollBar:IsScrollDownKey(key) then
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
	if itemLib.wiki.matchesKey(key) and self:IsMouseOver() then
		if self.dropped then
			if self.hoverSel and self.gems[self.list[self.hoverSel]] then
				-- mouse over
				itemLib.wiki.openGem(self.gems[self.list[self.hoverSel]])
			elseif self.selIndex and self.selIndex > 0 then
				-- selected
				itemLib.wiki.openGem(self.gems[self.list[self.selIndex]])
			elseif self.selIndex and not self.noMatches then
				-- search result
				itemLib.wiki.openGem(self.gems[self.list[m_max(self.selIndex, 1)]])
			end
		elseif self.index then
			local gem = self.skillsTab.displayGroup.gemList[self.index]
			if gem and gem.gemData then
				itemLib.wiki.openGem(gem.gemData)
			end
		end
	end
	local newSel = self.EditControl:OnKeyUp(key)
	return newSel == self.EditControl and self or newSel
end