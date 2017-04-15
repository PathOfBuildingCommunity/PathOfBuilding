-- Path of Building
--
-- Module: Build
-- Loads and manages the current build.
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_min = math.min
local m_max = math.max
local m_floor = math.floor
local m_abs = math.abs

local buildMode = common.New("ControlHost")

function buildMode:Init(dbFileName, buildName)
	self.abortSave = true

	self.tree = main.tree
	self.importTab = common.New("ImportTab", self)
	self.notesTab = common.New("NotesTab", self)
	self.configTab = common.New("ConfigTab", self)
	self.itemsTab = common.New("ItemsTab", self)
	self.treeTab = common.New("TreeTab", self)
	self.skillsTab = common.New("SkillsTab", self)
	self.calcsTab = common.New("CalcsTab", self)

	-- Controls: top bar, left side
	self.anchorTopBarLeft = common.New("Control", nil, 4, 4, 0, 20)
	self.controls.back = common.New("ButtonControl", {"LEFT",self.anchorTopBarLeft,"RIGHT"}, 0, 0, 60, 20, "<< Back", function()
		if self.unsaved then
			self:OpenSavePopup("LIST")
		else
			main:SetMode("LIST", self.dbFileName and self.buildName)
		end
	end)
	self.controls.buildName = common.New("Control", {"LEFT",self.controls.back,"RIGHT"}, 8, 0, 0, 20)
	self.controls.buildName.width = function(control)
		return DrawStringWidth(16, "VAR", self.buildName) + 98
	end
	self.controls.buildName.Draw = function(control)
		local x, y = control:GetPos()
		local bnw = DrawStringWidth(16, "VAR", self.buildName)
		SetDrawColor(0.5, 0.5, 0.5)
		DrawImage(nil, x + 91, y, bnw + 6, 20)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, x + 92, y + 1, bnw + 4, 18)
		SetDrawColor(1, 1, 1)
		DrawString(x, y + 2, "LEFT", 16, "VAR", "Current build:  "..self.buildName)
	end
	self.controls.save = common.New("ButtonControl", {"LEFT",self.controls.buildName,"RIGHT"}, 8, 0, 50, 20, "Save", function()
		self:SaveDBFile()
	end)
	self.controls.save.enabled = function()
		return not self.dbFileName or self.unsaved
	end
	self.controls.saveAs = common.New("ButtonControl", {"LEFT",self.controls.save,"RIGHT"}, 8, 0, 70, 20, "Save As", function()
		self:OpenSaveAsPopup()
	end)
	self.controls.saveAs.enabled = function()
		return self.dbFileName
	end

	-- Controls: top bar, right side
	self.anchorTopBarRight = common.New("Control", nil, function() return main.screenW / 2 + 6 end, 4, 0, 20)
	self.controls.pointDisplay = common.New("Control", {"LEFT",self.anchorTopBarRight,"RIGHT"}, -12, 0, 0, 20)
	self.controls.pointDisplay.x = function(control)
		local width, height = control:GetSize()
		if self.controls.saveAs:GetPos() + self.controls.saveAs:GetSize() < self.anchorTopBarRight:GetPos() - width - 16 then
			return -12 - width
		else
			return 0
		end
	end
	self.controls.pointDisplay.width = function(control)
		local used, ascUsed = self.spec:CountAllocNodes()
		local usedMax = 120 + (self.calcsTab.mainOutput.ExtraPoints or 0)
		local ascMax = 8
		control.str = string.format("%s%3d / %3d   %s%d / %d", used > usedMax and "^1" or "^7", used, usedMax, ascUsed > ascMax and "^1" or "^7", ascUsed, ascMax)
		control.req = "Required level: "..m_max(1, (100 + used - usedMax))
		return DrawStringWidth(16, "FIXED", control.str) + 8
	end
	self.controls.pointDisplay.Draw = function(control)
		local x, y = control:GetPos()
		local width, height = control:GetSize()
		SetDrawColor(1, 1, 1)
		DrawImage(nil, x, y, width, height)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
		SetDrawColor(1, 1, 1)
		DrawString(x + 4, y + 2, "LEFT", 16, "FIXED", control.str)
		if control:IsMouseInBounds() then
			SetDrawLayer(nil, 10)
			main:AddTooltipLine(16, control.req)
			main:DrawTooltip(x, y, width, height, main.viewPort)
			SetDrawLayer(nil, 0)
		end
	end
	self.controls.characterLevel = common.New("EditControl", {"LEFT",self.controls.pointDisplay,"RIGHT"}, 12, 0, 106, 20, "", "Level", "%D", 3, function(buf)
		self.characterLevel = m_min(tonumber(buf) or 1, 100)
		self.modFlag = true
		self.buildFlag = true
	end)
	self.controls.characterLevel.tooltipFunc = function()
		main:AddTooltipLine(16, "Experience multiplier:")
		local playerLevel = self.characterLevel
		local safeZone = 3 + m_floor(playerLevel / 16)
		for level, expLevel in ipairs(data.monsterExperienceLevelMap) do
			local diff = m_abs(playerLevel - expLevel) - safeZone
			local mult
			if diff <= 0 then
				mult = 1
			else
				mult = ((playerLevel + 5) / (playerLevel + 5 + diff ^ 2.5)) ^ 1.5
			end
			if playerLevel >= 95 then
				mult = mult * (1 / (1 + 0.1 * (playerLevel - 94)))
			end
			if mult > 0.01 then
				local line = level
				if level >= 68 then 
					line = line .. string.format(" (Tier %d)", level - 67)
				end
				line = line .. string.format(": %.1f%%", mult * 100)
				main:AddTooltipLine(14, line)
			end
		end
	end
	self.controls.classDrop = common.New("DropDownControl", {"LEFT",self.controls.characterLevel,"RIGHT"}, 8, 0, 100, 20, nil, function(index, val)
		local classId = self.tree.classNameMap[val]
		if classId ~= self.spec.curClassId then
			if self.spec:CountAllocNodes() == 0 or self.spec:IsClassConnected(classId) then
				self.spec:SelectClass(classId)
				self.spec:AddUndoState()
				self.buildFlag = true
			else
				main:OpenConfirmPopup("Class Change", "Changing class to "..val.." will reset your passive tree.\nThis can be avoided by connecting one of the "..val.." starting nodes to your tree.", "Continue", function()
					self.spec:SelectClass(classId)
					self.spec:AddUndoState()
					self.buildFlag = true					
				end)
			end
		end
	end)
	self.controls.ascendDrop = common.New("DropDownControl", {"LEFT",self.controls.classDrop,"RIGHT"}, 8, 0, 120, 20, nil, function(index, val)
		local ascendClassId = self.tree.ascendNameMap[val].ascendClassId
		self.spec:SelectAscendClass(ascendClassId)
		self.spec:AddUndoState()
		self.buildFlag = true
	end)

	-- Controls: Side bar
	self.anchorSideBar = common.New("Control", nil, 4, 36, 0, 0)
	self.controls.modeImport = common.New("ButtonControl", {"TOPLEFT",self.anchorSideBar,"TOPLEFT"}, 0, 0, 134, 20, "Import/Export Build", function()
		self.viewMode = "IMPORT"
	end)
	self.controls.modeImport.locked = function() return self.viewMode == "IMPORT" end
	self.controls.modeNotes = common.New("ButtonControl", {"LEFT",self.controls.modeImport,"RIGHT"}, 4, 0, 58, 20, "Notes", function()
		self.viewMode = "NOTES"
	end)
	self.controls.modeNotes.locked = function() return self.viewMode == "NOTES" end
	self.controls.modeConfig = common.New("ButtonControl", {"TOPRIGHT",self.anchorSideBar,"TOPLEFT"}, 300, 0, 100, 20, "Configuration", function()
		self.viewMode = "CONFIG"
	end)
	self.controls.modeConfig.locked = function() return self.viewMode == "CONFIG" end
	self.controls.modeTree = common.New("ButtonControl", {"TOPLEFT",self.anchorSideBar,"TOPLEFT"}, 0, 26, 72, 20, "Tree", function()
		self.viewMode = "TREE"
	end)
	self.controls.modeTree.locked = function() return self.viewMode == "TREE" end
	self.controls.modeSkills = common.New("ButtonControl", {"LEFT",self.controls.modeTree,"RIGHT"}, 4, 0, 72, 20, "Skills", function()
		self.viewMode = "SKILLS"
	end)
	self.controls.modeSkills.locked = function() return self.viewMode == "SKILLS" end
	self.controls.modeItems = common.New("ButtonControl", {"LEFT",self.controls.modeSkills,"RIGHT"}, 4, 0, 72, 20, "Items", function()
		self.viewMode = "ITEMS"
	end)
	self.controls.modeItems.locked = function() return self.viewMode == "ITEMS" end
	self.controls.modeCalcs = common.New("ButtonControl", {"LEFT",self.controls.modeItems,"RIGHT"}, 4, 0, 72, 20, "Calcs", function()
		self.viewMode = "CALCS"
	end)
	self.controls.modeCalcs.locked = function() return self.viewMode == "CALCS" end
	self.controls.banditNormal = common.New("DropDownControl", {"TOPLEFT",self.anchorSideBar,"TOPLEFT"}, 0, 70, 100, 16, 
		{{val="None",label="Passive point"},{val="Oak",label="Oak (Life)"},{val="Kraityn",label="Kraityn (Resists)"},{val="Alira",label="Alira (Mana)"}}, function(sel,val)
		self.banditNormal = val.val
		self.modFlag = true
		self.buildFlag = true
	end)
	self.controls.banditNormalLabel = common.New("LabelControl", {"BOTTOMLEFT",self.controls.banditNormal,"TOPLEFT"}, 0, 0, 0, 14, "^7Normal Bandit:")
	self.controls.banditCruel = common.New("DropDownControl", {"LEFT",self.controls.banditNormal,"RIGHT"}, 0, 0, 100, 16, 
		{{val="None",label="Passive point"},{val="Oak",label="Oak (Phys Dmg)"},{val="Kraityn",label="Kraityn (Att. Speed)"},{val="Alira",label="Alira (Cast Speed)"}}, function(sel,val)
		self.banditCruel = val.val
		self.modFlag = true
		self.buildFlag = true
	end)
	self.controls.banditCruelLabel = common.New("LabelControl", {"BOTTOMLEFT",self.controls.banditCruel,"TOPLEFT"}, 0, 0, 0, 14, "^7Cruel Bandit:")
	self.controls.banditMerciless = common.New("DropDownControl", {"LEFT",self.controls.banditCruel,"RIGHT"}, 0, 0, 100, 16, 
		{{val="None",label="Passive point"},{val="Oak",label="Oak (Endurance)"},{val="Kraityn",label="Kraityn (Frenzy)"},{val="Alira",label="Alira (Power)"}}, function(sel,val)
		self.banditMerciless = val.val
		self.modFlag = true
		self.buildFlag = true
	end)
	self.controls.banditMercilessLabel = common.New("LabelControl", {"BOTTOMLEFT",self.controls.banditMerciless,"TOPLEFT"}, 0, 0, 0, 14, "^7Merciless Bandit:")
	self.controls.mainSkillLabel = common.New("LabelControl", {"TOPLEFT",self.anchorSideBar,"TOPLEFT"}, 0, 95, 300, 16, "^7Main Skill:")
	self.controls.mainSocketGroup = common.New("DropDownControl", {"TOPLEFT",self.controls.mainSkillLabel,"BOTTOMLEFT"}, 0, 2, 300, 16, nil, function(index)
		self.mainSocketGroup = index
		self.modFlag = true
		self.buildFlag = true
	end)
	self.controls.mainSkill = common.New("DropDownControl", {"TOPLEFT",self.controls.mainSocketGroup,"BOTTOMLEFT"}, 0, 2, 300, 16, nil, function(index)
		local mainSocketGroup = self.skillsTab.socketGroupList[self.mainSocketGroup]
		mainSocketGroup.mainActiveSkill = index
		self.modFlag = true
		self.buildFlag = true
	end)
	self.controls.mainSkillPart = common.New("DropDownControl", {"TOPLEFT",self.controls.mainSocketGroup,"BOTTOMLEFT"}, 0, 20, 150, 18, nil, function(index)
		local mainSocketGroup = self.skillsTab.socketGroupList[self.mainSocketGroup]
		mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeGem.srcGem.skillPart = index
		self.modFlag = true
		self.buildFlag = true
	end)
	self.controls.mainSkillMinion = common.New("DropDownControl", {"TOPLEFT",self.controls.mainSocketGroup,"BOTTOMLEFT"}, 0, 20, 178, 18, nil, function(index, val)
		local mainSocketGroup = self.skillsTab.socketGroupList[self.mainSocketGroup]
		mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeGem.srcGem.skillMinion = val.val
		self.modFlag = true
		self.buildFlag = true
	end)
	self.controls.mainSkillMinionLibrary = common.New("ButtonControl", {"LEFT",self.controls.mainSkillMinion,"RIGHT"}, 2, 0, 120, 18, "Manage Spectres...", function()
		self:OpenSpectreLibrary()
	end)
	self.controls.mainSkillMinionSkill = common.New("DropDownControl", {"TOPLEFT",self.controls.mainSkillMinion,"BOTTOMLEFT"}, 0, 2, 200, 16, nil, function(index)
		local mainSocketGroup = self.skillsTab.socketGroupList[self.mainSocketGroup]
		mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeGem.srcGem.skillMinionSkill = index
		self.modFlag = true
		self.buildFlag = true
	end)
	self.controls.statBox = common.New("TextListControl", {"TOPLEFT",self.controls.mainSocketGroup,"BOTTOMLEFT"}, 0, 62, 300, 0, {{x=170,align="RIGHT_X"},{x=174,align="LEFT"}})
	self.controls.statBox.height = function(control)
		local x, y = control:GetPos()
		return main.screenH - 30 - y
	end

	-- Initialise class dropdown
	for classId, class in pairs(self.tree.classes) do
		t_insert(self.controls.classDrop.list, class.name)
	end
	table.sort(self.controls.classDrop.list)

	-- List of display stats
	-- This defines the stats in the side bar, and also which stats show in node/item comparisons
	-- This may be user-customisable in the future
	self.displayStats = {
		{ stat = "AverageHit", label = "Average Hit", fmt = ".1f", compPercent = true },
		{ stat = "AverageDamage", label = "Average Damage", fmt = ".1f", compPercent = true, flag = "attack" },
		{ stat = "Speed", label = "Attack Rate", fmt = ".2f", compPercent = true, flag = "attack" },
		{ stat = "Speed", label = "Cast Rate", fmt = ".2f", compPercent = true, flag = "spell" },
		{ stat = "HitSpeed", label = "Hit Rate", fmt = ".2f" },
		{ stat = "PreEffectiveCritChance", label = "Crit Chance", fmt = ".2f%%" },
		{ stat = "CritChance", label = "Effective Crit Chance", fmt = ".2f%%", condFunc = function(v,o) return v ~= o.PreEffectiveCritChance end },
		{ stat = "CritMultiplier", label = "Crit Multiplier", fmt = "d%%", pc = true, condFunc = function(v,o) return o.CritChance > 0 end },
		{ stat = "HitChance", label = "Hit Chance", fmt = ".0f%%", flag = "attack" },
		{ stat = "TotalDPS", label = "Total DPS", fmt = ".1f", compPercent = true, flag = "notAverage" },
		{ stat = "TotalDot", label = "DoT DPS", fmt = ".1f", compPercent = true },
		{ stat = "BleedDPS", label = "Bleed DPS", fmt = ".1f", compPercent = true },
		{ stat = "IgniteDPS", label = "Ignite DPS", fmt = ".1f", compPercent = true },
		{ stat = "IgniteDamage", label = "Total Damage per Ignite", fmt = ".1f", compPercent = true },
		{ stat = "WithIgniteDPS", label = "Total DPS inc. Ignite", fmt = ".1f", compPercent = true },
		{ stat = "WithIgniteAverageDamage", label = "Average Dmg. inc. Ignite", fmt = ".1f", compPercent = true },
		{ stat = "PoisonDPS", label = "Poison DPS", fmt = ".1f", compPercent = true },
		{ stat = "PoisonDamage", label = "Total Damage per Poison", fmt = ".1f", compPercent = true },
		{ stat = "WithPoisonDPS", label = "Total DPS inc. Poison", fmt = ".1f", compPercent = true },
		{ stat = "WithPoisonAverageDamage", label = "Average Dmg. inc. Poison", fmt = ".1f", compPercent = true },
		{ stat = "DecayDPS", label = "Decay DPS", fmt = ".1f", compPercent = true },
		{ stat = "Cooldown", label = "Skill Cooldown", fmt = ".2fs", lowerIsBetter = true },
		{ stat = "ManaCost", label = "Mana Cost", fmt = "d", compPercent = true, lowerIsBetter = true, condFunc = function() return true end },
		{ },
		{ stat = "Str", label = "Strength", fmt = "d" },
		{ stat = "Dex", label = "Dexterity", fmt = "d" },
		{ stat = "Int", label = "Intelligence", fmt = "d" },
		{ },
		{ stat = "Life", label = "Total Life", fmt = "d", compPercent = true },
		{ stat = "Spec:LifeInc", label = "%Inc Life from Tree", fmt = "d%%", condFunc = function(v,o) return v > 0 and o.Life > 1 end },
		{ stat = "LifeUnreserved", label = "Unreserved Life", fmt = "d", condFunc = function(v,o) return v < o.Life end, compPercent = true },
		{ stat = "LifeUnreservedPercent", label = "Unreserved Life", fmt = "d%%", condFunc = function(v,o) return v < 100 end },
		{ stat = "LifeRegen", label = "Life Regen", fmt = ".1f" },
		{ stat = "LifeLeechGainRate", label = "Life Leech/On Hit Rate", fmt = ".1f", compPercent = true },
		{ stat = "LifeLeechGainPerHit", label = "Life Leech/Gain per Hit", fmt = ".1f", compPercent = true },
		{ },
		{ stat = "Mana", label = "Total Mana", fmt = "d", compPercent = true },
		{ stat = "Spec:ManaInc", label = "%Inc Mana from Tree", fmt = "d%%" },
		{ stat = "ManaUnreserved", label = "Unreserved Mana", fmt = "d", condFunc = function(v,o) return v < o.Mana end, compPercent = true },
		{ stat = "ManaUnreservedPercent", label = "Unreserved Mana", fmt = "d%%", condFunc = function(v,o) return v < 100 end },
		{ stat = "ManaRegen", label = "Mana Regen", fmt = ".1f" },
		{ stat = "ManaLeechGainRate", label = "Mana Leech/On Hit Rate", fmt = ".1f", compPercent = true },
		{ stat = "ManaLeechGainPerHit", label = "Mana Leech/Gain per Hit", fmt = ".1f", compPercent = true },
		{ },
		{ stat = "EnergyShield", label = "Energy Shield", fmt = "d", compPercent = true },
		{ stat = "Spec:EnergyShieldInc", label = "%Inc ES from Tree", fmt = "d%%" },
		{ stat = "EnergyShieldRegen", label = "Energy Shield Regen", fmt = ".1f" },
		{ stat = "EnergyShieldLeechGainRate", label = "ES Leech/On Hit Rate", fmt = ".1f", compPercent = true },
		{ stat = "EnergyShieldLeechGainPerHit", label = "ES Leech/Gain per Hit", fmt = ".1f", compPercent = true },
		{ stat = "Evasion", label = "Evasion rating", fmt = "d", compPercent = true },
		{ stat = "Spec:EvasionInc", label = "%Inc Evasion from Tree", fmt = "d%%" },
		{ stat = "EvadeChance", label = "Evade Chance", fmt = "d%%" },
		{ stat = "Armour", label = "Armour", fmt = "d", compPercent = true },
		{ stat = "Spec:ArmourInc", label = "%Inc Armour from Tree", fmt = "d%%" },
		{ stat = "MovementSpeedMod", label = "Movement Speed Modifier", fmt = "+d%%", mod = true },
		{ stat = "BlockChance", label = "Block Chance", fmt = "d%%" },
		{ stat = "SpellBlockChance", label = "Spell Block Chance", fmt = "d%%" },
		{ stat = "AttackDodgeChance", label = "Attack Dodge Chance", fmt = "d%%" },
		{ stat = "SpellDodgeChance", label = "Spell Dodge Chance", fmt = "d%%" },
		{ },
		{ stat = "FireResist", label = "Fire Resistance", fmt = "d%%", condFunc = function() return true end },
		{ stat = "ColdResist", label = "Cold Resistance", fmt = "d%%", condFunc = function() return true end },
		{ stat = "LightningResist", label = "Lightning Resistance", fmt = "d%%", condFunc = function() return true end },
		{ stat = "ChaosResist", label = "Chaos Resistance", fmt = "d%%", condFunc = function() return true end },
		{ stat = "FireResistOverCap", label = "Fire Res. Over Max", fmt = "d%%" },
		{ stat = "ColdResistOverCap", label = "Cold Res. Over Max", fmt = "d%%" },
		{ stat = "LightningResistOverCap", label = "Lightning Res. Over Max", fmt = "d%%" },
		{ stat = "ChaosResistOverCap", label = "Chaos Res. Over Max", fmt = "d%%" },
	}
	self.minionDisplayStats = {
		{ stat = "AverageDamage", label = "Average Damage", fmt = ".1f", compPercent = true },
		{ stat = "Speed", label = "Attack/Cast Rate", fmt = ".2f", compPercent = true },
		{ stat = "TotalDPS", label = "Total DPS", fmt = ".1f", compPercent = true },
		{ stat = "TotalDot", label = "DoT DPS", fmt = ".1f", compPercent = true },
		{ stat = "WithPoisonDPS", label = "DPS inc. Poison", fmt = ".1f", compPercent = true },
		{ stat = "Cooldown", label = "Skill Cooldown", fmt = ".2fs", lowerIsBetter = true },
		{ stat = "Life", label = "Total Life", fmt = ".1f", compPercent = true },
		{ stat = "LifeRegen", label = "Life Regen", fmt = ".1f" },
		{ stat = "LifeLeechGainRate", label = "Life Leech/On Hit Rate", fmt = ".1f", compPercent = true },
	}

	self.viewMode = "TREE"

	self.dbFileName = dbFileName
	self.buildName = buildName

	self.characterLevel = 1
	self.controls.characterLevel:SetText(tostring(self.characterLevel))
	self.banditNormal = "None"
	self.banditCruel = "None"
	self.banditMerciless = "None"
	self.spectreList = { }

	-- List of modules with Load/Save methods
	-- These will be called to load or save data to their respective sections of the build XML file
	self.savers = {
		["Build"] = self,
		["Config"] = self.configTab,
		["Notes"] = self.notesTab,
		["Tree"] = self.treeTab,
		["TreeView"] = self.treeTab.viewer,
		["Items"] = self.itemsTab,
		["Skills"] = self.skillsTab,
		["Calcs"] = self.calcsTab,
	}
	self.legacyLoaders = { -- Special loaders for legacy sections
		["Spec"] = self.treeTab,
	}

	if self:LoadDBFile() then
		main:SetMode("LIST", buildName)
		return
	end

	if next(self.configTab.input) == nil then
		-- Check for old calcs tab settings
		self.configTab:ImportCalcSettings()
	end

	-- Build calculation output tables
	self.calcsTab:BuildOutput()
	self:RefreshStatList()
	self.buildFlag = false

	--[[
	for _, item in pairs(main.uniqueDB.list) do
		ConPrintf("%s", item.name)
		self.itemsTab:AddItemTooltip(item)
	end
	for _, item in pairs(main.rareDB.list) do
		ConPrintf("%s", item.name)
		self.itemsTab:AddItemTooltip(item)
	end
	--]]

	--[[
	local start = GetTime()
	SetProfiling(true)
	for i = 1, 10  do
		self.calcsTab:PowerBuilder()
	end
	SetProfiling(false)
	ConPrintf("Power build time: %d msec", GetTime() - start)
	--]]

	self.abortSave = false
