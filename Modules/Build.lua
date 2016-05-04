local launch, cfg, main = ...

local ipairs = ipairs
local t_insert = table.insert

local buildMode = { }

buildMode.controls = { }

t_insert(buildMode.controls, common.newButton(4, 4, 60, 20, "<< Back", function()
	main:SetMode("LIST", buildMode.dbFileName)
end))

t_insert(buildMode.controls, common.newButton(4 + 68, 4, 60, 20, "Tree", function()
	buildMode.viewMode = "TREE"
end, function()
	return buildMode.viewMode ~= "TREE"
end))
	
t_insert(buildMode.controls, common.newButton(4 + 68*2, 4, 60, 20, "Items", function()
	buildMode.viewMode = "ITEMS"
end, function()
	return buildMode.viewMode ~= "ITEMS"
end))

t_insert(buildMode.controls, common.newButton(4 + 68*3, 4, 60, 20, "Calcs", function()
	buildMode.viewMode = "CALCS"
end, function()
	return buildMode.viewMode ~= "CALCS"
end))

t_insert(buildMode.controls, {
	x = 4 + 68*4,
	y = 4,
	Draw = function(self)
		local buildName = buildMode.dbFileName:gsub(".xml","")
		local bnw = DrawStringWidth(16, "VAR", buildName)
		SetDrawColor(0.5, 0.5, 0.5)
		DrawImage(nil, self.x + 91, self.y, bnw + 6, 20)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, self.x + 92, self.y + 1, bnw + 4, 18)
		SetDrawColor(1, 1, 1)
		DrawString(self.x, self.y + 2, "LEFT", 16, "VAR", "Current build:  "..buildName.."   "..((buildMode.calcs.modFlag or buildMode.spec.modFlag or buildMode.items.modFlag) and "(Unsaved)" or ""))
	end,
})

buildMode.controls.pointDisplay = {
	x = 0,
	y = 4,
	Draw = function(self)
		local used, ascUsed = buildMode.spec:CountAllocNodes()
		local usedMax = 120 + (buildMode.calcs.output.total_extraPoints or 0)
		local ascMax = 6
		local str = string.format("%s%3d / %3d   %s%d / %d", used > usedMax and "^1" or "^7", used, usedMax, ascUsed > ascMax and "^1" or "^7", ascUsed, ascMax)
		local strW = DrawStringWidth(16, "FIXED", str) + 6
		SetDrawColor(1, 1, 1)
		DrawImage(nil, self.x, self.y, strW + 2, 20)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, self.x + 1, self.y + 1, strW, 18)
		SetDrawColor(1, 1, 1)
		DrawString(self.x + 4, self.y + 2, "LEFT", 16, "FIXED", str)
	end,
}

buildMode.controls.classDrop = common.newDropDown(0, 4, 100, 20, nil, function(index, val)
	local classId = main.tree.classNameMap[val]
	if classId ~= buildMode.spec.curClassId then
		if buildMode.spec:IsClassConnected(classId) or buildMode.spec:CountAllocNodes() == 0 then
			buildMode.spec:SelectClass(classId)
			buildMode.spec:AddUndoState()
		else
			launch:ShowPrompt(0, 0, 0, "Changing class to "..val.." will reset your tree.\nThis can be avoided by connecting one of the "..val.." starting nodes to your tree.\n\nPress Y to continue.", function(key)
				if key == "y" then
					buildMode.spec:SelectClass(classId)
					buildMode.spec:AddUndoState()
				end
				return true
			end)
		end
	end
end, function()
	return buildMode.viewMode == "TREE"
end)

buildMode.controls.ascendDrop = common.newDropDown(0, 4, 100, 20, nil, function(index, val)
	local ascendClassId = main.tree.ascendNameMap[val].ascendClassId
	buildMode.spec:SelectAscendClass(ascendClassId)
	buildMode.spec:AddUndoState()
end, function()
	return buildMode.viewMode == "TREE"
end)

buildMode.savers = {
	["Build"] = "",
	["Calcs"] = "calcs",
	["Items"] = "items",
	["Spec"] = "spec",
	["TreeView"] = "treeView",
}

