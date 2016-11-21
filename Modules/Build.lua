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

local buildMode = common.New("ControlHost")

function buildMode:Init(dbFileName, buildName)
	self.abortSave = true

	self.tree = main.tree
	self.importTab = common.New("ImportTab", self)
	self.configTab = common.New("ConfigTab", self)
	self.spec = common.New("PassiveSpec", self)
	self.treeTab = common.New("TreeTab", self)
	self.skillsTab = common.New("SkillsTab", self)
	self.itemsTab = common.New("ItemsTab", self)
	self.calcsTab = common.New("CalcsTab", self)

	-- Controls: top bar, left side
	self.anchorTopBarLeft = common.New("Control", nil, 4, 4, 0, 20)
	self.controls.back = common.New("ButtonControl", {"LEFT",self.anchorTopBarLeft,"RIGHT"}, 0, 0, 60, 20, "<< Back", function()
		if self.unsaved then
			main:OpenPopup(280, 100, "Save Changes", {
				common.New("LabelControl", nil, 0, 20, 0, 16, "^7This build has unsaved changes.\nDo you want to save them now?"),
				common.New("ButtonControl", nil, -90, 70, 80, 20, "Save", function()
					self:SaveDBFile()
					main:ClosePopup()
					main:SetMode("LIST", self.buildName)
				end),
				common.New("ButtonControl", nil, 0, 70, 80, 20, "Don't Save", function()
					main:ClosePopup()
					main:SetMode("LIST", self.buildName)
				end),
				common.New("ButtonControl", nil, 90, 70, 80, 20, "Cancel", function()
					main:ClosePopup()
				end),
			})
		else
			main:SetMode("LIST", self.buildName)
		end
	end)
	self.controls.buildName = common.New("Control", {"LEFT",self.controls.back,"RIGHT"}, 8, 0, 0, 20)
	self.controls.buildName.Draw = function(control)
		local x, y = control:GetPos()
		local bnw = DrawStringWidth(16, "VAR", self.buildName)
		control.width = bnw + 98
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
		return self.unsaved
	end
	self.controls.saveAs = common.New("ButtonControl", {"LEFT",self.controls.save,"RIGHT"}, 8, 0, 70, 20, "Save As", function()
		local newFileName, newBuildName
		local popup
		popup = main:OpenPopup(370, 100, "Save As", {
			common.New("LabelControl", nil, 0, 20, 0, 16, "^7Enter new build name:"),
			edit = common.New("EditControl", nil, 0, 40, 350, 20, self.buildName, nil, "[%w _+-.()'\"]", 50, function(buf)
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
	end)

	-- Controls: top bar, right side
	self.anchorTopBarRight = common.New("Control", nil, function() return main.screenW / 2 + 6 end, 4, 0, 20)
	self.controls.pointDisplay = common.New("Control", {"RIGHT",self.anchorTopBarRight,"LEFT"}, -12, 0, 0, 20)
	self.controls.pointDisplay.Draw = function(control)
		local x, y = control:GetPos()
		local used, ascUsed = self.spec:CountAllocNodes()
		local usedMax = 120 + (self.calcsTab.mainOutput.ExtraPoints or 0)
		local ascMax = 8
		local str = string.format("%s%3d / %3d   %s%d / %d", used > usedMax and "^1" or "^7", used, usedMax, ascUsed > ascMax and "^1" or "^7", ascUsed, ascMax)
		local strW = DrawStringWidth(16, "FIXED", str) + 6
		control.width = strW + 2
		SetDrawColor(1, 1, 1)
		DrawImage(nil, x, y, strW + 2, 20)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, x + 1, y + 1, strW, 18)
		SetDrawColor(1, 1, 1)
		DrawString(x + 4, y + 2, "LEFT", 16, "FIXED", str)
		if control:IsMouseInBounds() then
			SetDrawLayer(nil, 10)
			main:AddTooltipLine(16, "Required level: "..m_max(1, (100 + used - usedMax)))
			main:DrawTooltip(x, y, control.width, control.height, main.viewPort)
			SetDrawLayer(nil, 0)
		end
	end
	self.controls.characterLevel = common.New("EditControl", {"LEFT",self.anchorTopBarRight,"RIGHT"}, 0, 0, 106, 20, "", "Level", "[%d]", 3, function(buf)
		self.characterLevel = tonumber(buf) or 1
		self.buildFlag = true
	end)
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
	self.controls.mainSkillPart = common.New("DropDownControl", {"TOPLEFT",self.controls.mainSocketGroup,"BOTTOMLEFT"}, 0, 20, 100, 18, nil, function(index)
		local mainSocketGroup = self.skillsTab.socketGroupList[self.mainSocketGroup]
		mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeGem.srcGem.skillPart = index
		self.modFlag = true
		self.buildFlag = true
	end)
	self.controls.statBox = common.New("TextListControl", {"TOPLEFT",self.controls.mainSocketGroup,"BOTTOMLEFT"}, 0, 42, 300, 0, {{x=170,align="RIGHT_X"},{x=174,align="LEFT"}})
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
		{ mod = "AverageHit", label = "Average Hit", fmt = ".1f", compPercent = true },
		{ mod = "Speed", label = "Attack Rate", fmt = ".2f", compPercent = true, flag = "attack" },
		{ mod = "Speed", label = "Cast Rate", fmt = ".2f", compPercent = true, flag = "spell" },
		{ mod = "CritChance", label = "Crit Chance", fmt = ".2f%%" },
		{ mod = "CritMultiplier", label = "Crit Multiplier", fmt = "d%%", pc = true, condFunc = function(v,o) return o.CritChance > 0 end },
		{ mod = "HitChance", label = "Hit Chance", fmt = "d%%", flag = "attack" },
		{ mod = "TotalDPS", label = "Total DPS", fmt = ".1f", compPercent = true, flag = "notAverage" },
		{ mod = "TotalDot", label = "DoT DPS", fmt = ".1f", compPercent = true },
		{ mod = "BleedDPS", label = "Bleed DPS", fmt = ".1f", compPercent = true },
		{ mod = "IgniteDPS", label = "Ignite DPS", fmt = ".1f", compPercent = true },
		{ mod = "PoisonDPS", label = "Poison DPS", fmt = ".1f", compPercent = true },
		{ mod = "PoisonDamage", label = "Total Damage per Poison", fmt = ".1f", compPercent = true },
		{ mod = "ManaCost", label = "Mana Cost", fmt = "d", compPercent = true, condFunc = function() return true end },
		{ },
		{ mod = "Str", label = "Strength", fmt = "d" },
		{ mod = "Dex", label = "Dexterity", fmt = "d" },
		{ mod = "Int", label = "Intelligence", fmt = "d" },
		{ },
		{ mod = "Life", label = "Total Life", fmt = "d", compPercent = true },
		{ mod = "Spec:LifeInc", label = "%Inc Life from Tree", fmt = "d%%", condFunc = function(v,o) return v > 0 and o.Life > 1 end },
		{ mod = "LifeUnreserved", label = "Unreserved Life", fmt = "d", condFunc = function(v,o) return v < o.Life end, compPercent = true },
		{ mod = "LifeUnreservedPercent", label = "Unreserved Life", fmt = "d%%", condFunc = function(v,o) return v < 100 end },
		{ mod = "LifeRegen", label = "Life Regen", fmt = ".1f" },
		{ },
		{ mod = "Mana", label = "Total Mana", fmt = "d", compPercent = true },
		{ mod = "Spec:ManaInc", label = "%Inc Mana from Tree", fmt = "d%%" },
		{ mod = "ManaUnreserved", label = "Unreserved Mana", fmt = "d", condFunc = function(v,o) return v < o.Mana end, compPercent = true },
		{ mod = "ManaUnreservedPercent", label = "Unreserved Mana", fmt = "d%%", condFunc = function(v,o) return v < 100 end },
		{ mod = "ManaRegen", label = "Mana Regen", fmt = ".1f" },
		{ },
		{ mod = "EnergyShield", label = "Energy Shield", fmt = "d", compPercent = true },
		{ mod = "Spec:EnergyShieldInc", label = "%Inc ES from Tree", fmt = "d%%" },
		{ mod = "EnergyShieldRegen", label = "Energy Shield Regen", fmt = ".1f" },
		{ mod = "Evasion", label = "Evasion rating", fmt = "d", compPercent = true },
		{ mod = "Spec:EvasionInc", label = "%Inc Evasion from Tree", fmt = "d%%" },
		{ mod = "EvadeChance", label = "Evade Chance", fmt = "d%%" },
		{ mod = "Armour", label = "Armour", fmt = "d", compPercent = true },
		{ mod = "Spec:ArmourInc", label = "%Inc Armour from Tree", fmt = "d%%" },
		{ mod = "BlockChance", label = "Block Chance", fmt = "d%%" },
		{ mod = "SpellBlockChance", label = "Spell Block Chance", fmt = "d%%" },
		{ mod = "AttackDodgeChance", label = "Attack Dodge Chance", fmt = "d%%" },
		{ mod = "SpellDodgeChance", label = "Spell Dodge Chance", fmt = "d%%" },
		{ },
		{ mod = "FireResist", label = "Fire Resistance", fmt = "d%%", condFunc = function() return true end },
		{ mod = "ColdResist", label = "Cold Resistance", fmt = "d%%", condFunc = function() return true end },
		{ mod = "LightningResist", label = "Lightning Resistance", fmt = "d%%", condFunc = function() return true end },
		{ mod = "ChaosResist", label = "Chaos Resistance", fmt = "d%%", condFunc = function() return true end },
		{ mod = "FireResistOverCap", label = "Fire Res. Over Max", fmt = "d%%" },
		{ mod = "ColdResistOverCap", label = "Cold Res. Over Max", fmt = "d%%" },
		{ mod = "LightningResistOverCap", label = "Lightning Res. Over Max", fmt = "d%%" },
		{ mod = "ChaosResistOverCap", label = "Chaos Res. Over Max", fmt = "d%%" },
	}

	self.viewMode = "TREE"

	self.dbFileName = dbFileName
	self.buildName = buildName

	self.characterLevel = 1
	self.banditNormal = "None"
	self.banditCruel = "None"
	self.banditMerciless = "None"

	-- List of modules with Load/Save methods
	-- These will be called to load or save data to their respective sections of the build XML file
	self.savers = {
		["Build"] = self,
		["Config"] = self.configTab,
		["Spec"] = self.spec,
		["TreeView"] = self.treeTab.viewer,
		["Items"] = self.itemsTab,
		["Skills"] = self.skillsTab,
		["Calcs"] = self.calcsTab,
	}

	ConPrintf("Loading '%s'...", dbFileName)
	if self:LoadDBFile() then
		main:SetMode("LIST", dbFileName)
		return
	end

	if next(self.configTab.input) == nil then
		-- Check for old calcs tab settings
		self.configTab:ImportCalcSettings()
	end

	-- Build calculation output tables
	self.calcsTab:BuildOutput()
	self:RefreshStatList()

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
		self.calcsTab:BuildPower(self)
	end
	SetProfiling(false)
	ConPrintf("Power build time: %d msec", GetTime() - start)
	--]]

	self.abortSave = false
