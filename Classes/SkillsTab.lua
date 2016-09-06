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

	self.list = { }

	-- Skill list
	self.controls.skillList = common.New("SkillList", {"TOPLEFT",self,"TOPLEFT"}, 20, 24, 360, 300, self)

	-- Skill details
	self.anchorSkillDetail = common.New("Control", {"TOPLEFT",self.controls.skillList,"TOPRIGHT"}, 20, 0, 0, 0)
	self.anchorSkillDetail.shown = function()
		return self.displaySkill ~= nil
	end
	self.controls.skillLabel = common.New("EditControl", {"TOPLEFT",self.anchorSkillDetail,"TOPLEFT"}, 0, 0, 380, 20, nil, "Label", "[%C]", 50, function(buf)
		self.displaySkill.label = buf
		self:ProcessSkill(self.displaySkill)
		self:AddUndoState()
	end)
	self.controls.skillSlotLabel = common.New("LabelControl", {"TOPLEFT",self.anchorSkillDetail,"TOPLEFT"}, 0, 30, 0, 16, "^7Socketed in:")
	self.controls.skillSlot = common.New("SlotSelectControl", {"TOPLEFT",self.anchorSkillDetail,"TOPLEFT"}, 85, 28, 100, 20, self.build, function(sel, selVal)
		if sel > 1 then
			self.displaySkill.slot = selVal
		else
			self.displaySkill.slot = nil
		end
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.skillActive = common.New("CheckBoxControl", {"LEFT",self.controls.skillSlot,"RIGHT"}, 60, 0, 20, "Active:", function(state)
		self.displaySkill.active = state
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	self.controls.skillActive.tooltip = "If a skill is active, any buff, aura or curse modifiers it provides will affect your other skills and your defensive stats.\nAny life or mana reservations will also be applied."

	-- Skill gem slots
	self.gemSlots = { }
	self:CreateGemSlot(1)
	self.controls.gemNameHeader = common.New("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].nameSpec,"TOPLEFT"}, 0, -2, 0, 16, "^7Gem name:")
	self.controls.gemLevelHeader = common.New("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].level,"TOPLEFT"}, 0, -2, 0, 16, "^7Level:")
	self.controls.gemQualityHeader = common.New("LabelControl", {"BOTTOMLEFT",self.gemSlots[1].quality,"TOPLEFT"}, 0, -2, 0, 16, "^7Quality:")
end)

function SkillsTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if node.elem == "Skill" then
			local skill = { }
			skill.active = node.attrib.active == "true"
			skill.label = node.attrib.label
			skill.slot = node.attrib.slot
			skill.skillPart = tonumber(node.attrib.skillPart)
			skill.gemList = { }
			for _, child in ipairs(node) do
				local gem = { }
				gem.nameSpec = child.attrib.nameSpec
				gem.level = tonumber(child.attrib.level)
				gem.quality = tonumber(child.attrib.quality)
				t_insert(skill.gemList, gem)
			end
			self:ProcessSkill(skill)
			t_insert(self.list, skill)
		end
	end
	self:SetDisplaySkill(self.list[1])
	self:ResetUndo()
end

function SkillsTabClass:Save(xml)
	for _, skill in ipairs(self.list) do
		local node = { elem = "Skill", attrib = {
			active = tostring(skill.active),
			label = skill.label,
			slot = skill.slot,
			skillPart = tostring(skill.skillPart)
		} }
		for _, gem in ipairs(skill.gemList) do
			t_insert(node, { elem = "Gem", attrib = {
				nameSpec = gem.nameSpec,
				level = tostring(gem.level),
				quality = tostring(gem.quality),
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
				self:PasteSkill()
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:UpdateGemSlots(viewPort)

	self:DrawControls(viewPort)
end

function SkillsTabClass:CopySkill(skill)
	local skillText = ""
	if skill.label:match("%S") then
		skillText = skillText .. "Label: "..skill.label.."\r\n"
	end
	if skill.slot then
		skillText = skillText .. "Slot: "..skill.slot.."\r\n"
	end
	for _, gem in ipairs(skill.gemList) do
		skillText = skillText .. string.format("%s %d/%d\r\n", gem.nameSpec, gem.level, gem.quality)
	end
	Copy(skillText)
end

function SkillsTabClass:PasteSkill()
	local skillText = Paste()
	if skillText then
		local newSkill = { label = "", active = true, gemList = { } }
		local label = skillText:match("Label: (%C+)")
		if label then
			newSkill.label = label
		end
		local slot = skillText:match("Slot: (%C+)")
		if slot then
			newSkill.slot = slot
		end
		for nameSpec, level, quality in skillText:gmatch("([ %a']+) (%d+)/(%d+)") do
			t_insert(newSkill.gemList, { nameSpec = nameSpec, level = tonumber(level) or 1, quality = tonumber(quality) or 0 })
		end
		if #newSkill.gemList > 0 then
			t_insert(self.list, newSkill)
			self.controls.skillList.selSkill = newSkill
			self.controls.skillList.selIndex = #self.list
			self:SetDisplaySkill(newSkill)
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
	slot.nameSpec = common.New("EditControl", nil, 0, 0, 200, 20, nil, nil, "[ %a']", 30, function(buf)
		if not self.displaySkill.gemList[index] then
			self.displaySkill.gemList[index] = { nameSpec = "", level = 1, quality = 0 }
		end
		self.displaySkill.gemList[index].nameSpec = buf
		self:ProcessSkill(self.displaySkill)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	if index == 1 then
		slot.nameSpec:SetAnchor("TOPLEFT", self.anchorSkillDetail, "TOPLEFT", 0, 28 + 28 + 16)
	else
		slot.nameSpec:SetAnchor("TOPLEFT", self.gemSlots[index - 1].nameSpec, "TOPLEFT", 0, 22)
	end
	slot.nameSpec:AddToTabGroup(self.controls.skillLabel)
	slot.nameSpec.shown = function()
		return index <= #self.displaySkill.gemList + 1
	end
	self.controls["gemSlotName"..index] = slot.nameSpec

	-- Gem level
	slot.level = common.New("EditControl", {"LEFT",slot.nameSpec,"RIGHT"}, 2, 0, 60, 20, nil, nil, "[%d]", 2, function(buf)
		if not self.displaySkill.gemList[index] then
			self.displaySkill.gemList[index] = { nameSpec = "", level = 1, quality = 0 }
		end
		self.displaySkill.gemList[index].level = tonumber(buf) or 1
		self:ProcessSkill(self.displaySkill)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.level:AddToTabGroup(self.controls.skillLabel)
	self.controls["gemSlotLevel"..index] = slot.level

	-- Gem quality
	slot.quality = common.New("EditControl", {"LEFT",slot.level,"RIGHT"}, 2, 0, 60, 20, nil, nil, "[%d]", 2, function(buf)
		if not self.displaySkill.gemList[index] then
			self.displaySkill.gemList[index] = { nameSpec = "", level = 1, quality = 0 }
		end
		self.displaySkill.gemList[index].quality = tonumber(buf) or 0
		self:ProcessSkill(self.displaySkill)
		self:AddUndoState()
		self.build.buildFlag = true
	end)
	slot.quality:AddToTabGroup(self.controls.skillLabel)
	self.controls["gemSlotQuality"..index] = slot.quality

	-- Parser/calculator error message
	slot.errMsg = common.New("LabelControl", {"LEFT",slot.quality,"RIGHT"}, 2, 2, 0, 16, function()
		return "^1"..(self.displaySkill.gemList[index] and (self.displaySkill.gemList[index].errMsg or self.displaySkill.gemList[index].calcsErrMsg) or "")
	end)
	self.controls["gemSlotErrMsg"..index] = slot.errMsg
end

-- Update the gem slot controls to reflect the currently displayed skill
function SkillsTabClass:UpdateGemSlots(viewPort)
	if not self.displaySkill then
		return
	end
	for slotIndex = 1, #self.displaySkill.gemList + 1 do
		if not self.gemSlots[slotIndex] then
			self:CreateGemSlot(slotIndex)
		end
		local slot = self.gemSlots[slotIndex]
		slot.nameSpec.inactiveCol = "^8"
		if slotIndex == #self.displaySkill.gemList + 1 then
			slot.nameSpec:SetText("")
			slot.level:SetText("")
			slot.quality:SetText("")
		else
			local gemData = self.displaySkill.gemList[slotIndex].data
			if gemData then
				if gemData.strength then
					slot.nameSpec.inactiveCol = data.colorCodes.STRENGTH
				elseif gemData.dexterity then
					slot.nameSpec.inactiveCol = data.colorCodes.DEXTERITY
				elseif gemData.intelligence then
					slot.nameSpec.inactiveCol = data.colorCodes.INTELLIGENCE
				end
			end
		end
	end
end

-- Find the skill gem matching the given specification
function SkillsTabClass:FindSkillGem(nameSpec)
	-- Search for gem name using increasingly broad search patterns
	local patternList = {
		"^ "..nameSpec:gsub("%a", function(a) return "["..a:upper()..a:lower().."]" end).."$", -- Exact match (case-insensitive)
		"^"..nameSpec:gsub("%a", " %0%%l+").."$", -- Simple abbreviation ("CtF" -> "Cold to Fire")
		"^"..nameSpec:gsub(" ",""):gsub("%l", "%%l*%0").."%l+$", -- Abbreviated words ("CldFr" -> "Cold to Fire")
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
				return "Gem '"..gemName.."' is unsupported"
			else
				return nil, gemName, gemData
			end
		end
	end
	return "Unrecognised gem name '"..nameSpec.."'"
end

-- Processes the given skill, filling in information that will be used for display or calculations
function SkillsTabClass:ProcessSkill(skill)
	-- Loop through the skill gem list
	local index = 1
	while true do
		local gem = skill.gemList[index]
		if not gem then
			break
		end
		if gem.nameSpec:match("%S") then
			-- Gem name has been specified, try to find the matching skill gem
			gem.errMsg, gem.name, gem.data = self:FindSkillGem(gem.nameSpec)
			if gem.name then
				gem.level = m_max(1, m_min(#gem.data.levels, gem.level))
				gem.quality = m_max(0, m_min(23, gem.quality))
			end
		else
			gem.errMsg, gem.name, gem.data = nil
		end
		if gem.nameSpec:match("%S") or gem.level ~= 1 or gem.quality ~= 0 then
			index = index + 1
		else
			-- Empty gem, remove it
			t_remove(skill.gemList, index)
		end
	end

	-- Determine the label to be displayed in the skill list and elsewhere
	-- If the user didn't specify one, default to the name of the first gem if present
	skill.displayLabel = (skill.label:match("%S") and skill.label)
						 or (skill.gemList[1] and skill.gemList[1].nameSpec:match("%S") and skill.gemList[1].nameSpec) 
						 or "Empty skill"
end

-- Set the skill to be displayed/edited
function SkillsTabClass:SetDisplaySkill(skill)
	self.displaySkill = skill
	if skill then
		self:ProcessSkill(skill)

		-- Update the main controls
		self.controls.skillLabel:SetText(skill.label)
		self.controls.skillSlot:SelByValue(skill.slot or "None")
		self.controls.skillActive.state = skill.active

		-- Update the gem slot controls
		for index, gem in pairs(skill.gemList) do
			if not self.gemSlots[index] then
				self:CreateGemSlot(index)
			end
			self.gemSlots[index].nameSpec:SetText(gem.nameSpec)
			self.gemSlots[index].level:SetText(gem.level)
			self.gemSlots[index].quality:SetText(gem.quality)
		end
	end
end

function SkillsTabClass:CreateUndoState()
	local state = { }
	state.list = copyTable(self.list)
	return state
end

function SkillsTabClass:RestoreUndoState(state)
	local displayId = isValueInArray(self.list, self.displaySkill)
	self.list = state.list
	self:SetDisplaySkill(displayId and self.list[displayId])
	if self.controls.skillList.selSkill then
		self.controls.skillList.selSkill = self.list[self.controls.skillList.selIndex]
	end
end