function buildMode:LoadDB()
	local dbXML, errMsg = common.xml.LoadXMLFile(self.dbFileName)
	if not dbXML then
		launch:ShowErrMsg("^1Error loading '%s': %s", self.dbFileName, errMsg)
		return true
	elseif dbXML[1].elem ~= "PathOfBuilding" then
		launch:ShowErrMsg("^1Error parsing '%s': 'PathOfBuilding' root element missing", self.dbFileName)
		return true
	end
	for _, node in ipairs(dbXML[1]) do
		if type(node) == "table" then
			local key = self.savers[node.elem]
			if key then
				local saver = self[key] or self
				if saver:Load(node, self.dbFileName) then
					return true
				end
			end
		end
	end
end
function buildMode:SaveDB()
	local dbXML = { elem = "PathOfBuilding" }
	for elem, key in pairs(self.savers) do
		local saver = self[key] or self
		local node = { elem = elem }
		saver:Save(node)
		t_insert(dbXML, node)
	end
	local res, errMsg = common.xml.SaveXMLFile(dbXML, self.dbFileName)
	if not res then
		launch:ShowErrMsg("Error saving '%s': %s", self.dbFileName, errMsg)
		return true
	end
end

function buildMode:Load(xml, fileName)
	if xml.attrib.viewMode then
		self.viewMode = xml.attrib.viewMode
	end
end
function buildMode:Save(xml)
	xml.attrib = {
		viewMode = self.viewMode,
		className = self.tree.classes[self.spec.curClassId].name,
		ascendClassName = self.spec.curAscendClassId > 0 and self.tree.classes[self.spec.curClassId].classes[tostring(self.spec.curAscendClassId)].name,
		level = tostring(self.calcs.input.player_level or 1)
	}
end

function buildMode:Init(dbFileName)
	self.dbFileName = dbFileName
	ConPrintf("Loading '%s'...", dbFileName)

	self.abortSave = true

	self.items = LoadModule("Modules/Items", launch, cfg, main)
	self.items:Init(self)
	self.calcs = LoadModule("Modules/Calcs", launch, cfg, main)
	self.calcs:Init(self)
	self.tree = main.tree
	self.spec = main.SpecClass.NewSpec(main.tree)
	self.treeView = main.TreeViewClass.NewTreeView()

	wipeTable(self.controls.classDrop.list)
	for classId, class in pairs(self.tree.classes) do
		t_insert(self.controls.classDrop.list, class.name)
	end
	table.sort(self.controls.classDrop.list)

	self.displayStats = {
		{ mod = "total_avg", label = "Average Hit", fmt = ".1f" },
		{ mod = "total_speed", label = "Speed", fmt = ".2f" },
		{ mod = "total_critChance", label = "Crit Chance", fmt = ".2f%%", pc = true },
		{ mod = "total_critMultiplier", label = "Crit Multiplier", fmt = "d%%", pc = true },
		{ mod = "total_hitChance", label = "Hit Chance", fmt = "d%%", pc = true },
		{ mod = "total_dps", label = "Total DPS", fmt = ".1f" },
		{ mod = "ignite_dps", label = "Ignite DPS", fmt = ".1f" },
		{ mod = "poison_dps", label = "Poison DPS", fmt = ".1f" },
		{ },
		{ mod = "spec_lifeInc", label = "Life %", fmt = "d" },
		{ mod = "total_life", label = "Total Life", fmt = "d" },
		{ },
		{ mod = "total_mana", label = "Total Mana", fmt = "d" },
		{ mod = "total_manaRegen", label = "Mana Regen", fmt = ".1f" },
		{ },
		{ mod = "total_energyShield", label = "Energy Shield", fmt = "d" },
		{ mod = "total_evasion", label = "Evasion rating", fmt = "d" },
		{ mod = "total_armour", label = "Armour", fmt = "d" },
		{ mod = "total_blockChance", label = "Block Chance", fmt = "d%%" },
		{ },
		{ mod = "total_fireResist", label = "Fire Resistance", fmt = "d%%" },
		{ mod = "total_coldResist", label = "Cold Resistance", fmt = "d%%" },
		{ mod = "total_lightningResist", label = "Lightning Resistance", fmt = "d%%" },
		{ mod = "total_chaosResist", label = "Chaos Resistance", fmt = "d%%" },
	}

	self.viewMode = "TREE"

	if self:LoadDB() then
		main:SetMode("LIST", dbFileName)
		return
	end

	--[[local start = GetTime()
	SetProfiling(true)
	for i = 1, 10  do
		self.calcs:BuildPower(self)
	end
	SetProfiling(false)
	ConPrintf("Power build time: %d msec", GetTime() - start)]]

	self.abortSave = false
