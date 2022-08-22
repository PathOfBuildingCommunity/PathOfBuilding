-- Path of Building
--
-- Module: Party Tab
-- Party tab for the current build.
--
local pairs = pairs
local ipairs = ipairs
local s_format = string.format
local t_insert = table.insert

local PartyTabClass = newClass("PartyTab", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

	self.build = build
	
	self.processedInput = { Aura = {}, Curse = {} }
	self.enemyModList = new("ModList")
	self.buffExports = {}
	self.enableExportBuffs = true

	self.lastContentAura = ""
	self.lastContentCurse = ""
	self.lastContentEnemyCond = ""
	self.lastContentEnemyMods = ""
	self.lastEnableExportBuffs = true
	self.showColorCodes = false

	local notesDesc = [[^7Party stuff	DO NOT EDIT ANY BOXES UNLESS YOU KNOW WHAT YOU ARE DOING, use copy/paste instead, or import
	To import a build that build must have been saved with Enable Export ticked
	]]
	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, 16, notesDesc)
	self.controls.notesDesc.width = function()
		return self.width / 2 - 16
	end
	self.controls.importCodeHeader = new("LabelControl", {"TOPLEFT",self.controls.notesDesc,"BOTTOMLEFT"}, 0, 26, 0, 16, "^7To import a build, enter code here: (NOT URL)")
	
	local importCodeHandle = function (buf)
		self.importCodeSite = nil
		self.importCodeDetail = ""
		self.importCodeXML = nil
		self.importCodeValid = false

		if #buf == 0 then
			return
		end

		self.importCodeDetail = colorCodes.NEGATIVE.."Invalid input"

		local xmlText = Inflate(common.base64.decode(buf:gsub("-","+"):gsub("_","/")))
		if not xmlText then
			return
		end
		if launch.devMode and IsKeyDown("SHIFT") then
			Copy(xmlText)
		end
		self.importCodeValid = true
		self.importCodeDetail = colorCodes.POSITIVE.."Code is valid"
		self.importCodeXML = xmlText
	end
	
	self.controls.importCodeIn = new("EditControl", {"TOPLEFT",self.controls.importCodeHeader,"BOTTOMLEFT"}, 0, 4, 328, 20, "", nil, nil, nil, importCodeHandle)
	self.controls.importCodeIn.width = function()
		return (self.width > 880) and 328 or (self.width / 2 - 100)
	end
	self.controls.importCodeIn.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
	self.controls.importCodeState = new("LabelControl", {"LEFT",self.controls.importCodeIn,"RIGHT"}, 8, 0, 0, 16)
	self.controls.importCodeState.label = function()
		return self.importCodeDetail or ""
	end
	self.controls.importCodeMode = new("DropDownControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, 0, 4, 160, 20, { "Aura", "Curse", "EnemyConditions", "EnemyMods", "All" })
	self.controls.importCodeMode.enabled = function()
		return self.importCodeValid
	end
	self.controls.importCodeGo = new("ButtonControl", {"LEFT",self.controls.importCodeMode,"RIGHT"}, 8, 0, 160, 20, "Import", function()
		if self.importCodeSite and not self.importCodeXML then
			return
		end
		
		-- Parse the XML
		local dbXML, errMsg = common.xml.ParseXML(self.importCodeXML)
		if not dbXML then
			launch:ShowErrMsg("^1Error loading '%s': %s", fileName, errMsg)
			return
		elseif dbXML[1].elem ~= "PathOfBuilding" then
			launch:ShowErrMsg("^1Error parsing '%s': 'PathOfBuilding' root element missing", fileName)
			return
		end

		-- Load data
		for _, node in ipairs(dbXML[1]) do
			if type(node) == "table" and node.elem == "Party" then
				if self.controls.importCodeMode.selIndex == 1 then
					self.controls.editAuras:SetText(node[6].attrib.string)
					wipeTable(self.processedInput["Aura"])
					self.processedInput["Aura"] = {}
					self:ParseBuffs(self.processedInput["Aura"], node[6].attrib.string, "Aura")
				elseif self.controls.importCodeMode.selIndex == 2 then
					self.controls.editCurses:SetText(node[7].attrib.string)
					wipeTable(self.processedInput["Curse"])
					self.processedInput["Curse"] = {}
					self:ParseBuffs(self.processedInput["Curse"], node[7].attrib.string, "Curse")
				elseif self.controls.importCodeMode.selIndex == 3 then
					self.controls.enemyCond:SetText(node[8].attrib.string)
				elseif self.controls.importCodeMode.selIndex == 4 then
					self.controls.enemyMods:SetText(node[9].attrib.string)
				elseif self.controls.importCodeMode.selIndex == 5 then
					self.controls.editAuras:SetText(node[6].attrib.string)
					wipeTable(self.processedInput["Aura"])
					self.processedInput["Aura"] = {}
					self:ParseBuffs(self.processedInput["Aura"], node[6].attrib.string, "Aura")
					self.controls.editCurses:SetText(node[7].attrib.string)
					wipeTable(self.processedInput["Curse"])
					self.processedInput["Curse"] = {}
					self:ParseBuffs(self.processedInput["Curse"], node[7].attrib.string, "Curse")
					self.controls.enemyCond:SetText(node[8].attrib.string)
					self.controls.enemyMods:SetText(node[9].attrib.string)
				end
				self.build.buildFlag = true 
				break
			end
		end
		
	end)
	self.controls.importCodeGo.enabled = function()
		return self.importCodeValid and not self.importCodeFetching
	end
	self.controls.importCodeGo.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
	
	self.controls.rebuild = new("ButtonControl", {"LEFT",self.controls.importCodeGo,"RIGHT"}, 8, 0, 160, 20, "Rebuild", function() 
		wipeTable(self.processedInput)
		wipeTable(self.enemyModList)
		self.processedInput = { Aura = {}, Curse = {} }
		self.enemyModList = new("ModList")
		self:ParseBuffs(self.processedInput["Aura"], self.controls.editAuras.buf, "Aura")
		self:ParseBuffs(self.processedInput["Curse"], self.controls.editCurses.buf, "Curse")
		self:ParseBuffs(self.enemyModList, self.controls.enemyCond.buf, "EnemyConditions")
		self:ParseBuffs(self.enemyModList, self.controls.enemyMods.buf, "EnemyMods")
		self.build.buildFlag = true 
	end)
	self.controls.rebuild.x = function()
		return (self.width > 1260) and 8 or (-328)
	end
	self.controls.rebuild.y = function()
		return (self.width > 1260) and 0 or 28
	end
	self.controls.enableExportBuffs = new("CheckBoxControl", {"LEFT",self.controls.rebuild,"RIGHT"}, 100, 0, 18, "Enable Export", function(state)
		self.enableExportBuffs = state
	end, "Enables the exporting of auras, cruses and modifiers to the enemy", false)

	self.controls.editAuras = new("EditControl", {"TOPLEFT",self.controls.importCodeMode,"TOPLEFT"}, 0, 40, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editAuras.width = function()
		return self.width / 2 - 16
	end
	self.controls.editAuras.y = function()
		return (self.width > 1260) and 40 or 68
	end
	self.controls.editAuras.height = function()
		return self.height - 148 - ((self.width > 1260) and 28 or 0)
	end

	self.controls.enemyCond = new("EditControl", {"TOPLEFT",self.controls.notesDesc,"TOPRIGHT"}, 8, 0, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.enemyCond.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyCond.height = function()
		return (self.controls.enemyCond.hasFocus and (self.height - 270) or 116)
	end

	self.controls.enemyMods = new("EditControl", {"TOPLEFT",self.controls.enemyCond,"BOTTOMLEFT"}, 0, 10, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.enemyMods.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyMods.height = function()
		return (self.controls.enemyMods.hasFocus and (self.height - 270) or 116)
	end

	self.controls.editCurses = new("EditControl", {"TOPLEFT",self.controls.enemyMods,"BOTTOMLEFT"}, 0, 10, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editCurses.width = function()
		return self.width / 2 - 16
	end
	self.controls.editCurses.height = function()
		return ((not self.controls.enemyCond.hasFocus and not self.controls.enemyMods.hasFocus) and (self.height - 148) or 116)
	end
	self:SelectControl(self.controls.editAuras)
end)

function PartyTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if node.elem == "TabStuff" then
			if node.attrib.name == "enableExportBuffs" then
				self.enableExportBuffs = node.attrib.string == "true"
				self.controls.enableExportBuffs.state = self.enableExportBuffs
			end
		elseif node.elem == "ImportedText" then
			if not node.attrib.name then
				ConPrintf("missing name")
			elseif node.attrib.name == "Aura" then
				self.controls.editAuras:SetText(node.attrib.string)
				self:ParseBuffs(self.processedInput["Aura"], node.attrib.string, "Aura")
			elseif node.attrib.name == "Curse" then
				self.controls.editCurses:SetText(node.attrib.string)
				self:ParseBuffs(self.processedInput["Curse"], node.attrib.string, "Curse")
			elseif node.attrib.name == "EnemyConditions" then
				self.controls.enemyCond:SetText(node.attrib.string)
				self:ParseBuffs(self.enemyModList, node.attrib.string, "EnemyConditions")
			elseif node.attrib.name == "EnemyMods" then
				self.controls.enemyMods:SetText(node.attrib.string)
				self:ParseBuffs(self.enemyModList, node.attrib.string, "EnemyMods")
			end
		elseif node.elem == "ExportedBuffs" then
			if not node.attrib.name then
				ConPrintf("missing name")
			end
			if node.attrib.name ~= "EnemyConditions" and node.attrib.name ~= "EnemyMods" then
				self:ParseBuffs(self.buffExports, node.attrib.string, node.attrib.name)
			end
			--self:ParseBuffs(self.buffExports, node.attrib.string, "Aura")
			--self:ParseBuffs(self.buffExports, node.attrib.string, "Curse")
			--self:ParseBuffs(self.buffExports, node.attrib.string, "EnemyConditions")
			--self:ParseBuffs(self.buffExports, node.attrib.string, "EnemyMods")
		end
	end
	self.lastContentAura = self.controls.editAuras.buf
	self.lastContentCurse = self.controls.editCurses.buf
	self.lastContentEnemyCond = self.controls.enemyCond.buf
	self.lastContentEnemyMods = self.controls.enemyMods.buf
	self.lastEnableExportBuffs = self.enableExportBuffs
end

function PartyTabClass:Save(xml)
	local child = { elem = "TabStuff", attrib = { name = "enableExportBuffs" } }
	child.attrib.string = tostring(self.enableExportBuffs)
	t_insert(xml, child)
	local child = { elem = "ImportedText", attrib = { name = "Aura" } }
	child.attrib.string = self.controls.editAuras.buf
	t_insert(xml, child)
	child = { elem = "ImportedText", attrib = { name = "Curse" } }
	child.attrib.string = self.controls.editCurses.buf
	t_insert(xml, child)
	child = { elem = "ImportedText", attrib = { name = "EnemyConditions" } }
	child.attrib.string = self.controls.enemyCond.buf
	t_insert(xml, child)
	child = { elem = "ImportedText", attrib = { name = "EnemyMods" } }
	child.attrib.string = self.controls.enemyMods.buf
	t_insert(xml, child)
	child = { elem = "ExportedBuffs", attrib = { name = "Aura" } }
	child.attrib.string = self:exportBuffs("Aura")
	t_insert(xml, child)
	child = { elem = "ExportedBuffs", attrib = { name = "Curse" } }
	child.attrib.string = self:exportBuffs("Curse")
	t_insert(xml, child)
	child = { elem = "ExportedBuffs", attrib = { name = "EnemyConditions" } }
	child.attrib.string = self:exportBuffs("EnemyConditions")
	t_insert(xml, child)
	child = { elem = "ExportedBuffs", attrib = { name = "EnemyMods" } }
	child.attrib.string = self:exportBuffs("EnemyMods")
	t_insert(xml, child)
	self.lastContentAura = self.controls.editAuras.buf
	self.lastContentCurse = self.controls.editCurses.buf
	self.lastContentEnemyCond = self.controls.enemyCond.buf
	self.lastContentEnemyMods = self.controls.enemyMods.buf
	self.lastEnableExportBuffs = self.enableExportBuffs
end

function PartyTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				if self.controls.editAuras.hasFocus then
					self.controls.editAuras:Undo()
				elseif self.controls.editCurses.hasFocus then
					self.controls.editCurses:Undo()
				end
			elseif event.key == "y" and IsKeyDown("CTRL") then
				if self.controls.editAuras.hasFocus then
					self.controls.editAuras:Redo()
				elseif self.controls.editCurses.hasFocus then
					self.controls.editCurses:Redo()
				end
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)

	self.modFlag = (self.lastContentAura ~= self.controls.editAuras.buf 
			and self.lastContentCurse ~= self.controls.editCurses.buf
			and self.lastContentEnemyCond ~= self.controls.enemyCond.buf
			and self.lastContentEnemyMods ~= self.controls.enemyMods.buf
			and self.lastEnableExportBuffs ~= self.enableExportBuffs)
end

function PartyTabClass:ParseBuffs(list, buf, buffType)
	if buffType == "EnemyConditions" then
		for line in buf:gmatch("([^\n]*)\n?") do
			list:NewMod(line:gsub("Condition:", "Condition:Party:"), "FLAG", true, "Party")
		end
	elseif buffType == "EnemyMods" then
		local modeName = true
		local currentName
		for line in buf:gmatch("([^\n]*)\n?") do
			if modeName then
				currentName = line
				modeName = false
			else
				modeName = true
				local modStrings = {}
				local modType = currentModType
				for line2 in line:gmatch("([^|]*)|?") do
					t_insert(modStrings, line2)
				end
				local tags = nil -- modStrings[7]
				list:NewMod(modStrings[3], modStrings[4], tonumber(modStrings[1]), "Party"..modStrings[2], ModFlag[modStrings[5]] or 0, KeywordFlag[modStrings[6]] or 0, tags)
			end
		end
	end
	local mode = "Name"
	if buffType == "Curse" then
		mode = "CurseLimit"
	end
	local currentName
	local currentEffect
	local isMark
	local currentModType = "Unknown"
	for line in buf:gmatch("([^\n]*)\n?") do
		if mode == "CurseLimit" and line ~= "" then
			list.limit = tonumber(line)
			mode = "Name"
		elseif mode == "Name" and line ~= "" then
			currentName = line
			if line == "extraAura" then
				currentModType = "extraAura"
				mode = "Stats"
			else
				mode = "Effect"
			end
		elseif mode == "Effect" then
			currentEffect = tonumber(line)
			if buffType == "Curse" then
				mode = "isMark"
			else
				mode = "Stats"
			end
		elseif mode == "isMark" then
			isMark = line=="true"
			mode = "Stats"
		elseif line == "---" then
			mode = "Name"
		else
			if line:find("|") then
				local modStrings = {}
				local modType = currentModType
				for line2 in line:gmatch("([^|]*)|?") do
					t_insert(modStrings, line2)
				end
				local mod = {
					value = (modStrings[1] == "true" and true) or tonumber(modStrings[1]) or 0,
					source = modStrings[2],
					name = modStrings[3],
					type = modStrings[4],
					flags = ModFlag[modStrings[5]] or 0,
					keywordFlags = KeywordFlag[modStrings[6]] or 0,
				}
				local extraTags = {} -- should parse this correctly instead of string match
				if modStrings[7]:find("type=GlobalEffect/effectType=AuraDebuff") then
					t_insert(extraTags, {
						type = "GlobalEffect",
						effectType = "AuraDebuff"
					})
					modType = "AuraDebuff"
					currentModType = "AuraDebuff"
				elseif modStrings[7]:find("type=GlobalEffect/effectType=Aura") then
					t_insert(extraTags, {
						type = "GlobalEffect",
						effectType = "Aura"
					})
					modType = "Aura"
					currentModType = "Aura"
				elseif modStrings[7]:find("type=GlobalEffect/effectType=Curse") then
					t_insert(extraTags, {
						type = "GlobalEffect",
						effectType = "Curse"
					})
					modType = "Curse"
					currentModType = "Curse"
				end
				mod[1] = extraTags[1]
				if not list[modType] then
					list[modType] = {}
					list[modType][currentName] = {
						modList = new("ModList"),
						effectMult = currentEffect
					}
					if isMark then
						list[modType][currentName].isMark = true
					end
				elseif not list[modType][currentName] then
					list[modType][currentName] = {
						modList = new("ModList"),
						effectMult = currentEffect
					}
					if isMark then
						list[modType][currentName].isMark = true
					end
				end
				list[modType][currentName].modList:AddMod(mod)
			end
		end
	end
end

function PartyTabClass:setBuffExports(buffExports)
	if not self.enableExportBuffs then
		return
	end
	wipeTable(self.buffExports)
	self.buffExports = copyTable(buffExports, true)
end

function PartyTabClass:exportBuffs(buffType)
	if not self.enableExportBuffs or not self.buffExports or not self.buffExports[buffType] then
		return ""
	end
	if self.buffExports[buffType].ConvertedToText then
		return self.buffExports[buffType].string
	end
	local buf = ((buffType == "Curse") and tostring(self.buffExports["CurseLimit"])) or ""
	for buffName, buff in pairs(self.buffExports[buffType]) do
		if #buf > 0 then
			buf = buf.."\n"
		end
		buf = buf..buffName
		if buffType == "Curse" then
			buf = buf.."\n"..tostring(buff.effectMult * 100)
			if buff.isMark then
				buf = buf.."\ntrue"
			else
				buf = buf.."\nfalse"
			end
		elseif buffType == "Aura" and buffName ~= "extraAura" then
			buf = buf.."\n"..tostring(buff.effectMult * 100)
		end
		if buffType == "Curse" or buffType == "Aura"  then
			for _, mod in ipairs(buff.modList) do
				buf = buf.."\n"..tostring(mod.value).."|"..mod.source.."|"..modLib.formatModParams(mod)
			end
			buf = buf.."\n---"
		elseif buffType == "EnemyMods" then
			buf = buf.."\n"..tostring(buff.value).."|"..buff.source.."|"..modLib.formatModParams(buff)
		end
	end
	wipeTable(self.buffExports[buffType])
	self.buffExports[buffType] = { ConvertedToText = true }
	self.buffExports[buffType].string = buf
	return buf
end