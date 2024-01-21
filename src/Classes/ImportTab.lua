-- Path of Building
--
-- Module: Import Tab
-- Import/Export tab for the current build.
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local b_rshift = bit.rshift
local band = bit.band

local realmList = {
	{ label = "PC", id = "PC", realmCode = "pc", hostName = "https://www.pathofexile.com/", profileURL = "account/view-profile/" },
	{ label = "Xbox", id = "XBOX", realmCode = "xbox", hostName = "https://www.pathofexile.com/", profileURL = "account/xbox/view-profile/" },
	{ label = "PS4", id = "SONY", realmCode = "sony", hostName = "https://www.pathofexile.com/", profileURL = "account/sony/view-profile/" },
	{ label = "Garena", id = "PC", realmCode = "pc", hostName = "https://web.poe.garena.tw/", profileURL = "account/view-profile/" },
	{ label = "Tencent", id = "PC", realmCode = "pc", hostName = "https://poe.game.qq.com/", profileURL = "account/view-profile/" },
}

local influenceInfo = itemLib.influenceInfo

local ImportTabClass = newClass("ImportTab", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

	self.build = build

	self.charImportMode = "GETACCOUNTNAME"
	self.charImportStatus = "Idle"
	self.controls.sectionCharImport = new("SectionControl", {"TOPLEFT",self,"TOPLEFT"}, 10, 18, 650, 250, "Character Import")
	self.controls.charImportStatusLabel = new("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, 6, 14, 200, 16, function()
		return "^7Character import status: "..self.charImportStatus
	end)

	-- Stage: input account name
	self.controls.accountNameHeader = new("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, 6, 40, 200, 16, "^7To start importing a character, enter the character's account name:")
	self.controls.accountNameHeader.shown = function()
		return self.charImportMode == "GETACCOUNTNAME"
	end
	self.controls.accountRealm = new("DropDownControl", {"TOPLEFT",self.controls.accountNameHeader,"BOTTOMLEFT"}, 0, 4, 60, 20, realmList )
	self.controls.accountRealm:SelByValue( main.lastRealm or "PC", "id" )
	self.controls.accountName = new("EditControl", {"LEFT",self.controls.accountRealm,"RIGHT"}, 8, 0, 200, 20, main.lastAccountName or "", nil, "%c", nil, nil, nil, nil, true)
	self.controls.accountName.pasteFilter = function(text)
		return text:gsub("[\128-\255]",function(c)
			return codePointToUTF8(c:byte(1)):gsub(".",function(c)
				return string.format("%%%X", c:byte(1))
			end)
		end)
	end
	-- accountHistory Control
	if not historyList then
		historyList = { }
		for accountName, account in pairs(main.gameAccounts) do
			t_insert(historyList, accountName)
			historyList[accountName] = true
		end
		table.sort(historyList, function(a,b)
			return a:lower() < b:lower()
		end)
	end -- don't load the list many times
	self.controls.accountNameGo = new("ButtonControl", {"LEFT",self.controls.accountName,"RIGHT"}, 8, 0, 60, 20, "Start", function()
		self.controls.sessionInput.buf = ""
		self:DownloadCharacterList()
	end)
	self.controls.accountNameGo.enabled = function()
		return self.controls.accountName.buf:match("%S")
	end

	self.controls.accountHistory = new("DropDownControl", {"LEFT",self.controls.accountNameGo,"RIGHT"}, 8, 0, 200, 20, historyList, function()
		self.controls.accountName.buf = self.controls.accountHistory.list[self.controls.accountHistory.selIndex]
	end)
	self.controls.accountHistory:SelByValue(main.lastAccountName)
	self.controls.accountHistory:CheckDroppedWidth(true)

	self.controls.removeAccount = new("ButtonControl", {"LEFT",self.controls.accountHistory,"RIGHT"}, 8, 0, 20, 20, "X", function()
		local accountName = self.controls.accountHistory.list[self.controls.accountHistory.selIndex]
		if (accountName ~= nil) then
		t_remove(self.controls.accountHistory.list, self.controls.accountHistory.selIndex)
		self.controls.accountHistory.list[accountName] = nil
		main.gameAccounts[accountName] = nil
		end
	end)

	self.controls.removeAccount.tooltipFunc = function(tooltip)
		tooltip:Clear()
		tooltip:AddLine(16, "^7Removes account from the dropdown list")
	end

	self.controls.accountNameUnicode = new("LabelControl", {"TOPLEFT",self.controls.accountRealm,"BOTTOMLEFT"}, 0, 16, 0, 14, "^7Note: if the account name contains non-ASCII characters then it must be URL encoded first.")
	self.controls.accountNameURLEncoder = new("ButtonControl", {"TOPLEFT",self.controls.accountNameUnicode,"BOTTOMLEFT"}, 0, 4, 170, 18, "^x4040FFhttps://www.urlencoder.org/", function()
		OpenURL("https://www.urlencoder.org/")
	end)

	-- Stage: input POESESSID
	self.controls.sessionHeader = new("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, 6, 40, 200, 14)
	self.controls.sessionHeader.label = function()
		return [[
^7The list of characters on ']]..self.controls.accountName.buf..[[' couldn't be retrieved. This may be because:
1. You entered a character name instead of an account name or
2. This account's characters tab is hidden (this is the default setting).
If this is your account, you can either:
1. Uncheck "Hide Characters" in your privacy settings or
2. Enter a POESESSID below.
You can get this from your web browser's cookies while logged into the Path of Exile website.
		]]
	end
	self.controls.sessionHeader.shown = function()
		return self.charImportMode == "GETSESSIONID"
	end
	self.controls.sessionRetry = new("ButtonControl", {"TOPLEFT",self.controls.sessionHeader,"TOPLEFT"}, 0, 108, 60, 20, "Retry", function()
		self:DownloadCharacterList()
	end)
	self.controls.sessionCancel = new("ButtonControl", {"LEFT",self.controls.sessionRetry,"RIGHT"}, 8, 0, 60, 20, "Cancel", function()
		self.charImportMode = "GETACCOUNTNAME"
		self.charImportStatus = "Idle"
	end)
	self.controls.sessionPrivacySettings = new("ButtonControl", {"LEFT",self.controls.sessionCancel,"RIGHT"}, 8, 0, 120, 20, "Privacy Settings", function()
		OpenURL('https://www.pathofexile.com/my-account/privacy')
	end)
	self.controls.sessionInput = new("EditControl", {"TOPLEFT",self.controls.sessionRetry,"BOTTOMLEFT"}, 0, 8, 350, 20, "", "POESESSID", "%X", 32)
	self.controls.sessionInput:SetProtected(true)
	self.controls.sessionGo = new("ButtonControl", {"LEFT",self.controls.sessionInput,"RIGHT"}, 8, 0, 60, 20, "Go", function()
		self:DownloadCharacterList()
	end)
	self.controls.sessionGo.enabled = function()
		return #self.controls.sessionInput.buf == 32
	end

	-- Stage: select character and import data
	self.controls.charSelectHeader = new("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, 6, 40, 200, 16, "^7Choose character to import data from:")
	self.controls.charSelectHeader.shown = function()
		return self.charImportMode == "SELECTCHAR" or self.charImportMode == "IMPORTING"
	end
	self.controls.charSelectLeagueLabel = new("LabelControl", {"TOPLEFT",self.controls.charSelectHeader,"BOTTOMLEFT"}, 0, 6, 0, 14, "^7League:")
	self.controls.charSelectLeague = new("DropDownControl", {"LEFT",self.controls.charSelectLeagueLabel,"RIGHT"}, 4, 0, 150, 18, nil, function(index, value)
		self:BuildCharacterList(value.league)
	end)
	self.controls.charSelect = new("DropDownControl", {"TOPLEFT",self.controls.charSelectHeader,"BOTTOMLEFT"}, 0, 24, 400, 18)
	self.controls.charSelect.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charImportHeader = new("LabelControl", {"TOPLEFT",self.controls.charSelect,"BOTTOMLEFT"}, 0, 16, 200, 16, "Import:")
	self.controls.charImportTree = new("ButtonControl", {"LEFT",self.controls.charImportHeader, "RIGHT"}, 8, 0, 170, 20, "Passive Tree and Jewels", function()
		if self.build.spec:CountAllocNodes() > 0 then
			main:OpenConfirmPopup("Character Import", "Importing the passive tree will overwrite your current tree.", "Import", function()
				self:DownloadPassiveTree()
			end)
		else
			self:DownloadPassiveTree()
		end
	end)
	self.controls.charImportTree.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charImportTreeClearJewels = new("CheckBoxControl", {"LEFT",self.controls.charImportTree,"RIGHT"}, 90, 0, 18, "Delete jewels:", nil, "Delete all existing jewels when importing.", true)
	self.controls.charImportItems = new("ButtonControl", {"LEFT",self.controls.charImportTree, "LEFT"}, 0, 36, 110, 20, "Items and Skills", function()
		self:DownloadItems()
	end)
	self.controls.charImportItems.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charImportItemsClearSkills = new("CheckBoxControl", {"LEFT",self.controls.charImportItems,"RIGHT"}, 85, 0, 18, "Delete skills:", nil, "Delete all existing skills when importing.", true)
	self.controls.charImportItemsClearItems = new("CheckBoxControl", {"LEFT",self.controls.charImportItems,"RIGHT"}, 220, 0, 18, "Delete equipment:", nil, "Delete all equipped items when importing.", true)
	self.controls.charImportItemsIgnoreWeaponSwap = new("CheckBoxControl", {"LEFT",self.controls.charImportItems,"RIGHT"}, 380, 0, 18, "Ignore weapon swap:", nil, "Ignore items and skills in weapon swap.", false)
	self.controls.charBanditNote = new("LabelControl", {"TOPLEFT",self.controls.charImportHeader,"BOTTOMLEFT"}, 0, 50, 200, 14, "^7Tip: After you finish importing a character, make sure you update the bandit choice,\nas it cannot be imported.")

	self.controls.charClose = new("ButtonControl", {"TOPLEFT",self.controls.charImportHeader,"BOTTOMLEFT"}, 0, 90, 60, 20, "Close", function()
		self.charImportMode = "GETACCOUNTNAME"
		self.charImportStatus = "Idle"
	end)

	-- Build import/export
	self.controls.sectionBuild = new("SectionControl", {"TOPLEFT",self.controls.sectionCharImport,"BOTTOMLEFT"}, 0, 18, 650, 182, "Build Sharing")
	self.controls.generateCodeLabel = new("LabelControl", {"TOPLEFT",self.controls.sectionBuild,"TOPLEFT"}, 6, 14, 0, 16, "^7Generate a code to share this build with other Path of Building users:")
	self.controls.generateCode = new("ButtonControl", {"LEFT",self.controls.generateCodeLabel,"RIGHT"}, 4, 0, 80, 20, "Generate", function()
		self.controls.generateCodeOut:SetText(common.base64.encode(Deflate(self.build:SaveDB("code"))):gsub("+","-"):gsub("/","_"))
	end)
	self.controls.enablePartyExportBuffs = new("CheckBoxControl", {"LEFT",self.controls.generateCode,"RIGHT"}, 100, 0, 18, "Export Support", function(state)
		self.build.partyTab.enableExportBuffs = state
		self.build.buildFlag = true 
	end, "This is for party play, to export support character, it enables the exporting of auras, curses and modifiers to the enemy", false)
	self.controls.generateCodeOut = new("EditControl", {"TOPLEFT",self.controls.generateCodeLabel,"BOTTOMLEFT"}, 0, 8, 250, 20, "", "Code", "%Z")
	self.controls.generateCodeOut.enabled = function()
		return #self.controls.generateCodeOut.buf > 0
	end
	self.controls.generateCodeCopy = new("ButtonControl", {"LEFT",self.controls.generateCodeOut,"RIGHT"}, 8, 0, 60, 20, "Copy", function()
		Copy(self.controls.generateCodeOut.buf)
		self.controls.generateCodeOut:SetText("")
	end)
	self.controls.generateCodeCopy.enabled = function()
		return #self.controls.generateCodeOut.buf > 0
	end

	local getExportSitesFromImportList = function()
		local exportWebsites = { }
		for k,v in pairs(buildSites.websiteList) do
			-- if entry has fields needed for Export
			if buildSites.websiteList[k].postUrl and buildSites.websiteList[k].postFields and buildSites.websiteList[k].codeOut then
				table.insert(exportWebsites, v)
			end
		end
		return exportWebsites
	end
	local exportWebsitesList = getExportSitesFromImportList()

	self.controls.exportFrom = new("DropDownControl", { "LEFT", self.controls.generateCodeCopy,"RIGHT"}, 8, 0, 120, 20, exportWebsitesList, function(_, selectedWebsite)
		main.lastExportWebsite = selectedWebsite.id
		self.exportWebsiteSelected = selectedWebsite.id
	end)
	self.controls.exportFrom:SelByValue(self.exportWebsiteSelected or main.lastExportWebsite or "Pastebin", "id")
	self.controls.generateCodeByLink = new("ButtonControl", { "LEFT", self.controls.exportFrom, "RIGHT"}, 8, 0, 100, 20, "Share", function()
		local exportWebsite = exportWebsitesList[self.controls.exportFrom.selIndex]
		local response = buildSites.UploadBuild(self.controls.generateCodeOut.buf, exportWebsite)
		if response then
			self.controls.generateCodeOut:SetText("")
			self.controls.generateCodeByLink.label = "Creating link..."
			launch:RegisterSubScript(response, function(pasteLink, errMsg)
				self.controls.generateCodeByLink.label = "Share"
				if errMsg then
					main:OpenMessagePopup(exportWebsite.id, "Error creating link:\n"..errMsg)
				else
					self.controls.generateCodeOut:SetText(exportWebsite.codeOut..pasteLink)
				end
			end)
		end
	end)
	self.controls.generateCodeByLink.enabled = function()
		for _, exportSite in ipairs(exportWebsitesList) do
			if #self.controls.generateCodeOut.buf > 0 and self.controls.generateCodeOut.buf:match(exportSite.matchURL) then
				return false
			end
		end
		return #self.controls.generateCodeOut.buf > 0
	end
	self.controls.exportFrom.enabled = function()
		for _, exportSite in ipairs(exportWebsitesList) do
			if #self.controls.generateCodeOut.buf > 0 and self.controls.generateCodeOut.buf:match(exportSite.matchURL) then
				return false
			end
		end
		return #self.controls.generateCodeOut.buf > 0
	end
	self.controls.generateCodeNote = new("LabelControl", {"TOPLEFT",self.controls.generateCodeOut,"BOTTOMLEFT"}, 0, 4, 0, 14, "^7Note: this code can be very long; you can use 'Share' to shrink it.")
	self.controls.importCodeHeader = new("LabelControl", {"TOPLEFT",self.controls.generateCodeNote,"BOTTOMLEFT"}, 0, 26, 0, 16, "^7To import a build, enter URL or code here:")

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

	local importSelectedBuild = function()
		if not self.importCodeValid or self.importCodeFetching then
			return
		end

		if self.controls.importCodeMode.selIndex == 1 then
			main:OpenConfirmPopup("Build Import", colorCodes.WARNING.."Warning:^7 Importing to the current build will erase ALL existing data for this build.", "Import", function()
				self.build:Shutdown()
				self.build:Init(self.build.dbFileName, self.build.buildName, self.importCodeXML)
				self.build.viewMode = "TREE"
			end)
		else
			self.build:Shutdown()
			self.build:Init(false, "Imported build", self.importCodeXML)
			self.build.viewMode = "TREE"
		end
	end

	self.controls.importCodeIn = new("EditControl", {"TOPLEFT",self.controls.importCodeHeader,"BOTTOMLEFT"}, 0, 4, 328, 20, "", nil, nil, nil, importCodeHandle, nil, nil, true)
	self.controls.importCodeIn.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
	self.controls.importCodeState = new("LabelControl", {"LEFT",self.controls.importCodeIn,"RIGHT"}, 8, 0, 0, 16)
	self.controls.importCodeState.label = function()
		return self.importCodeDetail or ""
	end
	self.controls.importCodeMode = new("DropDownControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, 0, 4, 160, 20, { "Import to this build", "Import to a new build" })
	self.controls.importCodeMode.enabled = function()
		return self.build.dbFileName and self.importCodeValid
	end
	self.controls.importCodeGo = new("ButtonControl", {"LEFT",self.controls.importCodeMode,"RIGHT"}, 8, 0, 160, 20, "Import", function()
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
					importSelectedBuild()
				end
			end)
			return
		end

		importSelectedBuild()
	end)
	self.controls.importCodeGo.label = function ()
		return self.importCodeFetching and "Retrieving paste.." or "Import"
	end
	self.controls.importCodeGo.enabled = function()
		return self.importCodeValid and not self.importCodeFetching
	end
	self.controls.importCodeGo.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
end)

function ImportTabClass:Load(xml, fileName)
	self.lastRealm = xml.attrib.lastRealm
	self.controls.accountRealm:SelByValue( self.lastRealm or main.lastRealm or "PC", "id" )
	self.lastAccountHash = xml.attrib.lastAccountHash
	self.controls.enablePartyExportBuffs.state = xml.attrib.exportParty == "true"
	self.build.partyTab.enableExportBuffs = self.controls.enablePartyExportBuffs.state
	if self.lastAccountHash then
		for accountName in pairs(main.gameAccounts) do
			if common.sha1(accountName) == self.lastAccountHash then
				self.controls.accountName:SetText(accountName)
			end
		end
	end
	self.lastCharacterHash = xml.attrib.lastCharacterHash
end

function ImportTabClass:Save(xml)
	xml.attrib = {
		lastRealm = self.lastRealm,
		lastAccountHash = self.lastAccountHash,
		lastCharacterHash = self.lastCharacterHash,
		exportParty = tostring(self.controls.enablePartyExportBuffs.state),
	}
end

function ImportTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)
end

function ImportTabClass:DownloadCharacterList()
	self.charImportMode = "DOWNLOADCHARLIST"
	self.charImportStatus = "Retrieving character list..."
	  -- Trim Trailing/Leading spaces
	local accountName = self.controls.accountName.buf:gsub('%s+', '')
	local realm = realmList[self.controls.accountRealm.selIndex]
	local sessionID = #self.controls.sessionInput.buf == 32 and self.controls.sessionInput.buf or (main.gameAccounts[accountName] and main.gameAccounts[accountName].sessionID)
	launch:DownloadPage(realm.hostName.."character-window/get-characters?accountName="..accountName.."&realm="..realm.realmCode, function(response, errMsg)
		if errMsg == "Response code: 401" then
			self.charImportStatus = colorCodes.NEGATIVE.."Sign-in is required."
			self.charImportMode = "GETSESSIONID"
			return
		elseif errMsg == "Response code: 403" then
			self.charImportStatus = colorCodes.NEGATIVE.."Account profile is private."
			self.charImportMode = "GETSESSIONID"
			return
		elseif errMsg == "Response code: 404" then
			self.charImportStatus = colorCodes.NEGATIVE.."Account name is incorrect."
			self.charImportMode = "GETACCOUNTNAME"
			return
		elseif errMsg then
			self.charImportStatus = colorCodes.NEGATIVE.."Error retrieving character list, try again ("..errMsg:gsub("\n"," ")..")"
			self.charImportMode = "GETACCOUNTNAME"
			return
		end
		local charList, errMsg = self:ProcessJSON(response.body)
		if errMsg then
			self.charImportStatus = colorCodes.NEGATIVE.."Error processing character list, try again later"
			self.charImportMode = "GETACCOUNTNAME"
			return
		end
		--ConPrintTable(charList)
		if #charList == 0 then
			self.charImportStatus = colorCodes.NEGATIVE.."The account has no characters to import."
			self.charImportMode = "GETACCOUNTNAME"
			return
		end
		-- GGG's character API has an issue where for /get-characters the account name is not case-sensitive, but for /get-passive-skills and /get-items it is.
		-- This workaround grabs the profile page and extracts the correct account name from one of the URLs.
		launch:DownloadPage(realm.hostName..realm.profileURL..accountName, function(response, errMsg)
			if errMsg then
				self.charImportStatus = colorCodes.NEGATIVE.."Error retrieving character list, try again ("..errMsg:gsub("\n"," ")..")"
				self.charImportMode = "GETACCOUNTNAME"
				return
			end
			local realAccountName = response.body:match("/view%-profile/([^/]+)/characters"):gsub(".", function(c) if c:byte(1) > 127 then return string.format("%%%2X",c:byte(1)) else return c end end)
			if not realAccountName then
				self.charImportStatus = colorCodes.NEGATIVE.."Failed to retrieve character list."
				self.charImportMode = "GETSESSIONID"
				return
			end
			self.controls.accountName:SetText(realAccountName)
			accountName = realAccountName
			self.charImportStatus = "Character list successfully retrieved."
			self.charImportMode = "SELECTCHAR"
			self.lastRealm = realm.id
			main.lastRealm = realm.id
			self.lastAccountHash = common.sha1(accountName)
			main.lastAccountName = accountName
			main.gameAccounts[accountName] = main.gameAccounts[accountName] or { }
			main.gameAccounts[accountName].sessionID = sessionID
			local leagueList = { }
			for i, char in ipairs(charList) do
				if not isValueInArray(leagueList, char.league) then
					t_insert(leagueList, char.league)
				end
			end
			table.sort(leagueList)
			wipeTable(self.controls.charSelectLeague.list)
			for _, league in ipairs(leagueList) do
				t_insert(self.controls.charSelectLeague.list, {
					label = league,
					league = league,
				})
			end
			t_insert(self.controls.charSelectLeague.list, {
				label = "All",
			})
			if self.controls.charSelectLeague.selIndex > #self.controls.charSelectLeague.list then
				self.controls.charSelectLeague.selIndex = 1
			end
			self.lastCharList = charList
			self:BuildCharacterList(self.controls.charSelectLeague:GetSelValue("league"))

			-- We only get here if the accountname was correct, found, and not private, so add it to the account history.
			self:SaveAccountHistory()
		end, sessionID and { header = "Cookie: POESESSID=" .. sessionID })
	end, sessionID and { header = "Cookie: POESESSID=" .. sessionID })
end

function ImportTabClass:BuildCharacterList(league)
	wipeTable(self.controls.charSelect.list)
	for i, char in ipairs(self.lastCharList) do
		if not league or char.league == league then
			t_insert(self.controls.charSelect.list, {
				label = string.format("%s: Level %d %s in %s", char.name or "?", char.level or 0, char.class or "?", char.league or "?"),
				char = char,
			})
		end
	end
	table.sort(self.controls.charSelect.list, function(a,b)
		return a.char.name:lower() < b.char.name:lower()
	end)
	self.controls.charSelect.selIndex = 1
	if self.lastCharacterHash then
		for i, char in ipairs(self.controls.charSelect.list) do
			if common.sha1(char.char.name) == self.lastCharacterHash then
				self.controls.charSelect.selIndex = i
				break
			end
		end
	end
end

function ImportTabClass:SaveAccountHistory()
	if not historyList[self.controls.accountName.buf] then
		t_insert(historyList, self.controls.accountName.buf)
		historyList[self.controls.accountName.buf] = true
		self.controls.accountHistory:SelByValue(self.controls.accountName.buf)
		table.sort(historyList, function(a,b)
			return a:lower() < b:lower()
		end)
		self.controls.accountHistory:CheckDroppedWidth(true)
	end
end

function ImportTabClass:DownloadPassiveTree()
	self.charImportMode = "IMPORTING"
	self.charImportStatus = "Retrieving character passive tree..."
	local realm = realmList[self.controls.accountRealm.selIndex]
	local accountName = self.controls.accountName.buf
	local sessionID = #self.controls.sessionInput.buf == 32 and self.controls.sessionInput.buf or (main.gameAccounts[accountName] and main.gameAccounts[accountName].sessionID)
	local charSelect = self.controls.charSelect
	local charData = charSelect.list[charSelect.selIndex].char
	launch:DownloadPage(realm.hostName.."character-window/get-passive-skills?accountName="..accountName.."&character="..charData.name.."&realm="..realm.realmCode, function(response, errMsg)
		self.charImportMode = "SELECTCHAR"
		if errMsg then
			self.charImportStatus = colorCodes.NEGATIVE.."Error importing character data, try again ("..errMsg:gsub("\n"," ")..")"
			return
		elseif response.body == "false" then
			self.charImportStatus = colorCodes.NEGATIVE.."Failed to retrieve character data, try again."
			return
		end
		self.lastCharacterHash = common.sha1(charData.name)
		self:ImportPassiveTreeAndJewels(response.body, charData)
	end, sessionID and { header = "Cookie: POESESSID=" .. sessionID })
end

function ImportTabClass:DownloadItems()
	self.charImportMode = "IMPORTING"
	self.charImportStatus = "Retrieving character items..."
	local realm = realmList[self.controls.accountRealm.selIndex]
	local accountName = self.controls.accountName.buf
	local sessionID = #self.controls.sessionInput.buf == 32 and self.controls.sessionInput.buf or (main.gameAccounts[accountName] and main.gameAccounts[accountName].sessionID)
	local charSelect = self.controls.charSelect
	local charData = charSelect.list[charSelect.selIndex].char
	launch:DownloadPage(realm.hostName.."character-window/get-items?accountName="..accountName.."&character="..charData.name.."&realm="..realm.realmCode, function(response, errMsg)
		self.charImportMode = "SELECTCHAR"
		if errMsg then
			self.charImportStatus = colorCodes.NEGATIVE.."Error importing character data, try again ("..errMsg:gsub("\n"," ")..")"
			return
		elseif response.body == "false" then
			self.charImportStatus = colorCodes.NEGATIVE.."Failed to retrieve character data, try again."
			return
		end
		self.lastCharacterHash = common.sha1(charData.name)
		self:ImportItemsAndSkills(response.body)
	end, sessionID and { header = "Cookie: POESESSID=" .. sessionID })
end

function ImportTabClass:ImportPassiveTreeAndJewels(json, charData)
	--local out = io.open("get-passive-skills.json", "w")
	--out:write(json)
	--out:close()
	local charPassiveData, errMsg = self:ProcessJSON(json)
	--local out = io.open("get-passive-skills.json", "w")
	--writeLuaTable(out, charPassiveData, 1)
	--out:close()

	-- 3.16+
	if charPassiveData.mastery_effects then
		local mastery, effect = 0, 0
		for key, value in pairs(charPassiveData.mastery_effects) do
			if type(value) ~= "string" then
				break
			end
			mastery = band(tonumber(value), 65535)
			effect = b_rshift(tonumber(value), 16)
			t_insert(charPassiveData.mastery_effects, mastery, effect)
		end
	end

	if charPassiveData.skill_overrides then
		for nodeId, override in pairs(charPassiveData.skill_overrides) do
			self.build.spec:ReplaceNode(override, self.build.spec.tree.tattoo.nodes[override.name])
			override.id = nodeId
		end
	end

	if errMsg then
		self.charImportStatus = colorCodes.NEGATIVE.."Error processing character data, try again later."
		return
	end
	self.charImportStatus = colorCodes.POSITIVE.."Passive tree and jewels successfully imported."
	self.build.spec.jewel_data = copyTable(charPassiveData.jewel_data)
	self.build.spec.extended_hashes = copyTable(charPassiveData.hashes_ex)
	--ConPrintTable(charPassiveData)
	if self.controls.charImportTreeClearJewels.state then
		for _, slot in pairs(self.build.itemsTab.slots) do
			if slot.selItemId ~= 0 and slot.nodeId then
				self.build.itemsTab.build.spec.ignoreAllocatingSubgraph = true -- ignore allocated cluster nodes on Import when Delete Jewel is true, clean slate
				self.build.itemsTab:DeleteItem(self.build.itemsTab.items[slot.selItemId])
			end
		end
	end
	for _, itemData in pairs(charPassiveData.items) do
		self:ImportItem(itemData)
	end
	self.build.itemsTab:PopulateSlots()
	self.build.itemsTab:AddUndoState()

	self.build.spec:ImportFromNodeList(charPassiveData.character, charPassiveData.ascendancy, charPassiveData.alternate_ascendancy or 0, charPassiveData.hashes, charPassiveData.skill_overrides, charPassiveData.mastery_effects or {}, latestTreeVersion .. (charData.league:match("Ruthless") and "_ruthless" or ""))
	self.build.spec:AddUndoState()
	self.build.characterLevel = charData.level
	self.build.characterLevelAutoMode = false
	self.build.configTab:UpdateLevel()
	self.build.controls.characterLevel:SetText(charData.level)
	self.build:EstimatePlayerProgress()
	local resistancePenaltyIndex = 3
	if self.build.Act then -- Estimate resistance penalty setting based on act progression estimate
		if type(self.build.Act) == "string" and self.build.Act == "Endgame" then resistancePenaltyIndex = 3
		elseif type(self.build.Act) == "number" then 
			if self.build.Act < 5 then resistancePenaltyIndex = 1
			elseif self.build.Act > 5 and self.build.Act < 11 then resistancePenaltyIndex = 2
			elseif self.build.Act > 10 then resistancePenaltyIndex = 3 end
		end
	end
	self.build.configTab.varControls["resistancePenalty"]:SetSel(resistancePenaltyIndex)
	self.build.buildFlag = true
	main:SetWindowTitleSubtext(string.format("%s (%s, %s, %s)", self.build.buildName, charData.name, charData.class, charData.league))
end

function ImportTabClass:ImportItemsAndSkills(json)
	--local out = io.open("get-items.json", "w")
	--out:write(json)
	--out:close()
	local charItemData, errMsg = self:ProcessJSON(json)
	if errMsg then
		self.charImportStatus = colorCodes.NEGATIVE.."Error processing character data, try again later."
		return
	end
	if self.controls.charImportItemsClearItems.state then
		for _, slot in pairs(self.build.itemsTab.slots) do
			if slot.selItemId ~= 0 and not slot.nodeId then
				self.build.itemsTab:DeleteItem(self.build.itemsTab.items[slot.selItemId])
			end
		end
	end

	local mainSkillEmpty = #self.build.skillsTab.socketGroupList == 0
	local skillOrder
	if self.controls.charImportItemsClearSkills.state then
		skillOrder = { }
		for _, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			for _, gem in ipairs(socketGroup.gemList) do
				if gem.grantedEffect and not gem.grantedEffect.support then
					t_insert(skillOrder, gem.grantedEffect.name)
				end
			end
		end
		wipeTable(self.build.skillsTab.socketGroupList)
	end
	self.charImportStatus = colorCodes.POSITIVE.."Items and skills successfully imported."
	--ConPrintTable(charItemData)
	for _, itemData in pairs(charItemData.items) do
		self:ImportItem(itemData)
	end
	if skillOrder then
		local groupOrder = { }
		for index, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			groupOrder[socketGroup] = index
		end
		table.sort(self.build.skillsTab.socketGroupList, function(a, b)
			local orderA
			for _, gem in ipairs(a.gemList) do
				if gem.grantedEffect and not gem.grantedEffect.support then
					local i = isValueInArray(skillOrder, gem.grantedEffect.name)
					if i and (not orderA or i < orderA) then
						orderA = i
					end
				end
			end
			local orderB
			for _, gem in ipairs(b.gemList) do
				if gem.grantedEffect and not gem.grantedEffect.support then
					local i = isValueInArray(skillOrder, gem.grantedEffect.name)
					if i and (not orderB or i < orderB) then
						orderB = i
					end
				end
			end
			if orderA and orderB then
				if orderA ~= orderB then
					return orderA < orderB
				else
					return groupOrder[a] < groupOrder[b]
				end
			elseif not orderA and not orderB then
				return groupOrder[a] < groupOrder[b]
			else
				return orderA
			end
		end)
	end
	if mainSkillEmpty then
		self.build.mainSocketGroup = self:GuessMainSocketGroup()
	end
	self.build.itemsTab:PopulateSlots()
	self.build.itemsTab:AddUndoState()
	self.build.skillsTab:AddUndoState()
	self.build.characterLevel = charItemData.character.level
	self.build.configTab:UpdateLevel()
	self.build.controls.characterLevel:SetText(charItemData.character.level)
	self.build.buildFlag = true
	return charItemData.character -- For the wrapper
end

local rarityMap = { [0] = "NORMAL", "MAGIC", "RARE", "UNIQUE", [9] = "RELIC", [10] = "RELIC" }
local slotMap = { ["Weapon"] = "Weapon 1", ["Offhand"] = "Weapon 2", ["Weapon2"] = "Weapon 1 Swap", ["Offhand2"] = "Weapon 2 Swap", ["Helm"] = "Helmet", ["BodyArmour"] = "Body Armour", ["Gloves"] = "Gloves", ["Boots"] = "Boots", ["Amulet"] = "Amulet", ["Ring"] = "Ring 1", ["Ring2"] = "Ring 2", ["Belt"] = "Belt" }

function ImportTabClass:ImportItem(itemData, slotName)
	if not slotName then
		if itemData.inventoryId == "PassiveJewels" then
			slotName = "Jewel "..self.build.latestTree.jewelSlots[itemData.x + 1]
		elseif itemData.inventoryId == "Flask" then
			slotName = "Flask "..(itemData.x + 1)
		elseif not (self.controls.charImportItemsIgnoreWeaponSwap.state and (itemData.inventoryId == "Weapon2" or itemData.inventoryId == "Offhand2")) then
			slotName = slotMap[itemData.inventoryId]
		end
	end
	if not slotName then
		-- Ignore any items that won't go into known slots
		return
	end

	local item = new("Item")

	-- Determine rarity, display name and base type of the item
	item.rarity = rarityMap[itemData.frameType]
	if #itemData.name > 0 then
		item.title = sanitiseText(itemData.name)
		item.baseName = sanitiseText(itemData.typeLine):gsub("Synthesised ","")
		item.name = item.title .. ", " .. item.baseName
		if item.baseName == "Two-Toned Boots" then
			-- Hack for Two-Toned Boots
			item.baseName = "Two-Toned Boots (Armour/Energy Shield)"
		end
		item.base = self.build.data.itemBases[item.baseName]
		if item.base then
			item.type = item.base.type
		else
			ConPrintf("Unrecognised base in imported item: %s", item.baseName)
		end
	else
		item.name = sanitiseText(itemData.typeLine)
		if item.name:match("Energy Blade") then
			local oneHanded = false
			for _, p in ipairs(itemData.properties) do
				if self.build.data.weaponTypeInfo[p.name] and self.build.data.weaponTypeInfo[p.name].oneHand then
					oneHanded = true
					break
				end
			end
			item.name = oneHanded and "Energy Blade One Handed" or "Energy Blade Two Handed"
			item.rarity = "NORMAL"
			itemData.implicitMods = { }
			itemData.explicitMods = { }
		end
		for baseName, baseData in pairs(self.build.data.itemBases) do
			local s, e = item.name:find(baseName, 1, true)
			if s then
				item.baseName = baseName
				item.namePrefix = item.name:sub(1, s - 1)
				item.nameSuffix = item.name:sub(e + 1)
				item.type = baseData.type
				break
			end
		end
		if not item.baseName then
			local s, e = item.name:find("Two-Toned Boots", 1, true)
			if s then
				-- Hack for Two-Toned Boots
				item.baseName = "Two-Toned Boots (Armour/Energy Shield)"
				item.namePrefix = item.name:sub(1, s - 1)
				item.nameSuffix = item.name:sub(e + 1)
				item.type = "Boots"
			end
		end
		item.base = self.build.data.itemBases[item.baseName]
	end
	if not item.base or not item.rarity then
		return
	end

	-- Import item data
	item.uniqueID = itemData.id
	if itemData.influences then
		for _, curInfluenceInfo in ipairs(influenceInfo) do
			item[curInfluenceInfo.key] = itemData.influences[curInfluenceInfo.display:lower()]
		end
	end
	if itemData.ilvl > 0 then
		item.itemLevel = itemData.ilvl
	end
	if item.base.weapon or item.base.armour or item.base.flask then
		item.quality = 0
	end
	if itemData.properties then
		for _, property in pairs(itemData.properties) do
			if property.name == "Quality" then
				item.quality = tonumber(property.values[1][1]:match("%d+"))
			elseif property.name == "Radius" then
				item.jewelRadiusLabel = property.values[1][1]
			elseif property.name == "Limited to" then
				item.limit = tonumber(property.values[1][1])
			elseif property.name == "Evasion Rating" then
				if item.baseName == "Two-Toned Boots (Armour/Energy Shield)" then
					-- Another hack for Two-Toned Boots
					item.baseName = "Two-Toned Boots (Armour/Evasion)"
					item.base = self.build.data.itemBases[item.baseName]
				end
			elseif property.name == "Energy Shield" then
				if item.baseName == "Two-Toned Boots (Armour/Evasion)" then
					-- Yet another hack for Two-Toned Boots
					item.baseName = "Two-Toned Boots (Evasion/Energy Shield)"
					item.base = self.build.data.itemBases[item.baseName]
				end
			end
			if property.name == "Energy Shield" or property.name == "Ward" or property.name == "Armour" or property.name == "Evasion Rating" then
				item.armourData = item.armourData or { }
				for _, value in ipairs(property.values) do
					item.armourData[property.name:gsub(" Rating", ""):gsub(" ", "")] = (item.armourData[property.name:gsub(" Rating", ""):gsub(" ", "")] or 0) + tonumber(value[1])
				end
			end
		end
	end
	item.split = itemData.split
	item.mirrored = itemData.mirrored
	item.corrupted = itemData.corrupted
	item.fractured = itemData.fractured
	item.synthesised = itemData.synthesised
	if itemData.sockets and itemData.sockets[1] then
		item.sockets = { }
		for i, socket in pairs(itemData.sockets) do
			if socket.sColour == "A" then
				item.abyssalSocketCount = item.abyssalSocketCount or 0 + 1
			end
			item.sockets[i] = { group = socket.group, color = socket.sColour }
		end
		if item.abyssalSocketCount and item.abyssalSocketCount > 0 and item.name:match("Energy Blade") then
			t_insert(itemData.explicitMods, "Has " .. item.abyssalSocketCount .. " Abyssal Sockets")
		end
	end
	if itemData.socketedItems then
		self:ImportSocketedItems(item, itemData.socketedItems, slotName)
	end
	if itemData.requirements and (not itemData.socketedItems or not itemData.socketedItems[1]) then
		-- Requirements cannot be trusted if there are socketed gems, as they may override the item's natural requirements
		item.requirements = { }
		for _, req in ipairs(itemData.requirements) do
			if req.name == "Level" then
				item.requirements.level = req.values[1][1]
			elseif req.name == "Class:" then
				item.classRestriction = req.values[1][1]
			end
		end
	end
	item.enchantModLines = { }
	item.scourgeModLines = { }
	item.classRequirementModLines = { }
	item.implicitModLines = { }
	item.explicitModLines = { }
	item.crucibleModLines = { }
	if itemData.enchantMods then
		for _, line in ipairs(itemData.enchantMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.enchantModLines, { line = line, extra = extra, mods = modList or { }, crafted = true })
			end
		end
	end
	if itemData.scourgeMods then
		for _, line in ipairs(itemData.scourgeMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.scourgeModLines, { line = line, extra = extra, mods = modList or { }, scourge = true })
			end
		end
	end
	if itemData.implicitMods then
		for _, line in ipairs(itemData.implicitMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.implicitModLines, { line = line, extra = extra, mods = modList or { } })
			end
		end
	end
	if itemData.fracturedMods then
		for _, line in ipairs(itemData.fracturedMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.explicitModLines, { line = line, extra = extra, mods = modList or { }, fractured = true })
			end
		end
	end
	if itemData.explicitMods then
		for _, line in ipairs(itemData.explicitMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.explicitModLines, { line = line, extra = extra, mods = modList or { } })
			end
		end
	end
	if itemData.crucibleMods then
		for _, line in ipairs(itemData.crucibleMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.crucibleModLines, { line = line, extra = extra, mods = modList or { }, crucible = true })
			end
		end
	end
	if itemData.craftedMods then
		for _, line in ipairs(itemData.craftedMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.explicitModLines, { line = line, extra = extra, mods = modList or { }, crafted = true })
			end
		end
	end
	-- Sometimes flavour text has actual mods that PoB cares about
	-- Right now, the only known one is "This item can be anointed by Cassia"
	if itemData.flavourText then
		for _, line in ipairs(itemData.flavourText) do
			for line in line:gmatch("[^\n]+") do
				-- Remove any text outside of curly braces, if they exist.
				-- This fixes lines such as:
				--   "<default>{This item can be anointed by Cassia}"
				-- To now be:
				--   "This item can be anointed by Cassia"
				local startBracket = line:find("{")
				local endBracket = line:find("}")
				if startBracket and endBracket and endBracket > startBracket then
					line = line:sub(startBracket + 1, endBracket - 1)
				end

				-- If the line parses, then it should be included as an explicit mod
				local modList, extra = modLib.parseMod(line)
				if modList then
					t_insert(item.explicitModLines, { line = line, extra = extra, mods = modList or { } })
				end
			end
		end
	end

	-- Add and equip the new item
	item:BuildAndParseRaw()
	--ConPrintf("%s", item.raw)
	if item.base then
		local repIndex, repItem
		for index, item in pairs(self.build.itemsTab.items) do
			if item.uniqueID == itemData.id then
				repIndex = index
				repItem = item
				break
			end
		end
		if repIndex then
			-- Item already exists in the build, overwrite it
			item.id = repItem.id
			self.build.itemsTab.items[item.id] = item
			item:BuildModList()
		else
			self.build.itemsTab:AddItem(item, true)
		end
		self.build.itemsTab.slots[slotName]:SetSelItemId(item.id)
	end
end

function ImportTabClass:ImportSocketedItems(item, socketedItems, slotName)
	-- Build socket group list
	local itemSocketGroupList = { }
	local abyssalSocketId = 1
	for _, socketedItem in ipairs(socketedItems) do
		if socketedItem.abyssJewel then
			self:ImportItem(socketedItem, slotName .. " Abyssal Socket "..abyssalSocketId)
			abyssalSocketId = abyssalSocketId + 1
		else
			local normalizedBasename, qualityType = self.build.skillsTab:GetBaseNameAndQuality(socketedItem.typeLine, nil)
			local gemId = self.build.data.gemForBaseName[normalizedBasename:lower()]
			if socketedItem.hybrid then
				-- Used by transfigured gems and dual-skill gems (currently just Stormbind) 
				normalizedBasename, qualityType  = self.build.skillsTab:GetBaseNameAndQuality(socketedItem.hybrid.baseTypeName, nil)
				gemId = self.build.data.gemForBaseName[normalizedBasename:lower()]
				if gemId and socketedItem.hybrid.isVaalGem then
					gemId = self.build.data.gemGrantedEffectIdForVaalGemId[self.build.data.gems[gemId].grantedEffectId]
				end
			end
			if gemId then
				local gemInstance = { level = 20, quality = 0, enabled = true, enableGlobal1 = true, gemId = gemId }
				gemInstance.nameSpec = self.build.data.gems[gemId].name
				gemInstance.support = socketedItem.support
				gemInstance.qualityId = qualityType
				for _, property in pairs(socketedItem.properties) do
					if property.name == "Level" then
						gemInstance.level = tonumber(property.values[1][1]:match("%d+"))
					elseif property.name == "Quality" then
						gemInstance.quality = tonumber(property.values[1][1]:match("%d+"))
					end
				end
				local groupID = item.sockets[socketedItem.socket + 1].group
				if not itemSocketGroupList[groupID] then
					itemSocketGroupList[groupID] = { label = "", enabled = true, gemList = { }, slot = slotName }
				end
				local socketGroup = itemSocketGroupList[groupID]
				if not socketedItem.support and socketGroup.gemList[1] and socketGroup.gemList[1].support and item.title ~= "Dialla's Malefaction" then
					-- If the first gemInstance is a support gemInstance, put the first active gemInstance before it
					t_insert(socketGroup.gemList, 1, gemInstance)
				else
					t_insert(socketGroup.gemList, gemInstance)
				end
			end
		end
	end

	-- Import the socket groups
	for _, itemSocketGroup in pairs(itemSocketGroupList) do
		-- Check if this socket group matches an existing one
		local repGroup
		for index, socketGroup in pairs(self.build.skillsTab.socketGroupList) do
			if #socketGroup.gemList == #itemSocketGroup.gemList and (not socketGroup.slot or socketGroup.slot == slotName) then
				local match = true
				for gemIndex, gem in pairs(socketGroup.gemList) do
					if gem.nameSpec:lower() ~= itemSocketGroup.gemList[gemIndex].nameSpec:lower() then
						match = false
						break
					end
				end
				if match then
					repGroup = socketGroup
					break
				end
			end
		end
		if repGroup then
			-- Update the existing one
			for gemIndex, gem in pairs(repGroup.gemList) do
				local itemGem = itemSocketGroup.gemList[gemIndex]
				gem.level = itemGem.level
				gem.quality = itemGem.quality
			end
		else
			t_insert(self.build.skillsTab.socketGroupList, itemSocketGroup)
		end
		self.build.skillsTab:ProcessSocketGroup(itemSocketGroup)
	end
end

-- Return the index of the group with the most gems
function ImportTabClass:GuessMainSocketGroup()
	local largestGroupSize = 0
	local largestGroupIndex = 1
	for i, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
		if #socketGroup.gemList > largestGroupSize then
			largestGroupSize = #socketGroup.gemList
			largestGroupIndex = i
		end
	end
	return largestGroupIndex
end

function HexToChar(x)
	return string.char(tonumber(x, 16))
end

function UrlDecode(url)
	if url == nil then
		return
	end
	url = url:gsub("+", " ")
	url = url:gsub("%%(%x%x)", HexToChar)
	return url
end

function ImportTabClass:ProcessJSON(json)
	local func, errMsg = loadstring("return "..jsonToLua(json))
	if errMsg then
		return nil, errMsg
	end
	setfenv(func, { }) -- Sandbox the function just in case
	local data = func()
	if type(data) ~= "table" then
		return nil, "Return type is not a table"
	end
	return data
end
