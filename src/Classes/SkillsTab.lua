-- Path of Building
--
-- Module: Skills Tab
-- Skills tab for the current build.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max

local groupSlotDropList = {
	{ label = "None" },
	{ label = "Weapon 1", slotName = "Weapon 1" },
	{ label = "Weapon 2", slotName = "Weapon 2" },
	{ label = "Weapon 1 (Swap)", slotName = "Weapon 1 Swap" },
	{ label = "Weapon 2 (Swap)", slotName = "Weapon 2 Swap" },
	{ label = "Helmet", slotName = "Helmet" },
	{ label = "Body Armour", slotName = "Body Armour" },
	{ label = "Gloves", slotName = "Gloves" },
	{ label = "Boots", slotName = "Boots" }, 
	{ label = "Amulet", slotName = "Amulet" },
	{ label = "Ring 1", slotName = "Ring 1" },
	{ label = "Ring 2", slotName = "Ring 2" },
	{ label = "Belt", slotName = "Belt" },
}

local defaultGemLevelList = {
	{
		label = "Normal Maximum",
		description = "All gems default to their highest valid non-corrupted gem level.",
		gemLevel = "normalMaximum",
	},
	{
		label = "Corrupted Maximum",
		description = [[Normal gems default to their highest valid corrupted gem level.
Awakened gems default to their highest valid non-corrupted gem level.]],
		gemLevel = "corruptedMaximum",
	},
	{
		label = "Awakened Maximum",
		description = "All gems default to their highest valid corrupted gem level.",
		gemLevel = "awakenedMaximum",
	},
	{
		label = "Match Character Level",
		description = [[All gems default to their highest valid non-corrupted gem level that your character meets the level requirement for.
This hides gems with a minimum level requirement above your character level, preventing them from showing up in the dropdown list.]],
		gemLevel = "characterLevel",
	},
}

local showSupportGemTypeList = {
	{ label = "All", show = "ALL" },
	{ label = "Non-Awakened", show = "NORMAL" },
	{ label = "Awakened", show = "AWAKENED" },
}

local sortGemTypeList = {
	{ label = "Full DPS", type = "FullDPS" },
	{ label = "Combined DPS", type = "CombinedDPS" },
	{ label = "Hit DPS", type = "TotalDPS" },
	{ label = "Average Hit", type = "AverageDamage" },
	{ label = "DoT DPS", type = "TotalDot" },
	{ label = "Bleed DPS", type = "BleedDPS" },
	{ label = "Ignite DPS", type = "IgniteDPS" },
	{ label = "Poison DPS", type = "TotalPoisonDPS" },
	{ label = "Effective Hit Pool", type = "TotalEHP" },
}

local alternateGemQualityList ={
	{ label = "Default", type = "Default" },
	{ label = "Anomalous", type = "Alternate1" },
	{ label = "Divergent", type = "Alternate2" },
	{ label = "Phantasmal", type = "Alternate3" },
}

