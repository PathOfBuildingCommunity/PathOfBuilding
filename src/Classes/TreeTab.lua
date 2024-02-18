-- Path of Building
--
-- Module: Tree Tab
-- Passive skill tree tab for the current build.
--
local ipairs = ipairs
local pairs = pairs
local next = next
local t_insert = table.insert
local t_remove = table.remove
local t_sort = table.sort
local t_concat = table.concat
local m_max = math.max
local m_min = math.min
local m_floor = math.floor
local m_abs = math.abs
local s_format = string.format
local s_gsub = string.gsub
local s_byte = string.byte
local dkjson = require "dkjson"

local TreeTabClass = newClass("TreeTab", "ControlHost", function(self, build)
	self.ControlHost()

	self.build = build
	self.isComparing = false;

	self.viewer = new("PassiveTreeView")

	self.specList = { }
	self.specList[1] = new("PassiveSpec", build, latestTreeVersion)
	self:SetActiveSpec(1)
	self:SetCompareSpec(1)

	self.anchorControls = new("Control", nil, 0, 0, 0, 20)

	-- Tree list dropdown
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
				local used, ascUsed, secondaryAscUsed, sockets = spec:CountAllocNodes()
				tooltip:AddLine(16, "Class: "..spec.curClassName)
				tooltip:AddLine(16, "Ascendancy: "..spec.curAscendClassName)
				tooltip:AddLine(16, "Points used: "..used)
				if sockets > 0 then
					tooltip:AddLine(16, "Jewel sockets: "..sockets)
				end
				if selIndex ~= self.activeSpec then
					local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator()
					if calcFunc then
						local output = calcFunc({ spec = spec }, {})
						self.build:AddStatComparesToTooltip(tooltip, calcBase, output, "^7Switching to this tree will give you:")
					end
					if spec.curClassId == self.build.spec.curClassId then
						local respec = 0
						for nodeId, node in pairs(self.build.spec.allocNodes) do
							-- Assumption: Nodes >= 65536 are small cluster passives.
							if node.type ~= "ClassStart" and node.type ~= "AscendClassStart"
							and (self.build.spec.tree.clusterNodeMap[node.dn] == nil or node.isKeystone or node.isJewelSocket) and nodeId < 65536
							and not spec.allocNodes[nodeId] then
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
				tooltip:AddLine(16, "Game Version: "..treeVersions[spec.treeVersion].display)
			end
		end
	end

	-- Compare checkbox
	self.controls.compareCheck = new("CheckBoxControl", { "LEFT", self.controls.specSelect, "RIGHT" }, 74, 0, 20, "Compare:", function(state)
		self.isComparing = state
		self:SetCompareSpec(self.activeCompareSpec)
		self.controls.compareSelect.shown = state
		if state then
			self.controls.reset:SetAnchor("LEFT", self.controls.compareSelect, "RIGHT", nil, nil, nil)
		else
			self.controls.reset:SetAnchor("LEFT", self.controls.compareCheck, "RIGHT", nil, nil, nil)
		end
	end)

	-- Compare tree dropdown
	self.controls.compareSelect = new("DropDownControl", { "LEFT", self.controls.compareCheck, "RIGHT" }, 8, 0, 190, 20, nil, function(index, value)
		if self.specList[index] then
			self:SetCompareSpec(index)
		end
	end)
	self.controls.compareSelect.shown = false
	self.controls.compareSelect.maxDroppedWidth = 1000
	self.controls.compareSelect.enableDroppedWidth = true
	self.controls.compareSelect.enableChangeBoxWidth = true
	self.controls.reset = new("ButtonControl", { "LEFT", self.controls.compareCheck, "RIGHT" }, 8, 0, 60, 20, "Reset", function()
		main:OpenConfirmPopup("Reset Tree", "Are you sure you want to reset your passive tree?", "Reset", function()
			self.build.spec:ResetNodes()
			self.build.spec:BuildAllDependsAndPaths()
			self.build.spec:AddUndoState()
			self.build.buildFlag = true
		end)
	end)

	-- Tree Version Dropdown
	self.treeVersions = { }
	for _, num in ipairs(treeVersionList) do
		t_insert(self.treeVersions, treeVersions[num].display)
	end
	self.controls.versionText = new("LabelControl", { "LEFT", self.controls.reset, "RIGHT" }, 8, 0, 0, 16, "Version:")
	self.controls.versionSelect = new("DropDownControl", { "LEFT", self.controls.versionText, "RIGHT" }, 8, 0, 100, 20, self.treeVersions, function(index, value)
		if value ~= self.build.spec.treeVersion then
			self:OpenVersionConvertPopup(value:gsub("[%(%)]", ""):gsub("[%.%s]", "_"), true)
		end
	end)
	self.controls.versionSelect.maxDroppedWidth = 1000
	self.controls.versionSelect.enableDroppedWidth = true
	self.controls.versionSelect.enableChangeBoxWidth = true
	self.controls.versionSelect.selIndex = #self.treeVersions

	-- Tree Search Textbox
	self.controls.treeSearch = new("EditControl", { "LEFT", self.controls.versionSelect, "RIGHT" }, 8, 0, main.portraitMode and 200 or 300, 20, "", "Search", "%c", 100, function(buf)
		self.viewer.searchStr = buf
		self.searchFlag = buf ~= self.viewer.searchStrSaved
	end, nil, nil, true)
	self.controls.treeSearch.tooltipText = "Uses Lua pattern matching for complex searches"

	self.tradeLeaguesList = { }
	-- Find Timeless Jewel Button
	self.controls.findTimelessJewel = new("ButtonControl", { "LEFT", self.controls.treeSearch, "RIGHT" }, 8, 0, 150, 20, "Find Timeless Jewel", function()
		self:FindTimelessJewel()
	end)

	-- Show Node Power Checkbox
	self.controls.treeHeatMap = new("CheckBoxControl", { "LEFT", self.controls.findTimelessJewel, "RIGHT" }, 130, 0, 20, "Show Node Power:", function(state)
		self.viewer.showHeatMap = state
		self.controls.treeHeatMapStatSelect.shown = state

		if state == false then
			self.controls.powerReportList.shown = false 
		end
	end)

	-- Control for setting max node depth to limit calculation time of the heat map
	self.controls.nodePowerMaxDepthSelect = new("DropDownControl",
	{ "LEFT", self.controls.treeHeatMap, "RIGHT" }, 8, 0, 50, 20, { "All", 5, 10, 15 }, function(index, value)
		local oldMax = self.build.calcsTab.nodePowerMaxDepth

		if type(value) == "number" then
			self.build.calcsTab.nodePowerMaxDepth = value
		else
			self.build.calcsTab.nodePowerMaxDepth = nil
		end

		-- If the heat map is shown, tell it to recalculate
		-- if the new value is larger than the old
		if oldMax ~= value and self.viewer.showHeatMap then
			if oldMax ~= nil and (self.build.calcsTab.nodePowerMaxDepth == nil or self.build.calcsTab.nodePowerMaxDepth > oldMax) then
				self:SetPowerCalc(self.build.calcsTab.powerStat)
			end
		end
	end)
	self.controls.nodePowerMaxDepthSelect.tooltipText = "Limit of Node distance to search (lower = faster)"

	-- Control for selecting the power stat to sort by (Defense, DPS, etc)
	self.controls.treeHeatMapStatSelect = new("DropDownControl", { "LEFT", self.controls.nodePowerMaxDepthSelect, "RIGHT" }, 8, 0, 150, 20, nil, function(index, value)
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

	-- Show/Hide Power Report Button
	self.controls.powerReport = new("ButtonControl", { "LEFT", self.controls.treeHeatMapStatSelect, "RIGHT" }, 8, 0, 150, 20,
		function() return self.controls.powerReportList.shown and "Hide Power Report" or "Show Power Report" end, function()
		self.controls.powerReportList.shown = not self.controls.powerReportList.shown
	end)

	-- Power Report List
	local yPos = self.controls.treeHeatMap.y == 0 and self.controls.specSelect.height + 4 or self.controls.specSelect.height * 2 + 8
	self.controls.powerReportList = new("PowerReportListControl", {"TOPLEFT", self.controls.specSelect, "BOTTOMLEFT"}, 0, yPos, 700, 220, function(selectedNode)
		-- this code is called by the list control when the user "selects" one of the passives in the list.
		-- we use this to set a flag which causes the next Draw() to recenter the passive tree on the desired node.
		if selectedNode.x then
			self.jumpToNode = true
			self.jumpToX = selectedNode.x
			self.jumpToY = selectedNode.y
		end
	end)
	self.controls.powerReportList.shown = false
	self.build.powerBuilderCallback = function()
		local powerStat = self.build.calcsTab.powerStat or data.powerStatList[1]
		local report = self:BuildPowerReportList(powerStat)
		self.controls.powerReportList:SetReport(powerStat, report)
	end

	self.controls.specConvertText = new("LabelControl", { "BOTTOMLEFT", self.controls.specSelect, "TOPLEFT" }, 0, -14, 0, 16, "^7This is an older tree version, which may not be fully compatible with the current game version.")
	self.controls.specConvertText.shown = function()
		return self.showConvert
	end
	local function getLatestTreeVersion()
		return latestTreeVersion .. (self.specList[self.activeSpec].treeVersion:match("^" .. latestTreeVersion .. "(.*)") or "")
	end
	local function buildConvertButtonLabel()
		return colorCodes.POSITIVE.."Convert to "..treeVersions[getLatestTreeVersion()].display
	end
	local function buildConvertAllButtonLabel()
		return colorCodes.POSITIVE.."Convert all trees to "..treeVersions[getLatestTreeVersion()].display
	end
	self.controls.specConvert = new("ButtonControl", { "LEFT", self.controls.specConvertText, "RIGHT" }, 8, 0, function() return DrawStringWidth(16, "VAR", buildConvertButtonLabel()) + 20 end, 20, buildConvertButtonLabel, function()
		self:ConvertToVersion(getLatestTreeVersion(), false, true)
	end)
	self.controls.specConvertAll = new("ButtonControl", { "LEFT", self.controls.specConvert, "RIGHT" }, 8, 0, function() return DrawStringWidth(16, "VAR", buildConvertAllButtonLabel()) + 20 end, 20, buildConvertAllButtonLabel, function()
		self:OpenVersionConvertAllPopup(getLatestTreeVersion())
	end)
	self.jumpToNode = false
	self.jumpToX = 0
	self.jumpToY = 0
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
			elseif event.key == "m" and IsKeyDown("CTRL") then
				self:OpenSpecManagePopup()
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	-- Determine positions if one line of controls doesn't fit in the screen width
	local twoLineHeight = 24
	if viewPort.width >= 1336 + (self.isComparing and 198 or 0) + (self.viewer.showHeatMap and 316 or 0) then
		twoLineHeight = 0
		self.controls.treeSearch:SetAnchor("LEFT", self.controls.versionSelect, "RIGHT", 8, 0)
		self.controls.powerReportList:SetAnchor("TOPLEFT", self.controls.specSelect, "BOTTOMLEFT", 0, self.controls.specSelect.height + 4)
	else
		self.controls.treeSearch:SetAnchor("TOPLEFT", self.controls.specSelect, "BOTTOMLEFT", 0, 4)
		self.controls.powerReportList:SetAnchor("TOPLEFT", self.controls.treeSearch, "BOTTOMLEFT", 0, self.controls.treeHeatMap.y + self.controls.treeHeatMap.height + 4)
	end
	-- determine positions for convert line of controls
	local convertTwoLineHeight = 24
	local convertMaxWidth = 900
	if viewPort.width >= convertMaxWidth then
		convertTwoLineHeight = 0
		self.controls.specConvert:SetAnchor("LEFT", self.controls.specConvertText, "RIGHT", 8, 0)
		self.controls.specConvertText:SetAnchor("BOTTOMLEFT", self.controls.specSelect, "TOPLEFT", 0, -14)
	else
		self.controls.specConvert:SetAnchor("TOPLEFT", self.controls.specConvertText, "BOTTOMLEFT", 0, 4)
		self.controls.specConvertText:SetAnchor("BOTTOMLEFT", self.controls.specSelect, "TOPLEFT", 0, -38)
	end

	local bottomDrawerHeight = self.controls.powerReportList.shown and 194 or 0
	self.controls.specSelect.y = -bottomDrawerHeight - twoLineHeight

	local treeViewPort = { x = viewPort.x, y = viewPort.y, width = viewPort.width, height = viewPort.height - (self.showConvert and 64 + bottomDrawerHeight + twoLineHeight or 32 + bottomDrawerHeight + twoLineHeight)}
	if self.jumpToNode then
		self.viewer:Focus(self.jumpToX, self.jumpToY, treeViewPort, self.build)
		self.jumpToNode = false
	end
	self.viewer.compareSpec = self.isComparing and self.specList[self.activeCompareSpec] or nil
	self.viewer:Draw(self.build, treeViewPort, inputEvents)

	local newSpecList = self:GetSpecList()
	self.controls.compareSelect.selIndex = self.activeCompareSpec
	self.controls.compareSelect:SetList(newSpecList)
	t_insert(newSpecList, "Manage trees... (ctrl-m)")
	self.controls.specSelect.selIndex = self.activeSpec
	self.controls.specSelect:SetList(newSpecList)

	if not self.controls.treeSearch.hasFocus then
		self.controls.treeSearch:SetText(self.viewer.searchStr)
	end

	self.controls.treeHeatMap.state = self.viewer.showHeatMap
	self.controls.treeHeatMapStatSelect.shown = self.viewer.showHeatMap
	self.controls.treeHeatMapStatSelect.list = self.powerStatList
	self.controls.treeHeatMapStatSelect.selIndex = 1
	self.controls.treeHeatMapStatSelect:CheckDroppedWidth(true)
	if self.build.calcsTab.powerStat then
		self.controls.treeHeatMapStatSelect:SelByValue(self.build.calcsTab.powerStat.stat, "stat")
	end

	SetDrawLayer(1)

	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (28 + bottomDrawerHeight + twoLineHeight), viewPort.width, 28 + bottomDrawerHeight + twoLineHeight)
	if self.showConvert then
		local height = viewPort.width < convertMaxWidth and (bottomDrawerHeight + twoLineHeight) or 0
		SetDrawColor(0.05, 0.05, 0.05)
		DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (60 + bottomDrawerHeight + twoLineHeight + convertTwoLineHeight), viewPort.width, 28 + height)
		SetDrawColor(0.85, 0.85, 0.85)
		DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (64 + bottomDrawerHeight + twoLineHeight + convertTwoLineHeight), viewPort.width, 4)
	end
	-- let white lines overwrite the black sections, regardless of showConvert
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (32 + bottomDrawerHeight + twoLineHeight), viewPort.width, 4)

	self:DrawControls(viewPort)
