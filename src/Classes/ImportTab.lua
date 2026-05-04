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
local m_max = math.max
local dkjson = require "dkjson"



local influenceInfo = itemLib.influenceInfo.all

function addOAuthControls(self)
	self.usingOauth = true
	self.isAuthorized = function() return main.api.authToken ~= nil end
	-- the 30 second timer for oauth
	--- @type integer?
	self.oauthTimer = nil
	-- timestamp for when we can request again after being rate limited
	--- @type integer?
	self.rateLimitEndTime = nil
	--- @type string?
	self.oauthErrCode = nil
	--- @type bool
	self.oauthLoading = false
	-- an array of Character for each realm. Note this is for the character
	-- list, which will mean that equipment and passives are missing
	-- https://www.pathofexile.com/developer/docs/reference#type-Character
	--- @type table<string, table[]>
	self.characterList = {}

	function charImportStatus()
		if not self.isAuthorized() and not self.oauthTimer then
			return colorCodes.WARNING .. "Not authenticated" .. (self.oauthErrCode or "")
		elseif not self.isAuthorized() and self.oauthTimer then
			local timeLeft = m_max(0, (self.oauthTimer + 30) - os.time())
			if timeLeft < 1 then
				self.oauthTimer = nil
				return colorCodes.WARNING .. "Not authenticated" .. (self.oauthErrCode or "")
			end
			return string.format("Logging in... (%d)", timeLeft) .. (self.oauthErrCode or "")
			-- user is spam changing realms and is rate limited
		elseif self.isAuthorized() and self.rateLimitEndTime then
			local timeLeft = m_max(0, self.rateLimitEndTime - os.time())
			if timeLeft < 0.5 then
				self.rateLimitEndTime = nil
				return "Authenticated"
			end
			return colorCodes.WARNING .. string.format("You're doing that too fast. Please wait (%d)", timeLeft)
		elseif self.isAuthorized() and self.oauthLoading then
			return "Fetching..."
		elseif self.isAuthorized() then
			return "Authenticated"
		end
		-- unreachable
		return ""
	end

	-- space after labels
	local labelSpacing = 6
	-- space between rows
	local rowSpacing = 6


	self.controls.charImportStatusLabel = new("LabelControl", { "TOPLEFT", self.controls.sectionOauthCharImport, "TOPLEFT" },
		{ labelSpacing, 14, 200, 16 }, function()
			return "^7Character import status: " .. charImportStatus()
		end)

	self.controls.logoutApiButton = new("ButtonControl", { "TOPLEFT", self.controls.charImportStatusLabel, "TOPRIGHT" },
		{ labelSpacing, 0, 170, 16 }, "^7Logout from Path of Exile API", function()
			main.api:ResetDetails()
			main:SaveSettings()
		end)
	self.controls.logoutApiButton.shown = function() return self.usingOauth and self.isAuthorized() end

	self.controls.characterImportAnchor = new("Control", { "TOPLEFT", self.controls.sectionOauthCharImport, "TOPLEFT" },
		{ labelSpacing, 40, 200, 16 })
	self.controls.sectionOauthCharImport.height = function()
		return self.isAuthorized() and 200 or 60
	end

	-- OAuth Stage: Authenticate
	self.controls.authenticateButton = new("ButtonControl", { "TOPLEFT", self.controls.characterImportAnchor, "TOPLEFT" },
		{ 0, 0, 200, 16 }, "^7Authorize with Path of Exile", function()
			main.api:FetchAuthToken(function(errCode)
				if errCode then
					self.oauthErrCode = errCode
					self.oauthTimer = nil
				else
					self.oauthErrCode = nil
					ConPrintf("%s", main.api.authToken)
					self.oauthTimer = nil
				end
			end)
			self.oauthTimer = os.time()
		end)
	self.controls.authenticateButton.shown = function()
		return self.usingOauth and not self.isAuthorized()
	end

	-- Stage: select realm, league, character, and import data
	self.controls.charSelectHeader = new("LabelControl", { "TOPLEFT", self.controls.sectionOauthCharImport, "TOPLEFT" },
		{ labelSpacing, 40, 200, 16 }, "^7Choose character to import data from:")
	self.controls.charSelectHeader.shown = function()
		return self.usingOauth and self.isAuthorized()
	end

	-- realm select
	function setLeaguesFromCharList()
		local currentRealm = self.controls.accountRealm:GetSelValue().realmCode
		local currentCharacters = currentRealm and self.characterList[currentRealm]
		if not currentCharacters or #currentCharacters == 0 then
			self.controls.charSelectLeague:SetList({})
			self.controls.charSelect:SetList({})
			return
		end
		local set = {}

		for _, character in ipairs(currentCharacters) do
			-- the api reference says league is (somehow) not necessarily present
			if character.league then
				set[character.league] = true
			end
		end
		local ret = {}

		for key, _ in pairs(set) do
			t_insert(ret, key)
		end
		table.sort(ret, function(a, b)
			return a:lower() < b:lower()
		end)
		table.insert(ret, "Any")

		self.controls.charSelectLeague:SetList(ret)
		self.controls.charSelectLeague.selIndex = nil
		if main.lastLeague then
			for i, v in ipairs(self.controls.charSelectLeague.list) do
				if v == main.lastLeague then
					self.controls.charSelectLeague:SetSel(i)
				end
			end
		else
			self.controls.charSelectLeague:SetSel(1)
		end
	end

	function fetchCharacters()
		local realm = self.controls.accountRealm:GetSelValue()
		self.oauthLoading = true
		function onResponse(body, err, timeNext)
			if not err then
				self.characterList[realm.realmCode] = body.characters
				setLeaguesFromCharList()
				self.oauthLoading = false
				return
			elseif err == "Response code: 429" then
				self.rateLimitEndTime = timeNext
			else
				self.oauthErrCode = err
			end
			self.oauthLoading = false
		end
		main.api:DownloadCharacterList(realm.realmCode, onResponse)
	end

	local realmList = {
		{ label = "PC",      id = "PC",   realmCode = "pc"},
		{ label = "Xbox",    id = "XBOX", realmCode = "xbox"},
		{ label = "Sony",     id = "SONY", realmCode = "sony" },
	}
	self.controls.accountRealm = new("DropDownControl", { "TOPLEFT", self.controls.charSelectHeader, "BOTTOMLEFT" },
		{ 0, rowSpacing, 60, 20 }, realmList, function()
			setLeaguesFromCharList()
		end)
	self.controls.accountRealm:SelByValue(main.lastRealm or "PC", "id")
	function fetchTextFunc()
		local realm = self.controls.accountRealm:GetSelValue()
		if realm and self.characterList[realm.realmCode] then
			return "Fetched"
		end
		return "Fetch Characters"
	end
	function fetchButtonEnabled()
		local realm = self.controls.accountRealm:GetSelValue()
		return not (realm and self.characterList[realm.realmCode])
	end
	self.controls.accountRealmFetchButton = new("ButtonControl", { "LEFT", self.controls.accountRealm, "RIGHT" },
		{ labelSpacing, 0, 130, 20 }, fetchTextFunc, fetchCharacters)
	self.controls.accountRealmFetchButton.enabled = fetchButtonEnabled

	-- league select
	--- @param newLeague string
	function onLeagueChange(_, newLeague)
		local realm = self.controls.accountRealm:GetSelValue().realmCode
		if newLeague == "Any" then
			self:BuildCharacterList(realm, nil, self.characterList[realm], self.controls.charSelect)
		else
			self:BuildCharacterList(realm, newLeague, self.characterList[realm], self.controls.charSelect)
		end
	end

	self.controls.charSelectLeagueLabel = new("LabelControl", { "TOPLEFT", self.controls.accountRealm, "BOTTOMLEFT" },
		{ 0, rowSpacing, 0, 14 }, "^7League:")
	self.controls.charSelectLeague = new("DropDownControl", { "LEFT", self.controls.charSelectLeagueLabel, "RIGHT" },
		{ labelSpacing, 0, 150, 18 }, nil, onLeagueChange)
	-- character select
	self.controls.charSelect = new("DropDownControl", { "TOPLEFT", self.controls.charSelectLeagueLabel, "BOTTOMLEFT" },
		{ 0, rowSpacing, 400, 18 }, nil)
	self.controls.charSelect.enabled = function()
		return self.usingOauth and self.isAuthorized()
	end

	-- import action controls
	local function saveDetails(realmId, league, charName)
		main.lastRealm = realmId
		self.lastRealm = realmId
		main.lastLeague = league
		self.lastLeague = league
		main.lastCharacterHash = common.sha1(charName)
		self.lastCharacterHash = common.sha1(charName)
	end
	self.controls.charImportHeader = new("LabelControl", { "TOPLEFT", self.controls.charSelect, "BOTTOMLEFT" },
		{ 0, rowSpacing, 200, 16 }, "^7Import:")
	self.controls.charImportTree = new("ButtonControl", { "LEFT", self.controls.charImportHeader, "RIGHT" },
		{ labelSpacing, 0, 170, 20 }, "Passive Tree and Jewels", function()
			local realm = self.controls.accountRealm:GetSelValue()
			local league = self.controls.charSelectLeague:GetSelValue()
			local selectedName = self.controls.charSelect:GetSelValue().label

			saveDetails(realm.id, league, selectedName)

			if self.build.spec:CountAllocNodes() > 0 then
				main:OpenConfirmPopup("Character Import", "Importing the passive tree will overwrite your current tree.",
					"Import", function()
						main.api:DownloadCharacter(realm.realmCode, selectedName, function(char)
							self:ImportPassiveTreeAndJewels(char.character)
						end)
					end)
			else
				main.api:DownloadCharacter(realm.realmCode, selectedName, function(char)
					self:ImportPassiveTreeAndJewels(char.character)
				end)
			end
		end)
	self.controls.charImportTree.enabled = function()
		return self.usingOauth and self.isAuthorized() and self.controls.charSelect:GetSelValue()
	end
	self.controls.charImportTreeClearJewels = new("CheckBoxControl", { "LEFT", self.controls.charImportTree, "RIGHT" },
		{ 90, 0, 18 }, "Delete jewels:", nil, "Delete all existing jewels when importing.", true)
	self.controls.charImportItems = new("ButtonControl", { "TOPLEFT", self.controls.charImportTree, "BOTTOMLEFT" },
		{ 0, rowSpacing, 110, 20 }, "Items and Skills", function()
			local realm = self.controls.accountRealm:GetSelValue()
			local league = self.controls.charSelectLeague:GetSelValue()
			local selectedName = self.controls.charSelect:GetSelValue().label

			saveDetails(realm.id, league, selectedName)

			main.api:DownloadCharacter(realm.realmCode, selectedName, function(char)
				self:ImportItemsAndSkills(char.character)
			end)
		end)
	self.controls.charImportItems.enabled = function()
		return self.usingOauth and self.isAuthorized() and self.controls.charSelect:GetSelValue()
	end
	self.controls.charImportItemsClearSkills = new("CheckBoxControl", { "LEFT", self.controls.charImportItems, "RIGHT" },
		{ 85, 0, 18 }, "Delete skills:", nil, "Delete all existing skills when importing.", true)
	self.controls.charImportItemsClearItems = new("CheckBoxControl", { "LEFT", self.controls.charImportItems, "RIGHT" },
		{ 220, 0, 18 }, "Delete equipment:", nil, "Delete all equipped items when importing.", true)
	self.controls.charImportItemsIgnoreWeaponSwap = new("CheckBoxControl", { "LEFT", self.controls.charImportItems,
		"RIGHT" }, { 380, 0, 18 }, "Ignore weapon swap:", nil, "Ignore items and skills in weapon swap.", false)
