-- Path of Building
--
-- Class: Item
-- Equippable item class
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}
local catalystList = {"Abrasive", "Accelerating", "Fertile", "Imbued", "Intrinsic", "Noxious", "Prismatic", "Tempering", "Turbulent", "Unstable"}
local catalystTags = {
	{ "attack" },
	{ "speed" },
	{ "life", "mana", "resource" },
	{ "caster" },
	{ "jewellery_attribute", "attribute" },
	{ "physical_damage", "chaos_damage" },
	{ "jewellery_resistance", "resistance" },
	{ "jewellery_defense", "defences" },
	{ "jewellery_elemental" ,"elemental_damage" },
	{ "critical" },
}

local function getCatalystScalar(catalystId, tags, quality)
	if not catalystId or type(catalystId) ~= "number" or not catalystTags[catalystId] or not tags or type(tags) ~= "table" or #tags == 0 then
		return 1
	end
	if not quality then
		quality = 20
	end

	-- Create a fast lookup table for all provided tags
	local tagLookup = {}
	for _, curTag in ipairs(tags) do
		tagLookup[curTag] = true;
	end

	-- Find if any of the catalyst's tags match the provided tags
	for _, catalystTag in ipairs(catalystTags[catalystId]) do
		if tagLookup[catalystTag] then
			return (100 + quality) / 100
		end
	end
	return 1
end

local influenceInfo = itemLib.influenceInfo

local ItemClass = newClass("Item", function(self, raw, rarity, highQuality)
	if raw then
		self:ParseRaw(sanitiseText(raw), rarity, highQuality)
	end	
end)

-- Reset all influence keys to false
function ItemClass:ResetInfluence()
	for _, curInfluenceInfo in ipairs(influenceInfo) do
		self[curInfluenceInfo.key] = false
	end
end

local influenceItemMap = { }
for _, curInfluenceInfo in ipairs(influenceInfo) do
	influenceItemMap[curInfluenceInfo.display.." Item"] = curInfluenceInfo.key
end

local lineFlags = {
	["crafted"] = true, ["crucible"] = true, ["custom"] = true, ["eater"] = true, ["enchant"] = true,
	["exarch"] = true, ["fractured"] = true, ["implicit"] = true, ["scourge"] = true, ["synthesis"] = true,
}

-- Special function to store unique instances of modifier on specific item slots
-- that require special handling for ItemConditions. Only called if line #224 is
-- uncommented
local specialModifierFoundList = {}
local inverseModifierFoundList = {}
local function getTagBasedModifiers(tagName, itemSlotName)
	local tag_name = tagName:lower()
	local slot_name = itemSlotName:lower():gsub(" ", "_")
	-- iterate all the item modifiers
	for k,v in pairs(data.itemMods.Item) do
		-- iterate across the modifier tags for each modifier
		for _,tag in ipairs(v.modTags) do
			-- if tag matches the tag_name we are investigating
			if tag:lower() == tag_name then
				local found = false
				-- if there is a valid weightKey table
				if #v.weightKey > 0 then
					for _,wk in ipairs(v.weightKey) do
						-- and it matches the slot_name of the item we are investigating
						if wk == slot_name then
							for _, dv in ipairs(v) do
								-- and the modifier description contains the tag_name keyword
								if dv:lower():find(tag_name) then
									found = true
									break
								else
									local excluded = false
									if data.itemTagSpecial[tagName] and data.itemTagSpecial[tagName][itemSlotName] then
										for _, specialMod in ipairs(data.itemTagSpecial[tagName][itemSlotName]) do
											if dv:lower():find(specialMod:lower()) then
												exclude = true
												break
											end
										end
									end
									if exclude then
										found = true
										break
									end
								end
							end
							if not found and not specialModifierFoundList[k] then
								specialModifierFoundList[k] = true
								ConPrintf("[%s] [%s] ENTRY: %s", tagName, itemSlotName, k)
							end
						end
					end
				else
					for _, dv in ipairs(v) do
						if dv:lower():find(tag_name) then
							found = true
							break
						else
							local excluded = false
							if data.itemTagSpecial[tagName] and data.itemTagSpecial[tagName][itemSlotName] then
								for _, specialMod in ipairs(data.itemTagSpecial[tagName][itemSlotName]) do
									if dv:lower():find(specialMod:lower()) then
										exclude = true
										break
									end
								end
							end
							if exclude then
								found = true
								break
							end
						end
					end
					if not found and not specialModifierFoundList[k] then
						specialModifierFoundList[k] = true
						ConPrintf("[%s] ENTRY: %s", tagName, k)
					end
				end
			end
		end
		for _, dv in ipairs(v) do
			if dv:lower():find(tag_name) then
				local found_2 = false
				if #v.weightKey > 0 then
					for _,wk in ipairs(v.weightKey) do
						if wk == slot_name then
							-- this is useless if the modTags = { } (is empty)
							if #v.modTags > 0 then
								for _,tag in ipairs(v.modTags) do
									if tag:lower() == tag_name then
										found_2 = true
										break
									else
										local excluded = false
										-- if we have an exclusion pattern list for that tagName and itemSlotName
										if data.itemTagSpecialExclusionPattern[tagName] and data.itemTagSpecialExclusionPattern[tagName][itemSlotName] then
											-- iterate across the exclusion patterns
											for _, specialMod in ipairs(data.itemTagSpecialExclusionPattern[tagName][itemSlotName]) do
												-- and if the description matches pattern exclude it
												if dv:lower():find(specialMod:lower()) then
													excluded = true
													break
												end
											end
										end
										if excluded then
											found_2 = true
											break
										end
									end
								end
								if not found_2 and not inverseModifierFoundList[k] then
									inverseModifierFoundList[k] = true
									ConPrintf("[%s] appears in desc but not in tags. [%s] %s", tag_name, k, dv)
									break
								end
							end
						end
					end
				else
					-- this is useless if the modTags = { } (is empty)
					if #v.modTags > 0 then
						for _,tag in ipairs(v.modTags) do
							if tag:lower() == tag_name then
								found_2 = true
								break
							else
								local excluded = false
								-- if we have an exclusion pattern list for that tagName and itemSlotName
								if data.itemTagSpecialExclusionPattern[tagName] and data.itemTagSpecialExclusionPattern[tagName][itemSlotName] then
									-- iterate across the exclusion patterns
									for _, specialMod in ipairs(data.itemTagSpecialExclusionPattern[tagName][itemSlotName]) do
										-- and if the description matches pattern exclude it
										if dv:lower():find(specialMod:lower()) then
											excluded = true
											break
										end
									end
								end
								if excluded then
									found_2 = true
									break
								end
							end
						end
						if not found_2 and not inverseModifierFoundList[k] then
							inverseModifierFoundList[k] = true
							ConPrintf("[%s] appears in desc but not in tags. [%s] %s", tag_name, k, dv)
						end
					end
				end
			end
		end
	end
end

-- Iterate over modifiers to see if specific substring is found (for conditional checking)
function ItemClass:FindModifierSubstring(substring, itemSlotName)
	local modLines = {}
	local substring, explicit = substring:gsub("explicit ", "")

	-- The commented out line below is used at GGPK updates to check if any new modifiers
	-- have been identified that need to be added to the manually maintained special modifier
	-- pool in Data.lua (data.itemTagSpecial and data.itemTagSpecialExclusionPattern tables)
	--getTagBasedModifiers(substring, itemSlotName)

	-- merge various modifier lines into one table
	for _,v in pairs(self.explicitModLines) do t_insert(modLines, v) end
	if explicit < 1 then
		for _,v in pairs(self.enchantModLines) do t_insert(modLines, v) end
		for _,v in pairs(self.scourgeModLines) do t_insert(modLines, v) end
		for _,v in pairs(self.implicitModLines) do t_insert(modLines, v) end
		for _,v in pairs(self.crucibleModLines) do t_insert(modLines, v) end
	end

	for _,v in pairs(modLines) do
		local currentVariant = false
		if v.variantList then
			for variant, enabled in pairs(v.variantList) do
				if enabled and variant == self.variant then
					currentVariant = true
				end
			end
		else
			currentVariant = true
		end
		if currentVariant then
			if v.line:lower():find(substring) and not v.line:lower():find(substring .. " modifier") then
				local excluded = false
				if data.itemTagSpecialExclusionPattern[substring] and data.itemTagSpecialExclusionPattern[substring][itemSlotName] then
					for _, specialMod in ipairs(data.itemTagSpecialExclusionPattern[substring][itemSlotName]) do
						if v.line:lower():find(specialMod:lower()) then
							excluded = true
							break
						end
					end
				end
				if not excluded then
					return true
				end
			end
			if data.itemTagSpecial[substring] and data.itemTagSpecial[substring][itemSlotName] then
				for _, specialMod in ipairs(data.itemTagSpecial[substring][itemSlotName]) do
					if v.line:lower():find(specialMod:lower()) and (not v.variantList or v.variantList[self.variant]) then
						return true
					end
				end
			end
		end
	end
	return false
