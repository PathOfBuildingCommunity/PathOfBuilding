-- Path of Building
--
-- Module: Items Tab
-- Items tab for the current build.
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local s_format = string.format
local m_max = math.max
local m_min = math.min
local m_floor = math.floor

local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Flask 1", "Flask 2", "Flask 3", "Flask 4", "Flask 5" }

local ItemsTabClass = common.NewClass("ItemsTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build

	self.socketViewer = common.New("PassiveTreeView")

	self.list = { }
	self.orderList = { }

	-- Build lists of item bases, separated by type
	self.baseLists = { }
	for name, base in pairs(data.itemBases) do
		local type = base.type
		if base.subType then
			type = type .. ": " .. base.subType
		end
		self.baseLists[type] = self.baseLists[type] or { }
		t_insert(self.baseLists[type], { label = name:gsub(" %(.+%)",""), name = name, base = base })
	end
	self.baseTypeList = { }
	for type, list in pairs(self.baseLists) do
		t_insert(self.baseTypeList, type)
		table.sort(list, function(a, b) 
			if a.base.req and b.base.req then
				if a.base.req.level == b.base.req.level then
					return a.name < b.name
				else
					return (a.base.req.level or 1) > (b.base.req.level or 1)
				end
			elseif a.base.req and not b.base.req then
				return true
			elseif b.base.req and not a.base.req then
				return false
			else
				return a.name < b.name
			end
		end)
	end
	table.sort(self.baseTypeList)

	-- Item slots
	self.slots = { }
	self.orderedSlots = { }
	self.slotOrder = { }
	for index, slotName in ipairs(baseSlots) do
		t_insert(self.controls, common.New("ItemSlot", {"TOPLEFT",self,"TOPLEFT"}, 96, (index - 1) * 20 + 24, self, slotName))
		self.slotOrder[slotName] = index
	end
	self.sockets = { }
	for _, node in pairs(main.tree.nodes) do
		if node.type == "socket" then
			local socketControl = common.New("ItemSlot", {"TOPLEFT",self,"TOPLEFT"}, 96, 0, self, "Jewel "..node.id, "Socket", node.id)
			self.controls["socket"..node.id] = socketControl
			self.sockets[node.id] = socketControl
			self.slotOrder["Jewel "..node.id] = #baseSlots + 1 + node.id
		end
	end
	table.sort(self.orderedSlots, function(a, b)
		return self.slotOrder[a.slotName] < self.slotOrder[b.slotName]
	end)
	self.controls.slotHeader = common.New("LabelControl", {"BOTTOMLEFT",self.orderedSlots[1],"TOPLEFT"}, 0, -4, 0, 16, "^7Equipped items:")
	self:PopulateSlots()

	-- Build item list
	self.controls.itemList = common.New("ItemList", {"TOPLEFT",self.orderedSlots[1],"TOPRIGHT"}, 20, 0, 360, 308, self)

	-- Database selector
	self.controls.selectDBLabel = common.New("LabelControl", {"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, 0, 14, 0, 16, "^7Import from:")
	self.controls.selectDBLabel.shown = function()
		return self.height < 984
	end
	self.controls.selectDB = common.New("DropDownControl", {"LEFT",self.controls.selectDBLabel,"RIGHT"}, 4, 0, 150, 18, { "Uniques", "Rare Templates" })

	-- Unique database
	self.controls.uniqueDB = common.New("ItemDB", {"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, 0, 76, 360, 260, self, main.uniqueDB)
	self.controls.uniqueDB.y = function()
		return self.controls.selectDBLabel:IsShown() and 76 or 54
	end
	self.controls.uniqueDB.shown = function()
		return not self.controls.selectDBLabel:IsShown() or self.controls.selectDB.sel == 1
	end

	-- Rare template database
	self.controls.rareDB = common.New("ItemDB", {"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, 0, 76, 360, 260, self, main.rareDB)
	self.controls.rareDB.y = function()
		return self.controls.selectDBLabel:IsShown() and 76 or 370
	end
	self.controls.rareDB.shown = function()
		return not self.controls.selectDBLabel:IsShown() or self.controls.selectDB.sel == 2
	end

	-- Display item
	self.controls.craftDisplayItem = common.New("ButtonControl", {"TOPLEFT",self.controls.itemList,"TOPRIGHT"}, 20, 0, 120, 20, "Craft item...", function()
		self:CraftItem()
	end)
	self.controls.craftDisplayItem.shown = function()
		return self.displayItem == nil
	end
	self.controls.newDisplayItem = common.New("ButtonControl", {"TOPLEFT",self.controls.craftDisplayItem,"TOPRIGHT"}, 8, 0, 120, 20, "Create custom...", function()
		self:EditDisplayItemText()
	end)
	self.controls.displayItemTip = common.New("LabelControl", {"TOPLEFT",self.controls.craftDisplayItem,"BOTTOMLEFT"}, 0, 8, 100, 16, 
[[^7Double-click an item from one of the lists,
or copy and paste an item from in game (hover over the item and Ctrl+C)
to view/edit the item and add it to your build.
You can Control + Click an item to equip it, or drag it onto the slot.
This will also add it to your build if it's from the unique/template list.
If there's 2 slots an item can go in, holding Shift will put it in the second.]])
	self.anchorDisplayItem = common.New("Control", {"TOPLEFT",self.controls.itemList,"TOPRIGHT"}, 20, 0, 0, 0)
	self.anchorDisplayItem.shown = function()
		return self.displayItem ~= nil
	end
	self.controls.addDisplayItem = common.New("ButtonControl", {"TOPLEFT",self.anchorDisplayItem,"TOPLEFT"}, 0, 0, 100, 20, "", function()
		self:AddDisplayItem()
	end)
	self.controls.addDisplayItem.label = function()
		return self.list[self.displayItem.id] and "Save" or "Add to build"
	end
	self.controls.editDisplayItem = common.New("ButtonControl", {"LEFT",self.controls.addDisplayItem,"RIGHT"}, 8, 0, 60, 20, "Edit...", function()
		self:EditDisplayItemText()
	end)
	self.controls.removeDisplayItem = common.New("ButtonControl", {"LEFT",self.controls.editDisplayItem,"RIGHT"}, 8, 0, 60, 20, "Cancel", function()
		self:SetDisplayItem()
	end)
	self.controls.displayItemVariant = common.New("DropDownControl", {"LEFT",self.controls.removeDisplayItem,"RIGHT"}, 8, 0, 200, 20, nil, function(sel)
		self.displayItem.variant = sel
		itemLib.buildItemModList(self.displayItem)
		self:UpdateDisplayItemRangeLines()
	end)
	self.controls.displayItemVariant.shown = function()
		return self.displayItem.variantList and #self.displayItem.variantList > 1
	end
	self.controls.displayItemEnchant = common.New("ButtonControl", {"TOPLEFT",self.controls.addDisplayItem,"BOTTOMLEFT"}, 0, 8, 160, 20, "Apply Enchantment...", function()
		self:EnchantDisplayItem()
	end)
	self.controls.displayItemEnchant.shown = function()
		return self.displayItem.enchantments
	end
	for i = 1, 6 do
		local prev = self.controls["displayItemAffix"..(i-1)] or self.controls.addDisplayItem
		local drop
		drop = common.New("DropDownControl", {"TOPLEFT",prev,"BOTTOMLEFT"}, i==1 and 40 or 0, i == 1 and function() return self.displayItem.enchantments and 28 or 8 end or 2, 418, 20, nil, function(sel, value)
			self.displayItem[drop.outputTable][drop.outputIndex] = value.value
			itemLib.craftItem(self.displayItem)
			self:UpdateDisplayItemRangeLines()
		end)
		drop.tooltipFunc = function(mode, sel, value)
			if mode ~= "OUT" and self.displayItem.affixes[value.value] and (not self.selControl or self.selControl == drop) then
				for _, line in ipairs(self.displayItem.affixes[value.value]) do
					main:AddTooltipLine(16, "^7"..line)
				end
			end
		end
		drop.shown = function()
			return self.displayItem.craftable and i <= self.displayItem.affixLimit
		end
		self.controls["displayItemAffix"..i] = drop
		self.controls["displayItemAffixLabel"..i] = common.New("LabelControl", {"RIGHT",drop,"LEFT"}, -4, 0, 0, 14, function()
			return drop.outputTable == "prefixes" and "^7Prefix:" or "^7Suffix:"
		end)
	end
	self.controls.displayItemRangeLine = common.New("DropDownControl", {"TOPLEFT",self.controls.addDisplayItem,"BOTTOMLEFT"}, 0, 0, 350, 18, nil, function(sel)
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[sel].range
	end)
	self.controls.displayItemRangeLine.y = function()
		return 8 + (self.displayItem and self.displayItem.enchantments and 28 or 0) + (self.displayItem and self.displayItem.craftable and (self.displayItem.affixLimit * 22 + 6) or 0)
	end
	self.controls.displayItemRangeLine.shown = function()
		return self.displayItem.rangeLineList[1] ~= nil
	end
	self.controls.displayItemRangeSlider = common.New("SliderControl", {"LEFT",self.controls.displayItemRangeLine,"RIGHT"}, 8, 0, 100, 18, function(val)
		self.displayItem.rangeLineList[self.controls.displayItemRangeLine.sel].range = val
		itemLib.buildItemModList(self.displayItem)
	end)

	-- Scroll bar
	self.controls.scrollBarH = common.New("ScrollBarControl", nil, 0, 0, 0, 18, 80, "HORIZONTAL", true)
end)

function ItemsTabClass:Load(xml, dbFileName)
	for _, node in ipairs(xml) do
		if node.elem == "Item" then
			local item = { }
			item.raw = ""
			item.id = tonumber(node.attrib.id)
			item.variant = tonumber(node.attrib.variant)
			itemLib.parseItemRaw(item)
			for _, child in ipairs(node) do
				if type(child) == "string" then
					item.raw = child
					itemLib.parseItemRaw(item)
				elseif child.elem == "ModRange" then
					local id = tonumber(child.attrib.id) or 0
					local range = tonumber(child.attrib.range) or 1
					if item.modLines[id] then
						item.modLines[id].range = range
					end
				end
			end
			itemLib.buildItemModList(item)
			self.list[item.id] = item
			t_insert(self.orderList, item.id)
		elseif node.elem == "Slot" then
			local slot = self.slots[node.attrib.name or ""]
			if slot then
				slot.selItemId = tonumber(node.attrib.itemId)
				if slot.controls.activate then
					slot.active = node.attrib.active == "true"
					slot.controls.activate.state = slot.active
				end
			end
		end
	end
	self:ResetUndo()
	self:PopulateSlots()
end

function ItemsTabClass:Save(xml)
	for _, id in ipairs(self.orderList) do
		local item = self.list[id]
		local child = { elem = "Item", attrib = { id = tostring(id), variant = item.variant and tostring(item.variant) } }
		t_insert(child, item.raw)
		for id, modLine in ipairs(item.modLines) do
			if modLine.range then
				t_insert(child, { elem = "ModRange", attrib = { id = tostring(id), range = tostring(modLine.range) } })
			end
		end
		t_insert(xml, child)
	end
	for name, slot in pairs(self.slots) do
		if slot.selItemId ~= 0 and not slot.nodeId then
			t_insert(xml, { elem = "Slot", attrib = { name = name, itemId = tostring(slot.selItemId), active = slot.active and "true" }})
		end
	end
	self.modFlag = false
end

function ItemsTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height
	self.controls.scrollBarH.width = viewPort.width
	self.controls.scrollBarH.x = viewPort.x
	self.controls.scrollBarH.y = viewPort.y + viewPort.height - 18
	self.controls.scrollBarH:SetContentDimension(self.controls.displayItemRangeSlider:GetPos() + self.controls.displayItemRangeSlider:GetSize() - self.x, viewPort.width)
	self.x = self.x - self.controls.scrollBarH.offset
	
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "v" and IsKeyDown("CTRL") then
				local newItem = Paste()
				if newItem then
					self:CreateDisplayItemFromRaw(newItem, true)
				end
			elseif event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
				self.build.buildFlag = true
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
				self.build.buildFlag = true
			elseif launch.devMode and event.key == "DELETE" and IsKeyDown("CTRL") then
				while self.orderList[1] do
					self:DeleteItem(self.list[self.orderList[1]])
				end
				self.build.buildFlag = true
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	if self.displayItem then
		local extraOffset = self.controls.displayItemRangeLine:IsShown() and 26 or 0
		if self.displayItem.enchantments then
			extraOffset = extraOffset + 28
		end
		if self.displayItem.craftable then
			extraOffset = extraOffset + self.displayItem.affixLimit * 22 + 6
		end
		self:AddItemTooltip(self.displayItem)
		local baseX, baseY = self.anchorDisplayItem:GetPos()
		main:DrawTooltip(baseX, baseY + 28 + extraOffset, nil, nil, viewPort, data.colorCodes[self.displayItem.rarity])
	end

	self:UpdateSockets()

	self:DrawControls(viewPort)
end

-- Update the item lists for all the slot controls
function ItemsTabClass:PopulateSlots()
	for _, slot in pairs(self.slots) do
		slot:Populate()
	end
end

-- Updates the status and position of the socket controls
function ItemsTabClass:UpdateSockets()
	-- Build a list of active sockets
	local activeSocketList = { }
	for nodeId, slot in pairs(self.sockets) do
		if self.build.spec.allocNodes[nodeId] then
			t_insert(activeSocketList, nodeId)
			slot.inactive = false
		else
			slot.inactive = true
		end
	end
	table.sort(activeSocketList)

	-- Update the position of the active socket controls
	for index, nodeId in pairs(activeSocketList) do
		self.sockets[nodeId].label = "Socket #"..index
		self.sockets[nodeId].y = (#baseSlots + index - 1) * 20 + 24
	end
end

-- Returns the slot control and equipped jewel for the given node ID
function ItemsTabClass:GetSocketAndJewelForNodeID(nodeId)
	return self.sockets[nodeId], self.list[self.sockets[nodeId].selItemId]
end

-- Opens the item crafting popup
function ItemsTabClass:CraftItem()
	local controls = { }
	local function makeItem(base)
		local item = { name = base.name, base = base.base, baseName = base.name, modLines = { }, quality = 0 }
		local raritySel = controls.rarity.sel
		if base.base.flask then
			if raritySel == 3 then
				raritySel = 2
			end
		end
		if data.itemMods[base.base.type] and (raritySel == 2 or raritySel == 3) then
			item.crafted = true
		end
		item.rarity = controls.rarity.list[raritySel].val
		if raritySel >= 3 then
			item.title = controls.title.buf:match("%S") and controls.title.buf or "New Item"
		end
		item.implicitLines = 0
		if base.base.implicit then
			for line in base.base.implicit:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.modLines, { line = line, extra = extra, modList = modList or { } })
				item.implicitLines = item.implicitLines + 1
			end
		end
		itemLib.normaliseQuality(item)
		return itemLib.makeItemFromRaw(itemLib.createItemRaw(item))
	end
	controls.rarityLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 50, 20, 0, 16, "Rarity:")
	controls.rarity = common.New("DropDownControl", nil, -80, 20, 100, 18, { 
		{val = "NORMAL",label=data.colorCodes.NORMAL.."Normal"},
		{val="MAGIC",label=data.colorCodes.MAGIC.."Magic"},
		{val="RARE",label=data.colorCodes.RARE.."Rare"},
		{val="UNIQUE",label=data.colorCodes.UNIQUE.."Unique"}
	})
	controls.rarity.sel = self.lastCraftRaritySel or 3
	controls.title = common.New("EditControl", nil, 70, 20, 190, 18, "", "Name")
	controls.title.shown = function()
		return controls.rarity.sel >= 3
	end
	controls.typeLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 50, 45, 0, 16, "Type:")
	controls.type = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 55, 45, 295, 18, self.baseTypeList, function(sel, value)
		controls.base.list = self.baseLists[self.baseTypeList[sel]]
		controls.base.sel = 1
	end)
	controls.type.sel = self.lastCraftTypeSel or 1
	controls.baseLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 50, 70, 0, 16, "Base:")
	controls.base = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 55, 70, 200, 18, self.baseLists[self.baseTypeList[controls.type.sel]])
	controls.base.sel = self.lastCraftBaseSel or 1
	controls.base.tooltipFunc = function(mode, sel, selVal)
		if mode ~= "OUT" then
			local item = makeItem(selVal)
			self:AddItemTooltip(item, nil, true)
			return data.colorCodes[item.rarity], true
		end
	end
	controls.save = common.New("ButtonControl", nil, -45, 100, 80, 20, "Create", function()
		main:ClosePopup()
		local item = makeItem(controls.base.list[controls.base.sel])
		self:SetDisplayItem(item)
		if not item.craftable and item.rarity ~= "NORMAL" then
			self:EditDisplayItemText()
		end
		self.lastCraftRaritySel = controls.rarity.sel
		self.lastCraftTypeSel = controls.type.sel
		self.lastCraftBaseSel = controls.base.sel
	end)
	controls.cancel = common.New("ButtonControl", nil, 45, 100, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 130, "Craft Item", controls)
end

-- Opens the item text editor popup
function ItemsTabClass:EditDisplayItemText()
	local controls = { }
	local function buildRaw()
		local editBuf = controls.edit.buf
		if editBuf:match("^Rarity: ") then
			return editBuf
		else
			return "Rarity: "..controls.rarity.list[controls.rarity.sel].val.."\n"..controls.edit.buf
		end
	end
	controls.rarity = common.New("DropDownControl", nil, -190, 10, 100, 18, { 
		{val="NORMAL",label=data.colorCodes.NORMAL.."Normal"},
		{val="MAGIC",label=data.colorCodes.MAGIC.."Magic"},
		{val="RARE",label=data.colorCodes.RARE.."Rare"},
		{val="UNIQUE",label=data.colorCodes.UNIQUE.."Unique"},
		{val="RELIC",label=data.colorCodes.RELIC.."Relic"}
	})
	controls.edit = common.New("EditControl", nil, 0, 40, 480, 420, "", nil, "^%C\t\n", nil, nil, 14)
	if self.displayItem then
		controls.edit:SetText(itemLib.createItemRaw(self.displayItem):gsub("Rarity: %w+\n",""))
		controls.rarity:SelByValue(self.displayItem.rarity)
	else
		controls.rarity.sel = 3
	end
	controls.edit.font = "FIXED"
	controls.save = common.New("ButtonControl", nil, -45, 470, 80, 20, self.displayItem and "Save" or "Create", function()
		local id = self.displayItem and self.displayItem.id
		self:CreateDisplayItemFromRaw(buildRaw(), not self.displayItem)
		self.displayItem.id = id
		main:ClosePopup()
	end)
	controls.save.enabled = function()
		local item = itemLib.makeItemFromRaw(buildRaw())
		return item ~= nil
	end
	controls.save.tooltipFunc = function()
		local item = itemLib.makeItemFromRaw(buildRaw())
		if item then
			self:AddItemTooltip(item, nil, true)
			return data.colorCodes[item.rarity], true
		else
			main:AddTooltipLine(14, "The item is invalid.")
			main:AddTooltipLine(14, "Check that the item's title and base name are in the correct format.")
			main:AddTooltipLine(14, "For Rare and Unique items, the first 2 lines must be the title and base name. E.g:")
			main:AddTooltipLine(14, "Abberath's Horn")
			main:AddTooltipLine(14, "Goat's Horn")
			main:AddTooltipLine(14, "For Normal and Magic items, the base name must be somewhere in the first line. E.g:")
			main:AddTooltipLine(14, "Scholar's Platinum Kris of Joy")
		end
	end	
	controls.cancel = common.New("ButtonControl", nil, 45, 470, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(500, 500, self.displayItem and "Edit Item Text" or "Create Custom Item from Text", controls, nil, "edit")
end

-- Opens the item enchanting popup
function ItemsTabClass:EnchantDisplayItem()
	local controls = { } 
	local enchantments = self.displayItem.enchantments
	local haveSkills = not self.displayItem.enchantments[data.labyrinths[1].name]
	local skillList = { }
	local skillsUsed = { }
	if haveSkills then
		for _, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			for _, gem in ipairs(socketGroup.gemList) do
				if gem.data and not gem.data.support then
					skillsUsed[gem.name] = true
					break
				end
			end
		end
	end
	local function buildSkillList(onlyUsedSkills)
		wipeTable(skillList)
		for skillName in pairs(enchantments) do
			if not onlyUsedSkills or not next(skillsUsed) or skillsUsed[skillName] then
				t_insert(skillList, skillName)
			end
		end
		table.sort(skillList)
	end
	local labyrinthList = { }
	local function buildLabyrinthList()
		wipeTable(labyrinthList)
		local list = haveSkills and enchantments[skillList[controls.skill and controls.skill.sel or 1]] or enchantments
		for _, lab in ipairs(data.labyrinths) do
			if list[lab.name] then
				t_insert(labyrinthList, lab)
			end
		end
	end
	local enchantmentList = { }
	local function buildEnchantmentList()
		wipeTable(enchantmentList)
		local list = haveSkills and enchantments[skillList[controls.skill and controls.skill.sel or 1]] or enchantments
		for _, enchantment in ipairs(list[labyrinthList[controls.labyrinth and controls.labyrinth.sel or 1].name]) do
			t_insert(enchantmentList, enchantment)
		end
	end
	if haveSkills then
		buildSkillList(true)
	end
	buildLabyrinthList()
	buildEnchantmentList()
	local function enchantItem()
		local item = itemLib.makeItemFromRaw(itemLib.createItemRaw(self.displayItem))
		item.id = self.displayItem.id
		for i = 1, item.implicitLines do 
			t_remove(item.modLines, 1)
		end
		local list = haveSkills and enchantments[controls.skill.list[controls.skill.sel]] or enchantments
		t_insert(item.modLines, 1, { crafted = true, line = list[controls.labyrinth.list[controls.labyrinth.sel].name][controls.enchantment.sel] })
		item.implicitLines = 1
		item.raw = itemLib.createItemRaw(item)
		itemLib.parseItemRaw(item)
		return item
	end
	if haveSkills then
		controls.skillLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 20, 0, 16, "Skill:")
		controls.skill = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 20, 180, 18, skillList, function(sel, value)
			buildLabyrinthList()
			buildEnchantmentList()
			controls.enchantment:SetSel(1)
		end)
		controls.allSkills = common.New("CheckBoxControl", {"TOPLEFT",nil,"TOPLEFT"}, 350, 20, 18, "All skills:", function(state)
			buildSkillList(not state)
			controls.skill:SetSel(1)
			buildEnchantmentList()
			controls.enchantment:SetSel(1)
		end)
		controls.allSkills.tooltip = "Show all skills, not just those used by this build."
		if not next(skillsUsed) then
			controls.allSkills.state = true
			controls.allSkills.enabled = false
		end
	end
	controls.labyrinthLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 45, 0, 16, "Labyrinth:")
	controls.labyrinth = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 45, 100, 18, labyrinthList, function(sel, value)
		buildEnchantmentList()
	end)
	controls.enchantmentLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 70, 0, 16, "Enchantment:")
	controls.enchantment = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 70, 440, 18, enchantmentList)
	controls.save = common.New("ButtonControl", nil, -45, 100, 80, 20, "Enchant", function()
		self:SetDisplayItem(enchantItem())
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function()
		local item = enchantItem()
		self:AddItemTooltip(item, nil, true)
		return data.colorCodes[item.rarity], true
	end	
	controls.close = common.New("ButtonControl", nil, 45, 100, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(550, 130, "Enchant Item", controls)
end

-- Attempt to create a new item from the given item raw text and sets it as the new display item
function ItemsTabClass:CreateDisplayItemFromRaw(itemRaw, normalise)
	local newItem = itemLib.makeItemFromRaw(itemRaw)
	if newItem then
		if normalise then
			itemLib.normaliseQuality(newItem)
		end
		self:SetDisplayItem(newItem)
	end
end

-- Sets the display item to the given item
function ItemsTabClass:SetDisplayItem(item)
	self.displayItem = item
	if item then
		-- Update the display item controls
		self.controls.displayItemVariant.list = item.variantList
		self.controls.displayItemVariant.sel = item.variant
		self:UpdateDisplayItemRangeLines()
		self.controls.scrollBarH:SetOffset(self.controls.scrollBarH.offsetMax)
		item.craftable = item.crafted and item.affixes and item.affixLimit > 0
		if item.craftable then
			local prefixList = { }
			local suffixList = { }
			for name, data in pairs(item.affixes) do
				if not data.exclude or (not data.exclude[item.base.subType] and not data.exclude[item.baseName]) then
					if data.type == "Prefix" then
						t_insert(prefixList, name)
					elseif data.type == "Suffix" then
						t_insert(suffixList, name)
					end
				end
			end
			table.sort(prefixList)
			t_insert(prefixList, 1, "None")
			table.sort(suffixList)
			t_insert(suffixList, 1, "None")
			local prefixTable = { }
			local suffixTable = { }
			for list, out in pairs({[prefixList] = prefixTable, [suffixList] = suffixTable}) do
				for i, name in pairs(list) do
					out[i] = {
						label = name,
						value = name,
					}
					if item.affixes[name] then
						out[i].label = out[i].label .. "   ^8[" .. table.concat(item.affixes[name], "/") .. "]"
					end
				end
			end
			for i = 1, item.affixLimit/2 do
				local pre = self.controls["displayItemAffix"..i]
				pre.list = prefixTable
				pre.outputTable = "prefixes"
				pre.outputIndex = i
				pre.sel = isValueInArray(prefixList, item.prefixes[i] or "None") or 1
				local suf = self.controls["displayItemAffix"..(i+item.affixLimit/2)]
				suf.list = suffixTable
				suf.outputTable = "suffixes"
				suf.outputIndex = i
				suf.sel = isValueInArray(suffixList, item.suffixes[i] or "None") or 1
			end
		end
	else
		self.controls.scrollBarH:SetOffset(0)
	end
end

-- Updates the range line dropdown and range slider for the current display item
function ItemsTabClass:UpdateDisplayItemRangeLines()
	if self.displayItem and self.displayItem.rangeLineList[1] then
		wipeTable(self.controls.displayItemRangeLine.list)
		for _, modLine in ipairs(self.displayItem.rangeLineList) do
			t_insert(self.controls.displayItemRangeLine.list, modLine.line)
		end
		self.controls.displayItemRangeLine.sel = 1
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[1].range
	end
end

-- Adds the given item to the build's item list
function ItemsTabClass:AddItem(item, noAutoEquip)
	if not item.id then
		-- Find an unused item ID
		item.id = 1
		while self.list[item.id] do
			item.id = item.id + 1
		end

		-- Add it to the end of the display order list
		t_insert(self.orderList, item.id)

		if not noAutoEquip then
			-- Autoequip it
			for _, slotName in ipairs(baseSlots) do
				if self.slots[slotName].selItemId == 0 and self:IsItemValidForSlot(item, slotName) then
					self.slots[slotName]:SetSelItemId(item.id)
					break
				end
			end
		end
	end
	
	-- Add it to the list
	self.list[item.id] = item
	itemLib.buildItemModList(item)
end

-- Adds the current display item to the build's item list
function ItemsTabClass:AddDisplayItem(noAutoEquip)
	-- Add it to the list and clear the current display item
	self:AddItem(self.displayItem, noAutoEquip)
	self:SetDisplayItem()

	self:PopulateSlots()
	self:AddUndoState()
	self.build.buildFlag = true
end

function ItemsTabClass:DeleteItem(item)
	for _, slot in pairs(self.slots) do
		if slot.selItemId == item.id then
			slot:SetSelItemId(0)
			self.build.buildFlag = true
		end
	end
	for index, id in pairs(self.orderList) do
		if id == item.id then
			t_remove(self.orderList, index)
			break
		end
	end
	for _, spec in pairs(self.build.treeTab.specList) do
		for nodeId, itemId in pairs(spec.jewels) do
			if itemId == item.id then
				spec.jewels[nodeId] = 0
			end
		end
	end
	self.list[item.id] = nil
	self:PopulateSlots()
	self:AddUndoState()
end

-- Returns the first slot in which the given item is equipped
function ItemsTabClass:GetEquippedSlotForItem(item)
	for _, slot in ipairs(self.orderedSlots) do
		if not slot.inactive and slot.selItemId == item.id then
			return slot
		end
	end
end

-- Check if the given item could be equipped in the given slot, taking into account possible conflicts with currently equipped items
-- For example, a shield is not valid for Weapon 2 if Weapon 1 is a staff, and a wand is not valid for Weapon 2 if Weapon 1 is a dagger
function ItemsTabClass:IsItemValidForSlot(item, slotName)
	if item.type == slotName:gsub(" %d+","") then
		return true
	elseif slotName == "Weapon 1" or slotName == "Weapon" then
		return item.base.weapon ~= nil
	elseif slotName == "Weapon 2" then
		local weapon1Sel = self.slots["Weapon 1"].selItemId or 0
		local weapon1Type = weapon1Sel > 0 and self.list[weapon1Sel].base.type or "None"
		if weapon1Type == "None" then
			return item.type == "Quiver" or item.type == "Shield" or (data.weaponTypeInfo[item.type] and data.weaponTypeInfo[item.type].oneHand)
		elseif weapon1Type == "Bow" then
			return item.type == "Quiver"
		elseif data.weaponTypeInfo[weapon1Type].oneHand then
			return item.type == "Shield" or (data.weaponTypeInfo[item.type] and data.weaponTypeInfo[item.type].oneHand and ((weapon1Type == "Wand" and item.type == "Wand") or (weapon1Type ~= "Wand" and item.type ~= "Wand")))
		end
	end
end

function ItemsTabClass:AddItemTooltip(item, slot, dbMode)
	-- Item name
	local rarityCode = data.colorCodes[item.rarity]
	if item.title then
		main:AddTooltipLine(20, rarityCode..item.title)
		main:AddTooltipLine(20, rarityCode..item.baseName:gsub(" %(.+%)",""))
	else
		main:AddTooltipLine(20, rarityCode..item.namePrefix..item.baseName:gsub(" %(.+%)","")..item.nameSuffix)
	end
	main:AddTooltipSeparator(10)

	-- Special fields for database items
	if dbMode then
		if item.variantList then
			if #item.variantList == 1 then
				main:AddTooltipLine(16, "^xFFFF30Variant: "..item.variantList[1])
			else
				main:AddTooltipLine(16, "^xFFFF30Variant: "..item.variantList[item.variant].." ("..#item.variantList.." variants)")
			end
		end
		if item.league then
			main:AddTooltipLine(16, "^xFF5555Exclusive to: "..item.league)
		end
		if item.unreleased then
			main:AddTooltipLine(16, "^1Not yet available")
		end
		main:AddTooltipSeparator(10)
	end

	local base = item.base
	local slotNum = slot and slot.slotNum or (IsKeyDown("SHIFT") and 2 or 1)
	local modList = item.modList or item.slotModList[slotNum]
	if base.weapon then
		-- Weapon-specific info
		local weaponData = item.weaponData[slotNum]
		main:AddTooltipLine(16, s_format("^x7F7F7F%s", base.type))
		if item.quality > 0 then
			main:AddTooltipLine(16, s_format("^x7F7F7FQuality: "..data.colorCodes.MAGIC.."+%d%%", item.quality))
		end
		local totalDamageTypes = 0
		if weaponData.PhysicalDPS then
			main:AddTooltipLine(16, s_format("^x7F7F7FPhysical Damage: "..data.colorCodes.MAGIC.."%d-%d (%.1f DPS)", weaponData.PhysicalMin, weaponData.PhysicalMax, weaponData.PhysicalDPS))
			totalDamageTypes = totalDamageTypes + 1
		end
		if weaponData.ElementalDPS then
			local elemLine
			for _, var in ipairs({"Fire","Cold","Lightning"}) do
				if weaponData[var.."DPS"] then
					elemLine = elemLine and elemLine.."^x7F7F7F, " or "^x7F7F7FElemental Damage: "
					elemLine = elemLine..s_format("%s%d-%d", data.colorCodes[var:upper()], weaponData[var.."Min"], weaponData[var.."Max"])
				end
			end
			main:AddTooltipLine(16, elemLine)
			main:AddTooltipLine(16, s_format("^x7F7F7FElemental DPS: "..data.colorCodes.MAGIC.."%.1f", weaponData.ElementalDPS))
			totalDamageTypes = totalDamageTypes + 1	
		end
		if weaponData.ChaosDPS then
			main:AddTooltipLine(16, s_format("^x7F7F7FChaos Damage: "..data.colorCodes.CHAOS.."%d-%d "..data.colorCodes.MAGIC.."(%.1f DPS)", weaponData.ChaosMin, weaponData.ChaosMax, weaponData.ChaosDPS))
			totalDamageTypes = totalDamageTypes + 1
		end
		if totalDamageTypes > 1 then
			main:AddTooltipLine(16, s_format("^x7F7F7FTotal DPS: "..data.colorCodes.MAGIC.."%.1f", weaponData.TotalDPS))
		end
		main:AddTooltipLine(16, s_format("^x7F7F7FCritical Strike Chance: %s%.2f%%", weaponData.critChance ~= base.weapon.critChanceBase and data.colorCodes.MAGIC or "^7", weaponData.critChance))
		main:AddTooltipLine(16, s_format("^x7F7F7FAttacks per Second: %s%.2f", weaponData.attackRate ~= base.weapon.attackRateBase and data.colorCodes.MAGIC or "^7", weaponData.attackRate))
	elseif base.armour then
		-- Armour-specific info
		local armourData = item.armourData
		if item.quality > 0 then
			main:AddTooltipLine(16, s_format("^x7F7F7FQuality: "..data.colorCodes.MAGIC.."+%d%%", item.quality))
		end
		if base.armour.blockChance and armourData.BlockChance > 0 then
			main:AddTooltipLine(16, s_format("^x7F7F7FChance to Block: %s%d%%", armourData.BlockChance ~= base.armour.blockChance and data.colorCodes.MAGIC or "^7", armourData.BlockChance))
		end
		for _, def in ipairs({{var="Armour",label="Armour"},{var="Evasion",label="Evasion Rating"},{var="EnergyShield",label="Energy Shield"}}) do
			local itemVal = armourData[def.var]
			if itemVal and itemVal > 0 then
				main:AddTooltipLine(16, s_format("^x7F7F7F%s: %s%d", def.label, itemVal ~= base.armour[def.var:sub(1,1):lower()..def.var:sub(2,-1).."Base"] and data.colorCodes.MAGIC or "^7", itemVal))
			end
		end
	elseif base.flask then
		-- Flask-specific info
		local flaskData = item.flaskData
		if item.quality > 0 then
			main:AddTooltipLine(16, s_format("^x7F7F7FQuality: "..data.colorCodes.MAGIC.."+%d%%", item.quality))
		end
		if flaskData.lifeTotal then
			main:AddTooltipLine(16, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FLife over %s%.1f0 ^x7F7F7FSeconds", flaskData.lifeTotal ~= base.flask.life and data.colorCodes.MAGIC or "^7", flaskData.lifeTotal, flaskData.duration ~= base.flask.duration and data.colorCodes.MAGIC or "^7", flaskData.duration))
		end
		if flaskData.manaTotal then
			main:AddTooltipLine(16, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FMana over %s%.1f0 ^x7F7F7FSeconds", flaskData.manaTotal ~= base.flask.mana and data.colorCodes.MAGIC or "^7", flaskData.manaTotal, flaskData.duration ~= base.flask.duration and data.colorCodes.MAGIC or "^7", flaskData.duration))
		end
		if not flaskData.lifeTotal and not flaskData.manaTotal then
			main:AddTooltipLine(16, s_format("^x7F7F7FLasts %s%.2f ^x7F7F7FSeconds", flaskData.duration ~= base.flask.duration and data.colorCodes.MAGIC or "^7", flaskData.duration))
		end
		main:AddTooltipLine(16, s_format("^x7F7F7FConsumes %s%d ^x7F7F7Fof %s%d ^x7F7F7FCharges on use",
			flaskData.chargesUsed ~= base.flask.chargesUsed and data.colorCodes.MAGIC or "^7",
			flaskData.chargesUsed,
			flaskData.chargesMax ~= base.flask.chargesMax and data.colorCodes.MAGIC or "^7",
			flaskData.chargesMax
		))
		for _, modLine in pairs(item.modLines) do
			if modLine.buff then
				main:AddTooltipLine(16, (modLine.extra and data.colorCodes.UNSUPPORTED or data.colorCodes.MAGIC) .. modLine.line)
			end
		end
	elseif item.type == "Jewel" then
		-- Jewel-specific info
		if item.limit then
			main:AddTooltipLine(16, "^x7F7F7FLimited to: ^7"..item.limit)
		end
		if item.jewelRadiusIndex then
			main:AddTooltipLine(16, "^x7F7F7FRadius: ^7"..data.jewelRadius[item.jewelRadiusIndex].label)
		end
		if item.jewelRadiusData and slot and item.jewelRadiusData[slot.nodeId] then
			local radiusData = item.jewelRadiusData[slot.nodeId]
			local line
			local codes = { data.colorCodes.MARAUDER, data.colorCodes.RANGER, data.colorCodes.WITCH }
			for i, stat in ipairs({"Str","Dex","Int"}) do
				if radiusData[stat] and radiusData[stat] ~= 0 then
					line = (line and line .. ", " or "") .. s_format("%s%d %s^7", codes[i], radiusData[stat], stat)
				end
			end
			if line then
				main:AddTooltipLine(16, "^x7F7F7FAllocated in Radius: "..line)
			end
		end
	end
	main:AddTooltipSeparator(10)

	-- Implicit/explicit modifiers
	if item.modLines[1] then
		for index, modLine in pairs(item.modLines) do
			if not modLine.buff and (not modLine.variantList or modLine.variantList[item.variant]) then
				local line = (not dbMode and modLine.range and itemLib.applyRange(modLine.line, modLine.range)) or modLine.line
				if not line:match("^%+?0[^%.]") and not line:match(" 0%-0 ") and not line:match(" 0 to 0 ") then -- Hack to hide 0-value modifiers
					local colorCode
					if modLine.extra then
						colorCode = data.colorCodes.UNSUPPORTED
						if launch.devMode and IsKeyDown("ALT") then
							line = line .. "   ^1'" .. modLine.extra .. "'"
						end
					else
						colorCode = modLine.crafted and data.colorCodes.CRAFTED or data.colorCodes.MAGIC
					end
					main:AddTooltipLine(16, colorCode..line)
				end
			end
			if index == item.implicitLines + item.buffLines and item.modLines[index + 1] then
				-- Add separator between implicit and explicit modifiers
				main:AddTooltipSeparator(10)
			end
		end
	end

	-- Corrupted item label
	if item.corrupted then
		if #item.modLines == item.implicitLines + item.buffLines then
			main:AddTooltipSeparator(10)
		end
		main:AddTooltipLine(16, "^1Corrupted")
	end
	main:AddTooltipSeparator(14)

	-- Mod differences
	local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator()
	if calcFunc then
		if base.flask then
			-- Special handling for flasks
			local stats = { }
			local flaskData = item.flaskData
			local modDB = self.build.calcsTab.mainEnv.modDB
			local durInc = modDB:Sum("INC", nil, "FlaskDuration")
			local effectInc = modDB:Sum("INC", nil, "FlaskEffect")
			if item.base.flask.life or item.base.flask.mana then
				local rateInc = modDB:Sum("INC", nil, "FlaskRecoveryRate")
				local instantPerc = flaskData.instantPerc > 0 and m_min(flaskData.instantPerc + effectInc, 100) or 0
				if item.base.flask.life then
					local lifeInc = modDB:Sum("INC", nil, "FlaskLifeRecovery")
					local lifeRateInc = modDB:Sum("INC", nil, "FlaskLifeRecoveryRate")
					local inst = flaskData.lifeBase * instantPerc / 100 * (1 + lifeInc / 100) * (1 + effectInc / 100)
					local grad = flaskData.lifeBase * (1 - instantPerc / 100) * (1 + lifeInc / 100) * (1 + effectInc / 100) * (1 + durInc / 100)
					local lifeDur = flaskData.duration * (1 + durInc / 100) / (1 + rateInc / 100) / (1 + lifeRateInc / 100)
					if inst > 0 and grad > 0 then
						t_insert(stats, s_format("^8Life recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8)", inst + grad, inst, grad, lifeDur))
					elseif inst + grad ~= flaskData.lifeTotal then
						if inst > 0 then
							t_insert(stats, s_format("^8Life recovered: ^7%d ^8instantly", inst))
						elseif grad > 0 then
							t_insert(stats, s_format("^8Life recovered: ^7%d ^8over ^7%.2fs", grad, lifeDur))
						end
					end
				end
				if item.base.flask.mana then
					local manaInc = modDB:Sum("INC", nil, "FlaskManaRecovery")
					local manaRateInc = modDB:Sum("INC", nil, "FlaskManaRecoveryRate")
					local inst = flaskData.manaBase * instantPerc / 100 * (1 + manaInc / 100) * (1 + effectInc / 100)
					local grad = flaskData.manaBase * (1 - instantPerc / 100) * (1 + manaInc / 100) * (1 + effectInc / 100) * (1 + durInc / 100)
					local manaDur = flaskData.duration * (1 + durInc / 100) / (1 + rateInc / 100) / (1 + manaRateInc / 100)
					if inst > 0 and grad > 0 then
						t_insert(stats, s_format("^8Mana recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8)", inst + grad, inst, grad, manaDur))
					elseif inst + grad ~= flaskData.manaTotal then
						if inst > 0 then
							t_insert(stats, s_format("^8Mana recovered: ^7%d ^8instantly", inst))
						elseif grad > 0 then
							t_insert(stats, s_format("^8Mana recovered: ^7%d ^8over ^7%.2fs", grad, manaDur))
						end
					end
				end
			else
				if durInc ~= 0 then
					t_insert(stats, s_format("^8Flask effect duration: ^7%.1f0s", flaskData.duration * (1 + durInc / 100)))
				end
			end
			local effectMod = 1 + (flaskData.effectInc + effectInc) / 100
			if effectMod ~= 1 then
				t_insert(stats, s_format("^8Flask effect modifier: ^7%+d%%", effectMod * 100 - 100))
			end
			local usedInc = modDB:Sum("INC", nil, "FlaskChargesUsed")
			if usedInc ~= 0 then
				local used = m_floor(flaskData.chargesUsed * (1 + usedInc / 100))
				t_insert(stats, s_format("^8Charges used: ^7%d ^8of ^7%d ^8(^7%d ^8uses)", used, flaskData.chargesMax, m_floor(flaskData.chargesMax / used)))
			end
			local gainMod = flaskData.gainMod * (1 + modDB:Sum("INC", nil, "FlaskChargesGained") / 100)
			if gainMod ~= 1 then
				t_insert(stats, s_format("^8Charge gain modifier: ^7%+d%%", gainMod * 100 - 100))
			end
			if stats[1] then
				main:AddTooltipLine(14, "^7Effective flask stats:")
				for _, stat in ipairs(stats) do
					main:AddTooltipLine(14, stat)
				end
			end
			local output = calcFunc({ toggleFlask = item })
			local header
			if self.build.calcsTab.mainEnv.flasks[item] then
				header = "^7Deactivating this flask will give you:"
			else
				header = "^7Activating this flask will give you:"
			end
			self.build:AddStatComparesToTooltip(calcBase, output, header)
		else
			self:UpdateSockets()
			-- Build sorted list of slots to compare with
			local compareSlots = { }
			for slotName, slot in pairs(self.slots) do
				local selItem = self.list[slot.selItemId]
				if self:IsItemValidForSlot(item, slotName) and not slot.inactive then
					t_insert(compareSlots, slot)
				end
			end
			table.sort(compareSlots, function(a, b)
				if a.selItemId ~= b.selItemId then
					if item == self.list[a.selItemId] then
						return true
					elseif item == self.list[b.selItemId] then
						return false
					end
				end
				local aNum = tonumber(a.slotName:match("%d+"))
				local bNum = tonumber(b.slotName:match("%d+"))
				if aNum and bNum then
					return aNum < bNum
				else
					return a.slotName < b.slotName
				end
			end)

			-- Add comparisons for each slot
			for _, slot in pairs(compareSlots) do
				local selItem = self.list[slot.selItemId]
				local output = calcFunc({ repSlotName = slot.slotName, repItem = item ~= selItem and item })
				local header
				if item == selItem then
					header = "^7Removing this item from "..slot.label.." will give you:"
				else
					header = string.format("^7Equipping this item in %s%s will give you:", slot.label, selItem and " (replacing "..data.colorCodes[selItem.rarity]..selItem.name.."^7)" or "")
				end
				self.build:AddStatComparesToTooltip(calcBase, output, header)
			end
		end
	end

	if launch.devMode and IsKeyDown("ALT") then
		-- Modifier debugging info
		main:AddTooltipSeparator(10)
		for _, mod in ipairs(modList) do
			main:AddTooltipLine(14, "^7"..modLib.formatMod(mod))
		end
	end
end

function ItemsTabClass:CreateUndoState()
	local state = { }
	state.list = copyTable(self.list)
	state.orderList = copyTable(self.orderList)
	state.slotSelItemId = { }
	for slotName, slot in pairs(self.slots) do
		state.slotSelItemId[slotName] = slot.selItemId
	end
	return state
end

function ItemsTabClass:RestoreUndoState(state)
	self.list = state.list
	self.orderList = state.orderList
	for slotName, selItemId in pairs(state.slotSelItemId) do
		self.slots[slotName]:SetSelItemId(selItemId)
	end
	self:PopulateSlots()
end
