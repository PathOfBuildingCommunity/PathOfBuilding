-- Path of Building
--
-- Module: Party Tab
-- Party tab for the current build.
--
local pairs = pairs
local ipairs = ipairs
local s_format = string.format
local t_insert = table.insert
local m_max = math.max
local mercenaryWarrant = require("Modules.MercenaryWarrantParser")

local mercenarySlotOrder = {
	"Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt",
}

---@class PartyTab: ControlHost, Control
local PartyTabClass = newClass("PartyTab", "ControlHost", "Control")

---@param build Build
function PartyTabClass:PartyTab(build)
	self:ControlHost()
	self:Control()

	self.build = build

	self.actor = { Aura = { }, Curse = { }, Warcry = { }, Link = { }, modDB = new("ModDB"):ModDB(), output = { } }
	self.actor.modDB.actor = self.actor
	self.enemyModList = new("ModList"):ModList()
	self.buffExports = { }
	self.enableExportBuffs = false
	self.mercenaries = { }
	self.activeMercenaryIndex = 1
	self.mercenaryItemRows = { }

	self.lastContent = {
		Aura = "",
		Curse = "",
		Warcry = "",
		Link = "",
		EnemyCond = "",
		EnemyMods = "",
		EnableExportBuffs = false,
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
		bufferHeightSmall = 106,
		bufferHeightLeft = function()
			-- 2 elements
			return (self.height - 378 - ((self.width > 1350) and 0 or 24) - self.controls.importCodeHeader.y() - self.controls.editAurasLabel.y())
		end,
		-- 4 elements
		bufferHeightRight = 434,
	}

	local notesDesc = [[^7To import a build it must be exported with "Export support" enabled in the import/export tab
	Auras with the highest effect will take priority, your curses will take priority over a support's
	
	All of these effects can be found in the Calcs tab]]
	
	self.controls.notesDesc = new("LabelControl"):LabelControl({"TOPLEFT",self,"TOPLEFT"}, {8, 8, 150, theme.stringHeight}, notesDesc)
	self.controls.notesDesc.width = function()
		local width = self.width / 2 - 16
		if width ~= self.controls.notesDesc.lastWidth then
			self.controls.notesDesc.lastWidth = width
			self.controls.notesDesc.label = table.concat(main:WrapString(notesDesc, theme.stringHeight, width - 50), "\n")
		end
		return width
	end
	self.controls.importCodeHeader = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.notesDesc,"BOTTOMLEFT"}, {0, 32, 0, theme.stringHeight}, "^7Enter a build code/URL below:")
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
		if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Warcry Skills" then
			self.controls.simpleWarcries.label = ""
			self.controls.editWarcries:SetText("")
			wipeTable(self.actor["Warcry"])
			self.actor["Warcry"] = {}
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
			if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Warcry Skills" then
				wipeTable(self.actor["Warcry"])
				self.actor["Warcry"] = { }
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
						elseif node.attrib.name == "Warcry Skills" then
							if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "Warcry Skills" then
								if #self.controls.editWarcries.buf > 0 then
									node[1] = self.controls.editWarcries.buf.."\n"..(node[1] or "")
								end
								self.controls.editWarcries:SetText(node[1] or "")
								self:ParseBuffs(self.actor["Warcry"], self.controls.editWarcries.buf, "Warcry", self.controls.simpleWarcries)
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
					elseif node.elem == "Mercenary" or node.elem == "Mercenaries" then
						if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" then
							self:ApplyMercenariesXML(node, dbXML, self.controls.appendNotReplace.state ~= true)
						end
					end
				end
				if partyDestinations[self.controls.importCodeDestination.selIndex] == "All" or partyDestinations[self.controls.importCodeDestination.selIndex] == "EnemyConditions" or partyDestinations[self.controls.importCodeDestination.selIndex] == "EnemyMods" then
					wipeTable(self.enemyModList)
					self.enemyModList = new("ModList"):ModList()
					self:ParseBuffs(self.enemyModList, self.controls.enemyCond.buf, "EnemyConditions")
					self:ParseBuffs(self.enemyModList, self.controls.enemyMods.buf, "EnemyMods", self.controls.simpleEnemyMods)
				end
				self.build.buildFlag = true 
				break
			end
		end
	end
	
	self.controls.importCodeIn = new("EditControl"):EditControl({"TOPLEFT",self.controls.importCodeHeader,"BOTTOMLEFT"}, {0, 4, 328, theme.buttonHeight}, "", nil, nil, nil, importCodeHandle)
	self.controls.importCodeIn.width = function()
		return (self.width > 880) and 328 or (self.width / 2 - 100)
	end
	self.controls.importCodeIn.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
	self.controls.importCodeState = new("LabelControl"):LabelControl({"LEFT",self.controls.importCodeIn,"RIGHT"}, {8, 0, 0, theme.stringHeight})
	self.controls.importCodeState.label = function()
		return self.importCodeDetail or ""
	end
	self.controls.importCodeDestination = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, {0, 4, 160, theme.buttonHeight}, partyDestinations)
	self.controls.importCodeDestination.tooltipText = "Destination for Import/clear\nCurrently Links Skills do not export"
	self.controls.importCodeGo = new("ButtonControl"):ButtonControl({"LEFT",self.controls.importCodeDestination,"RIGHT"}, {8, 0, 160, theme.buttonHeight}, "Import", function()
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
	self.controls.appendNotReplace = new("CheckBoxControl"):CheckBoxControl({"LEFT",self.controls.importCodeGo,"RIGHT"}, {60, 0, theme.buttonHeight}, "Append", function(state)
	end, "This sets the import button to append to the current party lists instead of replacing them (curses will still replace)", false)
	self.controls.appendNotReplace.x = function()
		return (self.width > theme.widthThreshold1) and 60 or (-276)
	end
	self.controls.appendNotReplace.y = function()
		return (self.width > theme.widthThreshold1) and 0 or 24
	end
	
	self.controls.clear = new("ButtonControl"):ButtonControl({"LEFT",self.controls.appendNotReplace,"RIGHT"}, {8, 0, 160, theme.buttonHeight}, "Clear", function()
		clearInputText()
		wipeTable(self.enemyModList)
		self.enemyModList = new("ModList"):ModList()
		self.build.buildFlag = true
	end)
	self.controls.clear.tooltipText = "^7Clears all the party tab imported data"
	
	self.controls.ShowAdvanceTools = new("CheckBoxControl"):CheckBoxControl({"TOPLEFT",self.controls.importCodeDestination,"BOTTOMLEFT"}, {140, 4, theme.buttonHeight}, "^7Show Advanced Info", function(state)
	end, "This shows the advanced info like what stats each aura/curse etc are adding, as well as enables the ability to edit them without a re-export\nDo not edit any boxes unless you know what you are doing, use copy/paste or import instead", false)
	self.controls.ShowAdvanceTools.y = function()
		return (self.width > theme.widthThreshold1) and 4 or 28
	end
	
	self.controls.removeEffects = new("ButtonControl"):ButtonControl({"LEFT",self.controls.ShowAdvanceTools,"RIGHT"}, {8, 0, 160, theme.buttonHeight}, "Disable Party Effects", function()
		wipeTable(self.actor)
		wipeTable(self.enemyModList)
		self.actor = { Aura = {}, Curse = {}, Warcry = { }, Link = {}, modDB = new("ModDB"):ModDB(), output = { } }
		self.actor.modDB.actor = self.actor
		self.enemyModList = new("ModList"):ModList()
		self.build.buildFlag = true
	end)
	self.controls.removeEffects.tooltipText = "^7Removes the effects of the supports, without removing the data\nUse \"rebuild all\" to apply the effects again"
	
	self.controls.rebuild = new("ButtonControl"):ButtonControl({"LEFT",self.controls.removeEffects,"RIGHT"}, {8, 0, 160, theme.buttonHeight}, "^7Rebuild All", function()
		wipeTable(self.actor)
		wipeTable(self.enemyModList)
		self.actor = { Aura = {}, Curse = {}, Warcry = { }, Link = {}, modDB = new("ModDB"):ModDB(), output = { } }
		self.actor.modDB.actor = self.actor
		self.enemyModList = new("ModList"):ModList()
		self:ParseBuffs(self.actor["modDB"], self.controls.editPartyMemberStats.buf, "PartyMemberStats", self.actor["output"])
		self:ParseBuffs(self.actor["Aura"], self.controls.editAuras.buf, "Aura", self.controls.simpleAuras)
		self:ParseBuffs(self.actor["Curse"], self.controls.editCurses.buf, "Curse", self.controls.simpleCurses)
		self:ParseBuffs(self.actor["Warcry"], self.controls.editWarcries.buf, "Warcry", self.controls.simpleWarcries)
		self:ParseBuffs(self.actor["Link"], self.controls.editLinks.buf, "Link", self.controls.simpleLinks)
		self:ParseBuffs(self.enemyModList, self.controls.enemyCond.buf, "EnemyConditions")
		self:ParseBuffs(self.enemyModList, self.controls.enemyMods.buf, "EnemyMods", self.controls.simpleEnemyMods)
		self.build.buildFlag = true 
	end)
	self.controls.rebuild.tooltipText = "^7Reparse all the inputs in case they have been disabled or they have changed since loading the build or importing"
	self.controls.rebuild.x = function()
		return (self.width > theme.widthThreshold1) and 8 or (-328)
	end
	self.controls.rebuild.y = function()
		return (self.width > theme.widthThreshold1) and 0 or 24
	end

	self.controls.editAurasLabel = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.ShowAdvanceTools,"TOPLEFT"}, {-140, 40, 0, theme.stringHeight}, "^7Auras")
	self.controls.editAurasLabel.y = function()
		return 36 + ((self.width <= theme.widthThreshold1) and 24 or 0)
	end
	self.controls.editAuras = new("EditControl"):EditControl({"TOPLEFT",self.controls.editAurasLabel,"TOPLEFT"}, {0, 18, 0, 0}, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editAuras.width = function()
		return self.width / 2 - 16
	end
	self.controls.editAuras.height = function()
		return (self.controls.editWarcries.hasFocus or self.controls.editLinks.hasFocus) and theme.bufferHeightSmall or theme.bufferHeightLeft()
	end
	
	self.controls.editAuras.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleAuras = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.editAurasLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "")
	self.controls.simpleAuras.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.editWarcriesLabel = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.editAurasLabel,"BOTTOMLEFT"}, {0, 8, 0, theme.stringHeight}, "^7Warcry Skills")
	self.controls.editWarcriesLabel.y = function()
		return self.controls.ShowAdvanceTools.state and (self.controls.editAuras.height() + 8) or (theme.lineCounter(self.controls.simpleAuras.label) + 4)
	end
	self.controls.editWarcries = new("EditControl"):EditControl({"TOPLEFT",self.controls.editWarcriesLabel,"TOPLEFT"}, {0, 18, 0, 0}, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editWarcries.width = function()
		return self.width / 2 - 16
	end
	self.controls.editWarcries.height = function()
		return (self.controls.editWarcries.hasFocus and theme.bufferHeightLeft() or theme.bufferHeightSmall)
	end
	self.controls.editWarcries.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleWarcries = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.editWarcriesLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "")
	self.controls.simpleWarcries.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.editLinksLabel = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.editWarcriesLabel,"BOTTOMLEFT"}, {0, 8, 0, theme.stringHeight}, "^7Link Skills")
	self.controls.editLinksLabel.y = function()
		return self.controls.ShowAdvanceTools.state and (self.controls.editWarcries.height() + 8) or (theme.lineCounter(self.controls.simpleWarcries.label) + 4)
	end
	self.controls.editLinks = new("EditControl"):EditControl({"TOPLEFT",self.controls.editLinksLabel,"TOPLEFT"}, {0, 18, 0, 0}, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editLinks.width = function()
		return self.width / 2 - 16
	end
	self.controls.editLinks.height = function()
		return (self.controls.editLinks.hasFocus and theme.bufferHeightLeft() or theme.bufferHeightSmall)
	end
	self.controls.editLinks.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleLinks = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.editLinksLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "")
	self.controls.simpleLinks.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	-- Mercenary Overview (Luminary / imported Mercenary)
	self.controls.mercenaryHeader = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.editLinksLabel,"BOTTOMLEFT"}, {0, 12, 0, theme.stringHeight}, function()
		local merc = self:GetActiveMercenary()
		local itemsTab = self.build and self.build.itemsTab
		local itemSet = itemsTab and itemsTab.activeItemSet
		local name = (merc and merc.name and merc.name ~= "" and merc.name)
			or (itemSet and itemSet.mercenaryName and itemSet.mercenaryName ~= "" and itemSet.mercenaryName)
			or "Unnamed"
		local buildName = (merc and merc.build) or (itemSet and itemSet.mercenaryBuild)
		local mercType = (merc and merc.type) or (itemSet and itemSet.mercenaryType)
		local mercLevel = (merc and merc.level) or (itemSet and itemSet.mercenaryLevel)
		local meta = {}
		if buildName and buildName ~= "" then
			t_insert(meta, buildName)
		end
		if mercType and mercType ~= "" then
			t_insert(meta, mercType)
		end
		if mercLevel and mercLevel > 0 then
			t_insert(meta, "Level " .. tostring(mercLevel))
		end
		local suffix = #meta > 0 and (" (" .. table.concat(meta, ", ") .. ")") or ""
		return "^7Mercenary: " .. colorCodes.RELIC .. name .. "^7" .. suffix
	end)
	self.controls.mercenaryHeader.y = function()
		return self.controls.ShowAdvanceTools.state and (self.controls.editLinks.height() + 12) or (theme.lineCounter(self.controls.simpleLinks.label) + 12)
	end
	self.controls.mercenaryHeader.shown = function()
		return self:IsMercenaryShown()
	end
	self.controls.mercenarySelect = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.mercenaryHeader,"BOTTOMLEFT"}, {0, 4, 220, 18}, {}, function(index)
		self:SetActiveMercenary(index)
	end)
	self.controls.mercenarySelect.shown = self.controls.mercenaryHeader.shown
	self.controls.mercenarySelect.enabled = function()
		return #self.mercenaries > 1
	end
	self.controls.mercenaryPasteWarrant = new("ButtonControl"):ButtonControl({"LEFT",self.controls.mercenarySelect,"RIGHT"}, {4, 0, 100, 18}, "Paste Warrant", function()
		self:OpenPasteWarrantPopup()
	end)
	self.controls.mercenaryPasteWarrant.shown = self.controls.mercenaryHeader.shown
	self.controls.mercenaryRemove = new("ButtonControl"):ButtonControl({"LEFT",self.controls.mercenaryPasteWarrant,"RIGHT"}, {4, 0, 65, 18}, "Remove", function()
		self:RemoveActiveMercenary()
	end)
	self.controls.mercenaryRemove.shown = self.controls.mercenaryHeader.shown
	self.controls.mercenaryRemove.enabled = function()
		return #self.mercenaries > 0
	end
	self.controls.mercenarySummary = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.mercenarySelect,"BOTTOMLEFT"}, {0, 6, 0, theme.stringHeight}, function()
		return self:BuildMercenarySkillsText()
	end)
	self.controls.mercenarySummary.shown = self.controls.mercenaryHeader.shown

	self.controls.mercenaryItemsList = new("ListControl"):ListControl({"TOPLEFT",self.controls.mercenarySummary,"BOTTOMLEFT"}, {0, 22, 380, 180}, 16, "VERTICAL", false, self.mercenaryItemRows, true)
	self.controls.mercenaryItemsList.label = "^7Mercenary Items:"
	self.controls.mercenaryItemsList.defaultText = "^x7F7F7FNo items equipped"
	self.controls.mercenaryItemsList.reserveIconSpace = true
	self.controls.mercenaryItemsList.width = function()
		return m_max(380, self.width / 2 - 24)
	end
	self.controls.mercenaryItemsList.y = function()
		return theme.lineCounter(self.controls.mercenarySummary:GetProperty("label")) + 24
	end
	self.controls.mercenaryItemsList.shown = self.controls.mercenaryHeader.shown
	self.controls.mercenaryItemsList.GetRowValue = function(_, column, index, entry)
		if column == 1 and entry then
			local itemsTab = self.build and self.build.itemsTab
			local item = entry.itemId and itemsTab and itemsTab.items[entry.itemId]
			if item then
				return "^7" .. entry.slotName .. ": " .. colorCodes[item.rarity] .. item.name
			end
			return "^7" .. entry.slotName .. ": ^x7F7F7FNone"
		end
		return ""
	end
	self.controls.mercenaryItemsList.GetRowIcon = function(_, column, index, entry)
		if column == 1 and entry and entry.itemId then
			local itemsTab = self.build and self.build.itemsTab
			local item = itemsTab and itemsTab.items[entry.itemId]
			if item then
				return itemsTab:GetItemIcon(item)
			end
		end
	end
	self.controls.mercenaryItemsList.AddValueTooltip = function(_, tooltip, index, entry)
		if main.popups[1] or not entry or not entry.itemId then
			tooltip:Clear()
			return
		end
		local itemsTab = self.build and self.build.itemsTab
		local item = itemsTab and itemsTab.items[entry.itemId]
		if item then
			if tooltip:CheckForUpdate(item, launch.devModeAlt, self.build.outputRevision) then
				itemsTab:AddItemTooltip(tooltip, item, nil, true)
			end
		else
			tooltip:Clear()
		end
	end
	self.controls.mercenaryItemsList.OnSelect = function(_, index, entry)
		self:SyncMercenaryItemPicker(entry and entry.slotName or nil)
	end

	self.controls.mercenaryItemSelectLabel = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.mercenaryItemsList,"BOTTOMLEFT"}, {0, 6, 0, theme.stringHeight}, function()
		local sel = self.controls.mercenaryItemsList.selValue
		return sel and ("^7" .. sel.slotName .. ":") or ""
	end)
	self.controls.mercenaryItemSelectLabel.shown = function()
		return self:IsMercenaryShown() and self:GetActiveMercenary() ~= nil and self.controls.mercenaryItemsList.selValue ~= nil
	end
	self.controls.mercenaryItemSelect = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.mercenaryItemsList,"BOTTOMLEFT"}, {85, 4, 295, 20}, {}, function(index, value)
		local sel = self.controls.mercenaryItemsList.selValue
		local merc = self:GetActiveMercenary()
		if not sel or not merc or not value then
			return
		end
		merc.items = merc.items or {}
		local newId = value.itemId or 0
		if newId == 0 then
			merc.items[sel.slotName] = nil
		else
			merc.items[sel.slotName] = newId
		end
		if sel.slotName == "Weapon 1" and merc.items["Weapon 2"] then
			local itemsTab = self.build and self.build.itemsTab
			local offhand = itemsTab and itemsTab.items[merc.items["Weapon 2"]]
			if offhand and not self:IsItemValidForMercenarySlot(offhand, "Weapon 2", merc.items) then
				merc.items["Weapon 2"] = nil
			end
		end
		local itemsTab = self.build and self.build.itemsTab
		if itemsTab and itemsTab.activeItemSet then
			itemsTab.activeItemSet.mercenaryItems = merc.items
		end
		self:SyncMercenaryItemsList()
		self:SyncMercenaryItemPicker(sel.slotName)
		if self.build then
			self.build.buildFlag = true
		end
	end)
	self.controls.mercenaryItemSelect.width = function()
		return m_max(295, self.controls.mercenaryItemsList.width() - 85)
	end
	self.controls.mercenaryItemSelect.shown = self.controls.mercenaryItemSelectLabel.shown
	self.controls.mercenaryItemSelect.enabled = function()
		return #self.controls.mercenaryItemSelect.list > 1
	end
	self.controls.mercenaryItemSelect.tooltipFunc = function(tooltip, mode, index, value)
		if main.popups[1] or mode == "OUT" or not value or not value.itemId or value.itemId == 0 then
			tooltip:Clear()
			return
		end
		local itemsTab = self.build and self.build.itemsTab
		local item = itemsTab and itemsTab.items[value.itemId]
		if item and tooltip:CheckForUpdate(item, launch.devModeAlt, self.build.outputRevision) then
			itemsTab:AddItemTooltip(tooltip, item, nil, true)
		end
	end

	self.controls.editPartyMemberStatsLabel = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.notesDesc,"TOPRIGHT"}, {8, 0, 0, theme.stringHeight}, "^7Party Member Stats")
	self.controls.editPartyMemberStats = new("EditControl"):EditControl({"TOPLEFT",self.controls.editPartyMemberStatsLabel,"BOTTOMLEFT"}, {0, 2, 0, 0}, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editPartyMemberStats.width = function()
		return self.width / 2 - 16
	end
	self.controls.editPartyMemberStats.height = function()
		return (self.controls.editPartyMemberStats.hasFocus and (self.height - theme.bufferHeightRight) or theme.bufferHeightSmall)
	end
	self.controls.editPartyMemberStats.shown = function()
		return self.controls.ShowAdvanceTools.state
	end

	self.controls.enemyCondLabel = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.editPartyMemberStatsLabel,"BOTTOMLEFT"}, {0, 8, 0, theme.stringHeight}, "^7Enemy Conditions")
	self.controls.enemyCondLabel.y = function()
		return self.controls.ShowAdvanceTools.state and (self.controls.editPartyMemberStats.height() + 8) or 4
	end
	self.controls.enemyCond = new("EditControl"):EditControl({"TOPLEFT",self.controls.enemyCondLabel,"BOTTOMLEFT"}, {0, 2, 0, 0}, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.enemyCond.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyCond.height = function()
		return (self.controls.enemyCond.hasFocus and (self.height - theme.bufferHeightRight) or theme.bufferHeightSmall)
	end
	self.controls.enemyCond.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleEnemyCond = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.enemyCondLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "^7---------------------------\n")
	self.controls.simpleEnemyCond.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.enemyModsLabel = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.enemyCondLabel,"BOTTOMLEFT"}, {0, 8, 0, theme.stringHeight}, "^7Enemy Modifiers")
	self.controls.enemyModsLabel.y = function()
		return self.controls.ShowAdvanceTools.state and (self.controls.enemyCond.height() + 8) or (theme.lineCounter(self.controls.simpleEnemyCond.label) + 4)
	end
	self.controls.enemyMods = new("EditControl"):EditControl({"TOPLEFT",self.controls.enemyModsLabel,"BOTTOMLEFT"}, {0, 2, 0, 0}, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.enemyMods.width = function()
		return self.width / 2 - 16
	end
	self.controls.enemyMods.height = function()
		return (self.controls.enemyMods.hasFocus and (self.height - theme.bufferHeightRight) or theme.bufferHeightSmall)
	end
	self.controls.enemyMods.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleEnemyMods = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.enemyModsLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "\n")
	self.controls.simpleEnemyMods.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end

	self.controls.editCursesLabel = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.enemyModsLabel,"BOTTOMLEFT"}, {0, 8, 0, theme.stringHeight}, "^7Curses")
	self.controls.editCursesLabel.y = function()
		return self.controls.ShowAdvanceTools.state and (self.controls.enemyMods.height() + 8) or (theme.lineCounter(self.controls.simpleEnemyMods.label) + 4)
	end
	self.controls.editCurses = new("EditControl"):EditControl({"TOPLEFT",self.controls.editCursesLabel,"BOTTOMLEFT"}, {0, 2, 0, 0}, "", nil, "^%C\t\n", nil, nil, 14, true)
	self.controls.editCurses.width = function()
		return self.width / 2 - 16
	end
	self.controls.editCurses.height = function()
		return (self.controls.enemyCond.hasFocus or self.controls.enemyMods.hasFocus or self.controls.editPartyMemberStats.hasFocus) and theme.bufferHeightSmall or (self.height - theme.bufferHeightRight)
	end
	self.controls.editCurses.shown = function()
		return self.controls.ShowAdvanceTools.state
	end
	self.controls.simpleCurses = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.editCursesLabel,"TOPLEFT"}, {0, 18, 0, theme.stringHeight}, "")
	self.controls.simpleCurses.shown = function()
		return not self.controls.ShowAdvanceTools.state
	end
	self:SelectControl(self.controls.editAuras)
	return self
