-- Path of Building
--
-- Module: Party Tab
-- Party tab for the current build.
--
local pairs = pairs
local ipairs = ipairs
local s_format = string.format
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max
local m_min = math.min
local m_floor = math.floor

local maximumMembers = 6

local PartyTabClass = newClass("PartyTab", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

	self.build = build
	
	self.selectedMember = 1
	self.partyMembers = { { } }

	self.actor = { Aura = { }, Curse = { }, Warcry = { }, Link = { }, modDB = new("ModDB"), output = { } }
	self.actor.modDB.actor = self.actor
	self.enemyModList = new("ModList")
	self.buffExports = { }
	self.enableExportBuffs = false

	self.lastContent = {
		Aura = "",
		Curse = "",
		Warcry = "",
		Link = "",
		EnemyCond = "",
		EnemyMods = "",
		EnableExportBuffs = false,
		selectedMember = 1,
		showAdvancedTools = false,
	}
	
	local partyDestinations = { "All", "Party Member Stats", "Aura", "Curse", "Warcry Skills", "Link Skills", "EnemyConditions", "EnemyMods" }
	
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
		widthThreshold2 = 1150,
		bufferHeightSmall = 106,
		bufferHeightLeft = function()
			-- 2 elements
			return (self.height - 418 - ((self.width > 1350) and 0 or 24) - self.controls.importCodeHeader.y() - self.controls.editAurasLabel.y())
		end,
		-- 4 elements
		bufferHeightRight = 434,
	}

	local notesDesc = [[^7To import a build it must be exported with "Export support" enabled in the import/export tab
	Auras with the highest effect will take priority, your curses will take priority over a support's
	
	All of these effects can be found in the Calcs tab]]
	
	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, {8, 8, 150, theme.stringHeight}, notesDesc)
	self.controls.notesDesc.width = function()
		local width = self.width / 2 - 16
		if width ~= self.controls.notesDesc.lastWidth then
			self.controls.notesDesc.lastWidth = width
			self.controls.notesDesc.label = table.concat(main:WrapString(notesDesc, theme.stringHeight, width - 50), "\n")
		end
		return width
	end
	self.controls.importCodeHeader = new("LabelControl", {"TOPLEFT",self.controls.notesDesc,"BOTTOMLEFT"}, {0, 32, 0, theme.stringHeight}, "^7Enter a build code/URL below:")
	self.controls.importCodeHeader.y = function()
		return theme.lineCounter(self.controls.notesDesc.label) + 4
	end
	
	local clearInputText = function()
		if self.selectedMember == 1 then
			return
		end
		local partyMember = self.partyMembers[self.selectedMember]
		local destination = partyDestinations[self.controls.importCodeDestination.selIndex]
		if destination == "All" or destination == "Party Member Stats" then
			self.controls.editPartyMemberStats:SetText("")
			partyMember.editPartyMemberStats = ""
		end
		if destination == "All" or destination == "Aura" then
			self.controls.simpleAuras.label = ""
			partyMember.simpleAuras = ""
			self.controls.editAuras:SetText("")
			partyMember.editAuras = ""
			wipeTable(partyMember["Aura"])
			partyMember["Aura"] = {}
		end
		if destination == "All" or destination == "Curse" then
			self.controls.simpleCurses.label = ""
			partyMember.simpleCurses = ""
			self.controls.editCurses:SetText("")
			partyMember.editCurses = ""
			wipeTable(partyMember["Curse"])
			partyMember["Curse"] = {}
		end
		if destination == "All" or destination == "Warcry Skills" then
			self.controls.simpleWarcries.label = ""
			partyMember.simpleWarcries = ""
			self.controls.editWarcries:SetText("")
			partyMember.editWarcries = ""
			wipeTable(partyMember["Warcry"])
			partyMember["Warcry"] = {}
		end
		if destination == "All" or destination == "Link Skills" then
			self.controls.simpleLinks.label = ""
			partyMember.simpleLinks = ""
			self.controls.editLinks:SetText("")
			partyMember.editLinks = ""
			wipeTable(partyMember["Link"])
			partyMember["Link"] = {}
		end
		if destination == "All" or destination == "EnemyConditions" then
			self.controls.simpleEnemyCond.label = "^7---------------------------\n"
			partyMember.simpleEnemyCond = ""
			self.controls.enemyCond:SetText("")
			partyMember.enemyCond = ""
		end
		if destination == "All" or destination == "EnemyMods" then
			self.controls.simpleEnemyMods.label = "\n"
			partyMember.simpleEnemyMods = ""
			self.controls.enemyMods:SetText("")
			partyMember.enemyMods = ""
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
	
	local finishImport = function(replaceMember)
		if not self.importCodeValid or self.importCodeFetching then
			return
		end
		
		if not replaceMember then
			t_insert(self.partyMembers, { name = "New Member "..(#self.partyMembers), Aura = {}, Curse = {}, Warcry = { }, Link = {}, modDB = new("ModDB"), output = { }, enemyModList = new("ModList") })
			self:SwapSelectedMember(#self.partyMembers, true)
			self.controls["Member"..#self.partyMembers.."Button"].label = "^7".."New Member "..(#self.partyMembers - 1)
		end
		local partyMember = self.partyMembers[self.selectedMember]
		local destination = partyDestinations[self.controls.importCodeDestination.selIndex]
		
		local currentCurseBuffer = nil
		local currentLinkBuffer = nil
		if replaceMember then
			if self.controls.appendNotReplace.state ~= true then
				clearInputText()
			else
				if destination == "All" or destination == "Aura" then
					wipeTable(partyMember["Aura"])
					partyMember["Aura"] = { }
				end
				if destination == "All" or destination == "Curse" then
					currentCurseBuffer = partyMember.editCurses
					self.controls.editCurses:SetText("") --curses do not play nicely with append atm, need to fix
					partyMember.editCurses = ""
					wipeTable(partyMember["Curse"])
					partyMember["Curse"] = { }
				end
				if destination == "All" or destination == "Warcry Skills" then
					wipeTable(partyMember["Warcry"])
					partyMember["Warcry"] = { }
				end
				if destination == "All" or destination == "Link Skills" then
					 -- only one link can be applied at a time anyway
					currentLinkBuffer = partyMember.editLinks
					self.controls.editLinks:SetText("")
					partyMember.editLinks = ""
					wipeTable(partyMember["Link"])
					partyMember["Link"] = { }
				end
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
							if destination == "All" or destination == "Party Member Stats" then
								partyMember.editPartyMemberStats = partyMember.editPartyMemberStats or ""
								if #partyMember.editPartyMemberStats > 0 then
									node[1] = partyMember.editPartyMemberStats.."\n"..(node[1] or "")
								end
								self.controls.editPartyMemberStats:SetText(node[1] or "")
								self:ParseBuffs("PartyMemberStats", partyMember, node[1])
							end
						elseif node.attrib.name == "Aura" then
							if destination == "All" or destination == "Aura" then
								partyMember.editAuras = partyMember.editAuras or ""
								if #partyMember.editAuras > 0 then
									node[1] = partyMember.editAuras.."\n"..(node[1] or "")
								end
								self.controls.editAuras:SetText(node[1] or "")
								self:ParseBuffs("Aura", partyMember, node[1])
							end
						elseif node.attrib.name == "Curse" then
							if destination == "All" or destination == "Curse" then
								partyMember.editCurses = partyMember.editCurses or ""
								if #partyMember.editCurses > 0 then
									node[1] = partyMember.editCurses.."\n"..(node[1] or "")
								end
								if currentCurseBuffer and node[1] =="--- Curse Limit ---\n1" then
									node[1] = currentCurseBuffer
								end
								self.controls.editCurses:SetText(node[1] or "")
								self:ParseBuffs("Curse", partyMember, node[1])
							end
						elseif node.attrib.name == "Warcry Skills" then
							if destination == "All" or destination == "Warcry Skills" then
								partyMember.editWarcries = partyMember.editWarcries or ""
								if #partyMember.editWarcries > 0 then
									node[1] = partyMember.editWarcries.."\n"..(node[1] or "")
								end
								self.controls.editWarcries:SetText(node[1] or "")
								self:ParseBuffs("Warcry", partyMember, node[1])
							end
						elseif node.attrib.name == "Link Skills" then
							if destination == "All" or destination == "Link Skills" then
								partyMember.editLinks = partyMember.editLinks or ""
								if #partyMember.editLinks > 0 then
									node[1] = partyMember.editLinks.."\n"..(node[1] or "")
								end
								if currentLinkBuffer and (not node[1] or node[1] == "") then
									node[1] = currentLinkBuffer
								end
								self.controls.editLinks:SetText(node[1] or "")
								self:ParseBuffs("Link", partyMember, node[1])
							end
						elseif node.attrib.name == "EnemyConditions" then
							if destination == "All" or destination == "EnemyConditions" then
								partyMember.enemyCond = partyMember.enemyCond or ""
								if #partyMember.enemyCond > 0 then
									node[1] = partyMember.enemyCond.."\n"..(node[1] or "")
								end
								self.controls.enemyCond:SetText(node[1] or "")
							end
						elseif node.attrib.name == "EnemyMods" then
							if destination == "All" or destination == "EnemyMods" then
								partyMember.enemyMods = partyMember.enemyMods or ""
								if #partyMember.enemyMods > 0 then
									node[1] = partyMember.enemyMods.."\n"..(node[1] or "")
								end
								self.controls.enemyMods:SetText(node[1] or "")
							end
						end
					end
				end
				if destination == "All" or destination == "EnemyConditions" or destination == "EnemyMods" then
					wipeTable(partyMember.enemyModList)
					partyMember.enemyModList = new("ModList")
					self:ParseBuffs("EnemyConditions", partyMember, self.controls.enemyCond.buf)
					self:ParseBuffs("EnemyMods", partyMember, self.controls.enemyMods.buf)
				end
				self.build.buildFlag = true 
				break
			end
		end
		self:CombineBuffs()
		self:SwapSelectedMember(self.selectedMember, true)
	end
	
	self.controls.importCodeIn = new("EditControl", {"TOPLEFT",self.controls.importCodeHeader,"BOTTOMLEFT"}, {0, 4, 328, theme.buttonHeight}, "", nil, nil, nil, importCodeHandle)
	self.controls.importCodeIn.width = function()
		return (self.width > 880) and 328 or (self.width / 2 - 100)
	end
	self.controls.importCodeIn.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeNewMember.onClick()
		end
	end
	self.controls.importCodeState = new("LabelControl", {"LEFT",self.controls.importCodeIn,"RIGHT"}, {8, 0, 0, theme.stringHeight})
	self.controls.importCodeState.label = function()
		return self.importCodeDetail or ""
	end
	self.controls.importCodeDestination = new("DropDownControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, {0, 4, 160, theme.buttonHeight}, partyDestinations)
	self.controls.importCodeDestination.tooltipText = "Destination for Import/clear"
	self.controls.importCodeNewMember = new("ButtonControl", {"LEFT",self.controls.importCodeDestination,"RIGHT"}, {8, 0, 160, theme.buttonHeight}, "Import (New Member)", function()
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
					finishImport(false)
				end
			end)
			return
		end

		finishImport(false)
	end)
	self.controls.importCodeNewMember.enabled = function()
		return (self.importCodeValid and not self.importCodeFetching) and (#self.partyMembers < maximumMembers)
	end
	self.controls.importCodeNewMember.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeNewMember.onClick()
		end
	end
	self.controls.importCodeOverwriteMember = new("ButtonControl", {"LEFT",self.controls.importCodeNewMember,"RIGHT"}, {8, 0, 180, theme.buttonHeight}, "Import (Overwrite Member)", function()
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
					finishImport(true)
				end
			end)
			return
		end

		finishImport(true)
	end)
	self.controls.importCodeOverwriteMember.enabled = function()
		return (self.importCodeValid and not self.importCodeFetching) and (self.selectedMember ~= 1)
	end
	self.controls.importCodeOverwriteMember.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeOverwriteMember.onClick()
		end
	end
	self.controls.importCodeOverwriteMember.x = function()
		return (self.width > theme.widthThreshold2) and 8 or (-328)
	end
	self.controls.importCodeOverwriteMember.y = function()
		return (self.width > theme.widthThreshold2) and 0 or 24
	end
	
	self.controls.ShowAdvanceTools = new("CheckBoxControl", {"TOPLEFT",self.controls.importCodeDestination,"BOTTOMLEFT"}, {140, 4, theme.buttonHeight}, "^7Show Advanced Info", function(state)
	end, "This shows the advanced info like what stats each aura/curse etc are adding, advanced buttons like disable/rebuild,\nas well as enables the ability to edit them without a re-export\nDo not edit any boxes unless you know what you are doing, use copy/paste or import instead", false)
	self.controls.ShowAdvanceTools.y = function()
		return (self.width > theme.widthThreshold2) and 4 or 28
	end
	
	self.controls.renameMember = new("EditControl", {"LEFT",self.controls.ShowAdvanceTools,"RIGHT"}, {8, 0, 160, theme.buttonHeight}, "", nil, "%^", 15, function(buf)
		if self.selectedMember ~= 1 then
			self.controls["Member"..self.selectedMember.."Button"].label = (self.partyMembers[self.selectedMember].NameColour or "^7")..buf
			self.partyMembers[self.selectedMember].name = buf
		end
	end, theme.stringHeight)
	self.controls.renameMember.tooltipText = "^7Renames the Current Party Member"
	self.controls.renameMember.enabled = function()
		return self.selectedMember ~= 1
	end
	
	self.controls.deleteMember = new("ButtonControl", {"LEFT",self.controls.renameMember,"RIGHT"}, {8, 0, 160, theme.buttonHeight}, "^7Delete Member", function()
		wipeTable(self.partyMembers[self.selectedMember])
		t_remove(self.partyMembers, self.selectedMember)
		for i = self.selectedMember, #self.partyMembers do
			self.controls["Member"..i.."Button"].label = (self.partyMembers[i].NameColour or "^7")..self.partyMembers[i].name
		end
		self:CombineBuffs()
		self:SwapSelectedMember(1, false)
		self.build.buildFlag = true
	end)
	self.controls.deleteMember.tooltipText = "^7Removes the Current Party Member"
	self.controls.deleteMember.x = function()
		return (self.width > theme.widthThreshold2) and 8 or (-142)
	end
	self.controls.deleteMember.y = function()
		return (self.width > theme.widthThreshold2) and 0 or -24
	end
	
	self.controls.clear = new("ButtonControl", {"TOPLEFT",self.controls.ShowAdvanceTools,"TOPLEFT"}, {-140, 30, 160, theme.buttonHeight}, "^7Clear", function() 
		clearInputText()
		self:CombineBuffs()
		self.build.buildFlag = true
	end)
	self.controls.clear.tooltipText = "^7Clears all the party tab imported data"
	self.controls.clear.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	
	self.controls.appendNotReplace = new("CheckBoxControl", {"LEFT",self.controls.clear,"RIGHT"}, {60, 0, theme.buttonHeight}, "^7Append", function(state)
	end, "This sets the import button to append to the current party lists instead of replacing them (curses will still replace)", false)
	
	self.controls.removeEffects = new("ButtonControl", {"LEFT",self.controls.appendNotReplace,"RIGHT"}, {8, 0, 160, theme.buttonHeight}, "Disable Party Effects", function()
		if self.selectedMember == 1 then
			for i, partyMember in ipairs(self.partyMembers) do
				if i ~= 1 then
					partyMember.NameColour = "^1"
					self.controls["Member"..i.."Button"].label = "^1"..partyMember.name
					partyMember["Aura"] = { }
					partyMember["Curse"] = { }
					partyMember["Warcry"] = { }
					partyMember["Link"] = { }
					partyMember["modDB"] = new("ModDB")
					partyMember.modDB.actor = partyMember
					partyMember["output"] = { }
					wipeTable(partyMember.enemyModList)
					partyMember.enemyModList = new("ModList")
				end
			end
		else
			local partyMember = self.partyMembers[self.selectedMember]
			partyMember.NameColour = "^1"
			self.controls["Member"..self.selectedMember.."Button"].label = "^1"..partyMember.name
			partyMember["Aura"] = { }
			partyMember["Curse"] = { }
			partyMember["Warcry"] = { }
			partyMember["Link"] = { }
			partyMember["modDB"] = new("ModDB")
			partyMember.modDB.actor = partyMember
			partyMember["output"] = { }
			wipeTable(partyMember.enemyModList)
			partyMember.enemyModList = new("ModList")
		end
		self:CombineBuffs()
		self:SwapSelectedMember(self.selectedMember, false)
		self.build.buildFlag = true
	end)
	self.controls.removeEffects.tooltipText = "^7Removes the effects of the supports, without removing the data\nUse \"rebuild all\" to apply the effects again"
	self.controls.removeEffects.x = function()
		return (self.width > theme.widthThreshold1) and 8 or (-240)
	end
	self.controls.removeEffects.y = function()
		return (self.width > theme.widthThreshold1) and 0 or 24
	end
	
	self.controls.rebuild = new("ButtonControl", {"LEFT",self.controls.removeEffects,"RIGHT"}, {8, 0, 160, theme.buttonHeight}, "^7Rebuild All", function()
		if self.selectedMember == 1 then
			for i, partyMember in ipairs(self.partyMembers) do
				if i ~= 1 then
					partyMember.NameColour = "^7"
					self.controls["Member"..i.."Button"].label = "^7"..partyMember.name
					partyMember["Aura"] = { }
					partyMember["Curse"] = { }
					partyMember["Warcry"] = { }
					partyMember["Link"] = { }
					partyMember["modDB"] = new("ModDB")
					partyMember.modDB.actor = partyMember
					partyMember["output"] = { }
					wipeTable(partyMember.enemyModList)
					partyMember.enemyModList = new("ModList")
					self:ParseBuffs("PartyMemberStats", partyMember, partyMember.editPartyMemberStats or "")
					self:ParseBuffs("Aura", partyMember, partyMember.editAuras or "")
					self:ParseBuffs("Curse", partyMember, partyMember.editCurses or "")
					self:ParseBuffs("Warcry", partyMember, partyMember.editWarcries or "")
					self:ParseBuffs("Link", partyMember, partyMember.editLinks or "")
					self:ParseBuffs("EnemyConditions", partyMember, partyMember.enemyCond or "")
					self:ParseBuffs("EnemyMods", partyMember, partyMember.enemyMods or "")
				end
			end
		else
			local partyMember = self.partyMembers[self.selectedMember]
			partyMember.NameColour = "^7"
			self.controls["Member"..self.selectedMember.."Button"].label = "^7"..partyMember.name
			partyMember["Aura"] = { }
			partyMember["Curse"] = { }
			partyMember["Warcry"] = { }
			partyMember["Link"] = { }
			partyMember["modDB"] = new("ModDB")
			partyMember.modDB.actor = partyMember
			partyMember["output"] = { }
			wipeTable(partyMember.enemyModList)
			partyMember.enemyModList = new("ModList")
			self:ParseBuffs("PartyMemberStats", partyMember, self.controls.editPartyMemberStats.buf)
			self:ParseBuffs("Aura", partyMember, self.controls.editAuras.buf)
			self:ParseBuffs("Curse", partyMember, self.controls.editCurses.buf)
			self:ParseBuffs("Warcry", partyMember, self.controls.editWarcries.buf)
			self:ParseBuffs("Link", partyMember, self.controls.editLinks.buf)
			self:ParseBuffs("EnemyConditions", partyMember, self.controls.enemyCond.buf)
			self:ParseBuffs("EnemyMods", partyMember, self.controls.enemyMods.buf)
		end
		self:CombineBuffs()
		self:SwapSelectedMember(self.selectedMember, false)
		self.build.buildFlag = true 
	end)
	self.controls.rebuild.tooltipText = "^7Reparse all the inputs incase they have been disabled or they have changed since loading the build or importing"
	
	self.controls.overviewButton = new("ButtonControl", {"TOPLEFT",self.controls.ShowAdvanceTools,"TOPLEFT"}, {-140, 30, 140, theme.buttonHeight}, "^7Overview", function()
		self:SwapSelectedMember(1, true)
	end)
	self.controls.overviewButton.tooltipText = "^7 Overview of everything all the other party members give"
	self.controls.overviewButton.width = function()
		return m_floor(m_min((self.width / 2) / m_min(#self.partyMembers, ((self.width > theme.widthThreshold1) and 6 or 3)) - 20, 160))
	end
	self.controls.overviewButton.y = function()
		return self.controls.ShowAdvanceTools.state and (60 + ((self.width > theme.widthThreshold1) and 0 or 24)) or 30
	end
	
	for i = 2, maximumMembers do
		self.controls["Member"..i.."Button"] = new("ButtonControl", {"LEFT",(i == 2) and self.controls.overviewButton or self.controls["Member"..(i - 1).."Button"],"RIGHT"}, {8, 0, 140, theme.buttonHeight}, "^7Member "..i, function()
			self:SwapSelectedMember(i, true)
		end)
		self.controls["Member"..i.."Button"].tooltipText = "^7 Swap to the "..({"1st","2nd","3rd","4th","5th"})[(i - 1)].." Party member"
		self.controls["Member"..i.."Button"].shown = function()
			return (#self.partyMembers >= i)
		end
		self.controls["Member"..i.."Button"].width = function()
			return m_floor(m_min((self.width / 2) / m_min(#self.partyMembers, ((self.width > theme.widthThreshold1) and 6 or 3)) - 20, 160))
		end
	end
	self.controls["Member4Button"].x = function()
		return (self.width > theme.widthThreshold1) and 8 or (-self.controls["Member4Button"].width()*3-16)
	end
	self.controls["Member4Button"].y = function()
		return (self.width > theme.widthThreshold1) and 0 or 24
	end

	local rebuildColourFunction = function(buf)
		if not self.partyMembers[self.selectedMember].NameColour or self.partyMembers[self.selectedMember].NameColour ~= "^1" then
			self.partyMembers[self.selectedMember].NameColour = "^4"
			self.controls["Member"..self.selectedMember.."Button"].label = "^4"..self.partyMembers[self.selectedMember].name
		end
	end
	self.controls.editAurasLabel = new("LabelControl", {"TOPLEFT",self.controls.overviewButton,"TOPLEFT"}, {0, 40, 0, theme.stringHeight}, "^7Auras")
	self.controls.editAurasLabel.y = function()
		return 36 + ((self.width <= theme.widthThreshold1) and 24 or 0)
	end
	self.controls.editAuras = new("EditControl", {"TOPLEFT",self.controls.editAurasLabel,"TOPLEFT"}, {0, 18, 0, 0}, "", nil, "^%C\t\n", nil, rebuildColourFunction, 14, true)
	self.controls.editAuras.width = function()
		return self.width / 2 - 16
	end
	self.controls.editAuras.height = function()
		return (self.controls.editWarcries.hasFocus or self.controls.editLinks.hasFocus) and theme.bufferHeightSmall or theme.bufferHeightLeft()
	end
	
	self.controls.editAuras.shown = function()
		return self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)
	end
	self.controls.simpleAuras = new("LabelControl", {"TOPLEFT",self.controls.editAurasLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "")
	self.controls.simpleAuras.shown = function()
		return not self.controls.ShowAdvanceTools.state or (self.selectedMember == 1)
	end

	self.controls.editWarcriesLabel = new("LabelControl", {"TOPLEFT",self.controls.editAurasLabel,"BOTTOMLEFT"}, {0, 8, 0, theme.stringHeight}, "^7Warcry Skills")
	self.controls.editWarcriesLabel.y = function()
		return (self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)) and (self.controls.editAuras.height() + 8) or (theme.lineCounter(self.controls.simpleAuras.label) + 4)
	end
	self.controls.editWarcries = new("EditControl", {"TOPLEFT",self.controls.editWarcriesLabel,"TOPLEFT"}, {0, 18, 0, 0}, "", nil, "^%C\t\n", nil, rebuildColourFunction, 14, true)
	self.controls.editWarcries.width = function()
		return self.width / 2 - 16
	end
	self.controls.editWarcries.height = function()
		return (self.controls.editWarcries.hasFocus and theme.bufferHeightLeft() or theme.bufferHeightSmall)
	end
	self.controls.editWarcries.shown = function()
		return self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)
	end
	self.controls.simpleWarcries = new("LabelControl", {"TOPLEFT",self.controls.editWarcriesLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "")
	self.controls.simpleWarcries.shown = function()
		return not self.controls.ShowAdvanceTools.state or (self.selectedMember == 1)
	end

	self.controls.editLinksLabel = new("LabelControl", {"TOPLEFT",self.controls.editWarcriesLabel,"BOTTOMLEFT"}, {0, 8, 0, theme.stringHeight}, "^7Link Skills")
	self.controls.editLinksLabel.y = function()
		return (self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)) and (self.controls.editWarcries.height() + 8) or (theme.lineCounter(self.controls.simpleWarcries.label) + 4)
	end
	self.controls.editLinks = new("EditControl", {"TOPLEFT",self.controls.editLinksLabel,"TOPLEFT"}, {0, 18, 0, 0}, "", nil, "^%C\t\n", nil, rebuildColourFunction, 14, true)
	self.controls.editLinks.width = function()
		return self.width / 2 - 16
	end
	self.controls.editLinks.height = function()
		return (self.controls.editLinks.hasFocus and theme.bufferHeightLeft() or theme.bufferHeightSmall)
	end
	self.controls.editLinks.shown = function()
		return self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)
	end
	self.controls.simpleLinks = new("LabelControl", {"TOPLEFT",self.controls.editLinksLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "")
	self.controls.simpleLinks.shown = function()
		return not self.controls.ShowAdvanceTools.state or (self.selectedMember == 1)
	end

	self.controls.editPartyMemberStatsLabel = new("LabelControl", {"TOPLEFT",self.controls.notesDesc,"TOPRIGHT"}, {8, 0, 0, theme.stringHeight}, "^7Party Member Stats")
	self.controls.editPartyMemberStats = new("EditControl", {"TOPLEFT",self.controls.editPartyMemberStatsLabel,"BOTTOMLEFT"}, {0, 2, 0, 0}, "", nil, "^%C\t\n", nil, rebuildColourFunction, 14, true)
	self.controls.editPartyMemberStats.width = function()
		return self.width / 2 - 16
	end
	self.controls.editPartyMemberStats.height = function()
		return (self.controls.editPartyMemberStats.hasFocus and (self.height - theme.bufferHeightRight) or theme.bufferHeightSmall)
	end
	self.controls.editPartyMemberStats.shown = function()
		return self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)
	end

	self.controls.enemyCondLabel = new("LabelControl", {"TOPLEFT",self.controls.editPartyMemberStatsLabel,"BOTTOMLEFT"}, {0, 8, 0, theme.stringHeight}, "^7Enemy Conditions")
	self.controls.enemyCondLabel.y = function()
		return (self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)) and (self.controls.editPartyMemberStats.height() + 8) or 4
	end
	self.controls.enemyCond = new("EditControl", {"TOPLEFT",self.controls.enemyCondLabel,"BOTTOMLEFT"}, {0, 2, 0, 0}, "", nil, "^%C\t\n", nil, rebuildColourFunction, 14, true)
	self.controls.enemyCond.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyCond.height = function()
		return (self.controls.enemyCond.hasFocus and (self.height - theme.bufferHeightRight) or theme.bufferHeightSmall)
	end
	self.controls.enemyCond.shown = function()
		return self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)
	end
	self.controls.simpleEnemyCond = new("LabelControl", {"TOPLEFT",self.controls.enemyCondLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "^7---------------------------\n")
	self.controls.simpleEnemyCond.shown = function()
		return not self.controls.ShowAdvanceTools.state or (self.selectedMember == 1)
	end

	self.controls.enemyModsLabel = new("LabelControl", {"TOPLEFT",self.controls.enemyCondLabel,"BOTTOMLEFT"}, {0, 8, 0, theme.stringHeight}, "^7Enemy Modifiers")
	self.controls.enemyModsLabel.y = function()
		return (self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)) and (self.controls.enemyCond.height() + 8) or (theme.lineCounter(self.controls.simpleEnemyCond.label) + 4)
	end
	self.controls.enemyMods = new("EditControl", {"TOPLEFT",self.controls.enemyModsLabel,"BOTTOMLEFT"}, {0, 2, 0, 0}, "", nil, "^%C\t\n", nil, rebuildColourFunction, 14, true)
	self.controls.enemyMods.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyMods.height = function()
		return (self.controls.enemyMods.hasFocus and (self.height - theme.bufferHeightRight) or theme.bufferHeightSmall)
	end
	self.controls.enemyMods.shown = function()
		return self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)
	end
	self.controls.simpleEnemyMods = new("LabelControl", {"TOPLEFT",self.controls.enemyModsLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "\n")
	self.controls.simpleEnemyMods.shown = function()
		return not self.controls.ShowAdvanceTools.state or (self.selectedMember == 1)
	end

	self.controls.editCursesLabel = new("LabelControl", {"TOPLEFT",self.controls.enemyModsLabel,"BOTTOMLEFT"}, {0, 8, 0, theme.stringHeight}, "^7Curses")
	self.controls.editCursesLabel.y = function()
		return (self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)) and (self.controls.enemyMods.height() + 8) or (theme.lineCounter(self.controls.simpleEnemyMods.label) + 4)
	end
	self.controls.editCurses = new("EditControl", {"TOPLEFT",self.controls.editCursesLabel,"BOTTOMLEFT"}, {0, 2, 0, 0}, "", nil, "^%C\t\n", nil, rebuildColourFunction, 14, true)
	self.controls.editCurses.width = function()
		return self.width / 2 - 16
	end
	self.controls.editCurses.height = function()
		return (self.controls.enemyCond.hasFocus or self.controls.enemyMods.hasFocus or self.controls.editPartyMemberStats.hasFocus) and theme.bufferHeightSmall or (self.height - theme.bufferHeightRight)
	end
	self.controls.editCurses.shown = function()
		return self.controls.ShowAdvanceTools.state and (self.selectedMember ~= 1)
	end
	self.controls.simpleCurses = new("LabelControl", {"TOPLEFT",self.controls.editCursesLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "")
	self.controls.simpleCurses.shown = function()
		return not self.controls.ShowAdvanceTools.state or (self.selectedMember == 1)
	end
	self:SelectControl(self.controls.editAuras)
end)

function PartyTabClass:Load(xml, fileName)
	local unknownMember
	for _, node in ipairs(xml) do
		if node.elem == "ImportedMember" then
			if not node.attrib.name then
				ConPrintf("missing name")
			else
				t_insert(self.partyMembers, { name = node.attrib.name, Aura = {}, Curse = {}, Warcry = { }, Link = {}, modDB = new("ModDB"), output = { }, enemyModList = new("ModList") })
				self.controls["Member"..#self.partyMembers.."Button"].label = "^7"..node.attrib.name
				local currentMember = self.partyMembers[#self.partyMembers]
				for _, node2 in ipairs(node) do
					if node2.attrib.name == "PartyMemberStats" then
						currentMember.editPartyMemberStats = node2[1] or ""
						self:ParseBuffs("PartyMemberStats", currentMember, node2[1] or "")
					elseif node2.attrib.name == "Aura" then
						currentMember.editAuras = node2[1] or ""
						self:ParseBuffs("Aura", currentMember, node2[1] or "")
					elseif node2.attrib.name == "Curse" then
						currentMember.editCurses = node2[1] or ""
						self:ParseBuffs("Curse", currentMember, node2[1] or "")
					elseif node2.attrib.name == "Warcry Skills" then
						currentMember.editWarcries = node2[1] or ""
						self:ParseBuffs("Warcry", currentMember, node2[1] or "")
					elseif node2.attrib.name == "Link Skills" then
						currentMember.editLinks = node2[1] or ""
						self:ParseBuffs("Link", currentMember, node2[1] or "")
					elseif node2.attrib.name == "EnemyConditions" then
						currentMember.enemyCond = node2[1] or ""
						self:ParseBuffs("EnemyConditions", currentMember, node2[1] or "")
					elseif node2.attrib.name == "EnemyMods" then
						currentMember.enemyMods = node2[1] or ""
						self:ParseBuffs("EnemyMods", currentMember, node2[1] or "")
					end
				end
			end
		elseif node.elem == "ImportedBuffs" then
			if not unknownMember then
				t_insert(self.partyMembers, { name = "Unknown", Aura = {}, Curse = {}, Warcry = { }, Link = {}, modDB = new("ModDB"), output = { }, enemyModList = new("ModList") })
				self.controls["Member"..#self.partyMembers.."Button"].label = "^7Unknown"
				unknownMember = self.partyMembers[#self.partyMembers]
			end
			if not node.attrib.name then
				ConPrintf("missing name")
			elseif node.attrib.name == "PartyMemberStats" then
				unknownMember.editPartyMemberStats = node[1] or ""
				self:ParseBuffs("PartyMemberStats", unknownMember, node[1] or "")
			elseif node.attrib.name == "Aura" then
				unknownMember.editAuras = node[1] or ""
				self:ParseBuffs("Aura", unknownMember, node[1] or "")
			elseif node.attrib.name == "Curse" then
				unknownMember.editCurses = node[1] or ""
				self:ParseBuffs("Curse", unknownMember, node[1] or "")
			elseif node.attrib.name == "Warcry Skills" then
				unknownMember.editWarcries = node[1] or ""
				self:ParseBuffs("Warcry", unknownMember, node[1] or "")
			elseif node.attrib.name == "Link Skills" then
				unknownMember.editLinks = node[1] or ""
				self:ParseBuffs("Link", unknownMember, node[1] or "")
			elseif node.attrib.name == "EnemyConditions" then
				unknownMember.editPartyMemberStats = node[1] or ""
				self:ParseBuffs("EnemyConditions", unknownMember, node[1] or "")
			elseif node.attrib.name == "EnemyMods" then
				unknownMember.enemyMods = node[1] or ""
				self:ParseBuffs("EnemyMods", unknownMember, node[1] or "")
			end
		elseif node.elem == "ExportedBuffs" then
			if not node.attrib.name then
				ConPrintf("missing name")
			end
		end
	end
	self:CombineBuffs()
	
	self.controls.importCodeDestination:SelByValue(xml.attrib.destination or "All")
	self.controls.appendNotReplace.state = xml.attrib.append == "true"
	self.controls.ShowAdvanceTools.state = xml.attrib.ShowAdvanceTools == "true"
	self:SwapSelectedMember((tonumber(xml.attrib.selectedMember) or 1), false)
	
	self.lastContent.PartyMemberStats = self.controls.editPartyMemberStats.buf
	self.lastContent.Aura = self.controls.editAuras.buf
	self.lastContent.Curse = self.controls.editCurses.buf
	self.lastContent.Warcry = self.controls.editWarcries.buf
	self.lastContent.Link = self.controls.editLinks.buf
	self.lastContent.EnemyCond = self.controls.enemyCond.buf
	self.lastContent.EnemyMods = self.controls.enemyMods.buf
	self.lastContent.EnableExportBuffs = self.enableExportBuffs
	self.lastContent.selectedMember = self.selectedMember
	
	self.lastContent.showAdvancedTools = self.controls.ShowAdvanceTools.state
end

function PartyTabClass:Save(xml)
	local child
	for i, partyMember in ipairs(self.partyMembers) do
		if i ~= 1 then
			local member = { elem = "ImportedMember", attrib = { name = partyMember.name } }
			if partyMember.editPartyMemberStats and partyMember.editPartyMemberStats ~= "" then
				child = { elem = "ImportedBuffs", attrib = { name = "PartyMemberStats" } }
				t_insert(child, partyMember.editPartyMemberStats)
				t_insert(member, child)
			end
			if partyMember.editAuras and partyMember.editAuras ~= "" then
				child = { elem = "ImportedBuffs", attrib = { name = "Aura" } }
				t_insert(child, partyMember.editAuras)
				t_insert(member, child)
			end
			if partyMember.editCurses and partyMember.editCurses ~= "" then
				child = { elem = "ImportedBuffs", attrib = { name = "Curse" } }
				t_insert(child, partyMember.editCurses)
				t_insert(member, child)
			end
			if partyMember.editWarcries and partyMember.editWarcries ~= "" then
				child = { elem = "ImportedBuffs", attrib = { name = "Warcry Skills" } }
				t_insert(child, partyMember.editWarcries)
				t_insert(member, child)
			end
			if partyMember.editLinks and partyMember.editLinks ~= "" then
				child = { elem = "ImportedBuffs", attrib = { name = "Link Skills" } }
				t_insert(child, partyMember.editLinks)
				t_insert(member, child)
			end
			if partyMember.enemyCond and partyMember.enemyCond ~= "" then
				child = { elem = "ImportedBuffs", attrib = { name = "EnemyConditions" } }
				t_insert(child, partyMember.enemyCond)
				t_insert(member, child)
			end
			if partyMember.enemyMods and partyMember.enemyMods ~= "" then
				child = { elem = "ImportedBuffs", attrib = { name = "EnemyMods" } }
				t_insert(child, partyMember.enemyMods)
				t_insert(member, child)
			end
			t_insert(xml, member)
		end
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
	exportString = self:exportBuffs("Warcry")
	if exportString ~= "" then
		child = { elem = "ExportedBuffs", attrib = { name = "Warcry Skills" } }
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
	self.lastContent.Warcry = self.controls.editWarcries.buf
	self.lastContent.Link = self.controls.editLinks.buf
	self.lastContent.EnemyCond = self.controls.enemyCond.buf
	self.lastContent.EnemyMods = self.controls.enemyMods.buf
	self.lastContent.EnableExportBuffs = self.enableExportBuffs
	self.lastContent.selectedMember = self.selectedMember
	xml.attrib = {
		destination = self.controls.importCodeDestination.list[self.controls.importCodeDestination.selIndex],
		append = tostring(self.controls.appendNotReplace.state),
		ShowAdvanceTools = tostring(self.controls.ShowAdvanceTools.state),
		selectedMember = tostring(self.selectedMember),
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
				elseif self.controls.editWarcries.hasFocus then
					self.controls.editWarcries:Undo()
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
				elseif self.controls.editWarcries.hasFocus then
					self.controls.editWarcries:Redo()
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
			or self.lastContent.Warcry ~= self.controls.editWarcries.buf
			or self.lastContent.Link ~= self.controls.editLinks.buf
			or self.lastContent.PartyMemberStats ~= self.controls.editPartyMemberStats.buf
			or self.lastContent.EnemyCond ~= self.controls.enemyCond.buf
			or self.lastContent.EnemyMods ~= self.controls.enemyMods.buf
			or self.lastContent.EnableExportBuffs ~= self.enableExportBuffs
			or self.lastContent.selectedMember ~= self.selectedMember
			or self.lastContent.showAdvancedTools ~= self.controls.ShowAdvanceTools.state)
end


function PartyTabClass:SwapSelectedMember(newMember, saveBuffers)
	if saveBuffers and self.selectedMember ~= 1 then
		self.partyMembers[self.selectedMember].editPartyMemberStats = self.controls.editPartyMemberStats.buf
		self.partyMembers[self.selectedMember].editAuras = self.controls.editAuras.buf
		self.partyMembers[self.selectedMember].editCurses = self.controls.editCurses.buf
		self.partyMembers[self.selectedMember].editWarcries = self.controls.editWarcries.buf
		self.partyMembers[self.selectedMember].editLinks = self.controls.editLinks.buf
		self.partyMembers[self.selectedMember].enemyCond = self.controls.enemyCond.buf
		self.partyMembers[self.selectedMember].enemyMods = self.controls.enemyMods.buf
	end
	self.selectedMember = newMember
	if newMember ~= 1 then
		self.controls.renameMember.buf = self.partyMembers[self.selectedMember].name
		self.controls.editPartyMemberStats.buf = self.partyMembers[self.selectedMember].editPartyMemberStats or ""
		self.controls.editAuras.buf = self.partyMembers[self.selectedMember].editAuras or ""
		self.controls.editCurses.buf = self.partyMembers[self.selectedMember].editCurses or ""
		self.controls.editWarcries.buf = self.partyMembers[self.selectedMember].editWarcries or ""
		self.controls.editLinks.buf = self.partyMembers[self.selectedMember].editLinks or ""
		self.controls.enemyCond.buf = self.partyMembers[self.selectedMember].enemyCond or ""
		self.controls.enemyMods.buf = self.partyMembers[self.selectedMember].enemyMods or ""
	else
		self.controls.renameMember.buf = ""
	end
	self.controls.simpleAuras.label = self.partyMembers[self.selectedMember].simpleAuras or ""
	self.controls.simpleCurses.label = self.partyMembers[self.selectedMember].simpleCurses or ""
	self.controls.simpleWarcries.label = self.partyMembers[self.selectedMember].simpleWarcries or ""
	self.controls.simpleLinks.label = self.partyMembers[self.selectedMember].simpleLinks or ""
	self.controls.simpleEnemyCond.label = self.partyMembers[self.selectedMember].simpleEnemyCond or ""
	self.controls.simpleEnemyMods.label = self.partyMembers[self.selectedMember].simpleEnemyMods or ""
end


function PartyTabClass:ParseBuffs(buffType, partyMember, buf)
	local list = partyMember[buffType]
	local labelName = ({ Aura = "simpleAuras", Curse = "simpleCurses", Warcry = "simpleWarcries", Link = "simpleLinks", EnemyConditions = "simpleEnemyCond", EnemyMods = "simpleEnemyMods", })[buffType]
	if buffType == "EnemyConditions" then
		list = partyMember.enemyModList
		for line in buf:gmatch("([^\n]*)\n?") do
			if line ~= "" then
				list:NewMod(line:gsub("Condition:", "Condition:Party:"), "FLAG", true, "Party")
			end
		end
	elseif buffType == "EnemyMods" then
		list = partyMember.enemyModList
		local enemyModList = {}
		local currentName
		for line in buf:gmatch("([^\n]*)\n?") do
			if not line:find("|") then
				currentName = line
				if labelName and currentName ~= "" then
					enemyModList[currentName] = enemyModList[currentName] or {}
				end
			else
				local mod = modLib.parseFormattedSourceMod(line)
				if mod then
					mod.source = "Party"..mod.source
					list:AddMod(mod)
					if labelName then
						t_insert(enemyModList[currentName], {mod.value, mod.type})
					end
				end
			end
		end
		if labelName then
			local count = 0
			partyMember[labelName] = "^7---------------------------"
			for modName, modList in pairs(enemyModList) do
				partyMember[labelName] = partyMember[labelName].."\n"..modName..":"
				count = count + 1
				for _, mod in ipairs(modList) do
					partyMember[labelName] = partyMember[labelName].." "..(mod[1] and "True" or mod[1]).." "..(mod[2] == "FLAG" and "" or mod[2])..", "
				end
			end
			if count > 0 then
				partyMember[labelName] = partyMember[labelName].."\n---------------------------\n"
			else
				partyMember[labelName] = partyMember[labelName].."\n"
			end
		end
	elseif buffType == "PartyMemberStats" then
		if not partyMember.modDB then
		else
			local modDB = partyMember.modDB
			local output = partyMember.output
			for line in buf:gmatch("([^\n]*)\n?") do
				if line:find("=") then
					if line:match("%.") then
						local k1, k2, v = line:match("([%w ]-%w+)%.([%w ]-%w+)=(.+)")
						output[k1] = {[k2] = tonumber(v)}
					elseif line:match("|") then
						local k, tags, v = line:match("([%w ]-%w+)|(.+)=(.+)")
						v = tonumber(v)
						for tag in tags:gmatch("([^|]*)|?") do
							if tag == "percent" then
								v = v / 100
							elseif tag == "max" then
								v = m_max(v, output[k] or 1)
							end
						end
						output[k] = v
					else
						local k, v = line:match("([%w ]-%w+)=(.+)")
						output[k] = tonumber(v)
					end
				elseif line ~= "" then
					modDB:NewMod(line, "FLAG", true, "Party")
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
		local currentModType = (buffType == "Link") and "Link" or (buffType == "Warcry") and "Warcry" or "Unknown"
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
				if line:find("|") and currentName ~= "SKIP" and not line:find("MinionModifier|LIST") then
					if currentModType == "otherEffects" then
						currentName, currentEffect, line = line:match("([%w ']-%w+)|(%w+)|(.+)")
					end
					local mod = modLib.parseFormattedSourceMod(line)
					if mod then
						for _, tag in ipairs(mod) do
							if tag.type == "GlobalEffect" and currentModType ~= "Link" and currentModType ~= "Warcry" and currentModType ~= "otherEffects" then
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
								local oldItem
								oldItem, mod.source = mod.source:match("Item:(%d+):(.+)")
								mod.source = "Party - "..mod.source
							end
							if mod.source:match("Skill") then
								local skillId = mod.source:match("Skill:(.+)")
								if not data.skills[skillId] then
									local minimisedName = currentName:gsub(" %l",string.upper):gsub(" ","")
									if data.skills[minimisedName] then
										mod.source = "Skill:"..minimisedName
									else
										mod.source = skillId
									end
								end
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
		if labelName then
			if buffType == "Aura" then
				local labelList = {}
				partyMember[labelName] = "^7---------------------------\n"
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
					partyMember[labelName] = partyMember[labelName]..table.concat(labelList)
					partyMember[labelName] = partyMember[labelName].."---------------------------\n"
				end
				if list["extraAura"] and list["extraAura"]["extraAura"] then
					partyMember[labelName] = partyMember[labelName].."extraAuras:\n"
					for _, auraMod in ipairs(list["extraAura"]["extraAura"].modList) do
						partyMember[labelName] = partyMember[labelName].."  "..(auraMod.type == "FLAG" and "" or (auraMod.type.." "))..auraMod.name..": "..tostring(auraMod.value).."\n"
					end
					partyMember[labelName] = partyMember[labelName].."---------------------------\n"
				end
				if list["otherEffects"] then
					partyMember[labelName] = partyMember[labelName].."otherEffects:\n"
					for buffName, buff in pairs(list["otherEffects"]) do
						for _, auraMod in ipairs(list["otherEffects"][buffName].modList) do
							partyMember[labelName] = partyMember[labelName].."  "..(auraMod.type == "FLAG" and "" or (auraMod.type.." "))..auraMod.name..": "..tostring(auraMod.value).."\n"
						end
					end
					partyMember[labelName] = partyMember[labelName].."---------------------------\n"
				end
			elseif buffType == "Warcry" then
				local labelList = {}
				for warcry, warcryMod in pairs(list["Warcry"] or {}) do
					t_insert(labelList, warcry..": "..warcryMod.effectMult.."%\n")
				end
				if #labelList > 0 then
					table.sort(labelList)
					partyMember[labelName] = "^7---------------------------\n"..table.concat(labelList).."---------------------------\n"
				else
					partyMember[labelName] = ""
				end
			elseif buffType == "Link" then
				local labelList = {}
				for link, linkMod in pairs(list["Link"] or {}) do
					t_insert(labelList, link..": "..linkMod.effectMult.."%\n")
				end
				if #labelList > 0 then
					table.sort(labelList)
					partyMember[labelName] = "^7---------------------------\n"..table.concat(labelList).."---------------------------\n"
				else
					partyMember[labelName] = ""
				end
			elseif buffType == "Curse" then
				local labelList = {}
				for curse, curseMod in pairs(list["Curse"] or {}) do
					t_insert(labelList, curse..": "..curseMod.effectMult.."%\n")
				end
				if #labelList > 0 then
					table.sort(labelList)
					partyMember[labelName] = "^7---------------------------\n"..table.concat(labelList).."---------------------------\n"
				else
					partyMember[labelName] = ""
				end
			end
		end
	end
end

function PartyTabClass:CombineBuffs(filter)
	for i, partyMember in ipairs(self.partyMembers) do
		if i == 1 then
			if not filter then
				wipeTable(self.actor)
				wipeTable(self.enemyModList)
				self.actor = { Aura = {}, Curse = {}, Warcry = { }, Link = {}, modDB = new("ModDB"), output = { } }
				self.actor.modDB.actor = self.actor
				self.enemyModList = new("ModList")
			end
			self.actor.Curse = { Limit = 0 }
		else
			if not filter or filter == "EnemyConditions" or filter == "EnemyMods" then
				self.enemyModList:AddList(partyMember.enemyModList)
			end
			if not filter or filter == "PartyMemberStats" then
				self.actor.modDB:AddList(partyMember.modDB)
				for k, v in pairs(partyMember.output) do
					if k == "MovementSpeedMod" then
						self.actor.output[k] = m_max((self.actor.output[k] or 0), tonumber(v))
					else
						self.actor.output[k] = v
					end
				end
			end
			if not filter or filter == "Aura" then
				if partyMember.Aura.Aura then
					self.actor.Aura.Aura = self.actor.Aura.Aura or { }
					for aura, auraMod in pairs(partyMember.Aura.Aura) do
						if aura == "Vaal" then
							self.actor.Aura.Aura.Vaal = self.actor.Aura.Aura.Vaal or { }
							for auraVaal, auraModVaal in pairs(auraMod) do
								if not self.actor.Aura.Aura.Vaal[auraVaal] or self.actor.Aura.Aura.Vaal[auraVaal].effectMult < auraModVaal.effectMult then
									self.actor.Aura.Aura.Vaal[auraVaal] = auraModVaal
								end
							end
						else
							if not self.actor.Aura.Aura[aura] or self.actor.Aura.Aura[aura].effectMult < auraMod.effectMult then
								self.actor.Aura.Aura[aura] = auraMod
							end
						end
					end
				end
				if partyMember.Aura.AuraDebuff then
					self.actor.Aura.AuraDebuff = self.actor.Aura.AuraDebuff or { }
					for aura, auraMod in pairs(partyMember.Aura.AuraDebuff) do
						if aura == "Vaal" then
							self.actor.Aura.AuraDebuff.Vaal = self.actor.Aura.AuraDebuff.Vaal or { }
							for auraVaal, auraModVaal in pairs(auraMod) do
								if not self.actor.Aura.AuraDebuff.Vaal[auraVaal] or self.actor.Aura.AuraDebuff.Vaal[auraVaal].effectMult < auraModVaal.effectMult then
									self.actor.Aura.AuraDebuff.Vaal[auraVaal] = auraModVaal
								end
							end
						else
							if not self.actor.Aura.AuraDebuff[aura] or self.actor.Aura.AuraDebuff[aura].effectMult < auraMod.effectMult then
								self.actor.Aura.AuraDebuff[aura] = auraMod
							end
						end
					end
				end
				if partyMember.Aura.extraAura then
					self.actor.Aura.extraAura = self.actor.Aura.extraAura or { }
					self.actor.Aura.extraAura.extraAura = self.actor.Aura.extraAura.extraAura or { modList = new("ModList") }
					self.actor.Aura.extraAura.extraAura.modList:AddList(partyMember.Aura.extraAura.extraAura.modList)
				end
				if partyMember.Aura.otherEffects then
					self.actor.Aura.otherEffects = self.actor.Aura.otherEffects or { }
					for _, auraMod in ipairs(partyMember.Aura.otherEffects) do
						t_insert(self.actor.Aura.otherEffects, auraMod)
					end
				end
			end
			if not filter or filter == "Curse" then
				if partyMember.Curse and ((partyMember.Curse.Limit or 0) > self.actor.Curse.Limit) then
					self.actor.Curse = partyMember.Curse
				end
			end
			if not filter or filter == "Warcry" then
				if partyMember.Warcry and partyMember.Warcry.Warcry then
					self.actor.Warcry.Warcry = self.actor.Warcry.Warcry or { }
					for k, v in pairs(partyMember.Warcry.Warcry) do
						if not self.actor.Warcry.Warcry[k] or self.actor.Warcry.Warcry[k].effectMult < v.effectMult then
							self.actor.Warcry.Warcry[k] = v
						end
					end
				end
			end
			if not filter or filter == "Link" then
				if partyMember.Link and partyMember.Link.Link and not self.actor.Link.Link then
					self.actor.Link.Link = partyMember.Link.Link
				end
			end
		end
	end
	if not filter or filter == "EnemyMods" then
		local count = 0
		local enemyModList = { }
		self.partyMembers[1].simpleEnemyMods = "^7---------------------------"
		for _, mod in ipairs(self.enemyModList) do
			if not mod.name:match("Condition:Party") then
				enemyModList[mod.name] = enemyModList[mod.name] or { }
				t_insert(enemyModList[mod.name], {mod.value, mod.type})
			end
		end
		for modName, modList in pairs(enemyModList) do
			self.partyMembers[1].simpleEnemyMods = self.partyMembers[1].simpleEnemyMods.."\n"..modName..":"
			count = count + 1
			for _, mod in ipairs(modList) do
				self.partyMembers[1].simpleEnemyMods = self.partyMembers[1].simpleEnemyMods.." "..(mod[1] and "True" or mod[1]).." "..(mod[2] == "FLAG" and "" or mod[2])..", "
			end
		end
		if count > 0 then
			self.partyMembers[1].simpleEnemyMods = self.partyMembers[1].simpleEnemyMods.."\n---------------------------\n"
		else
			self.partyMembers[1].simpleEnemyMods = self.partyMembers[1].simpleEnemyMods.."\n"
		end
	end
	if not filter or filter == "Aura" then
		local labelList = {}
		self.partyMembers[1].simpleAuras = "^7---------------------------\n"
		for aura, auraMod in pairs(self.actor.Aura["Aura"] or {}) do
			if aura ~= "Vaal" then
				t_insert(labelList, aura..": "..auraMod.effectMult.."%\n")
			end
		end
		if self.actor.Aura["Aura"] and self.actor.Aura["Aura"]["Vaal"] then
			for aura, auraMod in pairs(self.actor.Aura["Aura"]["Vaal"]) do
				t_insert(labelList, aura..": "..auraMod.effectMult.."%\n")
			end
		end
		for aura, auraMod in pairs(self.actor.Aura["AuraDebuff"] or {}) do
			if not self.actor.Aura["Aura"] or not self.actor.Aura["Aura"][aura] then
				if aura ~= "Vaal" then
					t_insert(labelList, aura..": "..auraMod.effectMult.."%\n")
				end
			end
		end
		if self.actor.Aura["AuraDebuff"] and self.actor.Aura["AuraDebuff"]["Vaal"] then
			if not self.actor.Aura["Aura"] or not self.actor.Aura["Aura"]["Vaal"] or not self.actor.Aura["Aura"]["Vaal"][aura] then
				for aura, auraMod in pairs(self.actor.Aura["AuraDebuff"]["Vaal"]) do
					t_insert(labelList, aura..": "..auraMod.effectMult.."%\n")
				end
			end
		end
		if #labelList > 0 then
			table.sort(labelList)
			self.partyMembers[1].simpleAuras = self.partyMembers[1].simpleAuras..table.concat(labelList)
			self.partyMembers[1].simpleAuras = self.partyMembers[1].simpleAuras.."---------------------------\n"
		end
		if self.actor.Aura["extraAura"] and self.actor.Aura["extraAura"]["extraAura"] then
			self.partyMembers[1].simpleAuras = self.partyMembers[1].simpleAuras.."extraAuras:\n"
			for _, auraMod in ipairs(self.actor.Aura["extraAura"]["extraAura"].modList) do
				self.partyMembers[1].simpleAuras = self.partyMembers[1].simpleAuras.."  "..(auraMod.type == "FLAG" and "" or (auraMod.type.." "))..auraMod.name..": "..tostring(auraMod.value).."\n"
			end
			self.partyMembers[1].simpleAuras = self.partyMembers[1].simpleAuras.."---------------------------\n"
		end
		if self.actor.Aura["otherEffects"] then
			self.partyMembers[1].simpleAuras = self.partyMembers[1].simpleAuras.."otherEffects:\n"
			for buffName, buff in pairs(self.actor.Aura["otherEffects"]) do
				for _, auraMod in ipairs(self.actor.Aura["otherEffects"][buffName].modList) do
					self.partyMembers[1].simpleAuras = self.partyMembers[1].simpleAuras.."  "..(auraMod.type == "FLAG" and "" or (auraMod.type.." "))..auraMod.name..": "..tostring(auraMod.value).."\n"
				end
			end
			self.partyMembers[1].simpleAuras = self.partyMembers[1].simpleAuras.."---------------------------\n"
		end
	end
	if not filter or filter == "Warcry" then
		local labelList = {}
		for warcry, warcryMod in pairs(self.actor.Warcry["Warcry"] or {}) do
			t_insert(labelList, warcry..": "..warcryMod.effectMult.."%\n")
		end
		if #labelList > 0 then
			table.sort(labelList)
			self.partyMembers[1].simpleWarcries= "^7---------------------------\n"..table.concat(labelList).."---------------------------\n"
		else
			self.partyMembers[1].simpleWarcries = ""
		end
	end
	if not filter or filter == "Link" then
		local labelList = {}
		for link, linkMod in pairs(self.actor.Link["Link"] or {}) do
			t_insert(labelList, link..": "..linkMod.effectMult.."%\n")
		end
		if #labelList > 0 then
			table.sort(labelList)
			self.partyMembers[1].simpleLinks = "^7---------------------------\n"..table.concat(labelList).."---------------------------\n"
		else
			self.partyMembers[1].simpleLinks = ""
		end
	end
	if not filter or filter == "Curse" then
		local labelList = {}
		for curse, curseMod in pairs(self.actor.Curse["Curse"] or {}) do
			t_insert(labelList, curse..": "..curseMod.effectMult.."%\n")
		end
		if #labelList > 0 then
			table.sort(labelList)
			self.partyMembers[1].simpleCurses = "^7---------------------------\n"..table.concat(labelList).."---------------------------\n"
		else
			self.partyMembers[1].simpleCurses = ""
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
			elseif buffType == "Link" or buffType == "Warcry" or buffType == "Aura" and buffName ~= "extraAura" and buffName ~= "otherEffects" then
				buf = buf.."\n"..tostring(buff.effectMult * 100)
			end
			if buffType == "Aura" and buffName == "otherEffects" then
				for innerBuffName, innerBuff in pairs(buff) do
					for _, mod in ipairs(innerBuff.modList) do
						buf = buf.."\n"..innerBuffName.."|"..tostring(innerBuff.effectMult * 100).."|"..modLib.formatSourceMod(mod)
					end
				end
				buf = buf.."\n---"
			elseif buffType == "Curse" or buffType == "Aura" or buffType == "Warcry" or buffType == "Link" then
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