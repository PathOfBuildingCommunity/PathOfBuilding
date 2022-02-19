-- Path of Building
--
-- Module: Tree Tab
-- Passive skill tree tab for the current build.
--
local ipairs = ipairs
local t_insert = table.insert
local t_sort = table.sort
local t_concat = table.concat
local m_max = math.max
local m_min = math.min
local m_floor = math.floor
local s_format = string.format

local AtlasTabClass = newClass("AtlasTab", "ControlHost", function(self, build)
	self.ControlHost()

	self.build = build
	self.isComparing = false;
	self.viewer = new("AtlasTreeView")

	self.specList = { }
	self.specList[1] = new("AtlasSpec", build, latestTreeVersion)
	self:SetActiveSpec(1)
	-- self:SetCompareSpec(1)

	self.anchorControls = new("Control", nil, 0, 0, 0, 20)
	self.controls.specSelect = new("DropDownControl", {"LEFT",self.anchorControls,"RIGHT"}, 0, 0, 190, 20, nil, function(index, value)
		if self.specList[index] then
			self.build.modFlag = true
			self:SetActiveSpec(index)
		else
			self:OpenSpecManagePopup()
		end
	end)
	self.controls.specSelect.maxDroppedWidth = 1000
	self.controls.specSelect.enableDroppedWidth = true
	self.controls.specSelect.enableChangeBoxWidth = true
	self.controls.specSelect.controls.scrollBar.enabled = true
	self.controls.specSelect.tooltipFunc = function(tooltip, mode, selIndex, selVal)
		tooltip:Clear()
		if mode ~= "OUT" then
			local spec = self.specList[selIndex]
			if spec then
				local used = spec:CountAllocNodes()
				tooltip:AddLine(16, "Points used: "..used)
				-- if sockets > 0 then
					-- tooltip:AddLine(16, "Jewel sockets: "..sockets)
				-- end
				if selIndex ~= self.activeSpec then
					if spec.curClassId == self.build.atlasSpec.curClassId then
						local respec = 0
						for nodeId, node in pairs(self.build.atlasSpec.allocNodes) do
							if not node.startNode and not spec.allocNodes[nodeId] then
								respec = respec + 1
							end
						end
						if respec > 0 then
							tooltip:AddLine(16, "^7Switching to this tree requires "..respec.." refund points.")
						end
					end
				end
				tooltip:AddLine(16, "Game Version: "..atlasTreeVersions[spec.treeVersion].display)
			end
		end
	end
	-- self.controls.compareCheck = new("CheckBoxControl", {"LEFT",self.controls.specSelect,"RIGHT"}, 74, 0, 20, "Compare:", function(state)
		-- self.isComparing = state
		-- self:SetCompareSpec(self.activeCompareSpec)
		-- self.controls.compareSelect.shown = state
		-- if state then
			-- self.controls.reset:SetAnchor("LEFT",self.controls.compareSelect,"RIGHT",nil,nil,nil)
		-- else
			-- self.controls.reset:SetAnchor("LEFT",self.controls.compareCheck,"RIGHT",nil,nil,nil)
		-- end
	-- end)
	-- self.controls.compareSelect = new("DropDownControl", {"LEFT",self.controls.compareCheck,"RIGHT"}, 8, 0, 190, 20, nil, function(index, value)
	-- self.controls.compareSelect = new("DropDownControl", {"LEFT",self.controls.specSelect,"RIGHT"}, 8, 0, 190, 20, nil, function(index, value)
		-- if self.specList[index] then
			-- self:SetCompareSpec(index)
		-- end
	-- end)
	-- self.controls.compareSelect.shown = false
	-- self.controls.compareSelect.maxDroppedWidth = 1000
	-- self.controls.compareSelect.enableDroppedWidth = true
	-- self.controls.compareSelect.enableChangeBoxWidth = true
	-- self.controls.reset = new("ButtonControl", {"LEFT",self.controls.compareCheck,"RIGHT"}, 8, 0, 60, 20, "Reset", function()
	self.controls.reset = new("ButtonControl", {"LEFT",self.controls.specSelect,"RIGHT"}, 8, 0, 60, 20, "Reset", function()
		main:OpenConfirmPopup("Reset Tree", "Are you sure you want to reset your passive tree?", "Reset", function()
			self.build.atlasSpec:ResetNodes()
			self.build.atlasSpec:BuildAllDependsAndPaths()
			self.build.atlasSpec:AddUndoState()
			self.build.buildFlag = true
		end)
	end)
	self.controls.import = new("ButtonControl", {"LEFT",self.controls.reset,"RIGHT"}, 8, 0, 90, 20, "Import Tree", function()
		self:OpenImportPopup()
	end)
	self.controls.export = new("ButtonControl", {"LEFT",self.controls.import,"RIGHT"}, 8, 0, 90, 20, "Export Tree", function()
		self:OpenExportPopup()
	end)
	self.controls.treeSearch = new("EditControl", {"LEFT",self.controls.export,"RIGHT"}, 8, 0, main.portraitMode and 200 or 300, 20, "", "Search", "%c%(%)", 100, function(buf)
		self.viewer.searchStr = buf
	end)
	self.controls.treeSearch.tooltipText = "Uses Lua pattern matching for complex searches"

	self.jumpToNode = false
	self.jumpToX = 0
	self.jumpToY = 0
end)

function AtlasTabClass:Draw(viewPort, inputEvents)
	self.anchorControls.x = viewPort.x + 4
	self.anchorControls.y = viewPort.y + viewPort.height - 24

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				self.build.atlasSpec:Undo()
				self.build.buildFlag = true
				inputEvents[id] = nil
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self.build.atlasSpec:Redo()
				self.build.buildFlag = true
				inputEvents[id] = nil
			elseif event.key == "f" and IsKeyDown("CTRL") then
				self:SelectControl(self.controls.treeSearch)
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	local bottomDrawerHeight = self.showPowerReport and 200 or 0
	self.controls.specSelect.y = -bottomDrawerHeight

	local treeViewPort = { x = viewPort.x, y = viewPort.y, width = viewPort.width, height = viewPort.height - (self.showConvert and 64 + bottomDrawerHeight or 32 + bottomDrawerHeight)}
	if self.jumpToNode then
		self.viewer:Focus(self.jumpToX, self.jumpToY, treeViewPort, self.build)
		self.jumpToNode = false
	end
	-- self.viewer.compareSpec = self.isComparing and self.specList[self.activeCompareSpec] or nil
	self.viewer:Draw(self.build, treeViewPort, inputEvents)

	self.controls.specSelect.selIndex = self.activeSpec
	wipeTable(newSpecList)
	newSpecList={}
	for id, spec in ipairs(self.specList) do
		specName=(spec.treeVersion ~= latestTreeVersion and ("["..atlasTreeVersions[spec.treeVersion].display.."] ") or "")..(spec.title or "Default")
		t_insert(newSpecList, (spec.treeVersion ~= latestTreeVersion and ("["..atlasTreeVersions[spec.treeVersion].display.."] ") or "")..(spec.title or "Default"))
	end
	-- self.controls.compareSelect:SetList(newSpecList)
	-- self.controls.compareSelect.selIndex = self.activeCompareSpec
	t_insert(newSpecList, "Manage trees...")
	self.controls.specSelect:SetList(newSpecList)

	if not self.controls.treeSearch.hasFocus then
		self.controls.treeSearch:SetText(self.viewer.searchStr)
	end

	SetDrawLayer(1)

	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (28 + bottomDrawerHeight), viewPort.width, 28 + bottomDrawerHeight)
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (32 + bottomDrawerHeight), viewPort.width, 4)

	-- if self.showConvert then
		-- SetDrawColor(0.05, 0.05, 0.05)
		-- DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (60 + bottomDrawerHeight), viewPort.width, 28)
		-- SetDrawColor(0.85, 0.85, 0.85)
		-- DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (64 + bottomDrawerHeight), viewPort.width, 4)
	-- end

	self:DrawControls(viewPort)
