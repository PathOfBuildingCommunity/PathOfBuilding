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

	local notesDesc = [[^7DO NOT EDIT ANY BOXES UNLESS YOU KNOW WHAT YOU ARE DOING, use copy/paste instead, or import
	To import a build, you must export that build with "Export Support" ticked
	The Strongest Aura applies, but your curses override the supports regardless of strength
	]]
	
	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, 16, notesDesc)
	self.controls.notesDesc.width = function()
		local width = self.width / 2 - 16
		if width ~= self.controls.notesDesc.lastWidth then
			self.controls.notesDesc.lastWidth = width
			self.controls.notesDesc.label = table.concat(main:WrapString(notesDesc, 16, width - 50), "\n")
		end
		return width
	end
	self.controls.importCodeHeader = new("LabelControl", {"TOPLEFT",self.controls.notesDesc,"BOTTOMLEFT"}, 0, 32, 0, 16, "^7Enter a build code below: (NOT URL)")
	self.controls.importCodeHeader.y = function()
		local lineCount = 1
		for i = 1, #self.controls.notesDesc.label do
			local c = self.controls.notesDesc.label:sub(i, i)
			if c == '\n' then lineCount = lineCount + 1 end
		end

		return (lineCount - 2) * 16
	end
	
	local importCodeHandle = function (buf)
		self.importCodeSite = nil
		self.importCodeDetail = ""
		self.importCodeXML = nil
		self.importCodeValid = false

		if #buf == 0 then
			return
		end

		self.importCodeDetail = colorCodes.NEGATIVE.."Invalid input"
		local urlText = buf:gsub("^[%s?]+", ""):gsub("[%s?]+$", "") -- Quick Trim
		if urlText:match("youtube%.com/redirect%?") or urlText:match("google%.com/url%?") then
			local nested_url = urlText:gsub(".*[?&]q=([^&]+).*", "%1")
			urlText = UrlDecode(nested_url)
		end

		for j=1,#buildSites.websiteList do
			if urlText:match(buildSites.websiteList[j].matchURL) then
				self.controls.importCodeIn.text = urlText
				self.importCodeValid = true
				self.importCodeDetail = colorCodes.POSITIVE.."URL is valid ("..buildSites.websiteList[j].label..")"
				self.importCodeSite = j
				if buf ~= urlText then
					self.controls.importCodeIn:SetText(urlText, false)
				end
				return
			end
		end

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
	
	local finishImport = function()
		if not self.importCodeValid or self.importCodeFetching then
			return
		end
	
		if self.controls.importCodeMode2.selIndex == 1 then
			if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 2 then
				self.controls.editAuras:SetText("")
				wipeTable(self.processedInput["Aura"])
				self.processedInput["Aura"] = {}
			end
			if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 3 then
				self.controls.editCurses:SetText("")
				wipeTable(self.processedInput["Curse"])
				self.processedInput["Curse"] = {}
			end
			if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 4 then
				self.controls.enemyCond:SetText("")
			end
			if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 5 then
				self.controls.enemyMods:SetText("")
			end
			if self.controls.importCodeMode2.selIndex == 3 then
				wipeTable(self.enemyModList)
				self.enemyModList = new("ModList")
				self.build.buildFlag = true 
				return
			end
		else
			if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 2 then
				wipeTable(self.processedInput["Aura"])
				self.processedInput["Aura"] = {}
			end
			if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 3 then
				self.controls.editCurses:SetText("") --curses do not play nicely with append atm, need to fix
				wipeTable(self.processedInput["Curse"])
				self.processedInput["Curse"] = {}
			end
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
				if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 2 then
					if #self.controls.editAuras.buf > 0 then
						node[5].attrib.string = self.controls.editAuras.buf.."\n"..node[5].attrib.string
					end
					self.controls.editAuras:SetText(node[5].attrib.string)
					self:ParseBuffs(self.processedInput["Aura"], self.controls.editAuras.buf, "Aura")
				end
				if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 3 then
					if #self.controls.editCurses.buf > 0 then
						node[6].attrib.string = self.controls.editCurses.buf.."\n"..node[6].attrib.string
					end
					self.controls.editCurses:SetText(node[6].attrib.string)
					self:ParseBuffs(self.processedInput["Curse"], self.controls.editCurses.buf, "Curse")
				end
				if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 4 then
					if #self.controls.enemyCond.buf > 0 then
						node[7].attrib.string = self.controls.enemyCond.buf.."\n"..node[7].attrib.string
					end
					self.controls.enemyCond:SetText(node[7].attrib.string)
				end
				if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 5 then
					if #self.controls.enemyMods.buf > 0 then
						node[8].attrib.string = self.controls.enemyMods.buf.."\n"..node[8].attrib.string
					end
					self.controls.enemyMods:SetText(node[8].attrib.string)
				end
				if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 4 or self.controls.importCodeMode.selIndex == 5 then
					wipeTable(self.enemyModList)
					self.enemyModList = new("ModList")
					self:ParseBuffs(self.enemyModList, self.controls.enemyCond.buf, "EnemyConditions")
					self:ParseBuffs(self.enemyModList, self.controls.enemyMods.buf, "EnemyMods")
				end
				self.build.buildFlag = true 
				break
			end
		end
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
	self.controls.importCodeMode = new("DropDownControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, 0, 4, 160, 20, { "All", "Aura", "Curse", "EnemyConditions", "EnemyMods" })
	self.controls.importCodeMode.enabled = function()
		return self.importCodeValid
	end
	self.controls.importCodeMode2 = new("DropDownControl", {"LEFT",self.controls.importCodeMode,"RIGHT"}, 8, 0, 160, 20, { "Replace", "Append", "Clear" })
	self.controls.importCodeGo = new("ButtonControl", {"LEFT",self.controls.importCodeMode2,"RIGHT"}, 8, 0, 160, 20, "Import", function()
		if self.controls.importCodeMode2.selIndex == 3 then
			if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 2 then
				self.controls.editAuras:SetText("")
				wipeTable(self.processedInput["Aura"])
				self.processedInput["Aura"] = {}
			end
			if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 3 then
				self.controls.editCurses:SetText("")
				wipeTable(self.processedInput["Curse"])
				self.processedInput["Curse"] = {}
			end
			if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 4 then
				self.controls.enemyCond:SetText("")
			end
			if self.controls.importCodeMode.selIndex == 1 or self.controls.importCodeMode.selIndex == 5 then
				self.controls.enemyMods:SetText("")
			end
			wipeTable(self.enemyModList)
			self.enemyModList = new("ModList")
			self.build.buildFlag = true 
			return
		end
		local importCodeFetching = false
		if self.importCodeSite and not self.importCodeXML then
			self.importCodeFetching = true
			local selectedWebsite = buildSites.websiteList[self.importCodeSite]
			buildSites.DownloadBuild(self.controls.importCodeIn.buf, selectedWebsite, function(isSuccess, data)
				self.importCodeFetching = false
				if not isSuccess then
					self.importCodeDetail = colorCodes.NEGATIVE..data
					self.importCodeValid = false
				else
					importCodeHandle(data)
					finishImport()
				end
			end)
			return
		end

		finishImport()
	end)
	self.controls.importCodeGo.label = function()
		return self.controls.importCodeMode2.selIndex == 3 and "Clear" or "Import"
	end
	self.controls.importCodeGo.enabled = function()
		return (self.importCodeValid and not self.importCodeFetching) or self.controls.importCodeMode2.selIndex == 3
	end
	self.controls.importCodeGo.x = function()
		return (self.width > 1350) and 8 or (-328)
	end
	self.controls.importCodeGo.y = function()
		return (self.width > 1350) and 0 or 28
	end
	self.controls.importCodeGo.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
	
	self.controls.rebuild = new("ButtonControl", {"LEFT",self.controls.importCodeGo,"RIGHT"}, 8, 0, 160, 20, "Rebuild All", function() 
		wipeTable(self.processedInput)
		wipeTable(self.enemyModList)
		self.processedInput = { Aura = {}, Curse = {} }
		self.enemyModList = new("ModList")
		if self.controls.importCodeMode2.selIndex ~= 3 then
			self:ParseBuffs(self.processedInput["Aura"], self.controls.editAuras.buf, "Aura")
			self:ParseBuffs(self.processedInput["Curse"], self.controls.editCurses.buf, "Curse")
			self:ParseBuffs(self.enemyModList, self.controls.enemyCond.buf, "EnemyConditions")
			self:ParseBuffs(self.enemyModList, self.controls.enemyMods.buf, "EnemyMods")
		end
		self.build.buildFlag = true 
	end)
	self.controls.rebuild.label = function()
		return self.controls.importCodeMode2.selIndex == 3 and "Remove effects" or "Rebuild All"
	end
	self.controls.rebuild.tooltipText = "^7Reparse all the inputs incase they have changed since loading the build or importing"

	self.controls.editAurasLabel = new("LabelControl", {"TOPLEFT",self.controls.importCodeMode,"TOPLEFT"}, 0, 40, 150, 16, "^7Auras")
	self.controls.editAurasLabel.y = function()
		return (self.width > 1350) and 40 or 68
	end
	self.controls.editAuras = new("EditControl", {"TOPLEFT",self.controls.editAurasLabel,"TOPLEFT"}, 0, 18, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editAuras.width = function()
		return self.width / 2 - 16
	end
	self.controls.editAuras.height = function()
		return self.height - 172 - ((self.width > 1260) and 0 or 28)
	end

	self.controls.enemyCondLabel = new("LabelControl", {"TOPLEFT",self.controls.notesDesc,"TOPRIGHT"}, 8, 0, 150, 16, "^7Enemy Conditions")
	self.controls.enemyCond = new("EditControl", {"TOPLEFT",self.controls.enemyCondLabel,"BOTTOMLEFT"}, 0, 2, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.enemyCond.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyCond.height = function()
		return (self.controls.enemyCond.hasFocus and (self.height - 304) or 106)
	end

	self.controls.enemyModsLabel = new("LabelControl", {"TOPLEFT",self.controls.enemyCond,"BOTTOMLEFT"}, 0, 8, 150, 16, "^7Enemy Modifiers")
	self.controls.enemyMods = new("EditControl", {"TOPLEFT",self.controls.enemyModsLabel,"BOTTOMLEFT"}, 0, 2, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.enemyMods.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyMods.height = function()
		return (self.controls.enemyMods.hasFocus and (self.height - 304) or 106)
	end

	self.controls.editCursesLabel = new("LabelControl", {"TOPLEFT",self.controls.enemyMods,"BOTTOMLEFT"}, 0, 8, 150, 16, "^7Curses")
	self.controls.editCurses = new("EditControl", {"TOPLEFT",self.controls.editCursesLabel,"BOTTOMLEFT"}, 0, 2, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editCurses.width = function()
		return self.width / 2 - 16
	end
	self.controls.editCurses.height = function()
		return ((not self.controls.enemyCond.hasFocus and not self.controls.enemyMods.hasFocus) and (self.height - 304) or 106)
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
			or self.lastContentCurse ~= self.controls.editCurses.buf
			or self.lastContentEnemyCond ~= self.controls.enemyCond.buf
			or self.lastContentEnemyMods ~= self.controls.enemyMods.buf
			or self.lastEnableExportBuffs ~= self.enableExportBuffs)
end

function PartyTabClass:ParseTags(line, currentModType) -- should parse this correctly instead of string match
	if not line then
		return "none", {}
	end
	local extraTags = {}
	local modType = currentModType
	for line2 in line:gmatch("([^,]*),?") do
		if line2:find("type=GlobalEffect/") then
			if line2:find("type=GlobalEffect/effectType=AuraDebuff") then
				t_insert(extraTags, {
					type = "GlobalEffect",
					effectType = "AuraDebuff"
				})
				modType = "AuraDebuff"
			elseif line2:find("type=GlobalEffect/effectType=Aura") then
				t_insert(extraTags, {
					type = "GlobalEffect",
					effectType = "Aura"
				})
				modType = "Aura"
			elseif line2:find("type=GlobalEffect/effectType=Curse") then
				t_insert(extraTags, {
					type = "GlobalEffect",
					effectType = "Curse"
				})
				modType = "Curse"
			end
		elseif line2:find("type=Condition/") then
			if line2:find("type=Condition/neg=true/var=RareOrUnique") then
				t_insert(extraTags, {
					type = "Condition",
					neg = true,
					var = "RareOrUnique"
				})
			elseif line2:find("type=Condition/var=RareOrUnique") then
				t_insert(extraTags, {
					type = "Condition",
					var = "RareOrUnique"
				})
			end
		end
	end
	return modType, extraTags
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
				local tags = nil -- modStrings[7], should be done with a modified version of "PartyTabClass:ParseTags" where conditions check vs the party and check that the ones in the build are NOT true, such that your effects override the supports
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
		if line ~= "---" and line:match("%-%-%-") then
			-- comment but not dividor, skip the line
		elseif mode == "CurseLimit" and line ~= "" then
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
				local modType, Tags = self:ParseTags(modStrings[7], currentModType)
				for _, tag in ipairs(Tags) do
					t_insert(mod, tag)
				end
				currentModType = modType
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
	local buf = ((buffType == "Curse") and ("--- Curse Limit ---" .. tostring(self.buffExports["CurseLimit"]))) or ""
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