end

function buildMode:Shutdown()
	if launch.devMode and not self.abortSave then
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
	self.modFlag = false
end

function buildMode:OnFrame(inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if IsKeyDown("CTRL") then
				if event.key == "s" then
					self:SaveDBFile()
					inputEvents[id] = nil
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

	-- Update contents of main skill dropdown
	wipeTable(self.controls.mainSocketGroup.list)
	for i, socketGroup in pairs(self.skillsTab.socketGroupList) do
		self.controls.mainSocketGroup.list[i] = { val = i, label = socketGroup.displayLabel }
	end
	if #self.controls.mainSocketGroup.list == 0 then
		self.controls.mainSocketGroup.list[1] = { val = 1, label = "<No skills added yet>" }
		self.controls.mainSkill.shown = false
		self.controls.mainSkillPart.shown = false
	else
		local mainSocketGroup = self.skillsTab.socketGroupList[self.mainSocketGroup]
		wipeTable(self.controls.mainSkill.list)
		for i, activeSkill in ipairs(mainSocketGroup.displaySkillList) do
			t_insert(self.controls.mainSkill.list, { val = i, label = activeSkill.activeGem.name })
		end
		self.controls.mainSkill.enabled = #mainSocketGroup.displaySkillList > 1
		self.controls.mainSkill.sel = mainSocketGroup.mainActiveSkill
		self.controls.mainSkill.shown = true
		self.controls.mainSkillPart.shown = false
		if mainSocketGroup.displaySkillList[1] then
			local activeGem = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeGem
			if activeGem and activeGem.data.parts and #activeGem.data.parts > 1 then
				self.controls.mainSkillPart.shown = true
				wipeTable(self.controls.mainSkillPart.list)
				for i, part in ipairs(activeGem.data.parts) do
					t_insert(self.controls.mainSkillPart.list, { val = i, label = part.name })
				end
				self.controls.mainSkillPart.sel = activeGem.srcGem.skillPart or 1
			end
		end
	end
	self.controls.mainSocketGroup.sel = self.mainSocketGroup

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

	self.unsaved = self.modFlag or self.configTab.modFlag or self.spec.modFlag or self.skillsTab.modFlag or self.itemsTab.modFlag or self.calcsTab.modFlag

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

	self:DrawControls(viewPort)
end

function buildMode:RefreshStatList()
	-- Build list of side bar stats
	wipeTable(self.controls.statBox.list)
	for index, statData in ipairs(self.displayStats) do
		if statData.mod then
			if not statData.flag or self.calcsTab.mainEnv.mainSkill.skillFlags[statData.flag] then 
				local modVal = self.calcsTab.mainOutput[statData.mod]
				if modVal and ((statData.condFunc and statData.condFunc(modVal,self.calcsTab.mainOutput)) or (not statData.condFunc and modVal ~= 0)) then
					t_insert(self.controls.statBox.list, { height = 16,  "^7"..statData.label..":", string.format("%s%"..statData.fmt, modVal >= 0 and "^7" or data.colorCodes.NEGATIVE, modVal * (statData.pc and 100 or 1)) })
				end
			end
		else
			t_insert(self.controls.statBox.list, { height = 10 })
		end
	end
end

-- Compare values of all display stats between the two output tables, and add any changed stats to the tooltip
-- Adds the provided header line before the first stat line, if any are added
-- Returns the number of stat lines added
function buildMode:AddStatComparesToTooltip(baseOutput, compareOutput, header)
	local count = 0
	for _, statData in ipairs(self.displayStats) do
		if statData.mod and (not statData.flag or self.calcsTab.mainEnv.mainSkill.skillFlags[statData.flag]) then
			local diff = (compareOutput[statData.mod] or 0) - (baseOutput[statData.mod] or 0)
			if diff > 0.001 or diff < -0.001 then
				if count == 0 then
					main:AddTooltipLine(14, header)
				end
				local line = string.format("%s%+"..statData.fmt.." %s", diff > 0 and data.colorCodes.POSITIVE or data.colorCodes.NEGATIVE, diff * (statData.pc and 100 or 1), statData.label)
				if statData.compPercent and (baseOutput[statData.mod] or 0) ~= 0 and (compareOutput[statData.mod] or 0) ~= 0 then
					line = line .. string.format(" (%+.1f%%)", (compareOutput[statData.mod] or 0) / (baseOutput[statData.mod] or 0) * 100 - 100)
				end
				main:AddTooltipLine(14, line)
				count = count + 1
			end
		end
	end
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
			local saver = self.savers[node.elem]
			if saver then
				if saver:Load(node, self.dbFileName) then
					return true
				end
			end
		end
	end
end

function buildMode:LoadDBFile()
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
	local xmlText = self:SaveDB(self.dbFileName)
	if not xmlText then
		return true
	end
	local file = io.open(self.dbFileName, "w+")
	if not file then
		return true
	end
	file:write(xmlText)
	file:close()
end

return buildMode