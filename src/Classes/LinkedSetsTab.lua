-- Path of Building
--
-- Module: Linked Sets Tab
-- Linked Sets tab for the current build.
--
local pairs = pairs
local t_insert = table.insert

-- for showing current links and saving; exclude cases involving None
local function isValidLink(type, index, set)
	if type == "tree" then
		return index ~= "None" and not (set.skillSet == "None" and set.itemSet == "None")
	elseif type == "skill" then
		return index ~= "None" and not (set.treeSet == "None" and set.itemSet == "None")
	elseif type == "item" then
		return index ~= "None" and not (set.treeSet == "None" and set.skillSet == "None")
	end
end

local LinkedSetsTabClass = newClass("LinkedSetsTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build
	self.treeSetLinks = {}
	self.itemSetLinks = {}
	self.skillSetLinks = {}
	self.enabled = false

	local activeNote = ""
	local notesDesc = [[^7
	With this tab, you can manage links between item, skill, and tree sets.
	Each set is listed on the left, with two dropdowns on the right to create a link between the sets.

	For example, given Tree Set 2 has Skill Set 2 and Item Set 2 linked, if you change to Tree Set 2 either in the Tree Tab or Items Tab,
	Skill Set 2 and Item Set 2 should automatically set active as well.
	But given no other links were created, switching to active Tree Set 1, Skill Set 1, or Item Set 1 would do nothing to the other Sets.]]
	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, 16, notesDesc)

	self.controls.enabled = new("CheckBoxControl", { "TOPLEFT", self, "TOPLEFT" }, 80, 145, 18, "Enabled:", function(state)
		self.enabled = state
		self.modFlag = true
	end)

	local dropdownWidth = 200
	-- Tree Linked Sets
	-- Skill and Item controls are anchored to these three labels
	self.controls.treeSetLabelRoot = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 25, 200, 0, 16, "^7Tree Sets")
	self.controls.treeSetLabelDropdownSkill = new("LabelControl", {"LEFT",self.controls.treeSetLabelRoot,"RIGHT"}, dropdownWidth, 0, 0, 16, "^7Skill Sets")
	self.controls.treeSetLabelDropdownItem = new("LabelControl", {"LEFT",self.controls.treeSetLabelDropdownSkill,"RIGHT"}, dropdownWidth*0.75, 0, 0, 16, "^7Item Sets")
	self.controls.treeSetDropdown = new("DropDownControl", {"LEFT",self.controls.treeSetLabelRoot,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		self:InitLinks("tree", value)
		self:LoadDropdowns("tree", value)
	end)
	self.controls.treeSetDropdownSkill = new("DropDownControl", {"LEFT",self.controls.treeSetLabelDropdownSkill,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		local treeSetTitle = self.controls.treeSetDropdown.list[self.controls.treeSetDropdown.selIndex]
		self:InitLinks("tree", treeSetTitle)
		self.treeSetLinks[treeSetTitle]["skillSet"] = value
		self.modFlag = true
	end)
	self.controls.treeSetDropdownSkill.enabled = function() return self.controls.treeSetDropdown.selIndex ~= 1 end
	self.controls.treeSetDropdownItem = new("DropDownControl", {"LEFT",self.controls.treeSetLabelDropdownItem,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		local treeSetTitle = self.controls.treeSetDropdown.list[self.controls.treeSetDropdown.selIndex]
		self:InitLinks("tree", treeSetTitle)
		self.treeSetLinks[treeSetTitle]["itemSet"] = value
		self.modFlag = true
	end)
	self.controls.treeSetDropdownItem.enabled = function() return self.controls.treeSetDropdown.selIndex ~= 1 end

	-- Skill Linked Sets
	self.controls.skillSetLabelRoot = new("LabelControl", {"LEFT",self.controls.treeSetLabelRoot,"LEFT"}, 0, 70, 0, 16, "^7Skill Sets")
	self.controls.skillSetLabelDropdownTree = new("LabelControl", {"LEFT",self.controls.treeSetLabelDropdownSkill,"LEFT"}, 0, 70, 0, 16, "^7Tree Sets")
	self.controls.skillSetLabelDropdownItem = new("LabelControl", {"LEFT",self.controls.treeSetLabelDropdownItem,"LEFT"}, 0, 70, 0, 16, "^7Item Sets")
	self.controls.skillSetDropdown = new("DropDownControl", {"LEFT",self.controls.skillSetLabelRoot,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		self:InitLinks("skill", value)
		self:LoadDropdowns("skill", value)
	end)
	self.controls.skillSetDropdownTree = new("DropDownControl", {"LEFT",self.controls.skillSetLabelDropdownTree,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		local skillSetTitle = self.controls.skillSetDropdown.list[self.controls.skillSetDropdown.selIndex]
		self:InitLinks("skill", skillSetTitle)
		self.skillSetLinks[skillSetTitle]["treeSet"] = value
		self.modFlag = true
	end)
	self.controls.skillSetDropdownTree.enabled = function() return self.controls.skillSetDropdown.selIndex ~= 1 end
	self.controls.skillSetDropdownItem = new("DropDownControl", {"LEFT",self.controls.skillSetLabelDropdownItem,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		local skillSetTitle = self.controls.skillSetDropdown.list[self.controls.skillSetDropdown.selIndex]
		self:InitLinks("skill", skillSetTitle)
		self.skillSetLinks[skillSetTitle]["itemSet"] = value
		self.modFlag = true
	end)
	self.controls.skillSetDropdownItem.enabled = function() return self.controls.skillSetDropdown.selIndex ~= 1 end

	-- Item Linked Sets
	self.controls.itemSetLabelRoot = new("LabelControl", {"LEFT",self.controls.treeSetLabelRoot,"LEFT"}, 0, 140, 0, 16, "^7Item Sets")
	self.controls.itemSetLabelDropdownTree = new("LabelControl", {"LEFT",self.controls.treeSetLabelDropdownSkill,"LEFT"}, 0, 140, 0, 16, "^7Tree Sets")
	self.controls.itemSetLabelDropdownSkill = new("LabelControl", {"LEFT",self.controls.treeSetLabelDropdownItem,"LEFT"}, 0, 140, 0, 16, "^7Skill Sets")
	self.controls.itemSetDropdown = new("DropDownControl", {"LEFT",self.controls.itemSetLabelRoot,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		self:InitLinks("item", value)
		self:LoadDropdowns("item", value)
	end)
	self.controls.itemSetDropdownTree = new("DropDownControl", {"LEFT",self.controls.itemSetLabelDropdownTree,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		local itemSetTitle = self.controls.itemSetDropdown.list[self.controls.itemSetDropdown.selIndex]
		self:InitLinks("item", itemSetTitle)
		self.itemSetLinks[itemSetTitle]["treeSet"] = value
		self.modFlag = true
	end)
	self.controls.itemSetDropdownTree.enabled = function() return self.controls.itemSetDropdown.selIndex ~= 1 end
	self.controls.itemSetDropdownSkill = new("DropDownControl", {"LEFT",self.controls.itemSetLabelDropdownSkill,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		local itemSetTitle = self.controls.itemSetDropdown.list[self.controls.itemSetDropdown.selIndex]
		self:InitLinks("item", itemSetTitle)
		self.itemSetLinks[itemSetTitle]["skillSet"] = value
		self.modFlag = true
	end)
	self.controls.itemSetDropdownSkill.enabled = function() return self.controls.itemSetDropdown.selIndex ~= 1 end

	self.controls.reset = new("ButtonControl", {"RIGHT",self.controls.treeSetDropdownItem,"RIGHT"}, 0, -74, 75, 18, "^7Reset", function()
		self:OpenResetPopup()
		self.modFlag = true
	end)

	local currentLinksNote = {}
	currentLinksNote["tree"] = function()
		local note = "^7{ Tree  -->  Skill, Item }\n\n"
		for index, link in pairs(self.treeSetLinks) do
			if isValidLink("tree", index, link) then
				note = note .. index .. "^7  -->  " .. (link.skillSet or "") .. "^7, " .. (link.itemSet or "") .. "\n"
			end
		end
		return note
	end
	currentLinksNote["skill"] = function()
		local note = "{ Skill  -->  Tree, Item }\n\n"
		for index, link in pairs(self.skillSetLinks) do
			if isValidLink("skill", index, link) then
				note = note .. index .. "^7  -->  " .. (link.treeSet or "") .. "^7, " .. (link.itemSet or "") .. "\n"
			end
		end
		return note
	end
	currentLinksNote["item"] = function()
		local note = "{ Item  -->  Tree, Skill }\n\n"
		for index, link in pairs(self.itemSetLinks) do
			if isValidLink("item", index, link) then
				note = note .. index .. "^7  -->  " .. (link.treeSet or "None") .. "^7, " .. (link.skillSet or "None") .. "\n"
			end
		end
		return note
	end
	self.controls.displayLinks = new("LabelControl", {"LEFT",self.controls.itemSetDropdown,"LEFT"}, 0, 85, 0, 16, "Current Links:")
	self.controls.displayLinksLabel = new("LabelControl", {"LEFT",self.controls.displayLinks,"LEFT"}, 0, 35, 150, 16, function()
		return currentLinksNote[activeNote] and currentLinksNote[activeNote]() or ""
	end)
	self.controls.displayLinksTreeButton = new("ButtonControl", { "LEFT",self.controls.displayLinks, "RIGHT"}, 8, 1, 150, 18, "^7Show Tree Set Links", function()
		activeNote = "tree"
	end)
	self.controls.displayLinksSkillButton = new("ButtonControl", {"LEFT",self.controls.displayLinksTreeButton,"RIGHT"}, 8, 0, 150, 18, "^7Show Skill Set Links", function()
		activeNote = "skill"
	end)
	self.controls.displayLinksItemButton = new("ButtonControl", {"LEFT",self.controls.displayLinksSkillButton,"RIGHT"}, 8, 0, 150, 18, "^7Show Item Set Links", function()
		activeNote = "item"
	end)
end)

function LinkedSetsTabClass:OpenResetPopup()
	local controls = { }
	controls.warningLabel = new("LabelControl", nil, 0, 20, 0, 16, "^7Warning: This action cannot be undone.\n")
	controls.reset = new("ButtonControl", nil, -60, 50, 100, 20, "Reset", function()
		self:ResetLinks(true)
		main:ClosePopup()
	end)
	controls.cancel = new("ButtonControl", nil, 60, 50, 100, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(325, 90, "Reset Links", controls, "convert", "edit")
end

function LinkedSetsTabClass:InitLinks(set, value)
	if set == "tree" then
		if not (self.treeSetLinks[value]) then
			self.treeSetLinks[value] = {
				skillSet = "None",
				itemSet = "None"
			}
		end
	elseif set == "skill" then
		if not (self.skillSetLinks[value]) then
			self.skillSetLinks[value] = {
				treeSet = "None",
				itemSet = "None"
			}
		end
	elseif set == "item" then
		if not (self.itemSetLinks[value]) then
			self.itemSetLinks[value] = {
				treeSet = "None",
				skillSet = "None"
			}
		end
	end
end

function LinkedSetsTabClass:LoadDropdowns(set, value)
	if set == "tree" then
		self.controls.treeSetDropdownItem:SelByValue(self.treeSetLinks[value].itemSet or "None")
		self.controls.treeSetDropdownSkill:SelByValue(self.treeSetLinks[value].skillSet or "None")
	elseif set == "skill" then
		self.controls.skillSetDropdownTree:SelByValue(self.skillSetLinks[value].treeSet or "None")
		self.controls.skillSetDropdownItem:SelByValue(self.skillSetLinks[value].itemSet or "None")
	elseif set == "item" then
		self.controls.itemSetDropdownTree:SelByValue(self.itemSetLinks[value].treeSet or "None")
		self.controls.itemSetDropdownSkill:SelByValue(self.itemSetLinks[value].skillSet or "None")
	end
end

function LinkedSetsTabClass:ResetLinks(hardReset)
	if hardReset then
		wipeTable(self.treeSetLinks)
		wipeTable(self.skillSetLinks)
		wipeTable(self.itemSetLinks)
	end

	self.controls.treeSetDropdown.selIndex = 1
	self.controls.treeSetDropdownSkill.selIndex = 1
	self.controls.treeSetDropdownItem.selIndex = 1

	self.controls.skillSetDropdown.selIndex = 1
	self.controls.skillSetDropdownTree.selIndex = 1
	self.controls.skillSetDropdownItem.selIndex = 1

	self.controls.itemSetDropdown.selIndex = 1
	self.controls.itemSetDropdownTree.selIndex = 1
	self.controls.itemSetDropdownSkill.selIndex = 1
end

local function getSetTitles(sets)
	local setTitles = { "None" }
	local title = ""
	for _, set in pairs(sets) do
		title = set.title or "Default"
		t_insert(setTitles, title)
	end
	return setTitles
end

function LinkedSetsTabClass:UpdateSetDropdowns()
	self.treeSetTitles = getSetTitles(self.build.treeTab.specList)
	self.skillSetTitles = getSetTitles(self.build.skillsTab.skillSets)
	self.itemSetTitles = getSetTitles(self.build.itemsTab.itemSets)

	self.controls.treeSetDropdown:SetList(self.treeSetTitles)
	self.controls.treeSetDropdownSkill:SetList(self.skillSetTitles)
	self.controls.treeSetDropdownItem:SetList(self.itemSetTitles)

	self.controls.skillSetDropdown:SetList(self.skillSetTitles)
	self.controls.skillSetDropdownTree:SetList(self.treeSetTitles)
	self.controls.skillSetDropdownItem:SetList(self.itemSetTitles)

	self.controls.itemSetDropdown:SetList(self.itemSetTitles)
	self.controls.itemSetDropdownTree:SetList(self.treeSetTitles)
	self.controls.itemSetDropdownSkill:SetList(self.skillSetTitles)
end

function LinkedSetsTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	self:UpdateSetDropdowns()
	self:ProcessControlsInput(inputEvents, viewPort)
	main:DrawBackground(viewPort)
	self:DrawControls(viewPort)
end

function LinkedSetsTabClass:Save(xml)
	xml.attrib = {
		enabled = tostring(self.enabled)
	}
	for index, link in pairs(self.treeSetLinks) do
		if isValidLink("tree", index, link) then
			local child = {
				elem = "TreeSet",
				attrib = {
					title = index,
					skillSet = link["skillSet"],
					itemSet = link["itemSet"]
				}
			}
			t_insert(xml, child)
		end
	end
	for index, link in pairs(self.skillSetLinks) do
		if isValidLink("skill", index, link) then
			local child = {
				elem = "SkillSet",
				attrib = {
					title = index,
					treeSet = link["treeSet"],
					itemSet = link["itemSet"]
				}
			}
			t_insert(xml, child)
		end
	end
	for index, link in pairs(self.itemSetLinks) do
		if isValidLink("item", index, link) then
			local child = {
				elem = "ItemSet",
				attrib = {
					title = index,
					treeSet = link["treeSet"],
					skillSet = link["skillSet"]
				}
			}
			t_insert(xml, child)
		end
	end
end

function LinkedSetsTabClass:Load(xml)
	if xml.attrib then
		self.enabled = xml.attrib.enabled == "true"
		self.controls.enabled.state = self.enabled
	end
	for _, node in pairs(xml) do
		if type(node) ~= "boolean" then
			if node.elem == "TreeSet" then
				self.treeSetLinks[node.attrib.title] = {
					["skillSet"] = node.attrib.skillSet or { },
					["itemSet"] = node.attrib.itemSet or { }
				}
			elseif node.elem == "SkillSet" then
				self.skillSetLinks[node.attrib.title] = {
					["treeSet"] = node.attrib.treeSet or { },
					["itemSet"] = node.attrib.itemSet or { }
				}
			elseif node.elem == "ItemSet" then
				self.itemSetLinks[node.attrib.title] = {
					["treeSet"] = node.attrib.treeSet or { },
					["skillSet"] = node.attrib.skillSet or { }
				}
			end
		end
	end
end

function LinkedSetsTabClass:LoadSetLinks(type, value)
	if self.build.linkedSetsTab.enabled then
		if type == "item" and self.build.linkedSetsTab.itemSetLinks[value] then
			self.build.treeTab:SetActiveSpecByVal(self.build.linkedSetsTab.itemSetLinks[value].treeSet)
			self.build.skillsTab:SetActiveSkillSetByVal(self.build.linkedSetsTab.itemSetLinks[value].skillSet)
		elseif type == "skill" and self.build.linkedSetsTab.skillSetLinks[value] then
			self.build.treeTab:SetActiveSpecByVal(self.build.linkedSetsTab.skillSetLinks[value].treeSet)
			self.build.itemsTab:SetActiveItemSetByVal(self.build.linkedSetsTab.skillSetLinks[value].itemSet)
		elseif type == "tree" and self.build.linkedSetsTab.treeSetLinks[value] then
			self.build.skillsTab:SetActiveSkillSetByVal(self.build.linkedSetsTab.treeSetLinks[value].skillSet)
			self.build.itemsTab:SetActiveItemSetByVal(self.build.linkedSetsTab.treeSetLinks[value].itemSet)
		end
	end
end

-- actions: rename, delete
function LinkedSetsTabClass:ModifySet(type, action, old, new)
	local function replace(action, new)
		return action == "rename" and new or "None"
	end
	if type == "tree" then
		-- replace index
		if self.treeSetLinks[old] then
			if action == "rename" then
				self.treeSetLinks[new] = copyTable(self.treeSetLinks[old])
			end
			self.treeSetLinks[old] = nil
		end
		-- replace set in other types
		for index, _ in pairs(self.skillSetLinks) do
			if self.skillSetLinks[index].treeSet == old then
				self.skillSetLinks[index].treeSet = replace(action, new)
			end
		end
		for index, _ in pairs(self.itemSetLinks) do
			if self.itemSetLinks[index].treeSet == old then
				self.itemSetLinks[index].treeSet = replace(action, new)
			end
		end
	elseif type == "skill" then
		if self.skillSetLinks[old] then
			if action == "rename" then
				self.skillSetLinks[new] = copyTable(self.skillSetLinks[old])
			end
			self.skillSetLinks[old] = nil
		end
		for index, _ in pairs(self.treeSetLinks) do
			if self.treeSetLinks[index].skillSet == old then
				self.treeSetLinks[index].skillSet = replace(action, new)
			end
		end
		for index, _ in pairs(self.itemSetLinks) do
			if self.itemSetLinks[index].skillSet == old then
				self.itemSetLinks[index].skillSet = replace(action, new)
			end
		end
	elseif type == "item" then
		if self.itemSetLinks[old] then
			if action == "rename" then
				self.itemSetLinks[new] = copyTable(self.itemSetLinks[old])
			end
			self.itemSetLinks[old] = nil
		end
		for index, _ in pairs(self.treeSetLinks) do
			if self.treeSetLinks[index].itemSet == old then
				self.treeSetLinks[index].itemSet = replace(action, new)
			end
		end
		for index, _ in pairs(self.skillSetLinks) do
			if self.skillSetLinks[index].itemSet == old then
				self.skillSetLinks[index].itemSet = replace(action, new)
			end
		end
	end
	-- bad UX if you delete a set that is the active selIndex of one of the dropdowns, so set all to default selIndex on any delete call
	if action == "delete" then
		self:ResetLinks(false)
	end
end