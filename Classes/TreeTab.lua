-- Path of Building
--
-- Module: Tree Tab
-- Passive skill tree tab for the current build.
--
local ipairs = ipairs
local t_insert = table.insert
local t_sort = table.sort
local m_max = math.max
local m_min = math.min
local m_floor = math.floor
local s_format = string.format

local TreeTabClass = newClass("TreeTab", "ControlHost", function(self, build)
	self.ControlHost()

	self.build = build

	self.viewer = new("PassiveTreeView")

	self.specList = { }
	self.specList[1] = new("PassiveSpec", build, latestTreeVersion)
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
				tooltip:AddLine(16, "Game Version: "..treeVersions[spec.treeVersion].display)
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

	self.controls.powerReportVert = new("ButtonControl", {"LEFT", self.anchorControls, "RIGHT"}, 1585, -550, 115, 20, "Power Report V", function()
		self:ShowPowerReport()
	end, true)
	self.controls.powerReport = new("ButtonControl", {"LEFT", self.controls.treeHeatMapStatPerPoint, "RIGHT"}, 8, 0, 120, 20, "Power Report", function()
		self:ShowPowerReport()
	end)
	self.controls.powerReport.tooltipText = function()
		return "View a report of node efficacy based on current heat map selection"
	end

	self.controls.specConvertText = new("LabelControl", {"BOTTOMLEFT",self.controls.specSelect,"TOPLEFT"}, 0, -14, 0, 16, "^7This is an older tree version, which may not be fully compatible with the current game version.")
	self.controls.specConvertText.shown = function()
		return self.showConvert
	end
	self.controls.specConvert = new("ButtonControl", {"LEFT",self.controls.specConvertText,"RIGHT"}, 8, 0, 120, 20, "^2Convert to "..treeVersions[latestTreeVersion].display, function()
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
	local twoLineHeight = self.controls.treeHeatMap.y == 24 and 26 or 0
	if(select(1, self.controls.powerReport:GetPos()) + select(1, self.controls.powerReport:GetSize()) > viewPort.x + viewPort.width) then
		twoLineHeight = 26
		self.controls.treeHeatMap:SetAnchor("BOTTOMLEFT",self.controls.specSelect,"BOTTOMLEFT",nil,nil,nil)
		self.controls.treeHeatMap.y = 24
		self.controls.treeHeatMap.x = 125

		self.controls.specSelect.y = -24
		self.controls.specConvertText.y = -16
	elseif viewPort.x + viewPort.width - (select(1, self.controls.treeSearch:GetPos()) + select(1, self.controls.treeSearch:GetSize())) > (select(1, self.controls.powerReport:GetPos()) + select(1, self.controls.powerReport:GetSize())) - viewPort.x  then
		twoLineHeight = 0
		self.controls.treeHeatMap:SetAnchor("LEFT",self.controls.treeSearch,"RIGHT",nil,nil,nil)
		self.controls.treeHeatMap.y = 0
		self.controls.treeHeatMap.x = 130

		self.controls.specSelect.y = 0
		self.controls.specConvertText.y = -14
	end
	--

	local treeViewPort = { x = viewPort.x, y = viewPort.y, width = viewPort.width, height = viewPort.height - (self.showConvert and 64 + twoLineHeight or 32 + twoLineHeight)}
	if self.jumpToNode then
		self.viewer:Focus(self.jumpToX, self.jumpToY, treeViewPort, self.build)
		self.jumpToNode = false
	end
	self.viewer:Draw(self.build, treeViewPort, inputEvents)

	self.controls.specSelect.selIndex = self.activeSpec
	wipeTable(self.controls.specSelect.list)
	for id, spec in ipairs(self.specList) do
		t_insert(self.controls.specSelect.list, (spec.treeVersion ~= latestTreeVersion and ("["..treeVersions[spec.treeVersion].display.."] ") or "")..(spec.title or "Default"))
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
	self.showConvert = curSpec.treeVersion ~= latestTreeVersion
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

function TreeTabClass:ModifyNodePopup(selectedNode)
	local controls = { }
	local modGroups = { }
	local smallAdditions = {"Strength", "Dex", "Devotion"}
	if not self.build.latestTree.legion.editedNodes then
		self.build.latestTree.legion.editedNodes = { }
	end
	local function buildMods(selectedNode)
		wipeTable(modGroups)
		for _, node in pairs(self.build.latestTree.legion.nodes) do
			if node.id:match("^"..selectedNode.conqueredBy.conqueror.type.."_.+") and node["not"] == (selectedNode.isNotable or false) and not node.ks then
				t_insert(modGroups, {
					label = node.dn,
					descriptions = copyTable(node.sd),
					type = selectedNode.conqueredBy.conqueror.type,
					id = node.id,
				})
			end
		end
		for _, addition in pairs(self.build.latestTree.legion.additions) do
			-- exclude passives that are already added (vaal, attributes, devotion)
			if addition.id:match("^"..selectedNode.conqueredBy.conqueror.type.."_.+") and not isValueInArray(smallAdditions, addition.dn) and selectedNode.conqueredBy.conqueror.type ~= "vaal" then
				t_insert(modGroups, {
					label = addition.dn,
					descriptions = copyTable(addition.sd),
					type = selectedNode.conqueredBy.conqueror.type,
					id = addition.id,
				})
			end
		end
	end
	local function addModifier(selectedNode)
		local newLegionNode = self.build.latestTree.legion.nodes[modGroups[controls.modSelect.selIndex].id]
		-- most nodes only replace or add 1 mod, so we need to just get the first control
		local modDesc = string.gsub(controls[1].label, "%^7", "")
		if  selectedNode.conqueredBy.conqueror.type == "eternal" or selectedNode.conqueredBy.conqueror.type == "templar" then
			self.specList[1]:NodeAdditionOrReplacementFromString(selectedNode, modDesc, true)
			selectedNode.dn = newLegionNode.dn
			selectedNode.sprites = newLegionNode.sprites
			selectedNode.icon = newLegionNode.icon
			selectedNode.spriteId = newLegionNode.id
		elseif selectedNode.conqueredBy.conqueror.type == "vaal" then
			selectedNode.dn = newLegionNode.dn
			selectedNode.sprites = newLegionNode.sprites
			selectedNode.icon = newLegionNode.icon
			selectedNode.spriteId = newLegionNode.id
			self.specList[1]:NodeAdditionOrReplacementFromString(selectedNode, modDesc, true)

			-- Vaal is the exception
			if controls[2] then
				modDesc = string.gsub(controls[2].label, "%^7", "")
				self.specList[1]:NodeAdditionOrReplacementFromString(selectedNode, modDesc, false)
			end
		else
			-- Replace the node first before adding the new line so we don't get multiple lines
			if self.build.latestTree.legion.editedNodes[selectedNode.conqueredBy.id] and self.build.latestTree.legion.editedNodes[selectedNode.conqueredBy.id][selectedNode.id] then
				self.specList[1]:ReplaceNode(selectedNode, self.build.latestTree.nodes[selectedNode.id])
			end
			self.specList[1]:NodeAdditionOrReplacementFromString(selectedNode, modDesc, false)
		end
		if not self.build.latestTree.legion.editedNodes[selectedNode.conqueredBy.id] then
			t_insert(self.build.latestTree.legion.editedNodes, selectedNode.conqueredBy.id, {})
		end
		t_insert(self.build.latestTree.legion.editedNodes[selectedNode.conqueredBy.id], selectedNode.id, copyTable(selectedNode, true))
	end

	local function constructUI(modGroup)
		local totalHeight = 43
		local i = 1
		while controls[i] or controls["slider"..i] do
			controls[i] = nil
			controls["slider"..i] = nil
			i = i + 1
		end
		for idx, desc in ipairs(modGroup.descriptions) do
			controls[idx] = new("LabelControl", {"TOPLEFT", controls["slider"..idx-1] or controls[idx-1] or controls.modSelect,"TOPLEFT"}, 0, 20, 600, 16, "^7"..desc)
			totalHeight = totalHeight + 20
			if desc:match("%(%-?[%d%.]+%-[%d%.]+%)") then
				controls["slider"..idx] = new("SliderControl", {"TOPLEFT",controls[idx],"BOTTOMLEFT"}, 0, 2, 300, 16, function(val)
					controls[idx].label = itemLib.applyRange(modGroup.descriptions[idx], val)
				end)
				controls["slider"..idx]:SetVal(.5)
				controls["slider"..idx].width = function()
					return controls["slider"..idx].divCount and 300 or 100
				end
				totalHeight = totalHeight + 20
			end
		end
		main.popups[1].height = totalHeight + 30
		controls.save.y = totalHeight
		controls.reset.y = totalHeight
		controls.close.y = totalHeight
	end

	buildMods(selectedNode)
	controls.modSelectLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 150, 25, 0, 16, "^7Modifier:")
	controls.modSelect = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 155, 25, 579, 18, modGroups, function(idx) constructUI(modGroups[idx]) end)
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
		if self.build.latestTree.legion.editedNodes[selectedNode.conqueredBy.id] then
			self.build.latestTree.legion.editedNodes[selectedNode.conqueredBy.id][selectedNode.id] = nil
		end
		if selectedNode.conqueredBy.conqueror.type == "vaal" and selectedNode.type == "Normal" then
			local legionNode = self.build.latestTree.legion.nodes["vaal_small_fire_resistance"]
			selectedNode.dn = "Vaal small node"
			selectedNode.sd = {"Right click to set mod"}
			selectedNode.sprites = legionNode.sprites
			selectedNode.mods = {""}
			selectedNode.modList = new("ModList")
			selectedNode.modKey = ""
		elseif selectedNode.conqueredBy.conqueror.type == "vaal" and selectedNode.type == "Notable" then
			local legionNode = self.build.latestTree.legion.nodes["vaal_notable_curse_1"]
			selectedNode.dn = "Vaal notable node"
			selectedNode.sd = {"Right click to set mod"}
			selectedNode.sprites = legionNode.sprites
			selectedNode.mods = {""}
			selectedNode.modList = new("ModList")
			selectedNode.modKey = ""
		else
			self.specList[1]:ReplaceNode(selectedNode, self.build.latestTree.nodes[selectedNode.id])
			if selectedNode.conqueredBy.conqueror.type == "templar" then
				self.specList[1]:NodeAdditionOrReplacementFromString(selectedNode,"+5 to Devotion")
			end
		end
		self.modFlag = true
		self.build.buildFlag = true
		main:ClosePopup()
	end)
	controls.close = new("ButtonControl", nil, 90, 75, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(800, 105, "Replace Modifier of Node", controls, "save")
	constructUI(modGroups[1])
end

function TreeTabClass:ShowPowerReport()
	local report = {}
	local currentStat = self.build.calcsTab.powerStat
	
	-- the report doesn't support listing the "offense/defense" hybrid heatmap, as it is not a single scalar and im unsure how to quantify numerically
	-- especially given the heatmap's current approach of using the sqrt() of both components. that number is cryptic to users, i suspect.
	if not currentStat or not currentStat.stat then
		main:OpenMessagePopup("Select a specific stat", "This feature does not report for the \"Offense/Defense\" heat map. Select a specific stat from the dropdown.")
		return
	end

	-- locate formatting information for the type of heat map being used.
	-- maybe a better place to find this? At the moment, it is the only place
	-- in the code that has this information in a tidy place.
	local currentStatLabel = currentStat.label
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

	-- search all nodes, ignoring ascendcies, sockets, etc.
	for nodeId, node in pairs(self.build.spec.nodes) do
		local isAlloc = node.alloc or self.build.calcsTab.mainEnv.grantedPassives[nodeId]
		if not isAlloc and (node.type == "Normal" or node.type == "Keystone" or node.type == "Notable") and not node.ascendancyName then
			local nodePower = (node.power.singleStat or 0) * ((displayStat.pc or displayStat.mod) and 100 or 1)
			local nodePowerStr = s_format("%"..displayStat.fmt, nodePower)

			if main.showThousandsCalcs then
				nodePowerStr = formatNumSep(nodePowerStr)
			end
			
			if (nodePower > 0 and not displayStat.lowerIsBetter) or (nodePower < 0 and displayStat.lowerIsBetter) then
				nodePowerStr = colorCodes.POSITIVE .. nodePowerStr
			elseif (nodePower < 0 and not displayStat.lowerIsBetter) or (nodePower > 0 and displayStat.lowerIsBetter) then
				nodePowerStr = colorCodes.NEGATIVE .. nodePowerStr
			end
			
			t_insert(report, {
				name = node.dn,
				power = nodePower,
				powerStr = nodePowerStr,
				id = node.id,
				x = node.x,
				y = node.y,
				type = node.type,
				pathDist = node.pathDist
			})
		end
	end

	-- search all cluster notables and add to the list
	for nodeName, node in pairs(self.build.spec.tree.clusterNodeMap) do
		local isAlloc = node.alloc
		if not isAlloc then			
			local nodePower = (node.power.singleStat or 0) * ((displayStat.pc or displayStat.mod) and 100 or 1)
			local nodePowerStr = s_format("%"..displayStat.fmt, nodePower)

			if main.showThousandsCalcs then
				nodePowerStr = formatNumSep(nodePowerStr)
			end
			
			if (nodePower > 0 and not displayStat.lowerIsBetter) or (nodePower < 0 and displayStat.lowerIsBetter) then
				nodePowerStr = colorCodes.POSITIVE .. nodePowerStr
			elseif (nodePower < 0 and not displayStat.lowerIsBetter) or (nodePower > 0 and displayStat.lowerIsBetter) then
				nodePowerStr = colorCodes.NEGATIVE .. nodePowerStr
			end
			
			t_insert(report, {
				name = node.dn,
				power = nodePower,
				powerStr = nodePowerStr,
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

	-- present the UI
	local controls = {}
	controls.powerReport = new("PowerReportListControl", nil, 0, 0, 550, 450, report, currentStatLabel, function(selectedNode)
		-- this code is called by the list control when the user "selects" one of the passives in the list.
		-- we use this to set a flag which causes the next Draw() to recenter the passive tree on the desired node.
		if(selectedNode.x) then
			self.jumpToNode = true
			self.jumpToX = selectedNode.x
			self.jumpToY = selectedNode.y
			main:ClosePopup()
		end		
	end)
	
	controls.done = new("ButtonControl", nil, 0, 490, 100, 20, "Close", function()
		main:ClosePopup()
	end)

	popup = main:OpenPopup(600, 500, "Power Report: " .. currentStatLabel, controls, "done", "list")
end