end

function buildMode:CanExit(mode)
	if not self.unsaved then
		return true
	end
	self:OpenSavePopup(mode)
	return false
end

function buildMode:Shutdown()
	if launch.devMode and not self.abortSave and self.dbFileName then
		self:SaveDBFile()
	end
	self.abortSave = nil

	self.savers = nil
end

function buildMode:Load(xml, fileName)
	if xml.attrib.viewMode then
		self.viewMode = xml.attrib.viewMode
	end
	self.characterLevel = tonumber(xml.attrib.level) or 1
	self.controls.characterLevel:SetText(tostring(self.characterLevel))
	for _, diff in pairs({"banditNormal","banditCruel","banditMerciless"}) do
		self[diff] = xml.attrib[diff] or "None"
	end
	self.mainSocketGroup = tonumber(xml.attrib.mainSkillIndex) or tonumber(xml.attrib.mainSocketGroup) or 1
	wipeTable(self.spectreList)
	for _, child in ipairs(xml) do
		if child.elem == "Spectre" then
			if child.attrib.id and data.minions[child.attrib.id] then
				t_insert(self.spectreList, child.attrib.id)
			end
		end
	end
end

function buildMode:Save(xml)
	xml.attrib = {
		viewMode = self.viewMode,
		level = tostring(self.characterLevel),
		className = self.spec.curClassName,
		ascendClassName = self.spec.curAscendClassName,
		banditNormal = self.banditNormal,
		banditCruel = self.banditCruel,
		banditMerciless = self.banditMerciless,
		mainSocketGroup = tostring(self.mainSocketGroup),
	}
	for _, id in ipairs(self.spectreList) do
		t_insert(xml, { elem = "Spectre", attrib = { id = id } })
	end
	self.modFlag = false
