-- Path of Building
--
-- Module: Items
-- Items view for the active build
--
local launch, main = ...

local t_insert = table.insert
local t_remove = table.remove
local s_format = string.format

local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt" }

local items = { }

function items:Init(build)
	self.build = build

	self.socketViewer = common.New("PassiveTreeView")

	self.list = { }
	self.orderList = { }

	self.slots = { }

	self.controls = { }

	for index, slotName in pairs(baseSlots) do
		t_insert(self.controls, common.New("ItemSlot", self, 100, (index - 1) * 20 + 24, slotName))
	end

	self.controls.itemList = common.New("ItemList", 0, 0, 360, 300, self)
	self.controls.deleteItem = common.New("ButtonControl", 0, 0, 60, 18, "Delete", function()
		self.controls.itemList:OnKeyUp("DELETE")
	end, function()
		return self.controls.itemList.selItem ~= nil
	end)

	self.controls.itemDB = common.New("ItemDB", 0, 0, 360, 300, self, main.uniqueDB)

	self.controls.addDisplayItem = common.New("ButtonControl", 0, 0, 100, 20, "Add to build", function()
		self:AddDisplayItem()
	end)
	self.controls.removeDisplayItem = common.New("ButtonControl", 0, 0, 60, 20, "Cancel", function()
		self.displayItem = nil
	end)
	self.controls.displayItemVariant = common.New("DropDownControl", 0, 0, 200, 20, { }, function(sel)
		self.displayItem.variant = sel
		itemLib.buildItemModList(self.displayItem)
		if self.displayItem.rangeLineList[1] then
			self.controls.displayItemRangeLine.sel = 1
			self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[1].range
		end
	end)
	self.controls.displayItemRangeLine = common.New("DropDownControl", 0, 0, 400, 18, { }, function(sel)
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[sel].range
	end)
	self.controls.displayItemRangeSlider = common.New("SliderControl", 0, 0, 100, 20, function(val)
		self.displayItem.rangeLineList[self.controls.displayItemRangeLine.sel].range = val
		itemLib.buildItemModList(self.displayItem)
	end)

	self.sockets = { }
	for _, node in pairs(main.tree.nodes) do
		if node.type == "socket" then
			self.sockets[node.id] = common.New("ItemSlot", self, 100, 0, "Jewel "..node.id, "Socket", node.id)
		end
	end

	self.undo = { }
	self.redo = { }
end

function items:Shutdown()
	self.controls = nil
	self.slots = nil
	self.list = nil
end

function items:Load(xml, dbFileName)
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
	self.undo = { self:CreateUndoState() }
	self.redo = { }
	self:PopulateSlots()
end

function items:Save(xml)
	self.modFlag = false
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
		t_insert(xml, { elem = "Slot", attrib = { name = name, itemId = tostring(slot.selItemId) }})
	end
end

