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
local catalystList = {"Abrasive", "Accelerating", "Dextral", "Fertile", "Imbued", "Intrinsic", "Noxious", "Prismatic", "Sinistral", "Tempering", "Turbulent", "Unstable"}
local catalystDescriptorList = {"Attack", "Speed", "Suffix", "Life and Mana", "Caster", "Attribute", "Physical and Chaos", "Resistance", "Prefix", "Defence", "Elemental", "Critical"}
local catalystTags = {
	{ "attack" },
	{ "speed" },
	{ "suffix" },
	{ "life", "mana", "resource" },
	{ "caster" },
	{ "jewellery_attribute", "attribute" },
	{ "physical_damage", "chaos_damage" },
	{ "jewellery_resistance", "resistance" },
	{ "prefix" },
	{ "jewellery_defense", "defences", "armour", "evasion", "energyshield" },
	{ "jewellery_elemental" ,"elemental_damage" },
	{ "critical" },
}

local function getCatalystScalar(catalystId, mod, quality)
	if mod.unscalable then
		return 1
	end
	local tags = mod.modTags
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
	-- these aren't actual mod tags but do sinistral/dextral catalyst
	for _, lineFlag in ipairs({ "prefix", "suffix" }) do
		if mod[lineFlag] then
			tagLookup[lineFlag] = true
		end
	end

	-- Find if any of the catalyst's tags match the provided tags
	for _, catalystTag in ipairs(catalystTags[catalystId]) do
		if tagLookup[catalystTag] then
			return (100 + quality) / 100
		end
	end
	return 1
end

local function normaliseModLine(line)
	return line:gsub("%d+%.?%d*", "#")
		:gsub("%(%-?#%-#%)", "#"):lower()
		:gsub("\n", " ")
end

local uniqueModStatOrder

local function sortCraftedModLines(modLines)
	local sourceOrder = { }
	for index, modLine in ipairs(modLines) do
		sourceOrder[modLine] = index
	end
	table.sort(modLines, function(a, b)
		local aGroup = (a.crafted or a.custom) and 3 or a.fractured and 1 or 2
		local bGroup = (b.crafted or b.custom) and 3 or b.fractured and 1 or 2
		if aGroup ~= bGroup then
			return aGroup < bGroup
		elseif aGroup < 3 and a.order ~= b.order then
			return (a.order or math.huge) < (b.order or math.huge)
		end
		return sourceOrder[a] < sourceOrder[b]
	end)
end

local influenceInfo = itemLib.influenceInfo.all

---@class Item
local ItemClass = newClass("Item")

function ItemClass:Item(raw, rarity, highQuality)
	if raw then
		self:ParseRaw(sanitiseText(raw), rarity, highQuality)
	end
	return self
end

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
	["crafted"] = true,
	["crucible"] = true,
	["custom"] = true,
	["disabled"] = true,
	["eater"] = true,
	["enchant"] = true,
	["exarch"] = true,
	["fractured"] = true,
	["implicit"] = true,
	["scourge"] = true,
	["synthesis"] = true,
	["mutated"] = true,
	["unscalable"] = true,
	["prefix"] = true,
	["suffix"] = true,
	-- this is not actually present in advanced copy strings unlike desecration
	-- in poe2. this is currently only added as a hack for cane of kulemak and
	-- should be added based on mod tags after matching a mod in the future
	["unveiled"] = true,
	["vestigial"] = true,
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
												excluded = true
												break
											end
										end
									end
									if excluded then
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
										excluded = true
										break
									end
								end
							end
							if excluded then
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
		if not v.disabled and self:CheckModLineVariant(v) then
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
					if v.line:lower():find(specialMod:lower()) then
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

function ItemClass:IsVariantGroupOptionEligible(groupId, variantId)
	local group = self.variantGroups and self.variantGroups[groupId]
	local versions = group and group[variantId]
	return versions and (versions[0] or self.selectedVersion and versions[self.selectedVersion]) or false
end

function ItemClass:GetVariantGroupOptions(groupId, excludeSelected)
	local options = { }
	if not self.variantGroups or not self.variantGroups[groupId] then
		return options
	end
	local used = { }
	if excludeSelected then
		for otherGroupId in pairsSortByKey(self.variantGroups) do
			if otherGroupId ~= groupId then
				local variantId = self.variantGroupSelections[otherGroupId]
				if variantId and self:IsVariantGroupOptionEligible(otherGroupId, variantId) then
					used[variantId] = true
				end
			end
		end
	end
	for variantId = 1, #self.variantList do
		if self:IsVariantGroupOptionEligible(groupId, variantId) and not used[variantId] then
			t_insert(options, variantId)
		end
	end
	return options
end

