-- Path of Building
--
-- Module: Set Manager Tab
-- Set Manager tab for the current build.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert

local SetManagerTabClass = newClass("SetManagerTab", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

	self.build = build

	self.treeSetLinks = {}
	self.itemSetLinks = {}
	self.skillSetLinks = {}
	self.enabled = false

	local notesDesc = [[^7
	With this tab, you can manage links between item, skill, and tree sets.
	Each set is listed on the left, with two dropdowns on the right to create a link between the sets.

	For example, given Tree Set 1 has Skill Set 2 and Item Set 2 linked, if you change to Tree Set 1 either in the Tree Tab or Items Tab,
	Skill Set 2 and Item Set 2 should automatically set active as well.
	But with no other changes, setting Skill Set 2 or Item Set 2 to active would do nothing to the other Sets.]]

	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, 16, notesDesc)
	self.controls.notesDesc.width = function()
		local width = self.width / 2 - 16
		if width ~= self.controls.notesDesc.lastWidth then
			self.controls.notesDesc.lastWidth = width
			self.controls.notesDesc.label = table.concat(main:WrapString(notesDesc, 16, width - 50), "\n")
		end
		return width
	end

	self.controls.enabled = new("CheckBoxControl", { "TOPLEFT", self, "TOPLEFT" }, 80, 145, 18, "Enabled:", function(state)
		self.enabled = state
		self.modFlag = true
	end)

	local dropdownWidth = 100
	-- Tree Set Manager
	-- Skill and Item Manager controls are anchored to these three labels
	self.controls.treeSetLabelRoot = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 35, 200, 0, 16, "Tree Sets")
	self.controls.treeSetLabelDropdownSkill = new("LabelControl", {"LEFT",self.controls.treeSetLabelRoot,"RIGHT"}, dropdownWidth*1.1, 0, 0, 16, "Skill Sets")
	self.controls.treeSetLabelDropdownItem = new("LabelControl", {"LEFT",self.controls.treeSetLabelDropdownSkill,"RIGHT"}, dropdownWidth/2, 0, 0, 16, "Item Sets")
	self.controls.treeSetDropdown = new("DropDownControl", {"LEFT",self.controls.treeSetLabelRoot,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		self:InitLinks("tree", value)
		self:LoadLinks("tree", value)
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

	-- Skill Set Manager
	self.controls.skillSetLabelRoot = new("LabelControl", {"LEFT",self.controls.treeSetLabelRoot,"LEFT"}, 0, 60, 0, 16, "Skill Sets")
	self.controls.skillSetLabelDropdownTree = new("LabelControl", {"LEFT",self.controls.treeSetLabelDropdownSkill,"LEFT"}, 0, 60, 0, 16, "Tree Sets")
	self.controls.skillSetLabelDropdownItem = new("LabelControl", {"LEFT",self.controls.treeSetLabelDropdownItem,"LEFT"}, 0, 60, 0, 16, "Item Sets")
	self.controls.skillSetDropdown = new("DropDownControl", {"LEFT",self.controls.skillSetLabelRoot,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		self:InitLinks("skill", value)
		self:LoadLinks("skill", value)
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

	-- Item Set Manager
	self.controls.itemSetLabelRoot = new("LabelControl", {"LEFT",self.controls.treeSetLabelRoot,"LEFT"}, 0, 120, 0, 16, "Item Sets")
	self.controls.itemSetLabelDropdownTree = new("LabelControl", {"LEFT",self.controls.treeSetLabelDropdownSkill,"LEFT"}, 0, 120, 0, 16, "Tree Sets")
	self.controls.itemSetLabelDropdownSkill = new("LabelControl", {"LEFT",self.controls.treeSetLabelDropdownItem,"LEFT"}, 0, 120, 0, 16, "Skill Sets")
	self.controls.itemSetDropdown = new("DropDownControl", {"LEFT",self.controls.itemSetLabelRoot,"LEFT"}, 0, 20, dropdownWidth, 18, nil, function(index, value)
		self:InitLinks("item", value)
		self:LoadLinks("item", value)
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

	self.controls.reset = new("ButtonControl", {"RIGHT",self.controls.treeSetDropdownItem,"RIGHT"}, 0, -74, 75, 18, "Reset", function()
		self:ResetLinks()
		self.modFlag = true
	end)

	-- Display current links all at once
	self.controls.displayLinks = new("LabelControl", {"LEFT",self.controls.itemSetDropdown,"LEFT"}, -15, 75, 0, 16, "Current Links:")
	self.controls.displayLinks.shown = function() return self.treeSetLinks ~= {} or self.skillSetLinks ~= {} or self.itemSetLinks ~= {} end
	self.controls.displayLinksTree = new("LabelControl", {"LEFT",self.controls.displayLinks,"LEFT"}, 0, 25, 150, 16, function()
		local note = "Tree Links                    Skill, Item\n"
		for index, link in pairs(self.treeSetLinks) do
			if index ~= "None" then
				note = note .. "   " .. index .. "  -->  " .. (link.skillSet or "") .. ", " .. (link.itemSet or "") .. "\n"
			end
		end
		return note
	end)
	self.controls.displayLinksSkill = new("LabelControl", {"LEFT",self.controls.displayLinksTree,"RIGHT"}, 85, 0, 150, 16, function()
		local note = "Skill Links                    Tree, Item\n"
		for index, link in pairs(self.skillSetLinks) do
			if index ~= "None" then
				note = note .. "   " .. index .. "  -->  " .. (link.treeSet or "") .. ", " .. (link.itemSet or "") .. "\n"
			end
		end
		return note
	end)
	self.controls.displayLinksItem = new("LabelControl", {"LEFT",self.controls.displayLinksSkill,"RIGHT"}, 85, 0, 150, 16, function()
		local note = "Item Links                    Tree, Skill\n"
		for index, link in pairs(self.itemSetLinks) do
			if index ~= "None" then
				note = note .. "   " .. index .. "  -->  " .. (link.treeSet or "None") .. ", " .. (link.skillSet or "None") .. "\n"
			end
		end
		return note
	end)
end)

function SetManagerTabClass:InitLinks(set, value)
	if set == "tree" then
		if not (self.treeSetLinks[value]) then
			self.treeSetLinks[value] = { }
		end
	elseif set == "skill" then
		if not (self.skillSetLinks[value]) then
			self.skillSetLinks[value] = { }
		end
	elseif set == "item" then
		if not (self.itemSetLinks[value]) then
			self.itemSetLinks[value] = { }
		end
	end
end

function SetManagerTabClass:LoadLinks(set, value)
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

function SetManagerTabClass:ResetLinks()
	wipeTable(self.treeSetLinks)
	wipeTable(self.skillSetLinks)
	wipeTable(self.itemSetLinks)

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

function SetManagerTabClass:GetSetTitles(sets)
	local setTitles = { "None" }
	local title = ""
	for _, set in pairs(sets) do
		title = set.title or "Default"
		t_insert(setTitles, title)
	end
	return setTitles
end

function SetManagerTabClass:UpdateSetDropdowns()
	self.treeSetTitles = self:GetSetTitles(self.build.treeTab.specList)
	self.skillSetTitles = self:GetSetTitles(self.build.skillsTab.skillSets)
	self.itemSetTitles = self:GetSetTitles(self.build.itemsTab.itemSets)

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

function SetManagerTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	self:UpdateSetDropdowns()

	-- TODO: undo, redo
	--for id, event in ipairs(inputEvents) do
	--	if event.type == "KeyDown" then
	--		if event.key == "z" and IsKeyDown("CTRL") then
	--		elseif event.key == "y" and IsKeyDown("CTRL") then
	--		end
	--	end
	--end

	self:ProcessControlsInput(inputEvents, viewPort)
	main:DrawBackground(viewPort)
	self:DrawControls(viewPort)
end

function SetManagerTabClass:Save(xml)
	xml.attrib = {
		enabled = tostring(self.enabled)
	}
	for index, treeSet in pairs(self.treeSetLinks) do
		if index ~= "None" then
			local child = {
				elem = "TreeSet",
				attrib = {
					title = index,
					skillSet = treeSet["skillSet"] or "None",
					itemSet = treeSet["itemSet"] or "None"
				}
			}
			t_insert(xml, child)
		end
	end

	for index, skillSet in pairs(self.skillSetLinks) do
		if index ~= "None" then
			local child = {
				elem = "SkillSet",
				attrib = {
					title = index,
					treeSet = skillSet["treeSet"] or "None",
					itemSet = skillSet["itemSet"] or "None"
				}
			}
			t_insert(xml, child)
		end
	end

	for index, itemSet in pairs(self.itemSetLinks) do
		if index ~= "None" then
			local child = {
				elem = "ItemSet",
				attrib = {
					title = index,
					treeSet = itemSet["treeSet"] or "None",
					skillSet = itemSet["skillSet"] or "None"
				}
			}
			t_insert(xml, child)
		end
	end
end

function SetManagerTabClass:Load(xml)
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