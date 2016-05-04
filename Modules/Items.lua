-- Path of Building
--
-- Module: Items
-- Items view for the active build
--
local launch, cfg, main = ...

local t_insert = table.insert
local m_floor = math.floor
local s_format = string.format

local items = { }

local function applyRange(line, range)
	return line:gsub("%((%d+)%-(%d+) to (%d+)%-(%d+)%)", function(minMin, maxMin, minMax, maxMax) return string.format("%d-%d", tonumber(minMin) + range * (tonumber(minMax) - tonumber(minMin)), tonumber(maxMin) + range * (tonumber(maxMax) - tonumber(maxMin))) end)
		:gsub("%((%d+) to (%d+)%)", function(min, max) return tostring(tonumber(min) + range * (tonumber(max) - tonumber(min))) end)
end

items.slots = { }
items.controls = { }

items.controls.addDisplayItem = common.newButton(0, 0, 60, 20, "Add", function()
	items:AddDisplayItem()
end)

local function mkItemSlot(x, y, slotName, slotLabel)
	local slot = { }
	slot.items = { }
	slot.list = { }
	slot.x = x
	slot.y = y
	slot.width = 320
	slot.height = 20
	slot.slotName = slotName
	slot.label = slotLabel or slotName
	slot.dropDown = common.newDropDown(x, y, slot.width, slot.height, slot.list, function(sel)
		if slot.items[sel] ~= slot.selItem then
			slot.selItem = slot.items[sel]
			items:PopulateSlots()
			items.buildFlag = true
			items.modFlag = true
		end
	end)
	function slot:Populate()
		wipeTable(self.items)
		wipeTable(self.list)
		self.items[1] = 0
		self.list[1] = "None"
		self.dropDown.sel = 1
		for _, item in ipairs(items.list) do
			if items:IsItemValidForSlot(item, slotName) then
				t_insert(self.items, item.id)
				t_insert(self.list, data.colorCodes[item.rarity]..item.name)
				if item.id == self.selItem then
					self.dropDown.sel = #self.list
				end
			end
		end
		if not self.selItem or not items.list[self.selItem] or not items:IsItemValidForSlot(items.list[self.selItem], slotName) then
			self.selItem = 0
		end
	end
	function slot:Draw(viewPort)
		self.dropDown.x = viewPort.x + self.x
		self.dropDown.y = viewPort.y + self.y
		DrawString(self.dropDown.x - 2, self.dropDown.y + 2, "RIGHT_X", self.height - 4, "VAR", "^7"..slot.label..":")
		self.dropDown:Draw()
		if self.dropDown:IsMouseOver() then
			local ttItem
			if self.dropDown.dropped then
				if self.dropDown.hoverSel then
					ttItem = items.list[self.items[self.dropDown.hoverSel]]
				end
			elseif self.selItem and not items.selControl then
				ttItem = items.list[self.selItem]
			end
			if ttItem then
				items:AddItemTooltip(ttItem)
				main:DrawTooltip(self.dropDown.x, self.dropDown.y, self.width, self.height, viewPort, data.colorCodes[ttItem.rarity], true)
			end
		end
	end
	function slot:IsMouseOver()
		return self.dropDown:IsMouseOver()
	end
	function slot:OnKeyDown(key)
		return self.dropDown:OnKeyDown(key)
	end
	function slot:OnKeyUp(key)
		return self.dropDown:OnKeyUp(key)
	end
	items.slots[slotName] = slot
	return slot
end