end

function AtlasTabClass:Load(xml, dbFileName)
	self.specList = { }
	for _, node in pairs(xml) do
		if type(node) == "table" then
			if node.elem == "Spec" then
				if node.attrib.treeVersion and not atlasTreeVersions[node.attrib.treeVersion] then
					main:OpenMessagePopup("Unknown Atlas Tree Version", "The build you are trying to load uses an unrecognised version of the atlas skill tree.\nYou may need to update the program before loading this build.")
					-- return true
					node.attrib.treeVersion = defaultTreeVersion
				end
				local newSpec = new("AtlasSpec", self.build, node.attrib.treeVersion or defaultTreeVersion)
				newSpec:Load(node, dbFileName)
				t_insert(self.specList, newSpec)
			end
		end
	end
	if not self.specList[1] then
		self.specList[1] = new("AtlasSpec", self.build, latestTreeVersion)
	end
	self:SetActiveSpec(tonumber(xml.attrib.activeSpec) or 1)
end

function AtlasTabClass:PostLoad()
	for _, spec in ipairs(self.specList) do
		spec:PostLoad()
	end
end

function AtlasTabClass:Save(xml)
	xml.attrib = {
		activeSpec = tostring(self.activeSpec)
	}
	for specId, spec in ipairs(self.specList) do
		local child = {
			elem = "Spec"
		}
		spec:Save(child)
		t_insert(xml, child)
	end
	self.modFlag = false
