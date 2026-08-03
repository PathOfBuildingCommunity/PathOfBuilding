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

local gemTooltip = LoadModule("Classes/GemTooltip")
local toolTipText = "Prefix tag searches with a colon and exclude tags with a dash. e.g. :fire:lightning:-cold:area"
local imbuedTooltipText = "\"Socketed in\" item must be set in order to add an imbued support.\nOnly one imbued support is allowed per item."

local GemSelectClass = newClass("GemSelectControl", "EditControl", function(self, anchor, rect, skillsTab, index, changeFunc, forceTooltip, imbued)
	self.EditControl(anchor, rect, nil, nil, "^ %a':-")
	self.controls.scrollBar = new("ScrollBarControl", { "TOPRIGHT", self, "TOPRIGHT" }, {-1, 0, 18, 0}, (self.height - 4) * 4)
	self.controls.scrollBar.y = function()
		local width, height = self:GetSize()
		return height + 1
	end
	self.controls.scrollBar.height = function()
		return (self.height - 4) * m_min(#self.list, 15) + 2
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
	self.imbuedSelect = imbued
	self.dpsBuildFlag = false
end)

function GemSelectClass:CalcOutputWithThisGem(calcFunc, gemData, useFullDPS)
	local gemList = self.skillsTab.displayGroup.gemList
	local displayGemList = self.skillsTab.displayGroup.displayGemList
	local oldGem

	-- the imbuedSupport control actively switches to the latest index of the current displayGroup's gemList so we can use the canSupport filtering
	if self.imbuedSelect then
		self.index = #gemList + 1
	end
	if gemList[self.index] then
		oldGem = copyTable(gemList[self.index], true)
	else
		gemList[self.index] = {
			level = gemData.naturalMaxLevel,
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
	gemInstance.level = self.skillsTab:ProcessGemLevel(gemData, self.imbuedSelect)
	gemInstance.gemData = gemData
	gemInstance.displayEffect = nil
	-- Calculate the impact of using this gem
	local output = calcFunc(nil, useFullDPS)
	-- Put the original gem back into the list
	if oldGem then
		gemInstance.gemData = oldGem.gemData
		gemInstance.level = oldGem.level
		gemInstance.displayEffect = oldGem.displayEffect
	else
		gemList[self.index] = nil
	end
	
	self.skillsTab.displayGroup.displayGemList = displayGemList
	
	return output, gemInstance
end

function GemSelectClass:PopulateGemList()
	wipeTable(self.gems)
	local showAll = self.skillsTab.showSupportGemTypes == "ALL"
	local showExceptional = self.skillsTab.showSupportGemTypes == "EXCEPTIONAL"
	local showNormal = self.skillsTab.showSupportGemTypes == "NORMAL"
	local matchLevel = self.skillsTab.defaultGemLevel == "characterLevel"
	local characterLevel = self.skillsTab.build and self.skillsTab.build.characterLevel or 1

	for gemId, gemData in pairs(self.skillsTab.build.data.gems) do
		if not gemData.grantedEffect.hideFromGemList and (self.sortGemsBy and gemData.tags[self.sortGemsBy] == true or not self.sortGemsBy) then
			local levelRequirement = gemData.grantedEffect.levels[1].levelRequirement or 1
			if characterLevel >= levelRequirement or not matchLevel then
				local isLegacyAwakened = gemData.grantedEffect.legacy and gemData.grantedEffect.plusVersionOf
				if self.imbuedSelect then
					-- Imbued dropdown only allows non-exceptional support gems and supports that don't grant active skills
					if gemData.grantedEffect.support and not gemData.tagString:match("Exceptional") and not isLegacyAwakened and (not gemData.secondaryGrantedEffect or gemData.secondaryGrantedEffect.support) then
						self.gems["Default:" .. gemId] = gemData
					end
				else
					if (showExceptional or showAll) and (isLegacyAwakened or gemData.tagString:match("Exceptional")) then
						if self.skillsTab.showLegacyGems or not gemData.grantedEffect.legacy then
							self.gems["Default:" .. gemId] = gemData
						end
					elseif showNormal or showAll then
						self.gems["Default:" .. gemId] = gemData
					end
				end
			end
		end
	end
end

function GemSelectClass:FilterSupport(gemId, gemData)
	local showSupportTypes = self.skillsTab.showSupportGemTypes
	local isLegacyAwakened = (gemData.grantedEffect.legacy and gemData.grantedEffect.plusVersionOf)
	if gemData.grantedEffect.legacy and not self.skillsTab.showLegacyGems then
		return false
	end

	if self.imbuedSelect then
		return self.sortCache.canSupport[gemId]
	end

	return (not gemData.grantedEffect.support
		or showSupportTypes == "ALL"
		or (showSupportTypes == "NORMAL" and not (isLegacyAwakened or gemData.tagString:match("Exceptional")))
		or (showSupportTypes == "EXCEPTIONAL" and (isLegacyAwakened or gemData.tagString:match("Exceptional"))))
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
		local lowerSearch = searchTerm:lower()
		local patternList = {
			"^ " .. lowerSearch.."$", -- Exact match
			"^" .. lowerSearch:gsub("%a", " %0%%l+") .. "$", -- Simple abbreviation ("CtF" -> "Cold to Fire")
			"^ " .. lowerSearch, -- Starts with
			lowerSearch, -- Contains
		}
		for i, pattern in ipairs(patternList) do
			local matchList = { }
			for gemId, gemData in pairs(self.gems) do
				if self:FilterSupport(gemId, gemData) and not added[gemId] and ((" "..gemData.name:lower()):match(pattern)) then
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
							elseif tagName == "aoe" then
								tagName = "area"
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
		and sortCache.considerGemType == self.skillsTab.showSupportGemTypes and sortCache.showLegacyGems == self.skillsTab.showLegacyGems then
		return
	end

	if not sameSortBy or not sortCache or (sortCache.considerGemType ~= self.skillsTab.showSupportGemTypes
		or sortCache.showLegacyGems ~= self.skillsTab.showLegacyGems
		or sortCache.defaultQuality ~= self.skillsTab.defaultGemQuality
		or sortCache.defaultLevel ~= self.skillsTab.defaultGemLevel
		or (sortCache.characterLevel ~= self.skillsTab.build.characterLevel and self.skillsTab.defaultGemLevel == "characterLevel")) then
		self.lastSortGemsBy = self.sortGemsBy
		self:PopulateGemList()
	end

	-- Initialize a new sort cache
	sortCache = {
		considerGemType = self.skillsTab.showSupportGemTypes,
		showLegacyGems = self.skillsTab.showLegacyGems,
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
					if calcLib.canGrantedEffectSupportActiveSkill(gemData.grantedEffect, activeSkill, self.imbuedSelect) then
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
							if calcLib.canGrantedEffectSupportActiveSkill(gemData.grantedEffect, activeSkill, self.imbuedSelect) then
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
								if calcLib.canGrantedEffectSupportActiveSkill(gemData.grantedEffect, activeSkill, self.imbuedSelect) then
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
	local useFullDPS = dpsField == "FullDPS"
	local calcFunc, calcBase = self.skillsTab.build.calcsTab:GetMiscCalculator(self.build)
	-- Check for nil because some fields may not be populated, default to 0
	local baseDPS = (dpsField == "FullDPS" and calcBase[dpsField] ~= nil and calcBase[dpsField]) or (calcBase.Minion and calcBase.Minion.CombinedDPS) or (calcBase[dpsField] ~= nil and calcBase[dpsField]) or 0

	sortCache.calcFunc = calcFunc
	sortCache.useFullDPS = useFullDPS
	sortCache.baseDPS = baseDPS
	sortCache.dpsField = dpsField
	sortCache.pendingGems = { }

	for gemId, gemData in pairs(self.gems) do
		sortCache.dps[gemId] = baseDPS
		-- Gems that support the active skill or have global effects need DPS calc
		if sortCache.canSupport[gemId] or (gemData.grantedEffect.hasGlobalEffect and not gemData.grantedEffect.support) then
			sortCache.pendingGems[#sortCache.pendingGems + 1] = gemId
		end
		-- Neutral color until DPS is computed
		sortCache.dpsColor[gemId] = ""
	end

	self.dpsBuildFlag = true
end

function GemSelectClass:SortGemList(gemList)
	local sortCache = self.sortCache
	local gems = self.gems
	-- cache names to avoid repeated table lookups in comparator
	local names = {}
	for _, gemId in ipairs(gemList) do
		local gem = gems[gemId]
		names[gemId] = gem and gem.name or gemId
	end
	t_sort(gemList, function(a, b)
		if sortCache.canSupport[a] == sortCache.canSupport[b] then
			if self.skillsTab.sortGemsByDPS and sortCache.dps[a] ~= sortCache.dps[b] then
				return sortCache.dps[a] > sortCache.dps[b]
			else
				return names[a] < names[b]
			end
		else
			return sortCache.canSupport[a]
		end
	end)
end

function GemSelectClass:SyncSelection()
	self.selIndex = 0
	for index, gemId in ipairs(self.list) do
		if self.gems[gemId] and self.gems[gemId].name:lower() == self.buf:lower() then
			self.selIndex = index
			self:ScrollSelIntoView()
			break
		end
	end
end

function GemSelectClass:SortCurrentList()
	if #self.searchStr == 0 then
		self:SortGemList(self.list)
		self:SyncSelection()
	end
end

function GemSelectClass:DPSBuilder()
	local sortCache = self.sortCache
	if not sortCache or not sortCache.pendingGems then return end

	local pending = sortCache.pendingGems
	local calcFunc = sortCache.calcFunc
	local useFullDPS = sortCache.useFullDPS
	local baseDPS = sortCache.baseDPS
	local dpsField = sortCache.dpsField
	local start = GetTime()

	for index, gemId in ipairs(pending) do
		local gemData = self.gems[gemId]
		if gemData then
			local output = self:CalcOutputWithThisGem(calcFunc, gemData, useFullDPS)
			sortCache.dps[gemId] = (dpsField == "FullDPS" and output[dpsField] ~= nil and output[dpsField]) or (output.Minion and output.Minion.CombinedDPS) or (output[dpsField] ~= nil and output[dpsField]) or 0
			if sortCache.dps[gemId] > baseDPS then
				sortCache.dpsColor[gemId] = "^x228866"
			elseif sortCache.dps[gemId] < baseDPS then
				sortCache.dpsColor[gemId] = "^xFF4422"
			else
				sortCache.dpsColor[gemId] = "^xFFFF66"
			end
		end
		local now = GetTime()
		if now - start > 50 then
			self:SortCurrentList()
			if self.dpsBuilderCallback then
				self.dpsBuilderCallback(m_floor(index/#pending*100))
			end
			coroutine.yield()
			start = now
		end
	end

	self:SortCurrentList()
	sortCache.pendingGems = nil
end

function GemSelectClass:UpdateGem(setText, addUndo, focusLost)
	local gemId = self.list[m_max(self.selIndex, 1)]
	-- don't process unless the buffer equals an actual gem, whether typed, clicked, or navigated with arrows
	-- we don't nil the gemId here if it doesn't match because the imbuedGemSelect and slotGemSelect have different paths
	local bufMatchesGem = (self.gems[gemId] and self.buf:lower() == self.gems[gemId].name:lower())

	if self.buf:match("%S") and self.gems[gemId] then
		self.gemId = gemId
	else
		self.gemId = nil
	end
	self.gemName = bufMatchesGem and (self.gemId and self.gems[self.gemId].name) or ""
	if setText then
		self:SetText(self.gemName)
	end
	self.gemChangeFunc(self.gemId and self.gemId:gsub("%w+:", ""), addUndo and self.gemName ~= self.initialBuf, focusLost, bufMatchesGem)
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
	self.sortPercentage = self.sortPercentage or ""
	if self.dpsBuildFlag then
		self.dpsBuildFlag = false
		self.dpsBuilder = coroutine.create(self.DPSBuilder)
		self.dpsBuilderCallback = function(percentage)
			self.sortPercentage = ("%d%%"):format(percentage)
		end
	end
	if self.dpsBuilder then
		local res, errMsg = coroutine.resume(self.dpsBuilder, self)
		if launch.devMode and not res then
			error(errMsg)
		end
		if coroutine.status(self.dpsBuilder) == "dead" then
			self.dpsBuilder = nil
		end
	end

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
		if self.dpsBuilder then
			SetDrawColor(0.75, 0.75, 0.75)
			DrawString(x + width - 4, y, "RIGHT_X", height - 2, "VAR", "Sorting " .. self.sortPercentage)
		end
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
			DrawString(0, y, "LEFT", height - 4, "VAR", gemText)
			if gemData then
				if gemData.grantedEffect.support and self.sortCache.canSupport[gemId] and self.sortCache.dpsColor[gemId] ~= "" then
					SetDrawColor(self.sortCache.dpsColor[gemId])
					main:DrawCheckMark(width - 4 - height / 2 - (scrollBar.enabled and 18 or 0), y + (height - 4) / 2, (height - 4) * 0.8)
				elseif gemData.grantedEffect.hasGlobalEffect and self.sortCache.dpsColor[gemId] ~= "" then
					SetDrawColor(self.sortCache.dpsColor[gemId])
					DrawString(width - 4 - height / 2 - (scrollBar.enabled and 18 or 0), y - 2, "CENTER_X", height, "VAR", "+")
				end
			end
		end
		SetViewport()
		self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)
		if self.hoverSel then
			-- Debounce hover
			if self.hoverSel == self.lastHoverSel then
				self.hoverFrameCount = (self.hoverFrameCount or 0) + 1
			else
				self.lastHoverSel = self.hoverSel
				self.hoverFrameCount = 0
			end
			if self.hoverFrameCount >= 2 then
				local calcFunc, calcBase = self.skillsTab.build.calcsTab:GetMiscCalculator(self.build)
				if calcFunc then
					self.tooltip:Clear()
					local gemData = self.gems[self.list[self.hoverSel]]
					local output= self:CalcOutputWithThisGem(calcFunc, gemData, self.skillsTab.sortGemsByDPSField == "FullDPS")
					local gemInstance = {
						level = self.skillsTab:ProcessGemLevel(gemData, self.imbuedSelect),
						quality = self.skillsTab.defaultGemQuality or 0,
						qualityId = "Default",
						count = 1,
						enabled = true,
						enableGlobal1 = true,
						enableGlobal2 = true,
						gemId = gemData.id,
						nameSpec = gemData.name,
						skillId = gemData.grantedEffectId,
						displayEffect = nil,
						gemData = gemData
					}
					self:AddGemTooltip(gemInstance)
					self.tooltip:AddSeparator(10)
					self.skillsTab.build:AddStatComparesToTooltip(self.tooltip, calcBase, output, "^7Selecting this gem will give you:")
					self.tooltip:Draw(x, y + height + 2 + (self.hoverSel - 1) * (height - 4) - scrollBar.offset, width, height - 4, viewPort)
				end
			end
		else
			self.lastHoverSel = nil
			self.hoverFrameCount = 0
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

			if hoverControl and hoverControl.imbuedSelect then -- tooltip for imbued
				gemInstance = { }
				if type(hoverControl.gemId) == "string" then -- on select
					gemInstance["gemData"] = hoverControl.gems[hoverControl.gemId]
				else -- on load
					gemInstance["gemData"] = hoverControl.gemId
				end
				gemInstance.level = 1
				gemInstance.quality = 0
			end

			if gemInstance and gemInstance.gemData then
				self:AddGemTooltip(gemInstance)
			else
				self.tooltip:AddLine(16, self.imbuedSelect and imbuedTooltipText or toolTipText)
			end

			if not self.imbuedSelect then
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
				DrawImage(nil, sx, y+2, 16, height-4)
				SetDrawColor(0,0,0)
				DrawImage(nil, sx+1, y+2, 16-2, height-4)
				SetDrawColor(colorS,colorS,colorS)
				DrawString(sx + 8, y, "CENTER_X", height - 2, "VAR", "S")

				-- active shortcut
				sx = x + width - (16*2) - (2*2)
				SetDrawColor(colorA,colorA,colorA)
				DrawImage(nil, sx, y+2, 16, height-4)
				SetDrawColor(0,0,0)
				DrawImage(nil, sx+1, y+2, 16-2, height-4)
				SetDrawColor(colorA,colorA,colorA)
				DrawString(sx + 8, y, "CENTER_X", height - 2, "VAR", "A")
			end

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
	gemTooltip.AddGemTooltip(self.tooltip, self.skillsTab.build, gemInstance)
end

function GemSelectClass:OnFocusGained()
	self.EditControl:OnFocusGained()
	self.dropped = true
	self:UpdateSortCache()
	self:BuildList("")
	self:SyncSelection()
	self.initialBuf = self.buf
end

function GemSelectClass:CancelSelection()
	self.dropped = false
	self.buf = self.initialBuf
	self:BuildList("")
	self:SyncSelection()
	self:UpdateGem(false, true, true)
end

function GemSelectClass:OnFocusLost()
	if self.dropped then
		self:CancelSelection()
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
	if not self.imbuedSelect and key == "LEFTBUTTON" and (cursorY > y and cursorY < (y + height)) then
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
			self:CancelSelection()
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
			if self.gems[self.list[self.selIndex]] then
				self:SetText(self.gems[self.list[self.selIndex]].name)
			end
			self:UpdateGem(true, true, true)
			return
		elseif key == "ESCAPE" then
			self:CancelSelection()
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
