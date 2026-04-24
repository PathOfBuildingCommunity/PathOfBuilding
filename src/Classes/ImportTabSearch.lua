local realmList = {
	{ label = "PC",      id = "PC",   realmCode = "pc",   hostName = "https://www.pathofexile.com/", profileURL = "account/view-profile/" },
	{ label = "Xbox",    id = "XBOX", realmCode = "xbox", hostName = "https://www.pathofexile.com/", profileURL = "account/view-profile/" },
	{ label = "PS4",     id = "SONY", realmCode = "sony", hostName = "https://www.pathofexile.com/", profileURL = "account/view-profile/" },
	{ label = "Hotcool", id = "PC",   realmCode = "pc",   hostName = "https://pathofexile.tw/",      profileURL = "account/view-profile/" },
	{ label = "Tencent", id = "PC",   realmCode = "pc",   hostName = "https://poe.game.qq.com/",     profileURL = "account/view-profile/" },
}
ImportTabSearchClass = newClass("ImportTabSeach", "ControlHost", "Control", function(self)
	self.ControlHost()
	self.Control()
	self.charImportMode = "GETACCOUNTNAME"
	self.charImportStatus = "Idle"
	self.controls.sectionCharImport = new("SectionControl", { "TOPLEFT", self, "TOPLEFT" },
		{ 10, 18, 650, 250 },
		"Character Import")
	self.controls.charImportStatusLabel = new("LabelControl",
		{ "TOPLEFT", self.controls.sectionCharImport, "TOPLEFT" },
		{ 6, 14, 200, 16 }, function()
			return "^7Character import status: " .. self.charImportStatus
		end)
	-- Stage: input account name
	self.controls.accountNameHeader = new("LabelControl",
		{ "TOPLEFT", self.controls.sectionCharImport, "TOPLEFT" },
		{ 6, 40, 200, 16 }, "^7To start importing a character, enter the character's account name:")
	self.controls.accountNameHeader.shown = function()
		return self.charImportMode == "GETACCOUNTNAME"
	end
	self.controls.accountRealm = new("DropDownControl",
		{ "TOPLEFT", self.controls.accountNameHeader, "BOTTOMLEFT" },
		{ 0, 4, 60, 20 }, realmList)
	self.controls.accountRealm:SelByValue(main.lastRealm or "PC", "id")
	self.controls.accountName = new("EditControl", { "LEFT", self.controls.accountRealm, "RIGHT" },
		{ 8, 0, 200, 20 },
		main.lastAccountName or "", nil, "%c", nil, nil, nil, nil, true)
	self.controls.accountName.pasteFilter = function(text)
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
	self.controls.accountNameGo = new("ButtonControl", { "LEFT", self.controls.accountName, "RIGHT" },
		{ 8, 0, 60, 20 },
		"Start", function()
			self.controls.sessionInput.buf = ""
			self:DownloadCharacterList()
		end)
	self.controls.accountNameGo.enabled = function()
		return self.controls.accountName.buf:match("%S[#%-]%d%d%d%d$")
	end
	self.controls.accountNameGo.tooltipFunc = function(tooltip)
		tooltip:Clear()
		if not self.controls.accountName.buf:match("[#%-]%d%d%d%d$") and self.controls.accountName.buf ~= "" then
			tooltip:AddLine(16, "^7Missing discriminator e.g. " .. self.controls.accountName.buf .. "#1234")
		end
	end

	self.controls.accountHistory = new("DropDownControl",
		{ "LEFT", self.controls.accountNameGo, "RIGHT" },
		{ 8, 0, 200, 20 }, historyList, function()
			self.controls.accountName.buf = self.controls.accountHistory.list
				[self.controls.accountHistory.selIndex]
		end)
	self.controls.accountHistory:SelByValue(main.lastAccountName)
	self.controls.accountHistory:CheckDroppedWidth(true)

	self.controls.removeAccount = new("ButtonControl",
		{ "LEFT", self.controls.accountHistory, "RIGHT" }, { 8, 0, 20, 20 },
		"X", function()
			local accountName = self.controls.accountHistory.list
				[self.controls.accountHistory.selIndex]
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

	self.controls.accountNameMissingDiscriminator = new("LabelControl",
		{ "TOPLEFT", self.controls.accountName, "BOTTOMLEFT" }, { 0, 8, 0, 16 },
		"^1Missing discriminator e.g. #1234")
	self.controls.accountNameMissingDiscriminator.shown = function()
		return not self.controls.accountName.buf:match("[#%-]%d%d%d%d$") and
			self.controls.accountName.buf ~= ""
	end

	self.controls.accountNameUnicode = new("LabelControl",
		{ "TOPLEFT", self.controls.accountRealm, "BOTTOMLEFT" },
		{ 0, 34, 0, 14 },
		"^7Note: if the account name contains non-ASCII characters it must be pasted into the textbox,\nnot typed manually.")

	-- Stage: select character and import data
	self.controls.charSelectHeader = new("LabelControl",
		{ "TOPLEFT", self.controls.sectionCharImport, "TOPLEFT" },
		{ 6, 40, 200, 16 }, "^7Choose character to import data from:")
	self.controls.charSelectHeader.shown = function()
		return self.charImportMode == "SELECTCHAR" or self.charImportMode == "IMPORTING"
	end
	self.controls.charSelectLeagueLabel = new("LabelControl",
		{ "TOPLEFT", self.controls.charSelectHeader, "BOTTOMLEFT" },
		{ 0, 6, 0, 14 }, "^7League:")
	self.controls.charSelectLeague = new("DropDownControl",
		{ "LEFT", self.controls.charSelectLeagueLabel, "RIGHT" },
		{ 4, 0, 150, 18 }, nil, function(index, value)
			self:BuildCharacterList(value.league)
		end)
	self.controls.charSelect = new("DropDownControl",
		{ "TOPLEFT", self.controls.charSelectHeader, "BOTTOMLEFT" },
		{ 0, 24, 400, 18 })
	self.controls.charSelect.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charImportHeader = new("LabelControl",
		{ "TOPLEFT", self.controls.charSelect, "BOTTOMLEFT" },
		{ 0, 16, 200, 16 }, "^7Import:")
	self.controls.charImportTree = new("ButtonControl",
		{ "LEFT", self.controls.charImportHeader, "RIGHT" },
		{ 8, 0, 170, 20 }, "Passive Tree and Jewels", function()
			if self.build.spec:CountAllocNodes() > 0 then
				main:OpenConfirmPopup("Character Import",
					"Importing the passive tree will overwrite your current tree.",
					"Import", function()
						self:DownloadPassiveTree()
					end)
			else
				self:DownloadPassiveTree()
			end
			self:SetPredefinedBuildName()
		end)
	self.controls.charImportTree.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charImportTreeClearJewels = new("CheckBoxControl",
		{ "LEFT", self.controls.charImportTree, "RIGHT" },
		{ 90, 0, 18 }, "Delete jewels:", nil, "Delete all existing jewels when importing.", true)
	self.controls.charImportItems = new("ButtonControl",
		{ "LEFT", self.controls.charImportTree, "LEFT" },
		{ 0, 36, 110, 20 }, "Items and Skills", function()
			self:DownloadItems()
			self:SetPredefinedBuildName()
		end)
	self.controls.charImportItems.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charImportItemsClearSkills = new("CheckBoxControl",
		{ "LEFT", self.controls.charImportItems, "RIGHT" },
		{ 85, 0, 18 }, "Delete skills:", nil, "Delete all existing skills when importing.", true)
	self.controls.charImportItemsClearItems = new("CheckBoxControl",
		{ "LEFT", self.controls.charImportItems, "RIGHT" },
		{ 220, 0, 18 }, "Delete equipment:", nil, "Delete all equipped items when importing.", true)
	self.controls.charImportItemsIgnoreWeaponSwap = new("CheckBoxControl",
		{ "LEFT", self.controls.charImportItems,
			"RIGHT" }, { 380, 0, 18 }, "Ignore weapon swap:", nil, "Ignore items and skills in weapon swap.", false)
	self.controls.charBanditNote = new("LabelControl",
		{ "TOPLEFT", self.controls.charImportHeader, "BOTTOMLEFT" },
		{ 0, 50, 200, 14 },
		"^7Tip: After you finish importing a character, make sure you update the bandit choice,\nas it cannot be imported.")

	self.controls.charClose = new("ButtonControl",
		{ "TOPLEFT", self.controls.charImportHeader, "BOTTOMLEFT" },
		{ 0, 90, 60, 20 }, "Close", function()
			self.charImportMode = "GETACCOUNTNAME"
			self.charImportStatus = "Idle"
		end)

	-- Build import/export
	self.controls.sectionBuild = new("SectionControl",
		{ "TOPLEFT", self.controls.sectionCharImport, "BOTTOMLEFT" },
		{ 0, 18, 650, 182 }, "Build Sharing")
	self.controls.generateCodeLabel = new("LabelControl",
		{ "TOPLEFT", self.controls.sectionBuild, "TOPLEFT" },
		{ 6, 14, 0, 16 }, "^7Generate a code to share this build with other Path of Building users:")
	self.controls.generateCode = new("ButtonControl",
		{ "LEFT", self.controls.generateCodeLabel, "RIGHT" },
		{ 4, 0, 80, 20 }, "Generate", function()
			self.controls.generateCodeOut:SetText(common.base64.encode(Deflate(self.build:SaveDB(
					"code"))):gsub("+", "-")
				:gsub("/", "_"))
		end)
	self.controls.enablePartyExportBuffs = new("CheckBoxControl",
		{ "LEFT", self.controls.generateCode, "RIGHT" },
		{ 100, 0, 18 }, "Export Support", function(state)
			self.build.partyTab.enableExportBuffs = state
			self.build.buildFlag = true
		end,
		"This is for party play, to export support character, it enables the exporting of auras, curses and modifiers to the enemy",
		false)
	self.controls.generateCodeOut = new("EditControl",
		{ "TOPLEFT", self.controls.generateCodeLabel, "BOTTOMLEFT" },
		{ 0, 8, 250, 20 }, "", "Code", "%Z")
	self.controls.generateCodeOut.enabled = function()
		return #self.controls.generateCodeOut.buf > 0
	end
	self.controls.generateCodeCopy = new("ButtonControl",
		{ "LEFT", self.controls.generateCodeOut, "RIGHT" },
		{ 8, 0, 60, 20 }, "Copy", function()
			Copy(self.controls.generateCodeOut.buf)
			self.controls.generateCodeOut:SetText("")
		end)
	self.controls.generateCodeCopy.enabled = function()
		return #self.controls.generateCodeOut.buf > 0
	end
	return self.controls
end)

function ImportTabSearchClass:DownloadItems()
	self.charImportMode = "IMPORTING"
	self.charImportStatus = "Retrieving character items..."
	local realm = realmList[self.controls.accountRealm.selIndex]
	local accountName = self.controls.accountName.buf
	local sessionID = #self.controls.sessionInput.buf == 32 and self.controls.sessionInput.buf or
	(main.gameAccounts[accountName] and main.gameAccounts[accountName].sessionID)
	local charSelect = self.controls.charSelect
	local charData = charSelect.list[charSelect.selIndex].char
	launch:DownloadPage(
	realm.hostName ..
	"character-window/get-items?accountName=" ..
	accountName:gsub("#", "%%23") .. "&character=" .. urlEncode(charData.name) .. "&realm=" .. realm.realmCode,
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
			self.lastCharacterHash = common.sha1(charData.name)
			if not self.lastLeague then
				self.lastLeague = charSelectLeague:GetSelValueByKey("league")
			end
			self:ImportItemsAndSkills(response.body)
		end, sessionID and { header = "Cookie: POESESSID=" .. sessionID })
end
