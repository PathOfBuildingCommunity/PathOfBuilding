-- Path of Building
--
-- Module: Item Tools
-- Various functions for dealing with items
--

local m_min = math.min
local m_floor = math.floor
local t_insert = table.insert

itemLib = { }

-- Apply range value (0 to 1) to a modifier that has a range: (x to x) or (x-x to x-x)
function itemLib.applyRange(line, range)
	return line:gsub("%((%d+)%-(%d+) to (%d+)%-(%d+)%)", 
		function(minMin, maxMin, minMax, maxMax) 
			return string.format("%d-%d", m_floor(tonumber(minMin) + range * (tonumber(minMax) - tonumber(minMin)) + 0.5), m_floor(tonumber(maxMin) + range * (tonumber(maxMax) - tonumber(maxMin)) + 0.5)) 
		end)
		:gsub("(+?)%((%-?%d+) to (%-?%d+)%)", 
		function(plus, min, max) 
			local numVal = m_floor(tonumber(min) + range * (tonumber(max) - tonumber(min)) + 0.5)
			if numVal < 0 then
				if plus == "+" then
					plus = ""
				end
			end
			return plus .. tostring(numVal) 
		end)
		:gsub("%-(%d+%%) increased", function(num) return num.." reduced" end)
end

-- Make an item from raw data
function itemLib.makeItemFromRaw(raw)
	local newItem = {
		raw = raw:gsub("^%s+",""):gsub("%s+$",""):gsub("\r\n","\n"):gsub("%b<>",""):gsub("–","-"):gsub("\226\128\147","-"):gsub("\226\136\146","-"):gsub("ö","o"):gsub("\195\182","o")
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
		elseif data.weaponTypeInfo[line] then
			item.weaponType = line
		else
			local specName, specVal = line:match("^(%a+): %+?([%d%-%.]+)")
			if not specName then
				specName, specVal = line:match("^(%a+): (.+)")
			end
			if specName then
				if specName == "Radius" and item.type == "Jewel" then
					for index, data in pairs(data.jewelRadius) do
						if specVal == data.label then
							item.jewelRadiusIndex = index
							break
						end
					end
				elseif specName == "Quality" then
					item.quality = tonumber(specVal)
				elseif specName == "Variant" then
					if not item.variantList then
						item.variantList = { }
					end
					t_insert(item.variantList, specVal)
				elseif specName == "League" then
					item.league = specVal
				elseif specName == "Implicits" then
					item.implicitLines = tonumber(specVal)
				end
			else
				local varSpec = line:match("^{variant:([%d,]+)}")
				local variantList
				if varSpec then
					variantList = { }
					for varId in varSpec:gmatch("%d+") do
						variantList[tonumber(varId)] = true
					end
				end
				line = line:gsub("%b{}", "")
				local rangedLine
				if line:match("%(%d+%-%d+ to %d+%-%d+%)") or line:match("%(%-?%d+ to %-?%d+%)") then
					rangedLine = itemLib.applyRange(line, 1)
				end
				local modList, extra = modLib.parseMod(rangedLine or line)
				if modList then
					t_insert(item.modLines, { line = line, extra = extra, mods = modList, variantList = variantList, range = rangedLine and 0.5 })
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
						t_insert(item.modLines, { line = line, extra = line, mods = { }, variantList = variantList })
					elseif gameModeStage == "FINDEXPLICIT" then
						gameModeStage = "DONE"
					end
				elseif foundExplicit then
					t_insert(item.modLines, { line = line, extra = line, mods = { }, variantList = variantList })
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
	if not item.corrupted then
		item.quality = 20
	end
	if item.variantList then
		item.variant = m_min(#item.variantList, item.variant or #item.variantList)
	end
	itemLib.buildItemModList(item)
end

-- Build list of modifiers for an item while applying local modifers and adding quality
function itemLib.buildItemModList(item)
	if not item.base then
		return
	end
	local modList = { }
	item.modList = modList
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
				modLib.listMerge(modList, k, v)
			end
		end
	end
	if item.base.weapon then
		modList.weaponX_type = item.base.type
		modList.weaponX_name = item.name
		for _, dmgType in pairs({"physical","lightning","cold","fire","chaos"}) do
			local min = (item.base.weapon[dmgType.."Min"] or 0) + (modList["attack_"..dmgType.."Min"] or 0)
			local max = (item.base.weapon[dmgType.."Max"] or 0) + (modList["attack_"..dmgType.."Max"] or 0)
			if dmgType == "physical" then
				if modList.weaponNoPhysical then
					min, max = 0, 0
				else
					min = m_floor(min * (1 + ((modList["physicalInc"] or 0) + item.quality) / 100) + 0.5)
					max = m_floor(max * (1 + ((modList["physicalInc"] or 0) + item.quality) / 100) + 0.5)
				end
				modList["physicalInc"] = nil
			end
			if min > 0 and max > 0 then
				modList["weaponX_"..dmgType.."Min"] = min
				modList["weaponX_"..dmgType.."Max"] = max
			end
			modList["attack_"..dmgType.."Min"] = nil
			modList["attack_"..dmgType.."Max"] = nil
		end
		modList.weaponX_attackRate = m_floor(item.base.weapon.attackRateBase * (1 + (modList.attackSpeedInc or 0) / 100) * 100 + 0.5) / 100
		modList.weaponX_attackSpeedInc = modList.attackSpeedInc
		modList.attackSpeedInc = nil
		if modList.weaponAlwaysCrit then
			modList.weaponX_critChanceBase = 100
		else
			modList.weaponX_critChanceBase = m_floor(item.base.weapon.critChanceBase * (1 + (modList.critChanceInc or 0) / 100) * 100 + 0.5) / 100
		end
		modList.critChanceInc = nil
	elseif item.base.armour then
		if item.base.type == "Shield" then
			modList.weaponX_type = "Shield"
		end
		if item.base.armour.armourBase then
			modList.armourBase = m_floor((item.base.armour.armourBase + (modList.armourBase or 0)) * (1 + ((modList.armourInc or 0) + (modList.armourAndEvasionInc or 0) + (modList.armourAndEnergyShieldInc or 0) + (modList.defencesInc or 0) + item.quality) / 100) + 0.5)
		end
		if item.base.armour.evasionBase then
			modList.evasionBase = m_floor((item.base.armour.evasionBase + (modList.evasionBase or 0)) * (1 + ((modList.evasionInc or 0) + (modList.armourAndEvasionInc or 0) + (modList.evasionAndEnergyShieldInc or 0) + (modList.defencesInc or 0) + item.quality) / 100) + 0.5)
		end
		if item.base.armour.energyShieldBase then
			modList.energyShieldBase = m_floor((item.base.armour.energyShieldBase + (modList.energyShieldBase or 0)) * (1 + ((modList.energyShieldInc or 0) + (modList.armourAndEnergyShieldInc or 0) + (modList.evasionAndEnergyShieldInc or 0) + (modList.defencesInc or 0) + item.quality) / 100) + 0.5)
		end
		if item.base.armour.blockChance then
			if modList.shieldNoBlock then
				modList.blockChance = 0
			else
				modList.blockChance = item.base.armour.blockChance + (modList.blockChance or 0)
			end
		end
		modList.armourInc = nil
		modList.evasionInc = nil
		modList.energyShieldInc = nil
		modList.armourAndEvasionInc = nil
		modList.armourAndEnergyShieldInc = nil
		modList.evasionAndEnergyShieldInc = nil
		modList.defencesInc = nil
	elseif item.type == "Jewel" then
		item.jewelFunc = modList.jewelFunc
		modList.jewelFunc = nil
	end
end