function items:DrawItems(viewPort, inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "v" and IsKeyDown("CTRL") then
				local newItem = Paste()
				if newItem then
					self:CreateDisplayItemFromRaw(newItem)
				end
			elseif event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
			end
		end
	end
	common.controlsInput(self, inputEvents)

	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(main.tree.assets.Background1.handle, viewPort.x, viewPort.y, viewPort.width, viewPort.height, 0, 0, viewPort.width / 100, viewPort.height / 100)

	if self.displayItem then
		self.controls.addDisplayItem.x = viewPort.x + 820
		self.controls.addDisplayItem.y = viewPort.y + 4
		self.controls.addDisplayItem.hidden = false
		self.controls.addDisplayItem.label = self.list[self.displayItem.id] and "Save" or "Add to build"
		self.controls.removeDisplayItem.x = viewPort.x + 820 + 104
		self.controls.removeDisplayItem.y = viewPort.y + 4
		self.controls.removeDisplayItem.hidden = false
		self.controls.displayItemVariant.x = viewPort.x + 820 + 104 + 64
		self.controls.displayItemVariant.y = viewPort.y + 4
		self.controls.displayItemVariant.hidden = not self.displayItem.variantList or #self.displayItem.variantList == 1
		local ttOffset
		if self.displayItem.rangeLineList[1] then
			ttOffset = 24
			self.controls.displayItemRangeLine.x = viewPort.x + 820
			self.controls.displayItemRangeLine.y = viewPort.y + 4 + 24 + 1
			self.controls.displayItemRangeLine.hidden = false
			self.controls.displayItemRangeSlider.x = viewPort.x + 820 + 404
			self.controls.displayItemRangeSlider.y = viewPort.y + 4 + 24
			self.controls.displayItemRangeSlider.hidden = false
			wipeTable(self.controls.displayItemRangeLine.list)
			for _, modLine in ipairs(self.displayItem.rangeLineList) do
				t_insert(self.controls.displayItemRangeLine.list, modLine.line)
			end
		else
			ttOffset = 0
			self.controls.displayItemRangeLine.hidden = true
			self.controls.displayItemRangeSlider.hidden = true
		end
		self:AddItemTooltip(self.displayItem)
		main:DrawTooltip(viewPort.x + 820, viewPort.y + 4 + 24 + ttOffset, nil, nil, viewPort, data.colorCodes[self.displayItem.rarity])
	else
		self.controls.addDisplayItem.hidden = true
		self.controls.removeDisplayItem.hidden = true
		self.controls.displayItemVariant.hidden = true
		self.controls.displayItemRangeLine.hidden = true
		self.controls.displayItemRangeSlider.hidden = true
	end

	DrawString(viewPort.x + 100, viewPort.y + 4, "LEFT", 16, "VAR", "^7Equipped items:")
	self.controls.itemList.x = viewPort.x + 440
	self.controls.itemList.y = viewPort.y + 24
	self.controls.deleteItem.x = self.controls.itemList.x + self.controls.itemList.width - 60
	self.controls.deleteItem.y = viewPort.y + 4
	DrawString(viewPort.x + 440, viewPort.y + 4, "LEFT", 16, "VAR", "^7All items:")
	self.controls.itemDB.x = viewPort.x + 440
	self.controls.itemDB.y = viewPort.y + 24 + 300 + 60

	self:UpdateJewels()

	common.controlsDraw(self, viewPort)
end

function items:PopulateSlots()
	for _, slot in pairs(self.slots) do
		slot:Populate()
	end
end

function items:UpdateJewels()
	local spec = self.build.spec
	for nodeId, slot in pairs(self.sockets) do
		if not spec.allocNodes[nodeId] then
			slot.inactive = true
			if self.controls["socket"..nodeId] then
				self.controls["socket"..nodeId] = nil
			end
		end
	end
	local socketList = { }
	for nodeId, node in pairs(spec.allocNodes) do
		if node.type == "socket" then
			t_insert(socketList, nodeId)
		end
	end
	table.sort(socketList)
	for index, nodeId in pairs(socketList) do
		local slot = self.sockets[nodeId]
		self.controls["socket"..nodeId] = slot
		slot.inactive = false
		slot.baseY = (#baseSlots + index - 1) * 20 + 24
	end
end

function items:GetSocketAndJewelForNodeID(nodeId)
	return self.sockets[nodeId], self.list[self.sockets[nodeId].selItemId]
end

function items:CreateDisplayItemFromRaw(itemRaw)
	local newItem = itemLib.makeItemFromRaw(itemRaw)
	if newItem then
		self:SetDisplayItem(newItem)
	end
end

function items:SetDisplayItem(item)
	self.displayItem = item
	self.controls.displayItemVariant.list = item.variantList
	self.controls.displayItemVariant.sel = item.variant
	if self.displayItem.rangeLineList[1] then
		self.controls.displayItemRangeLine.sel = 1
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[1].range
	end
end

function items:AddDisplayItem()
	if not self.displayItem.id then
		self.displayItem.id = 1
		while self.list[self.displayItem.id] do
			self.displayItem.id = self.displayItem.id + 1
		end
		t_insert(self.orderList, self.displayItem.id)
	end
	self.list[self.displayItem.id] = self.displayItem
	self.displayItem = nil
	self:PopulateSlots()
	self:AddUndoState()
end

function items:DeleteItem(item)
	for _, slot in pairs(self.slots) do
		if slot.selItemId == item.id then
			slot.selItemId = 0
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

function items:GetEquippedSlotForItem(item)
	for _, slot in pairs(self.slots) do
		if slot.selItemId == item.id then
			return slot
		end
	end
end

function items:IsItemValidForSlot(item, slotName)
	if item.type == slotName:gsub(" %d+","") then
		return true
	elseif slotName == "Weapon 1" or slotName == "Weapon" then
		return item.base.weapon ~= nil
	elseif slotName == "Weapon 2" then
		local weapon1Sel = self.slots["Weapon 1"].selItemId or 0
		local weapon1Type = weapon1Sel > 0 and self.list[weapon1Sel].base.type or "None"
		if weapon1Type == "Bow" then
			return item.type == "Quiver"
		elseif data.weaponTypeInfo[weapon1Type].oneHand then
			return item.type == "Shield" or (data.weaponTypeInfo[item.type] and data.weaponTypeInfo[item.type].oneHand and (weapon1Type == "None" or (weapon1Type == "Wand" and item.type == "Wand") or (weapon1Type ~= "Wand" and item.type ~= "Wand")))
		end
	end
end

function items:GetPrimarySlotForItem(item)
	if item.base.weapon then
		return "Weapon 1"
	elseif item.type == "Quiver" or item.type == "Shield" then
		return "Weapon 2"
	else
		return item.type
	end
end

function items:AddItemTooltip(item, dbMode)
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
	if dbMode and (item.variantList or item.league) then
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
		main:AddTooltipSeperator(10)
	end

	local base = item.base
	local modList = item.modList
	if base.weapon then
		-- Weapon-specific info
		main:AddTooltipLine(16, s_format("^x7F7F7F%s", base.type))
		if item.quality > 0 then
			main:AddTooltipLine(16, s_format("^x7F7F7FQuality: "..data.colorCodes.MAGIC.."+%d%%", item.quality))
		end
		local totalDamage = 0
		local totalDamageTypes = 0
		if modList.weaponX_physicalMin then
			totalDamage = totalDamage + (modList.weaponX_physicalMin + modList.weaponX_physicalMax) / 2
			local physicalDPS = (modList.weaponX_physicalMin + modList.weaponX_physicalMax) / 2 * modList.weaponX_attackRate
			main:AddTooltipLine(16, s_format("^x7F7F7FPhysical Damage: "..data.colorCodes.MAGIC.."%d-%d (%.1f DPS)", modList.weaponX_physicalMin, modList.weaponX_physicalMax, physicalDPS))
			totalDamageTypes = totalDamageTypes + 1
		end
		local elemLine
		local elemTotal = 0
		for _, var in ipairs({"fire","cold","lightning"}) do
			local min = modList["weaponX_"..var.."Min"]
			local max = modList["weaponX_"..var.."Max"]
			if min and max then
				elemLine = elemLine and elemLine.."^x7F7F7F, " or "^x7F7F7FElemental Damage: "
				elemLine = elemLine..s_format("%s%d-%d", data.colorCodes[var:upper()], min, max)
				elemTotal = elemTotal + (min + max) / 2
			end
		end
		totalDamage = totalDamage + elemTotal
		if elemLine then
			main:AddTooltipLine(16, elemLine)
			main:AddTooltipLine(16, s_format("^x7F7F7FElemental DPS: "..data.colorCodes.MAGIC.."%.1f", elemTotal * modList.weaponX_attackRate))
			totalDamageTypes = totalDamageTypes + 1	
		end
		if modList.weaponX_chaosMin then
			totalDamage = totalDamage + (modList.weaponX_chaosMin + modList.weaponX_chaosMax) / 2
			local chaosDPS = (modList.weaponX_chaosMin + modList.weaponX_chaosMax) / 2 * modList.weaponX_attackRate
			main:AddTooltipLine(16, s_format("^x7F7F7FChaos Damage: "..data.colorCodes.CHAOS.."%d-%d "..data.colorCodes.MAGIC.."(%.1f DPS)", modList.weaponX_chaosMin, modList.weaponX_chaosMax, chaosDPS))
			totalDamageTypes = totalDamageTypes + 1
		end
		if totalDamageTypes > 1 then
			main:AddTooltipLine(16, s_format("^x7F7F7FTotal DPS: "..data.colorCodes.MAGIC.."%.1f", totalDamage * modList.weaponX_attackRate))
		end
		main:AddTooltipLine(16, s_format("^x7F7F7FCritical Strike Chance: %s%.2f%%", modList.weaponX_critChanceBase ~= base.weapon.critChanceBase and data.colorCodes.MAGIC or "^7", modList.weaponX_critChanceBase))
		main:AddTooltipLine(16, s_format("^x7F7F7FAttacks per Second: %s%.2f", modList.weaponX_attackRate ~= base.weapon.attackRateBase and data.colorCodes.MAGIC or "^7", modList.weaponX_attackRate))
	elseif base.armour then
		-- Armour-specific info
		if item.quality > 0 then
			main:AddTooltipLine(16, s_format("^x7F7F7FQuality: "..data.colorCodes.MAGIC.."+%d%%", item.quality))
		end
		if base.armour.blockChance and modList.blockChance > 0 then
			main:AddTooltipLine(16, s_format("^x7F7F7FChance to Block: %s%d%%", modList.blockChance ~= base.armour.blockChance and data.colorCodes.MAGIC or "^7", modList.blockChance))
		end
		for _, def in ipairs({{var="armour",label="Armour"},{var="evasion",label="Evasion Rating"},{var="energyShield",label="Energy Shield"}}) do
			local itemVal = modList[def.var.."Base"]
			if itemVal then
				main:AddTooltipLine(16, s_format("^x7F7F7F%s: %s%d", def.label, itemVal ~= base.armour[def.var.."Base"] and data.colorCodes.MAGIC or "^7", itemVal))
			end
		end
	elseif item.jewelRadiusIndex then
		-- Jewel-specific info
		main:AddTooltipLine(16, "^x7F7F7FRadius: ^7"..data.jewelRadius[item.jewelRadiusIndex].label)
	end
	main:AddTooltipSeperator(10)

	-- Implicit/explicit modifiers
	if item.modLines[1] then
		for index, modLine in pairs(item.modLines) do
			if not modLine.variantList or modLine.variantList[item.variant] then
				local line = (not dbMode and modLine.range and itemLib.applyRange(modLine.line, modLine.range)) or modLine.line
				if not line:match("^%+?0") then -- Hack to hide 0-value modifiers
					main:AddTooltipLine(16, (modLine.extra and data.colorCodes.NORMAL or data.colorCodes.MAGIC)..line)
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
	local calcFunc, calcBase = self.build.calcs:GetItemCalculator()
	if calcFunc then
		self:UpdateJewels()
		local compareSlots = { }
		for slotName, slot in pairs(self.slots) do
			local selItem = self.list[slot.selItemId]
			if items:IsItemValidForSlot(item, slotName) and not slot.inactive and (item ~= selItem or item.type == "Jewel") then
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
		local seperator = false
		for _, slot in pairs(compareSlots) do
			local selItem = self.list[slot.selItemId]
			local output = calcFunc(slot.slotName, item ~= selItem and item)
			local header
			if item == selItem then
				header = "^7Removing this jewel will give you:"
			else
				header = string.format("^7Equipping this item in %s%s will give you:", slot.label, selItem and " (replacing "..data.colorCodes[selItem.rarity]..selItem.name.."^7)" or "")
			end
			self.build:AddStatComparesToTooltip(calcBase, output, header)
		end
	end

	if launch.devMode and IsKeyDown("ALT") then
		-- Modifier debugging info
		main:AddTooltipSeperator(10)
		local nameList = { }
		for k in pairs(modList) do
			t_insert(nameList, k)
		end
		table.sort(nameList)
		for _, name in ipairs(nameList) do
			main:AddTooltipLine(16, "^7"..name.." = "..tostring(modList[name]))
		end
	end
end

function items:CreateUndoState()
	local state = { }
	state.list = copyTable(self.list)
	state.orderList = copyTable(self.orderList)
	state.slotSelItemId = { }
	for slotName, slot in pairs(self.slots) do
		state.slotSelItemId[slotName] = slot.selItemId
	end
	return state
end

function items:RestoreUndoState(state)
	self.list = state.list
	self.orderList = state.orderList
	for slotName, selItemId in pairs(state.slotSelItemId) do
		self.slots[slotName].selItemId = selItemId
	end
	self:PopulateSlots()
end

function items:AddUndoState(noClearRedo)
	t_insert(self.undo, 1, self:CreateUndoState())
	self.undo[102] = nil
	self.modFlag = true
	self.buildFlag = true
	if not noClearRedo then
		self.redo = {}
	end
end

function items:Undo()
	if self.undo[2] then
		t_insert(self.redo, 1, t_remove(self.undo, 1))
		self:RestoreUndoState(t_remove(self.undo, 1))
		self:AddUndoState(true)
	end
end

function items:Redo()
	if self.redo[1] then
		self:RestoreUndoState(t_remove(self.redo, 1))
		self:AddUndoState(true)
	end
end

return items