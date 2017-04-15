-- Path of Building
--
-- Module: Skills Tab
-- Skills tab for the current build.
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max

local SkillsTabClass = common.NewClass("SkillsTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build

	self.socketGroupList = { }

	-- Socket group list
	self.controls.groupList = common.New("SkillList", {"TOPLEFT",self,"TOPLEFT"}, 20, 24, 360, 300, self)

	-- Socket group details
	self.anchorGroupDetail = common.New("Control", {"TOPLEFT",self.controls.groupList,"TOPRIGHT"}, 20, 0, 0, 0)
	self.anchorGroupDetail.shown = function()
		return self.displayGroup ~= nil
	end
	self.controls.groupLabel = common.New("EditControl", {"TOPLEFT",self.anchorGroupDetail,"TOPLEFT"}, 0, 0, 380, 20, nil, "Label", "%c", 50, function(buf)
		self.displayGroup.label = buf
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.groupSlotLabel = common.New("LabelControl", {"TOPLEFT",self.anchorGroupDetail,"TOPLEFT"}, 0, 30, 0, 16, "^7Socketed in:")
	self.controls.groupSlot = common.New("DropDownControl", {"TOPLEFT",self.anchorGroupDetail,"TOPLEFT"}, 85, 28, 110, 20, { "None", "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2" }, function(sel, selVal)
		if sel > 1 then
			self.displayGroup.slot = selVal
		else
			self.displayGroup.slot = nil
		end
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.groupSlot.tooltipFunc = function(mode, sel, selVal)
		if mode == "OUT" or sel == 1 then
			main:AddTooltipLine(16, "Select the item in which this skill is socketed.")
			main:AddTooltipLine(16, "This will allow the skill to benefit from modifiers on the item that affect socketed gems.")
		else
			local slot = self.build.itemsTab.slots[selVal]
			local ttItem = self.build.itemsTab.list[slot.selItemId]
			if ttItem then
				self.build.itemsTab:AddItemTooltip(ttItem, slot)
				return data.colorCodes[ttItem.rarity], true
			else
				main:AddTooltipLine(16, "No item is equipped in this slot.")
			end
		end
	end
	self.controls.groupSlot.enabled = function()
		return self.displayGroup.source == nil
	end
	self.controls.groupEnabled = common.New("CheckBoxControl", {"LEFT",self.controls.groupSlot,"RIGHT"}, 70, 0, 20, "Enabled:", function(state)
		self.displayGroup.enabled = state
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.sourceNote = common.New("LabelControl", {"TOPLEFT",self.controls.groupSlotLabel,"TOPLEFT"}, 0, 30, 0, 16)
	self.controls.sourceNote.shown = function()
		return self.displayGroup.source ~= nil
	end
	self.controls.sourceNote.label = function()
		local item = self.displayGroup.sourceItem or { rarity = "NORMAL", name = "?" }
		local itemName = data.colorCodes[item.rarity]..item.name.."^7"
		local activeGem = self.displayGroup.gemList[1]
		local label = [[^7This is a special group created for the ']]..activeGem.color..activeGem.name..[[^7' skill,
which is being provided by ']]..itemName..[['.
You cannot delete this group, but it will disappear if you un-equip the item.]]
		if not self.displayGroup.noSupports then
			label = label .. "\n\n" .. [[You cannot add support gems to this group, but support gems in
any other group socketed into ']]..itemName..[['
will automatically apply to the skill.]]
		end
		return label
	end

	-- Skill gem slots
	self.gemSlots = { }
	self:CreateGemSlot(1)
	self.controls.gemNameHeader = common.New("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].nameSpec,"TOPLEFT"}, 0, -2, 0, 16, "^7Gem name:")
	self.controls.gemLevelHeader = common.New("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].level,"TOPLEFT"}, 0, -2, 0, 16, "^7Level:")
	self.controls.gemQualityHeader = common.New("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].quality,"TOPLEFT"}, 0, -2, 0, 16, "^7Quality:")
	self.controls.gemEnableHeader = common.New("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].enabled,"TOPLEFT"}, -16, -2, 0, 16, "^7Enabled:")
end)

function SkillsTabClass:Load(xml, fileName)
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
				local gem = { }
				gem.nameSpec = child.attrib.nameSpec
				gem.level = tonumber(child.attrib.level)
				gem.quality = tonumber(child.attrib.quality)
				gem.enabled = not child.attrib.enabled and true or child.attrib.enabled == "true"
				gem.skillPart = tonumber(child.attrib.skillPart)
				gem.skillPartCalcs = tonumber(child.attrib.skillPartCalcs)
				gem.skillMinion = child.attrib.skillMinion
				gem.skillMinionCalcs = child.attrib.skillMinionCalcs
				gem.skillMinionSkill = tonumber(child.attrib.skillMinionSkill)
				gem.skillMinionSkillCalcs = tonumber(child.attrib.skillMinionSkillCalcs)
				t_insert(socketGroup.gemList, gem)
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
	for _, socketGroup in ipairs(self.socketGroupList) do
		local node = { elem = "Skill", attrib = {
			enabled = tostring(socketGroup.enabled),
			label = socketGroup.label,
			slot = socketGroup.slot,
			source = socketGroup.source,
			mainActiveSkill = tostring(socketGroup.mainActiveSkill),
			mainActiveSkillCalcs = tostring(socketGroup.mainActiveSkillCalcs),
		} }
		for _, gem in ipairs(socketGroup.gemList) do
			t_insert(node, { elem = "Gem", attrib = {
				nameSpec = gem.nameSpec,
				level = tostring(gem.level),
				quality = tostring(gem.quality),
				enabled = tostring(gem.enabled),
				skillPart = gem.skillPart and tostring(gem.skillPart),
				skillPartCalcs = gem.skillPartCalcs and tostring(gem.skillPartCalcs),
				skillMinion = gem.skillMinion,
				skillMinionCalcs = gem.skillMinionCalcs,
				skillMinionSkill = gem.skillMinionSkill and tostring(gem.skillMinionSkill),
				skillMinionSkillCalcs = gem.skillMinionSkillCalcs and tostring(gem.skillMinionSkillCalcs),
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
	for _, gem in ipairs(socketGroup.gemList) do
		skillText = skillText .. string.format("%s %d/%d %s\r\n", gem.nameSpec, gem.level, gem.quality, gem.enabled and "" or "DISABLED")
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
		for nameSpec, level, quality, state in skillText:gmatch("([ %a']+) (%d+)/(%d+) ?(%a*)") do
			t_insert(newGroup.gemList, { nameSpec = nameSpec, level = tonumber(level) or 20, quality = tonumber(quality) or 0, enabled = state ~= "DISABLED" })
		end
		if #newGroup.gemList > 0 then
			t_insert(self.socketGroupList, newGroup)
			self.controls.groupList.selGroup = newGroup
			self.controls.groupList.selIndex = #self.socketGroupList
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

	-- Gem name specification
	slot.nameSpec = common.New("GemSelectControl", nil, 0, 0, 300, 20, self, index, function(buf, addUndo)
		if not self.displayGroup.gemList[index] then
			self.displayGroup.gemList[index] = { nameSpec = "", level = 20, quality = 0, enabled = true }
			slot.level:SetText("20")
			slot.quality:SetText("0")
			slot.enabled.state = true
		end
		local gem = self.displayGroup.gemList[index]
		local prevDefaultLevel
		if gem.data then
			prevDefaultLevel = (gem.data.levels[20] and 20) or (gem.data.levels[3][1] and 3) or 1
		end
		gem.nameSpec = buf
		self:ProcessSocketGroup(self.displayGroup)
		if gem.data then
			local defaultLevel = (gem.data.levels[20] and 20) or (gem.data.levels[3][1] and 3) or 1
			gem.defaultLevel = defaultLevel
			if prevDefaultLevel ~= defaultLevel then
				gem.level = defaultLevel
				slot.level:SetText(tostring(gem.level))
			end
		end
		if addUndo then
			self:AddUndoState()
		end
		self.build.buildFlag = true
	end)
	if index == 1 then
		slot.nameSpec:SetAnchor("TOPLEFT", self.anchorGroupDetail, "TOPLEFT", 0, 28 + 28 + 16)
	else
		slot.nameSpec:SetAnchor("TOPLEFT", self.gemSlots[index - 1].nameSpec, "TOPLEFT", 0, 22)
	end
	slot.nameSpec:AddToTabGroup(self.controls.groupLabel)
	slot.nameSpec.shown = function()
		return index <= #self.displayGroup.gemList + 1 and self.displayGroup.source == nil
	end
	self.controls["gemSlotName"..index] = slot.nameSpec

	-- Gem level
	slot.level = common.New("EditControl", {"LEFT",slot.nameSpec,"RIGHT"}, 2, 0, 60, 20, nil, nil, "%D", 2, function(buf)
		if not self.displayGroup.gemList[index] then
			self.displayGroup.gemList[index] = { nameSpec = "", level = 20, quality = 0, enabled = true }
			slot.quality:SetText("0")
			slot.enabled.state = true
		end
		self.displayGroup.gemList[index].level = tonumber(buf) or self.displayGroup.gemList[index].defaultLevel or 20
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.level:AddToTabGroup(self.controls.groupLabel)
	self.controls["gemSlotLevel"..index] = slot.level

	-- Gem quality
	slot.quality = common.New("EditControl", {"LEFT",slot.level,"RIGHT"}, 2, 0, 60, 20, nil, nil, "%D", 2, function(buf)
		if not self.displayGroup.gemList[index] then
			self.displayGroup.gemList[index] = { nameSpec = "", level = 20, quality = 0, enabled = true }
			slot.level:SetText("20")
			slot.enabled.state = true
		end
		self.displayGroup.gemList[index].quality = tonumber(buf) or 0
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.quality:AddToTabGroup(self.controls.groupLabel)
	self.controls["gemSlotQuality"..index] = slot.quality

	-- Enable gem
	slot.enabled = common.New("CheckBoxControl", {"LEFT",slot.quality,"RIGHT"}, 18, 0, 20, nil, function(state)
		if not self.displayGroup.gemList[index] then
			self.displayGroup.gemList[index] = { nameSpec = "", level = 20, quality = 0, enabled = true }
			slot.level:SetText("20")
			slot.quality:SetText("0")
		end
		self.displayGroup.gemList[index].enabled = state
		self:ProcessSocketGroup(self.displayGroup)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.enabled.tooltipFunc = function()
		if self.displayGroup.gemList[index] then
			local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator(self.build)
			if calcFunc then
				self.displayGroup.gemList[index].enabled = not self.displayGroup.gemList[index].enabled
				local output = calcFunc()
				self.displayGroup.gemList[index].enabled = not self.displayGroup.gemList[index].enabled
				self.build:AddStatComparesToTooltip(calcBase, output, self.displayGroup.gemList[index].enabled and "^7Disabling this gem will give you:" or "^7Enabling this gem will give you:")
			end
		end
	end
	self.controls["gemSlotEnable"..index] = slot.enabled

	-- Parser/calculator error message
	slot.errMsg = common.New("LabelControl", {"LEFT",slot.enabled,"RIGHT"}, 2, 2, 0, 16, function()
		return "^1"..(self.displayGroup.gemList[index] and self.displayGroup.gemList[index].errMsg or "")
	end)
	self.controls["gemSlotErrMsg"..index] = slot.errMsg
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
	local gemName, gemData
	for i, pattern in ipairs(patternList) do
		for name, data in pairs(data.gems) do
			if (" "..name):match(pattern) then
				if gemName then
					return "Ambiguous gem name '"..nameSpec.."': matches '"..gemName.."', '"..name.."'"
				end
				gemName = name
				gemData = data
			end
		end
		if gemName then
			if gemData.unsupported then
				return gemName.." is unsupported"
			else
				return nil, gemName, gemData
			end
		end
	end
	return "Unrecognised gem name '"..nameSpec.."'"
end

-- Processes the given socket group, filling in information that will be used for display or calculations
function SkillsTabClass:ProcessSocketGroup(socketGroup)
	-- Loop through the skill gem list
	local index = 1
	while true do
		local gem = socketGroup.gemList[index]
		if not gem then
			break
		end
		gem.color = "^8"
		if gem.nameSpec:match("%S") then
			-- Gem name has been specified, try to find the matching skill gem
			if data.gems[gem.nameSpec] then
				if data.gems[gem.nameSpec].unsupported then
					gem.errMsg = gem.nameSpec.." is not supported yet"
					gem.name = nil
					gem.data = nil
				else
					gem.errMsg = nil
					gem.name = gem.nameSpec
					gem.data = data.gems[gem.nameSpec]
				end
			elseif data.skills[gem.nameSpec] then
				gem.errMsg = nil
				gem.data = data.skills[gem.nameSpec]
				gem.name = gem.data.name
			else
				gem.errMsg, gem.name, gem.data = self:FindSkillGem(gem.nameSpec)
				if gem.name then
					gem.nameSpec = gem.name
				end
			end
			if gem.name then
				if gem.data.color == 1 then
					gem.color = data.colorCodes.STRENGTH
				elseif gem.data.color == 2 then
					gem.color = data.colorCodes.DEXTERITY
				elseif gem.data.color == 3 then
					gem.color = data.colorCodes.INTELLIGENCE
				else
					gem.color = data.colorCodes.NORMAL
				end
			end
		else
			gem.errMsg, gem.name, gem.data = nil
		end
		if gem.nameSpec:match("%S") or gem.level ~= (gem.defaultLevel or 20) or gem.quality ~= 0 or (socketGroup == self.displayGroup and self.gemSlots[index] and self.gemSlots[index].nameSpec.dropped) then
			index = index + 1
		else
			-- Empty gem, remove it
			t_remove(socketGroup.gemList, index)

			if socketGroup == self.displayGroup then
				-- Update the other gem slot controls
				for index2 = index, #socketGroup.gemList do
					local gem = socketGroup.gemList[index2]
					if not self.gemSlots[index2] then
						self:CreateGemSlot(index2)
					end
					self.gemSlots[index2].nameSpec:SetText(gem.nameSpec)
					self.gemSlots[index2].level:SetText(gem.level)
					self.gemSlots[index2].quality:SetText(gem.quality)
					self.gemSlots[index2].enabled.state = gem.enabled
				end
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
		self.controls.groupSlot:SelByValue(socketGroup.slot or "None")
		self.controls.groupEnabled.state = socketGroup.enabled

		-- Update the gem slot controls
		self:UpdateGemSlots()
		for index, gem in pairs(socketGroup.gemList) do
			self.gemSlots[index].nameSpec:SetText(gem.nameSpec)
			self.gemSlots[index].level:SetText(gem.level)
			self.gemSlots[index].quality:SetText(gem.quality)
			self.gemSlots[index].enabled.state = gem.enabled
		end
	end
end

function SkillsTabClass:CreateUndoState()
	local state = { }
	state.socketGroupList = { }
	for _, socketGroup in ipairs(self.socketGroupList) do
		local newGroup = { 
			label = socketGroup.label,
			slot = socketGroup.slot,
			enabled = socketGroup.enabled,
			source = socketGroup.source,
			mainActiveSkill = socketGroup.mainActiveSkill,
			mainActiveSkillCalcs = socketGroup.mainActiveSkillCalcs,
			gemList = { }
		}
		for index, gem in pairs(socketGroup.gemList) do
			newGroup.gemList[index] = {
				nameSpec = gem.nameSpec,
				level = gem.level,
				quality = gem.quality,
				enabled = gem.enabled,
				skillPart = gem.skillPart,
				skillPartCalcs = gem.skillPartCalcs,
				skillMinion = gem.skillMinion,
				skillMinionCalcs = gem.skillMinionCalcs,
				skillMinionSkill = gem.skillMinionSkill,
				skillMinionSkillCalcs = gem.skillMinionSkillCalcs,
				name = gem.name,
				data = gem.data,
				errMsg = gem.errMsg,
			}
		end
		t_insert(state.socketGroupList, newGroup)
	end
	return state
end

function SkillsTabClass:RestoreUndoState(state)
	local displayId = isValueInArray(self.socketGroupList, self.displayGroup)
	self.socketGroupList = state.socketGroupList
	self:SetDisplayGroup(displayId and self.socketGroupList[displayId])
	if self.controls.groupList.selGroup then
		self.controls.groupList.selGroup = self.socketGroupList[self.controls.groupList.selIndex]
	end
end