end

function buildMode:OnFrame(inputEvents)
	if self.abortSave and not launch.devMode then
		main:SetMode("LIST", self.buildName)
	end

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if IsKeyDown("CTRL") then
				if event.key == "s" then
					self:SaveDBFile()
					inputEvents[id] = nil
				elseif event.key == "w" then
					if self.unsaved then
						self:OpenSavePopup("LIST")
					else
						main:SetMode("LIST", self.dbFileName and self.buildName)
					end
				elseif event.key == "1" then
					self.viewMode = "TREE"
				elseif event.key == "2" then
					self.viewMode = "SKILLS"
				elseif event.key == "3" then
					self.viewMode = "ITEMS"
				elseif event.key == "4" then
					self.viewMode = "CALCS"
				elseif event.key == "5" then
					self.viewMode = "CONFIG"
				end
			end
		end
	end
	self:ProcessControlsInput(inputEvents, main.viewPort)

	-- Update contents of ascendancy class dropdown
	wipeTable(self.controls.ascendDrop.list)
	for i = 0, #self.spec.curClass.classes do
		local ascendClass = self.spec.curClass.classes[i]
		t_insert(self.controls.ascendDrop.list, ascendClass.name)
	end

	self.controls.classDrop:SelByValue(self.spec.curClassName)
	self.controls.ascendDrop:SelByValue(self.spec.curAscendClassName)

	for _, diff in pairs({"banditNormal","banditCruel","banditMerciless"}) do
		self.controls[diff]:SelByValue(self[diff])
	end

	if self.buildFlag then
		-- Rebuild calculation output tables
		self.buildFlag = false
		self.calcsTab:BuildOutput()
		self:RefreshStatList()
	end

	-- Update contents of main skill dropdowns
	self:RefreshSkillSelectControls(self.controls, self.mainSocketGroup, "")

	-- Draw contents of current tab
	local sideBarWidth = 312
	local tabViewPort = {
		x = sideBarWidth,
		y = 32,
		width = main.screenW - sideBarWidth,
		height = main.screenH - 32
	}
	if self.viewMode == "IMPORT" then
		self.importTab:Draw(tabViewPort, inputEvents)
	elseif self.viewMode == "NOTES" then
		self.notesTab:Draw(tabViewPort, inputEvents)
	elseif self.viewMode == "CONFIG" then
		self.configTab:Draw(tabViewPort, inputEvents)
	elseif self.viewMode == "TREE" then
		self.treeTab:Draw(tabViewPort, inputEvents)
	elseif self.viewMode == "SKILLS" then
		self.skillsTab:Draw(tabViewPort, inputEvents)
	elseif self.viewMode == "ITEMS" then
		self.itemsTab:Draw(tabViewPort, inputEvents)
	elseif self.viewMode == "CALCS" then
		self.calcsTab:Draw(tabViewPort, inputEvents)
	end

	self.unsaved = self.modFlag or self.notesTab.modFlag or self.configTab.modFlag or self.spec.modFlag or self.skillsTab.modFlag or self.itemsTab.modFlag or self.calcsTab.modFlag

	SetDrawLayer(5)

	-- Draw top bar background
	SetDrawColor(0.2, 0.2, 0.2)
	DrawImage(nil, 0, 0, main.screenW, 28)
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, 0, 28, main.screenW, 4)
	DrawImage(nil, main.screenW/2 - 2, 0, 4, 28)

	-- Draw side bar background
	SetDrawColor(0.1, 0.1, 0.1)
	DrawImage(nil, 0, 32, sideBarWidth - 4, main.screenH - 32)
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, sideBarWidth - 4, 32, 4, main.screenH - 32)

	self:DrawControls(main.viewPort)
