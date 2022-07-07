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
	self.controls.import = new("ButtonControl", { "LEFT", self.controls.reset, "RIGHT" }, 8, 0, 90, 20, "Import Tree", function()
		self:OpenImportPopup()
	end)
	self.controls.export = new("ButtonControl", { "LEFT", self.controls.import, "RIGHT" }, 8, 0, 90, 20, "Export Tree", function()
		self:OpenExportPopup()
	end)
	self.controls.treeSearch = new("EditControl", { "LEFT", self.controls.export, "RIGHT" }, 8, 0, main.portraitMode and 200 or 300, 20, "", "Search", "%c%(%)", 100, function(buf)
		self.viewer.searchStr = buf
	end)
	self.controls.treeSearch.tooltipText = "Uses Lua pattern matching for complex searches"
	self.controls.findTimelessJewel = new("ButtonControl", { "LEFT", self.controls.treeSearch, "RIGHT" }, 8, 0, 150, 20, "Find Timeless Jewel", function()
		self:FindTimelessJewel()
	end)
	self.controls.treeHeatMap = new("CheckBoxControl", { "LEFT", self.controls.findTimelessJewel, "RIGHT" }, 130, 0, 20, "Show Node Power:", function(state)
		self.viewer.showHeatMap = state
		self.controls.treeHeatMapStatSelect.shown = state
	end)
	self.controls.treeHeatMapStatSelect = new("DropDownControl", { "LEFT", self.controls.treeHeatMap, "RIGHT" }, 8, 0, 150, 20, nil, function(index, value)
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

	self.controls.powerReport = new("ButtonControl", { "LEFT", self.controls.treeHeatMapStatSelect, "RIGHT" }, 8, 0, 150, 20, self.showPowerReport and "Hide Power Report" or "Show Power Report", function()
		self.showPowerReport = not self.showPowerReport
		self:TogglePowerReport()
	end)
	self.controls.powerReport.enabled = function()
		return self.build.calcsTab and self.build.calcsTab.powerBuilderInitialized
	end
	self.controls.powerReport.tooltipFunc = function(tooltip)
		tooltip:Clear()
		if not (self.build.calcsTab and self.build.calcsTab.powerBuilderInitialized) then
			tooltip:AddLine(14, "Show Power Report is disabled until the first time")
			tooltip:AddLine(14, "an evaluation of all nodes and clusters completes.")
		end
	end
	self.showPowerReport = false

	self.controls.specConvertText = new("LabelControl", { "BOTTOMLEFT", self.controls.specSelect, "TOPLEFT" }, 0, -14, 0, 16, "^7This is an older tree version, which may not be fully compatible with the current game version.")
	self.controls.specConvertText.shown = function()
		return self.showConvert
	end
	self.controls.specConvert = new("ButtonControl", { "LEFT", self.controls.specConvertText, "RIGHT" }, 8, 0, 120, 20, "^2Convert to "..treeVersions[latestTreeVersion].display, function()
		local newSpec = new("PassiveSpec", self.build, latestTreeVersion)
		newSpec.title = self.build.spec.title
		newSpec.jewels = copyTable(self.build.spec.jewels)
		newSpec:RestoreUndoState(self.build.spec:CreateUndoState())
		newSpec:BuildClusterJewelGraphs()
		t_insert(self.specList, self.activeSpec + 1, newSpec)
		self:SetActiveSpec(self.activeSpec + 1)
		self.modFlag = true
		main:OpenMessagePopup("Tree Converted", "The tree has been converted to "..treeVersions[latestTreeVersion].display..".\nNote that some or all of the passives may have been de-allocated due to changes in the tree.\n\nYou can switch back to the old tree using the tree selector at the bottom left.")
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
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	-- Determine positions if one line of controls doesn't fit in the screen width
	local twoLineHeight = 24
	if viewPort.width >= 1484 or (viewPort.width >= 1168 and not self.viewer.showHeatMap) then
		twoLineHeight = 0
		self.controls.findTimelessJewel:SetAnchor("LEFT", self.controls.treeSearch, "RIGHT", 8, 0)
		if self.controls.powerReportList then
			self.controls.powerReportList:SetAnchor("TOPLEFT", self.controls.specSelect, "BOTTOMLEFT", 0, self.controls.specSelect.height + 4)
			self.controls.allocatedNodeToggle:SetAnchor("TOPLEFT", self.controls.powerReportList, "TOPRIGHT", 8, 0)
		end
	else
		self.controls.findTimelessJewel:SetAnchor("TOPLEFT", self.controls.specSelect, "BOTTOMLEFT", 0, 4)
		if self.controls.powerReportList then
			self.controls.powerReportList:SetAnchor("TOPLEFT", self.controls.findTimelessJewel, "BOTTOMLEFT", 0, self.controls.treeHeatMap.y + self.controls.treeHeatMap.height + 4)
			self.controls.allocatedNodeToggle:SetAnchor("TOPLEFT", self.controls.powerReportList, "TOPRIGHT", -76, -44)
		end
	end

	local bottomDrawerHeight = self.showPowerReport and 194 or 0
	self.controls.specSelect.y = -bottomDrawerHeight - twoLineHeight

	local treeViewPort = { x = viewPort.x, y = viewPort.y, width = viewPort.width, height = viewPort.height - (self.showConvert and 64 + bottomDrawerHeight + twoLineHeight or 32 + bottomDrawerHeight + twoLineHeight)}
	if self.jumpToNode then
		self.viewer:Focus(self.jumpToX, self.jumpToY, treeViewPort, self.build)
		self.jumpToNode = false
	end
	self.viewer.compareSpec = self.isComparing and self.specList[self.activeCompareSpec] or nil
	self.viewer:Draw(self.build, treeViewPort, inputEvents)

	local newSpecList = { }
	self.controls.compareSelect.selIndex = self.activeCompareSpec
	for id, spec in ipairs(self.specList) do
		t_insert(newSpecList, (spec.treeVersion ~= latestTreeVersion and ("["..treeVersions[spec.treeVersion].display.."] ") or "")..(spec.title or "Default"))
	end
	self.controls.compareSelect:SetList(newSpecList)

	self.controls.specSelect.selIndex = self.activeSpec
	wipeTable(newSpecList)
	for id, spec in ipairs(self.specList) do
		t_insert(newSpecList, (spec.treeVersion ~= latestTreeVersion and ("["..treeVersions[spec.treeVersion].display.."] ") or "")..(spec.title or "Default"))
	end
	self.build.itemsTab.controls.specSelect:SetList(copyTable(newSpecList)) -- Update the passive tree dropdown control in itemsTab
	t_insert(newSpecList, "Manage trees...")
	self.controls.specSelect:SetList(newSpecList)

	if not self.controls.treeSearch.hasFocus then
		self.controls.treeSearch:SetText(self.viewer.searchStr)
	end

	self.controls.treeHeatMap.state = self.viewer.showHeatMap
	self.controls.treeHeatMapStatSelect.list = self.powerStatList
	self.controls.treeHeatMapStatSelect.selIndex = 1
	self.controls.treeHeatMapStatSelect:CheckDroppedWidth(true)
	if self.build.calcsTab.powerStat then
		self.controls.treeHeatMapStatSelect:SelByValue(self.build.calcsTab.powerStat.stat, "stat")
	end
	if self.controls.powerReportList then
		if self.build.calcsTab.powerStat and self.build.calcsTab.powerStat.stat then
			self.controls.powerReportList.label = self.build.calcsTab.powerBuilder and "Building table..." or "Click to focus node on tree"
		else
			self.controls.powerReportList.label = "^7\"Offense/Defense\" not supported.  Select a specific stat from the dropdown."
		end
	end

	SetDrawLayer(1)

	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (28 + bottomDrawerHeight + twoLineHeight), viewPort.width, 28 + bottomDrawerHeight + twoLineHeight)
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (32 + bottomDrawerHeight + twoLineHeight), viewPort.width, 4)

	if self.showConvert then
		SetDrawColor(0.05, 0.05, 0.05)
		DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (60 + bottomDrawerHeight + twoLineHeight), viewPort.width, 28)
		SetDrawColor(0.85, 0.85, 0.85)
		DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - (64 + bottomDrawerHeight + twoLineHeight), viewPort.width, 4)
	end

	self:DrawControls(viewPort)
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
	self.modFlag = false
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
	self.showConvert = curSpec.treeVersion ~= latestTreeVersion
	if self.build.itemsTab.itemOrderList[1] then
		-- Update item slots if items have been loaded already
		self.build.itemsTab:PopulateSlots()
	end
	-- Update the passive tree dropdown control in itemsTab
	self.build.itemsTab.controls.specSelect.selIndex = specId
