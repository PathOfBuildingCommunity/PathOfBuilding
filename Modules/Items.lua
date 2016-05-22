-- Path of Building
--
-- Module: Items
-- Items view for the active build
--
local launch, main = ...

local t_insert = table.insert
local s_format = string.format

local baseSlots = { "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Weapon 1", "Weapon 2" }

local items = { }

function items:Init(build)
	self.build = build

	self.list = { }
	self.orderList = { }

	self.slots = { }

	self.controls = { }
	self.controls.addDisplayItem = common.New("ButtonControl", 0, 0, 60, 20, "Add", function()
		self:AddDisplayItem()
	end)
	for index, slotName in pairs(baseSlots) do
		t_insert(self.controls, common.New("ItemSlot", self, 400, (index - 1) * 20, slotName))
	end

	self.sockets = { }
	for _, node in pairs(main.tree.nodes) do
		if node.type == "socket" then
			self.sockets[node.id] = common.New("ItemSlot", self, 400, 0, "Jewel "..node.id, "Socket")
		end
	end
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
				self.slots[node.attrib.name].selItem = tonumber(node.attrib.itemId)
			end
		end
	end
	self:PopulateSlots()
end

function items:Save(xml)
	self.modFlag = false
	for _, id in ipairs(self.orderList) do
		local item = self.list[id]
		local child = { elem = "Item", attrib = { id = tostring(id) } }
		t_insert(child, item.raw)
		for id, modLine in ipairs(item.modLines) do
			if modLine.range then
				t_insert(child, { elem = "ModRange", attrib = { id = tostring(id), range = tostring(modLine.range) } })
			end
		end
		t_insert(xml, child)
	end
	for name, slot in pairs(self.slots) do
		t_insert(xml, { elem = "Slot", attrib = { name = name, itemId = tostring(slot.selItem) }})
	end
end

