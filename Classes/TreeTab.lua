-- Path of Building
--
-- Module: Tree Tab
-- Passive skill tree tab for the current build.
--
local ipairs = ipairs
local t_insert = table.insert
local m_min = math.min

local TreeTabClass = newClass("TreeTab", "ControlHost", function(self, build)
	self.ControlHost()

	self.build = build

	self.viewer = new("PassiveTreeView")

	self.specList = { }
	self.specList[1] = new("PassiveSpec", build, build.targetVersionData.latestTreeVersion)
	self:SetActiveSpec(1)

	self.anchorControls = new("Control", nil, 0, 0, 0, 20)
	self.controls.specSelect = new("DropDownControl", {"LEFT",self.anchorControls,"RIGHT"}, 0, 0, 190, 20, nil, function(index, value)
		if self.specList[index] then
			self.build.modFlag = true
			self:SetActiveSpec(index)
		else
			self:OpenSpecManagePopup()
		end
	end)
	self.controls.specSelect.tooltipFunc = function(tooltip, mode, selIndex, selVal)
		tooltip:Clear()
		if mode ~= "OUT" then
			local spec = self.specList[selIndex]
			if spec then
				local used, ascUsed, sockets = spec:CountAllocNodes()
				tooltip:AddLine(16, "Class: "..spec.curClassName)
				tooltip:AddLine(16, "Ascendancy: "..spec.curAscendClassName)
				tooltip:AddLine(16, "Points used: "..used)
				if sockets > 0 then
					tooltip:AddLine(16, "Jewel sockets: "..sockets)
				end
				if selIndex ~= self.activeSpec then
					local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator()
					if calcFunc then
						local output = calcFunc({ spec = spec })
						self.build:AddStatComparesToTooltip(tooltip, calcBase, output, "^7Switching to this tree will give you:")
					end
					if spec.curClassId == self.build.spec.curClassId then
						local respec = 0
						for nodeId, node in pairs(self.build.spec.allocNodes) do
							if node.type ~= "ClassStart" and node.type ~= "AscendClassStart" and not spec.allocNodes[nodeId] then
								if node.ascendancyName then
									respec = respec + 5
								else
									respec = respec + 1
								end
							end
						end
						if respec > 0 then
							tooltip:AddLine(16, "^7Switching to this tree requires "..respec.." refund points.")
						end
					end
				end
				tooltip:AddLine(16, "Game Version: "..treeVersions[spec.treeVersion].short)
			end
		end
	end
	self.controls.reset = new("ButtonControl", {"LEFT",self.controls.specSelect,"RIGHT"}, 8, 0, 60, 20, "Reset", function()
		main:OpenConfirmPopup("Reset Tree", "Are you sure you want to reset your passive tree?", "Reset", function()
			self.build.spec:ResetNodes()
			self.build.spec:AddUndoState()
			self.build.buildFlag = true
		end)
	end)
	self.controls.import = new("ButtonControl", {"LEFT",self.controls.reset,"RIGHT"}, 8, 0, 90, 20, "Import Tree", function()
		self:OpenImportPopup()
	end)
	self.controls.export = new("ButtonControl", {"LEFT",self.controls.import,"RIGHT"}, 8, 0, 90, 20, "Export Tree", function()
		self:OpenExportPopup()
	end)
	self.controls.treeSearch = new("EditControl", {"LEFT",self.controls.export,"RIGHT"}, 8, 0, 300, 20, "", "Search", "%c%(%)", 100, function(buf)
		self.viewer.searchStr = buf
	end)
	self.controls.treeHeatMap = new("CheckBoxControl", {"LEFT",self.controls.treeSearch,"RIGHT"}, 130, 0, 20, "Show Node Power:", function(state)
		self.viewer.showHeatMap = state
		self.controls.treeHeatMapStatSelect.shown = state
	end)
	self.controls.treeHeatMapStatSelect = new("DropDownControl", {"LEFT",self.controls.treeHeatMap,"RIGHT"}, 8, 0, 150, 20, nil, function(index, value)
		self:SetPowerCalc(value)
	end)
	self.controls.treeHeatMap.tooltipText = function()
		local offCol, defCol = main.nodePowerTheme:match("(%a+)/(%a+)")
		return "When enabled, an estimate of the offensive and defensive strength of\neach unallocated passive is calculated and displayed visually.\nOffensive power shows as "..offCol:lower()..", defensive power as "..defCol:lower().."."
	end

	self.powerStatList = { }
	for _, stat in ipairs(data.powerStatList) do
		if not stat.ignoreForNodes then
			t_insert(self.powerStatList, stat)
		end
	end

	self.controls.treeHeatMapTopStat = new("CheckBoxControl", {"LEFT", self.controls.treeHeatMapStatSelect,"RIGHT"}, 110, 0, 20, "Show top node:", function(state)
		self.viewer.heatMapTopPick = state
	end )

	self.controls.treeHeatMapTopStat.tooltipText = function()
		return "When enabled, only the strongest node for the selected stat will be highlighted."
	end

	self.controls.treeHeatMapStatPerPoint = new("CheckBoxControl", {"LEFT", self.controls.treeHeatMapTopStat,"RIGHT"}, 115, 0, 20, "Power per point:", function(state)
		self.viewer.heatMapStatPerPoint = state
	end )

	self.controls.treeHeatMapStatPerPoint.tooltipText = function()
		return "When enabled, node power is divided by the point cost it would take to get there,\nso closer points are considered stronger"
	end

	self.controls.specConvertText = new("LabelControl", {"BOTTOMLEFT",self.controls.specSelect,"TOPLEFT"}, 0, -14, 0, 16, "^7This is an older tree version, which may not be fully compatible with the current game version.")
	self.controls.specConvertText.shown = function()
		return self.showConvert
	end
	self.controls.specConvert = new("ButtonControl", {"LEFT",self.controls.specConvertText,"RIGHT"}, 8, 0, 120, 20, "^2Convert to "..treeVersions[self.build.targetVersionData.latestTreeVersion].short, function()
		local newSpec = new("PassiveSpec", self.build, self.build.targetVersionData.latestTreeVersion)
		newSpec.title = self.build.spec.title
		newSpec.jewels = copyTable(self.build.spec.jewels)
		newSpec:RestoreUndoState(self.build.spec:CreateUndoState())
		newSpec:BuildClusterJewelGraphs()
		t_insert(self.specList, self.activeSpec + 1, newSpec)
		self:SetActiveSpec(self.activeSpec + 1)
		self.modFlag = true
		main:OpenMessagePopup("Tree Converted", "The tree has been converted to "..treeVersions[self.build.targetVersionData.latestTreeVersion].short..".\nNote that some or all of the passives may have been de-allocated due to changes in the tree.\n\nYou can switch back to the old tree using the tree selector at the bottom left.")
	end)
end)