end

function PartyTabClass:OpenPasteWarrantPopup()
	local controls = {}
	local clipboard = Paste()
	local initialText = (clipboard and mercenaryWarrant.IsWarrantText(clipboard)) and clipboard or ""
	local errText = ""
	controls.label = new("LabelControl"):LabelControl(nil, {0, 16, 0, 16}, "^7Paste Mercenary Warrant text (from in-game or PoE Trade):")
	controls.edit = new("EditControl"):EditControl(nil, {0, 38, 460, 240}, initialText, nil, "^%C\t\n", nil, function(buf)
		errText = ""
		controls.add.enabled = buf:match("%S") ~= nil
	end, 14, true)
	controls.err = new("LabelControl"):LabelControl(nil, {0, 284, 0, 14}, function()
		return errText ~= "" and (colorCodes.NEGATIVE .. errText) or ""
	end)
	controls.add = new("ButtonControl"):ButtonControl(nil, {-50, 304, 90, 20}, "Add", function()
		local ok, res = mercenaryWarrant.ApplyWarrant(self.build, controls.edit.buf)
		if ok then
			main:ClosePopup()
		else
			errText = res or "Invalid Mercenary Warrant text"
		end
	end)
	controls.add.enabled = initialText ~= ""
	controls.cancel = new("ButtonControl"):ButtonControl(nil, {50, 304, 90, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(500, 336, "Paste Mercenary Warrant", controls, "add", "edit", "cancel")
end

function PartyTabClass:GetActiveMercenary()
	return self.mercenaries and self.mercenaries[self.activeMercenaryIndex] or nil
end

function PartyTabClass:IsItemValidForMercenarySlot(item, slotName, mercItems)
	if not item or not item.base then
		return false
	end
	if item.type == "Jewel" or item.type == "Flask" or item.type == "Tincture" or item.type == "Graft" or item.type == "Viscera" then
		return false
	end
	if slotName == "Weapon 1" then
		return item.base.weapon ~= nil
	elseif slotName == "Weapon 2" then
		local itemsTab = self.build and self.build.itemsTab
		local weapon1Id = mercItems and mercItems["Weapon 1"] or 0
		local weapon1 = itemsTab and itemsTab.items[weapon1Id]
		local weapon1Type = weapon1 and weapon1.base and weapon1.base.type or "None"
		local weaponInfo = self.build and self.build.data and self.build.data.weaponTypeInfo or {}
		if weapon1Type == "None" then
			return item.type == "Shield" or (weaponInfo[item.type] and weaponInfo[item.type].oneHand)
		elseif weapon1Type == "Bow" then
			return item.type == "Quiver"
		elseif weaponInfo[weapon1Type] and weaponInfo[weapon1Type].oneHand then
			return item.type == "Shield" or (weaponInfo[item.type] and weaponInfo[item.type].oneHand and ((weapon1Type == "Wand" and item.type == "Wand") or (weapon1Type ~= "Wand" and item.type ~= "Wand")))
		end
		return false
	end
	local slotType = slotName:match("^([%a ]+) %d+$") or slotName
	return item.type == slotType
end

function PartyTabClass:SyncMercenaryItemPicker(slotName)
	local control = self.controls.mercenaryItemSelect
	if not control then
		return
	end
	wipeTable(control.list)
	control.selIndex = 1
	local merc = self:GetActiveMercenary()
	local itemsTab = self.build and self.build.itemsTab
	if not slotName or not merc or not itemsTab then
		return
	end
	t_insert(control.list, { label = "None", itemId = 0 })
	local equippedId = merc.items and merc.items[slotName] or 0
	for _, itemId in ipairs(itemsTab.itemOrderList) do
		local item = itemsTab.items[itemId]
		if item and self:IsItemValidForMercenarySlot(item, slotName, merc.items) then
			t_insert(control.list, {
				label = colorCodes[item.rarity] .. item.name,
				itemId = item.id,
			})
			if item.id == equippedId then
				control.selIndex = #control.list
			end
		end
	end
end

function PartyTabClass:SyncMercenaryItemsList()
	local prevSlotName = self.controls.mercenaryItemsList and self.controls.mercenaryItemsList.selValue and self.controls.mercenaryItemsList.selValue.slotName
	wipeTable(self.mercenaryItemRows)
	local merc = self:GetActiveMercenary()
	local itemsTab = self.build and self.build.itemsTab
	local mercItems = (merc and merc.items) or (itemsTab and itemsTab.activeItemSet and itemsTab.activeItemSet.mercenaryItems)
	if merc or (mercItems and next(mercItems) ~= nil) then
		for _, slotName in ipairs(mercenarySlotOrder) do
			local itemId = mercItems and mercItems[slotName]
			if itemId and itemsTab and not itemsTab.items[itemId] then
				itemId = nil
			end
			t_insert(self.mercenaryItemRows, { slotName = slotName, itemId = itemId })
		end
	end
	if self.controls.mercenaryItemsList then
		local restoredIdx
		if prevSlotName then
			for i, row in ipairs(self.mercenaryItemRows) do
				if row.slotName == prevSlotName then
					restoredIdx = i
					break
				end
			end
		end
		self.controls.mercenaryItemsList.selIndex = restoredIdx
		self.controls.mercenaryItemsList.selValue = restoredIdx and self.mercenaryItemRows[restoredIdx] or nil
		self:SyncMercenaryItemPicker(restoredIdx and prevSlotName or nil)
	end
end

function PartyTabClass:SyncMercenaryDropdown()
	local control = self.controls.mercenarySelect
	if control then
		wipeTable(control.list)
		for i, merc in ipairs(self.mercenaries) do
			local name = (merc.name and merc.name ~= "") and merc.name or ("Mercenary #" .. tostring(i))
			local lvl = tonumber(merc.level) or 0
			local label = lvl > 0 and string.format("%s (lvl %d)", name, lvl) or name
			t_insert(control.list, { label = label, index = i })
		end
		control.selIndex = (#self.mercenaries > 0) and math.min(math.max(self.activeMercenaryIndex, 1), #self.mercenaries) or 1
	end
	self:SyncMercenaryItemsList()
end

function PartyTabClass:SetActiveMercenary(index)
	if #self.mercenaries == 0 then
		self.activeMercenaryIndex = 1
		self:SyncMercenaryDropdown()
		return
	end
	self.activeMercenaryIndex = math.min(math.max(tonumber(index) or 1, 1), #self.mercenaries)
	local merc = self.mercenaries[self.activeMercenaryIndex]
	local itemsTab = self.build and self.build.itemsTab
	if itemsTab and itemsTab.activeItemSet and merc then
		itemsTab.activeItemSet.mercenaryName = merc.name
		itemsTab.activeItemSet.mercenaryBuild = merc.build
		itemsTab.activeItemSet.mercenaryType = merc.type
		itemsTab.activeItemSet.mercenaryLevel = merc.level
		itemsTab.activeItemSet.mercenaryItems = merc.items or {}
	end
	local skillsTab = self.build and self.build.skillsTab
	if skillsTab and skillsTab.mercenarySocketGroupList and merc then
		wipeTable(skillsTab.mercenarySocketGroupList)
		for _, group in ipairs(merc.skills or {}) do
			t_insert(skillsTab.mercenarySocketGroupList, group)
		end
	end
	self:SyncMercenaryDropdown()
	if self.build then
		self.build.buildFlag = true
	end
end

function PartyTabClass:UpsertMercenary(entry)
	if not entry then
		return
	end
	entry.skills = entry.skills or {}
	entry.items = entry.items or {}
	local matchIdx
	for i, existing in ipairs(self.mercenaries) do
		if entry.index ~= nil and existing.index ~= nil and existing.index == entry.index then
			matchIdx = i
			break
		elseif entry.name and entry.name ~= "" and existing.name == entry.name then
			matchIdx = i
			break
		end
	end
	if matchIdx then
		if next(entry.items) == nil and self.mercenaries[matchIdx].items and next(self.mercenaries[matchIdx].items) ~= nil and not entry.replaceItems then
			entry.items = self.mercenaries[matchIdx].items
		end
		entry.replaceItems = nil
		self.mercenaries[matchIdx] = entry
		self:SetActiveMercenary(matchIdx)
	else
		entry.replaceItems = nil
		t_insert(self.mercenaries, entry)
		self:SetActiveMercenary(#self.mercenaries)
	end
end

function PartyTabClass:RemoveActiveMercenary()
	if #self.mercenaries == 0 then
		return
	end
	table.remove(self.mercenaries, self.activeMercenaryIndex)
	if #self.mercenaries == 0 then
		local itemsTab = self.build and self.build.itemsTab
		if itemsTab and itemsTab.activeItemSet then
			itemsTab.activeItemSet.mercenaryName = nil
			itemsTab.activeItemSet.mercenaryBuild = nil
			itemsTab.activeItemSet.mercenaryType = nil
			itemsTab.activeItemSet.mercenaryLevel = nil
			itemsTab.activeItemSet.mercenaryItems = {}
		end
		local skillsTab = self.build and self.build.skillsTab
		if skillsTab and skillsTab.mercenarySocketGroupList then
			wipeTable(skillsTab.mercenarySocketGroupList)
		end
		self.activeMercenaryIndex = 1
		self:SyncMercenaryDropdown()
		if self.build then
			self.build.buildFlag = true
		end
	else
		self:SetActiveMercenary(math.min(self.activeMercenaryIndex, #self.mercenaries))
	end
end

function PartyTabClass:IsMercenaryShown()
	if self.build and self.build.spec and self.build.spec.curAscendClassName == "Luminary" then
		return true
	end
	if self.mercenaries and #self.mercenaries > 0 then
		return true
	end
	local skillsTab = self.build and self.build.skillsTab
	if skillsTab and skillsTab.mercenarySocketGroupList and #skillsTab.mercenarySocketGroupList > 0 then
		return true
	end
	local itemsTab = self.build and self.build.itemsTab
	if itemsTab and itemsTab.activeItemSet and itemsTab.activeItemSet.mercenaryItems then
		for _, itemId in pairs(itemsTab.activeItemSet.mercenaryItems) do
			if itemId and itemId ~= 0 then
				return true
			end
		end
	end
	return false
end

function PartyTabClass:BuildMercenarySkillsText()
	local lines = {}
	local merc = self:GetActiveMercenary()
	local skillsTab = self.build and self.build.skillsTab
	local skillGroups = (merc and merc.skills) or (skillsTab and skillsTab.mercenarySocketGroupList)
	if skillGroups and #skillGroups > 0 then
		t_insert(lines, "^7Skills:")
		for _, group in ipairs(skillGroups) do
			local parts = {}
			for _, gem in ipairs(group.gemList or {}) do
				local name = (gem.gemData and gem.gemData.name) or (gem.grantedEffect and gem.grantedEffect.name) or gem.nameSpec
				if name and name ~= "" then
					local info = {}
					if gem.level then
						t_insert(info, "Lv " .. tostring(gem.level))
					end
					if gem.mercTier then
						t_insert(info, "Tier " .. tostring(gem.mercTier))
					end
					t_insert(parts, #info > 0 and (name .. " (" .. table.concat(info, ", ") .. ")") or name)
				end
			end
			if #parts > 0 then
				t_insert(lines, "  " .. (group.enabled == false and "^x7F7F7F" or "^7") .. table.concat(parts, " + "))
			end
		end
	else
		t_insert(lines, "^x7F7F7FSkills: None")
	end
	return table.concat(lines, "\n")
end

function PartyTabClass:BuildMercenarySummaryText()
	local lines = { self:BuildMercenarySkillsText() }
	local merc = self:GetActiveMercenary()

	local itemsTab = self.build and self.build.itemsTab
	local itemLines = {}
	local mercItems = (merc and merc.items) or (itemsTab and itemsTab.activeItemSet and itemsTab.activeItemSet.mercenaryItems)
	if mercItems and itemsTab then
		for slotName, itemId in pairsSortByKey(mercItems) do
			if itemId and itemId ~= 0 then
				local item = itemsTab.items[itemId]
				if item then
					t_insert(itemLines, "  ^7" .. slotName .. ": " .. colorCodes[item.rarity] .. item.name)
				end
			end
		end
	end
	if #itemLines > 0 then
		t_insert(lines, "^7Items:")
		for _, l in ipairs(itemLines) do
			t_insert(lines, l)
		end
	else
		t_insert(lines, "^x7F7F7FItems: None")
	end
	return table.concat(lines, "\n")
end

function PartyTabClass:ParseMercenaryNode(mercNode, itemLookup)
	local itemsTab = self.build and self.build.itemsTab
	local skillsTab = self.build and self.build.skillsTab
	local entry = {
		index = tonumber(mercNode.attrib.index),
		name = mercNode.attrib.name,
		build = mercNode.attrib.build,
		type = mercNode.attrib.type,
		level = tonumber(mercNode.attrib.level),
		skills = {},
		items = {},
		replaceItems = true,
	}
	for _, child in ipairs(mercNode) do
		if child.elem == "Skills" and skillsTab then
			for _, skillNode in ipairs(child) do
				if skillNode.elem == "Skill" then
					skillsTab:LoadSkill(skillNode, skillsTab.activeSkillSetId, entry.skills)
					if entry.skills[#entry.skills] then
						entry.skills[#entry.skills].isMercenary = true
					end
				end
			end
		elseif child.elem == "Items" and itemsTab then
			for _, slotNode in ipairs(child) do
				if slotNode.elem == "Slot" and slotNode.attrib.name and slotNode.attrib.itemId then
					local slotName = slotNode.attrib.name:gsub("^Mercenary ", "")
					local srcId = tonumber(slotNode.attrib.itemId)
					if srcId and srcId ~= 0 then
						if itemLookup and itemLookup[srcId] then
							local rawText
							for _, itemChild in ipairs(itemLookup[srcId]) do
								if type(itemChild) == "string" then
									rawText = itemChild
									break
								end
							end
							if rawText then
								local newItem = new("Item"):Item(rawText)
								if newItem.base then
									itemsTab:AddItem(newItem, true)
									entry.items[slotName] = newItem.id
								end
							end
						elseif itemsTab.items[srcId] then
							entry.items[slotName] = srcId
						end
					end
				end
			end
		end
	end
	return entry
end

function PartyTabClass:ApplyMercenariesXML(node, dbXML, replaceExisting)
	if not node then
		return
	end
	local itemLookup
	if dbXML then
		itemLookup = {}
		for _, tabNode in ipairs(dbXML[1]) do
			if type(tabNode) == "table" and tabNode.elem == "Items" then
				for _, itemNode in ipairs(tabNode) do
					if itemNode.elem == "Item" and itemNode.attrib.id then
						itemLookup[tonumber(itemNode.attrib.id)] = itemNode
					end
				end
			end
		end
	end

	local hadExisting = #self.mercenaries > 0
	local prevActive = self.activeMercenaryIndex
	if replaceExisting then
		wipeTable(self.mercenaries)
	end

	local activeIdx = 1
	if node.elem == "Mercenaries" then
		activeIdx = tonumber(node.attrib.active) or 1
		for _, child in ipairs(node) do
			if child.elem == "Mercenary" then
				local entry = self:ParseMercenaryNode(child, itemLookup)
				if replaceExisting then
					t_insert(self.mercenaries, entry)
				else
					self:UpsertMercenary(entry)
				end
			end
		end
		if not replaceExisting and hadExisting then
			activeIdx = prevActive
		end
	elseif node.elem == "Mercenary" then
		local entry = self:ParseMercenaryNode(node, itemLookup)
		self:UpsertMercenary(entry)
		activeIdx = (not replaceExisting and hadExisting) and prevActive or self.activeMercenaryIndex
	end

	if #self.mercenaries > 0 then
		self:SetActiveMercenary(activeIdx)
	else
		self:SyncMercenaryDropdown()
	end
	if self.build and self.build.itemsTab then
		self.build.itemsTab:PopulateSlots()
	end
end

function PartyTabClass:PostLoad()
	if self.pendingMercenaryXML then
		self:ApplyMercenariesXML(self.pendingMercenaryXML, nil, true)
		self.pendingMercenaryXML = nil
	end
end

function PartyTabClass:Load(xml, fileName)
	self.pendingMercenaryXML = nil
	wipeTable(self.mercenaries)
	self.activeMercenaryIndex = 1
	self:SyncMercenaryDropdown()
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
			elseif node.attrib.name == "Warcry Skills" then
				self.controls.editWarcries:SetText(node[1] or "")
				self:ParseBuffs(self.actor["Warcry"], node[1] or "", "Warcry", self.controls.simpleWarcries)
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
			--self:ParseBuffs(self.buffExports, node[1] or "", "Warcry")
			--self:ParseBuffs(self.buffExports, node[1] or "", "Link")
			--self:ParseBuffs(self.buffExports, node[1] or "", "EnemyConditions")
			--self:ParseBuffs(self.buffExports, node[1] or "", "EnemyMods")
		elseif node.elem == "Mercenary" or node.elem == "Mercenaries" then
			self.pendingMercenaryXML = node
		end
	end
	self.lastContent.PartyMemberStats = self.controls.editPartyMemberStats.buf
	self.lastContent.Aura = self.controls.editAuras.buf
	self.lastContent.Curse = self.controls.editCurses.buf
	self.lastContent.Warcry = self.controls.editWarcries.buf
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
	if self.controls.editWarcries.buf and self.controls.editWarcries.buf ~= "" then
		child = { elem = "ImportedBuffs", attrib = { name = "Warcry Skills" } }
		t_insert(child, self.controls.editWarcries.buf)
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
	local function serializeMercenaryNode(merc)
		local mercNode = {
			elem = "Mercenary",
			attrib = {
				index = merc.index ~= nil and tostring(merc.index) or nil,
				name = merc.name,
				build = merc.build,
				type = merc.type,
				level = merc.level and tostring(merc.level) or nil,
			}
		}
		if merc.skills and #merc.skills > 0 then
			local skillsNode = { elem = "Skills" }
			for _, socketGroup in ipairs(merc.skills) do
				local skillNode = { elem = "Skill", attrib = {
					enabled = tostring(socketGroup.enabled),
					label = socketGroup.label,
				} }
				for _, gemInstance in ipairs(socketGroup.gemList) do
					t_insert(skillNode, { elem = "Gem", attrib = {
						nameSpec = gemInstance.nameSpec,
						skillId = gemInstance.skillId,
						gemId = gemInstance.gemData and gemInstance.gemData.gameId,
						variantId = gemInstance.gemData and gemInstance.gemData.variantId,
						level = tostring(gemInstance.level),
						quality = tostring(gemInstance.quality),
						mercTier = gemInstance.mercTier and tostring(gemInstance.mercTier),
						enabled = tostring(gemInstance.enabled),
						enableGlobal1 = tostring(gemInstance.enableGlobal1),
						enableGlobal2 = tostring(gemInstance.enableGlobal2),
						count = tostring(gemInstance.count),
					} })
				end
				t_insert(skillsNode, skillNode)
			end
			t_insert(mercNode, skillsNode)
		end
		if merc.items and next(merc.items) ~= nil then
			local itemsNode = { elem = "Items" }
			for slotName, itemId in pairsSortByKey(merc.items) do
				if itemId and itemId ~= 0 then
					t_insert(itemsNode, { elem = "Slot", attrib = { name = slotName, itemId = tostring(itemId) } })
				end
			end
			if #itemsNode > 0 then
				t_insert(mercNode, itemsNode)
			end
		end
		return mercNode
	end

	local mercList = self.mercenaries
	if #mercList == 0 then
		local skillsTab = self.build and self.build.skillsTab
		local itemsTab = self.build and self.build.itemsTab
		local itemSet = itemsTab and itemsTab.activeItemSet
		local hasMercMeta = itemSet and ((itemSet.mercenaryName and itemSet.mercenaryName ~= "") or (itemSet.mercenaryBuild and itemSet.mercenaryBuild ~= "") or (itemSet.mercenaryLevel and itemSet.mercenaryLevel > 0))
		local hasMercSkills = skillsTab and skillsTab.mercenarySocketGroupList and #skillsTab.mercenarySocketGroupList > 0
		local hasMercItems = itemSet and itemSet.mercenaryItems and next(itemSet.mercenaryItems) ~= nil
		if hasMercMeta or hasMercSkills or hasMercItems then
			mercList = { {
				name = itemSet and itemSet.mercenaryName,
				build = itemSet and itemSet.mercenaryBuild,
				type = itemSet and itemSet.mercenaryType,
				level = itemSet and itemSet.mercenaryLevel,
				skills = skillsTab and skillsTab.mercenarySocketGroupList or {},
				items = itemSet and itemSet.mercenaryItems or {},
			} }
		end
	end
	if #mercList > 0 then
		local mercsNode = { elem = "Mercenaries", attrib = { active = tostring(self.activeMercenaryIndex or 1) } }
		for _, merc in ipairs(mercList) do
			t_insert(mercsNode, serializeMercenaryNode(merc))
		end
		t_insert(xml, mercsNode)
	end
	xml.attrib = {
		destination = self.controls.importCodeDestination.list[self.controls.importCodeDestination.selIndex],
		append = tostring(self.controls.appendNotReplace.state),
		ShowAdvanceTools = tostring(self.controls.ShowAdvanceTools.state)
	}
end

function PartyTabClass:ResetModFlags()
	self.lastContent.PartyMemberStats = self.controls.editPartyMemberStats.buf
	self.lastContent.Aura = self.controls.editAuras.buf
	self.lastContent.Curse = self.controls.editCurses.buf
	self.lastContent.Warcry = self.controls.editWarcries.buf
	self.lastContent.Link = self.controls.editLinks.buf
	self.lastContent.EnemyCond = self.controls.enemyCond.buf
	self.lastContent.EnemyMods = self.controls.enemyMods.buf
	self.lastContent.EnableExportBuffs = self.enableExportBuffs
	self.lastContent.showAdvancedTools = self.controls.ShowAdvanceTools.state
	self.modFlag = false
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
			or self.lastContent.Warcry ~= self.controls.editWarcries.buf
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
					local k1, k2, v = line:match("^([%w ]-%w+)%.([%w ]-%w+)=(.+)$")
					if k1 then
						if type(label[k1]) ~= "table" then
							label[k1] = { }
						end
						label[k1][k2] = tonumber(v)
					elseif line:match("|") then
						local k, tags, v = line:match("([%w ]-%w+)|(.+)=(.+)")
						v = tonumber(v)
						for tag in tags:gmatch("([^|]*)|?") do
							if tag == "percent" then
								v = v / 100
							elseif tag == "max" then
								v = m_max(v, label[k] or 1)
							end
						end
						label[k] = v
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
								modList = new("ModList"):ModList(),
								effectMult = currentEffect
							}
							if isMark then
								listElement[currentName].isMark = true
							end
						elseif listElement[currentName].effectMult ~= currentEffect then
							if listElement[currentName].effectMult < currentEffect then
								listElement[currentName] = {
									modList = new("ModList"):ModList(),
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
			elseif buffType == "Warcry" then
				local labelList = {}
				for warcry, warcryMod in pairs(list["Warcry"] or {}) do
					t_insert(labelList, warcry..": "..warcryMod.effectMult.."%\n")
				end
				if #labelList > 0 then
					table.sort(labelList)
					label.label = "^7---------------------------\n"..table.concat(labelList).."---------------------------\n"
				else
					label.label = ""
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
	for buffName, buff in pairsSortByKey(self.buffExports[buffType]) do
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
				for innerBuffName, innerBuff in pairsSortByKey(buff) do
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