local baseSlots = { "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Weapon 1", "Weapon 2" }
for index, slotName in pairs(baseSlots) do
	t_insert(items.controls, mkItemSlot(400, (index - 1) * 20, slotName))
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
		slot.y = (#baseSlots + index - 1) * 20
	end
end

function items:GetSocketJewel(nodeId)
	return self.sockets[nodeId], self.list[self.sockets[nodeId].selItem]
end

function items:ParseItemRaw(item)
	if not item.id then
		item.id = 1
		while self.list[item.id] do
			item.id = item.id + 1
		end
	end
	item.name = "?"
	item.rarity = "UNIQUE"
	item.rawLines = { }
	for line in string.gmatch(item.raw .. "\r\n", "([^\r\n]*)\r?\n") do
		line = line:gsub("^%s+",""):gsub("%s+$","")
		if #line > 0 then
			t_insert(item.rawLines, line)
		end
	end
	local mode = "WIKI"
	local l = 1
	if item.rawLines[l] then
		local rarity = item.rawLines[l]:match("^Rarity: (%a+)")
		if rarity then
			mode = "GAME"
			item.rarity = rarity:upper()
			l = l + 1
		end
	end
	if item.rawLines[l] then
		item.name = item.rawLines[l]
		l = l + 1
	end
	if item.rarity == "NORMAL" or item.rarity == "MAGIC" then
		for baseName, baseData in pairs(data.itemBases) do
			if item.name:find(baseName, 1, true) then
				item.baseName = baseName
				item.type = baseData.type
				break
			end
		end
	elseif item.rawLines[l] and not item.rawLines[l]:match("^%-") and data.itemBases[item.rawLines[l]] then
		item.baseName = item.rawLines[l]
		item.title = item.name
		item.name = item.title .. ", " .. item.baseName
		item.type = data.itemBases[item.baseName].type
	end
	item.modLines = { }
	while item.rawLines[l] do
		local line = item.rawLines[l]
		if data.weaponTypeInfo[line] then
			item.weaponType = line
		else
			local specName, specVal = line:match("^([%a ]+): %+?([%d%-%.]+)")
			if not specName then
				specName, specVal = line:match("^([%a ]+): (.+)")
			end
			if specName then
				if specName == "Radius" and item.type == "Jewel" then
					for index, data in pairs(data.jewelRadius) do
						if specVal == data.label then
							item.radius = index
							break
						end
					end
				end
			else
				local rangedLine
				if line:match("%(%d+%-%d+ to %d+%-%d+%)") or line:match("%(%d+ to %d+%)") then
					rangedLine = applyRange(line, 1)
				end
				local modList, extra = mod.parseMod(rangedLine or line)
				if modList then
					t_insert(item.modLines, { line = line, extra = extra, mods = modList, range = rangedLine and 1 })
				end
			end
		end
		l = l + 1
	end
	self:BuildItemModList(item)
end

function items:BuildItemModList(item)
	local modList = { }
	item.modList = modList
	for _, modLine in ipairs(item.modLines) do
		if not modLine.extra then
			if modLine.range then
				local line = applyRange(modLine.line, modLine.range)
				local list, extra = mod.parseMod(line)
				if list and not extra then
					mod.mods = list
				end
			end
			for k, v in pairs(modLine.mods) do
				mod.listMerge(modList, k, v)
			end
		end
	end
	local base = data.itemBases[item.baseName]
	if not base then
		return
	end
	if base.weapon then
		modList.weaponX_type = base.type
		modList.weaponX_name = item.name
		for _, elem in pairs({"physical","lightning","cold","fire","chaos"}) do
			local min = (base.weapon[elem.."Min"] or 0) + (modList["attack_"..elem.."Min"] or 0)
			local max = (base.weapon[elem.."Max"] or 0) + (modList["attack_"..elem.."Max"] or 0)
			if elem == "physical" then
				if modList.weaponNoPhysical then
					min, max = 0, 0
				else
					min = m_floor(min * (1 + (modList["physicalInc"] or 0) / 100 + .2) + 0.5)
					max = m_floor(max * (1 + (modList["physicalInc"] or 0) / 100 + .2) + 0.5)
				end
				modList["physicalInc"] = nil
			end
			if min > 0 and max > 0 then
				modList["weaponX_"..elem.."Min"] = min
				modList["weaponX_"..elem.."Max"] = max
			end
			modList["attack_"..elem.."Min"] = nil
			modList["attack_"..elem.."Max"] = nil
		end
		modList.weaponX_attackRate = m_floor(base.weapon.attackRateBase * (1 + (modList.attackSpeedInc or 0) / 100) * 100 + 0.5) / 100
		modList.attackSpeedInc = nil
		if modList.weaponAlwaysCrit then
			modList.weaponX_critChanceBase = 100
		else
			modList.weaponX_critChanceBase = m_floor(base.weapon.critChanceBase * (1 + (modList.critChanceInc or 0) / 100) * 100 + 0.5) / 100
		end
		modList.critChanceInc = nil
	elseif base.armour then
		if base.type == "Shield" then
			modList.weaponX_type = "Shield"
		end
		if base.armour.armourBase then
			modList.armourBase = m_floor((base.armour.armourBase + (modList.armourBase or 0)) * (1 + ((modList.armourInc or 0) + (modList.armourAndEvasionInc or 0) + (modList.armourAndESInc or 0) + 20) / 100) + 0.5)
		end
		if base.armour.evasionBase then
			modList.evasionBase = m_floor((base.armour.evasionBase + (modList.evasionBase or 0)) * (1 + ((modList.evasionInc or 0) + (modList.armourAndEvasionInc or 0) + (modList.evasionAndEnergyShieldInc or 0) + 20) / 100) + 0.5)
		end
		if base.armour.energyShieldBase then
			modList.energyShieldBase = m_floor((base.armour.energyShieldBase + (modList.energyShieldBase or 0)) * (1 + ((modList.energyShieldInc or 0) + (modList.armourAndEnergyShieldInc or 0) + (modList.evasionAndEnergyShieldInc or 0) + 20) / 100) + 0.5)
		end
		if base.armour.blockChance then
			if modList.shieldNoBlock then
				modList.blockChance = 0
			else
				modList.blockChance = base.armour.blockChance + (modList.blockChance or 0)
			end
		end
		modList.armourInc = nil
		modList.evasionInc = nil
		modList.energyShieldInc = nil
		modList.armourAndEvasionInc = nil
		modList.armourAndESInc = nil
		modList.evasionAndEnergyShieldInc = nil
	elseif item.type == "Jewel" then
		item.jewelFunc = modList.jewelFunc
		modList.jewelFunc = nil
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
		if modList.weaponX_physicalMin then
			main:AddTooltipLine(16, s_format("^x7F7F7FPhysical Damage: "..data.colorCodes.MAGIC.."%d-%d", modList.weaponX_physicalMin, modList.weaponX_physicalMax))
		end
		local elemLine
		for _, var in ipairs({"fire","cold","lightning"}) do
			if modList["weaponX_"..var.."Min"] then
				elemLine = elemLine and elemLine.."^x7F7F7F, " or "^x7F7F7FElemental Damage: "
				elemLine = elemLine..s_format("%s%d-%d", data.colorCodes[var:upper()], modList["weaponX_"..var.."Min"], modList["weaponX_"..var.."Max"])
			end
		end
		if elemLine then
			main:AddTooltipLine(16, elemLine)
		end
		if modList.weaponX_chaosMin then
			main:AddTooltipLine(16, s_format("^x7F7F7FChaos Damage: "..data.colorCodes.CHAOS.."%d-%d", modList.weaponX_chaosMin, modList.weaponX_chaosMax))
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
			local line = modLine.range and applyRange(modLine.line, modLine.range) or modLine.line
			main:AddTooltipLine(16, (modLine.extra and data.colorCodes.NORMAL or data.colorCodes.MAGIC)..line)
			if index == 1 and base.implicit and item.modLines[2] then
				main:AddTooltipSeperator(10)
			end
		end
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
							main:AddTooltipLine(14, string.format("%s%+"..statData.fmt.." %s", diff > 0 and "^x00FF44" or "^xFF3300", diff * (statData.pc and 100 or 1), statData.label))
						end
					end
				end
			end
		end
	end
	if IsKeyDown("ALT") then
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

function items:AddDisplayItem()
	for _, item in pairs(self.list) do
		if item.raw == self.displayItem.raw then
			self.displayItem = nil
			return
		end
	end
	if not self.list[self.displayItem.id] then
		t_insert(self.orderList, self.displayItem.id)
	end
	self.list[self.displayItem.id] = self.displayItem
	self.displayItem = nil
	self:PopulateSlots()
end

function items:Init(build)
	self.build = build
	self.list = { }
	self.sockets = { }
	for _, node in pairs(main.tree.nodes) do
		if node.type == "socket" then
			self.sockets[node.id] = mkItemSlot(400, 0, "Jewel "..node.id, "Socket")
		end
	end
	self.orderList = { }
end
function items:Shutdown()

end

function items:Load(xml, dbFileName)
	for _, node in ipairs(xml) do
		if node.elem == "Item" then
			local item = { }
			item.raw = ""
			item.id = tonumber(node.attrib.id)
			self:ParseItemRaw(item)
			for _, child in ipairs(node) do
				if type(child) == "string" then
					item.raw = child
					self:ParseItemRaw(item)
				elseif child.elem == "ModRange" then
					local id = tonumber(child.attrib.id) or 0
					local range = tonumber(child.attrib.range) or 1
					if item.modLines[id] then
						item.modLines[id].range = range
					end
				end
			end
			self:BuildItemModList(item)
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
					self:ParseItemRaw(self.displayItem)
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

return items