function TreeTabClass:Draw(viewPort, inputEvents)
	self.anchorControls.x = viewPort.x + 4
	self.anchorControls.y = viewPort.y + viewPort.height - 24

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				self.build.spec:Undo()
				self.build.buildFlag = true
				inputEvents[id] = nil
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self.build.spec:Redo()
				self.build.buildFlag = true
				inputEvents[id] = nil
			elseif event.key == "f" and IsKeyDown("CTRL") then
				self:SelectControl(self.controls.treeSearch)
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	-- Determine positions if one line of controls doesn't fit in the screen width
	local twoLineHeight = self.controls.treeHeatMap.y == 24 and 26 or 0
	if(select(1, self.controls.treeHeatMapStatPerPoint:GetPos()) + select(1, self.controls.treeHeatMapStatPerPoint:GetSize()) > viewPort.x + viewPort.width) then
		twoLineHeight = 26
		self.controls.treeHeatMap:SetAnchor("BOTTOMLEFT",self.controls.specSelect,"BOTTOMLEFT",nil,nil,nil)
		self.controls.treeHeatMap.y = 24
		self.controls.treeHeatMap.x = 125

		self.controls.specSelect.y = -24
		self.controls.specConvertText.y = -16
	elseif viewPort.x + viewPort.width - (select(1, self.controls.treeSearch:GetPos()) + select(1, self.controls.treeSearch:GetSize())) > (select(1, self.controls.treeHeatMapStatPerPoint:GetPos()) + select(1, self.controls.treeHeatMapStatPerPoint:GetSize())) - viewPort.x  then
		twoLineHeight = 0
		self.controls.treeHeatMap:SetAnchor("LEFT",self.controls.treeSearch,"RIGHT",nil,nil,nil)
		self.controls.treeHeatMap.y = 0
		self.controls.treeHeatMap.x = 130

		self.controls.specSelect.y = 0
		self.controls.specConvertText.y = -14
	end
	--

	local treeViewPort = { x = viewPort.x, y = viewPort.y, width = viewPort.width, height = viewPort.height - (self.showConvert and 64 + twoLineHeight or 32 + twoLineHeight)}
	self.viewer:Draw(self.build, treeViewPort, inputEvents)

	self.controls.specSelect.selIndex = self.activeSpec
	wipeTable(self.controls.specSelect.list)
	for id, spec in ipairs(self.specList) do
		t_insert(self.controls.specSelect.list, (spec.treeVersion ~= self.build.targetVersionData.latestTreeVersion and ("["..treeVersions[spec.treeVersion].short.."] ") or "")..(spec.title or "Default"))
	end
	t_insert(self.controls.specSelect.list, "Manage trees...")
	
	if not self.controls.treeSearch.hasFocus then
		self.controls.treeSearch:SetText(self.viewer.searchStr)
	end
	
	self.controls.treeHeatMap.state = self.viewer.showHeatMap

	self.controls.treeHeatMapStatSelect.list = self.powerStatList
	self.controls.treeHeatMapStatSelect.selIndex = 1
	if self.build.calcsTab.powerStat then
		self.controls.treeHeatMapStatSelect:SelByValue(self.build.calcsTab.powerStat.stat, "stat")
	end
	
	SetDrawLayer(1)

	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (28 + twoLineHeight), viewPort.width, 28 + twoLineHeight)
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (32 + twoLineHeight), viewPort.width, 4)

	if self.showConvert then
		SetDrawColor(0.05, 0.05, 0.05)
		DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (60 + twoLineHeight), viewPort.width, 28)
		SetDrawColor(0.85, 0.85, 0.85)
		DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (64 + twoLineHeight), viewPort.width, 4)
	end

	self:DrawControls(viewPort)