end
function addAccountNameControls(self)
	self.charImportMode = "GETACCOUNTNAME"
	self.charImportStatus = "Idle"
	self.controls.siteCharImportStatusLabel = new("LabelControl", { "TOPLEFT", self.controls.sectionCharSiteImport, "TOPLEFT" },
		{ 6, 14, 200, 16 }, function()
		return "^7Character import status: " .. self.charImportStatus
	end)

	-- Stage: input account name
	self.controls.siteAccountNameHeader = new("LabelControl", { "TOPLEFT", self.controls.sectionCharSiteImport, "TOPLEFT" },
		{ 6, 40, 250, 16 }, "^7To start importing a character, enter the character's account name:")
	self.controls.siteAccountNameHeader.shown = function()
		return self.charImportMode == "GETACCOUNTNAME"
	end
	local realmList = {
		{ label = "PC",      id = "PC",   realmCode = "pc",   hostName = "https://www.pathofexile.com/", profileURL = "account/view-profile/" },
		{ label = "Xbox",    id = "XBOX", realmCode = "xbox", hostName = "https://www.pathofexile.com/", profileURL = "account/view-profile/" },
		{ label = "Sony",     id = "SONY", realmCode = "sony", hostName = "https://www.pathofexile.com/", profileURL = "account/view-profile/" },
		{ label = "Hotcool", id = "PC",   realmCode = "pc",   hostName = "https://pathofexile.tw/",      profileURL = "account/view-profile/" },
		{ label = "Tencent", id = "PC",   realmCode = "pc",   hostName = "https://poe.game.qq.com/",     profileURL = "account/view-profile/" },
	}
	self.controls.siteAccountRealm = new("DropDownControl",
		{ "TOPLEFT", self.controls.siteAccountNameHeader, "BOTTOMLEFT" },
		{ 0, 4, 60, 20 }, realmList)
	self.controls.siteAccountRealm:SelByValue(main.lastRealm or "PC", "id")
	self.controls.siteAccountName = new("EditControl", { "LEFT", self.controls.siteAccountRealm, "RIGHT" }, { 8, 0, 200, 20 },
		main.lastAccountName or "", nil, "%c", nil, nil, nil, nil, true)
	self.controls.siteAccountName.pasteFilter = function(text)
		return text:gsub(".", function(c)
			local byte = c:byte()
			if byte >= 128 then
				return string.format("%%%02X", byte)
			else
				return c
			end
		end)
	end
	-- accountHistory Control
	if not historyList then
		historyList = {}
		for accountName, account in pairs(main.gameAccounts) do
			t_insert(historyList, accountName)
			historyList[accountName] = true
		end
		table.sort(historyList, function(a, b)
			return a:lower() < b:lower()
		end)
	end -- don't load the list many times
	self.controls.siteAccountNameGo = new("ButtonControl", { "LEFT", self.controls.siteAccountName, "RIGHT" }, { 8, 0, 60, 20 },
		"Start", function()
		self:DownloadSiteCharacterList()
	end)
	self.controls.siteAccountNameGo.enabled = function()
		return self.controls.siteAccountName.buf:match("%S[#%-]%d%d%d%d$")
	end
	self.controls.siteAccountNameGo.tooltipFunc = function(tooltip)
		tooltip:Clear()
		if not self.controls.siteAccountName.buf:match("[#%-]%d%d%d%d$") and self.controls.siteAccountName.buf ~= "" then
			tooltip:AddLine(16, "^7Missing discriminator e.g. " .. self.controls.siteAccountName.buf .. "#1234")
		end
	end

	self.controls.siteAccountHistory = new("DropDownControl", { "LEFT", self.controls.siteAccountNameGo, "RIGHT" },
		{ 8, 0, 200, 20 }, historyList, function()
		self.controls.siteAccountName.buf = self.controls.siteAccountHistory.list[self.controls.siteAccountHistory.selIndex]
	end)
	self.controls.siteAccountHistory:SelByValue(main.lastAccountName)
	self.controls.siteAccountHistory:CheckDroppedWidth(true)

	self.controls.siteRemoveAccount = new("ButtonControl", { "LEFT", self.controls.siteAccountHistory, "RIGHT" }, { 8, 0, 20, 20 },
		"X", function()
		local accountName = self.controls.siteAccountHistory.list[self.controls.siteAccountHistory.selIndex]
		if (accountName ~= nil) then
			t_remove(self.controls.siteAccountHistory.list, self.controls.siteAccountHistory.selIndex)
			self.controls.siteAccountHistory.list[accountName] = nil
			main.gameAccounts[accountName] = nil
		end
	end)

	self.controls.siteRemoveAccount.tooltipFunc = function(tooltip)
		tooltip:Clear()
		tooltip:AddLine(16, "^7Removes account from the dropdown list")
	end

	self.controls.siteAccountNameMissingDiscriminator = new("LabelControl",
		{ "TOPLEFT", self.controls.siteAccountName, "BOTTOMLEFT" }, { 0, 8, 0, 16 }, "^1Missing discriminator e.g. #1234")
	self.controls.siteAccountNameMissingDiscriminator.shown = function()
		return not self.controls.siteAccountName.buf:match("[#%-]%d%d%d%d$") and self.controls.siteAccountName.buf ~= ""
	end

	self.controls.siteAccountNameUnicode = new("LabelControl", { "TOPLEFT", self.controls.siteAccountRealm, "BOTTOMLEFT" },
		{ 0, 34, 0, 14 },
		"^7Note: if the account name contains non-ASCII characters it must be pasted into the textbox,\nnot typed manually.")

	-- Stage: select character and import data
	self.controls.siteCharSelectHeader = new("LabelControl", { "TOPLEFT", self.controls.sectionCharSiteImport, "TOPLEFT" },
		{ 6, 40, 200, 16 }, "^7Choose character to import data from:")
	self.controls.siteCharSelectHeader.shown = function()
		return self.charImportMode == "SELECTCHAR" or self.charImportMode == "IMPORTING"
	end
	self.controls.siteCharSelectLeagueLabel = new("LabelControl", { "TOPLEFT", self.controls.siteCharSelectHeader, "BOTTOMLEFT" },
		{ 0, 6, 0, 14 }, "^7League:")
	self.controls.siteCharSelectLeague = new("DropDownControl", { "LEFT", self.controls.siteCharSelectLeagueLabel, "RIGHT" },
		{ 4, 0, 150, 18 }, nil, function(index, value)
			self:BuildCharacterList("pc", value.league, self.lastCharList, self.controls.siteCharSelect)
		end)
	self.controls.siteCharSelect = new("DropDownControl", { "TOPLEFT", self.controls.siteCharSelectHeader, "BOTTOMLEFT" },
		{ 0, 24, 400, 18 })
	self.controls.siteCharSelect.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.siteCharImportHeader = new("LabelControl", { "TOPLEFT", self.controls.siteCharSelect, "BOTTOMLEFT" },
		{ 0, 16, 200, 16 }, "^7Import:")
	self.controls.siteCharImportTree = new("ButtonControl", { "LEFT", self.controls.siteCharImportHeader, "RIGHT" },
		{ 8, 0, 170, 20 }, "Passive Tree and Jewels", function()
		if self.build.spec:CountAllocNodes() > 0 then
			main:OpenConfirmPopup("Character Import", "Importing the passive tree will overwrite your current tree.",
				"Import", function()
				self:DownloadPassiveTree()
			end)
		else
			self:DownloadPassiveTree()
		end
		self:SetPredefinedBuildName()
	end)
	self.controls.siteCharImportTree.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.siteCharImportTreeClearJewels = new("CheckBoxControl", { "LEFT", self.controls.siteCharImportTree, "RIGHT" },
		{ 90, 0, 18 }, "Delete jewels:", nil, "Delete all existing jewels when importing.", true)
	self.controls.siteCharImportItems = new("ButtonControl", { "LEFT", self.controls.siteCharImportTree, "LEFT" },
		{ 0, 36, 110, 20 }, "Items and Skills", function()
		self:DownloadItems()
		self:SetPredefinedBuildName()
	end)
	self.controls.siteCharImportItems.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.siteCharImportItemsClearSkills = new("CheckBoxControl", { "LEFT", self.controls.siteCharImportItems, "RIGHT" },
		{ 85, 0, 18 }, "Delete skills:", nil, "Delete all existing skills when importing.", true)
	self.controls.siteCharImportItemsClearItems = new("CheckBoxControl", { "LEFT", self.controls.siteCharImportItems, "RIGHT" },
		{ 220, 0, 18 }, "Delete equipment:", nil, "Delete all equipped items when importing.", true)
	self.controls.siteCharImportItemsIgnoreWeaponSwap = new("CheckBoxControl", { "LEFT", self.controls.siteCharImportItems,
		"RIGHT" }, { 380, 0, 18 }, "Ignore weapon swap:", nil, "Ignore items and skills in weapon swap.", false)
	self.controls.siteCharBanditNote = new("LabelControl", { "TOPLEFT", self.controls.siteCharImportHeader, "BOTTOMLEFT" },
		{ 0, 50, 200, 14 },
		"^7Tip: After you finish importing a character, make sure you update the bandit choice,\nas it can only be imported by logging in above.")

	self.controls.siteCharClose = new("ButtonControl", { "TOPLEFT", self.controls.siteCharImportHeader, "BOTTOMLEFT" },
		{ 0, 90, 60, 20 }, "Close", function()
		self.charImportMode = "GETACCOUNTNAME"
		self.charImportStatus = "Idle"
	end)