end

local function specToNumber(s)
	local n = s:match("^([%+%-]?[%d%.]+)")
	return n and tonumber(n)
end

-- Parse raw item data and extract item name, base type, quality, and modifiers
function ItemClass:ParseRaw(raw, rarity, highQuality)
	self.raw = raw
	self.name = "?"
	self.namePrefix = ""
	self.nameSuffix = ""
	self.base = nil
	self.rarity = rarity or "UNIQUE"
	self.quality = nil
	self.rawLines = { }
	-- Find non-blank lines and trim whitespace
	for line in raw:gmatch("%s*([^\n]*%S)") do
	 	t_insert(self.rawLines, line)
	end
	local mode = rarity and "GAME" or "WIKI"
	local l = 1
	local itemClass
	if self.rawLines[l] then
		if self.rawLines[l]:match("^Item Class:") then
			itemClass = self.rawLines[l]:gsub("^Item Class: %s+", "%1")
			l = l + 1 -- Item class is already determined by the base type
		end
		local rarity = self.rawLines[l]:match("^Rarity: (%a+)")
		if rarity then
			mode = "GAME"
			if colorCodes[rarity:upper()] then
				self.rarity = rarity:upper()
			end
			if self.rarity == "UNIQUE" then
				-- Hack for relics
				for _, line in ipairs(self.rawLines) do
					if line:find("Foil Unique") then
						self.rarity = "RELIC"
						break
					end
				end
			end
			l = l + 1
		end
	end
	if self.rawLines[l] then
		self.name = self.rawLines[l]
		-- Determine if "Unidentified" item
		local unidentified = false
		for _, line in ipairs(self.rawLines) do
			if line == "Unidentified" then
				unidentified = true
				break
			end
		end

		-- Found the name for a rare or unique, but let's parse it if it's a magic or normal or Unidentified item to get the base
		if not (self.rarity == "NORMAL" or self.rarity == "MAGIC" or unidentified) then
			l = l + 1
		end
	end
	self.checkSection = false
	self.sockets = { }
	self.classRequirementModLines = { }
	self.buffModLines = { }
	self.enchantModLines = { }
	self.scourgeModLines = { }
	self.implicitModLines = { }
	self.explicitModLines = { }
	self.crucibleModLines = { }
	local implicitLines = 0
	self.variantList = nil
	self.prefixes = { }
	self.suffixes = { }
	self.requirements = { }
	self.requirements.str = 0
	self.requirements.dex = 0
	self.requirements.int = 0
	self.baseLines = { }
	local importedLevelReq
	local flaskBuffLines
	local deferJewelRadiusIndexAssignment
	local gameModeStage = "FINDIMPLICIT"
	local foundExplicit, foundImplicit

	while self.rawLines[l] do	
		local line = self.rawLines[l]
		if flaskBuffLines and flaskBuffLines[line] then
			flaskBuffLines[line] = nil
		elseif line == "--------" then
			self.checkSection = true
		elseif line == "Split" then
			self.split = true
		elseif line == "Mirrored" then
			self.mirrored = true
		elseif line == "Corrupted" then
			self.corrupted = true
		elseif line == "Fractured Item" then
			self.fractured = true
		elseif line == "Synthesised Item" then
			self.synthesised = true
		elseif influenceItemMap[line] then
			self[influenceItemMap[line]] = true
		elseif line == "Requirements:" then
			-- nothing to do
		else
			if self.checkSection then
				if gameModeStage == "IMPLICIT" then
					if foundImplicit then
						-- There were definitely implicits, so any following modifiers must be explicits
						gameModeStage = "EXPLICIT"
						foundExplicit = true
					else
						gameModeStage = "FINDEXPLICIT"
					end
				elseif gameModeStage == "EXPLICIT" then
					gameModeStage = "DONE"
				elseif gameModeStage == "FINDIMPLICIT" and self.itemLevel and not line:match(" %(implicit%)") and
						not line:match(" %(enchant%)") and not line:find("Talisman Tier") then
					gameModeStage = "EXPLICIT"
					foundExplicit = true
				end
				self.checkSection = false
			end
			local specName, specVal = line:match("^([%a ]+:?): (.+)$")
			if specName then
				if specName == "Class:" then
					specName = "Requires Class"
				end
			else
				specName, specVal = line:match("^(Requires %a+) (.+)$")
			end
			if specName then
				if specName == "Unique ID" then
					self.uniqueID = specVal
				elseif specName == "Item Level" then
					self.itemLevel = specToNumber(specVal)
				elseif specName == "Requires Class" then
					self.classRestriction = specVal
				elseif specName == "Quality" then
					self.quality = specToNumber(specVal)
				elseif specName == "Sockets" then
					local group = 0
					for c in specVal:gmatch(".") do
						if c:match("[RGBWA]") then
							t_insert(self.sockets, { color = c, group = group })
						elseif c == " " then
							group = group + 1
						end
					end
				elseif specName == "Radius" and self.type == "Jewel" then
					self.jewelRadiusLabel = specVal:match("^%a+")
					if specVal:match("^%a+") == "Variable" then
                        -- Jewel radius is variable and must be read from it's mods instead after they are parsed
                        deferJewelRadiusIndexAssignment = true
                    else
                        for index, data in pairs(data.jewelRadius) do
                            if specVal:match("^%a+") == data.label then
                                self.jewelRadiusIndex = index
                                break
                            end
						end
					end
				elseif specName == "Limited to" and self.type == "Jewel" then
					self.limit = specToNumber(specVal)
				elseif specName == "Variant" then
					if not self.variantList then
						self.variantList = { }
					end
					-- This has to be kept for backwards compatibility
					local ver, name = specVal:match("{([%w_]+)}(.+)")
					if ver then
						t_insert(self.variantList, name)
					else
						t_insert(self.variantList, specVal)
					end
				elseif specName == "Talisman Tier" then
					self.talismanTier = specToNumber(specVal)
				elseif specName == "Armour" or specName == "Evasion Rating" or specName == "Evasion" or specName == "Energy Shield" or specName == "Ward" then
					if specName == "Evasion Rating" then
						specName = "Evasion"
						if self.baseName == "Two-Toned Boots (Armour/Energy Shield)" then
							-- Another hack for Two-Toned Boots
							self.baseName = "Two-Toned Boots (Armour/Evasion)"
							self.base = data.itemBases[self.baseName]
						end
					elseif specName == "Energy Shield" then
						specName = "EnergyShield"
						if self.baseName == "Two-Toned Boots (Armour/Evasion)" then
							-- Yet another hack for Two-Toned Boots
							self.baseName = "Two-Toned Boots (Evasion/Energy Shield)"
							self.base = data.itemBases[self.baseName]
						end
					end
					self.armourData = self.armourData or { }
					self.armourData[specName] = specToNumber(specVal)
				elseif specName:match("BasePercentile") then
					self.armourData = self.armourData or { }
					self.armourData[specName] = specToNumber(specVal) or 0
				elseif specName == "Requires Level" then
					self.requirements.level = specToNumber(specVal)
				elseif specName == "Level" then
					-- Requirements from imported items can't always be trusted
					importedLevelReq = specToNumber(specVal)
				elseif specName == "LevelReq" then
					self.requirements.level = specToNumber(specVal)
				elseif specName == "Has Alt Variant" then
					self.hasAltVariant = true
				elseif specName == "Has Alt Variant Two" then
					self.hasAltVariant2 = true
				elseif specName == "Has Alt Variant Three" then
					self.hasAltVariant3 = true
				elseif specName == "Has Alt Variant Four" then
					self.hasAltVariant4 = true
				elseif specName == "Has Alt Variant Five" then
					self.hasAltVariant5 = true
				elseif specName == "Selected Variant" then
					self.variant = specToNumber(specVal)
				elseif specName == "Selected Alt Variant" then
					self.variantAlt = specToNumber(specVal)
				elseif specName == "Selected Alt Variant Two" then
					self.variantAlt2 = specToNumber(specVal)
				elseif specName == "Selected Alt Variant Three" then
					self.variantAlt3 = specToNumber(specVal)
				elseif specName == "Selected Alt Variant Four" then
					self.variantAlt4 = specToNumber(specVal)
				elseif specName == "Selected Alt Variant Five" then
					self.variantAlt5 = specToNumber(specVal)
				elseif specName == "Has Variants" or specName == "Selected Variants" then
					-- Need to skip this line for backwards compatibility
					-- with builds that used an old Watcher's Eye implementation
					l = l + 1
				elseif specName == "League" then
					self.league = specVal
				elseif specName == "Crafted" then
					self.crafted = true
				elseif specName == "Scourge" then
					self.scourge = true
				elseif specName == "Crucible" then
					self.crucible = true
				elseif specName == "Implicit" then
					self.implicit = true
				elseif specName == "Prefix" then
					local range, affix = specVal:match("{range:([%d.]+)}(.+)")
					range = range or ((affix or specVal) ~= "None" and main.defaultItemAffixQuality)
					t_insert(self.prefixes, {
						modId = affix or specVal,
						range = tonumber(range),
					})
				elseif specName == "Suffix" then
					local range, affix = specVal:match("{range:([%d.]+)}(.+)")
					range = range or ((affix or specVal) ~= "None" and main.defaultItemAffixQuality)
					t_insert(self.suffixes, {
						modId = affix or specVal,
						range = tonumber(range),
					})
				elseif specName == "Implicits" then
					implicitLines = specToNumber(specVal) or 0
					gameModeStage = "EXPLICIT"
				elseif specName == "Unreleased" then
					self.unreleased = (specVal == "true")
				elseif specName == "Upgrade" then
					self.upgradePaths = self.upgradePaths or { }
					t_insert(self.upgradePaths, specVal)
				elseif specName == "Source" then
					self.source = specVal
				elseif specName == "Cluster Jewel Skill" then
					if self.clusterJewel and self.clusterJewel.skills[specVal] then
						self.clusterJewelSkill = specVal
					end
				elseif specName == "Cluster Jewel Node Count" then
					if self.clusterJewel then
						local num = specToNumber(specVal) or self.clusterJewel.maxNodes
						self.clusterJewelNodeCount = m_min(m_max(num, self.clusterJewel.minNodes), self.clusterJewel.maxNodes)
					end
				elseif specName == "Catalyst" then
					for i=1, #catalystList do
						if specVal == catalystList[i] then
							self.catalyst = i
						end
					end
				elseif specName == "CatalystQuality" then
					self.catalystQuality = specToNumber(specVal)
				elseif specName == "Note" then
					self.note = specVal
				elseif specName == "Str" or specName == "Strength" or specName == "Dex" or specName == "Dexterity" or
				       specName == "Int" or specName == "Intelligence" then
					self.requirements[specName:sub(1,3):lower()] = specToNumber(specVal)
				elseif specName == "Critical Strike Range" or specName == "Attacks per Second" or specName == "Weapon Range" or
				       specName == "Critical Strike Chance" or specName == "Physical Damage" or specName == "Elemental Damage" or
				       specName == "Chaos Damage" or specName == "Chance to Block" or specName == "Armour" or
					   specName == "Energy Shield" or specName == "Evasion" then
					self.hidden_specs = true
				-- Anything else is an explicit with a colon in it (Fortress Covenant, Pure Talent, etc) unless it's part of the custom name
				elseif not (self.name:match(specName) and self.name:match(specVal)) then
					foundExplicit = true
					gameModeStage = "EXPLICIT"
				end
			end
			if line == "Prefixes:" then
				foundExplicit = true
				gameModeStage = "EXPLICIT"
			end
			if not specName or foundExplicit or foundImplicit then
				local modLine = { modTags = {} }

				line = line:gsub("{(%a*):?([^}]*)}", function(k,val)
					if k == "variant" then
						modLine.variantList = { }
						for varId in val:gmatch("%d+") do
							modLine.variantList[tonumber(varId)] = true
						end
					elseif k == "tags" then
						for tag in val:gmatch("[%a_]+") do
							t_insert(modLine.modTags, tag)
						end
					elseif k == "range" then
						modLine.range = tonumber(val)
					elseif lineFlags[k] then
						modLine[k] = true
					end

					return ""
				end)

				line = line:gsub(" %((%l+)%)", function(k)
					if lineFlags[k] then
						modLine[k] = true
					end
					return ""
				end)

				if modLine.enchant then
					modLine.crafted = true
					modLine.implicit = true
				end

				local baseName
				if not self.base and (self.rarity == "NORMAL" or self.rarity == "MAGIC") then
					-- Exact match (affix-less magic and normal items)
					if self.name:match("Energy Blade") and itemClass then -- Special handling for energy blade base.
						self.name = itemClass:match("One Hand") and "Energy Blade One Handed" or "Energy Blade Two Handed"
					end
					if data.itemBases[self.name] then
						baseName = self.name
					else
						local bestMatch = {length = -1}
						-- Partial match (magic items with affixes)
						for itemBaseName, baseData in pairs(data.itemBases) do
							local s, e = self.name:find(itemBaseName, 1, true)
							if s and e and (e-s > bestMatch.length) then
								bestMatch.match = itemBaseName
								bestMatch.length = e-s
								bestMatch.e = e
								bestMatch.s = s
							end
						end
						if bestMatch.match then
							self.namePrefix = self.name:sub(1, bestMatch.s - 1)
							self.nameSuffix = self.name:sub(bestMatch.e + 1)
							baseName = bestMatch.match
						end
					end
					if not baseName then
						local s, e = self.name:find("Two-Toned Boots", 1, true)
						if s then
							-- Hack for Two-Toned Boots
							baseName = "Two-Toned Boots"
							self.namePrefix = self.name:sub(1, s - 1)
							self.nameSuffix = self.name:sub(e + 1)
						end
					end
					self.name = self.name:gsub(" %(.+%)","")
				end
				if not baseName then
					baseName = line:gsub("^Superior ", ""):gsub("^Synthesised ","")
				end
				if baseName == "Two-Toned Boots" then
					baseName = "Two-Toned Boots (Armour/Energy Shield)"
				end
				local base = data.itemBases[baseName]
				if base then
					-- Items with variants can have multiple bases
					self.baseLines[baseName] = { line = baseName, variantList = modLine.variantList }
					-- Set the actual base if variant matches or doesn't have variants
					if not self.variant or not modLine.variantList or modLine.variantList[self.variant] then
						self.baseName = baseName
						if not (self.rarity == "NORMAL" or self.rarity == "MAGIC") then
							self.title = self.name
						end
						self.type = base.type
						self.base = base
						self.affixes = (self.base.subType and data.itemMods[self.base.type..self.base.subType])
								or data.itemMods[self.base.type]
								or data.itemMods.Item
						if self.base.weapon then
							self.enchantments = data.enchantments["Weapon"]
						elseif self.base.flask then
							self.enchantments = data.enchantments["Flask"]
							if self.base.utility_flask then
								self.enchantments = data.enchantments["Flask"]
							end
						else
							self.enchantments = data.enchantments[self.base.type]
						end
						self.corruptible = self.base.type ~= "Flask"
						self.canBeInfluenced = self.base.influenceTags ~= nil
						self.clusterJewel = data.clusterJewels and data.clusterJewels.jewels[self.baseName]
						self.requirements.str = self.base.req.str or 0
						self.requirements.dex = self.base.req.dex or 0
						self.requirements.int = self.base.req.int or 0
						local maxReq = m_max(self.requirements.str, self.requirements.dex, self.requirements.int)
						self.defaultSocketColor = (maxReq == self.requirements.dex and "G") or (maxReq == self.requirements.int and "B") or "R"
						if self.base.flask and self.base.flask.buff and not flaskBuffLines then
							flaskBuffLines = { }
							for _, line in ipairs(self.base.flask.buff) do
								flaskBuffLines[line] = true
								local modList, extra = modLib.parseMod(line)
								t_insert(self.buffModLines, { line = line, extra = extra, modList = modList or { } })
							end
						end
					end
					-- Base lines don't need mod parsing, skip it
					goto continue
				end
				if modLine.implicit then
					foundImplicit = true
					gameModeStage = "IMPLICIT"
				end
				local catalystScalar = getCatalystScalar(self.catalyst, modLine.modTags, self.catalystQuality)
				local rangedLine = itemLib.applyRange(line, 1, catalystScalar)
				local modList, extra = modLib.parseMod(rangedLine)
				if (not modList or extra) and self.rawLines[l+1] then
					-- Try to combine it with the next line
					local nextLine = self.rawLines[l+1]:gsub("%b{}", ""):gsub(" ?%(%l+%)","")
					local combLine = line.." "..nextLine
					rangedLine = itemLib.applyRange(combLine, 1, catalystScalar)
					modList, extra = modLib.parseMod(rangedLine, true)
					if modList and not extra then
						line = line.."\n"..nextLine
						l = l + 1
					else
						modList, extra = modLib.parseMod(rangedLine)
					end
				end

				local lineLower = line:lower()
				if lineLower == "this item can be anointed by cassia" then
					self.canBeAnointed = true
				elseif lineLower == "can have a second enchantment modifier" then
					self.canHaveTwoEnchants = true
				elseif lineLower == "can have 1 additional enchantment modifiers" then
					self.canHaveTwoEnchants = true
				elseif lineLower == "can have 2 additional enchantment modifiers" then
					self.canHaveTwoEnchants = true
					self.canHaveThreeEnchants = true
				elseif lineLower == "can have 3 additional enchantment modifiers" then
					self.canHaveTwoEnchants = true
					self.canHaveThreeEnchants = true
					self.canHaveFourEnchants = true
				elseif lineLower == "has a crucible passive skill tree with only support passive skills" then
					self.canHaveOnlySupportSkillsCrucibleTree = true
				elseif lineLower == "has a crucible passive skill tree" then
					self.canHaveShieldCrucibleTree = true
				elseif lineLower == "has a two handed sword crucible passive skill tree" then
					self.canHaveTwoHandedSwordCrucibleTree = true
				end

				local modLines
				if modLine.enchant or (modLine.crafted and #self.enchantModLines + #self.implicitModLines < implicitLines) then
					modLines = self.enchantModLines
				elseif modLine.scourge then
					modLines = self.scourgeModLines
				elseif line:find("Requires Class") then
					modLines = self.classRequirementModLines
				elseif modLine.implicit or (not modLine.crafted and #self.enchantModLines + #self.scourgeModLines + #self.implicitModLines < implicitLines) then
					modLines = self.implicitModLines
				elseif modLine.crucible then
					modLines = self.crucibleModLines
				else
					modLines = self.explicitModLines
				end
				modLine.line = line
				if modList then
					modLine.modList = modList
					modLine.extra = extra
					modLine.valueScalar = catalystScalar
					modLine.range = modLine.range or main.defaultItemAffixQuality
					t_insert(modLines, modLine)
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
					if gameModeStage == "IMPLICIT" or gameModeStage == "EXPLICIT" or (gameModeStage == "FINDIMPLICIT" and (not data.itemBases[line]) and not (self.name == line) and not line:find("Two%-Toned") and not (self.base and (line == self.base.type or self.base.subType and line == self.base.subType .. " " .. self.base.type))) then
						modLine.modList = { }
						modLine.extra = line
						t_insert(modLines, modLine)
					elseif gameModeStage == "FINDEXPLICIT" then
						gameModeStage = "DONE"
					end
				elseif foundExplicit then
					modLine.modList = { }
					modLine.extra = line
					t_insert(modLines, modLine)
				end
			end
		end
		::continue::
		l = l + 1
	end
	if self.baseName and self.title then
		self.name = self.title .. ", " .. self.baseName:gsub(" %(.+%)","")
	end
	if self.base and not self.requirements.level then
		if importedLevelReq and #self.sockets == 0 then
			-- Requirements on imported items can only be trusted for items with no sockets
			self.requirements.level = importedLevelReq
		else
			self.requirements.level = self.base.req.level
		end
	end
	self.affixLimit = 0
	if self.crafted then
		if not self.affixes then 
			self.crafted = false
		elseif self.rarity == "MAGIC" then
			self.affixLimit = 2
		elseif self.rarity == "RARE" then
			self.affixLimit = ((self.type == "Jewel" and not (self.base.subType == "Abyss" and self.corrupted)) and 4 or 6)
		else
			self.crafted = false
		end
		if self.crafted then
			for _, list in ipairs({self.prefixes,self.suffixes}) do
				for i = 1, self.affixLimit/2 do
					if not list[i] then
						list[i] = { modId = "None" }
					elseif list[i].modId ~= "None" and not self.affixes[list[i].modId] then
						for modId, mod in pairs(self.affixes) do
							if list[i].modId == mod.affix then
								list[i].modId = modId
								break
							end
						end
						if not self.affixes[list[i].modId] then
							list[i].modId = "None"
						end
					end
				end
			end
		end
	end
	if self.base and self.base.socketLimit then
		if #self.sockets == 0 then
			for i = 1, self.base.socketLimit do
				t_insert(self.sockets, {
					color = self.defaultSocketColor,
					group = 0,
				})
			end
		end
	end
	self.abyssalSocketCount = 0
	if self.variantList then
		self.variant = m_min(#self.variantList, self.variant or #self.variantList)
		if self.hasAltVariant then
			self.variantAlt = m_min(#self.variantList, self.variantAlt or #self.variantList)
		end
		if self.hasAltVariant2 then
			self.variantAlt2 = m_min(#self.variantList, self.variantAlt2 or #self.variantList)
		end
		if self.hasAltVariant3 then
			self.variantAlt3 = m_min(#self.variantList, self.variantAlt3 or #self.variantList)
		end
		if self.hasAltVariant4 then
			self.variantAlt4 = m_min(#self.variantList, self.variantAlt4 or #self.variantList)
		end
		if self.hasAltVariant5 then
			self.variantAlt5 = m_min(#self.variantList, self.variantAlt5 or #self.variantList)
		end
	end
	if not self.quality then
		self:NormaliseQuality()
		if highQuality then
			-- Behavior of NormaliseQuality should be looked at because calling it twice has different results.
			-- Leaving it alone for now. Just moving it here from Main.lua so BuildAndParseRaw doesn't need to be called.
			self:NormaliseQuality()
		end
	end
	self:BuildModList()
	if deferJewelRadiusIndexAssignment then
		self.jewelRadiusIndex = self.jewelData.radiusIndex
	end
end

function ItemClass:NormaliseQuality()
	if self.base and (self.base.armour or self.base.weapon or self.base.flask) then
		if not self.quality then
			self.quality = 0
		elseif not self.uniqueID and not self.corrupted and not self.split and not self.mirrored and self.quality < 20 then
			self.quality = 20
		end
	end	
end

function ItemClass:GetModSpawnWeight(mod, includeTags, excludeTags)
	local weight = 0
	if self.base then
		local function HasInfluenceTag(key)
			if self.base.influenceTags then
				for _, curInfluenceInfo in ipairs(influenceInfo) do
					if self[curInfluenceInfo.key] and self.base.influenceTags[curInfluenceInfo.key] == key then
						return true
					end
				end
			end
			return false
		end

		local function HasMavenInfluence(modAffix)
			return modAffix:match("Elevated")
		end

		for i, key in ipairs(mod.weightKey) do
			if (self.base.tags[key] or (includeTags and includeTags[key]) or HasInfluenceTag(key)) and not (excludeTags and excludeTags[key]) then
				weight = (HasInfluenceTag(key) and HasMavenInfluence(mod.affix)) and 1000 or mod.weightVal[i]
				break
			end
		end
		for i, key in ipairs(mod.weightMultiplierKey) do
			if (self.base.tags[key] or (includeTags and includeTags[key]) or HasInfluenceTag(key)) and not (excludeTags and excludeTags[key]) then
				weight = weight * mod.weightMultiplierVal[i] / 100
				break
			end
		end
	end
	return weight
end

function ItemClass:CheckIfModIsDelve(mod)
	return mod.affix == "Subterranean" or mod.affix == "of the Underground"
end


function ItemClass:BuildRaw()
	local rawLines = { }
	t_insert(rawLines, "Rarity: " .. self.rarity)
	if self.title then
		t_insert(rawLines, self.title)
		t_insert(rawLines, self.baseName)
	else
		t_insert(rawLines, (self.namePrefix or "") .. self.baseName .. (self.nameSuffix or ""))
	end
	if self.armourData then
		for _, type in ipairs({ "Armour", "Evasion", "EnergyShield", "Ward" }) do
			if self.armourData[type] and self.armourData[type] > 0 then
				t_insert(rawLines, type:gsub("EnergyShield", "Energy Shield") .. ": " .. self.armourData[type])
				if self.armourData[type .. "BasePercentile"] then
					t_insert(rawLines, type .. "BasePercentile: " .. self.armourData[type .. "BasePercentile"])
				end
			end
		end
	end
	if self.uniqueID then
		t_insert(rawLines, "Unique ID: " .. self.uniqueID)
	end
	if self.league then
		t_insert(rawLines, "League: " .. self.league)
	end
	if self.unreleased then
		t_insert(rawLines, "Unreleased: true")
	end
	for i, curInfluenceInfo in ipairs(influenceInfo) do
		if self[curInfluenceInfo.key] then
			t_insert(rawLines, curInfluenceInfo.display .. " Item")
		end
	end
	if self.crafted then
		t_insert(rawLines, "Crafted: true")
		for i, affix in ipairs(self.prefixes or { }) do
			t_insert(rawLines, "Prefix: " .. (affix.range and ("{range:" .. round(affix.range,3) .. "}") or "") .. affix.modId)
		end
		for i, affix in ipairs(self.suffixes or { }) do
			t_insert(rawLines, "Suffix: " .. (affix.range and ("{range:" .. round(affix.range,3) .. "}") or "") .. affix.modId)
		end
	end
	if self.catalyst and self.catalyst > 0 then
		t_insert(rawLines, "Catalyst: " .. catalystList[self.catalyst])
	end
	if self.catalystQuality then
		t_insert(rawLines, "CatalystQuality: " .. self.catalystQuality)
	end
	if self.clusterJewel then
		if self.clusterJewelSkill then
			t_insert(rawLines, "Cluster Jewel Skill: " .. self.clusterJewelSkill)
		end
		if self.clusterJewelNodeCount then
			t_insert(rawLines, "Cluster Jewel Node Count: " .. self.clusterJewelNodeCount)
		end
	end
	if self.talismanTier then
		t_insert(rawLines, "Talisman Tier: " .. self.talismanTier)
	end
	if self.itemLevel then
		t_insert(rawLines, "Item Level: " .. self.itemLevel)
	end
	local function writeModLine(modLine)
		local line = modLine.line
		if modLine.range and line:match("%(%-?[%d%.]+%-%-?[%d%.]+%)") then
			line = "{range:" .. round(modLine.range, 3) .. "}" .. line
		end
		if modLine.crafted then
			line = "{crafted}" .. line
		end
		if modLine.custom then
			line = "{custom}" .. line
		end
		if modLine.scourge then
			line = "{scourge}" .. line
		end
		if modLine.crucible then
			line = "{crucible}" .. line
		end
		if modLine.fractured then
			line = "{fractured}" .. line
		end
		if modLine.exarch then
			line = "{exarch}" .. line
		end
		if modLine.eater then
			line = "{eater}" .. line
		end
		if modLine.synthesis then
			line = "{synthesis}" .. line
		end
		if modLine.variantList then
			local varSpec
			for varId in pairs(modLine.variantList) do
				varSpec = (varSpec and varSpec .. "," or "") .. varId
			end
			line = "{variant:" .. varSpec .. "}" .. line
		end
		if modLine.modTags and #modLine.modTags > 0 then
			line = "{tags:" .. table.concat(modLine.modTags, ",") .. "}" .. line
		end
		t_insert(rawLines, line)
	end
	if self.variantList then
		for _, variantName in ipairs(self.variantList) do
			t_insert(rawLines, "Variant: " .. variantName)
		end
		t_insert(rawLines, "Selected Variant: " .. self.variant)

		for _, baseLine in pairs(self.baseLines) do
			if baseLine.variantList then
				writeModLine(baseLine)
			end
		end	
		if self.hasAltVariant then
			t_insert(rawLines, "Has Alt Variant: true")
			t_insert(rawLines, "Selected Alt Variant: " .. self.variantAlt)
		end
		if self.hasAltVariant2 then
			t_insert(rawLines, "Has Alt Variant Two: true")
			t_insert(rawLines, "Selected Alt Variant Two: " .. self.variantAlt2)
		end
		if self.hasAltVariant3 then
			t_insert(rawLines, "Has Alt Variant Three: true")
			t_insert(rawLines, "Selected Alt Variant Three: " .. self.variantAlt3)
		end
		if self.hasAltVariant4 then
			t_insert(rawLines, "Has Alt Variant Four: true")
			t_insert(rawLines, "Selected Alt Variant Four: " .. self.variantAlt4)
		end
		if self.hasAltVariant5 then
			t_insert(rawLines, "Has Alt Variant Five: true")
			t_insert(rawLines, "Selected Alt Variant Five: " .. self.variantAlt5)
		end
	end
	if self.quality then
		t_insert(rawLines, "Quality: " .. self.quality)
	end
	if self.sockets and #self.sockets > 0 then
		local line = "Sockets: "
		for i, socket in pairs(self.sockets) do
			line = line .. socket.color
			if self.sockets[i+1] then
				line = line .. (socket.group == self.sockets[i+1].group and "-" or " ")
			end
		end
		t_insert(rawLines, line)
	end
	if self.requirements and self.requirements.level then
		t_insert(rawLines, "LevelReq: " .. self.requirements.level)
	end
	if self.jewelRadiusLabel then
		t_insert(rawLines, "Radius: " .. self.jewelRadiusLabel)
	end
	if self.limit then
		t_insert(rawLines, "Limited to: " .. self.limit)
	end
	if self.classRestriction then
		t_insert(rawLines, "Requires Class " .. self.classRestriction)
	end
	t_insert(rawLines, "Implicits: " .. (#self.enchantModLines + #self.implicitModLines + #self.scourgeModLines))
	for _, modLine in ipairs(self.enchantModLines) do
		writeModLine(modLine)
	end
	for _, modLine in ipairs(self.scourgeModLines) do
		writeModLine(modLine)
	end
	for _, modLine in ipairs(self.classRequirementModLines) do
		writeModLine(modLine)
	end
	for _, modLine in ipairs(self.implicitModLines) do
		writeModLine(modLine)
	end
	for _, modLine in ipairs(self.explicitModLines) do
		writeModLine(modLine)
	end
	for _, modLine in ipairs(self.crucibleModLines) do
		writeModLine(modLine)
	end
	if self.split then
		t_insert(rawLines, "Split")
	end
	if self.mirrored then
		t_insert(rawLines, "Mirrored")
	end
	if self.corrupted or self.scourge then
		t_insert(rawLines, "Corrupted")
	end
	return table.concat(rawLines, "\n")
end

function ItemClass:BuildAndParseRaw()
	local raw = self:BuildRaw()
	self:ParseRaw(raw)
end

-- Rebuild explicit modifiers using the item's affixes
function ItemClass:Craft()
	-- Save off any crafted or custom mods so they can be re-added at the end
	local savedMods = {}
	for _, mod in ipairs(self.explicitModLines) do
		if mod.crafted or mod.custom then
			t_insert(savedMods, mod)
		end
	end

	wipeTable(self.explicitModLines)
	self.namePrefix = ""
	self.nameSuffix = ""
	self.requirements.level = self.base.req.level
	local statOrder = { }
	for _, list in ipairs({self.prefixes,self.suffixes}) do
		for i = 1, self.affixLimit / 2 do
			local affix = list[i]
			if not affix then
				list[i] = { modId = "None" }
			end
			local mod = self.affixes[affix.modId]
			if mod then
				if mod.type == "Prefix" then
					self.namePrefix = mod.affix .. " "
				elseif mod.type == "Suffix" then
					self.nameSuffix = " " .. mod.affix
				end
				self.requirements.level = m_max(self.requirements.level or 0, m_floor(mod.level * 0.8))
				local rangeScalar = getCatalystScalar(self.catalyst, mod.modTags, self.catalystQuality)
				for i, line in ipairs(mod) do
					line = itemLib.applyRange(line, affix.range or 0.5, rangeScalar)
					local order = mod.statOrder[i]
					if statOrder[order] then
						-- Combine stats
						local start = 1
						statOrder[order].line = statOrder[order].line:gsub("%d+", function(num)
							local s, e, other = line:find("(%d+)", start)
							start = e + 1
							return tonumber(num) + tonumber(other)
						end)
					else
						local modLine = { line = line, order = order }
						for l = 1, #self.explicitModLines + 1 do
							if not self.explicitModLines[l] or self.explicitModLines[l].order > order then
								t_insert(self.explicitModLines, l, modLine)
								break
							end
						end
						statOrder[order] = modLine
					end	
				end
			end
		end
	end

	-- Restore the crafted and custom mods
	for _, mod in ipairs(savedMods) do
		t_insert(self.explicitModLines, mod)
	end

	self:BuildAndParseRaw()
end

function ItemClass:CheckModLineVariant(modLine)
	return not modLine.variantList 
		or modLine.variantList[self.variant]
		or (self.hasAltVariant and modLine.variantList[self.variantAlt])
		or (self.hasAltVariant2 and modLine.variantList[self.variantAlt2])
		or (self.hasAltVariant3 and modLine.variantList[self.variantAlt3])
		or (self.hasAltVariant4 and modLine.variantList[self.variantAlt4])
		or (self.hasAltVariant5 and modLine.variantList[self.variantAlt5])
end

-- Return the name of the slot this item is equipped in
function ItemClass:GetPrimarySlot()
	if self.base.weapon then
		return "Weapon 1"
	elseif self.type == "Quiver" or self.type == "Shield" then
		return "Weapon 2"
	elseif self.type == "Ring" then
		return "Ring 1"
	elseif self.type == "Flask" then
		return "Flask 1"
	else
		return self.type
	end
end

-- Calculate local modifiers, and removes them from the modifier list
-- To be considered local, a modifier must be an exact flag match, and cannot have any tags (e.g. conditions, multipliers)
-- Only the InSlot tag is allowed (for Adds x to x X Damage in X Hand modifiers)
local function calcLocal(modList, name, type, flags)
	local result
	if type == "FLAG" then
		result = false
	elseif type == "MORE" then
		result = 1
	else
		result = 0
	end
	local i = 1
	while modList[i] do
		local mod = modList[i]
		if mod.name == name and mod.type == type and mod.flags == flags and mod.keywordFlags == 0 and (not mod[1] or mod[1].type == "InSlot") then
			if type == "FLAG" then
				result = result or mod.value
			-- convert MORE to times multiplier, e.g. 50% more = 1.5x, result = 1.5
			elseif type == "MORE" then
				result = result * ((100 + mod.value) / 100)
			else
				result = result + mod.value
			end
			t_remove(modList, i)
		else
			i = i + 1
		end
	end
	return result
end

-- Build list of modifiers in a given slot number (1 or 2) while applying local modifiers and adding quality
function ItemClass:BuildModListForSlotNum(baseList, slotNum)
	local slotName = self:GetPrimarySlot()
	if slotNum == 2 then
		slotName = slotName:gsub("1", "2")
	end
	local modList = new("ModList")
	for _, baseMod in ipairs(baseList) do
		local mod = copyTable(baseMod)
		local add = true
		for _, tag in ipairs(mod) do
			if tag.type == "SlotNumber" or tag.type == "InSlot" then
				if tag.num ~= slotNum then
					add = false
					break
				end
			end
			for k, v in pairs(tag) do
				if type(v) == "string" then
					tag[k] = v:gsub("{SlotName}", slotName)
							  :gsub("{Hand}", (slotNum == 1) and "MainHand" or "OffHand")
							  :gsub("{OtherSlotNum}", slotNum == 1 and "2" or "1")
				end
			end
		end
		if add then
			mod.sourceSlot = slotName
			modList:AddMod(mod)
		end
	end
	if #self.sockets > 0 then
		local multiName = {
			R = "Multiplier:RedSocketIn"..slotName,
			G = "Multiplier:GreenSocketIn"..slotName,
			B = "Multiplier:BlueSocketIn"..slotName,
			W = "Multiplier:WhiteSocketIn"..slotName,
		}
		for _, socket in ipairs(self.sockets) do
			if multiName[socket.color] then
				modList:NewMod(multiName[socket.color], "BASE", 1, "Item Sockets")
			end
		end
	end
	local craftedQuality = calcLocal(modList,"Quality","BASE",0) or 0
	if craftedQuality ~= self.craftedQuality then
		if self.craftedQuality then
			self.quality = (self.quality or 0) - self.craftedQuality + craftedQuality
		end
		self.craftedQuality = craftedQuality
	end
	if self.quality then
		modList:NewMod("Multiplier:QualityOn"..slotName, "BASE", self.quality, "Quality")
	end
	if self.base.weapon then
		local weaponData = { }
		self.weaponData[slotNum] = weaponData
		weaponData.type = self.base.type
		weaponData.name = self.name
		weaponData.AttackSpeedInc = calcLocal(modList, "Speed", "INC", ModFlag.Attack) + m_floor(self.quality / 8 * calcLocal(modList, "AlternateQualityLocalAttackSpeedPer8Quality", "INC", 0))
		weaponData.AttackRate = round(self.base.weapon.AttackRateBase * (1 + weaponData.AttackSpeedInc / 100), 2)
		weaponData.rangeBonus = calcLocal(modList, "WeaponRange", "BASE", 0) + 10 * calcLocal(modList, "WeaponRangeMetre", "BASE", 0) + m_floor(self.quality / 10 * calcLocal(modList, "AlternateQualityLocalWeaponRangePer10Quality", "BASE", 0))
		weaponData.range = self.base.weapon.Range + weaponData.rangeBonus
		for _, dmgType in pairs(dmgTypeList) do
			local min = (self.base.weapon[dmgType.."Min"] or 0) + calcLocal(modList, dmgType.."Min", "BASE", 0)
			local max = (self.base.weapon[dmgType.."Max"] or 0) + calcLocal(modList, dmgType.."Max", "BASE", 0)
			if dmgType == "Physical" then
				local physInc = calcLocal(modList, "PhysicalDamage", "INC", 0)
				local qualityScalar = self.quality
				if calcLocal(modList, "AlternateQualityWeapon", "BASE", 0) > 0 then
					qualityScalar = 0
				end
				min = round(min * (1 + (physInc + qualityScalar) / 100))
				max = round(max * (1 + (physInc + qualityScalar) / 100))
			end
			if min > 0 and max > 0 then
				weaponData[dmgType.."Min"] = min
				weaponData[dmgType.."Max"] = max
				local dps = (min + max) / 2 * weaponData.AttackRate
				weaponData[dmgType.."DPS"] = dps
				if dmgType ~= "Physical" and dmgType ~= "Chaos" then
					weaponData.ElementalDPS = (weaponData.ElementalDPS or 0) + dps
				end
			end
		end
		weaponData.CritChance = round((self.base.weapon.CritChanceBase + calcLocal(modList, "CritChance", "BASE", 0)) * (1 + (calcLocal(modList, "CritChance", "INC", 0) + m_floor(self.quality / 4 * calcLocal(modList, "AlternateQualityLocalCritChancePer4Quality", "INC", 0))) / 100), 2)
		for _, value in ipairs(modList:List(nil, "WeaponData")) do
			weaponData[value.key] = value.value
		end
		for _, mod in ipairs(modList) do
			-- Convert accuracy, L/MGoH and PAD Leech modifiers to local
			if (
				(mod.name == "Accuracy" and mod.flags == 0) or (mod.name == "ImpaleChance" and mod.flags ~= ModFlag.Spell) or
				((mod.name == "LifeOnHit" or mod.name == "ManaOnHit") and mod.flags == ModFlag.Attack) or
				((mod.name == "PhysicalDamageLifeLeech" or mod.name == "PhysicalDamageManaLeech") and mod.flags == ModFlag.Attack)
			   ) and (mod.keywordFlags == 0 or mod.keywordFlags == KeywordFlag.Attack) and not mod[1] then
				mod[1] = { type = "Condition", var = (slotNum == 1) and "MainHandAttack" or "OffHandAttack" }
			elseif (mod.name == "PoisonChance" or mod.name == "BleedChance") and mod.flags ~= ModFlag.Spell and (not mod[1] or (mod[1].type == "Condition" and mod[1].var == "CriticalStrike" and not mod[2])) then
				t_insert(mod, { type = "Condition", var = (slotNum == 1) and "MainHandAttack" or "OffHandAttack" })
			end
		end
		weaponData.TotalDPS = 0
		for _, dmgType in pairs(dmgTypeList) do
			weaponData.TotalDPS = weaponData.TotalDPS + (weaponData[dmgType.."DPS"] or 0)
		end
	elseif self.base.armour then
		local armourData = self.armourData
		local armourBase = calcLocal(modList, "Armour", "BASE", 0) + (self.base.armour.ArmourBaseMin or 0)
		local armourVariance = (self.base.armour.ArmourBaseMax or 0) - (self.base.armour.ArmourBaseMin or 0)
		local armourEvasionBase = calcLocal(modList, "ArmourAndEvasion", "BASE", 0)
		local evasionBase = calcLocal(modList, "Evasion", "BASE", 0) + (self.base.armour.EvasionBaseMin or 0)
		local evasionVariance = (self.base.armour.EvasionBaseMax or 0) - (self.base.armour.EvasionBaseMin or 0)
		local evasionEnergyShieldBase = calcLocal(modList, "EvasionAndEnergyShield", "BASE", 0)
		local energyShieldBase = calcLocal(modList, "EnergyShield", "BASE", 0) + (self.base.armour.EnergyShieldBaseMin or 0)
		local energyShieldVariance = (self.base.armour.EnergyShieldBaseMax or 0) - (self.base.armour.EnergyShieldBaseMin or 0)
		local armourEnergyShieldBase = calcLocal(modList, "ArmourAndEnergyShield", "BASE", 0)
		local wardBase = calcLocal(modList, "Ward", "BASE", 0) + (self.base.armour.WardBaseMin or 0)
		local wardVariance = (self.base.armour.WardBaseMax or 0) - (self.base.armour.WardBaseMin or 0)
		local armourInc = calcLocal(modList, "Armour", "INC", 0)
		local armourEvasionInc = calcLocal(modList, "ArmourAndEvasion", "INC", 0)
		local evasionInc = calcLocal(modList, "Evasion", "INC", 0)
		local evasionEnergyShieldInc = calcLocal(modList, "EvasionAndEnergyShield", "INC", 0)
		local energyShieldInc = calcLocal(modList, "EnergyShield", "INC", 0)
		local wardInc = calcLocal(modList, "Ward", "INC", 0)
		local armourEnergyShieldInc = calcLocal(modList, "ArmourAndEnergyShield", "INC", 0)
		local defencesInc = calcLocal(modList, "Defences", "INC", 0)
		local qualityScalar = self.quality
		if calcLocal(modList, "AlternateQualityArmour", "BASE", 0) > 0 then
			qualityScalar = 0
		end
		-- base percentiles need to differ for each armour type, as they're weighted differently
		if armourData.Armour and armourData.Armour > 0 and not armourData.ArmourBasePercentile then
			armourData.ArmourBasePercentile = ((armourData.Armour / (1 + (armourInc + armourEvasionInc + armourEnergyShieldInc + defencesInc + qualityScalar) / 100) - armourBase)) / armourVariance
			armourData.ArmourBasePercentile = round(m_max(m_min(armourData.ArmourBasePercentile, 1), 0), 4)
		end
		if armourData.Evasion and armourData.Evasion > 0 and not armourData.EvasionBasePercentile then
			armourData.EvasionBasePercentile = ((armourData.Evasion / (1 + (evasionInc + armourEvasionInc + evasionEnergyShieldInc + defencesInc + qualityScalar) / 100) - evasionBase)) / evasionVariance
			armourData.EvasionBasePercentile = round(m_max(m_min(armourData.EvasionBasePercentile, 1), 0), 4)
		end
		if armourData.EnergyShield and armourData.EnergyShield > 0 and not armourData.EnergyShieldBasePercentile then
			armourData.EnergyShieldBasePercentile = ((armourData.EnergyShield / (1 + (energyShieldInc + armourEnergyShieldInc + evasionEnergyShieldInc + defencesInc + qualityScalar) / 100) - energyShieldBase)) / energyShieldVariance
			armourData.EnergyShieldBasePercentile = round(m_max(m_min(armourData.EnergyShieldBasePercentile, 1), 0), 4)
		end
		if armourData.Ward and armourData.Ward > 0 and not armourData.WardBasePercentile then
			armourData.WardBasePercentile = ((armourData.Ward / (1 + (wardInc + defencesInc + qualityScalar) / 100) - wardBase)) / wardVariance
			armourData.WardBasePercentile = round(m_max(m_min(armourData.WardBasePercentile, 1), 0),4)
		end

		armourData.Armour = round((armourBase + armourEvasionBase + armourEnergyShieldBase + armourVariance * (armourData.ArmourBasePercentile or 1)) * (1 + (armourInc + armourEvasionInc + armourEnergyShieldInc + defencesInc + qualityScalar) / 100))
		armourData.Evasion = round((evasionBase + armourEvasionBase + evasionEnergyShieldBase + evasionVariance * (armourData.EvasionBasePercentile or 1)) * (1 + (evasionInc + armourEvasionInc + evasionEnergyShieldInc + defencesInc + qualityScalar) / 100))
		armourData.EnergyShield = round((energyShieldBase + evasionEnergyShieldBase + armourEnergyShieldBase + energyShieldVariance * (armourData.EnergyShieldBasePercentile or 1)) * (1 + (energyShieldInc + armourEnergyShieldInc + evasionEnergyShieldInc + defencesInc + qualityScalar) / 100))
		armourData.Ward = round((wardBase + wardVariance * (armourData.WardBasePercentile or 1)) * (1 + (wardInc + defencesInc + qualityScalar) / 100))

		if not armourData.ArmourBasePercentile and armourData.Armour > 0 then
			armourData.ArmourBasePercentile = 1
		end
		if not armourData.EvasionBasePercentile and armourData.Evasion > 0 then
			armourData.EvasionBasePercentile = 1
		end
		if not armourData.EnergyShieldBasePercentile and armourData.EnergyShield > 0 then
			armourData.EnergyShieldBasePercentile = 1
		end
		if not armourData.WardBasePercentile and armourData.Ward > 0 then
			armourData.WardBasePercentile = 1
		end

		if self.base.armour.BlockChance then
			armourData.BlockChance = self.base.armour.BlockChance + calcLocal(modList, "BlockChance", "BASE", 0)
		end
		if self.base.armour.MovementPenalty then
			modList:NewMod("MovementSpeed", "INC", -self.base.armour.MovementPenalty, self.modSource, { type = "Condition", var = "IgnoreMovementPenalties", neg = true })
		end
		for _, value in ipairs(modList:List(nil, "ArmourData")) do
			armourData[value.key] = value.value
		end
	elseif self.base.flask then
		local flaskData = self.flaskData
		local durationInc = calcLocal(modList, "Duration", "INC", 0)
		local durationMore = calcLocal(modList, "Duration", "MORE", 0)
		if self.base.flask.life or self.base.flask.mana then
			-- Recovery flask
			flaskData.instantPerc = calcLocal(modList, "FlaskInstantRecovery", "BASE", 0)
			local recoveryMod = 1 + calcLocal(modList, "FlaskRecovery", "INC", 0) / 100
			local rateMod = 1 + calcLocal(modList, "FlaskRecoveryRate", "INC", 0) / 100
			flaskData.duration = round(self.base.flask.duration * (1 + durationInc / 100) / rateMod * durationMore, 1)
			if self.base.flask.life then
				flaskData.lifeBase = self.base.flask.life * (1 + self.quality / 100) * recoveryMod
				flaskData.lifeInstant = flaskData.lifeBase * flaskData.instantPerc / 100
				flaskData.lifeGradual = flaskData.lifeBase * (1 - flaskData.instantPerc / 100)
				flaskData.lifeTotal = flaskData.lifeInstant + flaskData.lifeGradual
				flaskData.lifeAdditional = calcLocal(modList, "FlaskAdditionalLifeRecovery", "BASE", 0)
				flaskData.lifeEffectNotRemoved = calcLocal(baseList, "LifeFlaskEffectNotRemoved", "FLAG", 0)
			end
			if self.base.flask.mana then
				flaskData.manaBase = self.base.flask.mana * (1 + self.quality / 100) * recoveryMod
				flaskData.manaInstant = flaskData.manaBase * flaskData.instantPerc / 100
				flaskData.manaGradual = flaskData.manaBase * (1 - flaskData.instantPerc / 100)
				flaskData.manaTotal = flaskData.manaInstant + flaskData.manaGradual
				flaskData.manaEffectNotRemoved = calcLocal(baseList, "ManaFlaskEffectNotRemoved", "FLAG", 0)
			end
		else
			-- Utility flask
			flaskData.duration = round(self.base.flask.duration * (1 + (durationInc + self.quality) / 100) * durationMore, 1)
		end
		flaskData.chargesMax = self.base.flask.chargesMax + calcLocal(modList, "FlaskCharges", "BASE", 0)
		flaskData.chargesUsed = m_floor(self.base.flask.chargesUsed * (1 + calcLocal(modList, "FlaskChargesUsed", "INC", 0) / 100))
		flaskData.gainMod = 1 + calcLocal(modList, "FlaskChargeRecovery", "INC", 0) / 100
		flaskData.effectInc = calcLocal(modList, "FlaskEffect", "INC", 0)
		for _, value in ipairs(modList:List(nil, "FlaskData")) do
			flaskData[value.key] = value.value
		end
	elseif self.type == "Jewel" then
		if self.name:find("Grand Spectrum") then
			local spectrumMod = modLib.createMod("Multiplier:GrandSpectrum", "BASE", 1, self.name)
			modList:AddMod(spectrumMod)
			modList:NewMod("MinionModifier", "LIST", { mod = spectrumMod }, self.name)
		end

		local jewelData = self.jewelData
		for _, func in ipairs(modList:List(nil, "JewelFunc")) do
			jewelData.funcList = jewelData.funcList or { }
			t_insert(jewelData.funcList, func)
		end
		for _, value in ipairs(modList:List(nil, "JewelData")) do
			jewelData[value.key] = value.value
		end
		if modList:List(nil, "ImpossibleEscapeKeystones") then
			jewelData.impossibleEscapeKeystones = { }
			for _, value in ipairs(modList:List(nil, "ImpossibleEscapeKeystones")) do
				jewelData.impossibleEscapeKeystones[value.key] = value.value
			end
		end
		if self.clusterJewel then
			jewelData.clusterJewelNotables = { }
			for _, name in ipairs(modList:List(nil, "ClusterJewelNotable")) do
				t_insert(jewelData.clusterJewelNotables, name)
			end
			jewelData.clusterJewelAddedMods = { }
			for _, line in ipairs(modList:List(nil, "AddToClusterJewelNode")) do
				t_insert(jewelData.clusterJewelAddedMods, line)
			end

			-- Small and Medium Curse Cluster Jewel passive mods are parsed the same so the medium cluster data overwrites small and the skills differ
			-- This changes small curse clusters to have the correct clusterJewelSkill so it passes validation below and works as expected in the tree
			if jewelData.clusterJewelSkill == "affliction_curse_effect" and jewelData.clusterJewelNodeCount and jewelData.clusterJewelNodeCount < 4 then
				jewelData.clusterJewelSkill = "affliction_curse_effect_small"
			end

			-- Validation
			if jewelData.clusterJewelNodeCount then
				jewelData.clusterJewelNodeCount = m_min(m_max(jewelData.clusterJewelNodeCount, self.clusterJewel.minNodes), self.clusterJewel.maxNodes)
			end
			if jewelData.clusterJewelSkill and not self.clusterJewel.skills[jewelData.clusterJewelSkill] then
				jewelData.clusterJewelSkill = nil
			end
			jewelData.clusterJewelValid = jewelData.clusterJewelKeystone 
				or ((jewelData.clusterJewelSkill or jewelData.clusterJewelSmallsAreNothingness) and jewelData.clusterJewelNodeCount) 
				or (jewelData.clusterJewelSocketCountOverride and jewelData.clusterJewelNothingnessCount)
		end
	end	
	return { unpack(modList) }
end

-- Build lists of modifiers for each slot the item can occupy
function ItemClass:BuildModList()
	if not self.base then
		return
	end
	local baseList = new("ModList")
	if self.base.weapon then
		self.weaponData = { }
	elseif self.base.armour then
		self.armourData = self.armourData or { }
	elseif self.base.flask then
		self.flaskData = { }
		self.buffModList = { }
	elseif self.type == "Jewel" then
		self.jewelData = { }
	end
	self.baseModList = baseList
	self.rangeLineList = { }
	self.modSource = "Item:"..(self.id or -1)..":"..self.name
	for _, modLine in ipairs(self.buffModLines) do
		if not modLine.extra and self:CheckModLineVariant(modLine) then
			for _, mod in ipairs(modLine.modList) do
				mod.source = self.modSource
				t_insert(self.buffModList, mod)
			end
		end
	end
	local function processModLine(modLine)
		if self:CheckModLineVariant(modLine) then
			-- special section for variant over-ride of pre-modifier item parameters
			if modLine.line:find("Requires Class") then
				self.classRestriction = modLine.line:gsub("{variant:([%d,]+)}", ""):match("Requires Class (.+)")
			end
			-- handle understood modifier variable properties
			if not modLine.extra then
				if modLine.range then
					-- Check if line actually has a range
					if modLine.line:find("%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)") then
						local strippedModeLine = modLine.line:gsub("\n"," ")						
						local catalystScalar = getCatalystScalar(self.catalyst, modLine.modTags, self.catalystQuality)
						-- Put the modified value into the string
						local line = itemLib.applyRange(strippedModeLine, modLine.range, catalystScalar)
						-- Check if we can parse it before adding the mods
						local list, extra = modLib.parseMod(line)
						if list and not extra then
							modLine.modList = list
							t_insert(self.rangeLineList, modLine)
						end
					end
				end
				for _, mod in ipairs(modLine.modList) do
					mod = modLib.setSource(mod, self.modSource)
					baseList:AddMod(mod)
				end
				if modLine.modTags and #modLine.modTags > 0 then
					self.hasModTags = true
				end
			end
		end
	end
	for _, modLine in ipairs(self.enchantModLines) do
		processModLine(modLine)
	end
	for _, modLine in ipairs(self.scourgeModLines) do
		processModLine(modLine)
	end
	for _, modLine in ipairs(self.classRequirementModLines) do
		processModLine(modLine)
	end
	for _, modLine in ipairs(self.implicitModLines) do
		processModLine(modLine)
	end
	for _, modLine in ipairs(self.explicitModLines) do
		processModLine(modLine)
	end
	for _, modLine in ipairs(self.crucibleModLines) do
		processModLine(modLine)
	end
	if calcLocal(baseList, "NoAttributeRequirements", "FLAG", 0) then
		self.requirements.strMod = 0
		self.requirements.dexMod = 0
		self.requirements.intMod = 0
	else
		self.requirements.strMod = m_floor((self.requirements.str + calcLocal(baseList, "StrRequirement", "BASE", 0)) * (1 + calcLocal(baseList, "StrRequirement", "INC", 0) / 100))
		self.requirements.dexMod = m_floor((self.requirements.dex + calcLocal(baseList, "DexRequirement", "BASE", 0)) * (1 + calcLocal(baseList, "DexRequirement", "INC", 0) / 100))
		self.requirements.intMod = m_floor((self.requirements.int + calcLocal(baseList, "IntRequirement", "BASE", 0)) * (1 + calcLocal(baseList, "IntRequirement", "INC", 0) / 100))
	end
	self.grantedSkills = { }
	for _, skill in ipairs(baseList:List(nil, "ExtraSkill")) do
		if skill.name ~= "Unknown" then
			t_insert(self.grantedSkills, {
				skillId = skill.skillId,
				level = skill.level,
				noSupports = skill.noSupports,
				source = self.modSource,
				triggered = skill.triggered,
				triggerChance = skill.triggerChance,
			})
		end
	end
	local socketCount = calcLocal(baseList, "SocketCount", "BASE", 0)
	self.abyssalSocketCount = calcLocal(baseList, "AbyssalSocketCount", "BASE", 0)
	self.selectableSocketCount = m_max(self.base.socketLimit or 0, #self.sockets) - self.abyssalSocketCount
	if calcLocal(baseList, "NoSockets", "FLAG", 0) then
		-- Remove all sockets
		wipeTable(self.sockets)
		self.selectableSocketCount = 0
	elseif socketCount > 0 then
		-- Force the socket count to be equal to the stated number
		self.selectableSocketCount = socketCount
		local group = 0
		for i = 1, m_max(socketCount, #self.sockets) do 
			if i > socketCount then
				self.sockets[i] = nil
			elseif not self.sockets[i] then
				self.sockets[i] = {
					color = self.defaultSocketColor,
					group = group
				}
			else
				group = self.sockets[i].group
			end
		end
	elseif self.abyssalSocketCount > 0 then
		-- Ensure that there are the correct number of abyssal sockets present
		local newSockets = { }
		local group = 0
		if self.sockets then
			for i, socket in ipairs(self.sockets) do
				if socket.color ~= "A" then
					t_insert(newSockets, socket)
					group = socket.group
					if #newSockets >= self.selectableSocketCount then
						break
					end
				end
			end
		end
		for i = 1, self.abyssalSocketCount do
			group = group + 1
			t_insert(newSockets, {
				color = "A",
				group = group
			})
		end
		self.sockets = newSockets
	end
	self.socketedJewelEffectModifier = 1 + calcLocal(baseList, "SocketedJewelEffect", "INC", 0) / 100
	if self.name == "Tabula Rasa, Simple Robe" or self.name == "Skin of the Loyal, Simple Robe" or self.name == "Skin of the Lords, Simple Robe" then
		-- Hack to remove the energy shield
		baseList:NewMod("ArmourData", "LIST", { key = "EnergyShield", value = 0 })
	end
	if self.base.weapon or self.type == "Ring" then
		self.slotModList = { }
		for i = 1, 2 do
			self.slotModList[i] = self:BuildModListForSlotNum(baseList, i)
		end
	else
		self.modList = self:BuildModListForSlotNum(baseList)
	end
end