end

function TreeTabClass:Load(xml, dbFileName)
	self.specList = { }
	if xml.elem == "Spec" then
		-- Import single spec from old build
		self.specList[1] = new("PassiveSpec", self.build, self.build.targetVersionData.defaultTreeVersion)
		self.specList[1]:Load(xml, dbFileName)
		self.activeSpec = 1
		self.build.spec = self.specList[1]
		return
	end
	for _, node in pairs(xml) do
		if type(node) == "table" then
			if node.elem == "Spec" then
				if node.attrib.treeVersion and not treeVersions[node.attrib.treeVersion] then
					main:OpenMessagePopup("Unknown Passive Tree Version", "The build you are trying to load uses an unrecognised version of the passive skill tree.\nYou may need to update the program before loading this build.")
					return true
				end
				local newSpec = new("PassiveSpec", self.build, node.attrib.treeVersion or self.build.targetVersionData.defaultTreeVersion)
				newSpec:Load(node, dbFileName)
				t_insert(self.specList, newSpec)
			end
		end
	end
	if not self.specList[1] then
		self.specList[1] = new("PassiveSpec", self.build, self.build.targetVersionData.latestTreeVersion)
	end
	self:SetActiveSpec(tonumber(xml.attrib.activeSpec) or 1)
end

function TreeTabClass:PostLoad()
	for _, spec in ipairs(self.specList) do
		spec:PostLoad()
	end
end

function TreeTabClass:Save(xml)
	xml.attrib = { 
		activeSpec = tostring(self.activeSpec)
	}
	for specId, spec in ipairs(self.specList) do
		if specId == self.activeSpec then
			-- Update this spec's jewels from the socket slots
			for _, slot in pairs(self.build.itemsTab.slots) do
				if slot.nodeId then
					spec.jewels[slot.nodeId] = slot.selItemId
				end
			end
		end
		local child = {
			elem = "Spec"
		}
		spec:Save(child)
		t_insert(xml, child)
	end
	self.modFlag = false
end

function TreeTabClass:SetActiveSpec(specId)
	local prevSpec = self.build.spec
	self.activeSpec = m_min(specId, #self.specList)
	local curSpec = self.specList[self.activeSpec]
	self.build.spec = curSpec
	self.build.buildFlag = true
	self.build.spec:SetWindowTitleWithBuildClass()
	for _, slot in pairs(self.build.itemsTab.slots) do
		if slot.nodeId then
			if prevSpec then
				-- Update the previous spec's jewel for this slot
				prevSpec.jewels[slot.nodeId] = slot.selItemId
			end
			if curSpec.jewels[slot.nodeId] then
				-- Socket the jewel for the new spec
				slot.selItemId = curSpec.jewels[slot.nodeId]
			end
		end
	end
	self.showConvert = curSpec.treeVersion ~= self.build.targetVersionData.latestTreeVersion
	if self.build.itemsTab.itemOrderList[1] then
		-- Update item slots if items have been loaded already
		self.build.itemsTab:PopulateSlots()
	end
end

function TreeTabClass:SetPowerCalc(selection)
	self.viewer.showHeatMap = true
	self.build.buildFlag = true
	self.build.powerBuildFlag = true
	self.build.calcsTab.powerStat = selection
	self.build.calcsTab:BuildPower()
end

function TreeTabClass:OpenSpecManagePopup()
	main:OpenPopup(370, 290, "Manage Passive Trees", {
		new("PassiveSpecListControl", nil, 0, 50, 350, 200, self),
		new("ButtonControl", nil, 0, 260, 90, 20, "Done", function()
			main:ClosePopup()
		end),
	})
end

function TreeTabClass:OpenImportPopup()
	local controls = { }
	local function decodeTreeLink(treeLink)
		local errMsg = self.build.spec:DecodeURL(treeLink)
		if errMsg then
			controls.msg.label = "^1"..errMsg
		else
			self.build.spec:AddUndoState()
			self.build.buildFlag = true
			main:ClosePopup()
		end
	end
	controls.editLabel = new("LabelControl", nil, 0, 20, 0, 16, "Enter passive tree link:")
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
		else
			decodeTreeLink(treeLink)
		end
	end)
	controls.cancel = new("ButtonControl", nil, 45, 80, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(380, 110, "Import Tree", controls, "import", "edit")
end

function TreeTabClass:OpenExportPopup()
	local treeLink = self.build.spec:EncodeURL(treeVersions[self.build.spec.treeVersion].export)
	local popup
	local controls = { }
	controls.label = new("LabelControl", nil, 0, 20, 0, 16, "Passive tree link:")
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