function items:DrawItems(viewPort, inputEvents)
	common.controlsInput(self, inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "v" and IsKeyDown("CTRL") then
				local newItem = Paste()
				if newItem then
					self.displayItem = {
						raw = newItem:gsub("^%s+",""):gsub("%s+$",""):gsub("–","-"):gsub("%b<>",""):gsub("ö","o")
					}
					itemLib.parseItemRaw(self.displayItem)
					if not self.displayItem.baseName then
						self.displayItem = nil
					end
				end
			end
		end
	end

	if self.displayItem then
		self.controls.addDisplayItem.x = viewPort.x + viewPort.width - 530
		self.controls.addDisplayItem.y = viewPort.y + 4
		self.controls.addDisplayItem.hidden = false
		self.controls.addDisplayItem.label = self.list[self.displayItem.id] and "Save" or "Add"
		self:AddItemTooltip(self.displayItem)
		main:DrawTooltip(viewPort.x + viewPort.width - 500, viewPort.y + 28, nil, nil, viewPort, data.colorCodes[self.displayItem.rarity], true)
	else
		self.controls.addDisplayItem.hidden = true
	end

	self:UpdateJewels()

	common.controlsDraw(self, viewPort)

	for index, id in pairs(self.orderList) do
		local item = self.list[id]
		local rarityCode = data.colorCodes[item.rarity]
		SetDrawColor(rarityCode)
		local x = viewPort.x + 2
		local y = viewPort.y + 2 + 16 * (index - 1)
		DrawString(x, y, "LEFT", 16, "VAR", item.name)
		local cx, cy = GetCursorPos()
		if cx >= x and cx < x + 250 and cy >= y and cy < y + 16 then
			self:AddItemTooltip(item)
			main:DrawTooltip(x, y, 250, 16, viewPort, rarityCode, true)
		end
	end
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
			self.controls["socket"..nodeId] = nil
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
		slot.baseY = (#baseSlots + index - 1) * 20
	end
end

function items:GetSocketAndJewel(nodeId)
	return self.sockets[nodeId], self.list[self.sockets[nodeId].selItem]
end

function items:AddDisplayItem()
	for _, item in pairs(self.list) do
		if item.raw == self.displayItem.raw then
			self.displayItem = nil
			return
		end
	end
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
end

function items:IsItemValidForSlot(item, slotName)
	if item.type == slotName:gsub(" %d+","") then
		return true
	elseif slotName == "Weapon 1" or slotName == "Weapon" then
		return data.itemBases[item.baseName].weapon ~= nil
	elseif slotName == "Weapon 2" then
		local weapon1Sel = self.slots["Weapon 1"].selItem
		local weapon1Type = weapon1Sel > 0 and data.itemBases[self.list[weapon1Sel].baseName].type or "None"
		if weapon1Type == "Bow" then
			return item.type == "Quiver"
		elseif data.weaponTypeInfo[weapon1Type].oneHand then
			return item.type == "Shield" or (data.weaponTypeInfo[item.type] and data.weaponTypeInfo[item.type].oneHand and (weapon1Type == "None" or (weapon1Type == "Wand" and item.type == "Wand") or (weapon1Type ~= "Wand" and item.type ~= "Wand")))
		end
	end
end

function items:AddItemTooltip(item)
	local rarityCode = data.colorCodes[item.rarity]
	if item.title then
		main:AddTooltipLine(20, rarityCode..item.title)
		main:AddTooltipLine(20, rarityCode..item.baseName)
	else
		main:AddTooltipLine(20, rarityCode..item.name)
	end
	local base = data.itemBases[item.baseName]
	modList = item.modList
	if base.weapon then
		main:AddTooltipSeperator(10)
		main:AddTooltipLine(16, s_format("^x7F7F7F%s", base.type))
		main:AddTooltipLine(16, "^x7F7F7FQuality: "..data.colorCodes.MAGIC.."+20%")
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
		main:AddTooltipSeperator(10)
		main:AddTooltipLine(16, "^x7F7F7FQuality: "..data.colorCodes.MAGIC.."+20%")
		if base.armour.blockChance and modList.blockChance > 0 then
			main:AddTooltipLine(16, s_format("^x7F7F7FChance to Block: %s%d%%", modList.blockChance ~= base.armour.blockChance and data.colorCodes.MAGIC or "^7", modList.blockChance))
		end
		for _, def in ipairs({{var="armour",label="Armour"},{var="evasion",label="Evasion Rating"},{var="energyShield",label="Energy Shield"}}) do
			local itemVal = modList[def.var.."Base"]
			if itemVal then
				main:AddTooltipLine(16, s_format("^x7F7F7F%s: %s%d", def.label, itemVal ~= base.armour[def.var.."Base"] and data.colorCodes.MAGIC or "^7", itemVal))
			end
		end
	elseif item.radius then
		main:AddTooltipSeperator(10)
		main:AddTooltipLine(16, "^x7F7F7FRadius: ^7"..data.jewelRadius[item.radius].label)
	end
	if item.modLines[1] then
		main:AddTooltipSeperator(10)
		for index, modLine in pairs(item.modLines) do
			local line = modLine.range and itemLib.applyRange(modLine.line, modLine.range) or modLine.line
			main:AddTooltipLine(16, (modLine.extra and data.colorCodes.NORMAL or data.colorCodes.MAGIC)..line)
			if index == item.implicitLines and item.modLines[index + 1] then
				main:AddTooltipSeperator(10)
			end
		end
	end
	if item.corrupted then
		if #item.modLines == item.implicitLines then
			main:AddTooltipSeperator(10)
		end
		main:AddTooltipLine(16, "^1Corrupted")
	end
	self:UpdateJewels()
	for slotName, slot in pairs(self.slots) do
		local selItem = self.list[slot.selItem]
		if items:IsItemValidForSlot(item, slotName) and not slot.inactive and (item ~= selItem or item.type == "Jewel") then
			local calcFunc, calcBase = self.build.calcs:GetItemCalculator()
			if calcFunc then
				local output = calcFunc(slotName, item ~= selItem and item)
				local header = false
				for _, statData in ipairs(self.build.displayStats) do
					if statData.mod then
						local diff = (output[statData.mod] or 0) - (calcBase[statData.mod] or 0)
						if diff > 0.001 or diff < -0.001 then
							if not header then
								main:AddTooltipSeperator(14)
								if item == selItem then
									main:AddTooltipLine(14, "^7Removing this jewel will give you:")
								else
									main:AddTooltipLine(14, string.format("^7Equipping this item in %s%s will give you:", slot.label, selItem and " (replacing "..data.colorCodes[selItem.rarity]..selItem.name.."^7)" or ""))
								end
								header = true
							end
							main:AddTooltipLine(14, string.format("%s%+"..statData.fmt.." %s", diff > 0 and data.colorCodes.POSITIVE or data.colorCodes.NEGATIVE, diff * (statData.pc and 100 or 1), statData.label))
						end
					end
				end
			end
		end
	end
	if launch.devMode and IsKeyDown("ALT") then
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

return items