function ItemClass:NormaliseVariantSelections()
	if self.versionList and #self.versionList > 0 then
		self.selectedVersion = m_max(1, m_min(#self.versionList, self.selectedVersion or #self.versionList))
	else
		self.selectedVersion = nil
	end
	self.variantGroupSelections = self.variantGroupSelections or { }
	for groupId in pairs(self.variantGroupSelections) do
		if not self.variantGroups[groupId] then
			self.variantGroupSelections[groupId] = nil
		end
	end

	local used = { }
	local needsSelection = { }
	for groupId in pairsSortByKey(self.variantGroups) do
		if #self:GetVariantGroupOptions(groupId, false) > 0 then
			local selected = self.variantGroupSelections[groupId]
			if selected and self:IsVariantGroupOptionEligible(groupId, selected) and not used[selected] then
				used[selected] = true
			else
				t_insert(needsSelection, groupId)
			end
		end
	end
	for _, groupId in ipairs(needsSelection) do
		local selected
		for _, variantId in ipairs(self:GetVariantGroupOptions(groupId, false)) do
			if not used[variantId] then
				selected = variantId
				break
			end
		end
		self.variantGroupSelections[groupId] = selected
		if selected then
			used[selected] = true
		end
	end
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
		line = escapeGGGString(line)
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
			if self.rarity == "UNIQUE" or self.rarity == "RELIC" then
				-- Hack for relics
				for _, line in ipairs(self.rawLines) do
					if line:find("Foil Unique") then
						self.rarity = "RELIC"
						local captured = line:match("%((.-)%)")
						self.foilType = captured or "Rainbow"
						break
					end
				end
			end
			l = l + 1
		end
	end
	if self.rawLines[l] then
		if self.rawLines[l] == "--------" then
			l = l + 1
		end
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
	-- old items or trade-sourced items have increases to modifiers baked in to the item text, which
	-- means that we can't add e.g. quality or mod magnitude effect to them during parsing. we will
	-- assume an item to be an advanced copy format if either has mod roll information, a modifier
	-- line with a range, or advanced copy lines
	self.advancedCopy = false
	self.modMagnitudeMods = {}
	local implicitLines = 0
	self.variantList = nil
	self.versionList = nil
	self.allowDuplicateVariants = false
	self.variantGroups = { }
	self.variantGroupSelections = self.variantGroupSelections or { }
	self.usesVariantGroups = false
	self.prefixes = { }
	self.suffixes = { }
	self.requirements = { }
	self.requirements.str = 0
	self.requirements.dex = 0
	self.requirements.int = 0
	self.baseLines = { }
	self.foulborn = false
	self.vestigial = false
	self.mutatedLines = nil
	---@type RareLikeUniqueDescription?
	self.rareLikeUnique = nil
	local importedLevelReq
	local flaskBuffLines
	local tinctureBuffLines
	local deferJewelRadiusIndexAssignment
	local gameModeStage = "FINDIMPLICIT"
	local foundExplicit, foundImplicit
	local linePrefix = ""
	local linePostfix = ""

	while self.rawLines[l] do
		local line = self.rawLines[l]
		if line == "Veiled Prefix" or line == "Veiled Suffix" then
			self.veiled = true
		end
		if flaskBuffLines and flaskBuffLines[line] then
			flaskBuffLines[line] = nil
		elseif tinctureBuffLines and tinctureBuffLines[line] then
			tinctureBuffLines[line] = nil
		elseif line == "--------" then
			linePrefix = ""
			linePostfix = ""
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
		elseif line:match("Foil Unique") then
			local captured = line:match("%((.-)%)")
			self.foilType = captured or "Rainbow"
		elseif influenceItemMap[line] then
			self[influenceItemMap[line]] = true
		elseif line == "Requirements:" then
			-- nothing to do
		elseif line:match("^%(%a+") or line:match("^%(%d+%%? of ") then
			-- Reminder text, nothing to parse
			while self.rawLines[l] and not self.rawLines[l]:match("%)$") do
				l = l + 1
			end
		elseif self.base and self.base.flask and (
			line:match("^Lasts .+ Seconds$")
			or line:match("^Consumes %d+ of %d+ Charges on use$")
			or line:match("^Currently has %d+ Charges$")
		) then
			-- In-game flask state and base properties aren't modifier lines.
		elseif line:match("^{ ") then
			-- We're parsing advanced copy/paste format
			self.advancedCopy = true
			linePrefix = ""
			linePostfix = ""
			self.crafted = true
			local fullModName, modTags, increasedAmt = line:match("^{ (.-) %- (.-)  %- (%d*).*}$")
			if not fullModName then
				fullModName, modTags = line:match("^{ (.-) %- (.-) }$")
			end
			if not fullModName then
				fullModName = line:match("^{ (.-) }$")
			end
			local modName = fullModName:match("^.*Modifier \"(.*)\"")
			if modName and modName ~= "" and self.affixes then
				self.pendingAffixList = { }
				local backupAffixList = { }
				for modId, modData in pairs(self.affixes) do
					if modData.affix == modName then
						local ignoreModType = self.rareLikeUnique and self.rareLikeUnique.ignoreModType
						if self:CanHaveMod(modData) then
							if modData.type == "Prefix" or ignoreModType then
								t_insert(self.pendingAffixList, { modId = modId, table = self.prefixes })
							elseif modData.type == "Suffix" then
								t_insert(self.pendingAffixList, { modId = modId, table = self.suffixes })
							end
						else
							-- Conqueror mods can't natively spawn on items, so we'll use those if we don't find a match otherwise
							if modData.type == "Prefix" or ignoreModType then
								t_insert(backupAffixList, { modId = modId, table = self.prefixes })
							elseif modData.type == "Suffix" then
								t_insert(backupAffixList, { modId = modId, table = self.suffixes })
							end
						end
					end
				end
				if #self.pendingAffixList == 0 and #backupAffixList > 0 then
					self.pendingAffixList = backupAffixList
				end
				if #self.pendingAffixList == 0 and #backupAffixList == 0 then
					-- Could be a veiled, temple, or other custom mod, so just keep it around
					linePrefix = "{custom}"
				end
			elseif fullModName:match("(.*)Enhancement.*") then
				linePostfix = " (enchant)"
			end
			local possibleLineFlags = fullModName:gsub("Foulborn", "Mutated"):match("(.*)Modifier.*")
			if possibleLineFlags then
				for flag in possibleLineFlags:gmatch("%a+") do
					local flagLower = flag:lower()
					if lineFlags[flagLower] then
						linePrefix = linePrefix .. "{" .. flagLower .. "}"
					end
				end
			end
			if fullModName:match("^Allocated Crucible Passive Skill") then
				linePrefix = linePrefix .. "{crucible}"
			end
			if modTags and modTags ~= "" then
				linePrefix = linePrefix .. "{tags:" .. modTags:lower():gsub("%s+", "") .. "}"
			end
		else
			line = linePrefix .. line .. linePostfix
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
			local specName, specVal = line:match("^([%a %(%)]+:?): (.+)$")
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
				elseif specName == "Memory Strands" then
					self.memoryStrands = specToNumber(specVal)
				elseif specName == "Requires Class" then
					self.classRestriction = specVal
				elseif specName:match("Quality %([%a%s]+ Modifiers%)") then
					self.catalystQuality = specToNumber(specVal:match("(%d+)%%"))
					for i=1, #catalystDescriptorList do
						if specName:match("Quality %(([%a%s]+) Modifiers%)") == catalystDescriptorList[i] then
							self.catalyst = i
						end
					end
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
					self.jewelRadiusLabel = specVal:match("^[%a ]+")
					if specVal:match("^[%a ]+") == "Variable" then
						-- Jewel radius is variable and must be read from it's mods instead after they are parsed
						deferJewelRadiusIndexAssignment = true
					else
						for index, data in pairs(data.jewelRadius) do
							if specVal:match("^[%a ]+") == data.label then
								self.jewelRadiusIndex = index
								break
							end
						end
					end
				elseif specName == "Limited to" and self.type == "Jewel" then
					self.limit = specToNumber(specVal)
				elseif specName == "Version" then
					if not self.versionList then
						self.versionList = { }
					end
					t_insert(self.versionList, specVal)
					self.usesVariantGroups = true
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
				elseif specName == "Selected Version" then
					self.selectedVersion = specToNumber(specVal)
					self.usesVariantGroups = true
				elseif specName == "Selected Variant Group" then
					local groupId, variantId = specVal:match("^(%d+)%s*=%s*(%d+)$")
					if groupId and variantId then
						self.variantGroupSelections[tonumber(groupId)] = tonumber(variantId)
						self.usesVariantGroups = true
					end
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
				elseif specName == "Allow Duplicate Variants" then
					self.allowDuplicateVariants = specVal == "true"
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
				elseif specName == "Prefix" or specName == "Suffix" then
					local affixes = specName == "Prefix" and self.prefixes or self.suffixes
					local fractured = specVal:match("^{fractured}") and true
					specVal = specVal:gsub("^{fractured}", "")
					local range, affix = specVal:match("{range:([^}]+)}(.+)")
					if range and range:find(",", 1, true) then
						local ranges = { }
						for value in range:gmatch("[^,]+") do
							t_insert(ranges, tonumber(value))
						end
						range = ranges
					else
						range = tonumber(range)
					end
					if not range and (affix or specVal) ~= "None" then
						range = main.defaultItemAffixQuality
					end
					t_insert(affixes, {
						modId = affix or specVal,
						range = range,
						fractured = fractured,
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
				elseif specName == "Intangibility" then
					self.intangibility = specToNumber(specVal)
				elseif specName == "Note" then
					self.note = specVal
				elseif specName == "Str" or specName == "Strength" or specName == "Dex" or specName == "Dexterity" or
				       specName == "Int" or specName == "Intelligence" then
					self.requirements[specName:sub(1,3):lower()] = specToNumber(specVal)
				elseif specName == "Critical Strike Range" or specName == "Attacks per Second" or specName == "Weapon Range" or
				       specName == "Critical Strike Chance" or specName == "Physical Damage" or specName == "Elemental Damage" or
				       specName == "Chaos Damage" or specName == "Chance to Block" or specName == "Block chance" or
					specName == "Armour" or specName == "Energy Shield" or specName == "Evasion" then
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
					elseif k == "version" then
						modLine.versionList = { }
						for versionId in val:gmatch("%d+") do
							modLine.versionList[tonumber(versionId)] = true
						end
						self.usesVariantGroups = true
					elseif k == "group" then
						modLine.variantGroupList = { }
						for groupId in val:gmatch("%d+") do
							groupId = tonumber(groupId)
							if groupId and groupId > 0 then
								modLine.variantGroupList[groupId] = true
							end
						end
						self.usesVariantGroups = true
					elseif k == "tags" then
						for tag in val:gmatch("[%a_]+") do
							t_insert(modLine.modTags, tag)
						end
					elseif k == "modGroup" then
						modLine.modGroup = val
					elseif k == "range" then
						self.advancedCopy = true
						modLine.range = tonumber(val)
					elseif k == "corruptedRange" then
						modLine.corruptedRange = tonumber(val)
					elseif lineFlags[k] then
						modLine[k] = true
					end

					return ""
				end)
				if modLine.variantGroupList then
					if not modLine.variantList then
						ConPrintf("Grouped item line has no variant: %s", line)
					else
						for groupId in pairs(modLine.variantGroupList) do
							local group = self.variantGroups[groupId] or { }
							self.variantGroups[groupId] = group
							for variantId in pairs(modLine.variantList) do
								if self.variantList and self.variantList[variantId] then
									local versions = group[variantId] or { }
									group[variantId] = versions
									if modLine.versionList then
										for versionId in pairs(modLine.versionList) do
											if self.versionList and self.versionList[versionId] then
												versions[versionId] = true
											end
										end
									else
										versions[0] = true
									end
								else
									ConPrintf("Grouped item line references unknown variant %d: %s", variantId, line)
								end
							end
						end
					end
				end

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
				if modLine.vestigial then
					self.vestigial = true
				end

				local baseName
				-- items containing (#-#) lines are marked since the values won't have catalyst or mod magnitudes applied
				if line:find("%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)") then
					self.advancedCopy = true
				end
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
					baseName = line:gsub("^Superior ", ""):gsub("^Synthesised ", ""):gsub("^Vestigial ", "")
				end
				if baseName == "Two-Toned Boots" then
					baseName = "Two-Toned Boots (Armour/Energy Shield)"
				end
				local base = data.itemBases[baseName]
				if base then
					-- Items with variants can have multiple bases
					self.baseLines[baseName] = {
						line = baseName,
						variantList = modLine.variantList,
						versionList = modLine.versionList,
						variantGroupList = modLine.variantGroupList,
					}
					if self.usesVariantGroups and self.versionList and not self.selectedVersion then
						self.selectedVersion = #self.versionList
					end
					-- Set the actual base if variant matches or doesn't have variants
					local baseMatches = self.usesVariantGroups and self:CheckModLineVariant(modLine)
						or (not self.usesVariantGroups and (not self.variant or not modLine.variantList or modLine.variantList[self.variant]))
					if baseMatches then
						self.baseName = baseName
						if not (self.rarity == "NORMAL" or self.rarity == "MAGIC") then
							self.title = self.name
						end
						if self.rarity == "UNIQUE" and self.title
							-- the foulborn transformation on this item
							-- increases the radius, which isn't a mod line
							-- in PoB, which makes it incompatible with this
							-- approach
							and not self.title:lower():find("might of the meek") then
							self.mutatedLines = data.foulbornMap[self.title:gsub("^[Ff]oulborn ", "")]
						end
						self.type = base.type
						self.base = base
						self.affixes = (self.base.subType and data.itemMods[self.base.type..self.base.subType])
								or data.itemMods[self.base.type]
								or data.itemMods.Item
						if self.title then
							self.rareLikeUnique = data.rareLikeUniques[self.title:lower()]
							if self.rareLikeUnique then
								self.affixes = self.rareLikeUnique.affixes
							end
						end
						if self.base.flask then
							if self.base.utility_flask then
								self.enchantments = data.enchantments["UtilityFlask"]
							else
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
						if self.base.tincture and self.base.tincture.buff and not tinctureBuffLines then
							tinctureBuffLines = { }
							for _, line in ipairs(self.base.tincture.buff) do
								tinctureBuffLines[line] = true
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
				local catalystScalar = 1
				if line:match(" %- Unscalable Value$") then
					line = line:gsub(" %- Unscalable Value$", "")
					modLine.unscalable = true
				else
					catalystScalar = getCatalystScalar(self.catalyst, modLine, self.catalystQuality)
				end
				-- Advanced copy uses current(base) for fixed-value modifiers,
				-- in addition to the current(min-max) form handled below.
				line = line:gsub("(%-?%d+%.?%d*)%((%-?%d+%.?%d*)%)", "%1")
				if self.pendingAffixList and #self.pendingAffixList > 0 then
					if #self.pendingAffixList > 1 then
						-- Probably a conqueror or essence mod since the mod name is the same for all of them
						-- Try to match the line against one of the mods there
						local rangeLine = line:gsub("%-?%d+%.?%d*%(", "(")
						local valueStrippedLine = rangeLine:gsub("%-?%d+%.?%d*", "#")
						local exactAffix
						local fallbackAffix
						for _, pendingAffix in ipairs(self.pendingAffixList) do
							local modData = self.affixes[pendingAffix.modId]
							for _, modDataLine in ipairs(modData) do
								if line == modDataLine or rangeLine == modDataLine then
									exactAffix = pendingAffix
									break
								end
								if not fallbackAffix and valueStrippedLine == modDataLine:gsub("%-?%d+%.?%d*", "#") then
									fallbackAffix = pendingAffix
								end
							end
							if exactAffix then
								break
							end
						end
						self.pendingAffixList = { exactAffix or fallbackAffix or self.pendingAffixList[1] }
					end
					-- Use rolling Delta/Range in case one range is 1-3 and another is 1-100 so we get the finest precision possible
					local bestPrecisionDelta = -1
					local bestPrecisionRange = -1
					local rollRanges = { }
					local affixMod = self.affixes[self.pendingAffixList[1].modId]
					modLine.order = affixMod and affixMod.statOrder[1]
					for value, range in line:gmatch("(%-?%d+%.?%d*)%((%-?%d+%.?%d*%-%-?%d+%.?%d*)%)") do
						local min, max = range:match("(%-?%d+%.?%d*)%-(%-?%d+%.?%d*)")
						if tonumber(min) > tonumber(max) then
							min, max = max, min
						end
						local delta = tonumber(max) - min
						t_insert(rollRanges, delta > 0 and round((value - min) / delta, 6) or 0.5)
						line = line:gsub(value .. "%(" .. range:gsub("%-", "%%-") .. "%)", value)
						if delta > bestPrecisionDelta then
							bestPrecisionRange = round((value - min) / delta, 3)
							bestPrecisionDelta = delta
						end
					end
					t_insert(self.pendingAffixList[1].table, {
						modId = self.pendingAffixList[1].modId,
						-- Legacy modifiers can roll outside the current data range. Keep the
						-- extrapolated range so crafting a different affix doesn't normalise it.
						range = #rollRanges > 1 and rollRanges or bestPrecisionDelta > 0 and bestPrecisionRange or 0.5,
						fractured = modLine.fractured,
					})
					self.pendingAffixList = {}
				else
					local bestPrecisionDelta = -1
					local bestPrecisionRange = -1
					local firstRollRange
					local hasIndependentRolls

					-- Advanced copy only provides the endpoints for enum ranges; keep the selected value.
					line = line:gsub("(%s*)(%b())", function(space, range)
						if range:find("-", 1, true) and not range:find("%d") then
							return ""
						end
						return space .. range
					end)
					local advancedCopyLine = line

					for value, range in line:gmatch("(%-?%d+%.?%d*)%((%-?%d+%.?%d*%-%-?%d+%.?%d*)%)") do
						local min, max = range:match("(%-?%d+%.?%d*)%-(%-?%d+%.?%d*)")
						if tonumber(min) > tonumber(max) then
							min, max = max, min
						end
						local delta = tonumber(max) - min
						local rollRange = delta > 0 and round((value - min) / delta, 6) or 0.5
						if firstRollRange and firstRollRange ~= rollRange then
							hasIndependentRolls = true
						end
						firstRollRange = firstRollRange or rollRange
						if delta > bestPrecisionDelta then
							bestPrecisionRange = rollRange
							bestPrecisionDelta = delta
						end
						if bestPrecisionRange > 1 or bestPrecisionRange < 0 then
							line = line:gsub(value .. "%(" .. range:gsub("%-", "%%-") .. "%)", value)
						else
							line = line:gsub(value .. "%(" .. range:gsub("%-", "%%-") .. "%)", (tonumber(value) < 0 and "+" or "") .. "(" .. min .. "-" .. max .. ")")
						end
					end
					if hasIndependentRolls then
						line = advancedCopyLine:gsub("(%-?%d+%.?%d*)%(%-?%d+%.?%d*%-%-?%d+%.?%d*%)", "%1")
					elseif bestPrecisionRange <= 1 and bestPrecisionRange >= 0 then
						modLine.range = bestPrecisionRange
					end
				end
				local rangedLine = itemLib.applyRange(line, 1, catalystScalar, modLine.corruptedRange)
				local modList, extra = modLib.parseMod(rangedLine)
				local nextModGroup = self.rawLines[l + 1]
					and self.rawLines[l + 1]:match("{modGroup:([^}]+)}")
				-- Only combine generated lines that came from the same modifier.
				if (not modList or extra) and self.rawLines[l + 1]
					and modLine.modGroup == nextModGroup then
					-- Try to combine it with the next line
					local nextLine = self.rawLines[l+1]:gsub("%b{}", ""):gsub(" ?%(%l+%)","")
					local combLine = line.." "..nextLine
					rangedLine = itemLib.applyRange(combLine, 1, catalystScalar, modLine.corruptedRange)
					modList, extra = modLib.parseMod(rangedLine, true)
					if modList and not extra then
						line = line .. "\n" .. nextLine
						l = l + 1
					else
						modList, extra = modLib.parseMod(rangedLine)
					end
				end
				local lineLower = modLine.disabled and "" or line:lower()
				-- \d+% increased/reduced explicit/implicit/ *tags* modifier magnitudes
				local modMagnitudePattern = { "(%d+)%% ([ir][ne][cd][ru][ec][ae][sd]e?d?) ?([%a%s]*) modifier magnitudes",
					-- \d+% increased/reduced effect of suffixes/prefixes
					"(%d+)%% ([ir][ne][cd][ru][ec][ae][sd]e?d?) effect of ([sp][ur][fe]fix)es",
					-- eyes of the greatwolf
					"([%a%s]*) modifier magnitudes are doubled" }
				if lineLower == "implicit modifiers cannot be changed" then
					self.implicitsCannotBeChanged = true
				elseif lineLower:match(" prefix modifiers? allowed") then
					self.prefixes.limit = (self.prefixes.limit or 0) + (tonumber(lineLower:match("%+(%d+) prefix modifiers? allowed")) or 0) - (tonumber(lineLower:match("%-(%d+) prefix modifiers? allowed")) or 0)
				elseif lineLower:match(" suffix modifiers? allowed") then
					self.suffixes.limit = (self.suffixes.limit or 0) + (tonumber(lineLower:match("%+(%d+) suffix modifiers? allowed")) or 0) - (tonumber(lineLower:match("%-(%d+) suffix modifiers? allowed")) or 0)
				elseif lineLower:find("can be anointed") then -- blight uniques and Cord Belt
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
				elseif lineLower == "has elder, shaper and all conqueror influences" then
					self.HasElderShaperAndAllConquerorInfluences = true
					for _, curInfluenceInfo in ipairs(itemLib.influenceInfo.default) do
						self[curInfluenceInfo.key] = true
					end
				elseif lineLower:match("if the eater of worlds is dominant") then
					self.canHaveEldritchInfluence = true
				elseif lineLower == "has a crucible passive skill tree with only support passive skills" then
					self.canHaveOnlySupportSkillsCrucibleTree = true
				elseif lineLower == "has a crucible passive skill tree" then
					self.canHaveShieldCrucibleTree = true
				elseif lineLower == "has a two handed sword crucible passive skill tree" then
					self.canHaveTwoHandedSwordCrucibleTree = true
				elseif lineLower == "cannot roll caster modifiers" then
					self.restrictTag = true
					self.noCaster = true
				elseif lineLower == "cannot roll attack modifiers" then
					self.restrictTag = true
					self.noAttack = true
				elseif lineLower == "cannot roll modifiers of non-cold damage types" then
					self.restrictDamageType = true
					self.onlyColdDamage = true
				elseif lineLower == "cannot roll modifiers of non-fire damage types" then
					self.restrictDamageType = true
					self.onlyFireDamage = true
				elseif lineLower == "cannot roll modifiers of non-lightning damage types" then
					self.restrictDamageType = true
					self.onlyLightningDamage = true
				elseif lineLower == "cannot roll modifiers of non-chaos damage types" then
					self.restrictDamageType = true
					self.onlyChaosDamage = true
				elseif lineLower == "cannot roll modifiers of non-physical damage types" then
					self.restrictDamageType = true
					self.onlyPhysicalDamage = true
				end

				-- some tags might not match up exactly to tag strings. this has a list of exceptions
				local modMagnitudeTagMap = {
					defence = "defences",
					-- 3.29 eyes of the greatwolf
					enchantment = "enchant",
				}
				for _, pattern in ipairs(modMagnitudePattern) do
					if not modLine.disabled and rangedLine:lower():find(pattern) then
						local rangedLine = itemLib.applyRange(line, modLine.range or main.defaultItemAffixQuality or 1, catalystScalar, modLine.corruptedRange)
						local amount, increaseOrDecrease, modTagsString = rangedLine:lower():match(pattern)
						local multiplier
						-- "are doubled" format -> swap variables
						if amount and not (increaseOrDecrease or modTagsString) then
							modTagsString = amount
							amount = 100
							increaseOrDecrease = "increased"
							multiplier = 2
						end
						if amount and modTagsString and (increaseOrDecrease == "increased" or increaseOrDecrease == "reduced") then
							local modTags = {}
							local modType
							local quality = increaseOrDecrease == "increased" and tonumber(amount) or -tonumber(amount)
							if modTagsString == "explicit physical and chaos damage" then
								table.insert(self.modMagnitudeMods, { tags = { "damage" }, anyTags = { "physical", "chaos" }, quality = quality, modType = "explicit" })
							else
								-- explicit elemental damage -> tags = {elemental, damage}, modType = explicit
								for word in (modTagsString .. " "):gmatch("%S+") do
									word = word:lower()
									word = modMagnitudeTagMap[word] or word
									if word == "implicit" or word == "explicit" or word == "enchant" then
										modType = word
									else
										table.insert(modTags, word)
									end
								end
								table.insert(self.modMagnitudeMods, { tags = modTags, quality = quality, multiplier = multiplier, modType = modType })
							end
							break
						end
					end
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
						modLine.range = main.defaultItemAffixQuality
						t_insert(modLines, modLine)
					elseif gameModeStage == "FINDEXPLICIT" then
						gameModeStage = "DONE"
					end
				elseif foundExplicit or (not foundExplicit and gameModeStage == "EXPLICIT") then
					modLine.modList = { }
					modLine.extra = line
					t_insert(modLines, modLine)
				end
			end
		end
		::continue::
		l = l + 1
	end
	if self.advancedCopy and (self.rarity == "UNIQUE" or self.rarity == "RELIC") then
		if not uniqueModStatOrder then
			uniqueModStatOrder = { exact = { }, normalised = { } }
			for _, mod in pairs(data.itemMods.ItemExclusive) do
				for index, line in ipairs(mod) do
					local exactLine = line:lower():gsub("\n", " ")
					local statLine = normaliseModLine(line)
					uniqueModStatOrder.exact[exactLine] = m_min(uniqueModStatOrder.exact[exactLine] or math.huge, mod.statOrder[index])
					uniqueModStatOrder.normalised[statLine] = m_min(uniqueModStatOrder.normalised[statLine] or math.huge, mod.statOrder[index])
				end
			end
		end
		for _, modLine in ipairs(self.explicitModLines) do
			local exactLine = modLine.line:lower():gsub("\n", " ")
			modLine.order = uniqueModStatOrder.exact[exactLine]
				or uniqueModStatOrder.normalised[normaliseModLine(modLine.line)]
		end
	end
	if self.base and #self.sockets > 0 then
		-- In-game requirement totals include requirements from socketed gems.
		-- Derive the item's attribute requirements from its base and local mods instead.
		self.requirements.str = self.base.req.str or 0
		self.requirements.dex = self.base.req.dex or 0
		self.requirements.int = self.base.req.int or 0
	end
	if self.base and not self.requirements.level then
		if importedLevelReq and #self.sockets == 0 then
			-- Requirements on imported items can only be trusted for items with no sockets
			self.requirements.level = importedLevelReq
		else
			self.requirements.level = self.base.req.level
		end
	end
	-- hack for cane of kulemak
	if ((self.title and self.title:lower()) == "cane of kulemak") and (self.rarity == "UNIQUE" or self.rarity == "RELIC") and self.advancedCopy then
		for _, mod in ipairs(self.explicitModLines) do
			if not mod.line:match("magnitude") then
				mod.unveiled = true
			end
		end
	end
	if self.advancedCopy or self.crafted then
		-- apply mod magnitude boost to matching mods
		if #self.modMagnitudeMods > 0 then
			for _, modMagnitudeMod in ipairs(self.modMagnitudeMods) do
				local modLists
				if modMagnitudeMod.modType then
					modLists = { self[modMagnitudeMod.modType .. "ModLines"] }
				else
					modLists = { self.implicitModLines, self.explicitModLines, self.enchantModLines }
				end
				for _, mods in ipairs(modLists) do
					for _, mod in ipairs(mods or {}) do
						-- avoid scaling variant lines which are not active
						if mod.variantList and (self:GetModLineVariantCount(mod) == 0) then
							goto modMagnitudeContinue
						end
						-- Create a fast lookup table for all provided tags
						local tagLookup = {}
						for _, curTag in ipairs(mod.modTags) do
							tagLookup[curTag] = true;
						end
						-- these aren't actual mod tags but do appear in mod magnitude mods
						for _, lineFlag in ipairs({ "unveiled", "prefix", "suffix" }) do
							if mod[lineFlag] then
								tagLookup[lineFlag] = true
							end
						end
						local match = true
						for _, magnitudeTag in ipairs(modMagnitudeMod.tags) do
							if not tagLookup[magnitudeTag] then
								match = false
							end
						end
						if modMagnitudeMod.anyTags and not (tagLookup[modMagnitudeMod.anyTags[1]] or tagLookup[modMagnitudeMod.anyTags[2]]) then
							match = false
						end
						if match and not mod.unscalable then
							if modMagnitudeMod.multiplier then
								mod.valueScalar = (mod.valueScalar or 1) * modMagnitudeMod.multiplier
							else
								mod.valueScalar = (mod.valueScalar or 1) + (modMagnitudeMod.quality / 100)
							end
						end
						if mod.valueScalar and mod.valueScalar ~= 1 then
							local rangedLine = itemLib.applyRange(mod.line, mod.range or 1, mod.valueScalar, 1)
							local modList, extra = modLib.parseMod(rangedLine)
							mod.displayValueScalar = 1
							mod.modList = modList
							mod.extra = extra
						end
						::modMagnitudeContinue::
					end
				end
			end
		end
	end
	if self.advancedCopy and #self.explicitModLines > 1 then
		sortCraftedModLines(self.explicitModLines)
	end
	self.affixLimit = 0
	if self.crafted then
		if not self.affixes then
			self.crafted = false
		elseif self.rarity == "MAGIC" then
			if self.prefixes.limit or self.suffixes.limit then
				self.prefixes.limit = m_max(m_min((self.prefixes.limit or 0) + 1, 2), 0)
				self.suffixes.limit = m_max(m_min((self.suffixes.limit or 0) + 1, 2), 0)
				self.affixLimit = self.prefixes.limit + self.suffixes.limit
			else
				self.affixLimit = 2
			end
		elseif self.rarity == "RARE" then
			self.affixLimit = (((self.type == "Jewel" and not (self.base.subType == "Abyss" and self.corrupted)) or self.type == "Graft") and 4 or 6)
			if self.prefixes.limit or self.suffixes.limit then
				self.prefixes.limit = m_max(m_min((self.prefixes.limit or 0) + self.affixLimit / 2, self.affixLimit), 0)
				self.suffixes.limit = m_max(m_min((self.suffixes.limit or 0) + self.affixLimit / 2, self.affixLimit), 0)
				self.affixLimit = self.prefixes.limit + self.suffixes.limit
			end
		elseif self.rareLikeUnique then
			self.prefixes.limit = self.rareLikeUnique.prefixLimit
			self.suffixes.limit = self.rareLikeUnique.suffixLimit
			self.affixLimit = self.prefixes.limit + self.suffixes.limit
		else
			self.crafted = false
		end
		if self.crafted then
			for _, list in ipairs({self.prefixes,self.suffixes}) do
				for i = 1, (list.limit or (self.affixLimit / 2)) do
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
	if self.usesVariantGroups then
		self:NormaliseVariantSelections()
	elseif self.variantList then
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
	if self.mutatedLines then
		-- Match both sides so the same checkbox can apply or revert the transformation.
		for origModId, foulModId in pairs(self.mutatedLines) do
			local function checkMod(modId, newModId, mutated)
				local originalMod = mutated and data.itemMods.Foulborn[modId] or data.itemMods.ItemExclusive[modId]
				if not originalMod then
					ConPrintf("mod not found while testing mutated mods %s, %s", modId, mutated)
					return
				end
				local function findMatchingLines(lines)
					local matchingLines = {}
					local matchedLines = {}
					for _, line in ipairs(lines) do
						local statLine = normaliseModLine(line)
						for _, modLine in ipairs(self.explicitModLines) do
							if not matchedLines[modLine]
								and normaliseModLine(modLine.line) == statLine
								and self:CheckModLineVariant(modLine) then
								matchedLines[modLine] = true
								t_insert(matchingLines, modLine)
								break
							end
						end
					end
					return #lines == #matchingLines and matchingLines
				end
				-- Some modifier descriptions are represented by separate lines in PoB.
				local matchingLines = findMatchingLines({ table.concat(originalMod, " ") })
					or findMatchingLines(originalMod)
				if matchingLines then
					for _, modLine in ipairs(matchingLines) do
						modLine.modId = modId
						modLine.newModId = newModId
						if mutated then
							modLine.mutated = true
						end
					end
				end
			end
			-- check if there are foulborn source mods
			checkMod(origModId, foulModId)
			-- check if there are foulborn mods which can be reverted, and mark
			-- them as mutated as in case they are missing the flag
			checkMod(foulModId, origModId, true)
		end
	end
	for _, v in ipairs(self.explicitModLines) do
		if v.mutated then
			self.foulborn = true
		end
	end
	-- ensure that foulborn items have the name prefix
	local hasFoulbornPrefix = self.title and self.title:lower():find("^foulborn ")
	if self.foulborn and not hasFoulbornPrefix then
		self.title = "Foulborn " .. self.title
	elseif not self.foulborn and hasFoulbornPrefix then
		self.title = self.title:gsub("[Ff]oulborn ", "")
	end
	if self.baseName and self.title then
		self.name = self.title .. ", " .. self.baseName:gsub(" %(.+%)", "")
	end
	if not self.quality then
		self:NormaliseQuality()
		if highQuality then
			-- Behavior of NormaliseQuality should be looked at because calling it twice has different results.
			-- Leaving it alone for now. Just moving it here from Main.lua so BuildAndParseRaw doesn't need to be called.
			self:NormaliseQuality()
		end
	end
	if self.base and self.base.enchant and #self.enchantModLines == 0 then
		local enchantIndex = 1
		for line in self.base.enchant:gmatch("[^\n]+") do
			local modList, extra = modLib.parseMod(line)
			t_insert(self.enchantModLines, {
				line = line,
				crafted = true,
				implicit = true,
				enchant = true,
				extra = extra,
				modList = modList or { },
				modTags = self.base.enchantModTypes and self.base.enchantModTypes[enchantIndex] or { },
			})
			enchantIndex = enchantIndex + 1
		end
	end
	self:BuildModList()
	if deferJewelRadiusIndexAssignment then
		self.jewelRadiusIndex = self.jewelData.radiusIndex
	end
end

---@param modId string The id which will be present on the removed mod lines
---@param newModId string Id of the new mod which is used to get the new mod lines
---@param mutatedValue boolean? Whether the new mod is a mutated line. Also determines what table the new mod is taken from.
function ItemClass:MutateMod(modId, newModId, mutatedValue)
	local newMod = mutatedValue and data.itemMods.Foulborn[newModId] or data.itemMods.ItemExclusive[newModId]
	if not newMod then
		ConPrintf("Invalid mod id given to MutateMod: %s, %s, %s", modId, newModId, mutatedValue)
		return
	end
	local i = 1
	-- where we will reinsert the mod lines
	local insertIdx
	local variantList
	local versionList
	local variantGroupList
	while self.explicitModLines[i] do
		local modLine = self.explicitModLines[i]
		if modLine.modId == modId and self:CheckModLineVariant(modLine) then
			if not insertIdx then
				insertIdx = i
				variantList = modLine.variantList
				versionList = modLine.versionList
				variantGroupList = modLine.variantGroupList
			end
			table.remove(self.explicitModLines, i)
		else
			i = i + 1
		end
	end
	table.insert(self.explicitModLines, insertIdx, {
		line = table.concat(newMod, "\n"),
		modTags = newMod.modTags,
		variantList = variantList,
		versionList = versionList,
		variantGroupList = variantGroupList,
		mutated = mutatedValue,
		modGroup = newModId,
	})
	self:BuildAndParseRaw()
end
function ItemClass:NormaliseQuality()
	if self.base and (self.base.armour or self.base.weapon or self.base.flask or self.base.tincture) then
		if not self.quality then
			self.quality = 0
		elseif not self.uniqueID and not self.corrupted and not self.split and not self.mirrored and self.quality < 20 then
			self.quality = 20
		end
	end
end

function ItemClass:GetModSpawnWeight(mod, includeTags, excludeTags, baseTags)
	local weight = 0
	if self.base then
		baseTags = baseTags or self.base.tags
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
		if self.restrictTag then
			for _, key in ipairs(mod.modTags) do
				local flagName = "no" .. key:gsub("^%l", string.upper)
				if flagName and self[flagName] then
					return 0
				end
			end
		end
		if self.restrictDamageType then
			local required, restricted = false, {}
			for _, element in ipairs({ "fire", "cold", "lightning", "chaos", "physical" }) do
				local flagName = "only" .. element:gsub("^%l", string.upper) .. "Damage"
				if self[flagName] then
					required = true
				else
					restricted[element] = true
				end
			end
			if required then
				for _, key in ipairs(mod.modTags) do
					if restricted[key] then
						return 0
					end
				end
			end
		end

		for i, key in ipairs(mod.weightKey) do
			if (baseTags[key] or (includeTags and includeTags[key]) or HasInfluenceTag(key)) and not (excludeTags and excludeTags[key]) then
				weight = (HasInfluenceTag(key) and HasMavenInfluence(mod.affix)) and 1000 or mod.weightVal[i]
				break
			end
		end
		for i, key in ipairs(mod.weightMultiplierKey or {}) do
			if (baseTags[key] or (includeTags and includeTags[key]) or HasInfluenceTag(key)) and not (excludeTags and excludeTags[key]) then
				weight = weight * mod.weightMultiplierVal[i] / 100
				break
			end
		end
	end
	return weight
end

function ItemClass:GetNecropolisModSpawnWeight(mod)
	local weight = 0
	if self.base then
		for i, key in ipairs(mod.weightKey) do
			if self.base.tags[key:gsub("necropolis_", "")] then
				weight = mod.weightVal[i]
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
	if self.intangibility then
		t_insert(rawLines, string.format("Intangibility: %d%%", self.intangibility))
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
		for _, affix in ipairs(self.prefixes or { }) do
			local range = affix.range and "{range:" .. (type(affix.range) == "table" and table.concat(affix.range, ",") or round(affix.range, 3)) .. "}" or ""
			t_insert(rawLines, "Prefix: " .. (affix.fractured and "{fractured}" or "") .. range .. affix.modId)
		end
		for _, affix in ipairs(self.suffixes or { }) do
			local range = affix.range and "{range:" .. (type(affix.range) == "table" and table.concat(affix.range, ",") or round(affix.range, 3)) .. "}" or ""
			t_insert(rawLines, "Suffix: " .. (affix.fractured and "{fractured}" or "") .. range .. affix.modId)
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
	if self.memoryStrands then
		t_insert(rawLines, "Memory Strands: " .. self.memoryStrands)
	end
	local function writeModLine(modLine)
		local line = modLine.line
		local function prependToAllLines(prefix)
			line = prefix .. line:gsub("\n", "\n" .. prefix)
		end
		local function makeIdSpec(idList)
			local ids = { }
			for id in pairsSortByKey(idList) do
				t_insert(ids, id)
			end
			return table.concat(ids, ",")
		end
		if modLine.range and line:match("%(%-?[%d%.]+%-%-?[%d%.]+%)") then
			line = "{range:" .. round(modLine.range, 6) .. "}" .. line
		end
		if modLine.corruptedRange then
			line = "{corruptedRange:" .. round(modLine.corruptedRange, 2) .. "}" .. line
		end
		if modLine.disabled then
			line = "{disabled}" .. line
		end
		if modLine.crafted then
			line = "{crafted}" .. line
		end
		if modLine.enchant then
			line = "{enchant}" .. line
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
		-- ggg tag for cultivated/foulborn mod
		if modLine.mutated then
			line = "{mutated}" .. line
		end
		if modLine.modGroup then
			local modGroup = "{modGroup:" .. modLine.modGroup .. "}"
			line = modGroup .. line:gsub("\n", "\n" .. modGroup)
		end
		if modLine.fractured then
			line = "{fractured}" .. line
		end
		if modLine.prefix then
			line = "{prefix}" .. line
		end
		if modLine.suffix then
			line = "{suffix}" .. line
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
		if modLine.unscalable then
			line = "{unscalable}" .. line
		end
		if modLine.vestigial then
			line = "{vestigial}" .. line
		end
		local hasNewSelection = modLine.versionList or modLine.variantGroupList
		if hasNewSelection and modLine.modTags and #modLine.modTags > 0 then
			line = "{tags:" .. table.concat(modLine.modTags, ",") .. "}" .. line
		end
		if modLine.variantGroupList then
			prependToAllLines("{group:" .. makeIdSpec(modLine.variantGroupList) .. "}")
		end
		if modLine.variantList then
			prependToAllLines("{variant:" .. makeIdSpec(modLine.variantList) .. "}")
		end
		if modLine.versionList then
			prependToAllLines("{version:" .. makeIdSpec(modLine.versionList) .. "}")
		end
		if not hasNewSelection and modLine.modTags and #modLine.modTags > 0 then
			line = "{tags:" .. table.concat(modLine.modTags, ",") .. "}" .. line
		end
		t_insert(rawLines, line)
	end
	if self.versionList then
		for _, versionName in ipairs(self.versionList) do
			t_insert(rawLines, "Version: " .. versionName)
		end
		if self.selectedVersion then
			t_insert(rawLines, "Selected Version: " .. self.selectedVersion)
		end
	end
	if self.variantList then
		for _, variantName in ipairs(self.variantList) do
			t_insert(rawLines, "Variant: " .. variantName)
		end
		if self.usesVariantGroups then
			for groupId in pairsSortByKey(self.variantGroups) do
				local variantId = self.variantGroupSelections[groupId]
				if variantId then
					t_insert(rawLines, "Selected Variant Group: " .. groupId .. "=" .. variantId)
				end
			end
		else
			t_insert(rawLines, "Selected Variant: " .. self.variant)
		end

		for _, baseLine in pairs(self.baseLines or { }) do
			if baseLine.variantList or baseLine.versionList or baseLine.variantGroupList then
				writeModLine(baseLine)
			end
		end
		if not self.usesVariantGroups and self.hasAltVariant then
			t_insert(rawLines, "Has Alt Variant: true")
			t_insert(rawLines, "Selected Alt Variant: " .. self.variantAlt)
		end
		if not self.usesVariantGroups and self.hasAltVariant2 then
			t_insert(rawLines, "Has Alt Variant Two: true")
			t_insert(rawLines, "Selected Alt Variant Two: " .. self.variantAlt2)
		end
		if not self.usesVariantGroups and self.hasAltVariant3 then
			t_insert(rawLines, "Has Alt Variant Three: true")
			t_insert(rawLines, "Selected Alt Variant Three: " .. self.variantAlt3)
		end
		if not self.usesVariantGroups and self.hasAltVariant4 then
			t_insert(rawLines, "Has Alt Variant Four: true")
			t_insert(rawLines, "Selected Alt Variant Four: " .. self.variantAlt4)
		end
		if not self.usesVariantGroups and self.hasAltVariant5 then
			t_insert(rawLines, "Has Alt Variant Five: true")
			t_insert(rawLines, "Selected Alt Variant Five: " .. self.variantAlt5)
		end
		if self.allowDuplicateVariants then
			t_insert(rawLines, "Allow Duplicate Variants: true")
		end
	end
	if not self.variantList then
		for _, baseLine in pairs(self.baseLines or { }) do
			if baseLine.versionList or baseLine.variantGroupList then
				writeModLine(baseLine)
			end
		end
	end
	if self.quality then
		t_insert(rawLines, "Quality: " .. self.quality)
	end
	if self.sockets and #self.sockets > 0 then
		local line = "Sockets: "
		for i, socket in ipairs(self.sockets) do
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
	if self.fractured then
		t_insert(rawLines, "Fractured Item")
	end
	if self.corrupted or self.scourge then
		t_insert(rawLines, "Corrupted")
	end
	if self.foilType then
		t_insert(rawLines, "Foil Unique" .. " (" .. self.foilType .. ")")
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
		if mod.crafted or mod.custom or (self.rareLikeUnique and not (mod.prefix or mod.suffix)) then
			t_insert(savedMods, mod)
		end
	end

	wipeTable(self.explicitModLines)
	self.namePrefix = ""
	self.nameSuffix = ""
	self.requirements.level = self.base.req.level
	local statOrder = { }
	for _, list in ipairs({ self.prefixes, self.suffixes }) do
		for i = 1, (list.limit or (self.affixLimit / 2)) do
			local affix = list[i]
			if not affix then
				list[i] = { modId = "None" }
			end
			local mod = self.affixes[affix.modId]
			if mod then
				if mod.type == "Prefix" then
					self.namePrefix = mod.affix .. " " .. self.namePrefix
				elseif mod.type == "Suffix" then
					self.nameSuffix = self.nameSuffix .. " " .. mod.affix
				end
				self.requirements.level = m_max(self.requirements.level or 0, m_floor(mod.level * 0.8))
				for i, line in ipairs(mod) do
					line = itemLib.applyRange(line, affix.range or 0.5)
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
						local modLine = { line = line, order = order, type = mod.type, modTags = mod.modTags or { }, fractured = affix.fractured }
						if mod.type == "Prefix" then
							modLine.prefix = true
						elseif mod.type == "Suffix" then
							modLine.suffix = true
						end
						t_insert(self.explicitModLines, modLine)
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
	if #self.explicitModLines > 1 then
		sortCraftedModLines(self.explicitModLines)
	end

	self:BuildAndParseRaw()
end

function ItemClass:CheckModLineVariant(modLine)
	if self.usesVariantGroups then
		if modLine.versionList and (not self.selectedVersion or not modLine.versionList[self.selectedVersion]) then
			return false
		end
		if modLine.variantGroupList then
			if not modLine.variantList then
				return false
			end
			for groupId in pairs(modLine.variantGroupList) do
				local selectedVariant = self.variantGroupSelections[groupId]
				if selectedVariant and modLine.variantList[selectedVariant] then
					return true
				end
			end
			return false
		end
		return not modLine.variantList
	end
	return not modLine.variantList
		or modLine.variantList[self.variant]
		or (self.hasAltVariant and modLine.variantList[self.variantAlt])
		or (self.hasAltVariant2 and modLine.variantList[self.variantAlt2])
		or (self.hasAltVariant3 and modLine.variantList[self.variantAlt3])
		or (self.hasAltVariant4 and modLine.variantList[self.variantAlt4])
		or (self.hasAltVariant5 and modLine.variantList[self.variantAlt5])
end

function ItemClass:GetModLineVariantCount(modLine)
	if not self.allowDuplicateVariants or not modLine.variantList then
		return self:CheckModLineVariant(modLine) and 1 or 0
	end

	-- Mageblood can intentionally select the same variant more than once.
	local variantList = modLine.variantList
	local count = variantList[self.variant] and 1 or 0
	for i = 1, 5 do
		local suffix = i == 1 and "" or i
		local variant = self["variantAlt" .. suffix]
		if self["hasAltVariant" .. suffix] and variant and variantList[variant] then
			count = count + 1
		end
	end
	return count
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
	elseif self.type == "Tincture" then
		return "Flask 1"
	elseif self.type == "Graft" then
		return "Graft 1"
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

-- Build list of modifiers in a given slot number while applying local modifiers and adding quality
function ItemClass:BuildModListForSlotNum(baseList, slotNum)
	local slotName = self:GetPrimarySlot()
	if slotNum ~= 1 then
		slotName = slotName:gsub("1", tostring(slotNum))
	end
	local modList = new("ModList"):ModList()
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
		local groupCounts = {}
		for _, socket in ipairs(self.sockets) do
			local group = socket.group
    		groupCounts[group] = (groupCounts[group] or 0) + 1
			if multiName[socket.color] then
				modList:NewMod(multiName[socket.color], "BASE", 1, "Item Sockets")
			end
		end
		local unlinkedSockets = 0
		for _, count in pairs(groupCounts) do
			if count == 1 then
				unlinkedSockets = unlinkedSockets + 1
			end
		end
		modList:NewMod("Multiplier:UnlinkedSocketIn"..slotName, "BASE", unlinkedSockets, "Unlinked Item Sockets")
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
		weaponData.subType = self.base.subType
		weaponData.name = self.name
		weaponData.AttackSpeedInc = calcLocal(modList, "Speed", "INC", ModFlag.Attack) + m_floor(self.quality / 8 * calcLocal(modList, "AlternateQualityLocalAttackSpeedPer8Quality", "INC", 0))
		weaponData.AttackRate = round(self.base.weapon.AttackRateBase * (1 + weaponData.AttackSpeedInc / 100), 2)
		weaponData.rangeBonus = calcLocal(modList, "WeaponRange", "BASE", 0) + 10 * calcLocal(modList, "WeaponRangeMetre", "BASE", 0) + m_floor(self.quality / 10 * calcLocal(modList, "AlternateQualityLocalWeaponRangePer10Quality", "BASE", 0))
		weaponData.range = self.base.weapon.Range + weaponData.rangeBonus
		local LocalIncEle = calcLocal(modList, "LocalElementalDamage", "INC", 0)
		for _, dmgType in ipairs(dmgTypeList) do
			local min = (self.base.weapon[dmgType.."Min"] or 0) + calcLocal(modList, dmgType.."Min", "BASE", 0)
			local max = (self.base.weapon[dmgType.."Max"] or 0) + calcLocal(modList, dmgType.."Max", "BASE", 0)
			if dmgType == "Physical" then
				local physInc = calcLocal(modList, "PhysicalDamage", "INC", 0)
				local qualityScalar = self.quality
				if calcLocal(modList, "AlternateQualityWeapon", "BASE", 0) > 0 then
					qualityScalar = 0
				end
				min = round(min * (1 + physInc / 100) * (1 + qualityScalar / 100))
				max = round(max * (1 + physInc / 100) * (1 + qualityScalar / 100))
			elseif dmgType ~= "Physical" and dmgType ~= "Chaos" then
				local localInc = calcLocal(modList, "Local"..dmgType.."Damage", "INC", 0) + LocalIncEle
				min = round(min * (1 + localInc / 100))
				max = round(max * (1 + localInc / 100))
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
		for _, dmgType in ipairs(dmgTypeList) do
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
			armourData.ArmourBasePercentile = ((armourData.Armour / ((1 + (armourInc + armourEvasionInc + armourEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100))) - armourBase)) / armourVariance
			armourData.ArmourBasePercentile = round(m_max(m_min(armourData.ArmourBasePercentile, 1), 0), 4)
		end
		if armourData.Evasion and armourData.Evasion > 0 and not armourData.EvasionBasePercentile then
			armourData.EvasionBasePercentile = ((armourData.Evasion / ((1 + (evasionInc + armourEvasionInc + evasionEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100))) - evasionBase)) / evasionVariance
			armourData.EvasionBasePercentile = round(m_max(m_min(armourData.EvasionBasePercentile, 1), 0), 4)
		end
		if armourData.EnergyShield and armourData.EnergyShield > 0 and not armourData.EnergyShieldBasePercentile then
			armourData.EnergyShieldBasePercentile = ((armourData.EnergyShield / ((1 + (energyShieldInc + armourEnergyShieldInc + evasionEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100))) - energyShieldBase)) / energyShieldVariance
			armourData.EnergyShieldBasePercentile = round(m_max(m_min(armourData.EnergyShieldBasePercentile, 1), 0), 4)
		end
		if armourData.Ward and armourData.Ward > 0 and not armourData.WardBasePercentile then
			armourData.WardBasePercentile = ((armourData.Ward / ((1 + (wardInc + defencesInc) / 100) * (1 + (qualityScalar / 100))) - wardBase)) / wardVariance
			armourData.WardBasePercentile = round(m_max(m_min(armourData.WardBasePercentile, 1), 0),4)
		end

		armourData.Armour = round((armourBase + armourEvasionBase + armourEnergyShieldBase + armourVariance * (armourData.ArmourBasePercentile or 1)) * (1 + (armourInc + armourEvasionInc + armourEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100)))
		armourData.Evasion = round((evasionBase + armourEvasionBase + evasionEnergyShieldBase + evasionVariance * (armourData.EvasionBasePercentile or 1)) * (1 + (evasionInc + armourEvasionInc + evasionEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100)))
		armourData.EnergyShield = round((energyShieldBase + evasionEnergyShieldBase + armourEnergyShieldBase + energyShieldVariance * (armourData.EnergyShieldBasePercentile or 1)) * (1 + (energyShieldInc + armourEnergyShieldInc + evasionEnergyShieldInc + defencesInc) / 100) * (1 + (qualityScalar / 100)))
		armourData.Ward = round((wardBase + wardVariance * (armourData.WardBasePercentile or 1)) * (1 + (wardInc + defencesInc) / 100) * (1 + (qualityScalar / 100)))

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
			armourData.BlockChance = m_floor((self.base.armour.BlockChance + calcLocal(modList, "BlockChance", "BASE", 0)) * (1 + calcLocal(modList, "BlockChance", "INC", 0) / 100))
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
			flaskData.instantLowLifePerc = calcLocal(modList, "FlaskLowLifeInstantRecovery", "BASE", 0)
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
			flaskData.duration = round(self.base.flask.duration * (1 + durationInc / 100) * (1 + self.quality / 100) * durationMore, 1)
		end
		flaskData.chargesMax = self.base.flask.chargesMax + calcLocal(modList, "FlaskCharges", "BASE", 0)
		flaskData.chargesUsed = m_floor(self.base.flask.chargesUsed * (1 + calcLocal(modList, "FlaskChargesUsed", "INC", 0) / 100))
		flaskData.gainMod = 1 + calcLocal(modList, "FlaskChargeRecovery", "INC", 0) / 100
		flaskData.effectInc = calcLocal(modList, "FlaskEffect", "INC", 0) + calcLocal(modList, "LocalEffect", "INC", 0)
		for _, value in ipairs(modList:List(nil, "FlaskData")) do
			flaskData[value.key] = value.value
		end
	elseif self.base.tincture then
		local tinctureData = self.tinctureData
		tinctureData.manaBurn = (self.base.tincture.manaBurn + 0.01) / (1 + calcLocal(modList, "TinctureManaBurnRate", "INC", 0) / 100) / (1 + calcLocal(modList, "TinctureManaBurnRate", "MORE", 0) / 100)
		tinctureData.cooldownInc = calcLocal(modList, "TinctureCooldownRecovery", "INC", 0) + calcLocal(modList, "CooldownRecovery", "INC", 0)
		tinctureData.cooldown = self.base.tincture.cooldown / (1 + tinctureData.cooldownInc / 100)
		tinctureData.effectInc = calcLocal(modList, "TinctureEffect", "INC", 0) + calcLocal(modList, "LocalEffect", "INC", 0)
		for _, value in ipairs(modList:List(nil, "TinctureData")) do
			tinctureData[value.key] = value.value
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
			if self.clusterJewel.size == "Small" and jewelData.clusterJewelSkill == "affliction_curse_effect" then
				jewelData.clusterJewelSkill = "affliction_curse_effect_small"
			elseif self.clusterJewel.size == "Medium" and jewelData.clusterJewelSkill == "affliction_curse_effect_small" then
				jewelData.clusterJewelSkill = "affliction_curse_effect"
			end

			-- Validation
			if jewelData.clusterJewelNodeCount then
				jewelData.clusterJewelNodeCount = m_min(m_max(jewelData.clusterJewelNodeCount, self.clusterJewel.minNodes), self.clusterJewel.maxNodes)
			end
			if jewelData.clusterJewelSkill and not self.clusterJewel.skills[jewelData.clusterJewelSkill] then
				jewelData.clusterJewelSkill = nil
			end
			-- Set missing crafting fields when using advanced copy
			self.clusterJewelSkill = self.clusterJewelSkill or jewelData.clusterJewelSkill
			self.clusterJewelNodeCount = self.clusterJewelNodeCount or jewelData.clusterJewelNodeCount
			jewelData.clusterJewelValid = jewelData.clusterJewelKeystone 
				or ((jewelData.clusterJewelSkill or jewelData.clusterJewelSmallsAreNothingness) and jewelData.clusterJewelNodeCount) 
				or (jewelData.clusterJewelSocketCountOverride and jewelData.clusterJewelNothingnessCount)
		end
	end
	return { unpack(modList) }
end

local function getRangedModList(item, modLine)
	if not modLine.range or not modLine.line:find("%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)") then
		return
	end
	local line = itemLib.applyRange(modLine.line:gsub("\n", " "), modLine.range, modLine.valueScalar, modLine.corruptedRange)
	local list, extra = modLib.parseMod(line)
	if itemLib.isZeroValueLine(line) then
		return {}
	end
	return not extra and list
end
-- Build lists of modifiers for each slot the item can occupy
function ItemClass:BuildModList()
	if not self.base then
		return
	end
	local baseList = new("ModList"):ModList()
	if self.base.weapon then
		self.weaponData = { }
	elseif self.base.armour then
		self.armourData = self.armourData or { }
	elseif self.base.flask then
		self.flaskData = { }
		self.buffModList = { }
	elseif self.base.tincture then
		self.tinctureData = { }
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
		if modLine.disabled then
			return
		end
		local variantCount = self:GetModLineVariantCount(modLine)
		if variantCount > 0 then
			-- special section for variant over-ride of pre-modifier item parameters
			if modLine.line:find("Requires Class") then
				self.classRestriction = modLine.line:gsub("{variant:([%d,]+)}", ""):match("Requires Class (.+)")
			end
			-- handle understood modifier variable properties
			local rangedModList = not modLine.extra and getRangedModList(self, modLine)
			if rangedModList then
				modLine.modList = rangedModList
				modLine.showSlider = true
				t_insert(self.rangeLineList, modLine)
			elseif modLine.modId and modLine.newModId then
				-- mutated mod transformation available
				t_insert(self.rangeLineList, modLine)
			end
			if not modLine.extra then
				for _, mod in ipairs(modLine.modList) do
					for _ = 1, variantCount do
						baseList:AddMod(modLib.setSource(mod, self.modSource))
					end
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
	if self.name == "Tabula Rasa, Simple Robe" or self.name == "Skin of the Loyal, Simple Robe" or self.name == "Skin of the Lords, Simple Robe" or self.name == "The Apostate, Cabalist Regalia" then
		-- Hack to remove the energy shield and base int requirement
		baseList:NewMod("ArmourData", "LIST", { key = "EnergyShield", value = 0 })
		self.requirements.int = 0
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
		self.abyssalSocketCount = 0
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
					if #newSockets >= self.selectableSocketCount then
						break
					end
					t_insert(newSockets, socket)
					group = socket.group
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
	if self.sockets and calcLocal(baseList, "SocketAlwaysMatches", "FLAG", 0) then
		self.sockets.colourAlwaysMatches = true
	end
	self.socketedJewelEffectModifier = 1 + calcLocal(baseList, "SocketedJewelEffect", "INC", 0) / 100
	if self.base.weapon or self.type == "Ring" then
		self.slotModList = { }
		for i = 1, 2 do
			self.slotModList[i] = self:BuildModListForSlotNum(baseList, i)
		end
		-- Ring 3
		if self.type == "Ring" then
			self.slotModList[3] = self:BuildModListForSlotNum(baseList, 3)
		end
	else
		self.modList = self:BuildModListForSlotNum(baseList)
	end
end

function ItemClass:CanHaveMod(mod, includeTags)
	local keyMap = { }
	includeTags = includeTags or { }
	for index, key in ipairs(mod.weightKey) do
		keyMap[key] = index
	end
	-- check for uniques with off-tag mods
	if data.casterTagCrucibleUniques[self.title] then
		includeTags["caster_unique_weapon"] = true
	end
	if data.minionTagCrucibleUniques[self.title] then
		includeTags["minion_unique_weapon"] = true
	end
	if self.rareLikeUnique and self.rareLikeUnique.validBases then
		-- Some uniques use modifiers from another item type.
		for _, base in ipairs(self.rareLikeUnique.validBases) do
			if self:GetModSpawnWeight(mod, includeTags, nil, base.base.tags) > 0 then
				return true
			end
		end
		return false
	end
	if self.canHaveOnlySupportSkillsCrucibleTree then
			return keyMap["crucible_unique_staff"] and mod.weightVal[keyMap["crucible_unique_staff"]] ~= 0
	elseif self.canHaveShieldCrucibleTree then
		return self:GetModSpawnWeight(mod, { ["crucible_unique_helmet"] = true, ["shield"] = true }) > 0
	elseif self.canHaveTwoHandedSwordCrucibleTree then
		return self:GetModSpawnWeight(mod, { ["two_hand_weapon"] = true }, { ["one_hand_weapon"] = true }) > 0
	end
	return self:GetModSpawnWeight(mod, includeTags) > 0
end
