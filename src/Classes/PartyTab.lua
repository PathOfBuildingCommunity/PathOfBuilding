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
	
	self.processedInput = {}
	self.buffExports = {}

	self.lastContent = ""
	self.showColorCodes = false

	local notesDesc = [[^7Party stuff	DO NOT EDIT ANY BOXES UNLESS YOU KNOW WHAT YOU ARE DOING, use copy/paste instead, or import]]
	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, 16, notesDesc)
	self.controls.importCodeHeader = new("LabelControl", {"TOPLEFT",self.controls.notesDesc,"BOTTOMLEFT"}, 0, 26, 0, 16, "^7To import a build, enter code here: (NOT URL)")
	
	local importCodeHandle = function (buf)
		self.importCodeSite = nil
		self.importCodeDetail = ""
		self.importCodeXML = nil
		self.importCodeValid = false

		if #buf == 0 then
			return
		end

		if not self.build.dbFileName then
			self.controls.importCodeMode.selIndex = 2
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
	self.controls.importCodeGo = new("ButtonControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, 0, 10, 160, 20, "Import", function()
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
				self.controls.editAuras:SetText(node[2].attrib.string)
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

	self.controls.editAuras = new("EditControl", {"TOPLEFT",self.controls.importCodeGo,"TOPLEFT"}, 0, 40, 0, 0, "", nil, "^%C\t\n", nil, function() 
		wipeTable(self.processedInput)
		self.processedInput = self:ParseAuras(self.controls.editAuras.buf)
		self.build.buildFlag = true 
	end, 16, true)
	self.controls.editAuras.width = function()
		return self.width - 16
	end
	self.controls.editAuras.height = function()
		return self.height - 148
	end
	self:SelectControl(self.controls.editAuras)
end)

function PartyTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if node.elem == "ImportedText" then
			if not node.attrib.name then
				ConPrintf("missing name")
			end
			self.controls.editAuras:SetText(node.attrib.string)
		end
		if node.elem == "ExportedBuffs" then
			if not node.attrib.name then
				ConPrintf("missing name")
			end
			buffExports = self:ParseAuras(node.attrib.string)
		end
	end
	self.lastContent = self.controls.editAuras.buf
end

function PartyTabClass:Save(xml)
	local child = { elem = "ImportedText", attrib = { name = "Aura" } }
	child.attrib.string = self.controls.editAuras.buf
	t_insert(xml, child)
	child = { elem = "ExportedBuffs", attrib = { name = "Aura" } }
	child.attrib.string = self:exportAuras()
	t_insert(xml, child)
	self.lastContent = self.controls.editAuras.buf
end

function PartyTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				self.controls.editAuras:Undo()
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self.controls.editAuras:Redo()
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)

	self.modFlag = (self.lastContent ~= self.controls.editAuras.buf)
end

function PartyTabClass:ParseAuras(buf)
	local allyBuffs = {}
	local mode = "Name"
	local currentName
	for line in buf:gmatch("([^\n]*)\n?") do
		if mode == "Name" and line ~= "" then
			currentName = line
			allyBuffs[currentName] = {}
			allyBuffs[currentName].modList = new("ModList")
			mode = "Effect"
		elseif mode == "Effect" then
			allyBuffs[currentName].effectMult = tonumber(line)
			mode = "Stats"
		elseif line == "---" then
			mode = "Name"
		else
			if line:find("|") then
				local modStrings = {}
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
				mod[1] = { -- this should be parsed from modStrings[7]
					type = "GlobalEffect",
					effectType = "Aura"
				}
				allyBuffs[currentName].modList:AddMod(mod)
			else
				local mods, extra = modLib.parseMod(line)
				if mods then
					local source = "Ally Mods"
					for i = 1, #mods do
						local mod = mods[i]

						if mod then
							mod = modLib.setSource(mod, source)
							allyBuffs[currentName].modList:AddMod(mod)
						end
					end
				end
			end
		end
	end
	return allyBuffs
end

function PartyTabClass:setBuffExports(buffExports)
	wipeTable(self.buffExports)
	self.buffExports = copyTable(buffExports, true)
end

function PartyTabClass:exportAuras()
	if not self.buffExports then
		return ""
	end
	if self.buffExports.ConvertedToText then
		return self.buffExports.string
	end
	local buf = ""
	for buffName, buff in pairs(self.buffExports) do
		if #buf > 0 then
			buf = buf.."\n"
		end
		buf = buf..buffName.."\n"..tostring(buff.effectMult * 100).."\n"
		for _, mod in ipairs(buff.modList) do
			buf = buf..tostring(mod.value).."|"..mod.source.."|"..modLib.formatModParams(mod).."\n"
			--buf = buf..s_format("%s|%s|%s|%s|-|-|-", tostring(mod.value), mod.source, mod.name, mod.type).."\n"
			--ConPrintTable(mod)
		end
		buf = buf.."---"
	end
	wipeTable(self.buffExports)
	self.buffExports = { ConvertedToText = true }
	self.buffExports.string = buf
	return buf
end