end

local ImportTabClass = newClass("ImportTab", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

	self.build = build

	if not main.api then
		main.api = new("PoEAPI", main.lastToken, main.lastRefreshToken, main.tokenExpiry)
	end


	self.controls.sectionOauthCharImport = new("SectionControl", { "TOPLEFT", self, "TOPLEFT" }, { 10, 18, 650, 200 },
		"Import From Your Account")

	addOAuthControls(self)

	self.controls.sectionCharSiteImport = new("SectionControl",
		{ "TOPLEFT", self.controls.sectionOauthCharImport, "BOTTOMLEFT" },
		{ 0, 18, 650, 250 },
		"Import By Account Name")
	addAccountNameControls(self)


	-- Build import/export
	self.controls.sectionBuild = new("SectionControl",
		{ "TOPLEFT", self.controls.sectionCharSiteImport, "BOTTOMLEFT", true },
		{ 0, 18, 650, 182 }, "Build Sharing")
	self.controls.generateCodeLabel = new("LabelControl", { "TOPLEFT", self.controls.sectionBuild, "TOPLEFT" },
		{ 6, 14, 0, 16 }, "^7Generate a code to share this build with other Path of Building users:")
	self.controls.generateCode = new("ButtonControl", {"LEFT",self.controls.generateCodeLabel,"RIGHT"}, {4, 0, 80, 20}, "Generate", function()
		self.controls.generateCodeOut:SetText(common.base64.encode(Deflate(self.build:SaveDB("code"))):gsub("+","-"):gsub("/","_"))
	end)
	self.controls.enablePartyExportBuffs = new("CheckBoxControl", {"LEFT",self.controls.generateCode,"RIGHT"}, {100, 0, 18}, "Export Support", function(state)
		self.build.partyTab.enableExportBuffs = state
		self.build.buildFlag = true 
	end, "This is for party play, to export support character, it enables the exporting of auras, curses and modifiers to the enemy", false)
	self.controls.generateCodeOut = new("EditControl", {"TOPLEFT",self.controls.generateCodeLabel,"BOTTOMLEFT"}, {0, 8, 250, 20}, "", "Code", "%Z")
	self.controls.generateCodeOut.enabled = function()
		return #self.controls.generateCodeOut.buf > 0
	end
	self.controls.generateCodeCopy = new("ButtonControl", {"LEFT",self.controls.generateCodeOut,"RIGHT"}, {8, 0, 60, 20}, "Copy", function()
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

	self.controls.exportFrom = new("DropDownControl", { "LEFT", self.controls.generateCodeCopy,"RIGHT"}, {8, 0, 120, 20}, exportWebsitesList, function(_, selectedWebsite)
		main.lastExportWebsite = selectedWebsite.id
		self.exportWebsiteSelected = selectedWebsite.id
	end)
	self.controls.exportFrom:SelByValue(self.exportWebsiteSelected or main.lastExportWebsite or "Pastebin", "id")
	self.controls.generateCodeByLink = new("ButtonControl", { "LEFT", self.controls.exportFrom, "RIGHT"}, {8, 0, 100, 20}, "Share", function()
		local exportWebsite = exportWebsitesList[self.controls.exportFrom.selIndex]
		local subScriptId = buildSites.UploadBuild(self.controls.generateCodeOut.buf, exportWebsite)
		if subScriptId then
			self.controls.generateCodeOut:SetText("")
			self.controls.generateCodeByLink.label = "Creating link..."
			launch:RegisterSubScript(subScriptId, function(pasteLink, errMsg)
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
	self.controls.generateCodeNote = new("LabelControl", {"TOPLEFT",self.controls.generateCodeOut,"BOTTOMLEFT"}, {0, 4, 0, 14}, "^7Note: this code can be very long; you can use 'Share' to shrink it.")
	self.controls.importCodeHeader = new("LabelControl", {"TOPLEFT",self.controls.generateCodeNote,"BOTTOMLEFT"}, {0, 26, 0, 16}, "^7To import a build, enter URL or code here:")

	local importCodeHandle = function (buf)
		self.importCodeSite = nil
		self.importCodeDetail = ""
		self.importCodeXML = nil
		self.importCodeValid = false
		self.importCodeJson = nil

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

		-- If we are in dev mode and the string is a json
		if launch.devMode and urlText:match("^%{.*%}$") ~= nil then
			local jsonData, _, errDecode = dkjson.decode(urlText)
			if errDecode then
				self.importCodeDetail = colorCodes.NEGATIVE.."Invalid JSON format (decode error)"
				return
			end
			if not jsonData.character then
				self.importCodeDetail = colorCodes.NEGATIVE.."Invalid JSON format (character missing)"
				return
			end
			jsonData = jsonData.character
			if not jsonData.equipment or not jsonData.passives then
				self.importCodeDetail = colorCodes.NEGATIVE.."Invalid JSON format (equipment or passives missing)"
				return
			end
			self.importCodeJson = jsonData
			self.importCodeDetail = colorCodes.POSITIVE.."JSON is valid"
			self.importCodeValid = true
			return
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
				self.build:Init(self.build.dbFileName, self.build.buildName, self.importCodeXML, false, self.importCodeSite and self.controls.importCodeIn.buf or nil)
				self.build.viewMode = "TREE"
			end)
		elseif self.controls.importCodeMode.selIndex == 3 then
			-- Import as comparison build
			if self.build.compareTab then
				if self.build.compareTab:ImportBuild(self.importCodeXML, "Imported comparison") then
					self.build.viewMode = "COMPARE"
				else
					main:OpenMessagePopup("Import Error", "Failed to import build for comparison.")
				end
			end
		else
			self.build:Shutdown()
			self.build:Init(false, "Imported build", self.importCodeXML, false, self.importCodeSite and self.controls.importCodeIn.buf or nil)
			self.build.viewMode = "TREE"
		end
	end

	self.controls.importCodeIn = new("EditControl", {"TOPLEFT",self.controls.importCodeHeader,"BOTTOMLEFT"}, {0, 4, 328, 20}, "", nil, nil, nil, importCodeHandle, nil, nil, true)
	self.controls.importCodeIn.enterFunc = function()
		if self.importCodeValid then
			self.controls.importCodeGo.onClick()
		end
	end
	self.controls.importCodeState = new("LabelControl", {"LEFT",self.controls.importCodeIn,"RIGHT"}, {8, 0, 0, 16})
	self.controls.importCodeState.label = function()
		return self.importCodeDetail or ""
	end
	self.controls.importCodeMode = new("DropDownControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, {0, 4, 200, 20}, { "Import to this build", "Import to a new build", "Import as comparison" })
	self.controls.importCodeMode.enabled = function()
		return (self.build.dbFileName or self.controls.importCodeMode.selIndex == 3) and self.importCodeValid
	end
	self.controls.importCodeGo = new("ButtonControl", {"LEFT",self.controls.importCodeMode,"RIGHT"}, {8, 0, 160, 20}, "Import", function()
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

		if self.importCodeJson then
			self:ImportItemsAndSkills(self.importCodeJson)
			self:ImportPassiveTreeAndJewels(self.importCodeJson)
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

	-- -- validate the status of the api the first time
	main.api:ValidateAuth(function() end)
end)

function ImportTabClass:Load(xml, fileName)
	self.lastRealm = xml.attrib.lastRealm
	self.lastLeague = xml.attrib.lastLeague
	self.lastAccountHash = xml.attrib.lastAccountHash
	self.importLink = xml.attrib.importLink
	self.controls.enablePartyExportBuffs.state = xml.attrib.exportParty == "true"
	self.build.partyTab.enableExportBuffs = self.controls.enablePartyExportBuffs.state
	if self.lastAccountHash and false then
		for accountName in pairs(main.gameAccounts) do
			if common.sha1(accountName) == self.lastAccountHash then
				self.controls.siteAccountName:SetText(accountName)
			end
		end
	end
	self.lastCharacterHash = xml.attrib.lastCharacterHash
end

function ImportTabClass:Save(xml)
	xml.attrib = {
		lastRealm = self.lastRealm,
		lastLeague = self.lastLeague,
		lastAccountHash = self.lastAccountHash,
		lastCharacterHash = self.lastCharacterHash,
		exportParty = tostring(self.controls.enablePartyExportBuffs.state),
		importLink = self.importLink
	}

	if self.build.importLink then
		xml.attrib.importLink = self.build.importLink
	end
	-- Gets rid of erroneous, potentially infinitely nested full base64 XML stored as an import link
	xml.attrib.importLink = (xml.attrib.importLink and xml.attrib.importLink:len() < 100) and xml.attrib.importLink or nil 
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

function ImportTabClass:ProcessSiteJSON(json)
	local func, errMsg = loadstring("return " .. jsonToLua(json))
	if errMsg then
		return nil, errMsg
	end
	setfenv(func, {}) -- Sandbox the function just in case
	local data = func()
	if type(data) ~= "table" then
		return nil, "Return type is not a table"
	end
	return data
end

function ImportTabClass:SaveAccountHistory()
	if not historyList[self.controls.siteAccountName.buf] then
		t_insert(historyList, self.controls.siteAccountName.buf)
		historyList[self.controls.siteAccountName.buf] = true
		table.sort(historyList, function(a, b)
			return a:lower() < b:lower()
		end)
		self.controls.accountHistory:CheckDroppedWidth(true)
		self.controls.accountHistory:SelByValue(self.controls.siteAccountName.buf)
	end
end

function ImportTabClass:DownloadPassiveTree()
	self.charImportMode = "IMPORTING"
	self.charImportStatus = "Retrieving character passive tree..."
	local realm = realmList[self.controls.siteAccountRealm.selIndex]
	local accountName = self.controls.siteAccountName.buf
	local charSelect = self.controls.siteCharSelect
	local charListData = charSelect.list[charSelect.selIndex].char
	launch:DownloadPage(
	realm.hostName ..
	"character-window/get-passive-skills?accountName=" ..
	accountName:gsub("#", "%%23") .. "&character=" .. urlEncode(charListData.name) .. "&realm=" .. realm.realmCode,
		function(response, errMsg)
			self.charImportMode = "SELECTCHAR"
			if errMsg then
				self.charImportStatus = colorCodes.NEGATIVE ..
				"Error importing character data, try again (" .. errMsg:gsub("\n", " ") .. ")"
				return
			elseif response.body == "false" then
				self.charImportStatus = colorCodes.NEGATIVE .. "Failed to retrieve character data, try again."
				return
			end
			self.lastCharacterHash = common.sha1(charListData.name)
			if not self.lastLeague then
				self.lastLeague = charSelectLeague:GetSelValueByKey("league")
			end
			local responseLua = dkjson.decode(response.body)
			-- modify response to be like the oauth API response
			local charData = copyTable(charListData)
			charData.passives = responseLua
			charData.jewels = responseLua.items
			self:ImportPassiveTreeAndJewels(charData)
		end)
end

function ImportTabClass:DownloadItems()
	self.charImportMode = "IMPORTING"
	self.charImportStatus = "Retrieving character items..."
	local realm = realmList[self.controls.siteAccountRealm.selIndex]
	local accountName = self.controls.siteAccountName.buf
	local charSelect = self.controls.siteCharSelect
	local charListData = charSelect.list[charSelect.selIndex].char
	launch:DownloadPage(
	realm.hostName ..
	"character-window/get-items?accountName=" ..
		accountName:gsub("#", "%%23") .. "&character=" .. urlEncode(charListData.name) .. "&realm=" .. realm.realmCode,
		function(response, errMsg)
			self.charImportMode = "SELECTCHAR"
			if errMsg then
				self.charImportStatus = colorCodes.NEGATIVE ..
				"Error importing character data, try again (" .. errMsg:gsub("\n", " ") .. ")"
				return
			elseif response.body == "false" then
				self.charImportStatus = colorCodes.NEGATIVE .. "Failed to retrieve character data, try again."
				return
			end
			self.lastCharacterHash = common.sha1(charListData.name)
			if not self.lastLeague then
				self.lastLeague = charSelectLeague:GetSelValueByKey("league")
			end
			local responseLua = dkjson.decode(response.body)
			-- modify response to be like the oauth API response
			local charData = copyTable(charListData)
			charData.equipment = responseLua.items
			self:ImportItemsAndSkills(charData)
		end)
end
function ImportTabClass:DownloadSiteCharacterList()
	function FindMatchingStandardLeague(league)
		-- Find a Standard league name for a given league name
		-- Reference https://api.pathofexile.com/league?realm=pc
		if string.find(league, "Hardcore") then
			return "Hardcore"
		elseif string.find(league, "HC SSF") then
			-- includes Ruthless "HC SSF R "
			return "SSF Hardcore"
		elseif string.find(league, "SSF") then
			-- Any non HardCore SSF's - includes Ruthless "SSF R "
			return "SSF Standard"
		else
			-- normal league and ruthless league (Sanctum, Ruthless Sanctum)
			return "Standard"
		end
	end

	self.charImportMode = "DOWNLOADCHARLIST"
	self.charImportStatus = "Retrieving character list..."
	local realm = realmList[self.controls.siteAccountRealm.selIndex]
	local accountName
	-- Handle spaces in the account name
	if realm.realmCode == "pc" then
		accountName = self.controls.siteAccountName.buf:gsub("%s+", "")
	else
		accountName = self.controls.siteAccountName.buf:gsub("^[%s?]+", ""):gsub("[%s?]+$", ""):gsub("%s", "+")
	end
	accountName = accountName:gsub("(.*)[#%-]", "%1#")
	launch:DownloadPage(
	realm.hostName ..
	"character-window/get-characters?accountName=" .. accountName:gsub("#", "%%23") .. "&realm=" .. realm.realmCode,
		function(response, errMsg)
			if errMsg == "Response code: 401" or errMsg == "Response code: 403" then
				self.charImportStatus = colorCodes.NEGATIVE .. "Account profile is private or does not exist."
				self.charImportMode = "GETACCOUNTNAME"
				return
			elseif errMsg == "Response code: 404" then
				self.charImportStatus = colorCodes.NEGATIVE .. "Account name is incorrect."
				self.charImportMode = "GETACCOUNTNAME"
				return
			elseif errMsg then
				self.charImportStatus = colorCodes.NEGATIVE ..
				"Error retrieving character list, try again (" .. errMsg:gsub("\n", " ") .. ")"
				self.charImportMode = "GETACCOUNTNAME"
				return
			end
			local charList, errMsg = self:ProcessSiteJSON(response.body)
			if errMsg then
				self.charImportStatus = colorCodes.NEGATIVE .. "Error processing character list, try again later"
				self.charImportMode = "GETACCOUNTNAME"
				return
			end
			--ConPrintTable(charList)
			if #charList == 0 then
				self.charImportStatus = colorCodes.NEGATIVE .. "The account has no characters to import."
				self.charImportMode = "GETACCOUNTNAME"
				return
			end
			-- GGG's character API has an issue where for /get-characters the account name is not case-sensitive, but for /get-passive-skills and /get-items it is.
			-- This workaround grabs the profile page and extracts the correct account name from one of the URLs.
			launch:DownloadPage(realm.hostName .. realm.profileURL .. accountName:gsub("#", "%%23"),
				function(response, errMsg)
					if errMsg then
						self.charImportStatus = colorCodes.NEGATIVE ..
						"Error retrieving character list, try again (" .. errMsg:gsub("\n", " ") .. ")"
						self.charImportMode = "GETACCOUNTNAME"
						return
					end
					local realAccountName = response.body:match("/view%-profile/([^/]+)/characters"):gsub(".",
						function(c) if c:byte(1) > 127 then return string.format("%%%2X", c:byte(1)) else return c end end)
					if not realAccountName then
						self.charImportStatus = colorCodes.NEGATIVE .. "Failed to retrieve character list."
						self.charImportMode = "GETACCOUNTNAME"
						return
					end
					realAccountName = realAccountName:gsub("(.*)[#%-]", "%1#")
					accountName = realAccountName
					self.controls.siteAccountName:SetText(realAccountName)
					self.charImportStatus = "Character list successfully retrieved."
					self.charImportMode = "SELECTCHAR"
					self.lastRealm = realm.id
					main.lastRealm = realm.id
					self.lastAccountHash = common.sha1(accountName)
					main.lastAccountName = accountName
					main.gameAccounts[accountName] = main.gameAccounts[accountName] or {}
					main.gameAccounts[accountName].sessionID = sessionID
					local leagueList = {}
					for i, char in ipairs(charList) do
						if not isValueInArray(leagueList, char.league) then
							t_insert(leagueList, char.league)
						end
					end
					table.sort(leagueList)
					charSelectLeague = self.controls.siteCharSelectLeague
					wipeTable(self.controls.siteCharSelectLeague.list)
					for _, league in ipairs(leagueList) do
						t_insert(self.controls.siteCharSelectLeague.list, {
							label = league,
							league = league,
						})
					end
					t_insert(self.controls.siteCharSelectLeague.list, {
						label = "All",
					})
					-- set the league combo to the last used if possible, used for previously imported characters
					if self.lastLeague then
						charSelectLeague:SelByValue(self.lastLeague, "league")
						-- check that it worked
						if charSelectLeague:GetSelValueByKey("league") ~= self.lastLeague then
							-- League maybe over, Character will be in standard
							standardLeagueName = FindMatchingStandardLeague(self.lastLeague)
							self.controls.siteCharSelectLeague:SelByValue(standardLeagueName, "league")
							if charSelectLeague:GetSelValueByKey("league") ~= standardLeagueName then
								-- give up and select the first entry. Ruthless mode may not have Standard equivalents
								charSelectLeague.selIndex = 1
							else
								self.lastLeague = standardLeagueName
							end
						end
					else
						if self.controls.siteCharSelectLeague.selIndex > #self.controls.siteCharSelectLeague.list then
							self.controls.siteCharSelectLeague.selIndex = 1
						end
					end
					self.lastCharList = charList
					self:BuildCharacterList("pc", self.controls.siteCharSelectLeague:GetSelValueByKey("league"), self.lastCharList, self.controls.siteCharSelect)

					-- We only get here if the accountname was correct, found, and not private, so add it to the account history.
					self:SaveAccountHistory()
				end)
		end)
end

--- @param realm string
--- @param league string
--- @param characters table?
--- @param control table
function ImportTabClass:BuildCharacterList(realm, league, characters, control)
	wipeTable(control.list)
	if not characters then
		return
	end
	for i, char in ipairs(characters) do
		if realm == char.realm and (not league) or char.league == league then
			charLvl = char.level or 0
			charLeague = char.league or "?"
			charName = char.name or "?"
			charClass = char.class or "?"

			classColor = colorCodes.DEFAULT
			if charClass ~= "?" then
				local tree = main:LoadTree(latestTreeVersion .. (char.league:match("Ruthless") and "_ruthless" or ""))
				classColor = colorCodes[charClass:upper()] or colorCodes[tree.ascendNameMap[charClass].class.name:upper()] or "^7"
			end

			local detail
			if league == nil then
				detail = string.format("%s%s ^x808080lvl %d in %s", classColor, charClass, charLvl, charLeague)
			else
				detail = string.format("%s%s ^x808080lvl %d", classColor, charClass, charLvl)
			end
			t_insert(control.list, {
				label = charName,
				char = char,
				searchFilter = charName.." "..charClass,
				detail = detail
			})
		end
	end
	table.sort(control.list, function(a,b)
		return a.char.name:lower() < b.char.name:lower()
	end)
	control.selIndex = 1
	if self.lastCharacterHash then
		for i, char in ipairs(control.list) do
			if common.sha1(char.char.name) == self.lastCharacterHash then
				control.selIndex = i
				break
			end
		end
	end
end
-- https://www.pathofexile.com/developer/docs/reference#type-Character
--- @class CharacterBasicData
--- @field id string? not present on website
--- @field name string
--- @field realm "pc" | "xbox" | "sony"
--- @field class string
--- @field league string
--- @field level integer
--- @field experience integer
---
--- @alias Bandits "Kraityn" | "Alira" | "Oak" | "Eramir"
--- @alias MajorPantheon "TheBrineKing" | " Arakaali" | " Solaris" | "Lunaris"
--- @alias MinorPantheon "Abberath" | " Gruthkul" | " Yugul" | " Shakari" | " Tukohama" | " Ralakesh" | " Garukhan" | "Ryslatha"


--- @class CharacterPassives
--- @field mastery_effects table<string, int>
--- @field skill_overrides table<string, table>
--- @field jewel_data table<string, table>
--- @field hashes_ex integer[]
--- @field hashes integer[]
--- @field bandit_choice Bandits?
--- @field pantheon_major MajorPantheon?
--- @field pantheon_minor MinorPantheon?
--- @field alternate_ascendancy string | integer integer on website, string on oauth

-- https://www.pathofexile.com/developer/docs/reference#type-Item
--- @alias Item any

--- @class CharacterPassivesData : CharacterBasicData
--- @field jewels Item[]
--- @field passives CharacterPassives
--- @param charData CharacterPassivesData
--- @return string
function ImportTabClass:ImportPassiveTreeAndJewels(charData)
	local charPassives = charData.passives
	-- 3.16+
	local mastery, effect = 0, 0
	for key, value in pairs(charPassives.mastery_effects) do
		if type(value) ~= "string" then
			break
		end
		mastery = band(tonumber(value), 65535)
		effect = b_rshift(tonumber(value), 16)
		t_insert(charPassives.mastery_effects, mastery, effect)
	end

	for nodeId, override in pairs(charData.passives.skill_overrides) do
		self.build.spec:ReplaceNode(override, self.build.spec.tree.tattoo.nodes[override.name])
		override.id = nodeId
	end

	if errMsg then
		return colorCodes.NEGATIVE.."Error processing character data, try again later."
	end
	self.build.spec.jewel_data = copyTable(charPassives.jewel_data)
	self.build.spec.extended_hashes = copyTable(charPassives.hashes_ex)
	if self.controls.charImportTreeClearJewels.state then
		for _, slot in pairs(self.build.itemsTab.slots) do
			if slot.selItemId ~= 0 and slot.nodeId then
				self.build.itemsTab.build.spec.ignoreAllocatingSubgraph = true -- ignore allocated cluster nodes on Import when Delete Jewel is true, clean slate
				self.build.itemsTab:DeleteItem(self.build.itemsTab.items[slot.selItemId])
			end
		end
	end
	for _, itemData in ipairs(charData.jewels) do
		self:ImportItem(itemData)
	end
	self.build.itemsTab:PopulateSlots()
	self.build.itemsTab:AddUndoState()


	local alternateAscendancyId
	if charPassives.alternate_ascendancy then
		-- oauth responses have bloodline names
		if type(charPassives.alternate_ascendancy) == "string" then
			local bloodline = self.build.latestTree.secondaryAscendNameMap[charPassives.alternate_ascendancy]
			alternateAscendancyId = bloodline and bloodline.ascendClassId
		-- site responses have integer ids
		else
			alternateAscendancyId = charPassives.alternate_ascendancy
		end
	else
		alternateAscendancyId = 0
	end
	-- Character import uses current GGG cluster hashes.
	self.build.spec.clusterHashFormatVersion = 2
	self.build.spec:ImportFromNodeList(charData.class,
		nil, 
		nil, 
		alternateAscendancyId,
		charPassives.hashes,
		charPassives.skill_overrides, 
		charPassives.mastery_effects or {},
			latestTreeVersion .. (charData.league:match("Ruthless") and "_ruthless" or "")
		)
	self.build.treeTab:SetActiveSpec(self.build.treeTab.activeSpec)
	self.build.spec:BuildClusterJewelGraphs()
	self.build.spec:AddUndoState()
	self.build.characterLevel = charData.level or 100
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
	
	local function setSelByVal(dropdown, val)
		for i, v in ipairs(dropdown.list) do
			if v.val == val then
				dropdown:SetSel(i)
			end
		end
	end

	local bandit = (charPassives.bandit_choice == "Eramir" or not charPassives.bandit_choice) and "None" or
		charPassives.bandit_choice
	setSelByVal(self.build.configTab.varControls["bandit"],
		bandit)

	local majorGod = charPassives.pantheon_major or "None"
	setSelByVal(self.build.configTab.varControls["pantheonMajorGod"],
		majorGod)

	local minorGod = charPassives.pantheon_minor or "None"
	setSelByVal(self.build.configTab.varControls["pantheonMinorGod"],
		minorGod)

	main:SetWindowTitleSubtext(string.format("%s (%s, %s, %s)", self.build.buildName, charData.name, charData.class,
		charData.league))
	return colorCodes.POSITIVE.."Passive tree and jewels successfully imported."
end

local SOCKET_GROUP_REIMPORT_KEY_SEPARATOR = "\31"

local function getSocketGroupReimportKey(socketGroup)
	-- Use a rarely-used separator to avoid accidental collisions when concatenating fields.
	local gemNameParts = { }
	for _, gem in ipairs(socketGroup.gemList) do
		t_insert(gemNameParts, (gem.nameSpec or ""):lower())
	end
	return table.concat({
		socketGroup.slot or "",
		socketGroup.source or "",
		tostring(#socketGroup.gemList),
		table.concat(gemNameParts, SOCKET_GROUP_REIMPORT_KEY_SEPARATOR),
	}, SOCKET_GROUP_REIMPORT_KEY_SEPARATOR)
end

local function snapshotSocketGroupReimportState(socketGroup, isMainGroup)
	local gemStates = { }
	for gemIndex, gem in ipairs(socketGroup.gemList) do
		gemStates[gemIndex] = {
			enabled = gem.enabled,
			count = gem.count,
			skillPart = gem.skillPart,
			skillPartCalcs = gem.skillPartCalcs,
			skillStageCount = gem.skillStageCount,
			skillStageCountCalcs = gem.skillStageCountCalcs,
			skillMineCount = gem.skillMineCount,
			skillMineCountCalcs = gem.skillMineCountCalcs,
			skillMinion = gem.skillMinion,
			skillMinionCalcs = gem.skillMinionCalcs,
			skillMinionItemSet = gem.skillMinionItemSet,
			skillMinionItemSetCalcs = gem.skillMinionItemSetCalcs,
			skillMinionSkill = gem.skillMinionSkill,
			skillMinionSkillCalcs = gem.skillMinionSkillCalcs,
			enableGlobal1 = gem.enableGlobal1,
			enableGlobal2 = gem.enableGlobal2,
		}
	end
	return {
		enabled = socketGroup.enabled,
		includeInFullDPS = socketGroup.includeInFullDPS,
		groupCount = socketGroup.groupCount,
		label = socketGroup.label,
		mainActiveSkill = socketGroup.mainActiveSkill,
		mainActiveSkillCalcs = socketGroup.mainActiveSkillCalcs,
		gemStates = gemStates,
		isMainGroup = isMainGroup,
	}
end

local function applyGemReimportState(gem, state)
	gem.enabled = state.enabled
	gem.count = state.count
	gem.skillPart = state.skillPart
	gem.skillPartCalcs = state.skillPartCalcs
	gem.skillStageCount = state.skillStageCount
	gem.skillStageCountCalcs = state.skillStageCountCalcs
	gem.skillMineCount = state.skillMineCount
	gem.skillMineCountCalcs = state.skillMineCountCalcs
	gem.skillMinion = state.skillMinion
	gem.skillMinionCalcs = state.skillMinionCalcs
	gem.skillMinionItemSet = state.skillMinionItemSet
	gem.skillMinionItemSetCalcs = state.skillMinionItemSetCalcs
	gem.skillMinionSkill = state.skillMinionSkill
	gem.skillMinionSkillCalcs = state.skillMinionSkillCalcs
	gem.enableGlobal1 = state.enableGlobal1
	gem.enableGlobal2 = state.enableGlobal2
end

local function applySocketGroupReimportState(socketGroup, state)
	socketGroup.enabled = state.enabled
	socketGroup.includeInFullDPS = state.includeInFullDPS
	socketGroup.groupCount = state.groupCount
	socketGroup.label = state.label
	socketGroup.mainActiveSkill = state.mainActiveSkill
	socketGroup.mainActiveSkillCalcs = state.mainActiveSkillCalcs
	if state.gemStates then
		for gemIndex, gemState in ipairs(state.gemStates) do
			if socketGroup.gemList[gemIndex] then
				applyGemReimportState(socketGroup.gemList[gemIndex], gemState)
			end
		end
	end
end

--- @class CharacterItemsData : CharacterBasicData
--- @field equipment Item[]
--- @param charData CharacterItemsData
--- @return CharacterItemsData, string
function ImportTabClass:ImportItemsAndSkills(charData)
	if self.controls.charImportItemsClearItems.state then
		for _, slot in pairs(self.build.itemsTab.slots) do
			if slot.selItemId ~= 0 and not slot.nodeId then
				self.build.itemsTab:DeleteItem(self.build.itemsTab.items[slot.selItemId])
			end
		end
	end

	local mainSkillEmpty = #self.build.skillsTab.socketGroupList == 0
	local skillOrder
	local preservedSocketGroupStateByKey
	if self.controls.charImportItemsClearSkills.state then
		skillOrder = { }
		preservedSocketGroupStateByKey = { }
		for _, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			for _, gem in ipairs(socketGroup.gemList) do
				if gem.grantedEffect and not gem.grantedEffect.support then
					t_insert(skillOrder, gem.grantedEffect.name)
				end
			end
		end
		for index, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			local key = getSocketGroupReimportKey(socketGroup)
			preservedSocketGroupStateByKey[key] = preservedSocketGroupStateByKey[key] or { }
			t_insert(preservedSocketGroupStateByKey[key], snapshotSocketGroupReimportState(socketGroup, index == self.build.mainSocketGroup))
		end
		wipeTable(self.build.skillsTab.socketGroupList)
		self.build.skillsTab:RebuildImbuedSupportBySlot()
	end
	for _, itemData in ipairs(charData.equipment) do
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
	if preservedSocketGroupStateByKey then
		local restoredMainSocketGroup
		for index, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			local stateList = preservedSocketGroupStateByKey[getSocketGroupReimportKey(socketGroup)]
			if stateList and stateList[1] then
				local state = t_remove(stateList, 1)
				applySocketGroupReimportState(socketGroup, state)
				if state.isMainGroup then
					restoredMainSocketGroup = index
				end
			end
		end
		if restoredMainSocketGroup then
			self.build.mainSocketGroup = restoredMainSocketGroup
		end
	end
	if mainSkillEmpty then
		self.build.mainSocketGroup = self:GuessMainSocketGroup()
	end
	self.build.itemsTab:PopulateSlots()
	self.build.itemsTab:AddUndoState()
	self.build.skillsTab:AddUndoState()
	self.build.characterLevel = charData.level
	self.build.configTab:UpdateLevel()
	self.build.controls.characterLevel:SetText(tostring(charData.level))
	self.build.buildFlag = true
	-- charData for the wrapper
	return charData, colorCodes.POSITIVE .. "Items and skills successfully imported."
end

local rarityMap = { [0] = "NORMAL", "MAGIC", "RARE", "UNIQUE", [9] = "RELIC", [10] = "RELIC" }
local slotMap = { ["Weapon"] = "Weapon 1", ["Offhand"] = "Weapon 2", ["Weapon2"] = "Weapon 1 Swap", ["Offhand2"] = "Weapon 2 Swap", ["Helm"] = "Helmet", ["BodyArmour"] = "Body Armour", ["Gloves"] = "Gloves", ["Boots"] = "Boots", 
				  ["Amulet"] = "Amulet", ["Ring"] = "Ring 1", ["Ring2"] = "Ring 2", ["Ring3"] = "Ring 3", ["Belt"] = "Belt",  ["BrequelGrafts"] = "Graft 1", ["BrequelGrafts2"] = "Graft 2", }

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
	if itemData.searing then
		item.cleansing = true
	end
	if itemData.tangled then
		item.tangle = true
	end
	if itemData.ilvl > 0 then
		item.itemLevel = itemData.ilvl
	end
	if item.base.weapon or item.base.armour or item.base.flask or item.base.tincture then
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
	if itemData.mutatedMods then
		for _, line in ipairs(itemData.mutatedMods) do
			for line in line:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.explicitModLines, { line = line, extra = extra, mods = modList or { }, mutated = true })
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
	if itemData.foilVariation or itemData.isRelic then
		local foilVariants = {
			"Amethyst",
			"Verdant",
			"Ruby",
			"Cobalt",
			"Sunset",
			"Aureate",
			"Celestial Quartz",
			"Celestial Ruby",
			"Celestial Emerald",
			"Celestial Aureate",
			"Celestial Pearl",
			"Celestial Amethyst",
		}
		item.foilType = foilVariants[itemData.foilVariation] or "Rainbow"
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
			local normalizedBasename = sanitiseText(socketedItem.typeLine)
			local gemId = self.build.data.gemForBaseName[normalizedBasename:lower()]
			if socketedItem.hybrid then
				-- Used by transfigured gems and dual-skill gems (currently just Stormbind) 
				normalizedBasename = sanitiseText(socketedItem.hybrid.baseTypeName)
				gemId = self.build.data.gemForBaseName[normalizedBasename:lower()]
				if gemId and socketedItem.hybrid.isVaalGem then
					gemId = self.build.data.gemGrantedEffectIdForVaalGemId[self.build.data.gems[gemId].grantedEffectId]
				end
			end
			if gemId then
				local gemInstance = { level = 20, quality = 0, enabled = true, enableGlobal1 = true, gemId = gemId }
				gemInstance.nameSpec = self.build.data.gems[gemId].name
				gemInstance.support = socketedItem.support
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
				if not socketedItem.support and socketGroup.gemList[1] and socketGroup.gemList[1].support and not (item.title and item.title:match("Dialla's Malefaction")) then
					-- If the first gemInstance is a support gemInstance, put the first active gemInstance before it
					t_insert(socketGroup.gemList, 1, gemInstance)
				else
					t_insert(socketGroup.gemList, gemInstance)
				end
				if socketedItem.builtInSupport then
					socketGroup.imbuedSupport = socketedItem.builtInSupport:gsub("Supported by Level 1 ", "")
					self.build.skillsTab.controls.imbuedSupport.gemChangeFunc(data.gems[data.gemForBaseName[socketGroup.imbuedSupport:lower().." support"]], nil, nil, slotName)
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

function ImportTabClass:SetPredefinedBuildName()
	local accountName = self.controls.siteAccountName.buf:gsub('%s+', ''):gsub("#%d+", "")
	local charSelect = self.controls.siteCharSelect
	local charData = charSelect.list[charSelect.selIndex].char
	local charName = charData.name
	main.predefinedBuildName = accountName .. " - " .. charName
end