end

function AtlasTabClass:SetActiveSpec(specId)
	self.activeSpec = m_min(specId, #self.specList)
	local curSpec = self.specList[self.activeSpec]
	self.build.atlasSpec = curSpec
	-- data.setJewelRadiiGlobally(curSpec.treeVersion)
	-- self.showConvert = curSpec.treeVersion ~= latestTreeVersion
end

-- function AtlasTabClass:SetCompareSpec(specId)
	-- self.activeCompareSpec = m_min(specId, #self.specList)
	-- local curSpec = self.specList[self.activeCompareSpec]

	-- self.compareSpec = curSpec
-- end

function AtlasTabClass:OpenSpecManagePopup()
	main:OpenPopup(370, 290, "Manage Atlas Trees", {
		new("AtlasSpecListControl", nil, 0, 50, 350, 200, self, "AtlasSpec"),
		new("ButtonControl", nil, 0, 260, 90, 20, "Done", function()
			main:ClosePopup()
		end),
	})
end

function AtlasTabClass:OpenImportPopup()
	local controls = { }
	local function decodeTreeLink(treeLink)
		local errMsg = self.build.atlasSpec:DecodeURL(treeLink)
		if errMsg then
			controls.msg.label = "^1"..errMsg
		else
			self.build.atlasSpec:AddUndoState()
			self.build.buildFlag = true
			main:ClosePopup()
		end
	end
	controls.editLabel = new("LabelControl", nil, 0, 20, 0, 16, "Enter Atlas tree link:")
	controls.edit = new("EditControl", nil, 0, 40, 350, 18, "", nil, nil, nil, function(buf)
		controls.msg.label = ""
	end)
	controls.msg = new("LabelControl", nil, 0, 58, 0, 16, "")
	controls.import = new("ButtonControl", nil, -45, 80, 80, 20, "Import", function()
		local treeLink = controls.edit.buf
		if #treeLink == 0 then
			return
		end
		if treeLink:match("poeurl%.com/") then
			controls.import.enabled = false
			controls.msg.label = "Resolving PoEURL link..."
			local id = LaunchSubScript([[
				local treeLink = ...
				local curl = require("lcurl.safe")
				local easy = curl.easy()
				easy:setopt_url(treeLink)
				easy:setopt_writefunction(function(data)
					return true
				end)
				easy:perform()
				local redirect = easy:getinfo(curl.INFO_REDIRECT_URL)
				easy:close()
				if not redirect or redirect:match("poeurl%.com/") then
					return nil, "Failed to resolve PoEURL link"
				end
				return redirect
			]], "", "", treeLink)
			if id then
				launch:RegisterSubScript(id, function(treeLink, errMsg)
					if errMsg then
						controls.msg.label = "^1"..errMsg
						controls.import.enabled = true
					else
						decodeTreeLink(treeLink)
					end
				end)
			end
		elseif treeLink:match("poeskilltree.com/") then
			decodeTreeLink(treeLink:gsub("/%?.+#","/"))
		else
			decodeTreeLink(treeLink)
		end
	end)
	controls.cancel = new("ButtonControl", nil, 45, 80, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(380, 110, "Import Tree", controls, "import", "edit")
end

function AtlasTabClass:OpenExportPopup()
	local treeLink = self.build.atlasSpec:EncodeURL(atlasTreeVersions[self.build.atlasSpec.treeVersion].url)
	local popup
	local controls = { }
	controls.label = new("LabelControl", nil, 0, 20, 0, 16, "Atlas tree link:")
	controls.edit = new("EditControl", nil, 0, 40, 350, 18, treeLink, nil, "%Z")
	controls.shrink = new("ButtonControl", nil, -90, 70, 140, 20, "Shrink with PoEURL", function()
		controls.shrink.enabled = false
		controls.shrink.label = "Shrinking..."
		launch:DownloadPage("http://poeurl.com/shrink.php?url="..treeLink, function(page, errMsg)
			controls.shrink.label = "Done"
			if errMsg or not page:match("%S") then
				main:OpenMessagePopup("PoEURL Shortener", "Failed to get PoEURL link. Try again later.")
			else
				treeLink = "http://poeurl.com/"..page
				controls.edit:SetText(treeLink)
				popup:SelectControl(controls.edit)
			end
		end)
	end)
	controls.copy = new("ButtonControl", nil, 30, 70, 80, 20, "Copy", function()
		Copy(treeLink)
	end)
	controls.done = new("ButtonControl", nil, 120, 70, 80, 20, "Done", function()
		main:ClosePopup()
	end)
	popup = main:OpenPopup(380, 100, "Export Tree", controls, "done", "edit")
end

