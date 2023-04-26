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
	self.enableExportBuffs = false

	self.lastContent = {
		Aura = "",
		Curse = "",
		Link = "",
		EnemyCond = "",
		EnemyMods = "",
		EnableExportBuffs = false,
		showAdvancedTools = false,
	}
	
	local partyDestinations = { "All", "Aura", "Curse", "Link Skills", "EnemyConditions", "EnemyMods" }

	local notesDesc = [[^7To import a build it must be exported with "Export support" enabled in the import/export tab
	Auras with the highest effect will take priority, your curses will take priority over a support's
	
	All of these effects can be found in the Calcs tab]]
	
	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, 16, notesDesc)
	self.controls.notesDesc.width = function()
		local width = self.width / 2 - 16
		if width ~= self.controls.notesDesc.lastWidth then
			self.controls.notesDesc.lastWidth = width
			self.controls.notesDesc.label = table.concat(main:WrapString(notesDesc, 16, width - 50), "\n")
		end
		return width
	end
	self.controls.importCodeHeader = new("LabelControl", {"TOPLEFT",self.controls.notesDesc,"BOTTOMLEFT"}, 0, 32, 0, 16, "^7Enter a build code/URL below:")
	self.controls.importCodeHeader.y = function()
		local lineCount = 1
		for i = 1, #self.controls.notesDesc.label do
			local c = self.controls.notesDesc.label:sub(i, i)
			if c == '\n' then lineCount = lineCount + 1 end
		end

		return (lineCount - 1) * 16
	end
	
	local clearInputText = function()
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Aura" then
			self.controls.simpleAuras.label = ""
			self.controls.editAuras:SetText("")
			wipeTable(self.processedInput["Aura"])
			self.processedInput["Aura"] = {}
		end
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Curse" then
			self.controls.simpleCurses.label = ""
			self.controls.editCurses:SetText("")
			wipeTable(self.processedInput["Curse"])
			self.processedInput["Curse"] = {}
		end
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Link Skills" then
			self.controls.simpleLinks.label = "^7Link Skills are not currently supported"
			self.controls.editCurses:SetText("")
			wipeTable(self.processedInput["Link"])
			self.processedInput["Link"] = {}
		end
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "EnemyConditions" then
			self.controls.simpleEnemyCond.label = "^7Enemy Conditions are not exported but will still work if correctly added"
			self.controls.enemyCond:SetText("")
		end
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "EnemyMods" then
			self.controls.simpleEnemyMods.label = "^7Enemy Modifiers are not exported but will still work if correctly added"
			self.controls.enemyMods:SetText("")
		end
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
		
		local currentCurseBuffer = nil
		if self.controls.appendNotReplace.state ~= true then
			clearInputText()
		else
			if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Aura" then
				wipeTable(self.processedInput["Aura"])
				self.processedInput["Aura"] = {}
			end
			if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Curse" then
				currentCurseBuffer = self.controls.editCurses.buf
				self.controls.editCurses:SetText("") --curses do not play nicely with append atm, need to fix
				wipeTable(self.processedInput["Curse"])
				self.processedInput["Curse"] = {}
			end
			if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Link Skills" then
				wipeTable(self.processedInput["Link"])
				self.processedInput["Link"] = {}
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
		for _, tabNode in ipairs(dbXML[1]) do
			if type(tabNode) == "table" and tabNode.elem == "Party" then
				for _, node in ipairs(tabNode) do
					if node.elem == "ExportedBuffs" then
						if not node.attrib.name then
							ConPrintf("missing name")
						elseif node.attrib.name == "Aura" then
							if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Aura" then
								if #self.controls.editAuras.buf > 0 then
									node[1] = self.controls.editAuras.buf.."\n"..(node[1] or "")
								end
								self.controls.editAuras:SetText(node[1] or "")
								self:ParseBuffs(self.processedInput["Aura"], self.controls.editAuras.buf, "Aura", self.controls.simpleAuras)
							end
						elseif node.attrib.name == "Curse" then
							if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Curse" then
								if #self.controls.editCurses.buf > 0 then
									node[1] = self.controls.editCurses.buf.."\n"..(node[1] or "")
								end
								if currentCurseBuffer and node[1] =="--- Curse Limit ---\n1" then
									node[1] = currentCurseBuffer
								end
								self.controls.editCurses:SetText(node[1] or "")
								self:ParseBuffs(self.processedInput["Curse"], self.controls.editCurses.buf, "Curse", self.controls.simpleCurses)
							end
						elseif node.attrib.name == "Link Skills" then
							if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Link Skills" then
								if #self.controls.editLinks.buf > 0 then
									node[1] = self.controls.editLinks.buf.."\n"..(node[1] or "")
								end
								self.controls.editLinks:SetText(node[1] or "")
								self:ParseBuffs(self.processedInput["Link"], self.controls.editLinks.buf, "Link", self.controls.simpleLinks)
							end
						elseif node.attrib.name == "EnemyConditions" then
							if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "EnemyConditions" then
								if #self.controls.enemyCond.buf > 0 then
									node[1] = self.controls.enemyCond.buf.."\n"..(node[1] or "")
								end
								self.controls.enemyCond:SetText(node[1] or "")
							end
						elseif node.attrib.name == "EnemyMods" then
							if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "EnemyMods" then
								if #self.controls.enemyMods.buf > 0 then
									node[1] = self.controls.enemyMods.buf.."\n"..(node[1] or "")
								end
								self.controls.enemyMods:SetText(node[1] or "")
							end
						end
					end
				end
				if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "EnemyConditions" or partyDestinations[self.controls.importCodeDestination.selIndex] == "EnemyMods" then
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
	self.controls.importCodeDestination = new("DropDownControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, 0, 4, 160, 20, partyDestinations)
	self.controls.importCodeDestination.tooltipText = "Destination for Import/clear\nCurrently EnemyConditions, EnemyMods and Links Skills do not export"
	self.controls.importCodeGo = new("ButtonControl", {"LEFT",self.controls.importCodeDestination,"RIGHT"}, 8, 0, 160, 20, "Import", function()
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
	self.controls.importCodeGo.enabled = function()
		return (self.importCodeValid and not self.importCodeFetching)
	end
	self.controls.importCodeGo.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
	self.controls.appendNotReplace = new("CheckBoxControl", {"LEFT",self.controls.importCodeGo,"RIGHT"}, 60, 0, 20, "Append", function(state)
	end, "This sets the import button to append to the current party lists instead of replacing them (curses will still replace)", false)
	self.controls.appendNotReplace.x = function()
		return (self.width > 1350) and 60 or (-276)
	end
	self.controls.appendNotReplace.y = function()
		return (self.width > 1350) and 0 or 28
	end
	
	self.controls.clear = new("ButtonControl", {"LEFT",self.controls.appendNotReplace,"RIGHT"}, 8, 0, 160, 20, "Clear", function() 
		clearInputText()
		wipeTable(self.enemyModList)
		self.enemyModList = new("ModList")
		self.build.buildFlag = true
	end)
	self.controls.clear.tooltipText = "^7Clears all the party tab imported data"
	
	self.controls.ShowAdvanceTools = new("CheckBoxControl", {"TOPLEFT",self.controls.importCodeDestination,"BOTTOMLEFT"}, 140, 4, 20, "^7Show Advanced Info", function(state)
	end, "This shows the advanced info like what stats each aura/curse etc are adding, as well as enables the ability to edit them without a re-export\nDo not edit any boxes unless you know what you are doing, use copy/paste or import instead", false)
	self.controls.ShowAdvanceTools.y = function()
		return (self.width > 1350) and 4 or 32
	end
	
	self.controls.removeEffects = new("ButtonControl", {"LEFT",self.controls.ShowAdvanceTools,"RIGHT"}, 8, 0, 160, 20, "Disable Party Effects", function() 
		wipeTable(self.processedInput)
		wipeTable(self.enemyModList)
		self.processedInput = { Aura = {}, Curse = {}, Link = {} }
		self.enemyModList = new("ModList")
		self.build.buildFlag = true
	end)
	self.controls.removeEffects.tooltipText = "^7Removes the effects of the supports, without removing the data\nUse \"rebuild all\" to apply the effects again"
	
	self.controls.rebuild = new("ButtonControl", {"LEFT",self.controls.removeEffects,"RIGHT"}, 8, 0, 160, 20, "^7Rebuild All", function() 
		wipeTable(self.processedInput)
		wipeTable(self.enemyModList)
		self.processedInput = { Aura = {}, Curse = {}, Link = {} }
		self.enemyModList = new("ModList")
		self:ParseBuffs(self.processedInput["Aura"], self.controls.editAuras.buf, "Aura", self.controls.simpleAuras)
		self:ParseBuffs(self.processedInput["Curse"], self.controls.editCurses.buf, "Curse", self.controls.simpleCurses)
		self:ParseBuffs(self.processedInput["Link"], self.controls.editLinks.buf, "Link", self.controls.simpleLinks)
		self:ParseBuffs(self.enemyModList, self.controls.enemyCond.buf, "EnemyConditions")
		self:ParseBuffs(self.enemyModList, self.controls.enemyMods.buf, "EnemyMods")
		self.build.buildFlag = true 
	end)
	self.controls.rebuild.tooltipText = "^7Reparse all the inputs incase they have been disabled or they have changed since loading the build or importing"
	self.controls.rebuild.x = function()
		return (self.width > 1350) and 8 or (-328)
	end
	self.controls.rebuild.y = function()
		return (self.width > 1350) and 0 or 28
	end

	self.controls.editAurasLabel = new("LabelControl", {"TOPLEFT",self.controls.ShowAdvanceTools,"TOPLEFT"}, -140, 40, 150, 16, "^7Auras")
	self.controls.editAurasLabel.y = function()
		return 40 + ((self.width <= 1350) and 28 or 0)
	end
	self.controls.editAuras = new("EditControl", {"TOPLEFT",self.controls.editAurasLabel,"TOPLEFT"}, 0, 18, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editAuras.width = function()
		return self.width / 2 - 16
	end
	self.controls.editAuras.height = function()
		return self.controls.editLinks.hasFocus and 106 or (self.height - 256 - ((self.width > 1350) and 0 or 28) - self.controls.importCodeHeader.y() - self.controls.editAurasLabel.y())
	end
	self.controls.editAuras.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleAuras = new("LabelControl", {"TOPLEFT",self.controls.editAurasLabel,"TOPLEFT"}, 0, 18, 0, 16, "")
	self.controls.simpleAuras.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.editLinksLabel = new("LabelControl", {"TOPLEFT",self.controls.editAurasLabel,"BOTTOMLEFT"}, 0, 8, 150, 16, "^7Link Skills")
	self.controls.editLinksLabel.y = function()
		if self.controls.ShowAdvanceTools.state then
			return (8 + self.controls.editAuras.height())
		end
		local lineCount = 0
		for i = 1, #self.controls.simpleAuras.label do
			local c = self.controls.simpleAuras.label:sub(i, i)
			if c == '\n' then lineCount = lineCount + 1 end
		end

		return (lineCount) * 16 + 4
	end
	self.controls.editLinks = new("EditControl", {"TOPLEFT",self.controls.editLinksLabel,"TOPLEFT"}, 0, 18, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editLinks.width = function()
		return self.width / 2 - 16
	end
	self.controls.editLinks.height = function()
		return (self.controls.editLinks.hasFocus and (self.height - 256 - ((self.width > 1350) and 0 or 28) - self.controls.importCodeHeader.y() - self.controls.editAurasLabel.y()) or 106)
	end
	self.controls.editLinks.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleLinks = new("LabelControl", {"TOPLEFT",self.controls.editLinksLabel,"TOPLEFT"}, 0, 18, 0, 16, "^7Link Skills are not currently supported")
	self.controls.simpleLinks.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.enemyCondLabel = new("LabelControl", {"TOPLEFT",self.controls.notesDesc,"TOPRIGHT"}, 8, 0, 150, 16, "^7Enemy Conditions")
	self.controls.enemyCond = new("EditControl", {"TOPLEFT",self.controls.enemyCondLabel,"BOTTOMLEFT"}, 0, 2, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.enemyCond.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyCond.height = function()
		return (self.controls.enemyCond.hasFocus and (self.height - 304) or 106)
	end
	self.controls.enemyCond.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleEnemyCond = new("LabelControl", {"TOPLEFT",self.controls.enemyCondLabel,"TOPLEFT"}, 0, 18, 0, 16, "^7Enemy Conditions are not exported but will still work if correctly added")
	self.controls.simpleEnemyCond.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.enemyModsLabel = new("LabelControl", {"TOPLEFT",self.controls.enemyCondLabel,"BOTTOMLEFT"}, 0, 8, 150, 16, "^7Enemy Modifiers")
	self.controls.enemyModsLabel.y = function()
		if self.controls.ShowAdvanceTools.state then
			return (8 + self.controls.enemyCond.height())
		end
		local lineCount = 1
		for i = 1, #self.controls.simpleEnemyCond.label do
			local c = self.controls.simpleEnemyCond.label:sub(i, i)
			if c == '\n' then lineCount = lineCount + 1 end
		end

		return (lineCount) * 16 + 4
	end
	self.controls.enemyMods = new("EditControl", {"TOPLEFT",self.controls.enemyModsLabel,"BOTTOMLEFT"}, 0, 2, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.enemyMods.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyMods.height = function()
		return (self.controls.enemyMods.hasFocus and (self.height - 304) or 106)
	end
	self.controls.enemyMods.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleEnemyMods = new("LabelControl", {"TOPLEFT",self.controls.enemyModsLabel,"TOPLEFT"}, 0, 18, 0, 16, "^7Enemy Modifiers are not exported but will still work if correctly added")
	self.controls.simpleEnemyMods.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.editCursesLabel = new("LabelControl", {"TOPLEFT",self.controls.enemyModsLabel,"BOTTOMLEFT"}, 0, 8, 150, 16, "^7Curses")
	self.controls.editCursesLabel.y = function()
		if self.controls.ShowAdvanceTools.state then
			return (8 + self.controls.enemyMods.height())
		end
		local lineCount = 1
		for i = 1, #self.controls.simpleEnemyMods.label do
			local c = self.controls.simpleEnemyMods.label:sub(i, i)
			if c == '\n' then lineCount = lineCount + 1 end
		end

		return (lineCount) * 16 + 4
	end
	self.controls.editCurses = new("EditControl", {"TOPLEFT",self.controls.editCursesLabel,"BOTTOMLEFT"}, 0, 2, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editCurses.width = function()
		return self.width / 2 - 16
	end
	self.controls.editCurses.height = function()
		return ((not self.controls.enemyCond.hasFocus and not self.controls.enemyMods.hasFocus) and (self.height - 304) or 106)
	end
	self.controls.editCurses.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleCurses = new("LabelControl", {"TOPLEFT",self.controls.editCursesLabel,"TOPLEFT"}, 0, 18, 0, 16, "")
	self.controls.simpleCurses.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end
	self:SelectControl(self.controls.editAuras)
end)

function PartyTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if node.elem == "ImportedBuffs" then
			if not node.attrib.name then
				ConPrintf("missing name")
			elseif node.attrib.name == "Aura" then
				self.controls.editAuras:SetText(node[1] or "")
				self:ParseBuffs(self.processedInput["Aura"], node[1] or "", "Aura", self.controls.simpleAuras)
			elseif node.attrib.name == "Curse" then
				self.controls.editCurses:SetText(node[1] or "")
				self:ParseBuffs(self.processedInput["Curse"], node[1] or "", "Curse", self.controls.simpleCurses)
			elseif node.attrib.name == "Link Skills" then
				self.controls.editLinks:SetText(node[1] or "")
				self:ParseBuffs(self.processedInput["Link"], node[1] or "", "Link", self.controls.simpleLinks)
			elseif node.attrib.name == "EnemyConditions" then
				self.controls.enemyCond:SetText(node[1] or "")
				self:ParseBuffs(self.enemyModList, node[1] or "", "EnemyConditions")
			elseif node.attrib.name == "EnemyMods" then
				self.controls.enemyMods:SetText(node[1] or "")
				self:ParseBuffs(self.enemyModList, node[1] or "", "EnemyMods")
			end
		elseif node.elem == "ExportedBuffs" then
			if not node.attrib.name then
				ConPrintf("missing name")
			end
			if node.attrib.name ~= "EnemyConditions" and node.attrib.name ~= "EnemyMods" then
				self:ParseBuffs(self.buffExports, node[1] or "", node.attrib.name)
			end
			--self:ParseBuffs(self.buffExports, node[1] or "", "Aura")
			--self:ParseBuffs(self.buffExports, node[1] or "", "Curse")
			--self:ParseBuffs(self.buffExports, node[1] or "", "Link")
			--self:ParseBuffs(self.buffExports, node[1] or "", "EnemyConditions")
			--self:ParseBuffs(self.buffExports, node[1] or "", "EnemyMods")
		end
	end
	self.lastContent.Aura = self.controls.editAuras.buf
	self.lastContent.Curse = self.controls.editCurses.buf
	self.lastContent.Link = self.controls.editLinks.buf
	self.lastContent.EnemyCond = self.controls.enemyCond.buf
	self.lastContent.EnemyMods = self.controls.enemyMods.buf
	self.lastContent.EnableExportBuffs = self.enableExportBuffs
	
	self.controls.importCodeDestination:SelByValue(xml.attrib.destination or "All")
	self.controls.appendNotReplace.state = xml.attrib.append == "true"
	self.controls.ShowAdvanceTools.state = xml.attrib.ShowAdvanceTools == "true"
	
	self.lastContent.showAdvancedTools = self.controls.ShowAdvanceTools.state
end

function PartyTabClass:Save(xml)
	local child = { elem = "ImportedBuffs", attrib = { name = "Aura" } }
	if self.controls.editAuras.buf and self.controls.editAuras.buf ~= "" then
		t_insert(child, self.controls.editAuras.buf)
		t_insert(xml, child)
	end
	if self.controls.editCurses.buf and self.controls.editCurses.buf ~= "" then
		child = { elem = "ImportedBuffs", attrib = { name = "Curse" } }
		t_insert(child, self.controls.editCurses.buf)
		t_insert(xml, child)
	end
	if self.controls.editLinks.buf and self.controls.editLinks.buf ~= "" then
		child = { elem = "ImportedBuffs", attrib = { name = "Link Skills" } }
		t_insert(child, self.controls.editLinks.buf)
		t_insert(xml, child)
	end
	if self.controls.enemyCond.buf and self.controls.enemyCond.buf ~= "" then
		child = { elem = "ImportedBuffs", attrib = { name = "EnemyConditions" } }
		t_insert(child, self.controls.enemyCond.buf)
		t_insert(xml, child)
	end
	if self.controls.enemyMods.buf and self.controls.enemyMods.buf ~= "" then
		child = { elem = "ImportedBuffs", attrib = { name = "EnemyMods" } }
		t_insert(child, self.controls.enemyMods.buf)
		t_insert(xml, child)
	end
	local exportString = self:exportBuffs("Aura")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "Aura" } }
		t_insert(child, self:exportBuffs("Aura"))
		t_insert(xml, child)
	end
	exportString = self:exportBuffs("Curse")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "Curse" } }
		t_insert(child, self:exportBuffs("Curse"))
		t_insert(xml, child)
	end
	exportString = self:exportBuffs("Link")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "Link Skills" } }
		t_insert(child, self:exportBuffs("Link"))
		t_insert(xml, child)
	end
	exportString = self:exportBuffs("EnemyConditions")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "EnemyConditions" } }
		t_insert(child, self:exportBuffs("EnemyConditions"))
		t_insert(xml, child)
	end
	exportString = self:exportBuffs("EnemyMods")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "EnemyMods" } }
		t_insert(child, self:exportBuffs("EnemyMods"))
		t_insert(xml, child)
	end
	self.lastContent.Aura = self.controls.editAuras.buf
	self.lastContent.Curse = self.controls.editCurses.buf
	self.lastContent.Link = self.controls.editLinks.buf
	self.lastContent.EnemyCond = self.controls.enemyCond.buf
	self.lastContent.EnemyMods = self.controls.enemyMods.buf
	self.lastContent.EnableExportBuffs = self.enableExportBuffs
	xml.attrib = {
		destination = self.controls.importCodeDestination.list[self.controls.importCodeDestination.selIndex],
		append = tostring(self.controls.appendNotReplace.state),
		ShowAdvanceTools = tostring(self.controls.ShowAdvanceTools.state)
	}
	self.lastContent.showAdvancedTools = self.controls.ShowAdvanceTools.state
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
				elseif self.controls.editLinks.hasFocus then
					self.controls.editLinks:Undo()
				end
			elseif event.key == "y" and IsKeyDown("CTRL") then
				if self.controls.editAuras.hasFocus then
					self.controls.editAuras:Redo()
				elseif self.controls.editCurses.hasFocus then
					self.controls.editCurses:Redo()
				elseif self.controls.editLinks.hasFocus then
					self.controls.editLinks:Redo()
				end
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)

	self.modFlag = (self.lastContent.Aura ~= self.controls.editAuras.buf 
			or self.lastContent.Curse ~= self.controls.editCurses.buf
			or self.lastContent.Link ~= self.controls.editLinks.buf
			or self.lastContent.EnemyCond ~= self.controls.enemyCond.buf
			or self.lastContent.EnemyMods ~= self.controls.enemyMods.buf
			or self.lastContent.EnableExportBuffs ~= self.enableExportBuffs
			or self.lastContent.showAdvancedTools ~= self.controls.ShowAdvanceTools.state)