end

function buildMode:Shutdown()
	if not self.abortSave then
		self:SaveDB()
	end
	self.abortSave = nil

	self.calcs:Shutdown()
	self.calcs = nil
	self.items:Shutdown()
	self.items = nil
	self.spec = nil
	self.treeView = nil
end

function buildMode:OnFrame(inputEvents)
	common.controlsInput(self, inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "s" and IsKeyDown("CTRL") then
				self:SaveDB()
				inputEvents[id] = nil
			end
		end
	end

	local class = main.tree.classes[self.spec.curClassId]
	local ascendClass = class.classes[tostring(self.spec.curAscendClassId)]
	wipeTable(self.controls.ascendDrop.list)
	for _, ascendClass in pairs(main.tree.classes[self.spec.curClassId].classes) do
		t_insert(self.controls.ascendDrop.list, ascendClass.name)
	end
	table.sort(self.controls.ascendDrop.list)

	self.controls.classDrop:SelByValue(class.name)
	self.controls.ascendDrop:SelByValue(ascendClass and ascendClass.name or "None")

	self.controls.pointDisplay.x = cfg.screenW / 2 + 6
	self.controls.classDrop.x = self.controls.pointDisplay.x + 154
	self.controls.ascendDrop.x = self.controls.classDrop.x + self.controls.classDrop.width + 8

	self.calcs:RunControl(self)

	if self.viewMode == "TREE" then
		local viewPort = {
			x = 258,
			y = 32,
			width = cfg.screenW - 258,
			height = cfg.screenH - 32
		}
		self.treeView:DrawTree(self, viewPort, inputEvents)
	elseif self.viewMode == "CALCS" then
		local viewPort = {
			x = 0,
			y = 32,
			width = cfg.screenW,
			height = cfg.screenH - 32
		}
		self.calcs:DrawGrid(viewPort, inputEvents)
	elseif self.viewMode == "ITEMS" then
		local viewPort = {
			x = 258,
			y = 32,
			width = cfg.screenW - 258,
			height = cfg.screenH - 32			
		}
		self.items:DrawItems(viewPort, inputEvents)
	end

	SetDrawColor(0.2, 0.2, 0.2)
	DrawImage(nil, 0, 0, cfg.screenW, 28)
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, 0, 28, cfg.screenW, 4)
	DrawImage(nil, cfg.screenW/2 - 2, 0, 4, 28)
	common.controlsDraw(self, viewPort)
	if self.viewMode ~= "CALCS" then
		SetDrawColor(0.1, 0.1, 0.1)
		DrawImage(nil, 0, 32, 254, cfg.screenH - 32)
		SetDrawColor(0.85, 0.85, 0.85)
		DrawImage(nil, 254, 32, 4, cfg.screenH - 32)
		local y = 36
		for index, data in ipairs(self.displayStats) do
			if data.mod then
				if self.calcs.output[data.mod] and self.calcs.output[data.mod] ~= 0 then
					DrawString(150, y, "RIGHT_X", 16, "VAR", data.label..":")
					DrawString(154, y, "LEFT", 16, "VAR", string.format("%"..data.fmt, self.calcs.output[data.mod] * (data.pc and 100 or 1)))
					y = y + 16
				end
			else
				y = y + 12
			end
		end
	end
end

return buildMode