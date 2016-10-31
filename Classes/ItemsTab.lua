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

local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt" }

local ItemsTabClass = common.NewClass("ItemsTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build

	self.socketViewer = common.New("PassiveTreeView")

	self.list = { }
	self.orderList = { }

	-- Item slots
	self.slots = { }
	for index, slotName in pairs(baseSlots) do
		t_insert(self.controls, common.New("ItemSlot", {"TOPLEFT",self,"TOPLEFT"}, 96, (index - 1) * 20 + 24, self, slotName))
	end
	self.sockets = { }
	for _, node in pairs(main.tree.nodes) do
		if node.type == "socket" then
			local socketControl = common.New("ItemSlot", {"TOPLEFT",self,"TOPLEFT"}, 96, 0, self, "Jewel "..node.id, "Socket", node.id)
			self.controls["socket"..node.id] = socketControl
			self.sockets[node.id] = socketControl
		end
	end
	self.controls.slotHeader = common.New("LabelControl", {"BOTTOMLEFT",self.slots[baseSlots[1]],"TOPLEFT"}, 0, -4, 0, 16, "^7Equipped items:")

	-- Build item list
	self.controls.itemList = common.New("ItemList", {"TOPLEFT",self.slots[baseSlots[1]],"TOPRIGHT"}, 20, 0, 360, 308, self)

	self.controls.selectDBLabel = common.New("LabelControl", {"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, 0, 14, 0, 16, "^7Import from:")
	self.controls.selectDB = common.New("DropDownControl", {"LEFT",self.controls.selectDBLabel,"RIGHT"}, 4, 0, 150, 18, { "Uniques", "Rare Templates" })

	-- Unique database
	self.controls.uniqueDB = common.New("ItemDB", {"TOPLEFT",self.controls.selectDBLabel,"BOTTOMLEFT"}, 0, 46, 360, 260, self, main.uniqueDB)
	self.controls.uniqueDB.shown = function()
		return self.controls.selectDB.sel == 1
	end

	-- Rare template database
	self.controls.rareDB = common.New("ItemDB", {"TOPLEFT",self.controls.selectDBLabel,"BOTTOMLEFT"}, 0, 46, 360, 260, self, main.rareDB)
	self.controls.rareDB.shown = function()
		return self.controls.selectDB.sel == 2
	end

	-- Display item
	self.controls.displayItemTip = common.New("LabelControl", {"TOPLEFT",self.controls.itemList,"TOPRIGHT"}, 20, 0, 100, 16, 
		"^7Double-click an item from one of the lists,\nor copy and paste an item from in game\nto view/edit the item and add it to your build.\nYou can Control + Click an item to equip it, or drag it onto the slot.\nThis will also add it to your build if it's from the unique/template list.\nIf there's 2 slots an item can go in, holding Shift will put it in the second.")
	self.controls.displayItemTip.shown = function()
		return self.displayItem == nil
	end
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
	self.controls.removeDisplayItem = common.New("ButtonControl", {"LEFT",self.controls.addDisplayItem,"RIGHT"}, 8, 0, 60, 20, "Cancel", function()
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
	self.controls.displayItemRangeLine = common.New("DropDownControl", {"TOPLEFT",self.controls.addDisplayItem,"BOTTOMLEFT"}, 0, 8, 350, 18, nil, function(sel)
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[sel].range
	end)
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
			if self.slots[node.attrib.name or ""] then
				self.slots[node.attrib.name].selItemId = tonumber(node.attrib.itemId)
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
		if slot.selItemId ~= 0 then
			t_insert(xml, { elem = "Slot", attrib = { name = name, itemId = tostring(slot.selItemId) }})
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
					self:CreateDisplayItemFromRaw(newItem)
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

-- Attempt to create a new item from the given item raw text and sets it as the new display item
function ItemsTabClass:CreateDisplayItemFromRaw(itemRaw)
	local newItem = itemLib.makeItemFromRaw(itemRaw)
	if newItem then
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
					self.slots[slotName].selItemId = item.id
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
			slot.selItemId = 0
			self.build.buildFlag = true
		end
	end
	for index, id in pairs(self.orderList) do
		if id == item.id then
			t_remove(self.orderList, index)
			break
		end
	end
	self.list[item.id] = nil
	self:PopulateSlots()
	self:AddUndoState()
end

-- Returns a slot in which the given item is equipped, if one exists
-- If the item is equipped in multiple slots, the return value may be any of those slots
function ItemsTabClass:GetEquippedSlotForItem(item)
	for _, slot in pairs(self.slots) do
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
		main:AddTooltipLine(20, rarityCode..item.baseName)
	else
		main:AddTooltipLine(20, rarityCode..item.name)
	end
	main:AddTooltipSeperator(10)

	-- Special fields for database items
	if dbMode and (item.variantList or item.league or item.unreleased) then
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
		main:AddTooltipSeperator(10)
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
				main:AddTooltipLine(16, s_format("^x7F7F7F%s: %s%d", def.label, itemVal ~= base.armour[def.var.."Base"] and data.colorCodes.MAGIC or "^7", itemVal))
			end
		end
	elseif item.type == "Jewel" then
		-- Jewel-specific info
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
		if item.limit then
			main:AddTooltipLine(16, "^x7F7F7FLimited to: ^7"..item.limit)
		end
	end
	main:AddTooltipSeperator(10)

	-- Implicit/explicit modifiers
	if item.modLines[1] then
		for index, modLine in pairs(item.modLines) do
			if not modLine.variantList or modLine.variantList[item.variant] then
				local line = (not dbMode and modLine.range and itemLib.applyRange(modLine.line, modLine.range)) or modLine.line
				if not line:match("^%+?0[^%.]") and not line:match(" 0%-0 ") and not line:match(" 0 to 0 ") then -- Hack to hide 0-value modifiers
					local colorCode
					if modLine.extra then
						colorCode = data.colorCodes.UNSUPPORTED
					else
						colorCode = modLine.crafted and data.colorCodes.CRAFTED or data.colorCodes.MAGIC
					end
					main:AddTooltipLine(16, colorCode..line)
				end
			end
			if index == item.implicitLines and item.modLines[index + 1] then
				-- Add seperator between implicit and explicit modifiers
				main:AddTooltipSeperator(10)
			end
		end
	end

	-- Corrupted item label
	if item.corrupted then
		if #item.modLines == item.implicitLines then
			main:AddTooltipSeperator(10)
		end
		main:AddTooltipLine(16, "^1Corrupted")
	end
	main:AddTooltipSeperator(14)

	-- Mod differences
	local calcFunc, calcBase = self.build.calcsTab:GetItemCalculator()
	if calcFunc then
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
			local output = calcFunc(slot.slotName, item ~= selItem and item)
			local header
			if item == selItem then
				header = "^7Removing this item will give you:"
			else
				header = string.format("^7Equipping this item in %s%s will give you:", slot.label, selItem and " (replacing "..data.colorCodes[selItem.rarity]..selItem.name.."^7)" or "")
			end
			self.build:AddStatComparesToTooltip(calcBase, output, header)
		end
	end

	if launch.devMode and IsKeyDown("ALT") then
		-- Modifier debugging info
		main:AddTooltipSeperator(10)
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
		self.slots[slotName].selItemId = selItemId
	end
	self:PopulateSlots()
end
