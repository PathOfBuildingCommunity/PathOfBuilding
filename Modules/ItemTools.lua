-- Path of Building
--
-- Module: Item Tools
-- Various functions for dealing with items.
--

local t_insert = table.insert
local m_min = math.min
local m_floor = math.floor

itemLib = { }

-- Apply range value (0 to 1) to a modifier that has a range: (x to x) or (x-x to x-x)
function itemLib.applyRange(line, range)
	return line:gsub("%((%d+)%-(%d+) to (%d+)%-(%d+)%)", "(%1-%2) to (%3-%4)")
		:gsub("(%+?)%((%-?%d+) to (%d+)%)", "%1(%2-%3)")
		:gsub("(%+?)%((%-?%d+)%-(%d+)%)", 
		function(plus, min, max) 
			local numVal = m_floor(tonumber(min) + range * (tonumber(max) - tonumber(min)) + 0.5)
			if numVal < 0 then
				if plus == "+" then
					plus = ""
				end
			end
			return plus .. tostring(numVal)
		end)
		:gsub("%((%d+%.?%d*)%-(%d+%.?%d*)%)",
		function(min, max) 
			local numVal = m_floor((tonumber(min) + range * (tonumber(max) - tonumber(min))) * 10 + 0.5) / 10
			return tostring(numVal) 
		end)
		:gsub("%-(%d+%%) increased", function(num) return num.." reduced" end)
end

-- Clean item text by removing or replacing unsupported or redundant characters or sequences
function itemLib.sanitiseItemText(text)
	-- Something something unicode support something grumble
	return text:gsub("^%s+",""):gsub("%s+$",""):gsub("\r\n","\n"):gsub("%b<>",""):gsub("–","-"):gsub("\226\128\147","-"):gsub("\226\136\146","-"):gsub("ö","o"):gsub("\195\182","o"):gsub("[\128-\255]","?")
end

-- Make an item from raw data
function itemLib.makeItemFromRaw(raw)
	local newItem = {
		raw = itemLib.sanitiseItemText(raw)
	}
	itemLib.parseItemRaw(newItem)
	if newItem.baseName then
		return newItem
	end
end

