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

local showSupportGemTypeList = {
	{ label = "All", show = "ALL" },
	{ label = "Non-Awakened", show = "NORMAL" },
	{ label = "Awakened", show = "AWAKENED" },
}

local sortGemTypeList ={
	{label = "Combined DPS", type = "CombinedDPS"},
	{label = "Total DPS", type = "TotalDPS"},
	{label = "Average Hit", type = "AverageDamage"},
	{label = "DoT DPS", type = "TotalDot"},
	{label = "Bleed DPS", type = "BleedDPS"},
	{label = "Ignite DPS", type = "IgniteDPS"},
	{label = "Poison DPS", type = "TotalPoisonDPS"},
}

local alternateGemQualityList ={
	{label = "Default", type = "Default"},
	{label = "Anomalous", type = "Alternate1"},
	{label = "Divergent", type = "Alternate2"},
	{label = "Phantasmal", type = "Alternate3"},
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

	-- Socket group list
	self.controls.groupList = new("SkillListControl", {"TOPLEFT",self,"TOPLEFT"}, 20, 24, 360, 300, self)
	self.controls.groupTip = new("LabelControl", {"TOPLEFT",self.controls.groupList,"BOTTOMLEFT"}, 0, 8, 0, 14, "^7Tip: You can copy/paste socket groups using Ctrl+C and Ctrl+V.")

	-- Gem options
	local optionInputsX = 204
	self.controls.optionSection = new("SectionControl", {"TOPLEFT",self.controls.groupList,"BOTTOMLEFT"}, 0, 50, 374, 154, "Gem Options")
	self.controls.sortGemsByDPS = new("CheckBoxControl", {"TOPLEFT",self.controls.groupList,"BOTTOMLEFT"}, optionInputsX, 70, 20, "Sort gems by DPS:", function(state)
		self.sortGemsByDPS = state
	end)
	self.controls.sortGemsByDPS.state = true
	self.controls.sortGemsByDPSFieldControl = new("DropDownControl", {"LEFT", self.controls.sortGemsByDPS, "RIGHT"}, 10, 0, 120, 20, sortGemTypeList, function(index, value)
		self.sortGemsByDPSField = value.type
	end)
	self.controls.defaultLevel = new("EditControl", {"TOPLEFT",self.controls.groupList,"BOTTOMLEFT"}, optionInputsX, 94, 60, 20, nil, nil, "%D", 2, function(buf)
		self.defaultGemLevel = m_max(m_min(tonumber(buf) or 20, 21), 1)
	end)
	self.controls.defaultLevelLabel = new("LabelControl", {"RIGHT",self.controls.defaultLevel,"LEFT"}, -4, 0, 0, 16, "^7Default gem level:")
	self.controls.defaultQuality = new("EditControl", {"TOPLEFT",self.controls.groupList,"BOTTOMLEFT"}, optionInputsX, 118, 60, 20, nil, nil, "%D", 2, function(buf)
		self.defaultGemQuality = m_min(tonumber(buf) or 0, 23)
	end)
	self.controls.defaultQualityLabel = new("LabelControl", {"RIGHT",self.controls.defaultQuality,"LEFT"}, -4, 0, 0, 16, "^7Default gem quality:")
	self.controls.showSupportGemTypes = new("DropDownControl", {"TOPLEFT",self.controls.groupList,"BOTTOMLEFT"}, optionInputsX, 142, 120, 20, showSupportGemTypeList, function(index, value)
		self.showSupportGemTypes = value.show
	end)
	self.controls.showSupportGemTypesLabel = new("LabelControl", {"RIGHT",self.controls.showSupportGemTypes,"LEFT"}, -4, 0, 0, 16, "^7Show support gems:")
	self.controls.showAltQualityGems = new("CheckBoxControl", {"TOPLEFT",self.controls.groupList,"BOTTOMLEFT"}, optionInputsX, 166, 20, "^7Show gem quality variants:", function(state)
		self.showAltQualityGems = state
	end)

	-- Socket group details
	self.anchorGroupDetail = new("Control", {"TOPLEFT",self.controls.groupList,"TOPRIGHT"}, 20, 0, 0, 0)
	self.anchorGroupDetail.shown = function()
		return self.displayGroup ~= nil
	end
	self.controls.groupLabel = new("EditControl", {"TOPLEFT",self.anchorGroupDetail,"TOPLEFT"}, 0, 0, 380, 20, nil, "Label", "%c", 50, function(buf)
		self.displayGroup.label = buf
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.groupSlotLabel = new("LabelControl", {"TOPLEFT",self.anchorGroupDetail,"TOPLEFT"}, 0, 30, 0, 16, "^7Socketed in:")
	self.controls.groupSlot = new("DropDownControl", {"TOPLEFT",self.anchorGroupDetail,"TOPLEFT"}, 85, 28, 130, 20, groupSlotDropList, function(index, value)
		self.displayGroup.slot = value.slotName
		self:CheckForItemActive()
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
	self.controls.groupEnabled = new("CheckBoxControl", {"LEFT",self.controls.groupSlot,"RIGHT"}, 70, 0, 20, "Enabled:", function(state)
		self.displayGroup.enabled = state
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.sourceNote = new("LabelControl", {"TOPLEFT",self.controls.groupSlotLabel,"TOPLEFT"}, 0, 30, 0, 16)
	self.controls.sourceNote.shown = function()
		return self.displayGroup.source ~= nil
	end
	self.controls.sourceNote.label = function()
		local source = self.displayGroup.sourceItem or (self.displayGroup.sourceNode and { rarity = "NORMAL", name = self.displayGroup.sourceNode.name }) or { rarity = "NORMAL", name = "?" }
		local sourceName = colorCodes[source.rarity]..source.name.."^7"
		local activeGem = self.displayGroup.gemList[1]
		local label = [[^7This is a special group created for the ']]..activeGem.color..(activeGem.grantedEffect and activeGem.grantedEffect.name or activeGem.nameSpec)..[[^7' skill,
which is being provided by ']]..sourceName..[['.
You cannot delete this group, but it will disappear if you ]]..(self.displayGroup.sourceNode and [[un-allocate the node.]] or [[un-equip the item.]])
		if not self.displayGroup.noSupports then
			label = label .. "\n\n" .. [[You cannot add support gems to this group, but support gems in
any other group socketed into ']]..sourceName..[['
will automatically apply to the skill.]]
		end
		return label
	end

	-- Skill gem slots
	self.anchorGemSlots = new("Control", {"TOPLEFT",self.anchorGroupDetail,"TOPLEFT"}, 0, 28 + 28 + 16, 0, 0)
	self.gemSlots = { }
	self:CreateGemSlot(1)
	self.controls.gemNameHeader = new("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].nameSpec,"TOPLEFT"}, 0, -2, 0, 16, "^7Gem name:")
	self.controls.gemLevelHeader = new("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].level,"TOPLEFT"}, 0, -2, 0, 16, "^7Level:")
	self.controls.gemQualityIdHeader = new("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].qualityId,"TOPLEFT"}, 0, -2, 0, 16, "^7Variant:")
	self.controls.gemQualityHeader = new("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].quality,"TOPLEFT"}, 0, -2, 0, 16, "^7Quality:")
	self.controls.gemEnableHeader = new("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].enabled,"TOPLEFT"}, -16, -2, 0, 16, "^7Enabled:")
end)

-- parse real gem name and quality by ommiting the first word if alt qual is set
function SkillsTabClass:GetBaseNameAndQuality(gemTypeLine, quality)
	-- if quality is default or nil check the gem type line if we have alt qual by comparing to the existing list
	if gemTypeLine and (quality == nil or quality == '' or quality == 'Default') then
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
    return gemTypeLine, quality or 'Default'
end

function SkillsTabClass:Load(xml, fileName)
	self.defaultGemLevel = tonumber(xml.attrib.defaultGemLevel)
	self.defaultGemQuality = tonumber(xml.attrib.defaultGemQuality)
	self.controls.defaultLevel:SetText(self.defaultGemLevel or "")
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
			local socketGroup = { }
			socketGroup.enabled = node.attrib.active == "true" or node.attrib.enabled == "true"
			socketGroup.label = node.attrib.label
			socketGroup.slot = node.attrib.slot
			socketGroup.source = node.attrib.source
			socketGroup.mainActiveSkill = tonumber(node.attrib.mainActiveSkill) or 1
			socketGroup.mainActiveSkillCalcs = tonumber(node.attrib.mainActiveSkillCalcs) or 1
			socketGroup.gemList = { }
			for _, child in ipairs(node) do
				local gemInstance = { }
				gemInstance.nameSpec = child.attrib.nameSpec or ""
				if child.attrib.gemId then
					local gemData = self.build.data.gems[child.attrib.gemId]
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
			t_insert(self.socketGroupList, socketGroup)
		end
	end
	self:SetDisplayGroup(self.socketGroupList[1])
	self:ResetUndo()
end

function SkillsTabClass:Save(xml)
	xml.attrib = {
		defaultGemLevel = tostring(self.defaultGemLevel),
		defaultGemQuality = tostring(self.defaultGemQuality),
		sortGemsByDPS = tostring(self.sortGemsByDPS),
		showSupportGemTypes = self.showSupportGemTypes,
		sortGemsByDPSField = self.sortGemsByDPSField,
		showAltQualityGems = tostring(self.showAltQualityGems)
	}
	for _, socketGroup in ipairs(self.socketGroupList) do
		local node = { elem = "Skill", attrib = {
			enabled = tostring(socketGroup.enabled),
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
				gemId = gemInstance.gemId,
				level = tostring(gemInstance.level),
				quality = tostring(gemInstance.quality),
				qualityId = gemInstance.qualityId,
				enabled = tostring(gemInstance.enabled),
				enableGlobal1 = tostring(gemInstance.enableGlobal1),
				enableGlobal2 = tostring(gemInstance.enableGlobal2),
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
		t_insert(xml, node)
	end
	self.modFlag = false
end

function SkillsTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	for id, event in ipairs(inputEvents) do
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

	main:DrawBackground(viewPort)

	self:UpdateGemSlots()

	self:DrawControls(viewPort)
end

function SkillsTabClass:CopySocketGroup(socketGroup)
	local skillText = ""
	if socketGroup.label:match("%S") then
		skillText = skillText .. "Label: "..socketGroup.label.."\r\n"
	end
	if socketGroup.slot then
		skillText = skillText .. "Slot: "..socketGroup.slot.."\r\n"
	end
	for _, gemInstance in ipairs(socketGroup.gemList) do
		skillText = skillText .. string.format("%s %d/%d %s %s\r\n", gemInstance.nameSpec, gemInstance.level, gemInstance.quality, gemInstance.qualityId, gemInstance.enabled and "" or "DISABLED")
	end
	Copy(skillText)
end

function SkillsTabClass:PasteSocketGroup()
	local skillText = Paste()
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
		for nameSpec, level, quality, qualityId, state in skillText:gmatch("([ %a']+) (%d+)/(%d+) (%a+%d?) ?(%a*)") do
			t_insert(newGroup.gemList, { nameSpec = nameSpec, level = tonumber(level) or 20, quality = tonumber(quality) or 0, qualityId = qualityId, enabled = state ~= "DISABLED" })
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
			self.gemSlots[index2].qualityId:SelByValue(gemInstance.qualityId, "type")
			self.gemSlots[index2].enabled.state = gemInstance.enabled
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
	slot.nameSpec = new("GemSelectControl", {"LEFT",slot.delete,"RIGHT"}, 2, 0, 300, 20, self, index, function(gemId, qualityId, addUndo)
		if not self.displayGroup then
			return
		end
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			if not gemId then
				return
			end
			gemInstance = { nameSpec = "", level = self.defaultGemLevel or 20, quality = self.defaultGemQuality or 0, qualityId = "Default", enabled = true, enableGlobal1 = true, new = true }
			self.displayGroup.gemList[index] = gemInstance
			slot.level:SetText(gemInstance.level)
			slot.quality:SetText(gemInstance.quality)
			slot.qualityId:SelByValue(gemInstance.qualityId)
			slot.enabled.state = true
			slot.enableGlobal1.state = true
		elseif gemId == gemInstance.gemId then
			return
		end
		gemInstance.gemId = gemId
		gemInstance.skillId = nil
		self:ProcessSocketGroup(self.displayGroup)
		-- Gem changed, update the list and default the quality id
		slot.qualityId.list = self:getGemAltQualityList(gemInstance.gemData)
		slot.qualityId:SelByValue(qualityId or "Default", "type")
		gemInstance.qualityId = qualityId or "Default"
		slot.level:SetText(tostring(gemInstance.level))
		if addUndo then
			self:AddUndoState()
		end
		self.build.buildFlag = true
	end)
	slot.nameSpec:AddToTabGroup(self.controls.groupLabel)
	self.controls["gemSlot"..index.."Name"] = slot.nameSpec

	-- Gem level
	slot.level = new("EditControl", {"LEFT",slot.nameSpec,"RIGHT"}, 2, 0, 60, 20, nil, nil, "%D", 2, function(buf)
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			gemInstance = { nameSpec = "", level = self.defaultGemLevel or 20, quality = self.defaultGemQuality or 0, qualityId = "Default", enabled = true, enableGlobal1 = true, new = true }
			self.displayGroup.gemList[index] = gemInstance
			slot.qualityId.list = self:getGemAltQualityList(gemInstance.gemData)
			slot.quality:SetText(gemInstance.quality)
			slot.qualityId:SelByValue(gemInstance.qualityId, "type")
			slot.enabled.state = true
			slot.enableGlobal1.state = true
		end
		gemInstance.level = tonumber(buf) or self.displayGroup.gemList[index].defaultLevel or self.defaultGemLevel or 20
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
			gemInstance = { nameSpec = "", level = self.defaultGemLevel or 20, quality = self.defaultGemQuality or 0, qualityId = "Default", enabled = true, enableGlobal1 = true, new = true }
			self.displayGroup.gemList[index] = gemInstance
			slot.level:SetText(gemInstance.level)
			slot.enabled.state = true
			slot.enableGlobal1.state = true
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
		-- Only show the tooltip if the combo box is expanded; this is to prevent multiple tooltips from appearing due to mouse being over other skills' combo boxes
		if not slot.qualityId.dropped then
			return
		end
		-- Get the gem instance from the skills
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			return
		end
		local gemData = gemInstance.gemData
		-- Get the hovered quality item
		local hoveredQuality = alternateGemQualityList[slot.qualityId.hoverSel]
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
		if gemData and gemData.grantedEffect.qualityStats[hoveredQuality.type] then
			local qualityTable = gemData.grantedEffect.qualityStats[hoveredQuality.type]
			addQualityLines(qualityTable, gemData.grantedEffect)
		end
		if gemData and gemData.secondaryGrantedEffect and gemData.secondaryGrantedEffect.qualityStats[hoveredQuality.type] then
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
				local output = calcFunc()
				self.displayGroup.gemList[index].qualityId = tempQual
				tooltip:AddSeparator(10)
				self.build:AddStatComparesToTooltip(tooltip, calcBase, output, "^7Switching to this quality variant will give you:")
			end
		end
	end
	slot.qualityId:AddToTabGroup(self.controls.groupLabel)
	self.controls["gemSlot"..index.."QualityId"] = slot.qualityId

	-- Gem quality
	slot.quality = new("EditControl", {"LEFT",slot.qualityId,"RIGHT"}, 2, 0, 60, 20, nil, nil, "%D", 2, function(buf)
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			gemInstance = { nameSpec = "", level = self.defaultGemLevel or 20, quality = self.defaultGemQuality or 0, qualityId = "Default", enabled = true, enableGlobal1 = true, new = true }
			self.displayGroup.gemList[index] = gemInstance
			slot.level:SetText(gemInstance.level)
			slot.enabled.state = true
			slot.enableGlobal1.state = true
		end
		gemInstance.quality = tonumber(buf) or self.defaultGemQuality or 0
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.quality:AddToTabGroup(self.controls.groupLabel)
	slot.quality.enabled = function()
		return index <= #self.displayGroup.gemList
	end
	self.controls["gemSlot"..index.."Quality"] = slot.quality

	-- Enable gem
	slot.enabled = new("CheckBoxControl", {"LEFT",slot.quality,"RIGHT"}, 18, 0, 20, nil, function(state)
		local gemInstance = self.displayGroup.gemList[index]
		if not gemInstance then
			gemInstance = { nameSpec = "", level = self.defaultGemLevel or 20, quality = self.defaultGemQuality or 0, qualityId = "Default", enabled = true, enableGlobal1 = true, new = true }
			self.displayGroup.gemList[index] = gemInstance
			slot.level:SetText(gemInstance.level)
			slot.quality:SetText(gemInstance.quality)
			slot.qualityId.list = self:getGemAltQualityList(gemInstance.gemData)
			slot.qualityId:SelByValue(gemInstance.qualityId, "type")
			slot.enableGlobal1.state = true
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
					local output = calcFunc()
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

	-- Parser/calculator error message
	slot.errMsg = new("LabelControl", {"LEFT",slot.enabled,"RIGHT"}, 2, 2, 0, 16, function()
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
		return gemInstance and gemInstance.gemData and gemInstance.gemData.grantedEffectList[1] and gemInstance.gemData.grantedEffectList[1].hasGlobalEffect and not gemInstance.gemData.grantedEffectList[1].support
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
		return gemInstance and gemInstance.gemData and gemInstance.gemData.grantedEffectList[2] and gemInstance.gemData.grantedEffectList[2].hasGlobalEffect and not gemInstance.gemData.grantedEffectList[2].support
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
		if gemData and (gemData.grantedEffect.qualityStats[entry.type] or (gemData.secondaryGrantedEffect and gemData.secondaryGrantedEffect.qualityStats[entry.type])) then
			t_insert(altQualList, entry)
		end
	end
	return altQualList
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
					return "Ambiguous gem name '"..nameSpec.."': matches '"..foundGemData.name.."', '"..gemData.name.."'"
				end
				foundGemData = gemData
			end
		end
		if foundGemData then
			return nil, foundGemData
		end
	end
	return "Unrecognised gem name '"..nameSpec.."'"
end

-- Processes the given socket group, filling in information that will be used for display or calculations
function SkillsTabClass:ProcessSocketGroup(socketGroup)
	-- Loop through the skill gem list
	local data = self.build.data
	for _, gemInstance in ipairs(socketGroup.gemList) do
		gemInstance.color = "^8"
		gemInstance.nameSpec = gemInstance.nameSpec or ""
		local prevDefaultLevel = gemInstance.gemData and gemInstance.gemData.defaultLevel or (gemInstance.new and (self.defaultGemLevel or 20))
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
			gemInstance.errMsg = gemInstance.nameSpec.." is not supported yet"
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
			if prevDefaultLevel and gemInstance.gemData and gemInstance.gemData.defaultLevel ~= prevDefaultLevel then
				gemInstance.level = m_min(self.defaultGemLevel or gemInstance.gemData.defaultLevel, gemInstance.gemData.defaultLevel + 1)
				gemInstance.defaultLevel = gemInstance.level
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
		end
	end
end

function SkillsTabClass:AddSocketGroupTooltip(tooltip, socketGroup)
	if socketGroup.enabled and not socketGroup.slotEnabled then
		tooltip:AddLine(16, "^7Note: this group is disabled because it is socketed in the inactive weapon set.")
	end
	local source = socketGroup.sourceItem or socketGroup.sourceNode
	if source then
		tooltip:AddLine(18, "^7Source: "..colorCodes[source.rarity or "NORMAL"]..source.name)
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
				skillEffect.level,
				(skillEffect.srcInstance and skillEffect.level > skillEffect.srcInstance.level) and colorCodes.MAGIC.."+"..(skillEffect.level - skillEffect.srcInstance.level).."^7" or "",
				skillEffect.quality,
				(skillEffect.srcInstance and skillEffect.quality > skillEffect.srcInstance.quality) and colorCodes.MAGIC.."+"..(skillEffect.quality - skillEffect.srcInstance.quality).."^7" or ""
			))
			if skillEffect.srcInstance then
				gemShown[skillEffect.srcInstance] = true
			end
		end
		if activeSkill.minion then
			tooltip:AddSeparator(10)
			tooltip:AddLine(16, "^7Active Skill #"..index.."'s Main Minion Skill:")
			local activeEffect = activeSkill.minion.mainSkill.effectList[1]
			tooltip:AddLine(20, string.format("%s%s ^7%d%s/%d%s",
				data.skillColorMap[activeEffect.grantedEffect.color],
				activeEffect.grantedEffect.name,
				activeEffect.level,
				(activeEffect.srcInstance and activeEffect.level > activeEffect.srcInstance.level) and colorCodes.MAGIC.."+"..(activeEffect.level - activeEffect.srcInstance.level).."^7" or "",
				activeEffect.quality,
				(activeEffect.srcInstance and activeEffect.quality > activeEffect.srcInstance.quality) and colorCodes.MAGIC.."+"..(activeEffect.quality - activeEffect.srcInstance.quality).."^7" or ""
			))
			if activeEffect.srcInstance then
				gemShown[activeEffect.srcInstance] = true
			end
		end
	end
	local showOtherHeader = true
	for _, gemInstance in ipairs(socketGroup.gemList) do
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
				displayEffect.level,
				displayEffect.level > gemInstance.level and colorCodes.MAGIC.."+"..(displayEffect.level - gemInstance.level).."^7" or "",
				displayEffect.quality,
				displayEffect.quality > gemInstance.quality and colorCodes.MAGIC.."+"..(displayEffect.quality - gemInstance.quality).."^7" or "",
				reason
			))
		end
	end
end

function SkillsTabClass:CreateUndoState()
	local state = { }
	state.socketGroupList = { }
	for _, socketGroup in ipairs(self.socketGroupList) do
		local newGroup = copyTable(socketGroup, true)
		newGroup.gemList = { }
		for index, gemInstance in pairs(socketGroup.gemList) do
			newGroup.gemList[index] = copyTable(gemInstance, true)
		end
		t_insert(state.socketGroupList, newGroup)
	end
	return state
end

function SkillsTabClass:RestoreUndoState(state)
	local displayId = isValueInArray(self.socketGroupList, self.displayGroup)
	wipeTable(self.socketGroupList)
	for k, v in pairs(state.socketGroupList) do
		self.socketGroupList[k] = v
	end
	self:SetDisplayGroup(displayId and self.socketGroupList[displayId])
	if self.controls.groupList.selValue then
		self.controls.groupList.selValue = self.socketGroupList[self.controls.groupList.selIndex]
	end
end

function SkillsTabClass:CheckForItemActive()
	--Determine if a skill from an item is present in the named socket group
	for _, socketGroupRow in ipairs(self.socketGroupList) do
		if socketGroupRow.gemList and #socketGroupRow.gemList == 1 and socketGroupRow.gemList[1].grantedEffect and socketGroupRow.gemList[1].grantedEffect.fromItem and not socketGroupRow.gemList[1].grantedEffect.support then
			if socketGroupRow.slot == self.displayGroup.slot and socketGroupRow ~= self.displayGroup then
				self.displayGroup.gemList[1] = socketGroupRow.gemList[1]
				t_insert(self.displayGroup.displaySkillList, 1, socketGroupRow.displaySkillList[1])
			end
		end
	end
end