end

function TreeTabClass:SetCompareSpec(specId)
	self.activeCompareSpec = m_min(specId, #self.specList)
	local curSpec = self.specList[self.activeCompareSpec]

	self.compareSpec = curSpec
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
	local versionLookup = "tree/([0-9]+)%.([0-9]+)%.([0-9]+)/"
	local controls = { }
	local function decodeTreeLink(treeLink, newTreeVersion)
			-- newTreeVersion is passed in as an output of validateTreeVersion(). It will always be a valid tree version text string
			-- If there was a version on the url, and it changed the version of the active spec, dump the active spec and get one of the right version. 
		if newTreeVersion ~= self.specList[self.activeSpec].treeVersion then
			local newSpec = new("PassiveSpec", self.build, newTreeVersion)
			newSpec:SelectClass(self.build.spec.curClassId)
			newSpec:SelectAscendClass(self.build.spec.curAscendClassId)
			newSpec.title = self.build.spec.title
			self.specList[self.activeSpec] = newSpec
			-- trigger all the things that go with changing a spec
			self:SetActiveSpec(self.activeSpec)
			self.modFlag = true
		end
	
		-- We will now have a spec that matches the version of the binary being imported
		local errMsg = self.build.spec:DecodeURL(treeLink)
		if errMsg then
			controls.msg.label = "^1"..errMsg
		else
			self.build.spec:AddUndoState()
			self.build.buildFlag = true
			main:ClosePopup()
		end
	end
	local function validateTreeVersion(major, minor)
		-- Take the Major and Minor version numbers and confirm it is a valid tree version. The point release is also passed in but it is not used
		-- Return: the passed in tree version as text or latestTreeVersion
		if major and minor then
			--need leading 0 here
			local newTreeVersionNum = tonumber(string.format("%d.%02d", major, minor))
			if newTreeVersionNum >= treeVersions[defaultTreeVersion].num and newTreeVersionNum <= treeVersions[latestTreeVersion].num then
				-- no leading 0 here
				return string.format("%s_%s", major, minor)
			else
				print(string.format("Version '%d_%02d' is out of bounds", major, minor))
			end
		end
		return latestTreeVersion
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
						controls.msg.label = "^1"..errMsg
						controls.import.enabled = true
						return
					else
						decodeTreeLink(treeLink, validateTreeVersion(treeLink:match(versionLookup)))
					end
				end)
			end
		elseif treeLink:match("poeskilltree.com/") then
			local oldStyleVersionLookup = "/%?v=([0-9]+)%.([0-9]+)%.([0-9]+)#"
			-- Strip the version from the tree : https://poeskilltree.com/?v=3.6.0#AAAABAMAABEtfIOFMo6-ksHfsOvu -> https://poeskilltree.com/AAAABAMAABEtfIOFMo6-ksHfsOvu
			decodeTreeLink(treeLink:gsub("/%?v=.+#","/"), validateTreeVersion(treeLink:match(oldStyleVersionLookup)))
		else
			-- EG: https://www.pathofexile.com/passive-skill-tree/3.15.0/AAAABgMADI6-HwKSwQQHLJwtH9-wTLNfKoP3ES3r5AAA
			-- EG: https://www.pathofexile.com/fullscreen-passive-skill-tree/3.15.0/AAAABgMADAQHES0fAiycLR9Ms18qg_eOvpLB37Dr5AAA
			decodeTreeLink(treeLink, validateTreeVersion(treeLink:match(versionLookup)))
		end
	end)
	controls.cancel = new("ButtonControl", nil, 45, 80, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(380, 110, "Import Tree", controls, "import", "edit")
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

function TreeTabClass:SetPowerCalc(selection)
	self.viewer.showHeatMap = true
	self.build.buildFlag = true
	self.build.calcsTab.powerBuildFlag = true
	self.build.calcsTab.powerStat = selection
	if self.showPowerReport then
		self.controls.allocatedNodeToggle.enabled = false
		self.controls.allocatedNodeDistance.enabled = false
		self.controls.powerReportList.label = "Building table..."
		self.build.calcsTab:BuildPower({ func = self.TogglePowerReport, caller = self })
	end
end

function TreeTabClass:BuildPowerReportUI()
	self.controls.powerReport.tooltipText = "A report of node efficacy based on current heat map selection"

	self.controls.allocatedNodeToggle = new("ButtonControl", {"TOPLEFT", self.controls.powerReportList, "TOPRIGHT" }, 8, 4, 160, 20, "Show allocated nodes", function()
		self.controls.powerReportList.allocated = not self.controls.powerReportList.allocated
		self.controls.allocatedNodeDistance.shown = self.controls.powerReportList.allocated
		self.controls.allocatedNodeDistance.enabled = self.controls.powerReportList.allocated
		self.controls.allocatedNodeToggle.label = self.controls.powerReportList.allocated and "Show Unallocated Nodes" or "Show allocated nodes"
		self.controls.powerReportList.pathLength = tonumber(self.controls.allocatedNodeDistance.buf or 1)
		self.controls.powerReportList:ReList()
	end)

	self.controls.allocatedNodeDistance = new("EditControl", {"TOPLEFT", self.controls.allocatedNodeToggle, "BOTTOMLEFT" }, 0, 4, 125, 20, 1, "Max path", "%D", 100, function(buf)
		self.controls.powerReportList.pathLength = tonumber(buf)
		self.controls.powerReportList:ReList()
	end)
end

function TreeTabClass:TogglePowerReport(caller)
	self = self or caller
	self.controls.powerReport.label = self.showPowerReport and "Hide Power Report" or "Show Power Report"
	local currentStat = self.build.calcsTab and self.build.calcsTab.powerStat or nil
	local report = {}
	if not self.showPowerReport and self.controls.powerReportList then
		self.controls.powerReportList.shown = false
		return
	end

	report = self:BuildPowerReportList(currentStat)
	local yPos = self.controls.treeHeatMap.y == 0 and self.controls.specSelect.height + 4 or self.controls.specSelect.height * 2 + 8
	self.controls.powerReportList = new("PowerReportListControl", {"TOPLEFT", self.controls.specSelect, "BOTTOMLEFT"}, 0, yPos, 700, 220, report, currentStat and currentStat.label or "", function(selectedNode)
		-- this code is called by the list control when the user "selects" one of the passives in the list.
		-- we use this to set a flag which causes the next Draw() to recenter the passive tree on the desired node.
		if selectedNode.x then
			self.jumpToNode = true
			self.jumpToX = selectedNode.x
			self.jumpToY = selectedNode.y
		end
	end)

	if not self.controls.allocatedNodeToggle then
		self:BuildPowerReportUI()
	end
	self.controls.allocatedNodeToggle:SetAnchor("TOPLEFT", self.controls.powerReportList, main.portraitMode and "BOTTOMLEFT" or "TOPRIGHT")
	self.controls.powerReportList.shown = self.showPowerReport

	-- the report doesn't support listing the "offense/defense" hybrid heatmap, as it is not a single scalar and im unsure how to quantify numerically
	-- especially given the heatmap's current approach of using the sqrt() of both components. that number is cryptic to users, i suspect.
	if currentStat and currentStat.stat then
		self.controls.powerReportList.label = "Click to focus node on tree"
		self.controls.powerReportList.enabled = true
	else
		self.controls.powerReportList.label = "^7\"Offense/Defense\" not supported.  Select a specific stat from the dropdown."
		self.controls.powerReportList.enabled = false
	end

	self.controls.allocatedNodeToggle.enabled = self.controls.powerReportList.enabled
	self.controls.allocatedNodeDistance.shown = self.controls.powerReportList.allocated
	self.controls.allocatedNodeToggle.label = self.controls.powerReportList.allocated and "Show Unallocated Nodes" or "Show allocated nodes"
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
			local nodePower = (node.power.singleStat or 0) * ((displayStat.pc or displayStat.mod) and 100 or 1)
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
	local controls = { }
	local modData = { }
	local smallAdditions = { "Strength", "Dex", "Devotion" }
	local searchResults = { }
	local jewelTypes = {
		{ label = "Glorious Vanity", name = "vaal", id = 1 },
		{ label = "Lethal Pride", name = "karui", id = 2 },
		{ label = "Brutal Restraint", name = "maraketh", id = 3 },
		{ label = "Militant Faith", name = "templar", id = 4 },
		{ label = "Elegant Hubris", name = "eternal", id = 5 }
	}
	local jewelType = jewelTypes[1]
	local conquerorTypes = {
		[1] = {
			{ label = "Doryani (Corrupted Soul)", id = 1 },
			{ label = "Xibaqua (Divine Flesh)", id = 2 },
			{ label = "Ahuana (Immortal Ambition)", id = 3 }
		},
		[2] = {
			{ label = "Kaom (Strength of Blood)", id = 1 },
			{ label = "Rakiata (Tempered by War)", id = 2 },
			{ label = "Akoya (Chainbreaker)", id = 3 }
		},
		[3] = {
			{ label = "Asenath (Dance with Death)", id = 1 },
			{ label = "Nasima (Second Sight)", id = 2 },
			{ label = "Balbala (The Traitor)", id = 3 }
		},
		[4] = {
			{ label = "Avarius (Power of Purpose)", id = 1 },
			{ label = "Dominus (Inner Conviction)", id = 2 },
			{ label = "Maxarius (Transcendence)", id = 3 }
		},
		[5] = {
			{ label = "Cadiro (Supreme Decadence)", id = 1 },
			{ label = "Victario (Supreme Grandstanding)", id = 2 },
			{ label = "Caspiro (Supreme Ostentation)", id = 3 }
		},
	}
	local conquerorType = conquerorTypes[jewelType.id][1]
	local jewelSockets = { }
	for socketId, socketData in pairs(self.build.spec.nodes) do
		if socketData.isJewelSocket then
			local keystone = "Unknown"
			if socketId == 6230 then
				keystone = "Iron Will"
			elseif socketId == 48768 then
				keystone = "Conduit"
			elseif socketId == 31683 then
				keystone = "Magebane"
			elseif socketId == 36634 then
				keystone = "Mind over Matter"
			elseif socketId == 41263 then
				keystone = "Pain Attunement"
			elseif socketId == 33989 then
				keystone = "Supreme Ego"
			elseif socketId == 34483 then
				keystone = "Elemental Equilibrium"
			elseif socketId == 28475 then
				keystone = "Unwavering Stance"
			elseif socketId == 33631 then
				keystone = "Eternal Youth"
			elseif socketId == 7960 then
				keystone = "Zealot's Oath"
			elseif socketId == 21984 then
				keystone = "Eldritch Battery"
			elseif socketId == 32763 then
				keystone = "Perfect Agony"
			elseif socketId == 46882 then
				keystone = "Point Blank"
			elseif socketId == 2491 then
				keystone = "Call to Arms"
			elseif socketId == 55190 then
				keystone = "Divine Shield"
			elseif socketId == 26196 then
				keystone = "Runebinder"
			elseif socketId == 61419 then
				keystone = "Doomsday"
			elseif socketId == 61834 then
				keystone = "Ghost Dance"
			elseif socketId == 60735 then
				keystone = "Acrobatics"
			elseif socketId == 54127 then
				keystone = "Duelist"
			elseif socketId == 26725 then
				keystone = "Marauder"
			end
			local label = keystone .. ": " .. socketId
			if self.build.spec.allocNodes[socketId] then
				label = "# " .. label
			end
			t_insert(jewelSockets, {
				label = label,
				keystone = keystone,
				id = socketId,
			})
		end
	end
	t_sort(jewelSockets, function(a, b) return a.label < b.label end)
	local jewelSocket = jewelSockets[1]

	local function buildMods()
		wipeTable(modData)
		for _, node in pairs(legionNodes) do
			if node.id:match("^" .. jewelType.name .. "_.+") and node["not"] and not node.ks then
				t_insert(modData, {
					label = node.dn,
					descriptions = copyTable(node.sd),
					type = jewelType.name,
					id = node.id,
				})
			end
		end
		for _, addition in pairs(legionAdditions) do
			-- exclude passives that are already added (vaal, attributes, devotion)
			if addition.id:match("^" .. jewelType.name .. "_.+") and not isValueInArray(smallAdditions, addition.dn) and jewelType.name ~= "vaal" then
				t_insert(modData, {
					label = addition.dn,
					descriptions = copyTable(addition.sd),
					type = jewelType.name,
					id = addition.id,
				})
			end
		end
		t_sort(modData, function(a, b) return a.label < b.label end)
	end

	controls.jewelSelectLabel = new("LabelControl", { "TOPRIGHT", nil, "TOPLEFT" }, 165, 25, 0, 16, "^7Jewel Type:")
	controls.jewelSelect = new("DropDownControl", { "LEFT", controls.jewelSelectLabel, "RIGHT" }, 43, 0, 200, 18, jewelTypes, function(index, value)
		jewelType = value
		controls.conquerorSelect:SetList(conquerorTypes[jewelType.id])
		buildMods()
	end)

	controls.conquerorSelectLabel = new("LabelControl", { "TOPLEFT", controls.jewelSelectLabel, "TOPLEFT" }, 0, 25, 0, 16, "^7Conqueror:")
	controls.conquerorSelect = new("DropDownControl", { "LEFT", controls.conquerorSelectLabel, "RIGHT" }, 45, 0, 200, 18, conquerorTypes[jewelType.id], function(index, value)
		conquerorType = value
	end)

	controls.socketSelectLabel = new("LabelControl", { "TOPLEFT", controls.conquerorSelectLabel, "TOPLEFT" }, 0, 25, 0, 16, "^7Jewel Socket:")
	controls.socketSelect = new("TimelessJewelSocketControl", { "LEFT", controls.socketSelectLabel, "RIGHT" }, 32, 0, 200, 18, jewelSockets, function(index, value)
		jewelSocket = value
	end, self.build, socketViewer, { controls.jewelSelect, controls.conquerorSelect })
	
	controls.socketFilterLabel = new("LabelControl", { "TOPLEFT", controls.socketSelectLabel, "TOPLEFT" }, 0, 25, 0, 16, "^7Filter Nodes:")
	controls.socketFilter = new("CheckBoxControl", { "LEFT", controls.socketFilterLabel, "RIGHT" }, 37, 0, 18)
	controls.socketFilter.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		tooltip:AddLine(16, "^7Enable this option to exclude nodes that you do not have allocated on your active passive skill tree.")
		tooltip:AddLine(16, "^7This can be useful if you're never going to path towards those excluded nodes and don't care what happens to them.")
	end

	buildMods()
	controls.nodeSelectLabel = new("LabelControl", { "TOPLEFT", controls.socketFilterLabel, "TOPLEFT" }, 0, 25, 0, 16, "^7Search for Node:")
	controls.nodeSelect = new("DropDownControl", { "LEFT", controls.nodeSelectLabel, "RIGHT" }, 10, 0, 200, 18, modData, function(index, value)
		controls.searchList.caret = #controls.searchList.buf + 1
		controls.searchList:Insert((#controls.searchList.buf > 0 and "\n" or "") .. value.id)
	end)
	controls.nodeSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" and value then
			for _, line in ipairs(value.descriptions) do
				tooltip:AddLine(16, "^7" .. line)
			end
		end
	end

	controls.searchListLabel = new("LabelControl", { "TOPLEFT", controls.nodeSelectLabel, "TOPLEFT" }, -74, 25, 0, 16, "^7Desired Nodes:")
	controls.searchList = new("EditControl", { "TOPLEFT", controls.searchListLabel, "TOPLEFT" }, 0, 25, 225, 200, "", nil, "^%C\t\n", nil, nil, 16, true)

	controls.searchResultsLabel = new("LabelControl", { "TOPLEFT", controls.nodeSelectLabel, "TOPLEFT" }, 167, 25, 0, 16, "^7Search Results:")
	controls.searchResults = new("TimelessJewelListControl", { "TOPLEFT", controls.searchResultsLabel, "TOPLEFT" }, 0, 25, 225, 200, searchResults, self.build)

	controls.search = new("ButtonControl", nil, -90, 385, 80, 20, "Search", function()
		if treeData.nodes[jewelSocket.id] and treeData.nodes[jewelSocket.id].isJewelSocket then
			local radiusNodes = treeData.nodes[jewelSocket.id].nodesInRadius[3] -- large radius around jewelSocket.id
			local allocatedNodes = { }
			local targetNodes = { }
			local desiredNodes = { }
			local seedMatchData = { }
			if controls.socketFilter.state then
				for nodeId in pairs(radiusNodes) do
					allocatedNodes[nodeId] = self.build.calcsTab.mainEnv.grantedPassives[nodeId] or self.build.spec.allocNodes[nodeId]
				end
			end
			for nodeId in pairs(radiusNodes) do
				if treeData.nodes[nodeId].isNotable
				and not treeData.nodes[nodeId].isJewelSocket
				and not treeData.nodes[nodeId].isKeystone
				and (not controls.socketFilter.state or allocatedNodes[nodeId]) then
					targetNodes[nodeId] = true
				end
			end
			for desiredNode in controls.searchList.buf:gmatch("[^\r\n]+") do
				desiredNodes[desiredNode] = true
			end
			local seedMatchDataLength = 0
			local seedMultiplier = jewelType.id == 5 and 20 or 1 -- Elegant Hubris
			for curSeed = data.timelessJewelSeedMin[jewelType.id] * seedMultiplier, data.timelessJewelSeedMax[jewelType.id] * seedMultiplier, seedMultiplier do
				seedMatchData[curSeed] = { }
				for targetNode in pairs(targetNodes) do
					local jewelDataTbl = data.readLUT(curSeed, targetNode, jewelType.id)
					if not next(jewelDataTbl) then
						ConPrintf("Missing LUT: " .. jewelType.label)
					else
						for _, jewelData in ipairs(jewelDataTbl) do
							local nodeId = nil
							if jewelData >= 94 then -- replace
								nodeId = legionNodes[jewelData - 94].id
							else -- add
								nodeId = legionAdditions[jewelData].id
							end
							if nodeId and desiredNodes[nodeId] then
								seedMatchData[curSeed][nodeId] = (seedMatchData[curSeed][nodeId] or 0) + 1
								seedMatchData[curSeed].matchTotal = (seedMatchData[curSeed].matchTotal or 0) + 1
								if seedMatchData[curSeed].matchTotal == 1 then
									seedMatchDataLength = seedMatchDataLength + 1
								end
							end
						end
						if next(targetNodes, targetNode) == nil then
							-- arbritary limit to avoid running out of memory
							if seedMatchDataLength > 200 then
								local lowestMatchTotal = math.huge
								for seedId, seedData in pairs(seedMatchData) do
									if seedData.matchTotal then
										lowestMatchTotal = m_min(seedData.matchTotal, lowestMatchTotal)
									end
								end
								if lowestMatchTotal ~= math.huge then
									for seedId, seedData in pairs(seedMatchData) do
										if seedData.matchTotal and seedData.matchTotal <= lowestMatchTotal then
											seedMatchData[seedId] = nil
											seedMatchDataLength = seedMatchDataLength - 1
										end
									end
								end
							end
						end
					end
				end
			end
			wipeTable(searchResults)
			local searchResultsIdx = 1
			for seedMatch, seedData in pairs(seedMatchData) do
				if seedData.matchTotal then
					searchResults[searchResultsIdx] = { }
					searchResults[searchResultsIdx].label = "Seed " .. seedMatch .. ": "
					for desiredNode in pairs(desiredNodes) do
						if seedData[desiredNode] then
							searchResults[searchResultsIdx].label = searchResults[searchResultsIdx].label .. " " .. seedData[desiredNode]
						else
							searchResults[searchResultsIdx].label = searchResults[searchResultsIdx].label .. " 0"
						end
					end
					searchResults[searchResultsIdx].type = jewelType
					searchResults[searchResultsIdx].conqueror = conquerorType.id
					searchResults[searchResultsIdx].socket = jewelSocket
					searchResults[searchResultsIdx].seed = seedMatch
					searchResults[searchResultsIdx].total = seedData.matchTotal
					searchResultsIdx = searchResultsIdx + 1
				end
			end
			t_sort(searchResults, function(a, b) return a.total > b.total end)
		end
	end)
	controls.reset = new("ButtonControl", nil, 0, 385, 80, 20, "Reset", function()
		controls.searchList:SetText("")
		wipeTable(searchResults)
	end)
	controls.close = new("ButtonControl", nil, 90, 385, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(500, 417, "Find a Timeless Jewel", controls, "search")
end