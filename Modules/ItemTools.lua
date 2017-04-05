-- Path of Building
--
-- Module: Item Tools
-- Various functions for dealing with items.
--

local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_floor = math.floor

local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}

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
	item.quality = nil
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
			if data.colorCodes[rarity:upper()] then
				item.rarity = rarity:upper()
			end
			if item.rarity == "NORMAL" then
				-- Hack for relics
				for _, line in ipairs(item.rawLines) do
					if line == "Relic Unique" then
						item.rarity = "RELIC"
						break
					end
				end
			end
			l = l + 1
		end
	end
	if item.rawLines[l] then
		item.name = item.rawLines[l]
		l = l + 1
	end
	item.namePrefix = ""
	item.nameSuffix = ""
	if item.rarity == "NORMAL" or item.rarity == "MAGIC" then
		for baseName, baseData in pairs(data.itemBases) do
			local s, e = item.name:find(baseName, 1, true)
			if s then
				item.baseName = baseName
				item.namePrefix = item.name:sub(1, s - 1)
				item.nameSuffix = item.name:sub(e + 1)
				item.type = baseData.type
				break
			end
		end
		if not item.baseName then
			local s, e = item.name:find("Two-Toned Boots", 1, true)
			if s then
				-- Hack for Two-Toned Boots
				item.baseName = "Two-Toned Boots (Armour/Energy Shield)"
				item.namePrefix = item.name:sub(1, s - 1)
				item.nameSuffix = item.name:sub(e + 1)
				item.type = "Boots"
			end
		end
		item.name = item.name:gsub(" %(.+%)","")
	elseif item.rawLines[l] and not item.rawLines[l]:match("^%-") then
		if item.rawLines[l] == "Two-Toned Boots" then
			item.rawLines[l] = "Two-Toned Boots (Armour/Energy Shield)"
		end
		if data.itemBases[item.rawLines[l]] then
			item.baseName = item.rawLines[l]
			item.title = item.name
			item.name = item.title .. ", " .. item.baseName:gsub(" %(.+%)","")
			item.type = data.itemBases[item.baseName].type
			l = l + 1
		end
	end
	item.base = data.itemBases[item.baseName]
	item.modLines = { }
	item.implicitLines = 0
	item.buffLines = 0
	item.affixes = data.itemMods[item.base and item.base.type]
	item.enchantments = data.enchantments[item.base and item.base.type]
	item.prefixes = { }
	item.suffixes = { }
	local flaskBuffLines = { }
	if item.base and item.base.flask and item.base.flask.buff then
		item.buffLines = #item.base.flask.buff
		for _, line in ipairs(item.base.flask.buff) do
			flaskBuffLines[line] = true
			local modList, extra = modLib.parseMod(line)
			t_insert(item.modLines, { line = line, extra = extra, modList = modList or { }, buff = true })
		end
	end
	local gameModeStage = "FINDIMPLICIT"
	local gameModeSection = 1
	local foundExplicit
	while item.rawLines[l] do
		local line = item.rawLines[l]
		if flaskBuffLines[line] then
			flaskBuffLines[line] = nil
		elseif line == "--------" then
			gameModeSection = gameModeSection + 1
			if gameModeStage == "IMPLICIT" then
				item.implicitLines = #item.modLines - item.buffLines
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
				elseif specName == "Crafted" then
					item.crafted = true
				elseif specName == "Prefix" then
					t_insert(item.prefixes, specVal)
				elseif specName == "Suffix" then
					t_insert(item.suffixes, specVal)
				elseif specName == "Implicits" then
					item.implicitLines = tonumber(specVal)
					gameModeStage = "EXPLICIT"
				elseif specName == "Unreleased" then
					item.unreleased = (specVal == "true")
				elseif specName == "Evasion Rating" then
					if item.baseName == "Two-Toned Boots (Armour/Energy Shield)" then
						-- Another hack for Two-Toned Boots
						item.baseName = "Two-Toned Boots (Armour/Evasion)"
						item.base = data.itemBases[item.baseName]
					end
				elseif specName == "Energy Shield" then
					if item.baseName == "Two-Toned Boots (Armour/Evasion)" then
						-- Yet another hack for Two-Toned Boots
						item.baseName = "Two-Toned Boots (Evasion/Energy Shield)"
						item.base = data.itemBases[item.baseName]
					end
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
				if (not modList or extra) and item.rawLines[l+1] then
					-- Try to combine it with the next line
					modList, extra = modLib.parseMod(line.." "..item.rawLines[l+1])
					if modList and not extra then
						line = line.."\n"..item.rawLines[l+1]
						l = l + 1
					else
						modList, extra = modLib.parseMod(rangedLine or line)
					end
				end
				if modList then
					t_insert(item.modLines, { line = line, extra = extra, modList = modList, variantList = variantList, crafted = crafted, range = rangedLine and (tonumber(rangeSpec) or 0.5) })
					if mode == "GAME" then
						if gameModeStage == "FINDIMPLICIT" then
							gameModeStage = "IMPLICIT"
						elseif gameModeStage == "FINDEXPLICIT" then
							foundExplicit = true
							gameModeStage = "EXPLICIT"
						elseif gameModeStage == "EXPLICIT" then
							foundExplicit = true
						end
					else
						foundExplicit = true
					end
				elseif mode == "GAME" then
					if gameModeStage == "IMPLICIT" or gameModeStage == "EXPLICIT" then
						t_insert(item.modLines, { line = line, extra = line, modList = { }, variantList = variantList, crafted = crafted })
					elseif gameModeStage == "FINDEXPLICIT" then
						gameModeStage = "DONE"
					end
				elseif foundExplicit then
					t_insert(item.modLines, { line = line, extra = line, modList = { }, variantList = variantList, crafted = crafted })
				end
			end
		end
		l = l + 1
	end
	if item.base and item.base.implicit then
		if item.implicitLines == 0 then
			item.implicitLines = 1 + #item.base.implicit:gsub("[^\n]","")
		end
	elseif mode == "GAME" and not foundExplicit then
		item.implicitLines = 0
	end
	item.affixLimit = 0
	if item.crafted and item.affixes then
		if item.rarity == "MAGIC" then
			item.affixLimit = 2
		elseif item.rarity == "RARE" then
			item.affixLimit = (item.base.type == "Jewel" and 4 or 6)
		end
	end
	if item.variantList then
		item.variant = m_min(#item.variantList, item.variant or #item.variantList)
	end
	if not item.quality then
		itemLib.normaliseQuality(item)
	end
	itemLib.buildItemModList(item)
end

function itemLib.normaliseQuality(item)
	if item.base and (item.base.armour or item.base.weapon or item.base.flask) then
		if not item.quality then
			item.quality = item.corrupted and 0 or 20 
		elseif not item.uniqueID and not item.corrupted then
			item.quality = 20
		end
	end	
end

-- Create raw item data for given item
function itemLib.createItemRaw(item)
	local rawLines = { }
	t_insert(rawLines, "Rarity: "..item.rarity)
	if item.title then
		t_insert(rawLines, item.title)
		t_insert(rawLines, item.baseName)
	else
		t_insert(rawLines, (item.namePrefix or "")..item.baseName..(item.nameSuffix or ""))
	end
	if item.uniqueID then
		t_insert(rawLines, "Unique ID: "..item.uniqueID)
	end
	if item.league then
		t_insert(rawLines, "League: "..item.league)
	end
	if item.unreleased then
		t_insert(rawLines, "Unreleased: true")
	end
	if item.crafted then
		t_insert(rawLines, "Crafted: true")
		for _, name in ipairs(item.prefixes or { }) do
			t_insert(rawLines, "Prefix: "..name)
		end
		for _, name in ipairs(item.suffixes or { }) do
			t_insert(rawLines, "Suffix: "..name)
		end
	end
	if item.itemLevel then
		t_insert(rawLines, "Item Level: "..item.itemLevel)
	end
	if item.variantList then
		for _, variantName in ipairs(item.variantList) do
			t_insert(rawLines, "Variant: "..variantName)
		end
		t_insert(rawLines, "Selected Variant: "..item.variant)
	end
	if item.quality then
		t_insert(rawLines, "Quality: "..item.quality)
	end
	if item.sockets then
		local line = "Sockets: "
		for i, socket in pairs(item.sockets) do
			line = line .. socket.color
			if item.sockets[i+1] then
				line = line .. (socket.group == item.sockets[i+1].group and "-" or " ")
			end
		end
		t_insert(rawLines, line)
	end
	if item.jewelRadiusIndex then
		t_insert(rawLines, "Radius: "..data.jewelRadius[item.jewelRadiusIndex].label)
	end
	if item.limit then
		t_insert(rawLines, "Limited to: "..item.limit)
	end
	t_insert(rawLines, "Implicits: "..item.implicitLines)
	for _, modLine in ipairs(item.modLines) do
		if not modLine.buff then
			local line = modLine.line
			if modLine.range then
				line = "{range:"..round(modLine.range,2).."}" .. line
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
			t_insert(rawLines, line)
		end
	end
	if item.corrupted then
		t_insert(rawLines, "Corrupted")
	end
	return table.concat(rawLines, "\n")
end

-- Rebuild explicit modifiers using the item's affixes
function itemLib.craftItem(item)
	local ranges = { }
	for l = item.buffLines + item.implicitLines + 1, #item.modLines do
		ranges[item.modLines[l].line] = item.modLines[l].range
		item.modLines[l] = nil
	end
	item.namePrefix = ""
	item.nameSuffix = ""
	for _, list in ipairs({item.prefixes,item.suffixes}) do
		for i = 1, item.affixLimit/2 do
			local name = list[i]
			if not name then
				list[i] = "None"
			end
			local mod = item.affixes[name]
			if mod then
				if mod.type == "Prefix" then
					item.namePrefix = name .. " "
				elseif mod.type == "Suffix" then
					item.nameSuffix = " " .. name
				end
				for _, line in ipairs(mod) do
					t_insert(item.modLines, { line = line, range = ranges[line] })
				end
			end
		end
	end
	if item.rarity == "MAGIC" then
		item.name = newName
	end
	item.raw = itemLib.createItemRaw(item)
	itemLib.parseItemRaw(item)
end

-- Return the name of the slot this item is equipped in
function itemLib.getPrimarySlotForItem(item)
	if item.base.weapon then
		return "Weapon 1"
	elseif item.type == "Quiver" or item.type == "Shield" then
		return "Weapon 2"
	elseif item.type == "Ring" then
		return "Ring 1"
	elseif item.type == "Flask" then
		return "Flask 1"
	else
		return item.type
	end
end

-- Add up local modifiers, and removes them from the modifier list
-- To be considered local, a modifier must be an exact flag match, and cannot have any tags (e.g conditions, multipliers)
-- Only the InSlot tag is allowed (for Adds x to x X Damage in X Hand modifiers)
local function sumLocal(modList, name, type, flags)
	local result = 0
	local i = 1
	while modList[i] do
		local mod = modList[i]
		if mod.name == name and mod.type == type and mod.flags == flags and mod.keywordFlags == 0 and (not mod.tagList[1] or mod.tagList[1].type == "InSlot") then
			result = result + mod.value
			t_remove(modList, i)
		else
			i = i + 1
		end
	end
	return result
end

-- Build list of modifiers for an item in a given slot number (1 or 2) while applying local modifers and adding quality
function itemLib.buildItemModListForSlotNum(item, baseList, slotNum)
	local slotName = itemLib.getPrimarySlotForItem(item)
	if slotNum == 2 then
		slotName = slotName:gsub("1", "2")
	end
	local modList = common.New("ModList")
	for _, baseMod in ipairs(baseList) do
		local mod = copyTable(baseMod)
		local add = true
		for _, tag in pairs(mod.tagList) do
			if tag.type == "SlotNumber" or tag.type == "InSlot" then
				if tag.num ~= slotNum then
					add = false
					break
				end
			elseif tag.type == "SocketedIn" then
				tag.slotName = slotName
			elseif tag.type == "Condition" and tag.var == "XHandAttack" then
				tag.var = (slotNum == 1) and "MainHandAttack" or "OffHandAttack"
			end
		end
		if add then
			mod.sourceSlot = slotName
			modList:AddMod(mod)
		end
	end
	if item.base.weapon then
		local weaponData = { }
		item.weaponData[slotNum] = weaponData
		weaponData.type = item.base.type
		weaponData.name = item.name
		weaponData.AttackSpeedInc = sumLocal(modList, "Speed", "INC", ModFlag.Attack)
		weaponData.attackRate = round(item.base.weapon.attackRateBase * (1 + weaponData.AttackSpeedInc / 100), 2)
		for _, dmgType in pairs(dmgTypeList) do
			local min = (item.base.weapon[dmgType.."Min"] or 0) + sumLocal(modList, dmgType.."Min", "BASE", 0)
			local max = (item.base.weapon[dmgType.."Max"] or 0) + sumLocal(modList, dmgType.."Max", "BASE", 0)
			if dmgType == "Physical" then
				local physInc = sumLocal(modList, "PhysicalDamage", "INC", 0)
				min = round(min * (1 + (physInc + item.quality) / 100))
				max = round(max * (1 + (physInc + item.quality) / 100))
			end
			if min > 0 and max > 0 then
				weaponData[dmgType.."Min"] = min
				weaponData[dmgType.."Max"] = max
				local dps = (min + max) / 2 * weaponData.attackRate
				weaponData[dmgType.."DPS"] = dps
				if dmgType ~= "Physical" and dmgType ~= "Chaos" then
					weaponData.ElementalDPS = (weaponData.ElementalDPS or 0) + dps
				end
			end
		end
		weaponData.critChance = round(item.base.weapon.critChanceBase * (1 + sumLocal(modList, "CritChance", "INC", 0) / 100), 2)
		for _, value in ipairs(modList:Sum("LIST", nil, "Misc")) do
			if value.type == "WeaponData" then
				weaponData[value.key] = value.value
			end
		end
		weaponData.AccuracyInc = sumLocal(modList, "Accuracy", "INC", 0)
		if weaponData.AccuracyInc > 0 then
			modList:NewMod("Accuracy", "MORE", weaponData.AccuracyInc, item.modSource, { type = "Condition", var = (slotNum == 1) and "MainHandAttack" or "OffHandAttack" })
		end
		for _, mod in ipairs(modList) do
			-- Convert accuracy, L/MGoH and PAD Leech modifiers to local
			if (
				(mod.name == "Accuracy" and mod.flags == 0) or
				((mod.name == "LifeOnHit" or mod.name == "ManaOnHit") and mod.flags == ModFlag.Attack) or
				((mod.name == "PhysicalDamageLifeLeech" or mod.name == "PhysicalDamageManaLeech") and mod.flags == ModFlag.Attack) 
			   ) and mod.keywordFlags == 0 and not mod.tagList[1] then
				mod.tagList[1] = { type = "Condition", var = (slotNum == 1) and "MainHandAttack" or "OffHandAttack" }
			end
		end
		weaponData.TotalDPS = 0
		for _, dmgType in pairs(dmgTypeList) do
			weaponData.TotalDPS = weaponData.TotalDPS + (weaponData[dmgType.."DPS"] or 0)
		end
	elseif item.base.armour then
		local armourData = item.armourData
		local armourBase = sumLocal(modList, "Armour", "BASE", 0) + (item.base.armour.armourBase or 0)
		local evasionBase = sumLocal(modList, "Evasion", "BASE", 0) + (item.base.armour.evasionBase or 0)
		local energyShieldBase = sumLocal(modList, "EnergyShield", "BASE", 0) + (item.base.armour.energyShieldBase or 0)
		local armourInc = sumLocal(modList, "Armour", "INC", 0)
		local armourEvasionInc = sumLocal(modList, "ArmourAndEvasion", "INC", 0)
		local evasionInc = sumLocal(modList, "Evasion", "INC", 0)
		local evasionEnergyShieldInc = sumLocal(modList, "EvasionAndEnergyShield", "INC", 0)
		local energyShieldInc = sumLocal(modList, "EnergyShield", "INC", 0)
		local armourEnergyShieldInc = sumLocal(modList, "ArmourAndEnergyShield", "INC", 0)
		local defencesInc = sumLocal(modList, "Defences", "INC", 0)
		armourData.Armour = round(armourBase * (1 + (armourInc + armourEvasionInc + armourEnergyShieldInc + defencesInc + item.quality) / 100))
		armourData.Evasion = round(evasionBase * (1 + (evasionInc + armourEvasionInc + evasionEnergyShieldInc + defencesInc + item.quality) / 100))
		armourData.EnergyShield = round(energyShieldBase * (1 + (energyShieldInc + armourEnergyShieldInc + evasionEnergyShieldInc + defencesInc + item.quality) / 100))
		if item.base.armour.blockChance then
			armourData.BlockChance = item.base.armour.blockChance + sumLocal(modList, "BlockChance", "BASE", 0)
		end
		if item.base.armour.movementPenalty then
			modList:NewMod("MovementSpeed", "INC", -item.base.armour.movementPenalty, item.modSource, { type = "Condition", var = "IgnoreMovementPenalties", neg = true })
		end
		for _, value in ipairs(modList:Sum("LIST", nil, "Misc")) do
			if value.type == "ArmourData" then
				armourData[value.key] = value.value
			end
		end
	elseif item.base.flask then
		local flaskData = item.flaskData
		local durationInc = sumLocal(modList, "Duration", "INC", 0)
		if item.base.flask.life or item.base.flask.mana then
			-- Recovery flask
			flaskData.instantPerc = sumLocal(modList, "FlaskInstantRecovery", "BASE", 0)
			local recoveryMod = 1 + sumLocal(modList, "FlaskRecovery", "INC", 0) / 100
			local rateMod = 1 + sumLocal(modList, "FlaskRecoveryRate", "INC", 0) / 100
			flaskData.duration = item.base.flask.duration * (1 + durationInc / 100) / rateMod
			if item.base.flask.life then
				flaskData.lifeBase = item.base.flask.life * (1 + item.quality / 100) * recoveryMod
				flaskData.lifeInstant = flaskData.lifeBase * flaskData.instantPerc / 100
				flaskData.lifeGradual = flaskData.lifeBase * (1 - flaskData.instantPerc / 100) * (1 + durationInc / 100)
				flaskData.lifeTotal = flaskData.lifeInstant + flaskData.lifeGradual
			end
			if item.base.flask.mana then
				flaskData.manaBase = item.base.flask.mana * (1 + item.quality / 100) * recoveryMod
				flaskData.manaInstant = flaskData.manaBase * flaskData.instantPerc / 100
				flaskData.manaGradual = flaskData.manaBase * (1 - flaskData.instantPerc / 100) * (1 + durationInc / 100)
				flaskData.manaTotal = flaskData.manaInstant + flaskData.manaGradual
			end
		else
			-- Utility flask
			flaskData.duration = item.base.flask.duration * (1 + (durationInc + item.quality) / 100)
		end
		flaskData.chargesMax = item.base.flask.chargesMax + sumLocal(modList, "FlaskCharges", "BASE", 0)
		flaskData.chargesUsed = m_floor(item.base.flask.chargesUsed * (1 + sumLocal(modList, "FlaskChargesUsed", "INC", 0) / 100))
		flaskData.gainMod = 1 + sumLocal(modList, "FlaskChargeRecovery", "INC", 0) / 100
		flaskData.effectInc = sumLocal(modList, "FlaskEffect", "INC", 0)
		for _, value in ipairs(modList:Sum("LIST", nil, "Misc")) do
			if value.type == "FlaskData" then
				flaskData[value.key] = value.value
			end
		end
	elseif item.type == "Jewel" then
		local jewelData = item.jewelData
		for _, value in ipairs(modList:Sum("LIST", nil, "Misc")) do
			if value.type == "JewelFunc" then
				jewelData.funcList = jewelData.funcList or { }
				t_insert(jewelData.funcList, value.func)
			elseif value.type == "JewelData" then
				jewelData[value.key] = value.value
			end
		end
	end	
	return { unpack(modList) }
end

-- Build lists of modifiers for each slot an item can occupy
function itemLib.buildItemModList(item)
	if not item.base then
		return
	end
	local baseList = { }
	if item.base.weapon then
		item.weaponData = { }
	elseif item.base.armour then
		item.armourData = { }
	elseif item.base.flask then
		item.flaskData = { }
		item.buffModList = { }
	elseif item.type == "Jewel" then
		item.jewelData = { }
	end
	item.baseModList = baseList
	item.rangeLineList = { }
	item.modSource = "Item:"..(item.id or -1)..":"..item.name
	for _, modLine in ipairs(item.modLines) do
		if not modLine.extra and (not modLine.variantList or modLine.variantList[item.variant]) then
			if modLine.range then
				local line = itemLib.applyRange(modLine.line, modLine.range)
				local list, extra = modLib.parseMod(line)
				if list and not extra then
					modLine.modList = list
					t_insert(item.rangeLineList, modLine)
				end
			end
			for _, mod in ipairs(modLine.modList) do
				mod.source = item.modSource
				if type(mod.value) == "table" and mod.value.mod then
					mod.value.mod.source = mod.source
				end
				if modLine.buff then
					t_insert(item.buffModList, mod)
				else
					t_insert(baseList, mod)
				end
			end
		end
	end
	if item.name == "Tabula Rasa, Simple Robe" or item.name == "Skin of the Loyal, Simple Robe" or item.name == "Skin of the Lords, Simple Robe" then
		-- Hack to remove the energy shield
		t_insert(baseList, { name = "Misc", type = "LIST", value = { type = "ArmourData", key = "EnergyShield" }, flags = 0, keywordFlags = 0, tagList = { } })
	end
	if item.base.weapon or item.type == "Ring" then
		item.slotModList = { }
		for i = 1, 2 do
			item.slotModList[i] = itemLib.buildItemModListForSlotNum(item, baseList, i)
		end
	else
		item.modList = itemLib.buildItemModListForSlotNum(item, baseList)
	end
end