local SkillsTabClass = newClass("SkillsTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build

	self.socketGroupList = { }

	self.sortGemsByDPS = true
	self.sortGemsByDPSField = "CombinedDPS"
	self.showSupportGemTypes = "ALL"
	self.showAltQualityGems = false
	self.defaultGemLevel = "normalMaximum"
	self.defaultGemQuality = main.defaultGemQuality

	-- Set selector
	self.controls.setSelect = new("DropDownControl", { "TOPLEFT", self, "TOPLEFT" }, 76, 8, 210, 20, nil, function(index, value)
		self:SetActiveSkillSet(self.skillSetOrderList[index])
		self:SetDisplayGroup(self.socketGroupList[1])
		self:AddUndoState()
	end)
	self.controls.setSelect.enableDroppedWidth = true
	self.controls.setSelect.enabled = function()
		return #self.skillSetOrderList > 1
	end
	self.controls.setLabel = new("LabelControl", { "RIGHT", self.controls.setSelect, "LEFT" }, -2, 0, 0, 16, "^7Skill set:")
	self.controls.setManage = new("ButtonControl", { "LEFT", self.controls.setSelect, "RIGHT" }, 4, 0, 90, 20, "Manage...", function()
		self:OpenSkillSetManagePopup()
	end)

	-- Socket group list
	self.controls.groupList = new("SkillListControl", { "TOPLEFT", self, "TOPLEFT" }, 20, 54, 360, 300, self)
	self.controls.groupTip = new("LabelControl", { "TOPLEFT", self.controls.groupList, "BOTTOMLEFT" }, 0, 8, 0, 14, 
[[
^7Usage Tips:
- You can copy/paste socket groups using Ctrl+C and Ctrl+V.
- Ctrl + Click to enable/disable socket groups.
- Ctrl + Right click to include/exclude in FullDPS calculations.
- Right click to set as the Main skill group.
]]
	)

	-- Gem options
	local optionInputsX = 170
	local optionInputsY = 45
	self.controls.optionSection = new("SectionControl", { "TOPLEFT", self.controls.groupList, "BOTTOMLEFT" }, 0, optionInputsY + 50, 360, 156, "Gem Options")
	self.controls.sortGemsByDPS = new("CheckBoxControl", { "TOPLEFT", self.controls.groupList, "BOTTOMLEFT" }, optionInputsX, optionInputsY + 70, 20, "Sort gems by DPS:", function(state)
		self.sortGemsByDPS = state
	end, nil, true)
	self.controls.sortGemsByDPSFieldControl = new("DropDownControl", { "LEFT", self.controls.sortGemsByDPS, "RIGHT" }, 10, 0, 140, 20, sortGemTypeList, function(index, value)
		self.sortGemsByDPSField = value.type
	end)
	self.controls.defaultLevel = new("DropDownControl", { "TOPLEFT", self.controls.groupList, "BOTTOMLEFT" }, optionInputsX, optionInputsY + 94, 170, 20, defaultGemLevelList, function(index, value)
		self.defaultGemLevel = value.gemLevel
	end)
	self.controls.defaultLevel.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" and value.description then
			tooltip:AddLine(16, "^7" .. value.description)
		end
	end
	self.controls.defaultLevelLabel = new("LabelControl", { "RIGHT", self.controls.defaultLevel, "LEFT" }, -4, 0, 0, 16, "^7Default gem level:")
	self.controls.defaultQuality = new("EditControl", { "TOPLEFT", self.controls.groupList, "BOTTOMLEFT" }, optionInputsX, optionInputsY + 118, 60, 20, nil, nil, "%D", 2, function(buf)
		self.defaultGemQuality = m_min(tonumber(buf) or 0, 23)
	end)
	self.controls.defaultQualityLabel = new("LabelControl", { "RIGHT", self.controls.defaultQuality, "LEFT" }, -4, 0, 0, 16, "^7Default gem quality:")
	self.controls.showSupportGemTypes = new("DropDownControl", { "TOPLEFT", self.controls.groupList, "BOTTOMLEFT" }, optionInputsX, optionInputsY + 142, 170, 20, showSupportGemTypeList, function(index, value)
		self.showSupportGemTypes = value.show
	end)
	self.controls.showSupportGemTypesLabel = new("LabelControl", { "RIGHT", self.controls.showSupportGemTypes, "LEFT" }, -4, 0, 0, 16, "^7Show support gems:")
	self.controls.showAltQualityGems = new("CheckBoxControl", { "TOPLEFT", self.controls.groupList, "BOTTOMLEFT" }, optionInputsX, optionInputsY + 166, 20, "^7Show quality variants:", function(state)
		self.showAltQualityGems = state
	end)

	-- Socket group details
	if main.portraitMode then
		self.anchorGroupDetail = new("Control", { "TOPLEFT", self.controls.optionSection, "BOTTOMLEFT" }, 0, 20, 0, 0)
	else
		self.anchorGroupDetail = new("Control", { "TOPLEFT", self.controls.groupList, "TOPRIGHT" }, 20, 0, 0, 0)
	end
	self.anchorGroupDetail.shown = function()
		return self.displayGroup ~= nil
	end
	self.controls.groupLabel = new("EditControl", { "TOPLEFT", self.anchorGroupDetail, "TOPLEFT" }, 0, 0, 380, 20, nil, "Label", "%c", 50, function(buf)
		self.displayGroup.label = buf
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.groupSlotLabel = new("LabelControl", { "TOPLEFT", self.anchorGroupDetail, "TOPLEFT" }, 0, 30, 0, 16, "^7Socketed in:")
	self.controls.groupSlot = new("DropDownControl", { "TOPLEFT", self.anchorGroupDetail, "TOPLEFT" }, 85, 28, 130, 20, groupSlotDropList, function(index, value)
		self.displayGroup.slot = value.slotName
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.groupSlot.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode == "OUT" or index == 1 then
			tooltip:AddLine(16, "Select the item in which this skill is socketed.")
			tooltip:AddLine(16, "This will allow the skill to benefit from modifiers on the item that affect socketed gems.")
		else
			local slot = self.build.itemsTab.slots[value.slotName]
			local ttItem = self.build.itemsTab.items[slot.selItemId]
			if ttItem then
				self.build.itemsTab:AddItemTooltip(tooltip, ttItem, slot)
			else
				tooltip:AddLine(16, "No item is equipped in this slot.")
			end
		end
	end
	self.controls.groupSlot.enabled = function()
		return self.displayGroup.source == nil
	end
	self.controls.groupEnabled = new("CheckBoxControl", { "LEFT", self.controls.groupSlot, "RIGHT" }, 70, 0, 20, "Enabled:", function(state)
		self.displayGroup.enabled = state
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.includeInFullDPS = new("CheckBoxControl", { "LEFT", self.controls.groupEnabled, "RIGHT" }, 145, 0, 20, "Include in Full DPS:", function(state)
		self.displayGroup.includeInFullDPS = state
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.groupCountLabel = new("LabelControl", { "LEFT", self.controls.includeInFullDPS, "RIGHT" }, 16, 0, 0, 16, "Count:")
	self.controls.groupCountLabel.shown = function()
		return self.displayGroup.source ~= nil
	end
	self.controls.groupCount = new("EditControl", { "LEFT", self.controls.groupCountLabel, "RIGHT" }, 4, 0, 60, 20, nil, nil, "%D", 2, function(buf)
		self.displayGroup.groupCount = tonumber(buf) or 1
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.groupCount.shown = function()
		return self.displayGroup.source ~= nil
	end
	self.controls.sourceNote = new("LabelControl", { "TOPLEFT", self.controls.groupSlotLabel, "TOPLEFT" }, 0, 30, 0, 16)
	self.controls.sourceNote.shown = function()
		return self.displayGroup.source ~= nil
	end
	self.controls.sourceNote.label = function()
		local label
		if self.displayGroup.explodeSources then
			label = [[^7This is a special group created for the enemy explosion effect,
which comes from the following sources:]]
			for _, source in ipairs(self.displayGroup.explodeSources) do
				label = label .. "\n\t" .. colorCodes[source.rarity or "NORMAL"] .. (source.name or source.dn or "???")
			end
			label = label .. "^7\nYou cannot delete this group, but it will disappear if you lose the above sources."
		else
			local activeGem = self.displayGroup.gemList[1]
			local sourceName
			if self.displayGroup.sourceItem then
				sourceName = "'" .. colorCodes[self.displayGroup.sourceItem.rarity] .. self.displayGroup.sourceItem.name
			elseif self.displayGroup.sourceNode then
				sourceName = "'" .. colorCodes["NORMAL"] .. self.displayGroup.sourceNode.name
			else
				sourceName = "'" .. colorCodes["NORMAL"] .. "?"
			end
			sourceName = sourceName .. "^7'"
			label = [[^7This is a special group created for the ']] .. activeGem.color .. (activeGem.grantedEffect and activeGem.grantedEffect.name or activeGem.nameSpec) .. [[^7' skill,
which is being provided by ]] .. sourceName .. [[.
You cannot delete this group, but it will disappear if you ]] .. (self.displayGroup.sourceNode and [[un-allocate the node.]] or [[un-equip the item.]])
			if not self.displayGroup.noSupports then
				label = label .. "\n\n" .. [[You cannot add support gems to this group, but support gems in
any other group socketed into ]] .. sourceName .. [[
will automatically apply to the skill.]]
			end
		end
		return label
	end

	-- Scroll bar
	self.controls.scrollBarH = new("ScrollBarControl", nil, 0, 0, 0, 18, 100, "HORIZONTAL", true)

	-- Initialise skill sets
	self.skillSets = { }
	self.skillSetOrderList = { 1 }
	self:NewSkillSet(1)
	self:SetActiveSkillSet(1)

	-- Skill gem slots
	self.anchorGemSlots = new("Control", {"TOPLEFT",self.anchorGroupDetail,"TOPLEFT"}, 0, 28 + 28 + 16, 0, 0)
	self.gemSlots = { }
	self:CreateGemSlot(1)
	self.controls.gemNameHeader = new("LabelControl", { "BOTTOMLEFT", self.gemSlots[1].nameSpec, "TOPLEFT" }, 0, -2, 0, 16, "^7Gem name:")
	self.controls.gemLevelHeader = new("LabelControl", { "BOTTOMLEFT", self.gemSlots[1].level, "TOPLEFT" }, 0, -2, 0, 16, "^7Level:")
	self.controls.gemQualityIdHeader = new("LabelControl", { "BOTTOMLEFT", self.gemSlots[1].qualityId, "TOPLEFT" }, 0, -2, 0, 16, "^7Variant:")
	self.controls.gemQualityHeader = new("LabelControl", { "BOTTOMLEFT", self.gemSlots[1].quality, "TOPLEFT" }, 0, -2, 0, 16, "^7Quality:")
	self.controls.gemEnableHeader = new("LabelControl", { "BOTTOMLEFT", self.gemSlots[1].enabled, "TOPLEFT" }, -16, -2, 0, 16, "^7Enabled:")
	self.controls.gemCountHeader = new("LabelControl", { "BOTTOMLEFT", self.gemSlots[1].count, "TOPLEFT" }, 8, -2, 0, 16, "^7Count:")
end)

-- parse real gem name and quality by omitting the first word if alt qual is set
function SkillsTabClass:GetBaseNameAndQuality(gemTypeLine, quality)
	gemTypeLine = sanitiseText(gemTypeLine)
	-- if quality is default or nil check the gem type line if we have alt qual by comparing to the existing list
	if gemTypeLine and (quality == nil or quality == "" or quality == "Default") then
		local firstword, otherwords = gemTypeLine:match("(%w+)%s(.+)")
		if firstword and otherwords then
			for _, entry in ipairs(alternateGemQualityList) do
				if firstword == entry.label then
					-- return the gem name minus <altqual> without a leading space and the new resolved type
					if entry.type == nil or entry.type == "" then
						entry.type = "Default"
					end
					return otherwords, entry.type
				end
			end
		end
	end
	-- no alt qual found, return gemTypeLine as is and either existing quality or Default if none is set
	return gemTypeLine, quality or "Default"
end

function SkillsTabClass:LoadSkill(node, skillSetId)
	if node.elem ~= "Skill" then
		return
	end

	local socketGroup = { }
	socketGroup.enabled = node.attrib.active == "true" or node.attrib.enabled == "true"
	socketGroup.includeInFullDPS = node.attrib.includeInFullDPS and node.attrib.includeInFullDPS == "true"
	socketGroup.groupCount = tonumber(node.attrib.groupCount)
	socketGroup.label = node.attrib.label
	socketGroup.slot = node.attrib.slot
	socketGroup.source = node.attrib.source
	socketGroup.mainActiveSkill = tonumber(node.attrib.mainActiveSkill) or 1
	socketGroup.mainActiveSkillCalcs = tonumber(node.attrib.mainActiveSkillCalcs) or 1
	socketGroup.gemList = { }
	for _, child in ipairs(node) do
		local gemInstance = { }
		gemInstance.nameSpec = sanitiseText(child.attrib.nameSpec or "")
		if child.attrib.gemId then
			local gemData
			local possibleVariants = self.build.data.gemsByGameId[child.attrib.gemId]
			if possibleVariants then
				-- If it is a known gem, try to determine which variant is used
				if child.attrib.variantId then
					-- New save format from 3.23 that stores the specific variation (transfiguration)
					gemData = possibleVariants[child.attrib.variantId]
				elseif child.attrib.skillId then
					-- Old format relying on the uniqueness of the granted effects id
					for _, variant in pairs(possibleVariants) do
						if variant.grantedEffectId == child.attrib.skillId then
							gemData = variant
							break
						end
					end
				end
			end
			if gemData then
				gemInstance.gemId = gemData.id
				gemInstance.skillId = gemData.grantedEffectId
				gemInstance.nameSpec = gemData.nameSpec
			end
		elseif child.attrib.skillId then
			local grantedEffect = self.build.data.skills[child.attrib.skillId]
			if grantedEffect then
				gemInstance.gemId = self.build.data.gemForSkill[grantedEffect]
				gemInstance.skillId = grantedEffect.id
				gemInstance.nameSpec = grantedEffect.name
			end
		end
		gemInstance.level = tonumber(child.attrib.level)
		gemInstance.quality = tonumber(child.attrib.quality)
		local nameSpecOverride, qualityOverrideId = SkillsTabClass:GetBaseNameAndQuality(gemInstance.nameSpec, child.attrib.qualityId)
		gemInstance.nameSpec = nameSpecOverride
		gemInstance.qualityId = qualityOverrideId

		if gemInstance.gemData then
			gemInstance.qualityId.list = self:getGemAltQualityList(gemInstance.gemData)
		end
		gemInstance.enabled = not child.attrib.enabled and true or child.attrib.enabled == "true"
		gemInstance.enableGlobal1 = not child.attrib.enableGlobal1 or child.attrib.enableGlobal1 == "true"
		gemInstance.enableGlobal2 = child.attrib.enableGlobal2 == "true"
		gemInstance.count = tonumber(child.attrib.count) or 1
		gemInstance.skillPart = tonumber(child.attrib.skillPart)
		gemInstance.skillPartCalcs = tonumber(child.attrib.skillPartCalcs)
		gemInstance.skillStageCount = tonumber(child.attrib.skillStageCount)
		gemInstance.skillStageCountCalcs = tonumber(child.attrib.skillStageCountCalcs)
		gemInstance.skillMineCount = tonumber(child.attrib.skillMineCount)
		gemInstance.skillMineCountCalcs = tonumber(child.attrib.skillMineCountCalcs)
		gemInstance.skillMinion = child.attrib.skillMinion
		gemInstance.skillMinionCalcs = child.attrib.skillMinionCalcs
		gemInstance.skillMinionItemSet = tonumber(child.attrib.skillMinionItemSet)
		gemInstance.skillMinionItemSetCalcs = tonumber(child.attrib.skillMinionItemSetCalcs)
		gemInstance.skillMinionSkill = tonumber(child.attrib.skillMinionSkill)
		gemInstance.skillMinionSkillCalcs = tonumber(child.attrib.skillMinionSkillCalcs)
		t_insert(socketGroup.gemList, gemInstance)
	end
	if node.attrib.skillPart and socketGroup.gemList[1] then
		socketGroup.gemList[1].skillPart = tonumber(node.attrib.skillPart)
	end
	self:ProcessSocketGroup(socketGroup)
	t_insert(self.skillSets[skillSetId].socketGroupList, socketGroup)
end

function SkillsTabClass:Load(xml, fileName)
	self.activeSkillSetId = 0
	self.skillSets = { }
	self.skillSetOrderList = { }
	-- Handle legacy configuration settings when loading `defaultGemLevel`
	if xml.attrib.matchGemLevelToCharacterLevel == "true" then
		self.controls.defaultLevel:SelByValue("characterLevel", "gemLevel")
	elseif type(xml.attrib.defaultGemLevel) == "string" and tonumber(xml.attrib.defaultGemLevel) == nil then
		self.controls.defaultLevel:SelByValue(xml.attrib.defaultGemLevel, "gemLevel")
	else
		self.controls.defaultLevel:SelByValue("normalMaximum", "gemLevel")
	end
	self.defaultGemLevel = self.controls.defaultLevel:GetSelValue("gemLevel")
	self.defaultGemQuality = m_max(m_min(tonumber(xml.attrib.defaultGemQuality) or 0, 23), 0)
	self.controls.defaultQuality:SetText(self.defaultGemQuality or "")
	if xml.attrib.sortGemsByDPS then
		self.sortGemsByDPS = xml.attrib.sortGemsByDPS == "true"
	end
	self.controls.sortGemsByDPS.state = self.sortGemsByDPS
	if xml.attrib.showAltQualityGems then
		self.showAltQualityGems = xml.attrib.showAltQualityGems == "true"
	end
	self.controls.showAltQualityGems.state = self.showAltQualityGems
	self.controls.showSupportGemTypes:SelByValue(xml.attrib.showSupportGemTypes or "ALL", "show")
	self.controls.sortGemsByDPSFieldControl:SelByValue(xml.attrib.sortGemsByDPSField or "CombinedDPS", "type") 
	self.showSupportGemTypes = self.controls.showSupportGemTypes:GetSelValue("show")
	self.sortGemsByDPSField = self.controls.sortGemsByDPSFieldControl:GetSelValue("type")
	for _, node in ipairs(xml) do
		if node.elem == "Skill" then
			-- Old format, initialize skill sets if needed
			if not self.skillSetOrderList[1] then
				self.skillSetOrderList[1] = 1
				self:NewSkillSet(1)
			end
			self:LoadSkill(node, 1)
		end

		if node.elem == "SkillSet" then
			local skillSet = self:NewSkillSet(tonumber(node.attrib.id))
			skillSet.title = node.attrib.title
			t_insert(self.skillSetOrderList, skillSet.id)
			for _, subNode in ipairs(node) do
				self:LoadSkill(subNode, skillSet.id)
			end
		end
	end
	self:SetActiveSkillSet(tonumber(xml.attrib.activeSkillSet) or 1)
	self:SetDisplayGroup(self.socketGroupList[1])
	self:ResetUndo()
end

function SkillsTabClass:Save(xml)
	xml.attrib = {
		activeSkillSet = tostring(self.activeSkillSetId),
		defaultGemLevel = self.defaultGemLevel,
		defaultGemQuality = tostring(self.defaultGemQuality),
		sortGemsByDPS = tostring(self.sortGemsByDPS),
		showSupportGemTypes = self.showSupportGemTypes,
		sortGemsByDPSField = self.sortGemsByDPSField,
		showAltQualityGems = tostring(self.showAltQualityGems)
	}
	for _, skillSetId in ipairs(self.skillSetOrderList) do
		local skillSet = self.skillSets[skillSetId]
		local child = { elem = "SkillSet", attrib = { id = tostring(skillSetId), title = skillSet.title } }
		t_insert(xml, child)

		for _, socketGroup in ipairs(skillSet.socketGroupList) do
			local node = { elem = "Skill", attrib = {
				enabled = tostring(socketGroup.enabled),
				includeInFullDPS = tostring(socketGroup.includeInFullDPS),
				groupCount = socketGroup.groupCount ~= nil and tostring(socketGroup.groupCount),
				label = socketGroup.label,
				slot = socketGroup.slot,
				source = socketGroup.source,
				mainActiveSkill = tostring(socketGroup.mainActiveSkill),
				mainActiveSkillCalcs = tostring(socketGroup.mainActiveSkillCalcs),
			} }
			for _, gemInstance in ipairs(socketGroup.gemList) do
				t_insert(node, { elem = "Gem", attrib = {
					nameSpec = gemInstance.nameSpec,
					skillId = gemInstance.skillId,
					gemId = gemInstance.gemData and gemInstance.gemData.gameId,
					variantId = gemInstance.gemData and gemInstance.gemData.variantId,
					level = tostring(gemInstance.level),
					quality = tostring(gemInstance.quality),
					qualityId = gemInstance.qualityId,
					enabled = tostring(gemInstance.enabled),
					enableGlobal1 = tostring(gemInstance.enableGlobal1),
					enableGlobal2 = tostring(gemInstance.enableGlobal2),
					count = tostring(gemInstance.count),
					skillPart = gemInstance.skillPart and tostring(gemInstance.skillPart),
					skillPartCalcs = gemInstance.skillPartCalcs and tostring(gemInstance.skillPartCalcs),
					skillStageCount = gemInstance.skillStageCount and tostring(gemInstance.skillStageCount),
					skillStageCountCalcs = gemInstance.skillStageCountCalcs and tostring(gemInstance.skillStageCountCalcs),
					skillMineCount = gemInstance.skillMineCount and tostring(gemInstance.skillMineCount),
					skillMineCountCalcs = gemInstance.skillMineCountCalcs and tostring(gemInstance.skillMineCountCalcs),
					skillMinion = gemInstance.skillMinion,
					skillMinionCalcs = gemInstance.skillMinionCalcs,
					skillMinionItemSet = gemInstance.skillMinionItemSet and tostring(gemInstance.skillMinionItemSet),
					skillMinionItemSetCalcs = gemInstance.skillMinionItemSetCalcs and tostring(gemInstance.skillMinionItemSetCalcs),
					skillMinionSkill = gemInstance.skillMinionSkill and tostring(gemInstance.skillMinionSkill),
					skillMinionSkillCalcs = gemInstance.skillMinionSkillCalcs and tostring(gemInstance.skillMinionSkillCalcs),
				} })
			end
			t_insert(child, node)
		end
	end
end

function SkillsTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height
	self.controls.scrollBarH.width = viewPort.width
	self.controls.scrollBarH.x = viewPort.x
	self.controls.scrollBarH.y = viewPort.y + viewPort.height - 18

	do
		local maxX = self.controls.gemCountHeader:GetPos() + self.controls.gemCountHeader:GetSize() + 15
		local contentWidth = maxX - self.x
		self.controls.scrollBarH:SetContentDimension(contentWidth, viewPort.width)
	end
	self.x = self.x - self.controls.scrollBarH.offset

	for _, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
				self.build.buildFlag = true
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
				self.build.buildFlag = true
			elseif event.key == "v" and IsKeyDown("CTRL") then
				self:PasteSocketGroup()
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)
	for _, event in ipairs(inputEvents) do
		if event.type == "KeyUp" then
			if self.controls.scrollBarH:IsScrollDownKey(event.key) then
				self.controls.scrollBarH:Scroll(1)
			elseif self.controls.scrollBarH:IsScrollUpKey(event.key) then
				self.controls.scrollBarH:Scroll(-1)
			end
		end
	end

	main:DrawBackground(viewPort)

	local newSetList = { }
	for index, skillSetId in ipairs(self.skillSetOrderList) do
		local skillSet = self.skillSets[skillSetId]
		t_insert(newSetList, skillSet.title or "Default")
		if skillSetId == self.activeSkillSetId then
			self.controls.setSelect.selIndex = index
		end
	end
	self.controls.setSelect:SetList(newSetList)

	if main.portraitMode then
		self.anchorGroupDetail:SetAnchor("TOPLEFT",self.controls.optionSection,"BOTTOMLEFT", 0, 20)
	else
		self.anchorGroupDetail:SetAnchor("TOPLEFT",self.controls.groupList,"TOPRIGHT", 20, 0)
	end

	self:UpdateGemSlots()

	self:DrawControls(viewPort)
end

function SkillsTabClass:CopySocketGroup(socketGroup)
	local skillText = ""
	if socketGroup.label and socketGroup.label:match("%S") then
		skillText = skillText .. "Label: " .. socketGroup.label .. "\r\n"
	end
	if socketGroup.slot then
		skillText = skillText .. "Slot: " .. socketGroup.slot .. "\r\n"
	end
	for _, gemInstance in ipairs(socketGroup.gemList) do
		skillText = skillText .. string.format("%s %d/%d %s %s %d\r\n", gemInstance.nameSpec, gemInstance.level, gemInstance.quality, gemInstance.qualityId, gemInstance.enabled and "" or "DISABLED", gemInstance.count or 1)
	end
	Copy(skillText)
end

function SkillsTabClass:PasteSocketGroup(testInput)
	local skillText = sanitiseText(Paste() or testInput)
	if skillText then
		local newGroup = { label = "", enabled = true, gemList = { } }
		local label = skillText:match("Label: (%C+)")
		if label then
			newGroup.label = label
		end
		local slot = skillText:match("Slot: (%C+)")
		if slot then
			newGroup.slot = slot
		end
		for nameSpec, level, quality, qualityId, state, count in skillText:gmatch("([ %a']+) (%d+)/(%d+) (%a+%d?) ?(%a*) (%d+)") do
			t_insert(newGroup.gemList, {
				nameSpec = nameSpec,
				level = tonumber(level) or 20,
				quality = tonumber(quality) or 0,
				qualityId = qualityId,
				enabled = state ~= "DISABLED",
				count = tonumber(count) or 1,
				enableGlobal1 = true,
				enableGlobal2 = true
			})
		end
		if #newGroup.gemList > 0 then
			t_insert(self.socketGroupList, newGroup)
			self.controls.groupList.selIndex = #self.socketGroupList
			self.controls.groupList.selValue = newGroup
			self:SetDisplayGroup(newGroup)
			self:AddUndoState()
			self.build.buildFlag = true
		end
	end
end

-- Create the controls for editing the gem at a given index
function SkillsTabClass:CreateGemSlot(index)
	local slot = { }
	self.gemSlots[index] = slot

	-- Delete gem
	slot.delete = new("ButtonControl", nil, 0, 0, 20, 20, "x", function()
		t_remove(self.displayGroup.gemList, index)
		for index2 = index, #self.displayGroup.gemList do
			-- Update the other gem slot controls
			local gemInstance = self.displayGroup.gemList[index2]
			self.gemSlots[index2].nameSpec:SetText(gemInstance.nameSpec)
			self.gemSlots[index2].level:SetText(gemInstance.level)
			self.gemSlots[index2].quality:SetText(gemInstance.quality)
			self.gemSlots[index2].qualityId.list = self:getGemAltQualityList(gemInstance.gemData)
			self.gemSlots[index2].qualityId:SelByValue(gemInstance.qualityId, "type")
			self.gemSlots[index2].enabled.state = gemInstance.enabled
			self.gemSlots[index2].enableGlobal1.state = gemInstance.enableGlobal1
			self.gemSlots[index2].enableGlobal2.state = gemInstance.enableGlobal2
			self.gemSlots[index2].count:SetText(gemInstance.count or 1)
		end
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	if index == 1 then
		slot.delete:SetAnchor("TOPLEFT", self.anchorGemSlots, "TOPLEFT", 0, 0)
	else
		local prevSlot = self.gemSlots[index-1]
		slot.delete:SetAnchor("TOPLEFT", prevSlot.delete, "BOTTOMLEFT", 0, function()
			return (prevSlot.enableGlobal1:IsShown() or prevSlot.enableGlobal2:IsShown()) and 24 or 2
		end)
	end
	slot.delete.shown = function()
		return index <= #self.displayGroup.gemList + 1 and self.displayGroup.source == nil
	end
	slot.delete.enabled = function()
		return index <= #self.displayGroup.gemList
	end
	slot.delete.tooltipText = "Remove this gem."
	self.controls["gemSlot"..index.."Delete"] = slot.delete

	-- Gem name specification
	slot.nameSpec = new("GemSelectControl", { "LEFT", slot.delete, "RIGHT" }, 2, 0, 300, 20, self, index, function(gemId, qualityId, addUndo)
		if not self.displayGroup then
			return
		end
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			if not gemId then
				return
			end
			gemInstance = {
				nameSpec = "",
				level = 1,
				quality = self.defaultGemQuality or 0,
				qualityId = "Default",
				enabled = true,
				enableGlobal1 = true,
				enableGlobal2 = true,
				count = 1,
				new = true
			}
			self.displayGroup.gemList[index] = gemInstance
			slot.level:SetText(gemInstance.level)
			slot.quality:SetText(gemInstance.quality)
			slot.qualityId:SelByValue(gemInstance.qualityId)
			slot.enabled.state = true
			slot.enableGlobal1.state = true
			slot.enableGlobal2.state = true
			slot.count:SetText(gemInstance.count)
		elseif gemId == gemInstance.gemId then
			return
		end
		gemInstance.gemId = gemId
		gemInstance.skillId = nil
		self:ProcessSocketGroup(self.displayGroup)
		-- New gems need to be constrained by ProcessGemLevel
		gemInstance.level = self:ProcessGemLevel(gemInstance.gemData)
		gemInstance.naturalMaxLevel = gemInstance.level
		-- Gem changed, update the list and default the quality id
		slot.qualityId.list = self:getGemAltQualityList(gemInstance.gemData)
		slot.qualityId:SelByValue(qualityId or "Default", "type")
		gemInstance.qualityId = qualityId or "Default"
		slot.level:SetText(gemInstance.level)
		slot.count:SetText(gemInstance.count or 1)
		if addUndo then
			self:AddUndoState()
		end
		self.build.buildFlag = true
	end, true)
	slot.nameSpec:AddToTabGroup(self.controls.groupLabel)
	self.controls["gemSlot"..index.."Name"] = slot.nameSpec

	-- Gem level
	slot.level = new("EditControl", { "LEFT", slot.nameSpec, "RIGHT" }, 2, 0, 60, 20, nil, nil, "%D", 2, function(buf)
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			gemInstance = { nameSpec = "", level = self.defaultGemLevel or 20, quality = self.defaultGemQuality or 0, qualityId = "Default", enabled = true, enableGlobal1 = true, enableGlobal2 = true, count = 1, new = true }
			self.displayGroup.gemList[index] = gemInstance
			slot.qualityId.list = self:getGemAltQualityList(gemInstance.gemData)
			slot.quality:SetText(gemInstance.quality)
			slot.qualityId:SelByValue(gemInstance.qualityId, "type")
			slot.enabled.state = true
			slot.enableGlobal1.state = true
			slot.count:SetText(gemInstance.count)
		end
		gemInstance.level = tonumber(buf) or self.displayGroup.gemList[index].naturalMaxLevel or self:ProcessGemLevel(gemInstance.gemData) or 20
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.level:AddToTabGroup(self.controls.groupLabel)
	slot.level.enabled = function()
		return index <= #self.displayGroup.gemList
	end
	self.controls["gemSlot"..index.."Level"] = slot.level

	-- Gem quality id
	slot.qualityId = new("DropDownControl",  {"LEFT",slot.level,"RIGHT"}, 2, 0, 90, 20, alternateGemQualityList, function(dropDownIndex, value)
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			gemInstance = { nameSpec = "", level = self.defaultGemLevel or 20, quality = self.defaultGemQuality or 0, qualityId = "Default", enabled = true, enableGlobal1 = true, enableGlobal2 = true, count = 1, new = true }
			self.displayGroup.gemList[index] = gemInstance
			slot.level:SetText(gemInstance.level)
			slot.enabled.state = true
			slot.enableGlobal1.state = true
			slot.count:SetText(gemInstance.count)
		end
		gemInstance.qualityId = value.type
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.qualityId.enabled = function()
		return index <= #self.displayGroup.gemList
	end
	slot.qualityId.tooltipFunc = function(tooltip)
		-- Reset the tooltip
		tooltip:Clear()
		-- Get the gem instance from the skills
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			return
		end
		local gemData = gemInstance.gemData
		-- Get the hovered quality item
		local hoveredQuality
		if not slot.qualityId.dropped then
			hoveredQuality = alternateGemQualityList[slot.qualityId.selIndex]
		else
			hoveredQuality = alternateGemQualityList[slot.qualityId.hoverSel]
		end
		-- gem data may not be initialized yet, or the quality may be nil, which happens when just floating over the dropdown
		if not gemData or not hoveredQuality then
			return
		end
		-- Function for both granted effect and secondary such as vaal
		local addQualityLines = function(qualityList, grantedEffect)
			tooltip:AddLine(18, colorCodes.GEM..grantedEffect.name)
			-- Hardcoded to use 20% quality instead of grabbing from gem, this is for consistency and so we always show something
			tooltip:AddLine(16, colorCodes.NORMAL.."At +20% Quality:")
			for k, qual in pairs(qualityList) do
				-- Do the stats one at a time because we're not guaranteed to get the descriptions in the same order we look at them here
				local stats = { }
				stats[qual[1]] = qual[2] * 20
				local descriptions = self.build.data.describeStats(stats, grantedEffect.statDescriptionScope)
				-- line may be nil if the value results in no line due to not being enough quality
				for _, line in ipairs(descriptions) do
					if line then
						-- Check if we have a handler for the mod in the gem's statMap or in the shared stat map for skills
						if grantedEffect.statMap[qual[1]] or self.build.data.skillStatMap[qual[1]] then
							tooltip:AddLine(16, colorCodes.MAGIC..line)
						else
							tooltip:AddLine(16, colorCodes.UNSUPPORTED..line)
						end
					end
				end
			end
		end
		-- Check if there is a quality of this type for the effect
		if gemData and gemData.grantedEffect.qualityStats and gemData.grantedEffect.qualityStats[hoveredQuality.type] then
			local qualityTable = gemData.grantedEffect.qualityStats[hoveredQuality.type]
			addQualityLines(qualityTable, gemData.grantedEffect)
		end
		if gemData and gemData.secondaryGrantedEffect and gemData.secondaryGrantedEffect.qualityStats and gemData.secondaryGrantedEffect.qualityStats[hoveredQuality.type] then
			local qualityTable = gemData.secondaryGrantedEffect.qualityStats[hoveredQuality.type]
			tooltip:AddSeparator(10)
			addQualityLines(qualityTable, gemData.secondaryGrantedEffect)
		end
		-- Add stat comparisons for hovered quality (based on set quality)
		if self.displayGroup.gemList[index] then
			local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator(self.build)
			if calcFunc then
				local tempQual = self.displayGroup.gemList[index].qualityId
				self.displayGroup.gemList[index].qualityId = hoveredQuality.type
				self:ProcessSocketGroup(self.displayGroup)
				local storedGlobalCacheDPSView = GlobalCache.useFullDPS
				GlobalCache.useFullDPS = GlobalCache.numActiveSkillInFullDPS > 0
				local output = calcFunc({}, {})
				GlobalCache.useFullDPS = storedGlobalCacheDPSView
				self.displayGroup.gemList[index].qualityId = tempQual
				tooltip:AddSeparator(10)
				self.build:AddStatComparesToTooltip(tooltip, calcBase, output, "^7Switching to this quality variant will give you:")
			end
		end
	end
	self.controls["gemSlot"..index.."QualityId"] = slot.qualityId

	-- Gem quality
	slot.quality = new("EditControl", {"LEFT",slot.qualityId,"RIGHT"}, 2, 0, 60, 20, nil, nil, "%D", 2, function(buf)
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			gemInstance = { nameSpec = "", level = self.defaultGemLevel or 20, quality = self.defaultGemQuality or 0, qualityId = "Default", enabled = true, enableGlobal1 = true, enableGlobal2 = true, count = 1, new = true }
			self.displayGroup.gemList[index] = gemInstance
			slot.level:SetText(gemInstance.level)
			slot.enabled.state = true
			slot.enableGlobal1.state = true
			slot.count:SetText(gemInstance.count)
		end
		gemInstance.quality = tonumber(buf) or self.defaultGemQuality or 0
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.quality.tooltipFunc = function(tooltip)
		if tooltip:CheckForUpdate(self.build.outputRevision, self.displayGroup) then
			if self.displayGroup.gemList[index] then
				local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator(self.build)
				if calcFunc then
					local storedQuality = self.displayGroup.gemList[index].quality
					self.displayGroup.gemList[index].quality = 20
					local storedGlobalCacheDPSView = GlobalCache.useFullDPS
					GlobalCache.useFullDPS = GlobalCache.numActiveSkillInFullDPS > 0
					local output = calcFunc({}, {})
					GlobalCache.useFullDPS = storedGlobalCacheDPSView
					self.displayGroup.gemList[index].quality = storedQuality
					self.build:AddStatComparesToTooltip(tooltip, calcBase, output, "^7Setting to 20 quality will give you:")
				end
			end
		end
	end
	slot.quality:AddToTabGroup(self.controls.groupLabel)
	slot.quality.enabled = function()
		return index <= #self.displayGroup.gemList
	end
	self.controls["gemSlot"..index.."Quality"] = slot.quality

	-- Enable gem
	slot.enabled = new("CheckBoxControl", {"LEFT",slot.quality,"RIGHT"}, 18, 0, 20, nil, function(state)
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			gemInstance = { nameSpec = "", level = self.defaultGemLevel or 20, quality = self.defaultGemQuality or 0, qualityId = "Default", enabled = true, enableGlobal1 = true, enableGlobal2 = true, count = 1, new = true }
			self.displayGroup.gemList[index] = gemInstance
			slot.level:SetText(gemInstance.level)
			slot.quality:SetText(gemInstance.quality)
			slot.qualityId.list = self:getGemAltQualityList(gemInstance.gemData)
			slot.qualityId:SelByValue(gemInstance.qualityId, "type")
			slot.count:SetText(gemInstance.count)
		end
		if not gemInstance.gemData.vaalGem then
			slot.enableGlobal1.state = true
			gemInstance.enableGlobal1 = true
			slot.enableGlobal2.state = true
			gemInstance.enableGlobal2 = true
		end
		gemInstance.enabled = state
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.enabled.tooltipFunc = function(tooltip)
		if tooltip:CheckForUpdate(self.build.outputRevision, self.displayGroup) then
			if self.displayGroup.gemList[index] then
				local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator(self.build)
				if calcFunc then
					self.displayGroup.gemList[index].enabled = not self.displayGroup.gemList[index].enabled
					local storedGlobalCacheDPSView = GlobalCache.useFullDPS
					GlobalCache.useFullDPS = GlobalCache.numActiveSkillInFullDPS > 0
					local output = calcFunc({}, {})
					GlobalCache.useFullDPS = storedGlobalCacheDPSView
					self.displayGroup.gemList[index].enabled = not self.displayGroup.gemList[index].enabled
					self.build:AddStatComparesToTooltip(tooltip, calcBase, output, self.displayGroup.gemList[index].enabled and "^7Disabling this gem will give you:" or "^7Enabling this gem will give you:")
				end
			end
		end
	end
	slot.enabled.enabled = function()
		return index <= #self.displayGroup.gemList
	end
	self.controls["gemSlot"..index.."Enable"] = slot.enabled

	-- Count gem
	slot.count = new("EditControl", {"LEFT",slot.enabled,"RIGHT"}, 18, 0, 60, 20, nil, nil, "%D", 2, function(buf)
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			gemInstance = { nameSpec = "", level = self.defaultGemLevel or 20, quality = self.defaultGemQuality or 0, qualityId = "Default", enabled = true, enableGlobal1 = true, count = 1, new = true }
			self.displayGroup.gemList[index] = gemInstance
			slot.level:SetText(gemInstance.level)
			slot.qualityId.list = self:getGemAltQualityList(gemInstance.gemData)
			slot.quality:SetText(gemInstance.quality)
			slot.qualityId:SelByValue(gemInstance.qualityId, "type")
			slot.enabled.state = true
			slot.enableGlobal1.state = true
		end
		gemInstance.count = tonumber(buf) or 1
		slot.count.buf = tostring(gemInstance.count)
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.count.shown = function()
		local gemInstance = self.displayGroup and self.displayGroup.gemList[index]
		if gemInstance then
			local grantedEffectList = gemInstance.gemData and gemInstance.gemData.grantedEffectList or { gemInstance.grantedEffect }
			for index, grantedEffect in ipairs(grantedEffectList) do
				if not grantedEffect.support and not grantedEffect.unsupported and (not grantedEffect.hasGlobalEffect or gemInstance["enableGlobal"..index]) then
					return true
				end
			end
		end
		return false
	end
	slot.count.tooltipFunc = function(tooltip)
		if tooltip:CheckForUpdate(self.build.outputRevision, self.displayGroup) then
			tooltip:AddLine(16, "^8Note: `count` integer value scales the DPS of associated skill by a scalar.")
			tooltip:AddLine(16, "^8To be used with totems, minions, shot-gunning of projectiles (e.g., VD, magma-orbs),")
			tooltip:AddLine(16, "^8multi-hit projectiles (e.g. ball-lightning), traps, mines.")
		end
	end
	slot.count.enabled = function()
		return index <= #self.displayGroup.gemList
	end
	self.controls["gemSlot"..index.."Count"] = slot.count

	-- Parser/calculator error message
	slot.errMsg = new("LabelControl", {"LEFT",slot.count,"RIGHT"}, 2, 2, 0, 16, function()
		local gemInstance = self.displayGroup and self.displayGroup.gemList[index]
		return "^1"..(gemInstance and gemInstance.errMsg or "")
	end)
	self.controls["gemSlot"..index.."ErrMsg"] = slot.errMsg

	-- Enable global-effect skill 1
	slot.enableGlobal1 = new("CheckBoxControl", {"TOPLEFT",slot.delete,"BOTTOMLEFT"}, 0, 2, 20, "", function(state)
		local gemInstance = self.displayGroup.gemList[index]
		gemInstance.enableGlobal1 = state
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.enableGlobal1.shown = function()
		local gemInstance = self.displayGroup and self.displayGroup.gemList[index]
		return gemInstance and gemInstance.gemData and gemInstance.gemData.vaalGem and gemInstance.gemData.grantedEffectList[1] and not gemInstance.gemData.grantedEffectList[1].support
	end
	slot.enableGlobal1.x = function()
		return self:IsShown() and (DrawStringWidth(16, "VAR", slot.enableGlobal1:GetProperty("label")) + 5) or 0
	end
	slot.enableGlobal1.label = function()
		return "Enable "..self.displayGroup.gemList[index].gemData.grantedEffectList[1].name..":"
	end
	self.controls["gemSlot"..index.."EnableGlobal1"] = slot.enableGlobal1

	-- Enable global-effect skill 2
	slot.enableGlobal2 = new("CheckBoxControl", {"LEFT",slot.enableGlobal1,"RIGHT",true}, 0, 0, 20, "", function(state)
		local gemInstance = self.displayGroup.gemList[index]
		gemInstance.enableGlobal2 = state
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.enableGlobal2.shown = function()
		local gemInstance = self.displayGroup and self.displayGroup.gemList[index]
		return gemInstance and gemInstance.gemData and gemInstance.gemData.vaalGem and gemInstance.gemData.grantedEffectList[2] and not gemInstance.gemData.grantedEffectList[2].support
	end
	slot.enableGlobal2.x = function()
		return self:IsShown() and (DrawStringWidth(16, "VAR", slot.enableGlobal2:GetProperty("label")) + 12) or 0
	end
	slot.enableGlobal2.label = function()
		return "Enable "..self.displayGroup.gemList[index].gemData.grantedEffectList[2].name..":"
	end
	self.controls["gemSlot"..index.."EnableGlobal2"] = slot.enableGlobal2
end

function SkillsTabClass:getGemAltQualityList(gemData)
	local altQualList = { }

	for indx, entry in ipairs(alternateGemQualityList) do
		if gemData and (gemData.grantedEffect.qualityStats and gemData.grantedEffect.qualityStats[entry.type] or (gemData.secondaryGrantedEffect and gemData.secondaryGrantedEffect.qualityStats and gemData.secondaryGrantedEffect.qualityStats[entry.type])) then
			t_insert(altQualList, entry)
		end
	end
	return #altQualList > 0 and altQualList or {{ label = "Default", type = "Default" }}
end

-- Update the gem slot controls to reflect the currently displayed socket group
function SkillsTabClass:UpdateGemSlots()
	if not self.displayGroup then
		return
	end
	for slotIndex = 1, #self.displayGroup.gemList + 1 do
		if not self.gemSlots[slotIndex] then
			self:CreateGemSlot(slotIndex)
		end
		local slot = self.gemSlots[slotIndex]
		if slotIndex == #self.displayGroup.gemList + 1 then
			slot.nameSpec:SetText("")
			slot.level:SetText("")
			slot.quality:SetText("")
			slot.qualityId:SelByValue("Default", "type")
			slot.enabled.state = false
			slot.count:SetText(1)
		else
			slot.nameSpec.inactiveCol = self.displayGroup.gemList[slotIndex].color
		end
	end
end

-- Find the skill gem matching the given specification
function SkillsTabClass:FindSkillGem(nameSpec)
	-- Search for gem name using increasingly broad search patterns
	local patternList = {
		"^ "..nameSpec:gsub("%a", function(a) return "["..a:upper()..a:lower().."]" end).."$", -- Exact match (case-insensitive)
		"^"..nameSpec:gsub("%a", " %0%%l+").."$", -- Simple abbreviation ("CtF" -> "Cold to Fire")
		"^ "..nameSpec:gsub(" ",""):gsub("%l", "%%l*%0").."%l+$", -- Abbreviated words ("CldFr" -> "Cold to Fire")
		"^"..nameSpec:gsub(" ",""):gsub("%a", ".*%0"), -- Global abbreviation ("CtoF" -> "Cold to Fire")
		"^"..nameSpec:gsub(" ",""):gsub("%a", function(a) return ".*".."["..a:upper()..a:lower().."]" end), -- Case insensitive global abbreviation ("ctof" -> "Cold to Fire")
	}
	for i, pattern in ipairs(patternList) do
		local foundGemData
		for gemId, gemData in pairs(self.build.data.gems) do
			if (" "..gemData.name):match(pattern) then
				if foundGemData then
					return "Ambiguous gem name '" .. nameSpec .. "': matches '" .. foundGemData.name .. "', '" .. gemData.name .. "'"
				end
				foundGemData = gemData
			end
		end
		if foundGemData then
			return nil, foundGemData
		end
	end
	return "Unrecognised gem name '" .. nameSpec .. "'"
end

function SkillsTabClass:ProcessGemLevel(gemData)
	local grantedEffect = gemData.grantedEffect
	local naturalMaxLevel = gemData.naturalMaxLevel
	if self.defaultGemLevel == "awakenedMaximum" then
		return naturalMaxLevel + 1
	elseif self.defaultGemLevel == "corruptedMaximum" then
		if grantedEffect.plusVersionOf then
			return naturalMaxLevel
		else
			return naturalMaxLevel + 1
		end
	elseif self.defaultGemLevel == "normalMaximum" then
		return naturalMaxLevel
	else -- self.defaultGemLevel == "characterLevel"
		local maxGemLevel = naturalMaxLevel
		if not grantedEffect.levels[maxGemLevel] then
			maxGemLevel = #grantedEffect.levels
		end
		local characterLevel = self.build and self.build.characterLevel or 1
		for gemLevel = maxGemLevel, 1, -1 do
			if grantedEffect.levels[gemLevel].levelRequirement <= characterLevel then
				return gemLevel
			end
		end
		return 1
	end
end

-- Processes the given socket group, filling in information that will be used for display or calculations
function SkillsTabClass:ProcessSocketGroup(socketGroup)
	-- Loop through the skill gem list
	local data = self.build.data
	for _, gemInstance in ipairs(socketGroup.gemList) do
		gemInstance.color = "^8"
		gemInstance.nameSpec = gemInstance.nameSpec or ""
		local prevDefaultLevel = gemInstance.gemData and gemInstance.gemData.naturalMaxLevel or (gemInstance.new and 20)
		gemInstance.gemData, gemInstance.grantedEffect = nil
		if gemInstance.gemId then
			-- Specified by gem ID
			-- Used for skills granted by skill gems
			gemInstance.errMsg = nil
			gemInstance.gemData = data.gems[gemInstance.gemId]
			if gemInstance.gemData then
				gemInstance.nameSpec = gemInstance.gemData.name
				gemInstance.skillId = gemInstance.gemData.grantedEffectId
			end
		elseif gemInstance.skillId then
			-- Specified by skill ID
			-- Used for skills granted by items
			gemInstance.errMsg = nil
			local gemId = data.gemForSkill[gemInstance.skillId]
			if gemId then
				gemInstance.gemData = data.gems[gemId]
			else
				gemInstance.grantedEffect = data.skills[gemInstance.skillId]
			end
			if gemInstance.triggered then
				if gemInstance.grantedEffect.levels[gemInstance.level] then
					gemInstance.grantedEffect.levels[gemInstance.level].cost = {}
				end
			end
		elseif gemInstance.nameSpec:match("%S") then
			-- Specified by gem/skill name, try to match it
			-- Used to migrate pre-1.4.20 builds
			gemInstance.errMsg, gemInstance.gemData = self:FindSkillGem(gemInstance.nameSpec)
			gemInstance.gemId = gemInstance.gemData and gemInstance.gemData.id
			gemInstance.skillId = gemInstance.gemData and gemInstance.gemData.grantedEffectId
			if gemInstance.gemData then
				gemInstance.nameSpec = gemInstance.gemData.name
			end
		else
			gemInstance.errMsg, gemInstance.gemData, gemInstance.skillId = nil
		end
		if gemInstance.gemData and gemInstance.gemData.grantedEffect.unsupported then
			gemInstance.errMsg = gemInstance.nameSpec .. " is not supported yet"
			gemInstance.gemData = nil
		end
		if gemInstance.gemData or gemInstance.grantedEffect then
			gemInstance.new = nil
			local grantedEffect = gemInstance.grantedEffect or gemInstance.gemData.grantedEffect
			if grantedEffect.color == 1 then
				gemInstance.color = colorCodes.STRENGTH
			elseif grantedEffect.color == 2 then
				gemInstance.color = colorCodes.DEXTERITY
			elseif grantedEffect.color == 3 then
				gemInstance.color = colorCodes.INTELLIGENCE
			else
				gemInstance.color = colorCodes.NORMAL
			end
			if prevDefaultLevel and gemInstance.gemData and gemInstance.gemData.naturalMaxLevel ~= prevDefaultLevel then
				gemInstance.level = gemInstance.gemData.naturalMaxLevel
				gemInstance.naturalMaxLevel = gemInstance.level
			end
			calcLib.validateGemLevel(gemInstance)
			if gemInstance.gemData then
				gemInstance.reqLevel = grantedEffect.levels[gemInstance.level].levelRequirement
				gemInstance.reqStr = calcLib.getGemStatRequirement(gemInstance.reqLevel, grantedEffect.support, gemInstance.gemData.reqStr)
				gemInstance.reqDex = calcLib.getGemStatRequirement(gemInstance.reqLevel, grantedEffect.support, gemInstance.gemData.reqDex)
				gemInstance.reqInt = calcLib.getGemStatRequirement(gemInstance.reqLevel, grantedEffect.support, gemInstance.gemData.reqInt)
			end
		end
	end
end

-- Set the skill to be displayed/edited
function SkillsTabClass:SetDisplayGroup(socketGroup)
	self.displayGroup = socketGroup
	if socketGroup then
		self:ProcessSocketGroup(socketGroup)

		-- Update the main controls
		self.controls.groupLabel:SetText(socketGroup.label)
		self.controls.groupSlot:SelByValue(socketGroup.slot, "slotName")
		self.controls.groupEnabled.state = socketGroup.enabled
		self.controls.includeInFullDPS.state = socketGroup.includeInFullDPS and socketGroup.enabled
		self.controls.groupCount:SetText(socketGroup.groupCount or 1)

		-- Update the gem slot controls
		self:UpdateGemSlots()
		for index, gemInstance in pairs(socketGroup.gemList) do
			self.gemSlots[index].nameSpec:SetText(gemInstance.nameSpec)
			self.gemSlots[index].level:SetText(gemInstance.level)
			self.gemSlots[index].quality:SetText(gemInstance.quality)
			self.gemSlots[index].qualityId.list = self:getGemAltQualityList(gemInstance.gemData)
			self.gemSlots[index].qualityId:SelByValue(gemInstance.qualityId, "type")
			self.gemSlots[index].enabled.state = gemInstance.enabled
			self.gemSlots[index].enableGlobal1.state = gemInstance.enableGlobal1
			self.gemSlots[index].enableGlobal2.state = gemInstance.enableGlobal2
			self.gemSlots[index].count:SetText(gemInstance.count or 1)
		end
	end
end

function SkillsTabClass:AddSocketGroupTooltip(tooltip, socketGroup)
	if socketGroup.explodeSources then
		for _, source in ipairs(socketGroup.explodeSources) do
			tooltip:AddLine(18, "^7Source: " .. colorCodes[source.rarity or "NORMAL"] .. (source.name or source.dn or "???"))
		end
		return
	end
	if socketGroup.enabled and not socketGroup.slotEnabled then
		tooltip:AddLine(16, "^7Note: this group is disabled because it is socketed in the inactive weapon set.")
	end
	local sourceSingle = socketGroup.sourceItem or socketGroup.sourceNode
	if sourceSingle then
		tooltip:AddLine(18, "^7Source: " .. colorCodes[sourceSingle.rarity or "NORMAL"] .. sourceSingle.name)
		tooltip:AddSeparator(10)
	end
	local gemShown = { }
	for index, activeSkill in ipairs(socketGroup.displaySkillList) do
		if index > 1 then
			tooltip:AddSeparator(10)
		end
		tooltip:AddLine(16, "^7Active Skill #"..index..":")
		for _, skillEffect in ipairs(activeSkill.effectList) do
			tooltip:AddLine(20, string.format("%s%s ^7%d%s/%d%s",
				data.skillColorMap[skillEffect.grantedEffect.color],
				skillEffect.grantedEffect.name,
				skillEffect.srcInstance and skillEffect.srcInstance.level or skillEffect.level,
				(skillEffect.srcInstance and skillEffect.level > skillEffect.srcInstance.level) and colorCodes.MAGIC.."+"..(skillEffect.level - skillEffect.srcInstance.level).."^7" or "",
				skillEffect.srcInstance and skillEffect.srcInstance.quality or skillEffect.quality,
				(skillEffect.srcInstance and skillEffect.quality > skillEffect.srcInstance.quality) and colorCodes.MAGIC.."+"..(skillEffect.quality - skillEffect.srcInstance.quality).."^7" or ""
			))
			if skillEffect.srcInstance then
				gemShown[skillEffect.srcInstance] = true
			end
		end
		if activeSkill.minion then
			tooltip:AddSeparator(10)
			tooltip:AddLine(16, "^7Active Skill #" .. index .. "'s Main Minion Skill:")
			local activeEffect = activeSkill.minion.mainSkill.effectList[1]
			tooltip:AddLine(20, string.format("%s%s ^7%d%s/%d%s",
				data.skillColorMap[activeEffect.grantedEffect.color],
				activeEffect.grantedEffect.name,
				activeEffect.srcInstance and activeEffect.srcInstance.level or activeEffect.level,
				(activeEffect.srcInstance and activeEffect.level > activeEffect.srcInstance.level) and colorCodes.MAGIC .. "+" .. (activeEffect.level - activeEffect.srcInstance.level) .. "^7" or "",
				activeEffect.srcInstance and activeEffect.srcInstance.quality or activeEffect.quality,
				(activeEffect.srcInstance and activeEffect.quality > activeEffect.srcInstance.quality) and colorCodes.MAGIC .. "+" .. (activeEffect.quality - activeEffect.srcInstance.quality) .. "^7" or ""
			))
			if activeEffect.srcInstance then
				gemShown[activeEffect.srcInstance] = true
			end
		end
	end
	local showOtherHeader = true
	for _, gemInstance in ipairs(socketGroup.displayGemList or socketGroup.gemList) do
		if not gemShown[gemInstance] then
			if showOtherHeader then
				showOtherHeader = false
				tooltip:AddSeparator(10)
				tooltip:AddLine(16, "^7Inactive Gems:")
			end
			local reason = ""
			local displayEffect = gemInstance.displayEffect or gemInstance
			local grantedEffect = gemInstance.gemData and gemInstance.gemData.grantedEffect or gemInstance.grantedEffect
			if not grantedEffect then
				reason = "(Unsupported)"
			elseif not gemInstance.enabled then
				reason = "(Disabled)"
			elseif not socketGroup.enabled or not socketGroup.slotEnabled then
			elseif grantedEffect.support then
				if displayEffect.superseded then
					reason = "(Superseded)"
				elseif (not displayEffect.isSupporting or not next(displayEffect.isSupporting)) and #socketGroup.displaySkillList > 0 then
					reason = "(Cannot apply to any of the active skills)"
				end
			end
			tooltip:AddLine(20, string.format("%s%s ^7%d%s/%d%s %s",
				gemInstance.color,
				(gemInstance.grantedEffect and gemInstance.grantedEffect.name) or (gemInstance.gemData and gemInstance.gemData.name) or gemInstance.nameSpec,
				displayEffect.srcInstance and displayEffect.srcInstance.level or displayEffect.level,
				displayEffect.level > gemInstance.level and colorCodes.MAGIC .. "+" .. (displayEffect.level - gemInstance.level) .. "^7" or "",
				displayEffect.srcInstance and displayEffect.srcInstance.quality or displayEffect.quality,
				displayEffect.quality > gemInstance.quality and colorCodes.MAGIC .. "+" .. (displayEffect.quality - gemInstance.quality) .. "^7" or "",
				reason
			))
		end
	end
end

function SkillsTabClass:CreateUndoState()
	local state = { }
	state.activeSkillSetId = self.activeSkillSetId
	state.skillSets = { }
	for skillSetIndex, skillSet in pairs(self.skillSets) do
		local newSkillSet = copyTable(skillSet, true)
		newSkillSet.socketGroupList = { }
		for socketGroupIndex, socketGroup in pairs(skillSet.socketGroupList) do
			local newGroup = copyTable(socketGroup, true)
			newGroup.gemList = { }
			for gemIndex, gem in pairs(socketGroup.gemList) do
				newGroup.gemList[gemIndex] = copyTable(gem, true)
			end
			newSkillSet.socketGroupList[socketGroupIndex] = newGroup
		end
		state.skillSets[skillSetIndex] = newSkillSet
	end
	state.skillSetOrderList = copyTable(self.skillSetOrderList)
	-- Save active socket group for both skillsTab and calcsTab to UndoState
	state.activeSocketGroup = self.build.mainSocketGroup
	state.activeSocketGroup2 = self.build.calcsTab.input.skill_number
	return state
end

function SkillsTabClass:RestoreUndoState(state)
	local displayId = isValueInArray(self.socketGroupList, self.displayGroup)
	wipeTable(self.skillSets)
	for k, v in pairs(state.skillSets) do
		self.skillSets[k] = v
	end
	wipeTable(self.skillSetOrderList)
	for k, v in ipairs(state.skillSetOrderList) do
		self.skillSetOrderList[k] = v
	end
	self:SetActiveSkillSet(state.activeSkillSetId)
	self:SetDisplayGroup(displayId and self.socketGroupList[displayId])
	if self.controls.groupList.selValue then
		self.controls.groupList.selValue = self.socketGroupList[self.controls.groupList.selIndex]
	end
	-- Load active socket group for both skillsTab and calcsTab from UndoState
	self.build.mainSocketGroup = state.activeSocketGroup
	self.build.calcsTab.input.skill_number = state.activeSocketGroup2
end

-- Opens the skill set manager
function SkillsTabClass:OpenSkillSetManagePopup()
	main:OpenPopup(370, 290, "Manage Skill Sets", {
		new("SkillSetListControl", nil, 0, 50, 350, 200, self),
		new("ButtonControl", nil, 0, 260, 90, 20, "Done", function()
			main:ClosePopup()
		end),
	})
end

-- Creates a new skill set
function SkillsTabClass:NewSkillSet(skillSetId)
	local skillSet = { id = skillSetId, socketGroupList = {} }
	if not skillSetId then
		skillSet.id = 1
		while self.skillSets[skillSet.id] do
			skillSet.id = skillSet.id + 1
		end
	end
	self.skillSets[skillSet.id] = skillSet
	return skillSet
end

-- Changes the active skill set
function SkillsTabClass:SetActiveSkillSet(skillSetId)
	-- Initialize skill sets if needed
	if not self.skillSetOrderList[1] then
		self.skillSetOrderList[1] = 1
		self:NewSkillSet(1)
	end

	if not skillSetId then
		skillSetId = self.activeSkillSetId
	end

	if not self.skillSets[skillSetId] then
		skillSetId = self.skillSetOrderList[1]
	end

	self.socketGroupList = self.skillSets[skillSetId].socketGroupList
	self.controls.groupList.list = self.socketGroupList
	self.activeSkillSetId = skillSetId
	self.build.buildFlag = true
end
