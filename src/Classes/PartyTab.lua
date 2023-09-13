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

	self.actor = { Aura = { }, Curse = { }, Link = { }, modDB = new("ModDB"), output = { } }
	self.actor.modDB.actor = self.actor
	self.enemyModList = new("ModList")
	self.buffExports = { }
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
	
	local partyDestinations = { "All", "Party Member Stats", "Aura", "Curse", "Link Skills", "EnemyConditions", "EnemyMods" }
	
	local theme = {
		stringHeight = 16,
		buttonHeight = 20,
		lineCounter = function(label)
			local lineCount = 0
			for i = 1, #label do
				local c = label:sub(i, i)
				if c == '\n' then lineCount = lineCount + 1 end
			end

			return lineCount * 16
		end,
		widthThreshold1 = 1350,
		bufferHeightSmall = 106,
		bufferHeightLeft = function()
			-- 2 elements
			return (self.height - 258 - ((self.width > 1350) and 0 or 24) - self.controls.importCodeHeader.y() - self.controls.editAurasLabel.y())
		end,
		-- 4 elements
		bufferHeightRight = 434,
	}

	local notesDesc = [[^7To import a build it must be exported with "Export support" enabled in the import/export tab
	Auras with the highest effect will take priority, your curses will take priority over a support's
	
	All of these effects can be found in the Calcs tab]]
	
	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, theme.stringHeight, notesDesc)
	self.controls.notesDesc.width = function()
		local width = self.width / 2 - 16
		if width ~= self.controls.notesDesc.lastWidth then
			self.controls.notesDesc.lastWidth = width
			self.controls.notesDesc.label = table.concat(main:WrapString(notesDesc, theme.stringHeight, width - 50), "\n")
		end
		return width
	end
	self.controls.importCodeHeader = new("LabelControl", {"TOPLEFT",self.controls.notesDesc,"BOTTOMLEFT"}, 0, 32, 0, theme.stringHeight, "^7Enter a build code/URL below:")
	self.controls.importCodeHeader.y = function()
		return theme.lineCounter(self.controls.notesDesc.label) + 4
	end
	
	local clearInputText = function()
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Party Member Stats" then
			self.controls.editPartyMemberStats:SetText("")
		end
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Aura" then
			self.controls.simpleAuras.label = ""
			self.controls.editAuras:SetText("")
			wipeTable(self.actor["Aura"])
			self.actor["Aura"] = {}
		end
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Curse" then
			self.controls.simpleCurses.label = ""
			self.controls.editCurses:SetText("")
			wipeTable(self.actor["Curse"])
			self.actor["Curse"] = {}
		end
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Link Skills" then
			self.controls.simpleLinks.label = ""
			self.controls.editLinks:SetText("")
			wipeTable(self.actor["Link"])
			self.actor["Link"] = {}
		end
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "EnemyConditions" then
			self.controls.simpleEnemyCond.label = "^7---------------------------\n"
			self.controls.enemyCond:SetText("")
		end
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "EnemyMods" then
			self.controls.simpleEnemyMods.label = "\n"
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
		local currentLinkBuffer = nil
		if self.controls.appendNotReplace.state ~= true then
			clearInputText()
		else
			if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Aura" then
				wipeTable(self.actor["Aura"])
				self.actor["Aura"] = { }
			end
			if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Curse" then
				currentCurseBuffer = self.controls.editCurses.buf
				self.controls.editCurses:SetText("") --curses do not play nicely with append atm, need to fix
				wipeTable(self.actor["Curse"])
				self.actor["Curse"] = { }
			end
			if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Link Skills" then
				 -- only one link can be applied at a time anyway
				currentLinkBuffer = self.controls.editLinks.buf
				self.controls.editLinks:SetText("")
				wipeTable(self.actor["Link"])
				self.actor["Link"] = { }
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
						elseif node.attrib.name == "PartyMemberStats" then
							if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Party Member Stats" then
								if #self.controls.editPartyMemberStats.buf > 0 then
									node[1] = self.controls.editPartyMemberStats.buf.."\n"..(node[1] or "")
								end
								self.controls.editPartyMemberStats:SetText(node[1] or "")
								self:ParseBuffs(self.actor["modDB"], self.controls.editPartyMemberStats.buf, "PartyMemberStats", self.actor["output"])
							end
						elseif node.attrib.name == "Aura" then
							if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Aura" then
								if #self.controls.editAuras.buf > 0 then
									node[1] = self.controls.editAuras.buf.."\n"..(node[1] or "")
								end
								self.controls.editAuras:SetText(node[1] or "")
								self:ParseBuffs(self.actor["Aura"], self.controls.editAuras.buf, "Aura", self.controls.simpleAuras)
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
								self:ParseBuffs(self.actor["Curse"], self.controls.editCurses.buf, "Curse", self.controls.simpleCurses)
							end
						elseif node.attrib.name == "Link Skills" then
							if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Link Skills" then
								if #self.controls.editLinks.buf > 0 then
									node[1] = self.controls.editLinks.buf.."\n"..(node[1] or "")
								end
								if currentLinkBuffer and (not node[1] or node[1] == "") then
									node[1] = currentLinkBuffer
								end
								self.controls.editLinks:SetText(node[1] or "")
								self:ParseBuffs(self.actor["Link"], self.controls.editLinks.buf, "Link", self.controls.simpleLinks)
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
					self:ParseBuffs(self.enemyModList, self.controls.enemyMods.buf, "EnemyMods", self.controls.simpleEnemyMods)
				end
				self.build.buildFlag = true 
				break
			end
		end
	end
	
	self.controls.importCodeIn = new("EditControl", {"TOPLEFT",self.controls.importCodeHeader,"BOTTOMLEFT"}, 0, 4, 328, theme.buttonHeight, "", nil, nil, nil, importCodeHandle)
	self.controls.importCodeIn.width = function()
		return (self.width > 880) and 328 or (self.width / 2 - 100)
	end
	self.controls.importCodeIn.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
	self.controls.importCodeState = new("LabelControl", {"LEFT",self.controls.importCodeIn,"RIGHT"}, 8, 0, 0, theme.stringHeight)
	self.controls.importCodeState.label = function()
		return self.importCodeDetail or ""
	end
	self.controls.importCodeDestination = new("DropDownControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, 0, 4, 160, theme.buttonHeight, partyDestinations)
	self.controls.importCodeDestination.tooltipText = "Destination for Import/clear\nCurrently Links Skills do not export"
	self.controls.importCodeGo = new("ButtonControl", {"LEFT",self.controls.importCodeDestination,"RIGHT"}, 8, 0, 160, theme.buttonHeight, "Import", function()
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
	self.controls.appendNotReplace = new("CheckBoxControl", {"LEFT",self.controls.importCodeGo,"RIGHT"}, 60, 0, theme.buttonHeight, "Append", function(state)
	end, "This sets the import button to append to the current party lists instead of replacing them (curses will still replace)", false)
	self.controls.appendNotReplace.x = function()
		return (self.width > theme.widthThreshold1) and 60 or (-276)
	end
	self.controls.appendNotReplace.y = function()
		return (self.width > theme.widthThreshold1) and 0 or 24
	end
	
	self.controls.clear = new("ButtonControl", {"LEFT",self.controls.appendNotReplace,"RIGHT"}, 8, 0, 160, theme.buttonHeight, "Clear", function() 
		clearInputText()
		wipeTable(self.enemyModList)
		self.enemyModList = new("ModList")
		self.build.buildFlag = true
	end)
	self.controls.clear.tooltipText = "^7Clears all the party tab imported data"
	
	self.controls.ShowAdvanceTools = new("CheckBoxControl", {"TOPLEFT",self.controls.importCodeDestination,"BOTTOMLEFT"}, 140, 4, theme.buttonHeight, "^7Show Advanced Info", function(state)
	end, "This shows the advanced info like what stats each aura/curse etc are adding, as well as enables the ability to edit them without a re-export\nDo not edit any boxes unless you know what you are doing, use copy/paste or import instead", false)
	self.controls.ShowAdvanceTools.y = function()
		return (self.width > theme.widthThreshold1) and 4 or 28
	end
	
	self.controls.removeEffects = new("ButtonControl", {"LEFT",self.controls.ShowAdvanceTools,"RIGHT"}, 8, 0, 160, theme.buttonHeight, "Disable Party Effects", function() 
		wipeTable(self.actor)
		wipeTable(self.enemyModList)
		self.actor = { Aura = {}, Curse = {}, Link = {}, modDB = new("ModDB"), output = { } }
		self.actor.modDB.actor = self.actor
		self.enemyModList = new("ModList")
		self.build.buildFlag = true
	end)
	self.controls.removeEffects.tooltipText = "^7Removes the effects of the supports, without removing the data\nUse \"rebuild all\" to apply the effects again"
	
	self.controls.rebuild = new("ButtonControl", {"LEFT",self.controls.removeEffects,"RIGHT"}, 8, 0, 160, theme.buttonHeight, "^7Rebuild All", function() 
		wipeTable(self.actor)
		wipeTable(self.enemyModList)
		self.actor = { Aura = {}, Curse = {}, Link = {}, modDB = new("ModDB"), output = { } }
		self.actor.modDB.actor = self.actor
		self.enemyModList = new("ModList")
		self:ParseBuffs(self.actor["modDB"], self.controls.editPartyMemberStats.buf, "PartyMemberStats", self.actor["output"])
		self:ParseBuffs(self.actor["Aura"], self.controls.editAuras.buf, "Aura", self.controls.simpleAuras)
		self:ParseBuffs(self.actor["Curse"], self.controls.editCurses.buf, "Curse", self.controls.simpleCurses)
		self:ParseBuffs(self.actor["Link"], self.controls.editLinks.buf, "Link", self.controls.simpleLinks)
		self:ParseBuffs(self.enemyModList, self.controls.enemyCond.buf, "EnemyConditions")
		self:ParseBuffs(self.enemyModList, self.controls.enemyMods.buf, "EnemyMods", self.controls.simpleEnemyMods)
		self.build.buildFlag = true 
	end)
	self.controls.rebuild.tooltipText = "^7Reparse all the inputs incase they have been disabled or they have changed since loading the build or importing"
	self.controls.rebuild.x = function()
		return (self.width > theme.widthThreshold1) and 8 or (-328)
	end
	self.controls.rebuild.y = function()
		return (self.width > theme.widthThreshold1) and 0 or 24
	end

	self.controls.editAurasLabel = new("LabelControl", {"TOPLEFT",self.controls.ShowAdvanceTools,"TOPLEFT"}, -140, 40, 0, theme.stringHeight, "^7Auras")
	self.controls.editAurasLabel.y = function()
		return 36 + ((self.width <= theme.widthThreshold1) and 24 or 0)
	end
	self.controls.editAuras = new("EditControl", {"TOPLEFT",self.controls.editAurasLabel,"TOPLEFT"}, 0, 18, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editAuras.width = function()
		return self.width / 2 - 16
	end
	self.controls.editAuras.height = function()
		return self.controls.editLinks.hasFocus and theme.bufferHeightSmall or theme.bufferHeightLeft()
	end
	
	self.controls.editAuras.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleAuras = new("LabelControl", {"TOPLEFT",self.controls.editAurasLabel,"TOPLEFT"}, 0, 18, 0, theme.stringHeight, "")
	self.controls.simpleAuras.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.editLinksLabel = new("LabelControl", {"TOPLEFT",self.controls.editAurasLabel,"BOTTOMLEFT"}, 0, 8, 0, theme.stringHeight, "^7Link Skills")
	self.controls.editLinksLabel.y = function()
		return self.controls.ShowAdvanceTools.state and (self.controls.editAuras.height() + 8) or (theme.lineCounter(self.controls.simpleAuras.label) + 4)
	end
	self.controls.editLinks = new("EditControl", {"TOPLEFT",self.controls.editLinksLabel,"TOPLEFT"}, 0, 18, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editLinks.width = function()
		return self.width / 2 - 16
	end
	self.controls.editLinks.height = function()
		return (self.controls.editLinks.hasFocus and theme.bufferHeightLeft() or theme.bufferHeightSmall)
	end
	self.controls.editLinks.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleLinks = new("LabelControl", {"TOPLEFT",self.controls.editLinksLabel,"TOPLEFT"}, 0, 18, 0, theme.stringHeight, "")
	self.controls.simpleLinks.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.editPartyMemberStatsLabel = new("LabelControl", {"TOPLEFT",self.controls.notesDesc,"TOPRIGHT"}, 8, 0, 0, theme.stringHeight, "^7Party Member Stats")
	self.controls.editPartyMemberStats = new("EditControl", {"TOPLEFT",self.controls.editPartyMemberStatsLabel,"BOTTOMLEFT"}, 0, 2, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editPartyMemberStats.width = function()
		return self.width / 2 - 16
	end
	self.controls.editPartyMemberStats.height = function()
		return (self.controls.editPartyMemberStats.hasFocus and (self.height - theme.bufferHeightRight) or theme.bufferHeightSmall)
	end
	self.controls.editPartyMemberStats.shown = function()
		return self.controls.ShowAdvanceTools.state
	end

	self.controls.enemyCondLabel = new("LabelControl", {"TOPLEFT",self.controls.editPartyMemberStatsLabel,"BOTTOMLEFT"}, 0, 8, 0, theme.stringHeight, "^7Enemy Conditions")
	self.controls.enemyCondLabel.y = function()
		return self.controls.ShowAdvanceTools.state and (self.controls.editPartyMemberStats.height() + 8) or 4
	end
	self.controls.enemyCond = new("EditControl", {"TOPLEFT",self.controls.enemyCondLabel,"BOTTOMLEFT"}, 0, 2, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.enemyCond.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyCond.height = function()
		return (self.controls.enemyCond.hasFocus and (self.height - theme.bufferHeightRight) or theme.bufferHeightSmall)
	end
	self.controls.enemyCond.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleEnemyCond = new("LabelControl", {"TOPLEFT",self.controls.enemyCondLabel,"TOPLEFT"}, 0, 18, 0, theme.stringHeight, "^7---------------------------\n")
	self.controls.simpleEnemyCond.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.enemyModsLabel = new("LabelControl", {"TOPLEFT",self.controls.enemyCondLabel,"BOTTOMLEFT"}, 0, 8, 0, theme.stringHeight, "^7Enemy Modifiers")
	self.controls.enemyModsLabel.y = function()
		return self.controls.ShowAdvanceTools.state and (self.controls.enemyCond.height() + 8) or (theme.lineCounter(self.controls.simpleEnemyCond.label) + 4)
	end
	self.controls.enemyMods = new("EditControl", {"TOPLEFT",self.controls.enemyModsLabel,"BOTTOMLEFT"}, 0, 2, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.enemyMods.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyMods.height = function()
		return (self.controls.enemyMods.hasFocus and (self.height - theme.bufferHeightRight) or theme.bufferHeightSmall)
	end
	self.controls.enemyMods.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleEnemyMods = new("LabelControl", {"TOPLEFT",self.controls.enemyModsLabel,"TOPLEFT"}, 0, 18, 0, theme.stringHeight, "\n")
	self.controls.simpleEnemyMods.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.editCursesLabel = new("LabelControl", {"TOPLEFT",self.controls.enemyModsLabel,"BOTTOMLEFT"}, 0, 8, 0, theme.stringHeight, "^7Curses")
	self.controls.editCursesLabel.y = function()
		return self.controls.ShowAdvanceTools.state and (self.controls.enemyMods.height() + 8) or (theme.lineCounter(self.controls.simpleEnemyMods.label) + 4)
	end
	self.controls.editCurses = new("EditControl", {"TOPLEFT",self.controls.editCursesLabel,"BOTTOMLEFT"}, 0, 2, 0, 0, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editCurses.width = function()
		return self.width / 2 - 16
	end
	self.controls.editCurses.height = function()
		return (self.controls.enemyCond.hasFocus or self.controls.enemyMods.hasFocus or self.controls.editPartyMemberStats.hasFocus) and theme.bufferHeightSmall or (self.height - theme.bufferHeightRight)
	end
	self.controls.editCurses.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleCurses = new("LabelControl", {"TOPLEFT",self.controls.editCursesLabel,"TOPLEFT"}, 0, 18, 0, theme.stringHeight, "")
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
			elseif node.attrib.name == "PartyMemberStats" then
				self.controls.editPartyMemberStats:SetText(node[1] or "")
				self:ParseBuffs(self.actor["modDB"], node[1] or "", "PartyMemberStats", self.actor["output"])
			elseif node.attrib.name == "Aura" then
				self.controls.editAuras:SetText(node[1] or "")
				self:ParseBuffs(self.actor["Aura"], node[1] or "", "Aura", self.controls.simpleAuras)
			elseif node.attrib.name == "Curse" then
				self.controls.editCurses:SetText(node[1] or "")
				self:ParseBuffs(self.actor["Curse"], node[1] or "", "Curse", self.controls.simpleCurses)
			elseif node.attrib.name == "Link Skills" then
				self.controls.editLinks:SetText(node[1] or "")
				self:ParseBuffs(self.actor["Link"], node[1] or "", "Link", self.controls.simpleLinks)
			elseif node.attrib.name == "EnemyConditions" then
				self.controls.enemyCond:SetText(node[1] or "")
				self:ParseBuffs(self.enemyModList, node[1] or "", "EnemyConditions")
			elseif node.attrib.name == "EnemyMods" then
				self.controls.enemyMods:SetText(node[1] or "")
				self:ParseBuffs(self.enemyModList, node[1] or "", "EnemyMods", self.controls.simpleEnemyMods)
			end
		elseif node.elem == "ExportedBuffs" then
			if not node.attrib.name then
				ConPrintf("missing name")
			end
			--if node.attrib.name ~= "EnemyConditions" and node.attrib.name ~= "EnemyMods" then
			---	self:ParseBuffs(self.buffExports, node[1] or "", node.attrib.name)
			--end
			--self:ParseBuffs(self.buffExports, node[1] or "", "PartyMemberStats")
			--self:ParseBuffs(self.buffExports, node[1] or "", "Aura")
			--self:ParseBuffs(self.buffExports, node[1] or "", "Curse")
			--self:ParseBuffs(self.buffExports, node[1] or "", "Link")
			--self:ParseBuffs(self.buffExports, node[1] or "", "EnemyConditions")
			--self:ParseBuffs(self.buffExports, node[1] or "", "EnemyMods")
		end
	end
	self.lastContent.PartyMemberStats = self.controls.editPartyMemberStats.buf
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
	local child
	if self.controls.editPartyMemberStats.buf and self.controls.editPartyMemberStats.buf ~= "" then
		child = { elem = "ImportedBuffs", attrib = { name = "PartyMemberStats" } }
		t_insert(child, self.controls.editPartyMemberStats.buf)
		t_insert(xml, child)
	end
	if self.controls.editAuras.buf and self.controls.editAuras.buf ~= "" then
		child = { elem = "ImportedBuffs", attrib = { name = "Aura" } }
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
	local exportString = self:exportBuffs("PlayerMods")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "PartyMemberStats" } }
		t_insert(child, exportString)
		t_insert(xml, child)
	end
	exportString = self:exportBuffs("Aura")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "Aura" } }
		t_insert(child, exportString)
		t_insert(xml, child)
	end
	exportString = self:exportBuffs("Curse")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "Curse" } }
		t_insert(child, exportString)
		t_insert(xml, child)
	end
	exportString = self:exportBuffs("Link")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "Link Skills" } }
		t_insert(child, exportString)
		t_insert(xml, child)
	end
	exportString = self:exportBuffs("EnemyConditions")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "EnemyConditions" } }
		t_insert(child, exportString)
		t_insert(xml, child)
	end
	exportString = self:exportBuffs("EnemyMods")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "EnemyMods" } }
		t_insert(child, exportString)
		t_insert(xml, child)
	end
	self.lastContent.PartyMemberStats = self.controls.editPartyMemberStats.buf
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
				elseif self.controls.editPartyMemberStats.hasFocus then
					self.controls.editPartyMemberStats:Undo()
				end
			elseif event.key == "y" and IsKeyDown("CTRL") then
				if self.controls.editAuras.hasFocus then
					self.controls.editAuras:Redo()
				elseif self.controls.editCurses.hasFocus then
					self.controls.editCurses:Redo()
				elseif self.controls.editLinks.hasFocus then
					self.controls.editLinks:Redo()
				elseif self.controls.editPartyMemberStats.hasFocus then
					self.controls.editPartyMemberStats:Redo()
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
			or self.lastContent.PartyMemberStats ~= self.controls.editPartyMemberStats.buf
			or self.lastContent.EnemyCond ~= self.controls.enemyCond.buf
			or self.lastContent.EnemyMods ~= self.controls.enemyMods.buf
			or self.lastContent.EnableExportBuffs ~= self.enableExportBuffs
			or self.lastContent.showAdvancedTools ~= self.controls.ShowAdvanceTools.state)
