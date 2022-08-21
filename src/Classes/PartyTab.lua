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
	self.buffExports = {}

	self.lastContentAura = ""
	self.lastContentCurse = ""
	self.showColorCodes = false

	local notesDesc = [[^7Party stuff	DO NOT EDIT ANY BOXES UNLESS YOU KNOW WHAT YOU ARE DOING, use copy/paste instead, or import]]
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
	self.controls.importCodeIn.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
	self.controls.importCodeState = new("LabelControl", {"LEFT",self.controls.importCodeIn,"RIGHT"}, 8, 0, 0, 16)
	self.controls.importCodeState.label = function()
		return self.importCodeDetail or ""
	end
	self.controls.importCodeMode = new("DropDownControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, 0, 4, 160, 20, { "Aura", "Curse" })
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
					self.controls.editAuras:SetText(node[3].attrib.string)
					wipeTable(self.processedInput["Aura"])
					self.processedInput["Aura"] = {}
					self:ParseBuffs(self.processedInput["Aura"], node[3].attrib.string, "Aura")
				elseif self.controls.importCodeMode.selIndex == 2 then
					self.controls.editCurses:SetText(node[4].attrib.string)
					wipeTable(self.processedInput["Curse"])
					self.processedInput["Curse"] = {}
					self:ParseBuffs(self.processedInput["Curse"], node[4].attrib.string, "Curse")
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
		self.processedInput = { Aura = {}, Curse = {} }
		self:ParseBuffs(self.processedInput["Aura"], self.controls.editAuras.buf, "Aura")
		self:ParseBuffs(self.processedInput["Curse"], self.controls.editCurses.buf, "Curse")
		self.build.buildFlag = true 
	end)

	self.controls.editAuras = new("EditControl", {"TOPLEFT",self.controls.importCodeMode,"TOPLEFT"}, 0, 40, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editAuras.width = function()
		return self.width / 2 - 16
	end
	self.controls.editAuras.height = function()
		return self.height - 148
	end

	self.controls.editMisc = new("EditControl", {"TOPLEFT",self.controls.notesDesc,"TOPRIGHT"}, 8, 0, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editMisc.width = function()
		return self.width / 2 - 16
	end
	local extraHeight = function()
		return false
	end
	self.controls.editMisc.height = function()
		return (extraHeight() and (self.height - 148) or 116)
	end

	self.controls.editCurses = new("EditControl", {"TOPLEFT",self.controls.editMisc,"BOTTOMLEFT"}, 0, 10, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editCurses.width = function()
		return self.width / 2 - 16
	end
	self.controls.editCurses.height = function()
		return (not extraHeight() and (self.height - 148) or 116)
	end
	self:SelectControl(self.controls.editAuras)
end)

function PartyTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if node.elem == "ImportedText" then
			if not node.attrib.name then
				ConPrintf("missing name")
			elseif node.attrib.name == "Aura" then
				self.controls.editAuras:SetText(node.attrib.string)
				self:ParseBuffs(self.processedInput["Aura"], node.attrib.string, "Aura")
			elseif node.attrib.name == "Curse" then
				self.controls.editCurses:SetText(node.attrib.string)
				self:ParseBuffs(self.processedInput["Curse"], node.attrib.string, "Curse")
			end
		end
		if node.elem == "ExportedBuffs" then
			if not node.attrib.name then
				ConPrintf("missing name")
			end
			self:ParseBuffs(self.buffExports, node.attrib.string, "Aura")
			self:ParseBuffs(self.buffExports, node.attrib.string, "Curse")
		end
	end
	self.lastContentAura = self.controls.editAuras.buf
	self.lastContentCurse = self.controls.editCurses.buf
end

function PartyTabClass:Save(xml)
	local child = { elem = "ImportedText", attrib = { name = "Aura" } }
	child.attrib.string = self.controls.editAuras.buf
	t_insert(xml, child)
	child = { elem = "ImportedText", attrib = { name = "Curse" } }
	child.attrib.string = self.controls.editCurses.buf
	t_insert(xml, child)
	child = { elem = "ExportedBuffs", attrib = { name = "Aura" } }
	child.attrib.string = self:exportBuffs("Aura")
	t_insert(xml, child)
	child = { elem = "ExportedBuffs", attrib = { name = "Curse" } }
	child.attrib.string = self:exportBuffs("Curse")
	t_insert(xml, child)
	self.lastContentAura = self.controls.editAuras.buf
	self.lastContentCurse = self.controls.editCurses.buf
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

	self.modFlag = (self.lastContentAura ~= self.controls.editAuras.buf and self.lastContentCurse ~= self.controls.editCurses.buf)
end

function PartyTabClass:ParseBuffs(list, buf, buffType)
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
			end
			mode = "Effect"
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
					value = tonumber(modStrings[1]),
					source = modStrings[2],
					name = modStrings[3],
					type = modStrings[4],
					flags = tonumber(modStrings[5]) or 0,
					keywordFlags = tonumber(modStrings[6]) or 0,
				}
				local extraTags = {}
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
	wipeTable(self.buffExports)
	self.buffExports = copyTable(buffExports, true)
end

function PartyTabClass:exportBuffs(buffType)
	if not self.buffExports or not self.buffExports[buffType] then
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
		buf = buf..buffName.."\n"..tostring(buff.effectMult * 100).."\n"
		if buffType == "Curse" then
			if buff.isMark then
				buf = buf.."true\n"
			else
				buf = buf.."false\n"
			end
		end
		for _, mod in ipairs(buff.modList) do
			buf = buf..tostring(mod.value).."|"..mod.source.."|"..modLib.formatModParams(mod).."\n"
			--buf = buf..s_format("%s|%s|%s|%s|-|-|-", tostring(mod.value), mod.source, mod.name, mod.type).."\n"
			--ConPrintTable(mod)
		end
		buf = buf.."---"
	end
	wipeTable(self.buffExports[buffType])
	self.buffExports[buffType] = { ConvertedToText = true }
	self.buffExports[buffType].string = buf
	return buf
end