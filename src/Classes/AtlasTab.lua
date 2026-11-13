local ipairs = ipairs
local t_insert = table.insert
local t_concat = table.concat
local m_min = math.min
local m_max = math.max

local statPanelWidth = 320

local AtlasTabClass = newClass("AtlasTab", "ControlHost")

function AtlasTabClass:AtlasTab(build)
	self:ControlHost()

	self.build = build
	self.viewer = new("AtlasTreeView"):AtlasTreeView()
	self.statPanel = new("AtlasStatPanel"):AtlasStatPanel(self)
	if not main.atlasLibrary then
		main.atlasLibrary = new("AtlasLibrary"):AtlasLibrary(main.userPath and (main.userPath .. "AtlasTrees.xml"))
	end
	self.library = main.atlasLibrary
	self.specList = self.library.specList
	self:SetActiveSpec(self.library.activeSpec)

	self.versionKeys = { }
	local versionLabels = { }
	for i = #atlasTreeVersions, 1, -1 do
		t_insert(self.versionKeys, atlasTreeVersions[i].key)
		t_insert(versionLabels, atlasTreeVersions[i].display)
	end

	self.anchorControls = new("Control"):Control(nil, { 0, 0, 0, 20 })
	self.controls.specSelect = new("DropDownControl"):DropDownControl({ "LEFT", self.anchorControls, "RIGHT" }, { 0, 0, 220, 20 }, nil, function(index)
		if self.specList[index] then
			self.modFlag = self.modFlag or index ~= self.activeSpec
			self:SetActiveSpec(index)
		else
			self:OpenSpecManagePopup()
		end
	end)
	self.controls.specSelect.maxDroppedWidth = 1000
	self.controls.specSelect.enableDroppedWidth = true
	self.controls.versionLabel = new("LabelControl"):LabelControl({ "LEFT", self.controls.specSelect, "RIGHT" }, { 8, 0, 0, 16 }, "^7Version:")
	self.controls.versionSelect = new("DropDownControl"):DropDownControl({ "LEFT", self.controls.versionLabel, "RIGHT" }, { 4, 0, 150, 20 }, versionLabels, function(index)
		local key = self.versionKeys[index]
		if key and key ~= self.spec.treeVersion then
			local dropped = self.spec:SetTreeVersion(key)
			self.spec:AddUndoState()
			self.notice = dropped > 0 and (dropped .. " node" .. (dropped == 1 and "" or "s") .. " not in this version were removed") or nil
		end
	end)
	self.controls.clear = new("ButtonControl"):ButtonControl({ "LEFT", self.controls.versionSelect, "RIGHT" }, { 8, 0, 60, 20 }, "Clear", function()
		self:ClearActiveSpec()
	end)
	self.controls.import = new("ButtonControl"):ButtonControl({ "LEFT", self.controls.clear, "RIGHT" }, { 8, 0, 70, 20 }, "Import...", function()
		self:OpenImportPopup()
	end)
	self.controls.export = new("ButtonControl"):ButtonControl({ "LEFT", self.controls.import, "RIGHT" }, { 4, 0, 70, 20 }, "Export...", function()
		self:OpenExportPopup()
	end)
	self.controls.search = new("EditControl"):EditControl({ "LEFT", self.controls.export, "RIGHT" }, { 8, 0, 200, 20 }, "", "Search", "%c", 100, function(buf)
		self.viewer.searchStr = buf
	end, nil, nil, true)
	self.controls.notice = new("LabelControl"):LabelControl({ "LEFT", self.controls.search, "RIGHT" }, { 8, 0, 0, 16 }, function()
		return self.notice and ("^xFFB050" .. self.notice) or ""
	end)
	self.controls.collapseAll = new("ButtonControl"):ButtonControl(nil, { 0, 0, 145, 20 }, "Collapse All", function()
		self.statPanel:SetAllCollapsed(true)
		self.statPanel.layoutDirty = true
	end)
	self.controls.expandAll = new("ButtonControl"):ButtonControl({ "LEFT", self.controls.collapseAll, "RIGHT" }, { 10, 0, 145, 20 }, "Expand All", function()
		self.statPanel:SetAllCollapsed(false)
		self.statPanel.layoutDirty = true
	end)
	return self