-- Parse raw item data and extract item name, base type, quality, and modifiers
function itemLib.parseItemRaw(item)
	item.name = "?"
	item.rarity = "UNIQUE"
	item.quality = 0
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
	item.base = data.itemBases[item.baseName]
	item.modLines = { }
	item.implicitLines = 0
	local gameModeStage = "FINDIMPLICIT"
	local gameModeSection = 1
	local foundExplicit
	while item.rawLines[l] do
		local line = item.rawLines[l]
		if line == "--------" then
			gameModeSection = gameModeSection + 1
			if gameModeStage == "IMPLICIT" then
				item.implicitLines = #item.modLines
				gameModeStage = "FINDEXPLICIT"
			elseif gameModeStage == "EXPLICIT" then
				gameModeStage = "DONE"
			end
		elseif line == "Corrupted" then
			item.corrupted = true
		else
			local specName, specVal = line:match("^([%a ]+): (%x+)$")
			if not specName then
				specName, specVal = line:match("^([%a ]+): %+?([%d%-%.]+)")
			end
			if not specName then
				specName, specVal = line:match("^([%a ]+): (.+)$")
			end
			if specName then
				if specName == "Unique ID" then
					item.uniqueID = specVal
				elseif specName == "Item Level" then
					item.itemLevel = tonumber(specVal)
				elseif specName == "Quality" then
					item.quality = tonumber(specVal)
				elseif specName == "Sockets" then
					local group = 0
					item.sockets = { }
					for c in specVal:gmatch(".") do
						if c:match("[RGBW]") then
							t_insert(item.sockets, { color = c, group = group })
						elseif c == " " then
							group = group + 1
						end
					end
				elseif specName == "Radius" and item.type == "Jewel" then
					for index, data in pairs(data.jewelRadius) do
						if specVal == data.label then
							item.jewelRadiusIndex = index
							break
						end
					end
				elseif specName == "Limited to" and item.type == "Jewel" then
					item.limit = tonumber(specVal)
				elseif specName == "Variant" then
					if not item.variantList then
						item.variantList = { }
					end
					t_insert(item.variantList, specVal)
				elseif specName == "Selected Variant" then
					item.variant = tonumber(specVal)
				elseif specName == "League" then
					item.league = specVal
				elseif specName == "Implicits" then
					item.implicitLines = tonumber(specVal)
					gameModeStage = "FINDEXPLICIT"
				elseif specName == "Unreleased" then
					item.unreleased = (specVal == "true")
				end
			end
			if line == "Prefixes:" then
				foundExplicit = true
				gameModeStage = "EXPLICIT"
			end
			if not specName or foundExplicit then
				local varSpec = line:match("{variant:([%d,]+)}")
				local variantList
				if varSpec then
					variantList = { }
					for varId in varSpec:gmatch("%d+") do
						variantList[tonumber(varId)] = true
					end
				end
				local rangeSpec = line:match("{range:([%d.]+)}")
				local crafted = line:match("{crafted}")
				line = line:gsub("%b{}", "")
				local rangedLine
				if line:match("%(%d+%-%d+ to %d+%-%d+%)") or line:match("%(%-?[%d%.]+ to %-?[%d%.]+%)") or line:match("%(%-?[%d%.]+%-[%d%.]+%)") then
					rangedLine = itemLib.applyRange(line, 1)
				end
				local modList, extra = modLib.parseMod(rangedLine or line)
				if modList then
					t_insert(item.modLines, { line = line, extra = extra, mods = modList, variantList = variantList, crafted = crafted, range = rangedLine and (tonumber(rangeSpec) or 0.5) })
					if mode == "GAME" then
						if gameModeStage == "FINDIMPLICIT" then
							gameModeStage = "IMPLICIT"
						elseif gameModeStage == "FINDEXPLICIT" then
							foundExplicit = true
							gameModeStage = "EXPLICIT"
						end
					else
						foundExplicit = true
					end
				elseif mode == "GAME" then
					if gameModeStage == "IMPLICIT" or gameModeStage == "EXPLICIT" then
						t_insert(item.modLines, { line = line, extra = line, mods = { }, variantList = variantList, crafted = crafted })
					elseif gameModeStage == "FINDEXPLICIT" then
						gameModeStage = "DONE"
					end
				elseif foundExplicit then
					t_insert(item.modLines, { line = line, extra = line, mods = { }, variantList = variantList, crafted = crafted })
				end
			end
		end
		l = l + 1
	end
	if item.base and item.base.implicit then
		if item.implicitLines == 0 then
			item.implicitLines = 1
		end
	elseif mode == "GAME" and not foundExplicit then
		item.implicitLines = 0
	end
	if not item.corrupted and item.base and (item.base.armour or item.base.weapon) then
		item.quality = 20
	end
	if item.variantList then
		item.variant = m_min(#item.variantList, item.variant or #item.variantList)
	end
	itemLib.buildItemModList(item)
end

-- Create raw item data for given item
function itemLib.createItemRaw(item)
	item.rawLines = { }
	t_insert(item.rawLines, "Rarity: "..item.rarity)
	if item.title then
		t_insert(item.rawLines, item.title)
		t_insert(item.rawLines, item.baseName)
	else
		t_insert(item.rawLines, item.name)
	end
	if item.uniqueID then
		t_insert(item.rawLines, "Unique ID: "..item.uniqueID)
	end
	if item.league then
		t_insert(item.rawLines, "League: "..item.league)
	end
	if item.unreleased then
		t_insert(item.rawLines, "Unreleased: true")
	end
	if item.itemLevel then
		t_insert(item.rawLines, "Item Level: "..item.itemLevel)
	end
	if item.variantList then
		for _, variantName in ipairs(item.variantList) do
			t_insert(item.rawLines, "Variant: "..variantName)
		end
		t_insert(item.rawLines, "Selected Variant: "..item.variant)
	end
	if item.quality > 0 then
		t_insert(item.rawLines, "Quality: "..item.quality)
	end
	if item.sockets then
		local line = "Sockets: "
		for i, socket in pairs(item.sockets) do
			line = line .. socket.color
			if item.sockets[i+1] then
				line = line .. (socket.group == item.sockets[i+1].group and "-" or " ")
			end
		end
		t_insert(item.rawLines, line)
	end
	if item.jewelRadiusIndex then
		t_insert(item.rawLines, "Radius: "..data.jewelRadius[item.jewelRadiusIndex].label)
	end
	if item.limit then
		t_insert(item.rawLines, "Limited to: "..item.limit)
	end
	if item.implicitLines > 0 then
		t_insert(item.rawLines, "Implicits: "..item.implicitLines)
	end
	for _, modLine in ipairs(item.modLines) do
		local line = modLine.line
		if modLine.range then
			line = "{range:"..modLine.range.."}" .. line
		end
		if modLine.crafted then
			line = "{crafted}" .. line
		end
		if modLine.variantList then
			local varSpec
			for varId in pairs(modLine.variantList) do
				varSpec = (varSpec and varSpec.."," or "") .. varId
			end
			line = "{variant:"..varSpec.."}"..line
		end
		t_insert(item.rawLines, line)
	end
	if item.corrupted then
		t_insert(item.rawLines, "Corrupted")
	end
	item.raw = table.concat(item.rawLines, "\n")
end

-- Return the name of the slot this item is equipped in
function itemLib.getPrimarySlotForItem(item)
	if item.base.weapon then
		return "Weapon 1"
	elseif item.type == "Quiver" or item.type == "Shield" then
		return "Weapon 2"
	elseif item.type == "Ring" then
		return "Ring 1"
	else
		return item.type
	end
end

-- Build list of modifiers for an item in a given slot number (1 or 2) while applying local modifers and adding quality
function itemLib.buildItemModListForSlotNum(item, baseList, slotNum)
	local modList = { }
	-- Process slot-specific modifiers
	for k, v in pairs(baseList) do
		if k:match("SocketedIn:X") then
			local slotName = itemLib.getPrimarySlotForItem(item)
			if slotNum then
				slotName = slotName:gsub("1", slotNum)
			end
			k = k:gsub("SocketedIn:X","SocketedIn:"..slotName)
		end
		local slot = tonumber(k:match("IfSlot:(%d)_"))
		if slot then
			if slot == slotNum then
				k = k:gsub("IfSlot:%d_","")
				modLib.listMerge(modList, k, v)
			end
		else
			if slotNum then
				k = k:gsub("weaponX_","weapon"..slotNum.."_")
			end
			modLib.listMerge(modList, k, v)
		end
	end
	if item.base.weapon then
		local weaponPrefix = "weapon"..slotNum.."_"
		modList[weaponPrefix.."type"] = item.base.type
		modList[weaponPrefix.."name"] = item.name
		modList[weaponPrefix.."attackRate"] = m_floor(item.base.weapon.attackRateBase * (1 + (modList.attackSpeedInc or 0) / 100) * 100 + 0.5) / 100
		modList[weaponPrefix.."attackSpeedInc"] = modList.attackSpeedInc
		modList.attackSpeedInc = nil
		for _, dmgType in pairs({"physical","lightning","cold","fire","chaos"}) do
			local min = (item.base.weapon[dmgType.."Min"] or 0) + (modList["attack_"..dmgType.."Min"] or 0)
			local max = (item.base.weapon[dmgType.."Max"] or 0) + (modList["attack_"..dmgType.."Max"] or 0)
			if dmgType == "physical" then
				if modList.weaponLocal_noPhysical then
					min, max = 0, 0
				else
					min = m_floor(min * (1 + ((modList["physicalInc"] or 0) + item.quality) / 100) + 0.5)
					max = m_floor(max * (1 + ((modList["physicalInc"] or 0) + item.quality) / 100) + 0.5)
				end
				modList["physicalInc"] = nil
			end
			if min > 0 and max > 0 then
				modList[weaponPrefix..dmgType.."Min"] = min
				modList[weaponPrefix..dmgType.."Max"] = max
				local dps = (min + max) / 2 * modList[weaponPrefix.."attackRate"]
				modList[weaponPrefix..dmgType.."DPS"] = dps
				modList[weaponPrefix.."damageDPS"] = (modList[weaponPrefix.."damageDPS"] or 0) + dps
				if dmgType ~= "physical" and dmgType ~= "chaos" then
					modList[weaponPrefix.."elementalDPS"] = (modList[weaponPrefix.."elementalDPS"] or 0) + dps
				end
			end
			modList["attack_"..dmgType.."Min"] = nil
			modList["attack_"..dmgType.."Max"] = nil
		end
		if modList.weaponLocal_alwaysCrit then
			modList[weaponPrefix.."critChanceBase"] = 100
		else
			modList[weaponPrefix.."critChanceBase"] = m_floor(item.base.weapon.critChanceBase * (1 + (modList.critChanceInc or 0) / 100) * 100 + 0.5) / 100
		end
		modList.critChanceInc = nil
	elseif item.base.armour then
		if item.base.type == "Shield" then
			modList.weapon2_type = "Shield"
		end
		local basePrefix = "slot:"..item.base.type.."_"
		modList[basePrefix.."armourBase"] = m_floor(((item.base.armour.armourBase or 0) + (modList.armourBase or 0)) * (1 + ((modList.armourInc or 0) + (modList.armourAndEvasionInc or 0) + (modList.armourAndEnergyShieldInc or 0) + (modList.defencesInc or 0) + item.quality) / 100) + 0.5)
		modList[basePrefix.."evasionBase"] = m_floor(((item.base.armour.evasionBase or 0) + (modList.evasionBase or 0)) * (1 + ((modList.evasionInc or 0) + (modList.armourAndEvasionInc or 0) + (modList.evasionAndEnergyShieldInc or 0) + (modList.defencesInc or 0) + item.quality) / 100) + 0.5)
		modList[basePrefix.."energyShieldBase"] = m_floor(((item.base.armour.energyShieldBase or 0) + (modList.energyShieldBase or 0)) * (1 + ((modList.energyShieldInc or 0) + (modList.armourAndEnergyShieldInc or 0) + (modList.evasionAndEnergyShieldInc or 0) + (modList.defencesInc or 0) + item.quality) / 100) + 0.5)
		if item.base.armour.blockChance then
			if modList.shieldLocal_noBlock then
				modList.blockChance = 0
			else
				modList.blockChance = item.base.armour.blockChance + (modList.blockChance or 0)
			end
		end
		modList.armourBase = nil
		modList.armourInc = nil
		modList.evasionBase = nil
		modList.evasionInc = nil
		modList.energyShieldBase = nil
		modList.energyShieldInc = nil
		modList.armourAndEvasionInc = nil
		modList.armourAndEnergyShieldInc = nil
		modList.evasionAndEnergyShieldInc = nil
		modList.defencesInc = nil
	elseif item.type == "Jewel" then
		item.jewelFunc = modList.jewelFunc
		modList.jewelFunc = nil
	end	
	return modList
end

-- Build lists of modifiers for each slot an item can occupy
function itemLib.buildItemModList(item)
	if not item.base then
		return
	end
	local baseList = { }
	item.rangeLineList = { }
	for _, modLine in ipairs(item.modLines) do
		if not modLine.extra and (not modLine.variantList or modLine.variantList[item.variant]) then
			if modLine.range then
				local line = itemLib.applyRange(modLine.line, modLine.range)
				local list, extra = modLib.parseMod(line)
				if list and not extra then
					modLine.mods = list
					t_insert(item.rangeLineList, modLine)
				end
			end
			for k, v in pairs(modLine.mods) do
				modLib.listMerge(baseList, k, v)
			end
		end
	end
	item.baseModList = baseList
	if item.base.weapon or item.type == "Ring" then
		item.slotModList = { }
		for i = 1, 2 do
			item.slotModList[i] = itemLib.buildItemModListForSlotNum(item, baseList, i)
		end
	else
		item.modList = itemLib.buildItemModListForSlotNum(item, baseList)
	end
end