end

function PartyTabClass:ParseBuffs(list, buf, buffType, label)
	if buffType == "EnemyConditions" then
		for line in buf:gmatch("([^\n]*)\n?") do
			if line ~= "" then
				list:NewMod(line:gsub("Condition:", "Condition:Party:"), "FLAG", true, "Party")
			end
		end
	elseif buffType == "EnemyMods" then
		local enemyModList = {}
		local currentName
		for line in buf:gmatch("([^\n]*)\n?") do
			if not line:find("|") then
				currentName = line
				if label and currentName ~= "" then
					enemyModList[currentName] = enemyModList[currentName] or {}
				end
			else
				local mod = modLib.parseFormattedSourceMod(line)
				if mod then
					mod.source = "Party"..mod.source
					list:AddMod(mod)
					if label then
						t_insert(enemyModList[currentName], {mod.value, mod.type})
					end
				end
			end
		end
		if label then
			local count = 0
			label.label = "^7---------------------------"
			for modName, modList in pairs(enemyModList) do
				label.label = label.label.."\n"..modName..":"
				count = count + 1
				for _, mod in ipairs(modList) do
					label.label = label.label.." "..(mod[1] and "True" or mod[1]).." "..(mod[2] == "FLAG" and "" or mod[2])..", "
				end
			end
			if count > 0 then
				label.label = label.label.."\n---------------------------\n"
			else
				label.label = label.label.."\n"
			end
		end
	elseif buffType == "PartyMemberStats" then
		if not list then
		else
			for line in buf:gmatch("([^\n]*)\n?") do
				if line:find("=") then
					-- label is output for this type, as a special case
					if line:match("%.") then
						local k1, k2, v = line:match("([%w ]-%w+)%.([%w ]-%w+)=(.+)")
						label[k1] = {[k2] = tonumber(v)}
					else
						local k, v = line:match("([%w ]-%w+)=(.+)")
						label[k] = tonumber(v)
					end
				elseif line ~= "" then
					list:NewMod(line, "FLAG", true, "Party")
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
		local currentModType = (buffType == "Link") and "Link" or "Unknown"
		for line in buf:gmatch("([^\n]*)\n?") do
			if line ~= "---" and line:match("%-%-%-") then
				-- comment but not divider, skip the line
			elseif mode == "CurseLimit" and line ~= "" then
				list.limit = tonumber(line)
				mode = "Name"
			elseif mode == "Name" and line ~= "" then
				currentName = line:gsub("_Debuff", "")
				currentEffect = 0
				if line == "extraAura" or line == "otherEffects" then
					currentModType = line
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
					if currentModType == "otherEffects" then
						currentName, currentEffect, line = line:match("([%w ]-%w+)|(%w+)|(.+)")
					end
					local mod = modLib.parseFormattedSourceMod(line)
					if mod then
						for _, tag in ipairs(mod) do
							if tag.type == "GlobalEffect" and currentModType ~= "Link" and currentModType ~= "otherEffects" then
								currentModType = tag.effectType
							end
						end
						list[currentModType] = list[currentModType] or {}
						local listElement = list[currentModType]
						if currentName:sub(1,4) == "Vaal" then
							list[currentModType]["Vaal"] = list[currentModType]["Vaal"] or {}
							listElement = list[currentModType]["Vaal"]
						end
						if not listElement[currentName] then
							listElement[currentName] = {
								modList = new("ModList"),
								effectMult = currentEffect
							}
							if isMark then
								listElement[currentName].isMark = true
							end
						elseif listElement[currentName].effectMult ~= currentEffect then
							if listElement[currentName].effectMult < currentEffect then
								listElement[currentName] = {
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
								mod.source = "Party - "..mod.source
							end
							if buffType == "Link" then
								mod.name = mod.name:gsub("Parent", "PartyMember")
								for _, modTag in ipairs(mod) do
									if modTag.actor and modTag.actor == "parent" then
										modTag.actor = "partyMembers"
									end
								end
							end
							listElement[currentName].modList:AddMod(mod)
						end
					end
				end
			end
		end
		if label then
			if buffType == "Aura" then
				local labelList = {}
				label.label = "^7---------------------------\n"
				for aura, auraMod in pairs(list["Aura"] or {}) do
					if aura ~= "Vaal" then
						t_insert(labelList, aura..": "..auraMod.effectMult.."%\n")
					end
				end
				if list["Aura"] and list["Aura"]["Vaal"] then
					for aura, auraMod in pairs(list["Aura"]["Vaal"]) do
						t_insert(labelList, aura..": "..auraMod.effectMult.."%\n")
					end
				end
				for aura, auraMod in pairs(list["AuraDebuff"] or {}) do
					if not list["Aura"] or not list["Aura"][aura] then
						if aura ~= "Vaal" then
							t_insert(labelList, aura..": "..auraMod.effectMult.."%\n")
						end
					end
				end
				if list["AuraDebuff"] and list["AuraDebuff"]["Vaal"] then
					if not list["Aura"] or not list["Aura"]["Vaal"] or not list["Aura"]["Vaal"][aura] then
						for aura, auraMod in pairs(list["AuraDebuff"]["Vaal"]) do
							t_insert(labelList, aura..": "..auraMod.effectMult.."%\n")
						end
					end
				end
				if #labelList > 0 then
					table.sort(labelList)
					label.label = label.label..table.concat(labelList)
					label.label = label.label.."---------------------------\n"
				end
				if list["extraAura"] and list["extraAura"]["extraAura"] then
					label.label = label.label.."extraAuras:\n"
					for _, auraMod in ipairs(list["extraAura"]["extraAura"].modList) do
						label.label = label.label.."  "..(auraMod.type == "FLAG" and "" or (auraMod.type.." "))..auraMod.name..": "..tostring(auraMod.value).."\n"
					end
					label.label = label.label.."---------------------------\n"
				end
				if list["otherEffects"] then
					label.label = label.label.."otherEffects:\n"
					for buffName, buff in pairs(list["otherEffects"]) do
						for _, auraMod in ipairs(list["otherEffects"][buffName].modList) do
							label.label = label.label.."  "..(auraMod.type == "FLAG" and "" or (auraMod.type.." "))..auraMod.name..": "..tostring(auraMod.value).."\n"
						end
					end
					label.label = label.label.."---------------------------\n"
				end
			elseif buffType == "Link" then
				local labelList = {}
				for link, linkMod in pairs(list["Link"] or {}) do
					t_insert(labelList, link..": "..linkMod.effectMult.."%\n")
				end
				if #labelList > 0 then
					table.sort(labelList)
					label.label = "^7---------------------------\n"..table.concat(labelList).."---------------------------\n"
				else
					label.label = ""
				end
			elseif buffType == "Curse" then
				local labelList = {}
				for curse, curseMod in pairs(list["Curse"] or {}) do
					t_insert(labelList, curse..": "..curseMod.effectMult.."%\n")
				end
				if #labelList > 0 then
					table.sort(labelList)
					label.label = "^7---------------------------\n"..table.concat(labelList).."---------------------------\n"
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
			elseif buffType == "Link" or buffType == "Aura" and buffName ~= "extraAura" and buffName ~= "otherEffects" then
				buf = buf.."\n"..tostring(buff.effectMult * 100)
			end
			if buffType == "Aura" and buffName == "otherEffects" then
				for innerBuffName, innerBuff in pairs(buff) do
					for _, mod in ipairs(innerBuff.modList) do
						buf = buf.."\n"..innerBuffName.."|"..tostring(innerBuff.effectMult * 100).."|"..modLib.formatSourceMod(mod)
					end
				end
				buf = buf.."\n---"
			elseif buffType == "Curse" or buffType == "Aura" or buffType == "Link" then
				for _, mod in ipairs(buff.modList) do
					buf = buf.."\n"..modLib.formatSourceMod(mod)
				end
				buf = buf.."\n---"
			elseif buffType == "EnemyMods" then
				if buff.MultiStat then
					for _, buffInner in ipairs(buff) do
						buf = buf.."\n"..modLib.formatSourceMod(buffInner)
					end
				else
					buf = buf.."\n"..modLib.formatSourceMod(buff)
				end
			end
		end
	end
	wipeTable(self.buffExports[buffType])
	self.buffExports[buffType] = { ConvertedToText = true }
	self.buffExports[buffType].string = buf
	return buf
end