end

function buildMode:OpenSavePopup(mode)
	local modeDesc = {
		["LIST"] = "now?",
		["EXIT"] = "before exiting?",
		["UPDATE"] = "before updating?",
	}
	main:OpenPopup(290, 100, "Save Changes", {
		common.New("LabelControl", nil, 0, 20, 0, 16, "^7This build has unsaved changes.\nDo you want to save them "..modeDesc[mode]),
		common.New("ButtonControl", nil, -90, 70, 80, 20, "Save", function()
			main:ClosePopup()
			self.actionOnSave = mode
			self:SaveDBFile()
		end),
		common.New("ButtonControl", nil, 0, 70, 80, 20, "Don't Save", function()
			main:ClosePopup()
			if mode == "LIST" then
				main:SetMode("LIST", self.dbFileName and self.buildName)
			elseif mode == "EXIT" then
				Exit()
			elseif mode == "UPDATE" then
				launch:ApplyUpdate(launch.updateAvailable)
			end
		end),
		common.New("ButtonControl", nil, 90, 70, 80, 20, "Cancel", function()
			main:ClosePopup()
		end),
	})
end

function buildMode:OpenSaveAsPopup()
	local newFileName, newBuildName
	local popup
	popup = main:OpenPopup(370, 100, self.dbFileName and "Save As" or "Save", {
		common.New("LabelControl", nil, 0, 20, 0, 16, "^7Enter new build name:"),
		edit = common.New("EditControl", nil, 0, 40, 350, 20, self.dbFileName and self.buildName, nil, "\\/:%*%?\"<>|%c", 50, function(buf)
			newFileName = main.buildPath..buf..".xml"
			newBuildName = buf
			popup.controls.save.enabled = false
			if not buf:match("%S") then
				return
			end
			local out = io.open(newFileName, "r")
			if out then
				out:close()
				return
			end
			popup.controls.save.enabled = true
		end),
		save = common.New("ButtonControl", nil, -45, 70, 80, 20, "Save", function()
			self.dbFileName = newFileName
			self.buildName = newBuildName
			main.modeArgs = { newFileName, newBuildName }
			self:SaveDBFile()
			main:ClosePopup()
		end),
		common.New("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
			main:ClosePopup()
		end),
	}, "save", "edit")
	popup.controls.save.enabled = false