end

function PartyTabClass:ParseBuffs(list, buf, buffType, label)
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
				if #modStrings >= 7 then
					-- should be done with a modified version of "modLib.parseTags" where conditions check vs the party
					-- and check that the ones in the build are NOT true, such that your effects override the supports
					local tags = nil -- modStrings[7]
					list:NewMod(modStrings[3], modStrings[4], tonumber(modStrings[1]), "Party"..modStrings[2], ModFlag[modStrings[5]] or 0, KeywordFlag[modStrings[6]] or 0, tags)
				end
			end
		end
	else
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
				-- comment but not divider, skip the line
			elseif mode == "CurseLimit" and line ~= "" then
				list.limit = tonumber(line)
				mode = "Name"
			elseif mode == "Name" and line ~= "" then
				currentName = line:gsub("_Debuff", "")
				currentEffect = 0
				if line == "extraAura" then
					currentModType = "extraAura"
					mode = "Stats"
				else
					mode = "Effect"
					currentModType = "Unknown"
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
				if line:find("|") and currentName ~= "SKIP" then
					local modType, mod = modLib.parseFormattedSourceMod(line, currentModType)
					if mod then
						currentModType = modType
						list[modType] = list[modType] or {}
						if not list[modType][currentName] then
							list[modType][currentName] = {
								modList = new("ModList"),
								effectMult = currentEffect
							}
							if isMark then
								list[modType][currentName].isMark = true
							end
						elseif list[modType][currentName].effectMult ~= currentEffect then
							if list[modType][currentName].effectMult < currentEffect then
								list[modType][currentName] = {
									modList = new("ModList"),
									effectMult = currentEffect
								}
							else
								currentName = "SKIP"
							end
						end
						if currentName ~= "SKIP" then
							if mod.source:match("Item") then
								_, mod.source = mod.source:match("Item:(%d+):(.+)")
								mod.source = "Party, "..mod.source
							end
							list[modType][currentName].modList:AddMod(mod)
						end
					end
				end
			end
		end
		if label then
			if buffType == "Aura" then
				local count = 0
				label.label = "^7---------------------------\n"
				for aura, auraMod in pairs(list["Aura"] or {}) do
					label.label = label.label..aura..": "..auraMod.effectMult.."%\n"
					count = count + 1
				end
				for aura, auraMod in pairs(list["AuraDebuff"] or {}) do
					label.label = label.label..aura..": "..auraMod.effectMult.."%\n"
					count = count + 1
				end
				if list["extraAura"] and list["extraAura"]["extraAura"] then
					label.label = label.label.."extraAuras:\n"
					count = count + 1
					for _, auraMod in ipairs(list["extraAura"]["extraAura"].modList) do
						label.label = label.label.."  "..(auraMod.type == "FLAG" and "" or (auraMod.type.." "))..auraMod.name..": "..tostring(auraMod.value).."\n"
					end
				end
				if count > 0 then
					label.label = label.label.."---------------------------\n"
				end
			elseif buffType == "Curse" then
				local count = 0
				label.label = "^7---------------------------\n"
				for curse, curseMod in pairs(list["Curse"] or {}) do
					label.label = label.label..curse..": "..curseMod.effectMult.."%\n"
					count = count + 1
				end
				if count > 0 then
					label.label = label.label.."---------------------------\n"
				else
					label.label = ""
				end
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
	local buf = ((buffType == "Curse") and ("--- Curse Limit ---\n" .. tostring(self.buffExports["CurseLimit"]))) or ""
	for buffName, buff in pairs(self.buffExports[buffType]) do
		if buffName ~= "extraAura" or #buff.modList > 0 then
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
					buf = buf.."\n"..modLib.formatSourceMod(mod)
				end
				buf = buf.."\n---"
			elseif buffType == "EnemyMods" then
				buf = buf.."\n"..modLib.formatSourceMod(buff)
			end
		end
	end
	wipeTable(self.buffExports[buffType])
	self.buffExports[buffType] = { ConvertedToText = true }
	self.buffExports[buffType].string = buf
	return buf
end