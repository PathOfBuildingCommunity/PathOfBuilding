-- Path of Building
--
-- Module: Import Tab
-- Import/Export tab for the current build.
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert

local ImportTabClass = common.NewClass("ImportTab", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

	self.build = build

	self.charImportMode = "GETACCOUNTNAME"
	self.charImportStatus = "Idle"
	self.controls.sectionCharImport = common.New("SectionControl", {"TOPLEFT",self,"TOPLEFT"}, 10, 18, 600, 210, "Character Import")
	self.controls.charImportStatusLabel = common.New("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, 6, 14, 200, 16, function()
		return "^7Character import status: "..self.charImportStatus
	end)

	-- Stage: input account name
	self.controls.accountNameHeader = common.New("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, 6, 40, 200, 16, "^7To start importing a character, enter the character's account name:")
	self.controls.accountNameHeader.shown = function()
		return self.charImportMode == "GETACCOUNTNAME"
	end
	self.controls.accountName = common.New("EditControl", {"TOPLEFT",self.controls.accountNameHeader,"BOTTOMLEFT"}, 0, 4, 200, 20, main.lastAccountName or "", nil, "[%C]", 50)
	self.controls.accountNameGo = common.New("ButtonControl", {"LEFT",self.controls.accountName,"RIGHT"}, 8, 0, 60, 20, "Start", function()
		self.controls.sessionInput.buf = ""
		self:DownloadCharacterList()
	end)
	self.controls.accountNameGo.enabled = function()
		return self.controls.accountName.buf:match("%S")
	end

	-- Stage: input POESESSID
	self.controls.sessionHeader = common.New("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, 6, 40, 200, 14)
	self.controls.sessionHeader.label = function()
		return [[
^7The list of characters on ']]..self.controls.accountName.buf..[[' couldn't be retrieved. This may be because:
1. The account name is wrong, or
2. The account's privacy settings hide the characters tab (this is the default setting).
If this is your account, you can either:
1. Change your privacy settings to show you characters tab and then retry, or
2. Enter a valid POESESSID below. 
You can get this from your web browser's cookies while logged into the Path of Exile website.
		]]
	end
	self.controls.sessionHeader.shown = function()
		return self.charImportMode == "GETSESSIONID"
	end
	self.controls.sessionRetry = common.New("ButtonControl", {"TOPLEFT",self.controls.sessionHeader,"TOPLEFT"}, 0, 108, 60, 20, "Retry", function()
		self.controls.sessionInput.buf = ""
		self:DownloadCharacterList()
	end)
	self.controls.sessionCancel = common.New("ButtonControl", {"LEFT",self.controls.sessionRetry,"RIGHT"}, 8, 0, 60, 20, "Cancel", function()
		self.charImportMode = "GETACCOUNTNAME"
		self.charImportStatus = "Idle"
	end)
	self.controls.sessionInput = common.New("EditControl", {"TOPLEFT",self.controls.sessionRetry,"BOTTOMLEFT"}, 0, 8, 350, 20, "", "POESESSID", "[%x]", 32)
	self.controls.sessionGo = common.New("ButtonControl", {"LEFT",self.controls.sessionInput,"RIGHT"}, 8, 0, 60, 20, "Go", function()
		self:DownloadCharacterList()
	end)
	self.controls.sessionGo.enabled = function()
		return #self.controls.sessionInput.buf == 32
	end

	-- Stage: select character and import data
	self.controls.charSelectHeader = common.New("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, 6, 40, 200, 16, "^7Choose character to import data from:")
	self.controls.charSelectHeader.shown = function()
		return self.charImportMode == "SELECTCHAR" or self.charImportMode == "IMPORTING"
	end
	self.controls.charSelect = common.New("DropDownControl", {"TOPLEFT",self.controls.charSelectHeader,"BOTTOMLEFT"}, 0, 4, 400, 18)
	self.controls.charSelect.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charImportHeader = common.New("LabelControl", {"TOPLEFT",self.controls.charSelect,"BOTTOMLEFT"}, 0, 16, 200, 16, "Import:")
	self.controls.charImport = common.New("ButtonControl", {"LEFT",self.controls.charImportHeader, "RIGHT"}, 8, 0, 100, 20, "Passive Tree", function()
		if self.build.spec:CountAllocNodes() > 0 then
			main:OpenConfirmPopup("Character Import", "Importing the passive tree will overwrite your current tree.", "Import", function()
				self:DownloadPassiveTree()
			end)
		else
			self:DownloadPassiveTree()
		end
	end)
	self.controls.charImport.enabled = function()
		return self.charImportMode == "SELECTCHAR"
	end
	self.controls.charDone = common.New("ButtonControl", {"TOPLEFT",self.controls.charImportHeader,"BOTTOMLEFT"}, 0, 30, 60, 20, "Done", function()
		self.charImportMode = "GETACCOUNTNAME"
		self.charImportStatus = "Idle"
	end)

	-- Build import/export
	self.controls.sectionBuild = common.New("SectionControl", {"TOPLEFT",self.controls.sectionCharImport,"BOTTOMLEFT"}, 0, 18, 600, 200, "Build Sharing")
	self.controls.generateCodeLabel = common.New("LabelControl", {"TOPLEFT",self.controls.sectionBuild,"TOPLEFT"}, 6, 14, 0, 16, "^7Generate a code to share this build with other Path of Building users:")
	self.controls.generateCode = common.New("ButtonControl", {"LEFT",self.controls.generateCodeLabel,"RIGHT"}, 4, 0, 80, 20, "Generate", function()
		self.controls.generateCodeOut:SetText(common.base64.encode(Deflate(self.build:SaveDB("code"))):gsub("+","-"):gsub("/","_"))
	end)
	self.controls.generateCodeOut = common.New("EditControl", {"TOPLEFT",self.controls.generateCodeLabel,"BOTTOMLEFT"}, 0, 8, 250, 20, "", "Code", "[%z]")
	self.controls.generateCodeOut.enabled = function()
		return #self.controls.generateCodeOut.buf > 0
	end
	self.controls.generateCodeCopy = common.New("ButtonControl", {"LEFT",self.controls.generateCodeOut,"RIGHT"}, 8, 0, 60, 20, "Copy", function()
		Copy(self.controls.generateCodeOut.buf)
		self.controls.generateCodeOut:SetText("")
	end)
	self.controls.generateCodeCopy.enabled = function()
		return #self.controls.generateCodeOut.buf > 0
	end
	self.controls.generateCodeNote = common.New("LabelControl", {"TOPLEFT",self.controls.generateCodeOut,"BOTTOMLEFT"}, 0, 4, 0, 14, "^7Note: this code can be very long; it may be easiest to share it using Pastebin or similar.")
	self.controls.importCodeHeader = common.New("LabelControl", {"TOPLEFT",self.controls.generateCodeNote,"BOTTOMLEFT"}, 0, 26, 0, 16, "^7To import a build, enter the code here:")
	self.controls.importCodeIn = common.New("EditControl", {"TOPLEFT",self.controls.importCodeHeader,"BOTTOMLEFT"}, 0, 4, 250, 20, "", nil, "[%w_%-=]", nil, function(buf)
		if #buf == 0 then
			self.importCodeState = nil
			return
		end
		self.importCodeState = "INVALID"
		local xmlText = Inflate(common.base64.decode(buf:gsub("-","+"):gsub("_","/")))
		if not xmlText then
			return
		end
		self.importCodeState = "VALID"
		self.importCodeXML = xmlText
	end)
	self.controls.importCodeState = common.New("LabelControl", {"LEFT",self.controls.importCodeIn,"RIGHT"}, 4, 0, 0, 16)
	self.controls.importCodeState.label = function()
		return (self.importCodeState == "VALID" and data.colorCodes.POSITIVE.."Code is valid") or (self.importCodeState == "INVALID" and data.colorCodes.NEGATIVE.."Invalid code") or ""
	end
	self.controls.importCodeMode = common.New("DropDownControl", {"TOPLEFT",self.controls.importCodeIn,"BOTTOMLEFT"}, 0, 4, 160, 20, { "Import to this build", "Import to a new build:" })
	self.controls.importCodeMode.enabled = function()
		return self.importCodeState == "VALID"
	end
	self.controls.importCodeBuildName = common.New("EditControl", {"LEFT",self.controls.importCodeMode,"RIGHT"}, 4, 0, 400, 20, "", "New build name", "[%w _+-.()]", 50)
	self.controls.importCodeBuildName.enabled = function()
		return self.importCodeState == "VALID" and self.controls.importCodeMode.sel == 2
	end
	self.controls.importCodeGo = common.New("ButtonControl", {"TOPLEFT",self.controls.importCodeMode,"BOTTOMLEFT"}, 0, 8, 60, 20, "Import", function()
		if self.controls.importCodeMode.sel == 1 then
			main:OpenConfirmPopup("Build Import", "^xFF9922Warning:^7 Importing to the current build will erase ALL existing data for this build.\nThis cannot be undone.", "Import", function()
				self:ImportToBuild(self.build.dbFileName, self.build.buildName)
			end)
		else
			local newBuildName = self.controls.importCodeBuildName.buf
			local newFileName = main.buildPath .. newBuildName .. ".xml"
			local file = io.open(newFileName, "r")
			if file then
				file:close()
				main:OpenMessagePopup("Build Import", "A build with that name already exists.")
				return
			end
			self:ImportToBuild(newFileName, newBuildName)
		end
	end)
	self.controls.importCodeGo.enabled = function()
		return self.importCodeState == "VALID" and (self.controls.importCodeMode.sel == 1 or self.controls.importCodeBuildName.buf:match("%S"))
	end
end)

function ImportTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	self:ProcessControlsInput(inputEvents)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)
end

function ImportTabClass:DownloadCharacterList()
	self.charImportMode = "DOWNLOADCHARLIST"
	self.charImportStatus = "Retrieving character list..."
	local accountName = self.controls.accountName.buf
	local sessionID = #self.controls.sessionInput.buf == 32 and self.controls.sessionInput.buf or main.accountSessionIDs[accountName]
	launch:DownloadPage("https://www.pathofexile.com/character-window/get-characters?accountName="..accountName, function(page, errMsg)
		if errMsg then
			self.charImportStatus = data.colorCodes.NEGATIVE.."Unknown error retrieving character list, try again ("..errMsg")"
			self.charImportMode = "GETACCOUNTNAME"
			return
		elseif page == "false" then
			self.charImportStatus = data.colorCodes.NEGATIVE.."Failed to retrieve character list."
			self.charImportMode = "GETSESSIONID"
			return
		end
		local charList, errMsg = self:ProcessJSON(page)
		if errMsg then
			self.charImportStatus = data.colorCodes.NEGATIVE.."Error processing character list, try again later"
			self.charImportMode = "GETACCOUNTNAME"
			return
		end
		self.charImportStatus = "Character list successfully retrieved."
		self.charImportMode = "SELECTCHAR"
		main.lastAccountName = accountName
		if sessionID then
			main.accountSessionIDs[accountName] = sessionID
		end
		wipeTable(self.controls.charSelect.list)
		for i, char in ipairs(charList) do
			t_insert(self.controls.charSelect.list, {
				val = char,
				label = string.format("%s: Level %d %s in %s", char.name or "?", char.level or 0, char.class or "?", char.league or "?")
			})
		end
		table.sort(self.controls.charSelect.list, function(a,b)
			return a.val.name:lower() < b.val.name:lower()
		end)
	end, sessionID and "POESESSID="..sessionID)
end

function ImportTabClass:DownloadPassiveTree()
	self.charImportMode = "IMPORTING"
	self.charImportStatus = "Retrieving character passive tree..."
	local accountName = self.controls.accountName.buf
	local sessionID = #self.controls.sessionInput.buf == 32 and self.controls.sessionInput.buf or main.accountSessionIDs[accountName]
	local charSelect = self.controls.charSelect
	local charData = charSelect.list[charSelect.sel].val
	launch:DownloadPage("https://www.pathofexile.com/character-window/get-passive-skills?accountName="..accountName.."&character="..charData.name, function(page, errMsg)
		self.charImportMode = "SELECTCHAR"
		if errMsg then
			self.charImportStatus = data.colorCodes.NEGATIVE.."Unknown error importing character data, try again ("..errMsg")"
			return
		elseif page == "false" then
			self.charImportStatus = data.colorCodes.NEGATIVE.."Failed to retrieve character data, try again."
			return
		end
		local passiveData, errMsg = self:ProcessJSON(page)
		if errMsg then
			self.charImportStatus = data.colorCodes.NEGATIVE.."Error processing character data, try again later."
			return
		end
		self.charImportStatus = data.colorCodes.POSITIVE.."Passive tree successfully imported."
		self.build.spec:ImportFromNodeList(charData.classId, charData.ascendancyClass, passiveData.hashes)
		self.build.spec:AddUndoState()
		self.build.characterLevel = charData.level
		self.build.buildFlag = true
		ConPrintTable(passiveData)
	end, sessionID and "POESESSID="..sessionID)
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

function ImportTabClass:ImportToBuild(buildFileName, buildName)
	self.build:Shutdown()
	local file = io.open(buildFileName, "w+")
	if not file then
		main:ShowMessagePopup("Build Import", "^xFF2222Error:^7 Couldn't create build file (invalid name?)")
		return
	end
	file:write(self.importCodeXML)
	file:close()
	self.build:Init(buildFileName, buildName)
	self.build.viewMode = "TREE"
end