end

function AtlasTabClass:GetSpecLabel(spec)
	local version = spec.treeVersion ~= latestAtlasTreeVersion and ("[" .. atlasTreeVersionMap[spec.treeVersion].display .. "] ") or ""
	return version .. (spec.title or "Default")
end

function AtlasTabClass:GetSpecList()
	local list = { }
	for _, spec in ipairs(self.specList) do
		t_insert(list, self:GetSpecLabel(spec))
	end
	return list
end

function AtlasTabClass:SetActiveSpec(index)
	self.activeSpec = m_max(1, m_min(index, #self.specList))
	self.spec = self.specList[self.activeSpec]
	self.library.activeSpec = self.activeSpec
	self.notice = nil
end

function AtlasTabClass:NewSpec(title)
	local spec = new("AtlasSpec"):AtlasSpec(latestAtlasTreeVersion, title)
	t_insert(self.specList, spec)
	self.modFlag = true
	self:SetActiveSpec(#self.specList)
	return spec
end

function AtlasTabClass:ClearActiveSpec()
	self.spec:ResetNodes()
	self.spec:AddUndoState()
end

function AtlasTabClass:HandleNodeClick(node)
	local spec = self.spec
	if node.type == "Root" or node.type == "Mastery" then
		return
	end
	if spec.allocNodes[node.id] then
		if node.variants then
			self:OpenVariantPopup(node)
			return
		end
		spec:DeallocNode(node)
		spec:AddUndoState()
	elseif spec:AllocNode(node) then
		spec:AddUndoState()
		if node.variants then
			self:OpenVariantPopup(node)
		end
	end
end

function AtlasTabClass:OpenVariantPopup(node)
	local spec = self.spec
	local labels = { }
	local selected = 1
	for index, variant in ipairs(node.variants) do
		t_insert(labels, t_concat(variant.sd, " / "))
		if variant.effect == spec.variantSelections[node.id] then
			selected = index
		end
	end
	local controls = { }
	controls.label = new("LabelControl"):LabelControl(nil, { 0, 20, 0, 16 }, "^7Choose the effect for this notable:")
	controls.variant = new("DropDownControl"):DropDownControl(nil, { 0, 44, 560, 20 }, labels, function(index)
		local variant = node.variants[index]
		if variant and spec:SetVariant(node.id, variant.effect) then
			spec:AddUndoState()
		end
	end)
	controls.variant.selIndex = selected
	controls.variant.enableDroppedWidth = true
	controls.variant.maxDroppedWidth = 1000
	controls.remove = new("ButtonControl"):ButtonControl(nil, { -50, 76, 90, 20 }, "Unallocate", function()
		spec:DeallocNode(node)
		spec:AddUndoState()
		main:ClosePopup()
	end)
	controls.done = new("ButtonControl"):ButtonControl(nil, { 50, 76, 90, 20 }, "Done", function()
		if not spec.variantSelections[node.id] and controls.variant.selIndex then
			controls.variant.selFunc(controls.variant.selIndex)
		end
		main:ClosePopup()
	end)
	main:OpenPopup(580, 108, node.dn, controls, "done", nil, "done")
end

function AtlasTabClass:OpenSpecManagePopup()
	main:OpenPopup(400, 290, "Manage Atlas Trees", {
		new("AtlasSpecListControl"):AtlasSpecListControl(nil, { 0, 50, 380, 200 }, self),
		new("ButtonControl"):ButtonControl(nil, { 0, 260, 90, 20 }, "Done", function()
			main:ClosePopup()
		end),
	})
end

function AtlasTabClass:OpenImportPopup()
	local controls = { }
	controls.label = new("LabelControl"):LabelControl(nil, { 0, 20, 0, 16 }, "^7Paste an atlas tree link (imports into '" .. self.spec.title .. "', version " .. atlasTreeVersionMap[self.spec.treeVersion].display .. "):")
	controls.edit = new("EditControl"):EditControl(nil, { 0, 40, 540, 20 }, "", nil, "%Z", nil, function(buf)
		controls.msg.label = ""
		controls.import.enabled = buf:match("%S") ~= nil
	end)
	controls.msg = new("LabelControl"):LabelControl(nil, { 0, 64, 0, 16 }, "")
	controls.import = new("ButtonControl"):ButtonControl(nil, { -45, 88, 80, 20 }, "Import", function()
		local ok, err = self.spec:DecodeURL(controls.edit.buf)
		if ok then
			self.spec:AddUndoState()
			main:ClosePopup()
		else
			controls.msg.label = "^1" .. err
		end
	end)
	controls.import.enabled = false
	controls.cancel = new("ButtonControl"):ButtonControl(nil, { 45, 88, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(580, 118, "Import Atlas Tree", controls, "import", "edit")
end

function AtlasTabClass:OpenExportPopup()
	local link = self.spec:EncodeURL()
	local controls = { }
	controls.label = new("LabelControl"):LabelControl(nil, { 0, 20, 0, 16 }, "^7Atlas tree link:")
	controls.edit = new("EditControl"):EditControl(nil, { 0, 40, 540, 20 }, link, nil, "%Z")
	controls.copy = new("ButtonControl"):ButtonControl(nil, { -45, 70, 80, 20 }, "Copy", function()
		Copy(link)
	end)
	controls.done = new("ButtonControl"):ButtonControl(nil, { 45, 70, 80, 20 }, "Done", function()
		main:ClosePopup()
	end)
	main:OpenPopup(580, 100, "Export Atlas Tree", controls, "done", "edit")
end

function AtlasTabClass:Load(xml)
	if self.library:ImportSpecs(xml) > 0 then
		self:SetActiveSpec(#self.specList)
	end
end

function AtlasTabClass:Draw(viewPort, inputEvents)
	self.anchorControls.x = viewPort.x + 4
	self.anchorControls.y = viewPort.y + viewPort.height - 24

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				self.spec:Undo()
				inputEvents[id] = nil
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self.spec:Redo()
				inputEvents[id] = nil
			elseif event.key == "f" and IsKeyDown("CTRL") then
				self:SelectControl(self.controls.search)
				inputEvents[id] = nil
			elseif event.key == "m" and IsKeyDown("CTRL") then
				self:OpenSpecManagePopup()
				inputEvents[id] = nil
			end
		end
	end

	local panelRect = { x = viewPort.x + viewPort.width - statPanelWidth, y = viewPort.y, width = statPanelWidth, height = viewPort.height - 32 }
	self.controls.collapseAll.x = panelRect.x + 10
	self.controls.collapseAll.y = panelRect.y + 56

	self:ProcessControlsInput(inputEvents, viewPort)

	local treeViewPort = { x = viewPort.x, y = viewPort.y, width = viewPort.width - statPanelWidth, height = viewPort.height - 32 }
	self.viewer:Draw(self.spec, treeViewPort, inputEvents, function(node)
		self:HandleNodeClick(node)
	end, self.highlightNodes)

	self.statPanel:Draw(panelRect, inputEvents)

	local specLabels = self:GetSpecList()
	t_insert(specLabels, "Manage atlas trees... (ctrl-m)")
	self.controls.specSelect:SetList(specLabels)
	self.controls.specSelect.selIndex = self.activeSpec
	for index, key in ipairs(self.versionKeys) do
		if key == self.spec.treeVersion then
			self.controls.versionSelect.selIndex = index
		end
	end

	SetDrawLayer(1)
	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - 30, viewPort.width, 30)
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height - 34, viewPort.width, 4)

	self:DrawControls(viewPort)

	if self.modFlag then
		self.library.modFlag = true
		self.modFlag = false
	end
	self.library.activeSpec = self.activeSpec
	self.library:SaveIfModified()
end