end

-- Open the spectre library popup
function buildMode:OpenSpectreLibrary()
	local controls = { }
	local destList = copyTable(self.spectreList)
	local sourceList = { }
	for id in pairs(data.spectres) do
		t_insert(sourceList, id)
	end
	table.sort(sourceList, function(a,b) 
		if data.minions[a].name == data.minions[b].name then
			return a < b
		else
			return data.minions[a].name < data.minions[b].name
		end
	end)
	controls.list = common.New("MinionList", nil, -100, 40, 190, 250, destList, true)
	controls.source = common.New("MinionList", nil, 100, 40, 190, 250, sourceList, false, controls.list)
	controls.save = common.New("ButtonControl", nil, -45, 300, 80, 20, "Save", function()
		self.spectreList = destList
		self.modFlag = true
		self.buildFlag = true
		main:ClosePopup()
	end)
	controls.cancel = common.New("ButtonControl", nil, 45, 300, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(410, 330, "Spectre Library", controls)
end

-- Refresh the set of controls used to select main group/skill/minion
function buildMode:RefreshSkillSelectControls(controls, mainGroup, suffix)
	controls.mainSocketGroup.sel = mainGroup
	wipeTable(controls.mainSocketGroup.list)
	for i, socketGroup in pairs(self.skillsTab.socketGroupList) do
		controls.mainSocketGroup.list[i] = { val = i, label = socketGroup.displayLabel }
	end
	if #controls.mainSocketGroup.list == 0 then
		controls.mainSocketGroup.list[1] = { val = 1, label = "<No skills added yet>" }
		controls.mainSkill.shown = false
		controls.mainSkillPart.shown = false
		controls.mainSkillMinion.shown = false
		controls.mainSkillMinionSkill.shown = false
	else
		local mainSocketGroup = self.skillsTab.socketGroupList[mainGroup]
		local displaySkillList = mainSocketGroup["displaySkillList"..suffix]
		local mainActiveSkill = mainSocketGroup["mainActiveSkill"..suffix] or 1
		wipeTable(controls.mainSkill.list)
		for i, activeSkill in ipairs(displaySkillList) do
			t_insert(controls.mainSkill.list, { val = i, label = activeSkill.activeGem.name })
		end
		controls.mainSkill.enabled = #displaySkillList > 1
		controls.mainSkill.sel = mainActiveSkill
		controls.mainSkill.shown = true
		controls.mainSkillPart.shown = false
		controls.mainSkillMinion.shown = false
		controls.mainSkillMinionLibrary.shown = false
		controls.mainSkillMinionSkill.shown = false
		if displaySkillList[1] then
			local activeSkill = displaySkillList[mainActiveSkill]
			local activeGem = activeSkill.activeGem
			if activeGem then
				if activeGem.data.parts and #activeGem.data.parts > 1 then
					controls.mainSkillPart.shown = true
					wipeTable(controls.mainSkillPart.list)
					for i, part in ipairs(activeGem.data.parts) do
						t_insert(controls.mainSkillPart.list, { val = i, label = part.name })
					end
					controls.mainSkillPart.sel = activeGem.srcGem["skillPart"..suffix] or 1
				elseif not activeSkill.skillFlags.disable and activeGem.data.minionList then
					local list
					if activeGem.data.minionList[1] then
						list = activeGem.data.minionList
					else
						list = self.spectreList 
						controls.mainSkillMinionLibrary.shown = true
					end
					wipeTable(controls.mainSkillMinion.list)
					for _, name in ipairs(list) do
						t_insert(controls.mainSkillMinion.list, {
							val = name,
							label = data.minions[name].name,
						})
					end
					controls.mainSkillMinion.enabled = #controls.mainSkillMinion.list > 1
					controls.mainSkillMinion.shown = true
					controls.mainSkillMinion:SelByValue(activeGem.srcGem["skillMinion"..suffix] or controls.mainSkillMinion.list[1])
					wipeTable(controls.mainSkillMinionSkill.list)
					if activeSkill.minion then
						for _, minionSkill in ipairs(activeSkill.minion.activeSkillList) do
							t_insert(controls.mainSkillMinionSkill.list, minionSkill.activeGem.name)
						end
						controls.mainSkillMinionSkill.sel = activeGem.srcGem["skillMinionSkill"..suffix] or 1
						controls.mainSkillMinionSkill.shown = true
						controls.mainSkillMinionSkill.enabled = #controls.mainSkillMinionSkill.list > 1
					else
						t_insert(controls.mainSkillMinion.list, "<No spectres in build>")
					end
				end
			end
		end
	end
end

-- Add stat list for given actor
function buildMode:AddDisplayStatList(statList, actor)
	for index, statData in ipairs(statList) do
		if statData.stat then
			if not statData.flag or actor.mainSkill.skillFlags[statData.flag] then 
				local statVal = actor.output[statData.stat]
				if statVal and ((statData.condFunc and statData.condFunc(statVal,actor.output)) or (not statData.condFunc and statVal ~= 0)) then
					t_insert(self.controls.statBox.list, {
						height = 16,
						"^7"..statData.label..":",
						string.format("%s%"..statData.fmt, statVal >= 0 and "^7" or data.colorCodes.NEGATIVE, statVal * ((statData.pc or statData.mod) and 100 or 1) - (statData.mod and 100 or 0)) 
					})
				end
			end
		else
			t_insert(self.controls.statBox.list, { height = 10 })
		end
	end
end

-- Build list of side bar stats
function buildMode:RefreshStatList()
	wipeTable(self.controls.statBox.list)
	if self.calcsTab.mainEnv.minion then
		t_insert(self.controls.statBox.list, { height = 18, "^7Minion:" })
		self:AddDisplayStatList(self.minionDisplayStats, self.calcsTab.mainEnv.minion)
		t_insert(self.controls.statBox.list, { height = 10 })
		t_insert(self.controls.statBox.list, { height = 18, "^7Player:" })
	end
	self:AddDisplayStatList(self.displayStats, self.calcsTab.mainEnv.player)
end

function buildMode:CompareStatList(statList, actor, baseOutput, compareOutput, header, nodeCount)
	local count = 0
	for _, statData in ipairs(statList) do
		if statData.stat and (not statData.flag or actor.mainSkill.skillFlags[statData.flag]) then
			local statVal1, statVal2
			if statData.space then
				statVal1 = compareOutput[statData.space] and compareOutput[statData.space][statData.stat] or 0
				statVal2 = baseOutput[statData.space] and baseOutput[statData.space][statData.stat] or 0
			else
				statVal1 = compareOutput[statData.stat] or 0
				statVal2 = baseOutput[statData.stat] or 0
			end
			local diff = statVal1 - statVal2
			if diff > 0.001 or diff < -0.001 then
				if count == 0 then
					main:AddTooltipLine(14, header)
				end
				local color = ((statData.lowerIsBetter and diff < 0) or (not statData.lowerIsBetter and diff > 0)) and data.colorCodes.POSITIVE or data.colorCodes.NEGATIVE
				local line = string.format("%s%+"..statData.fmt.." %s", color, diff * ((statData.pc or statData.mod) and 100 or 1), statData.label)
				local pcPerPt = ""
				if statData.compPercent and statVal1 ~= 0 and statVal2 ~= 0 then
					local pc = statVal1 / statVal2 * 100 - 100
					line = line .. string.format(" (%+.1f%%)", pc)
					if nodeCount then
						pcPerPt = string.format(" (%+.1f%%)", pc / nodeCount)
					end
				end
				if nodeCount then
					line = line .. string.format(" ^8[%+"..statData.fmt.."%s per point]", diff * ((statData.pc or statData.mod) and 100 or 1) / nodeCount, pcPerPt)
				end
				main:AddTooltipLine(14, line)
				count = count + 1
			end
		end
	end
	return count
end

-- Compare values of all display stats between the two output tables, and add any changed stats to the tooltip
-- Adds the provided header line before the first stat line, if any are added
-- Returns the number of stat lines added
function buildMode:AddStatComparesToTooltip(baseOutput, compareOutput, header, nodeCount)
	local count = 0
	if baseOutput.Minion then
		count = count + self:CompareStatList(self.minionDisplayStats, self.calcsTab.mainEnv.minion, baseOutput.Minion, compareOutput.Minion, header.."\n^7Minion:", nodeCount)
		if count > 0 then
			header = "^7Player:"
		else
			header = header.."\n^7Player:"
		end
	end
	count = count + self:CompareStatList(self.displayStats, self.calcsTab.mainEnv.player, baseOutput, compareOutput, header, nodeCount)
	return count
end

function buildMode:LoadDB(xmlText, fileName)
	-- Parse the XML
	local dbXML, errMsg = common.xml.ParseXML(xmlText)
	if not dbXML then
		launch:ShowErrMsg("^1Error loading '%s': %s", fileName, errMsg)
		return true
	elseif dbXML[1].elem ~= "PathOfBuilding" then
		launch:ShowErrMsg("^1Error parsing '%s': 'PathOfBuilding' root element missing", fileName)
		return true
	end

	-- For each child of the root node...
	for _, node in ipairs(dbXML[1]) do
		if type(node) == "table" then
			-- Check if there is a saver that can load this section
			local saver = self.savers[node.elem] or self.legacyLoaders[node.elem]
			if saver then
				if saver:Load(node, self.dbFileName) then
					return true
				end
			end
		end
	end

	for _, saver in pairs(self.savers) do
		if saver.PostLoad then
			saver:PostLoad()
		end
	end
end

function buildMode:LoadDBFile()
	if not self.dbFileName then
		return
	end
	ConPrintf("Loading '%s'...", self.dbFileName)
	local file = io.open(self.dbFileName, "r")
	if not file then
		return true
	end
	local xmlText = file:read("*a")
	file:close()
	return self:LoadDB(xmlText, self.dbFileName)
end

function buildMode:SaveDB(fileName)
	local dbXML = { elem = "PathOfBuilding" }

	-- Call on all savers to save their data in their respective sections
	for elem, saver in pairs(self.savers) do
		local node = { elem = elem }
		saver:Save(node)
		t_insert(dbXML, node)
	end

	-- Compose the XML
	local xmlText, errMsg = common.xml.ComposeXML(dbXML)
	if not xmlText then
		launch:ShowErrMsg("Error saving '%s': %s", fileName, errMsg)
	else
		return xmlText
	end
end

function buildMode:SaveDBFile()
	if not self.dbFileName then
		self:OpenSaveAsPopup()
		return
	end
	local xmlText = self:SaveDB(self.dbFileName)
	if not xmlText then
		return true
	end
	local file = io.open(self.dbFileName, "w+")
	if not file then
		main:OpenMessagePopup("Error", "Couldn't save the build file:\n"..self.dbFileName.."\nMake sure the save folder exists and is writable.")
		return true
	end
	file:write(xmlText)
	file:close()
	if self.actionOnSave == "LIST" then
		main:SetMode("LIST", self.dbFileName and self.buildName)
	elseif self.actionOnSave == "EXIT" then
		Exit()
	elseif self.actionOnSave == "UPDATE" then
		launch:ApplyUpdate(launch.updateAvailable)
	end
	self.actionOnSave = nil
end

return buildMode