end

function TreeTabClass:GetSpecList()
	local newSpecList = { }
	for _, spec in ipairs(self.specList) do
		t_insert(newSpecList, (spec.treeVersion ~= latestTreeVersion and ("["..treeVersions[spec.treeVersion].display.."] ") or "")..(spec.title or "Default"))
	end
	return newSpecList
end

function TreeTabClass:Load(xml, dbFileName)
	self.specList = { }
	if xml.elem == "Spec" then
		-- Import single spec from old build
		self.specList[1] = new("PassiveSpec", self.build, defaultTreeVersion)
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
				local newSpec = new("PassiveSpec", self.build, node.attrib.treeVersion or defaultTreeVersion)
				newSpec:Load(node, dbFileName)
				t_insert(self.specList, newSpec)
			end
		end
	end
	if not self.specList[1] then
		self.specList[1] = new("PassiveSpec", self.build, latestTreeVersion)
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
		local child = {
			elem = "Spec"
		}
		spec:Save(child)
		t_insert(xml, child)
	end
end

function TreeTabClass:SetActiveSpec(specId)
	local prevSpec = self.build.spec
	self.activeSpec = m_min(specId, #self.specList)
	local curSpec = self.specList[self.activeSpec]
	data.setJewelRadiiGlobally(curSpec.treeVersion)
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
			else
				-- Unsocket the old jewel from the previous spec
				slot.selItemId = 0
			end
		end
	end
	self.showConvert = not curSpec.treeVersion:match("^" .. latestTreeVersion)
	if self.build.itemsTab.itemOrderList[1] then
		-- Update item slots if items have been loaded already
		self.build.itemsTab:PopulateSlots()
	end
	-- Update the passive tree dropdown control in itemsTab
	self.build.itemsTab.controls.specSelect.selIndex = specId
	-- Update Version dropdown to active spec's
	if self.controls.versionSelect then
		self.controls.versionSelect:SelByValue(curSpec.treeVersion:gsub("%_", "."):gsub(".ruthless", " (ruthless)"))
	end
end

function TreeTabClass:SetCompareSpec(specId)
	self.activeCompareSpec = m_min(specId, #self.specList)
	local curSpec = self.specList[self.activeCompareSpec]

	self.compareSpec = curSpec
end

function TreeTabClass:ConvertToVersion(version, remove, success, ignoreRuthlessCheck)
	if not ignoreRuthlessCheck and self.build.spec.treeVersion:match("ruthless") and not version:match("ruthless") then
		if isValueInTable(treeVersionList, version.."_ruthless") then
			version = version.."_ruthless"
		end
	end
	local newSpec = new("PassiveSpec", self.build, version)
	newSpec.title = self.build.spec.title
	newSpec.jewels = copyTable(self.build.spec.jewels)
	newSpec:RestoreUndoState(self.build.spec:CreateUndoState(), version)
	newSpec:BuildClusterJewelGraphs()
	t_insert(self.specList, self.activeSpec + 1, newSpec)
	if remove then
		t_remove(self.specList, self.activeSpec)
		-- activeSpec + 1 is shifted down one on remove, otherwise we would set the spec below it if it exists
		self:SetActiveSpec(self.activeSpec)
	else
		self:SetActiveSpec(self.activeSpec + 1)
	end
	self.modFlag = true
	if success then
		main:OpenMessagePopup("Tree Converted", "The tree has been converted to "..treeVersions[version].display..".\nNote that some or all of the passives may have been de-allocated due to changes in the tree.\n\nYou can switch back to the old tree using the tree selector at the bottom left.")
	end
end

function TreeTabClass:ConvertAllToVersion(version)
	local currActiveSpec = self.activeSpec
	local specVersionList = { }
	for _, spec in ipairs(self.specList) do
		t_insert(specVersionList, spec.treeVersion)
	end
	for index, specVersion in ipairs(specVersionList) do
		if specVersion ~= version then
			self:SetActiveSpec(index)
			self:ConvertToVersion(version, true, false)
		end
	end
	self:SetActiveSpec(currActiveSpec)
end

function TreeTabClass:OpenSpecManagePopup()
	local importTree =
		new("ButtonControl", nil, -99, 259, 90, 20, "Import Tree", function()
			self:OpenImportPopup()
		end)
	local exportTree =
		new("ButtonControl", { "LEFT", importTree, "RIGHT" }, 8, 0, 90, 20, "Export Tree", function()
			self:OpenExportPopup()
		end)

	main:OpenPopup(370, 290, "Manage Passive Trees", {
		new("PassiveSpecListControl", nil, 0, 50, 350, 200, self),
		importTree,
		exportTree,
		new("ButtonControl", {"LEFT", exportTree, "RIGHT"}, 8, 0, 90, 20, "Done", function()
			main:ClosePopup()
		end),
	})
end

function TreeTabClass:OpenVersionConvertPopup(version, ignoreRuthlessCheck)
	local controls = { }
	controls.warningLabel = new("LabelControl", nil, 0, 20, 0, 16, "^7Warning: some or all of the passives may be de-allocated due to changes in the tree.\n\n" ..
		"Convert will replace your current tree.\nCopy + Convert will backup your current tree.\n")
	controls.convert = new("ButtonControl", nil, -125, 105, 100, 20, "Convert", function()
		self:ConvertToVersion(version, true, false, ignoreRuthlessCheck)
		main:ClosePopup()
	end)
	controls.convertCopy = new("ButtonControl", nil, 0, 105, 125, 20, "Copy + Convert", function()
		self:ConvertToVersion(version, false, false, ignoreRuthlessCheck)
		main:ClosePopup()
	end)
	controls.cancel = new("ButtonControl", nil, 125, 105, 100, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(570, 140, "Convert to Version "..treeVersions[version].display, controls, "convert", "edit")
end

function TreeTabClass:OpenVersionConvertAllPopup(version)
	local controls = { }
	controls.warningLabel = new("LabelControl", nil, 0, 20, 0, 16, "^7Warning: some or all of the passives may be de-allocated due to changes in the tree.\n\n" ..
		"Convert will replace all trees that are not Version "..treeVersions[version].display..".\nThis action cannot be undone.\n")
	controls.convert = new("ButtonControl", nil, -58, 105, 100, 20, "Convert", function()
		self:ConvertAllToVersion(version)
		main:ClosePopup()
	end)
	controls.cancel = new("ButtonControl", nil, 58, 105, 100, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(570, 140, "Convert all to Version "..treeVersions[version].display, controls, "convert", "edit")
end

function TreeTabClass:OpenImportPopup()
	local versionLookup = "tree/([0-9]+)%.([0-9]+)%.([0-9]+)/"
	local controls = { }
	local function decodePoePlannerTreeLink(treeLink)
		-- treeVersion is not known at this point. We need to decode the URL to get it.
		local tmpSpec = new("PassiveSpec", self.build, latestTreeVersion)
		local newTreeVersion_or_errMsg = tmpSpec:DecodePoePlannerURL(treeLink, true)
		-- Check for an error message
		if string.find(newTreeVersion_or_errMsg, "Invalid") then
			controls.msg.label = "^1"..newTreeVersion_or_errMsg
			return
		end

		-- 20230908. We always create a new Spec()
		local newSpec = new("PassiveSpec", self.build, newTreeVersion_or_errMsg)
		newSpec.title = controls.name.buf
		newSpec:DecodePoePlannerURL(treeLink, false)  --DecodePoePlannerURL was used above and URL proven correct.
		t_insert(self.specList, newSpec)
		-- trigger all the things that go with changing a spec
		self:SetActiveSpec(#self.specList)
		self.modFlag = true
		self.build.spec:AddUndoState()
		self.build.buildFlag = true
		main:ClosePopup()
	end

	local function decodeTreeLink(treeLink, newTreeVersion)
		-- newTreeVersion is passed in as an output of validateTreeVersion(). It will always be a valid tree version text string
		-- 20230908. We always create a new Spec()
		local newSpec = new("PassiveSpec", self.build, newTreeVersion)
		newSpec.title = controls.name.buf
		local errMsg = newSpec:DecodeURL(treeLink)
		if errMsg then
			controls.msg.label = "^1"..errMsg.."^7"
		else
			t_insert(self.specList, newSpec)
			-- trigger all the things that go with changing a spec
			self:SetActiveSpec(#self.specList)
			self.modFlag = true
			self.build.spec:AddUndoState()
			self.build.buildFlag = true
			main:ClosePopup()
		end
	end
	local function validateTreeVersion(isRuthless, major, minor)
		-- Take the Major and Minor version numbers and confirm it is a valid tree version. The point release is also passed in but it is not used
		-- Return: the passed in tree version as text or latestTreeVersion
		if major and minor then
			--need leading 0 here
			local newTreeVersionNum = tonumber(string.format("%d.%02d", major, minor))
			if newTreeVersionNum >= treeVersions[defaultTreeVersion].num and newTreeVersionNum <= treeVersions[latestTreeVersion].num then
				-- no leading 0 here
				return string.format("%s_%s", major, minor) .. (isRuthless and "_ruthless" or "")
			else
				print(string.format("Version '%d_%02d' is out of bounds", major, minor))
			end
		end
		return latestTreeVersion .. (isRuthless and "_ruthless" or "")
	end

	controls.nameLabel = new("LabelControl", nil, -180, 20, 0, 16, "Enter name for this passive tree:")
	controls.name = new("EditControl", nil, 100, 20, 350, 18, "", nil, nil, nil, function(buf)
		controls.msg.label = ""
		controls.import.enabled = buf:match("%S") and controls.edit.buf:match("%S")
	end)
	controls.editLabel = new("LabelControl", nil, -150, 45, 0, 16, "Enter passive tree link:")
	controls.edit = new("EditControl", nil, 100, 45, 350, 18, "", nil, nil, nil, function(buf)
		controls.msg.label = ""
		controls.import.enabled = buf:match("%S") and controls.name.buf:match("%S")
	end)
	controls.msg = new("LabelControl", nil, 0, 65, 0, 16, "")
	controls.import = new("ButtonControl", nil, -45, 85, 80, 20, "Import", function()
		local treeLink = controls.edit.buf
		if #treeLink == 0 then
			return
		end
		-- EG: http://poeurl.com/dABz
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
						controls.msg.label = "^1"..errMsg.."^7"
						controls.import.enabled = true
						return
					else
						decodeTreeLink(treeLink, validateTreeVersion(treeLink:match("tree/ruthless"), treeLink:match(versionLookup)))
					end
				end)
			end
		elseif treeLink:match("poeplanner.com/") then
			decodePoePlannerTreeLink(treeLink:gsub("/%?v=.+#","/"))
		elseif treeLink:match("poeskilltree.com/") then
			local oldStyleVersionLookup = "/%?v=([0-9]+)%.([0-9]+)%.([0-9]+)%-?r?u?t?h?l?e?s?s?#"
			-- Strip the version from the tree : https://poeskilltree.com/?v=3.6.0#AAAABAMAABEtfIOFMo6-ksHfsOvu -> https://poeskilltree.com/AAAABAMAABEtfIOFMo6-ksHfsOvu
			decodeTreeLink(treeLink:gsub("/%?v=.+#","/"), validateTreeVersion(treeLink:match("-ruthless#"), treeLink:match(oldStyleVersionLookup)))
		else
			-- EG: https://www.pathofexile.com/passive-skill-tree/3.15.0/AAAABgMADI6-HwKSwQQHLJwtH9-wTLNfKoP3ES3r5AAA
			-- EG: https://www.pathofexile.com/fullscreen-passive-skill-tree/3.15.0/AAAABgMADAQHES0fAiycLR9Ms18qg_eOvpLB37Dr5AAA
			-- EG: https://www.pathofexile.com/passive-skill-tree/ruthless/AAAABgAAAAAA (Ruthless doesn't have versions)
			decodeTreeLink(treeLink, validateTreeVersion(treeLink:match("tree/ruthless"), treeLink:match(versionLookup)))
		end
	end)
	controls.import.enabled = false
	controls.cancel = new("ButtonControl", nil, 45, 85, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(580, 115, "Import Tree", controls, "import", "name")
end

function TreeTabClass:OpenExportPopup()
	local treeLink = self.build.spec:EncodeURL(treeVersions[self.build.spec.treeVersion].url)
	local popup
	local controls = { }
	controls.label = new("LabelControl", nil, 0, 20, 0, 16, "Passive tree link:")
	controls.edit = new("EditControl", nil, 0, 40, 350, 18, treeLink, nil, "%Z")
	controls.shrink = new("ButtonControl", nil, -90, 70, 140, 20, "Shrink with PoEURL", function()
		controls.shrink.enabled = false
		controls.shrink.label = "Shrinking..."
		launch:DownloadPage("http://poeurl.com/shrink.php?url="..treeLink, function(response, errMsg)
			controls.shrink.label = "Done"
			if errMsg or not response.body:match("%S") then
				main:OpenMessagePopup("PoEURL Shortener", "Failed to get PoEURL link. Try again later.")
			else
				treeLink = "http://poeurl.com/"..response.body
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

function TreeTabClass:ModifyNodePopup(selectedNode)
	local controls = { }
	local modGroups = { }
	local function buildMods(selectedNode)
		wipeTable(modGroups)
		local treeNodes = self.build.spec.tree.nodes
		local numLinkedNodes = selectedNode.linkedId and #selectedNode.linkedId or 0
		local nodeName = treeNodes[selectedNode.id].dn
		local nodeValue = treeNodes[selectedNode.id].sd[1]
		for id, node in pairs(self.build.spec.tree.tattoo.nodes) do
			if (nodeName:match(node.targetType:gsub("^Small ", "")) or (node.targetValue ~= "" and nodeValue:match(node.targetValue)) or
					(node.targetType == "Small Attribute" and (nodeName == "Intelligence" or nodeName == "Strength" or nodeName == "Dexterity"))
					or (node.targetType == "Keystone" and treeNodes[selectedNode.id].type == node.targetType))
					and node.MinimumConnected <= numLinkedNodes then
				local combine = false
				for id, desc in pairs(node.stats) do
					combine = (id:match("^local_display.*") and #node.stats == (#node.sd - 1)) or combine
					if combine then break end
				end
				local descriptionsAndReminders = copyTable(node.sd)
				if combine then
					t_remove(descriptionsAndReminders, 1)
					t_remove(descriptionsAndReminders, 1)
					t_insert(descriptionsAndReminders, 1, node.sd[1] .. " " .. node.sd[2])
				end
				local descriptionsAndReminders = combine and { [1] = table.concat(node.sd, " ") } or copyTable(node.sd)
				if node.reminderText then
					t_insert(descriptionsAndReminders, node.reminderText[1])
				end
				t_insert(modGroups, {
				label = node.dn .. "                                                " .. table.concat(node.sd, ","),
				descriptions = descriptionsAndReminders,
				id = id,
				})
			end
		end
		table.sort(modGroups, function(a, b) return a.label < b.label end)
		end
	local function addModifier(selectedNode)
		local newTattooNode = self.build.spec.tree.tattoo.nodes[modGroups[controls.modSelect.selIndex].id]
		newTattooNode.id = selectedNode.id
		self.build.spec.hashOverrides[selectedNode.id] = newTattooNode
		self.build.spec:ReplaceNode(selectedNode, newTattooNode)
		self.build.spec:BuildAllDependsAndPaths()
	end

	local function constructUI(modGroup)
		local totalHeight = 43
		local maxWidth = 375
		local i = 1
		while controls[i] do
			controls[i] = nil
			i = i + 1
		end

		local wrapTable = {}
		for idx, desc in ipairs(modGroup.descriptions) do
			for _, wrappedDesc in ipairs(main:WrapString(desc, 16, maxWidth)) do
				t_insert(wrapTable, wrappedDesc)
			end
		end
		for idx, desc in ipairs(wrapTable) do
			controls[idx] = new("LabelControl", {"TOPLEFT", controls[idx-1] or controls.modSelect,"TOPLEFT"}, 0, 20, 600, 16, "^7"..desc)
			totalHeight = totalHeight + 20
		end
		main.popups[1].height = totalHeight + 30
		controls.save.y = totalHeight
		controls.reset.y = totalHeight
		controls.close.y = totalHeight
	end

	buildMods(selectedNode)
	controls.modSelectLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 150, 25, 0, 16, "^7Modifier:")
	controls.modSelect = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 155, 25, 250, 18, modGroups, function(idx) constructUI(modGroups[idx]) end)
	controls.modSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" and value then
			for _, line in ipairs(value.descriptions) do
				tooltip:AddLine(16, "^7"..line)
			end
		end
	end
	controls.save = new("ButtonControl", nil, -90, 75, 80, 20, "Add", function()
		addModifier(selectedNode)
		self.modFlag = true
		self.build.buildFlag = true
		main:ClosePopup()
	end)
	controls.reset = new("ButtonControl", nil, 0, 75, 80, 20, "Reset Node", function()
		self.build.spec.tree.nodes[selectedNode.id].isTattoo = false
		self.build.spec.hashOverrides[selectedNode.id] = nil
		self.build.spec:ReplaceNode(selectedNode, self.build.spec.tree.nodes[selectedNode.id])
		self.build.spec:BuildAllDependsAndPaths()
		self.modFlag = true
		self.build.buildFlag = true
		main:ClosePopup()
	end)
	controls.close = new("ButtonControl", nil, 90, 75, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(600, 105, "Replace Modifier of Node", controls, "save")
	constructUI(modGroups[1])
end

function TreeTabClass:SaveMasteryPopup(node, listControl)
		if listControl.selValue == nil then
			return
		end
		local effect = self.build.spec.tree.masteryEffects[listControl.selValue.id]
		node.sd = effect.sd
		node.allMasteryOptions = false
		node.reminderText = { "Tip: Right click to select a different effect" }
		self.build.spec.tree:ProcessStats(node)
		self.build.spec.masterySelections[node.id] = effect.id
		if not node.alloc then
			self.build.spec:AllocNode(node, self.viewer.tracePath and node == self.viewer.tracePath[#self.viewer.tracePath] and self.viewer.tracePath)
		end
		self.build.spec:AddUndoState()
		self.modFlag = true
		self.build.buildFlag = true
		main:ClosePopup()
end

function TreeTabClass:OpenMasteryPopup(node, viewPort)
	local controls = { }
	local effects = { }
	local cachedSd = node.sd
	local cachedAllMasteryOption = node.allMasteryOptions

	wipeTable(effects)
	for _, effect in pairs(node.masteryEffects) do
		local assignedNodeId = isValueInTable(self.build.spec.masterySelections, effect.effect)
		if not assignedNodeId or assignedNodeId == node.id then
			t_insert(effects, {label = t_concat(effect.stats, " / "), id = effect.effect})
		end
	end
	--Check to make sure that the effects list has a potential mod to apply to a mastery
	if not (next(effects) == nil) then
		local passiveMasteryControlHeight = (#effects + 1) * 14 + 2
		controls.close =  new("ButtonControl", nil, 0, 30 + passiveMasteryControlHeight, 90, 20, "Cancel", function()
			node.sd = cachedSd
			node.allMasteryOptions = cachedAllMasteryOption
			self.build.spec.tree:ProcessStats(node)
			main:ClosePopup()
		end)
		controls.effect = new("PassiveMasteryControl", {"TOPLEFT",nil,"TOPLEFT"}, 6, 25, 0, passiveMasteryControlHeight, effects, self, node, controls.save)
		main:OpenPopup(controls.effect.width + 12, controls.effect.height + 60, node.name, controls)
	end
end

function TreeTabClass:SetPowerCalc(powerStat)
	self.viewer.showHeatMap = true
	self.build.buildFlag = true
	self.build.calcsTab.powerBuildFlag = true
	self.build.calcsTab.powerStat = powerStat
	self.controls.powerReportList:SetReport(powerStat, nil)
end

function TreeTabClass:BuildPowerReportList(currentStat)
	local report = {}

	if not (currentStat and currentStat.stat) then
		return report
	end

	-- locate formatting information for the type of heat map being used.
	-- maybe a better place to find this? At the moment, it is the only place
	-- in the code that has this information in a tidy place.
	local displayStat = nil

	for index, ds in ipairs(self.build.displayStats) do
		if ds.stat == currentStat.stat then
			displayStat = ds
			break
		end
	end

	-- not every heat map has an associated "stat" in the displayStats table
	-- this is due to not every stat being displayed in the sidebar, I believe.
	-- But, we do want to use the formatting knowledge stored in that table rather than duplicating it here.
	-- If no corresponding stat is found, just default to a generic stat display (>0=good, one digit of precision).
	if not displayStat then
		displayStat = {
			fmt = ".1f"
		}
	end

	-- search all nodes, ignoring ascendancies, sockets, etc.
	for nodeId, node in pairs(self.build.spec.nodes) do
		local isAlloc = node.alloc or self.build.calcsTab.mainEnv.grantedPassives[nodeId]
		if (node.type == "Normal" or node.type == "Keystone" or node.type == "Notable") and not node.ascendancyName then
			local pathDist
			if isAlloc then
				pathDist = #(node.depends or { }) == 0 and 1 or #node.depends
			else
				pathDist = #(node.path or { }) == 0 and 1 or #node.path
			end
			local nodePower = (node.power.singleStat or 0) * ((displayStat.pc or displayStat.mod) and 100 or 1)
			local pathPower = (node.power.pathPower or 0) / pathDist * ((displayStat.pc or displayStat.mod) and 100 or 1)
			local nodePowerStr = s_format("%"..displayStat.fmt, nodePower)
			local pathPowerStr = s_format("%"..displayStat.fmt, pathPower)

			nodePowerStr = formatNumSep(nodePowerStr)
			pathPowerStr = formatNumSep(pathPowerStr)

			if (nodePower > 0 and not displayStat.lowerIsBetter) or (nodePower < 0 and displayStat.lowerIsBetter) then
				nodePowerStr = colorCodes.POSITIVE .. nodePowerStr
			elseif (nodePower < 0 and not displayStat.lowerIsBetter) or (nodePower > 0 and displayStat.lowerIsBetter) then
				nodePowerStr = colorCodes.NEGATIVE .. nodePowerStr
			end
			if (pathPower > 0 and not displayStat.lowerIsBetter) or (pathPower < 0 and displayStat.lowerIsBetter) then
				pathPowerStr = colorCodes.POSITIVE .. pathPowerStr
			elseif (pathPower < 0 and not displayStat.lowerIsBetter) or (pathPower > 0 and displayStat.lowerIsBetter) then
				pathPowerStr = colorCodes.NEGATIVE .. pathPowerStr
			end

			t_insert(report, {
				name = node.dn,
				power = nodePower,
				powerStr = nodePowerStr,
				pathPower = pathPower,
				pathPowerStr = pathPowerStr,
				allocated = isAlloc,
				id = node.id,
				x = node.x,
				y = node.y,
				type = node.type,
				pathDist = pathDist
			})
		end
	end

	-- search all cluster notables and add to the list
	for nodeName, node in pairs(self.build.spec.tree.clusterNodeMap) do
		local isAlloc = node.alloc
		if not isAlloc then
			local nodePower = (node.power and node.power.singleStat or 0) * ((displayStat.pc or displayStat.mod) and 100 or 1)
			local nodePowerStr = s_format("%"..displayStat.fmt, nodePower)

			nodePowerStr = formatNumSep(nodePowerStr)

			if (nodePower > 0 and not displayStat.lowerIsBetter) or (nodePower < 0 and displayStat.lowerIsBetter) then
				nodePowerStr = colorCodes.POSITIVE .. nodePowerStr
			elseif (nodePower < 0 and not displayStat.lowerIsBetter) or (nodePower > 0 and displayStat.lowerIsBetter) then
				nodePowerStr = colorCodes.NEGATIVE .. nodePowerStr
			end

			t_insert(report, {
				name = node.dn,
				power = nodePower,
				powerStr = nodePowerStr,
				pathPower = 0,
				pathPowerStr = "--",
				id = node.id,
				type = node.type,
				pathDist = "Cluster"
			})
		end
	end

	-- sort it
	if displayStat.lowerIsBetter then
		t_sort(report, function (a,b)
			return a.power < b.power
		end)
	else
		t_sort(report, function (a,b)
			return a.power > b.power
		end)
	end

	return report
end

function TreeTabClass:FindTimelessJewel()
	local socketViewer = new("PassiveTreeView")
	local treeData = self.build.spec.tree
	local legionNodes = treeData.legion.nodes
	local legionAdditions = treeData.legion.additions
	local timelessData = self.build.timelessData
	local controls = { }
	local modData = { }
	local ignoredMods = { "Might of the Vaal", "Legacy of the Vaal", "Strength", "Add Strength", "Dex", "Add Dexterity", "Devotion", "Price of Glory" }
	local totalMods = { [2] = "Strength", [3] = "Dexterity", [4] = "Devotion" }
	local totalModIDs = {
		["total_strength"] = { ["karui_notable_add_strength"] = true, ["karui_attribute_strength"] = true, ["karui_small_strength"] = true },
		["total_dexterity"] = { ["maraketh_notable_add_dexterity"] = true, ["maraketh_attribute_dex"] = true, ["maraketh_small_dex"] = true },
		["total_devotion"] = { ["templar_notable_devotion"] = true, ["templar_devotion_node"] = true, ["templar_small_devotion"] = true }
	}
	local reverseTotalModIDs = {
		["karui_notable_add_strength"] = true,
		["karui_attribute_strength"] = true,
		["karui_small_strength"] = true,
		["maraketh_notable_add_dexterity"] = true,
		["maraketh_attribute_dex"] = true,
		["maraketh_small_dex"] = true,
		["templar_notable_devotion"] = true,
		["templar_devotion_node"] = true,
		["templar_small_devotion"] = true
	}
	local jewelTypes = {
		{ label = "Glorious Vanity", name = "vaal", id = 1 },
		{ label = "Lethal Pride", name = "karui", id = 2 },
		{ label = "Brutal Restraint", name = "maraketh", id = 3 },
		{ label = "Militant Faith", name = "templar", id = 4 },
		{ label = "Elegant Hubris", name = "eternal", id = 5 }
	}
	-- rebuild `timelessData.jewelType` as we only store the minimum amount of `jewelType` data in build XML
	if next(timelessData.jewelType) then
		for idx, jewelType in ipairs(jewelTypes) do
			if jewelType.id == timelessData.jewelType.id then
				timelessData.jewelType = jewelType
				break
			end
		end
	else
		timelessData.jewelType = jewelTypes[1]
	end
	local conquerorTypes = {
		[1] = {
			{ label = "Any", id = 1 },
			{ label = "Doryani (Corrupted Soul)", id = 2 },
			{ label = "Xibaqua (Divine Flesh)", id = 3 },
			{ label = "Ahuana (Immortal Ambition)", id = 4 }
		},
		[2] = {
			{ label = "Any", id = 1 },
			{ label = "Kaom (Strength of Blood)", id = 2 },
			{ label = "Rakiata (Tempered by War)", id = 3 },
			{ label = "Akoya (Chainbreaker)", id = 4 }
		},
		[3] = {
			{ label = "Any", id = 1 },
			{ label = "Asenath (Dance with Death)", id = 2 },
			{ label = "Nasima (Second Sight)", id = 3 },
			{ label = "Balbala (The Traitor)", id = 4 }
		},
		[4] = {
			{ label = "Any", id = 1 },
			{ label = "Avarius (Power of Purpose)", id = 2 },
			{ label = "Dominus (Inner Conviction)", id = 3 },
			{ label = "Maxarius (Transcendence)", id = 4 }
		},
		[5] = {
			{ label = "Any", id = 1 },
			{ label = "Cadiro (Supreme Decadence)", id = 2 },
			{ label = "Victario (Supreme Grandstanding)", id = 3 },
			{ label = "Caspiro (Supreme Ostentation)", id = 4 }
		}
	}
	-- rebuild `timelessData.conquerorType` as we only store the minimum amount of `conquerorType` data in build XML
	if next(timelessData.conquerorType) then
		for idx, conquerorType in ipairs(conquerorTypes[timelessData.jewelType.id]) do
			if conquerorType.id == timelessData.conquerorType.id then
				timelessData.conquerorType = conquerorType
				break
			end
		end
	else
		timelessData.conquerorType = conquerorTypes[timelessData.jewelType.id][1]
	end
	local devotionVariants = {
		{ id = 1 , label = "Any" },
		{ id = 2 , label = "Totem Damage" },
		{ id = 3 , label = "Brand Damage" },
		{ id = 4 , label = "Channelling Damage" },
		{ id = 5 , label = "Area Damage" },
		{ id = 6 , label = "Elemental Damage" },
		{ id = 7 , label = "Elemental Resistances" },
		{ id = 8 , label = "Effect of non-Damaging Ailments" },
		{ id = 9 , label = "Elemental Ailment Duration" },
		{ id = 10, label = "Duration of Curses" },
		{ id = 11, label = "Minion Attack and Cast Speed" },
		{ id = 12, label = "Minions Accuracy Rating" },
		{ id = 13, label = "Mana Regen" },
		{ id = 14, label = "Skill Cost" },
		{ id = 15, label = "Non-Curse Aura Effect" },
		{ id = 16, label = "Defences from Shield" }
	}
	local jewelSockets = { }
	for socketId, socketData in pairs(self.build.spec.nodes) do
		if socketData.isJewelSocket and socketData.name ~= "Charm Socket"then
			local keystone = "Unknown"
			if socketId == 26725 then
				keystone = "Marauder"
			elseif socketId == 54127 then
				keystone = "Duelist"
			elseif socketId == 7960 then
				keystone = "Templar/Witch"
			else
				local minDistance = math.huge
				for _, nodeInRadius in pairs(treeData.nodes[socketId].nodesInRadius[3]) do
					if nodeInRadius.isKeystone then
						local distance = math.sqrt((nodeInRadius.x - socketData.x) ^ 2 + (nodeInRadius.y - socketData.y) ^ 2)
						if distance < minDistance then
							keystone = nodeInRadius.name
							minDistance = distance
						end
					end
				end
			end
			local label = keystone .. ": " .. socketId
			if self.build.spec.allocNodes[socketId] then
				label = "# " .. label
			end
			t_insert(jewelSockets, {
				label = label,
				keystone = keystone,
				id = socketId
			})
		end
	end
	t_sort(jewelSockets, function(a, b) return a.label < b.label end)
	-- rebuild `timelessData.jewelSocket` as we only store the minimum amount of `jewelSocket` data in build XML
	if next(timelessData.jewelSocket) then
		for idx, jewelSocket in ipairs(jewelSockets) do
			if jewelSocket.id == timelessData.jewelSocket.id then
				timelessData.jewelSocket = jewelSocket
				break
			end
		end
	else
		timelessData.jewelSocket = jewelSockets[1]
	end

	local function buildMods()
		wipeTable(modData)
		local smallModData = { }
		for _, node in pairs(legionNodes) do
			if node.id:match("^" .. timelessData.jewelType.name .. "_.+") and not isValueInArray(ignoredMods, node.dn) and not node.ks then
				if node["not"] then
					t_insert(modData, {
						label = node.dn .. "                                                " .. node.sd[1],
						descriptions = copyTable(node.sd),
						type = timelessData.jewelType.name,
						id = node.id
					})
					if node.sd[2] then
						modData[#modData].label = modData[#modData].label .. " " .. node.sd[2]
					end
				else
					t_insert(smallModData, {
						label = node.dn,
						descriptions = copyTable(node.sd),
						type = timelessData.jewelType.name,
						id = node.id
					})
				end
			end
		end
		for _, addition in pairs(legionAdditions) do
			-- exclude passives that are already added (vaal, attributes, devotion)
			if addition.id:match("^" .. timelessData.jewelType.name .. "_.+") and not isValueInArray(ignoredMods, addition.dn) and timelessData.jewelType.name ~= "vaal" then
				t_insert(modData, {
					label = addition.dn,
					descriptions = copyTable(addition.sd),
					type = timelessData.jewelType.name,
					id = addition.id
				})
			end
		end
		t_sort(modData, function(a, b) return a.label < b.label end)
		t_sort(smallModData, function (a, b) return a.label < b.label end)
		if totalMods[timelessData.jewelType.id] then
			t_insert(modData, 1, {
				label = "Total " .. totalMods[timelessData.jewelType.id],
				descriptions = { "This is a hybrid node containing all additions to " .. totalMods[timelessData.jewelType.id] },
				type = timelessData.jewelType.name,
				id = "total_" .. totalMods[timelessData.jewelType.id]:lower(),
				totalMod = true
			})
		end
		t_insert(modData, 1, { label = "..." })
		for i = 1, #smallModData do
			modData[#modData + 1] = smallModData[i]
		end
	end

	local function getNodeWeights()
		local nodeWeights = {
			[1] = controls.nodeSliderValue.label:sub(3):lower(),
			[2] = controls.nodeSlider2Value.label:sub(3):lower(),
			[3] = controls.nodeSlider3Value.label:sub(3):lower()
		}
		for i, nodeWeight in ipairs(nodeWeights) do
			if tonumber(nodeWeight) ~= nil then
				nodeWeights[i] = round(tonumber(nodeWeight), 3)
			end
		end
		return nodeWeights
	end

	local searchListTbl = { }
	local searchListFallbackTbl = { }
	local function parseSearchList(mode, fallback)
		if mode == 0 then
			if fallback then
				-- timelessData.searchListFallback => searchListFallbackTbl
				if timelessData.searchListFallback then
					searchListFallbackTbl = { }
					for inputLine in timelessData.searchListFallback:gmatch("[^\r\n]+") do
						searchListFallbackTbl[#searchListFallbackTbl + 1] = { }
						for splitLine in inputLine:gmatch("([^,%s]+)") do
							searchListFallbackTbl[#searchListFallbackTbl][#searchListFallbackTbl[#searchListFallbackTbl] + 1] = splitLine
						end
					end
				end
			else
				-- timelessData.searchList => searchListTbl
				if timelessData.searchList then
					searchListTbl = { }
					for inputLine in timelessData.searchList:gmatch("[^\r\n]+") do
						searchListTbl[#searchListTbl + 1] = { }
						for splitLine in inputLine:gmatch("([^,%s]+)") do
							searchListTbl[#searchListTbl][#searchListTbl[#searchListTbl] + 1] = splitLine
						end
					end
				end
			end
		else
			if fallback then
				-- searchListFallbackTbl => controls.searchListFallback
				if controls.searchListFallback and controls.nodeSelect then
					local searchText = ""
					for _, curRow in ipairs(searchListFallbackTbl) do
						if curRow[1] == controls.nodeSelect.list[controls.nodeSelect.selIndex].id then
							local nodeWeights = getNodeWeights()
							curRow[2] = nodeWeights[1]
							curRow[3] = nodeWeights[2]
							curRow[4] = nodeWeights[3]
						end
						if #searchText > 0 then
							searchText = searchText .. "\n"
						end
						searchText = searchText .. t_concat(curRow, ", ")
					end
					if timelessData.searchListFallback ~= searchText then
						timelessData.searchListFallback = searchText
						controls.searchListFallback:SetText(searchText)
						self.build.modFlag = true
					end
				end
			else
				-- searchListTbl => controls.searchList
				if controls.searchList and controls.nodeSelect then
					local searchText = ""
					for _, curRow in ipairs(searchListTbl) do
						if curRow[1] == controls.nodeSelect.list[controls.nodeSelect.selIndex].id then
							local nodeWeights = getNodeWeights()
							curRow[2] = nodeWeights[1]
							curRow[3] = nodeWeights[2]
							curRow[4] = nodeWeights[3]
						end
						if #searchText > 0 then
							searchText = searchText .. "\n"
						end
						searchText = searchText .. t_concat(curRow, ", ")
					end
					if timelessData.searchList ~= searchText then
						timelessData.searchList = searchText
						controls.searchList:SetText(searchText)
						self.build.modFlag = true
					end
				end
			end
		end
	end
	parseSearchList(0, false) -- initial load: [timelessData.searchList => searchListTbl]
	parseSearchList(0, true)  -- initial load: [timelessData.searchListFallback => searchListFallbackTbl]
	local function updateSearchList(text, fallback)
		if fallback then
			timelessData.searchListFallback = text
			controls.searchListFallback:SetText(text)
		else
			timelessData.searchList = text
			controls.searchList:SetText(text)
		end
		parseSearchList(0, fallback)
		self.build.modFlag = true
	end

	controls.devotionSelectLabel = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 820, 25, 0, 16, "^7Devotion modifiers:")
	controls.devotionSelectLabel.shown = timelessData.jewelType.id == 4
	controls.devotionSelect1 = new("DropDownControl", { "TOP", controls.devotionSelectLabel, "BOTTOM" }, 0, 8, 200, 18, devotionVariants, function(index, value)
		timelessData.devotionVariant1 = index
	end)
	controls.devotionSelect1.selIndex = timelessData.devotionVariant1
	controls.devotionSelect2 = new("DropDownControl", { "TOP", controls.devotionSelect1, "BOTTOM" }, 0, 7, 200, 18, devotionVariants, function(index, value)
		timelessData.devotionVariant2 = index
	end)
	controls.devotionSelect2.selIndex = timelessData.devotionVariant2

	controls.jewelSelectLabel = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 405, 25, 0, 16, "^7Jewel Type:")
	controls.jewelSelect = new("DropDownControl", { "LEFT", controls.jewelSelectLabel, "RIGHT" }, 10, 0, 200, 18, jewelTypes, function(index, value)
		timelessData.jewelType = value
		controls.devotionSelectLabel.shown = value.id == 4
		controls.conquerorSelect.list = conquerorTypes[timelessData.jewelType.id]
		controls.conquerorSelect.selIndex = 1
		timelessData.conquerorType = conquerorTypes[timelessData.jewelType.id][1]
		controls.nodeSelect.selIndex = 1
		buildMods()
		updateSearchList("", false)
		updateSearchList("", true)
	end)
	controls.jewelSelect.selIndex = timelessData.jewelType.id

	controls.conquerorSelectLabel = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 405, 50, 0, 16, "^7Conqueror:")
	controls.conquerorSelect = new("DropDownControl", { "LEFT", controls.conquerorSelectLabel, "RIGHT" }, 10, 0, 200, 18, conquerorTypes[timelessData.jewelType.id], function(index, value)
		timelessData.conquerorType = value
		self.build.modFlag = true
	end)
	controls.conquerorSelect.selIndex = timelessData.conquerorType.id

	controls.socketSelectLabel = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 405, 75, 0, 16, "^7Jewel Socket:")
	controls.socketSelect = new("TimelessJewelSocketControl", { "LEFT", controls.socketSelectLabel, "RIGHT" }, 10, 0, 200, 18, jewelSockets, function(index, value)
		timelessData.jewelSocket = value
		self.build.modFlag = true
	end, self.build, socketViewer)
	-- we need to search through `jewelSockets` for the correct `id` as the `idx` can become stale due to dynamic sorting
	for idx, jewelSocket in ipairs(jewelSockets) do
		if jewelSocket.id == timelessData.jewelSocket.id then
			controls.socketSelect.selIndex = idx
			break
		end
	end

	controls.socketFilterLabel = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 405, 100, 0, 16, "^7Filter Nodes:")
	controls.socketFilter = new("CheckBoxControl", { "LEFT", controls.socketFilterLabel, "RIGHT" }, 10, 0, 18, nil, function(value)
		timelessData.socketFilter = value
		self.build.modFlag = true
		controls.socketFilterAdditionalDistanceLabel.shown = value
		controls.socketFilterAdditionalDistance.shown = value
		controls.socketFilterAdditionalDistanceValue.shown = value
	end)
	controls.socketFilter.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		tooltip:AddLine(16, "^7Enable this option to exclude nodes that you do not have allocated on your active passive skill tree.")
		tooltip:AddLine(16, "^7This can be useful if you're never going to path towards those excluded nodes and don't care what happens to them.")
	end
	controls.socketFilter.state = timelessData.socketFilter

	local socketFilterAdditionalDistanceMAX = 10
	controls.socketFilterAdditionalDistanceLabel = new("LabelControl", { "LEFT", controls.socketFilter, "RIGHT" }, 10, 0, 0, 16, "^7Node Distance:")
	controls.socketFilterAdditionalDistance = new("SliderControl", { "LEFT", controls.socketFilterAdditionalDistanceLabel, "RIGHT" }, 10, 0, 66, 18, function(value)
		timelessData.socketFilterDistance = m_floor(value * socketFilterAdditionalDistanceMAX + 0.01)
		controls.socketFilterAdditionalDistanceValue.label = s_format("^7%d", timelessData.socketFilterDistance)
	end, { ["SHIFT"] = 1, ["CTRL"] = 1 / (socketFilterAdditionalDistanceMAX * 2), ["DEFAULT"] = 1 / socketFilterAdditionalDistanceMAX })
	controls.socketFilterAdditionalDistance.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if not controls.socketFilterAdditionalDistance.dragging then
			tooltip:AddLine(16, "^7This controls the maximum amount of points that need to be spent to grab a node before its filtered out")
		end
	end
	controls.socketFilterAdditionalDistance.tooltip.realDraw = controls.socketFilterAdditionalDistance.tooltip.Draw
	controls.socketFilterAdditionalDistance.tooltip.Draw = function(self, x, y, width, height, viewPort)
		local sliderOffsetX = round(184 * (1 - controls.socketFilterAdditionalDistance.val))
		local tooltipWidth, tooltipHeight = self:GetSize()
		if main.screenW >= 1384 - sliderOffsetX then
			return controls.socketFilterAdditionalDistance.tooltip.realDraw(self, x - 8 - sliderOffsetX, y - 4 - tooltipHeight, width, height, viewPort)
		end
		return controls.socketFilterAdditionalDistance.tooltip.realDraw(self, x, y, width, height, viewPort)
	end
	controls.socketFilterAdditionalDistanceValue = new("LabelControl", { "LEFT", controls.socketFilterAdditionalDistance, "RIGHT" }, 5, 0, 0, 16, "^70")
	controls.socketFilterAdditionalDistance:SetVal((timelessData.socketFilterDistance or 0) / socketFilterAdditionalDistanceMAX)
	controls.socketFilterAdditionalDistanceLabel.shown = timelessData.socketFilter
	controls.socketFilterAdditionalDistance.shown = timelessData.socketFilter
	controls.socketFilterAdditionalDistanceValue.shown = timelessData.socketFilter

	local scrollWheelSpeedTbl = { ["SHIFT"] = 0.01, ["CTRL"] = 0.0001, ["DEFAULT"] = 0.001 }
	local scrollWheelSpeedTbl2 = { ["SHIFT"] = 0.2, ["CTRL"] = 0.002, ["DEFAULT"] = 0.02 }

	local nodeSliderStatLabel = "None"
	controls.nodeSliderLabel = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 405, 125, 0, 16, "^7Primary Node Weight:")
	controls.nodeSlider = new("SliderControl", { "LEFT", controls.nodeSliderLabel, "RIGHT" }, 10, 0, 200, 16, function(value)
		controls.nodeSliderValue.label = s_format("^7%.3f", value * 10)
		parseSearchList(1, controls.searchListFallback and controls.searchListFallback.shown or false)
	end, scrollWheelSpeedTbl)
	controls.nodeSlider.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if not controls.nodeSlider.dragging then
			if nodeSliderStatLabel == "None" then
				tooltip:AddLine(16, "^7For nodes with multiple stats this slider controls the weight of the first stat listed.")
			else
				tooltip:AddLine(16, "^7This slider controls the weight of the following stat:")
				tooltip:AddLine(16, "^7        " .. nodeSliderStatLabel)
			end
		end
	end
	controls.nodeSliderValue = new("LabelControl", { "LEFT", controls.nodeSlider, "RIGHT" }, 5, 0, 0, 16, "^71.000")
	controls.nodeSlider.tooltip.realDraw = controls.nodeSlider.tooltip.Draw
	controls.nodeSlider.tooltip.Draw = function(self, x, y, width, height, viewPort)
		local sliderOffsetX = round(184 * (1 - controls.nodeSlider.val))
		local tooltipWidth, tooltipHeight = self:GetSize()
		if main.screenW >= 1338 - sliderOffsetX then
			return controls.nodeSlider.tooltip.realDraw(self, x - 8 - sliderOffsetX, y - 4 - tooltipHeight, width, height, viewPort)
		end
		return controls.nodeSlider.tooltip.realDraw(self, x, y, width, height, viewPort)
	end
	controls.nodeSlider:SetVal(0.1)

	local nodeSlider2StatLabel = "None"
	controls.nodeSlider2Label = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 405, 150, 0, 16, "^7Secondary Node Weight:")
	controls.nodeSlider2 = new("SliderControl", { "LEFT", controls.nodeSlider2Label, "RIGHT" }, 10, 0, 200, 16, function(value)
		controls.nodeSlider2Value.label = s_format("^7%.3f", value * 10)
		parseSearchList(1, controls.searchListFallback and controls.searchListFallback.shown or false)
	end, scrollWheelSpeedTbl)
	controls.nodeSlider2.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if not controls.nodeSlider2.dragging then
			if nodeSlider2StatLabel == "None" then
				tooltip:AddLine(16, "^7For nodes with multiple stats this slider controls the weight of the second stat listed.")
			else
				tooltip:AddLine(16, "^7This slider controls the weight of the following stat:")
				tooltip:AddLine(16, "^7        " .. nodeSlider2StatLabel)
			end
		end
	end
	controls.nodeSlider2Value = new("LabelControl", { "LEFT", controls.nodeSlider2, "RIGHT" }, 5, 0, 0, 16, "^71.000")
	controls.nodeSlider2.tooltip.realDraw = controls.nodeSlider2.tooltip.Draw
	controls.nodeSlider2.tooltip.Draw = function(self, x, y, width, height, viewPort)
		local sliderOffsetX = round(184 * (1 - controls.nodeSlider2.val))
		local tooltipWidth, tooltipHeight = self:GetSize()
		if main.screenW >= 1384 - sliderOffsetX then
			return controls.nodeSlider2.tooltip.realDraw(self, x - 8 - sliderOffsetX, y - 4 - tooltipHeight, width, height, viewPort)
		end
		return controls.nodeSlider2.tooltip.realDraw(self, x, y, width, height, viewPort)
	end
	controls.nodeSlider2:SetVal(0.1)

	controls.nodeSlider3Label = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 405, 175, 0, 16, "^7Minimum Node Weight:")
	controls.nodeSlider3 = new("SliderControl", { "LEFT", controls.nodeSlider3Label, "RIGHT" }, 10, 0, 200, 16, function(value)
		if value == 1 then
			controls.nodeSlider3Value.label = "^7Required"
		else
			controls.nodeSlider3Value.label = s_format("^7%.f", value * 500)
		end
		parseSearchList(1, controls.searchListFallback and controls.searchListFallback.shown or false)
	end, scrollWheelSpeedTbl2)
	controls.nodeSlider3.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if not controls.nodeSlider3.dragging then
			tooltip:AddLine(16, "^7Seeds that do not meet the minimum weight threshold for a desired node are excluded from the search results.")
		end
	end
	controls.nodeSlider3Value = new("LabelControl", { "LEFT", controls.nodeSlider3, "RIGHT" }, 5, 0, 0, 16, "^70")
	controls.nodeSlider3.tooltip.realDraw = controls.nodeSlider3.tooltip.Draw
	controls.nodeSlider3.tooltip.Draw = function(self, x, y, width, height, viewPort)
		local sliderOffsetX = round(184 * (1 - controls.nodeSlider3.val))
		local tooltipWidth, tooltipHeight = self:GetSize()
		if main.screenW >= 1728 - sliderOffsetX then
			return controls.nodeSlider3.tooltip.realDraw(self, x - 8 - sliderOffsetX, y - 4 - tooltipHeight, width, height, viewPort)
		end
		return controls.nodeSlider3.tooltip.realDraw(self, x, y, width, height, viewPort)
	end
	controls.nodeSlider3:SetVal(0)

	local function updateSliders(sliderData)
		if sliderData[2] == "required" then
			controls.nodeSlider.val = 1
			controls.nodeSliderValue.label = s_format("^7%.3f", 10)
		else
			controls.nodeSlider.val = m_min(m_max((tonumber(sliderData[2]) or 0) / 10, 0), 1)
			controls.nodeSliderValue.label = s_format("^7%.3f", controls.nodeSlider.val * 10)
		end
		if controls.nodeSlider2.enabled then
			if sliderData[3] == "required" then
				controls.nodeSlider2.val = 1
				controls.nodeSlider2Value.label = s_format("^7%.3f", 10)
			else
				controls.nodeSlider2.val = m_min(m_max((tonumber(sliderData[3]) or 0) / 10, 0), 1)
				controls.nodeSlider2Value.label = s_format("^7%.3f", controls.nodeSlider2.val * 10)
			end
		end
		if sliderData[4] == "required" then
			controls.nodeSlider3.val = 1
			controls.nodeSlider3Value.label = "^7Required"
		else
			controls.nodeSlider3.val = m_min(m_max((tonumber(sliderData[4]) or 0) / 500, 0), 1)
			controls.nodeSlider3Value.label = s_format("^7%.f", controls.nodeSlider3.val * 500)
		end
	end

	buildMods()
	controls.nodeSelectLabel = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 405, 200, 0, 16, "^7Search for Node:")
	controls.nodeSelect = new("DropDownControl", { "LEFT", controls.nodeSelectLabel, "RIGHT" }, 10, 0, 200, 18, modData, function(index, value)
		nodeSliderStatLabel = "None"
		nodeSlider2StatLabel = "None"
		if value.id then
			local statCount = 0
			for _, legionNode in ipairs(legionNodes) do
				if legionNode.id == value.id then
					statCount = #legionNode.sd
					nodeSliderStatLabel = legionNode.sd[1] or "None"
					nodeSlider2StatLabel = legionNode.sd[2] or "None"
					break
				end
			end
			if statCount == 0 then
				for _, legionAddition in ipairs(legionAdditions) do
					if legionAddition.id == value.id then
						statCount = #legionAddition.sd
						nodeSliderStatLabel = legionAddition.sd[1] or "None"
						nodeSlider2StatLabel = legionAddition.sd[2] or "None"
						break
					end
				end
			end
			if statCount <= 1 then
				controls.nodeSlider2Label.label = "^9Secondary Node Weight:"
				controls.nodeSlider2.val = 0
				controls.nodeSlider2Value.label = s_format("^9%.3f", 0)
			else
				controls.nodeSlider2Label.label = "^7Secondary Node Weight:"
				controls.nodeSlider2Value.label = s_format("^7%.3f", controls.nodeSlider2.val * 10)
			end
			controls.nodeSlider2.enabled = statCount > 1

			local nodeWeights = getNodeWeights()
			local newNode = value.id .. ", " .. nodeWeights[1] .. ", " .. nodeWeights[2] .. ", " .. nodeWeights[3]
			if controls.searchListFallback and controls.searchListFallback.shown then
				for _, searchRow in ipairs(searchListFallbackTbl) do
					-- update nodeSlider values and prevent duplicate searchList entries
					if searchRow[1] == value.id then
						updateSliders(searchRow)
						return
					end
				end
				controls.searchListFallback.caret = #controls.searchListFallback.buf + 1
				controls.searchListFallback:Insert((#controls.searchListFallback.buf > 0 and "\n" or "") .. newNode)
			else
				for _, searchRow in ipairs(searchListTbl) do
					-- update nodeSlider values and prevent duplicate searchList entries
					if searchRow[1] == value.id then
						updateSliders(searchRow)
						return
					end
				end
				controls.searchList.caret = #controls.searchList.buf + 1
				controls.searchList:Insert((#controls.searchList.buf > 0 and "\n" or "") .. newNode)
			end
			self.build.modFlag = true
		end
	end)
	controls.nodeSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" and value.descriptions then
			for _, line in ipairs(value.descriptions) do
				tooltip:AddLine(16, "^7" .. line)
			end
		end
	end

	local function generateFallbackWeights(nodes, selection)
		local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator(self.build)
		local newList = { }
		local baseOutput = calcFunc({ })
		if baseOutput.Minion then
			baseOutput = baseOutput.Minion
		end
		local baseValue = baseOutput[selection.stat] or 1
		if selection.transform then
			baseValue = selection.transform(baseValue)
		end
		for _, newNode in ipairs(nodes) do
			local output = nil
			if newNode.calcMultiple then
				output = calcFunc({ addNodes = { [newNode.node[1]] = true } })
			else
				output = calcFunc({ addNodes = { [newNode] = true } })
			end
			if output.Minion then
				output = output.Minion
			end
			local outputValue = output[selection.stat] or 0
			if selection.transform then
				outputValue = selection.transform(outputValue)
			end
			outputValue = outputValue / baseValue
			if outputValue ~= outputValue then
				outputValue = 1
			end
			t_insert(newList, {
				id = newNode.id,
				weight1 = (outputValue - 1) / (newNode.divisor or 1)
			})
			if newNode.calcMultiple then
				output = calcFunc({ addNodes = { [newNode.node[2]] = true } })
				if output.Minion then
					output = output.Minion
				end
				outputValue = output[selection.stat] or 0
				if selection.transform then
					outputValue = selection.transform(outputValue)
				end
				outputValue = outputValue / baseValue
				if outputValue ~= outputValue then
					outputValue = 1
				end
				newList[#newList].weight2 = (outputValue - 1) / (newNode.divisor or 1)
			end
		end
		return newList
	end

	local function setupFallbackWeights()
		-- replaceHelperFunc is duplicated from PassiveSpec.lua
		local replaceHelperFunc = function(statToFix, statKey, statMod, value)
			if statMod.fmt == "g" then -- note the only one we actually care about is "Ritual of Flesh" life regen
				if statKey:find("per_minute") then
					value = round(value / 60, 1)
				elseif statKey:find("permyriad") then
					value = value / 100
				elseif statKey:find("_ms") then
					value = value / 1000
				end
			end
			--if statMod.fmt == "d" then -- only ever d or g, and we want both past here
			if statMod.min ~= statMod.max then
				return statToFix:gsub("%(" .. statMod.min .. "%-" .. statMod.max .. "%)", value)
			elseif statMod.min ~= value then -- only true for might/legacy of the vaal which can combine stats
				return statToFix:gsub(statMod.min, value)
			end
			return statToFix -- if it doesn't need to be changed
		end

		local nodes = { }
		for _, modNode in ipairs(modData) do
			if modNode.id then
				local newNode = nil
				for _, legionNode in ipairs(legionNodes) do
					if legionNode.id == modNode.id or (totalModIDs[modNode.id] and totalModIDs[modNode.id][legionNode.id]) then
							newNode = { }
							newNode.id = modNode.id
							if modNode.type == "vaal" then
								if #legionNode.sd == 2 then
									newNode.calcMultiple = true
									if legionNode.modListGenerated then
										newNode.node = copyTable(legionNode.modListGenerated)
									else
										-- generate modList
										local modList1, extra1 = modLib.parseMod(replaceHelperFunc(legionNode.sd[1], legionNode.sortedStats[1], legionNode.stats[legionNode.sortedStats[1]], 100))
										local modList2, extra2 = modLib.parseMod(replaceHelperFunc(legionNode.sd[2], legionNode.sortedStats[2], legionNode.stats[legionNode.sortedStats[2]], 100))
										local modLists = { { modList = modList1 }, { modList = modList2 } }
										legionNode.modListGenerated = copyTable(modLists)
										newNode.node = copyTable(modLists)
									end
									newNode.node[1].id = legionNode.id
									newNode.node[2].id = legionNode.id
								else
									if legionNode.modListGenerated then
										newNode.modList = copyTable(legionNode.modListGenerated)
									else
										-- generate modList
										local modList, extra = modLib.parseMod(replaceHelperFunc(legionNode.sd[1], legionNode.sortedStats[1], legionNode.stats[legionNode.sortedStats[1]], 100))
										legionNode.modListGenerated = modList
										newNode.modList = modList
									end
								end
								newNode.divisor = 100
							else
								newNode.modList = legionNode.modList
								if modNode.totalMod then
									newNode.divisor = legionNode.modList[1].value
								end
							end
						break
					end
				end
				if not newNode then
					for _, legionAddition in ipairs(legionAdditions) do
						if legionAddition.id == modNode.id or (totalModIDs[modNode.id] and totalModIDs[modNode.id][legionAddition.id]) then
							newNode = { }
							newNode.id = modNode.id
							if legionAddition.modList then
								newNode.modList = legionAddition.modList
							elseif legionAddition.modListGenerated then
								newNode.modList = legionAddition.modListGenerated
							else
								-- generate modList
								local line = legionAddition.sd[1]
								if modNode.type == "vaal" then
									for key, stat in legionAddition.stats do -- should only be length 1
										line = replaceHelperFunc(line, key, stat, 100)
									end
								end
								local modList, extra = modLib.parseMod(line)
								legionAddition.modListGenerated = modList
								newNode.modList = modList
							end
							if modNode.type == "vaal" then
								newNode.divisor = 100
							elseif modNode.totalMod then
								newNode.divisor = newNode.modList[1].value
							end
							break
						end
					end
				end
				if newNode then
					t_insert(nodes, newNode)
				end
			end
		end
		local output = generateFallbackWeights(nodes, controls.fallbackWeightsList.list[controls.fallbackWeightsList.selIndex])
		local newList = ""
		local weightScalar = 100
		for _, legionNode in ipairs(output) do
			if legionNode.weight1 ~= 0 or (legionNode.weight2 and legionNode.weight2 ~= 0) then
				if #newList > 0 then
					newList = newList .. "\n"
				end
				newList = newList .. legionNode.id .. ", " .. round(legionNode.weight1 * weightScalar, 3) .. ", " .. round((legionNode.weight2 or 0) * weightScalar, 3) .. ", 0"
			end
		end
		updateSearchList(newList, true)
	end

	controls.fallbackWeightsLabel = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 405, 225, 0, 16, "^7Fallback Weight Mode:")
	local fallbackWeightsList = { }
	for id, stat in pairs(data.powerStatList) do
		if not stat.ignoreForItems and stat.label ~= "Name" then
			t_insert(fallbackWeightsList, {
				label = "Sort by " .. stat.label,
				stat = stat.stat,
				transform = stat.transform,
			})
		end
	end
	controls.fallbackWeightsList = new("DropDownControl", { "LEFT", controls.fallbackWeightsLabel, "RIGHT" }, 10, 0, 200, 18, fallbackWeightsList, function(index)
		timelessData.fallbackWeightMode.idx = index
	end)
	controls.fallbackWeightsList.selIndex = timelessData.fallbackWeightMode.idx or 1
	controls.fallbackWeightsButton = new("ButtonControl", { "LEFT", controls.fallbackWeightsList, "RIGHT" }, 5, 0, 66, 18, "Generate", function()
		setupFallbackWeights()
		controls.searchListFallbackButton.label = "^4Fallback Nodes"
	end)
	controls.fallbackWeightsButton.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		tooltip:AddLine(16, "^7Click this button to generate new fallback node weights, replacing your old ones.")
	end

	controls.searchListButton = new("ButtonControl", { "TOPLEFT", nil, "TOPLEFT" }, 12, 250, 106, 20, "^7Desired Nodes", function()
		if controls.searchListFallback.shown then
			controls.searchListFallback.shown = false
			controls.searchListFallback.enabled = false
			controls.searchList.shown = true
			controls.searchList.enabled = true
		end
	end)
	controls.searchListButton.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		tooltip:AddLine(16, "^7This contains a list of your desired nodes along with their primary, secondary, and minimum weights.")
		tooltip:AddLine(16, "^7This list can be updated manually or by selecting the node you want to update via the search dropdown list and then moving the node weight sliders.")
	end
	controls.searchListButton.locked = function() return controls.searchList.shown end
	controls.searchListFallbackButton = new("ButtonControl", { "LEFT", controls.searchListButton, "RIGHT" }, 5, 0, 110, 20, "^7Fallback Nodes", function()
		controls.searchList.shown = false
		controls.searchList.enabled = false
		controls.searchListFallback.shown = true
		controls.searchListFallback.enabled = true
		controls.searchListFallbackButton.label = "^7Fallback Nodes"
	end)
	controls.searchListFallbackButton.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		tooltip:AddLine(16, "^7This contains a list of your fallback nodes along with their primary, secondary, and minimum weights.")
		tooltip:AddLine(16, "^7This list can be updated manually or by selecting the node you want to update via the search dropdown list and then moving the node weight sliders.")
		tooltip:AddLine(16, "^7Fallback node weights are only used when no matching entry exists in the desired nodes list, allowing you to override or disable specific automatic weights.")
		tooltip:AddLine(16, "^7Fallback node weights typically contain automatically generated stat weights based on your current build.")
		tooltip:AddLine(16, "^7Any manual changes made to your fallback nodes are lost when you click the generate button, as it completely replaces them.")
	end
	controls.searchListFallbackButton.locked = function() return controls.searchListFallback.shown end
	controls.searchList = new("EditControl", { "TOPLEFT", nil, "TOPLEFT" }, 12, 275, 438, 200, timelessData.searchList, nil, "^%C\t\n", nil, function(value)
		timelessData.searchList = value
		parseSearchList(0, false)
		self.build.modFlag = true
	end, 16, true)
	controls.searchList.shown = true
	controls.searchList.enabled = true
	controls.searchList:SetText(timelessData.searchList and timelessData.searchList or "")
	controls.searchListFallback = new("EditControl", { "TOPLEFT", nil, "TOPLEFT" }, 12, 275, 438, 200, timelessData.searchListFallback, nil, "^%C\t\n", nil, function(value)
		timelessData.searchListFallback = value
		parseSearchList(0, true)
		self.build.modFlag = true
	end, 16, true)
	controls.searchListFallback.shown = false
	controls.searchListFallback.enabled = false
	controls.searchListFallback:SetText(timelessData.searchListFallback and timelessData.searchListFallback or "")

	controls.searchResultsLabel = new("LabelControl", { "TOPLEFT", nil, "TOPRIGHT" }, -450, 250, 0, 16, "^7Search Results:")
	controls.searchResults = new("TimelessJewelListControl", { "TOPLEFT", nil, "TOPRIGHT" }, -450, 275, 438, 200, self.build)
	controls.searchTradeLeagueSelect = new("DropDownControl", { "BOTTOMRIGHT", controls.searchResults, "TOPRIGHT" }, -175, -5, 140, 20, nil, function(_, value)
		self.timelessJewelLeagueSelect = value
	end)
	self.tradeQueryRequests = new("TradeQueryRequests")
	controls.msg = new("LabelControl", nil, -280, 5, 0, 16, "")
	if #self.tradeLeaguesList > 0 then
		controls.searchTradeLeagueSelect:SetList(self.tradeLeaguesList)
	else
		self.tradeQueryRequests:FetchLeagues("pc", function(leagues, errMsg)
			if errMsg then
				controls.msg.label = "^1Error fetching league list, default league will be used\n"..errMsg.."^7"
				return
			end
			local tempLeagueTable = { }
			for _, league in ipairs(leagues) do
				if league ~= "Standard" and  league ~= "Ruthless" and league ~= "Hardcore" and league ~= "Hardcore Ruthless" then
					if not (league:find("Hardcore") or league:find("Ruthless")) then
						-- set the dynamic, base league name to index 1 to sync league shown in dropdown on load with default/old behavior of copy trade url
						t_insert(tempLeagueTable, league)
						for _, val in ipairs(self.tradeLeaguesList) do
							t_insert(tempLeagueTable, val)
						end
						self.tradeLeaguesList = copyTable(tempLeagueTable)
					else
						t_insert(self.tradeLeaguesList, league)
					end
				end
			end
			t_insert(self.tradeLeaguesList, "Standard")
			t_insert(self.tradeLeaguesList, "Hardcore")
			t_insert(self.tradeLeaguesList, "Ruthless")
			t_insert(self.tradeLeaguesList, "Hardcore Ruthless")
			controls.searchTradeLeagueSelect:SetList(self.tradeLeaguesList)
		end)
	end
	controls.searchTradeButton = new("ButtonControl", { "BOTTOMRIGHT", controls.searchResults, "TOPRIGHT" }, 0, -5, 170, 20, "Copy Trade URL", function()
		local seedTrades = {}
		local startRow = controls.searchResults.selIndex or 1
		local endRow = startRow + m_floor(10 / ((timelessData.sharedResults.conqueror.id == 1) and 3 or 1))
		if controls.searchResults.highlightIndex then
			startRow = m_min(controls.searchResults.selIndex, controls.searchResults.highlightIndex)
			endRow = m_max(controls.searchResults.selIndex, controls.searchResults.highlightIndex)
		end

		local seedCount = m_min(#timelessData.searchResults - startRow, endRow - startRow) + 1
		-- update if not highlighted already

		local prevSearch = controls.searchTradeButton.lastSearch
		if prevSearch and prevSearch[1] == startRow and prevSearch[2] == seedCount then
			startRow = endRow + 1
			if (startRow > #timelessData.searchResults) then
				return
			end
			seedCount = m_min(#timelessData.searchResults - startRow + 1, seedCount)
			endRow = startRow + seedCount - 1
		end
		controls.searchResults.selIndex = startRow
		controls.searchResults.highlightIndex = endRow

		controls.searchTradeButton.lastSearch = {startRow, seedCount}

		for i = startRow, startRow + seedCount - 1 do
			local result = timelessData.searchResults[i]

			local conquerorKeystoneTradeIds = data.timelessJewelTradeIDs[timelessData.jewelType.id].keystone
			local conquerorTradeIds = { conquerorKeystoneTradeIds[1], conquerorKeystoneTradeIds[2], conquerorKeystoneTradeIds[3] }
			if timelessData.sharedResults.conqueror.id > 1 then
				conquerorTradeIds = { conquerorKeystoneTradeIds[timelessData.sharedResults.conqueror.id - 1] }
			end

			for _, tradeId in ipairs(conquerorTradeIds) do
				t_insert(seedTrades, {
					id = tradeId,
					value = {
						min = result.seed,
						max = result.seed
					}
				})
			end
		end

		local search = {
			query = {
				status = {
					option = "online"
				},
				stats = {
					{
						filters = seedTrades,
						type = "count",
						value = {
							min = 1
						}
					}
				}
			},
			sort = {
				price = "asc"
			}
		}

		if data.timelessJewelTradeIDs[timelessData.jewelType.id].devotion ~= nil then
			local devotionFilters = {}
			if timelessData.sharedResults.devotionVariant1.id > 1 then
				t_insert(devotionFilters, { id = data.timelessJewelTradeIDs[timelessData.jewelType.id].devotion[timelessData.sharedResults.devotionVariant1.id - 1] })
			end
			if timelessData.sharedResults.devotionVariant2.id > 1 then
				t_insert(devotionFilters, { id = data.timelessJewelTradeIDs[timelessData.jewelType.id].devotion[timelessData.sharedResults.devotionVariant2.id - 1] })
			end
			if next(devotionFilters) then
				t_insert(search.query.stats, {
					filters = devotionFilters,
					type = "and"
				})
			end
		end

		Copy("https://www.pathofexile.com/trade/search/"..(self.timelessJewelLeagueSelect or "").."/?q=" .. (s_gsub(dkjson.encode(search), "[^a-zA-Z0-9]", function(a)
			return s_format("%%%02X", s_byte(a))
		end)))

		controls.searchTradeButton.label = "Copy Next Trade URL"
	end)
	controls.searchTradeButton.enabled = timelessData.searchResults and #timelessData.searchResults > 0
	controls.searchTradeButton.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		tooltip:AddLine(16, "^7Click to generate and copy a trade URL for searching for jewels in this list.")
		tooltip:AddLine(16, "^7Paste the URL in a web browser to search.")
		tooltip:AddLine(16, "")
		tooltip:AddLine(16, "^7You can click to select a row so that search begins from there.")
		tooltip:AddLine(16, "^7After selecting a row You can also shift+click on another row to select a range of rows to search.")
	end

	local width = 80
	local divider = 10
	local buttons = 3
	local totalWidth = m_floor(width * buttons + divider * (buttons - 1))
	local buttonX = -totalWidth / 2 + width / 2

	controls.searchButton = new("ButtonControl", nil, buttonX, 485, width, 20, "Search", function()
		if treeData.nodes[timelessData.jewelSocket.id] and treeData.nodes[timelessData.jewelSocket.id].isJewelSocket then
			local radiusNodes = treeData.nodes[timelessData.jewelSocket.id].nodesInRadius[3] -- large radius around timelessData.jewelSocket.id
			local allocatedNodes = { }
			local unAllocatedNodesDistance = { }
			local targetNodes = { }
			local targetSmallNodes = { ["attributeSmalls"] = 0, ["otherSmalls"] = 0 }
			local desiredNodes = { }
			local minimumWeights = { }
			local resultNodes = { }
			local rootNodes = { }
			local desiredIdx = 0
			local searchListCombinedTbl = { }
			local searchListNodeFound = { }
			for _, curRow in ipairs(searchListTbl) do
				searchListNodeFound[curRow[1]] = true
				searchListCombinedTbl[#searchListCombinedTbl + 1] = copyTable(curRow)
			end
			for _, curRow in ipairs(searchListFallbackTbl) do
				if not searchListNodeFound[curRow[1]] then
					searchListCombinedTbl[#searchListCombinedTbl + 1] = copyTable(curRow)
				end
			end
			for _, desiredNode in ipairs(searchListCombinedTbl) do
				if #desiredNode > 1 then
					local displayName = nil
					local singleStat = false
					if totalMods[timelessData.jewelType.id] and desiredNode[1] == "total_" .. totalMods[timelessData.jewelType.id]:lower() then
						desiredNode[1] = "totalStat"
						displayName = totalMods[timelessData.jewelType.id]
					end
					if displayName == nil then
						for _, legionNode in ipairs(legionNodes) do
							if legionNode.id == desiredNode[1] then
								-- non-vaal replacements only support one nodeWeight
								if timelessData.jewelType.id > 1 then
									singleStat = true
								end
								displayName = t_concat(legionNode.sd, " + ")
								break
							end
						end
					end
					if displayName == nil then
						for _, legionAddition in ipairs(legionAdditions) do
							if legionAddition.id == desiredNode[1] then
								-- additions only support one nodeWeight
								singleStat = true
								displayName = t_concat(legionAddition.sd, " + ")
								break
							end
						end
					end
					if displayName ~= nil then
						for i, val in ipairs(desiredNode) do
							if singleStat and i == 2 then
								desiredNode[2] = tonumber(desiredNode[2]) or tonumber(desiredNode[3]) or 1
							end
							if val == "required" then
								desiredNode[i] = (singleStat and i == 2) and desiredNode[2] or 0
								if desiredNode[4] == nil or desiredNode[4] < 0.001 then
									desiredNode[4] = 0.001
								end
							end
						end
						if desiredNode[4] ~= nil and tonumber(desiredNode[4]) > 0 then
							t_insert(minimumWeights, { reqNode = desiredNode[1], weight = tonumber(desiredNode[4]) })
						end
						if desiredNodes[desiredNode[1]] then
							desiredNodes[desiredNode[1]] = {
								nodeWeight = tonumber(desiredNode[2]) or 0.001,
								nodeWeight2 = tonumber(desiredNode[3]) or 0.001,
								displayName = displayName or desiredNode[1],
								desiredIdx = desiredNodes[desiredNode[1]].desiredIdx
							}
						else
							desiredIdx = desiredIdx + 1
							desiredNodes[desiredNode[1]] = {
								nodeWeight = tonumber(desiredNode[2]) or 0.001,
								nodeWeight2 = tonumber(desiredNode[3]) or 0.001,
								displayName = displayName or desiredNode[1],
								desiredIdx = desiredIdx
							}
						end
					end
				end
			end
			wipeTable(searchListCombinedTbl)
			for _, class in pairs(treeData.classes) do
				rootNodes[class.startNodeId] = true
			end
			if controls.socketFilter.state then
				timelessData.socketFilterDistance = timelessData.socketFilterDistance or 0
				for nodeId in pairs(radiusNodes) do
					allocatedNodes[nodeId] = self.build.calcsTab.mainEnv.grantedPassives[nodeId] ~= nil or self.build.spec.allocNodes[nodeId] ~= nil
					if timelessData.socketFilterDistance > 0 then
						unAllocatedNodesDistance[nodeId] = self.build.spec.nodes[nodeId].pathDist or 1000
					end
				end
			end
			for nodeId in pairs(radiusNodes) do
				if not rootNodes[nodeId]
				and not treeData.nodes[nodeId].isJewelSocket
				and not treeData.nodes[nodeId].isKeystone
				and (not controls.socketFilter.state or allocatedNodes[nodeId] or (timelessData.socketFilterDistance > 0 and unAllocatedNodesDistance[nodeId] <= timelessData.socketFilterDistance)) then
					if (treeData.nodes[nodeId].isNotable or timelessData.jewelType.id == 1) then
						targetNodes[nodeId] = true
					elseif desiredNodes["totalStat"] and not treeData.nodes[nodeId].isNotable then
						if isValueInArray({ "Strength", "Intelligence", "Dexterity" }, treeData.nodes[nodeId].dn) then
							targetSmallNodes.attributeSmalls = targetSmallNodes.attributeSmalls + 1
						else
							targetSmallNodes.otherSmalls = targetSmallNodes.otherSmalls + 1
						end
					end
				end
			end
			local seedWeights = { }
			local seedMultiplier = timelessData.jewelType.id == 5 and 20 or 1 -- Elegant Hubris
			for curSeed = data.timelessJewelSeedMin[timelessData.jewelType.id] * seedMultiplier, data.timelessJewelSeedMax[timelessData.jewelType.id] * seedMultiplier, seedMultiplier do
				seedWeights[curSeed] = 0
				resultNodes[curSeed] = { }
				for targetNode in pairs(targetNodes) do
					local jewelDataTbl = data.readLUT(curSeed, targetNode, timelessData.jewelType.id)
					if not next(jewelDataTbl) then
						ConPrintf("Missing LUT: " .. timelessData.jewelType.label)
					else
						local curNode = nil
						local curNodeId = nil
						if jewelDataTbl[1] >= data.timelessJewelAdditions then -- replace
							curNode = legionNodes[jewelDataTbl[1] + 1 - data.timelessJewelAdditions]
							curNodeId = curNode and legionNodes[jewelDataTbl[1] + 1 - data.timelessJewelAdditions].id or nil
						else -- add
							curNode = legionAdditions[jewelDataTbl[1] + 1]
							curNodeId = curNode and legionAdditions[jewelDataTbl[1] + 1].id or nil
						end
						if desiredNodes["totalStat"] and reverseTotalModIDs[curNodeId] then
							curNodeId = "totalStat"
						end
						if timelessData.jewelType.id == 1 then
							local headerSize = #jewelDataTbl
							if headerSize == 2 or headerSize == 3 then
								if desiredNodes[curNodeId] then
									resultNodes[curSeed][curNodeId] = resultNodes[curSeed][curNodeId] or { targetNodeNames = { }, totalWeight = 0 }
									local statMod1 = curNode.stats[curNode.sortedStats[1]]
									local weight = desiredNodes[curNodeId].nodeWeight * jewelDataTbl[statMod1.index + 1]
									local statMod2 = curNode.stats[curNode.sortedStats[2]]
									if statMod2 then
										weight = weight + desiredNodes[curNodeId].nodeWeight2 * jewelDataTbl[statMod2.index + 1]
									end
									t_insert(resultNodes[curSeed][curNodeId], targetNode)
									t_insert(resultNodes[curSeed][curNodeId].targetNodeNames, treeData.nodes[targetNode].name)
									resultNodes[curSeed][curNodeId].totalWeight = resultNodes[curSeed][curNodeId].totalWeight + weight
									seedWeights[curSeed] = seedWeights[curSeed] + weight
								end
							elseif headerSize == 6 or headerSize == 8 then
								for i, jewelData in ipairs(jewelDataTbl) do
									curNode = legionAdditions[jewelDataTbl[i] + 1]
									curNodeId = curNode and legionAdditions[jewelDataTbl[i] + 1].id or nil
									if i <= (headerSize / 2) then
										if desiredNodes[curNodeId] then
											resultNodes[curSeed][curNodeId] = resultNodes[curSeed][curNodeId] or { targetNodeNames = { }, totalWeight = 0 }
											local weight = desiredNodes[curNodeId].nodeWeight * jewelDataTbl[i + (headerSize / 2)]
											resultNodes[curSeed][curNodeId].totalWeight = resultNodes[curSeed][curNodeId].totalWeight + weight
											t_insert(resultNodes[curSeed][curNodeId], targetNode)
											t_insert(resultNodes[curSeed][curNodeId].targetNodeNames, treeData.nodes[targetNode].name)
											seedWeights[curSeed] = seedWeights[curSeed] + weight
										end
									else
										break
									end
								end
							end
						elseif desiredNodes[curNodeId] then
							resultNodes[curSeed][curNodeId] = resultNodes[curSeed][curNodeId] or { targetNodeNames = { }, totalWeight = 0 }
							resultNodes[curSeed][curNodeId].totalWeight = resultNodes[curSeed][curNodeId].totalWeight + desiredNodes[curNodeId].nodeWeight
							t_insert(resultNodes[curSeed][curNodeId], targetNode)
							t_insert(resultNodes[curSeed][curNodeId].targetNodeNames, treeData.nodes[targetNode].name)
							seedWeights[curSeed] = seedWeights[curSeed] + desiredNodes[curNodeId].nodeWeight
						end
					end
				end
				if desiredNodes["totalStat"] then
					resultNodes[curSeed]["totalStat"] = resultNodes[curSeed]["totalStat"] or { targetNodeNames = { }, totalWeight = 0 }
					if timelessData.jewelType.id == 4 then -- Militant Faith
						local addedWeight = desiredNodes["totalStat"].nodeWeight * (5 * targetSmallNodes.otherSmalls + 10 * targetSmallNodes.attributeSmalls)
						addedWeight = addedWeight + resultNodes[curSeed]["totalStat"].totalWeight * 4
						resultNodes[curSeed]["totalStat"].totalWeight = resultNodes[curSeed]["totalStat"].totalWeight + addedWeight
						seedWeights[curSeed] = seedWeights[curSeed] + addedWeight
					else
						local addedWeight = desiredNodes["totalStat"].nodeWeight * (4 * targetSmallNodes.otherSmalls + 2 * targetSmallNodes.attributeSmalls)
						addedWeight = addedWeight + resultNodes[curSeed]["totalStat"].totalWeight * 19
						resultNodes[curSeed]["totalStat"].totalWeight = resultNodes[curSeed]["totalStat"].totalWeight + addedWeight
						seedWeights[curSeed] = seedWeights[curSeed] + addedWeight
					end
				end
				-- check minimum weights
				for _, val in ipairs(minimumWeights) do
					if (resultNodes[curSeed][val.reqNode] and resultNodes[curSeed][val.reqNode].totalWeight or 0) < val.weight then
						resultNodes[curSeed] = nil
						break
					end
				end
			end
			wipeTable(timelessData.searchResults)
			wipeTable(timelessData.sharedResults)
			timelessData.sharedResults.type = timelessData.jewelType
			timelessData.sharedResults.conqueror = timelessData.conquerorType
			timelessData.sharedResults.devotionVariant1 = devotionVariants[timelessData.devotionVariant1]
			timelessData.sharedResults.devotionVariant2 = devotionVariants[timelessData.devotionVariant2]
			timelessData.sharedResults.socket = timelessData.jewelSocket
			timelessData.sharedResults.desiredNodes = desiredNodes
			local function formatSearchValue(input)
				local   matchPattern1 = " 0"
				local replacePattern1 = "   "
				local   matchPattern2 = ".0 "
				local replacePattern2 = "    "
				local   matchPattern3 = "  %."
				local replacePattern3 = "0."
				local   matchPattern4 = "%.([0-9])0"
				local replacePattern4 = ".%1  "
				return (" " .. s_format("%006.2f", input))
				:gsub(matchPattern1, replacePattern1):gsub(matchPattern1, replacePattern1)
				:gsub(matchPattern2, replacePattern2):gsub(matchPattern2, replacePattern2)
				:gsub(matchPattern3, replacePattern3)
				:gsub(matchPattern4, replacePattern4)
			end
			local searchResultsIdx = 1
			for seedMatch, seedData in pairs(resultNodes) do
				if seedWeights[seedMatch] > 0 then
					timelessData.searchResults[searchResultsIdx] = { label = seedMatch .. ":" }
					if timelessData.jewelType.id == 1 or timelessData.jewelType.id == 3 then
						-- Glorious Vanity [100-8000], Brutal Restraint [500-8000]
						if seedMatch < 1000 then
							timelessData.searchResults[searchResultsIdx].label = "  " .. timelessData.searchResults[searchResultsIdx].label
						end
					elseif timelessData.jewelType.id == 4 then
						-- Militant Faith [2000-10000]
						if seedMatch < 10000 then
							timelessData.searchResults[searchResultsIdx].label = "  " .. timelessData.searchResults[searchResultsIdx].label
						end
					else
						-- Elegant Hubris [2000-160000]
						if seedMatch < 10000 then
							timelessData.searchResults[searchResultsIdx].label = "    " .. timelessData.searchResults[searchResultsIdx].label
						elseif seedMatch < 100000 then
							timelessData.searchResults[searchResultsIdx].label = "  " .. timelessData.searchResults[searchResultsIdx].label
						end
					end
					local sortedNodeArray = { }
					for legionId, desiredNode in pairs(desiredNodes) do
						if seedData[legionId] then
							if desiredNode.desiredIdx == 8 then
								sortedNodeArray[8] = " ..."
							elseif desiredNode.desiredIdx < 8 then
								sortedNodeArray[desiredNode.desiredIdx] = formatSearchValue(seedData[legionId].totalWeight)
							end
							timelessData.searchResults[searchResultsIdx][legionId] = timelessData.searchResults[searchResultsIdx][legionId] or { }
							timelessData.searchResults[searchResultsIdx][legionId].targetNodeNames = seedData[legionId].targetNodeNames
						elseif desiredNode.desiredIdx < 8 then
							sortedNodeArray[desiredNode.desiredIdx] = "     0     "
						end
					end
					timelessData.searchResults[searchResultsIdx].label = timelessData.searchResults[searchResultsIdx].label .. t_concat(sortedNodeArray)
					timelessData.searchResults[searchResultsIdx].seed = seedMatch
					timelessData.searchResults[searchResultsIdx].total = seedWeights[seedMatch]
					searchResultsIdx = searchResultsIdx + 1
				end
			end
			t_sort(timelessData.searchResults, function(a, b) return a.total > b.total end)
			controls.searchTradeButton.enabled = timelessData.searchResults and #timelessData.searchResults > 0
			controls.searchTradeButton.lastSearch = nil
			controls.searchTradeButton.label = "Copy Trade URL"
			controls.searchResults.highlightIndex = nil
			controls.searchResults.selIndex = 1
		end
	end)
	controls.resetButton = new("ButtonControl", nil, buttonX + (width + divider), 485, width, 20, "Reset", function()
		updateSearchList("", true)
		updateSearchList("", false)
		wipeTable(timelessData.searchResults)
		controls.searchTradeButton.enabled = false
	end)
	controls.closeButton = new("ButtonControl", nil, buttonX + (width + divider) * 2, 485, width, 20, "Cancel", function()
		main:ClosePopup()
	end)

	main:OpenPopup(910, 517, "Find a Timeless Jewel", controls)
end
