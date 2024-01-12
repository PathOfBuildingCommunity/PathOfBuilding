-- Path of Building
--
-- Module: Trade Query Generator
-- Generates weighted trade queries for item upgrades
--

local dkjson = require "dkjson"
local curl = require("lcurl.safe")
local m_max = math.max
local s_format = string.format
local t_insert = table.insert

-- TODO generate these from data files
local itemCategoryTags = {
	["Ring"] = { ["ring"] = true, ["ring_can_roll_minion_modifiers"] = true },
	["Amulet"] = { ["amulet"] = true },
	["Belt"] = { ["belt"] = true },
	["Chest"] = { ["body_armour"] = true, ["str_armour"] = true, ["dex_armour"] = true, ["int_armour"] = true, ["str_int_armour"] = true, ["str_dex_armour"] = true, ["str_dex_int_armour"] = true },
	["Helmet"] = { ["helmet"] = true, ["str_armour"] = true, ["dex_armour"] = true, ["int_armour"] = true, ["str_int_armour"] = true, ["str_dex_armour"] = true, ["str_dex_int_armour"] = true },
	["Gloves"] = { ["gloves"] = true, ["str_armour"] = true, ["dex_armour"] = true, ["int_armour"] = true, ["str_int_armour"] = true, ["str_dex_armour"] = true, ["str_dex_int_armour"] = true },
	["Boots"] = { ["boots"] = true, ["str_armour"] = true, ["dex_armour"] = true, ["int_armour"] = true, ["str_int_armour"] = true, ["str_dex_armour"] = true, ["str_dex_int_armour"] = true },
	["Quiver"] = { ["quiver"] = true },
	["Shield"] = { ["shield"] = true, ["focus"] = true, ["energy_shield"] = true, ["dex_shield"] = true, ["str_shield"] = true, ["str_int_shield"] = true, ["dex_int_shield"] = true, ["str_dex_shield"] = true, ["focus_can_roll_minion_modifiers"] = true },
	["1HWeapon"] = { ["weapon"] = true, ["one_hand_weapon"] = true, ["onehand"] = true, ["axe"] = true, ["sword"] = true, ["rapier"] = true, ["mace"] = true, ["sceptre"] = true, ["attack_dagger"] = true, ["dagger"] = true, ["rune_dagger"] = true, ["wand"] = true, ["claw"] = true, ["weapon_can_roll_minion_modifiers"] = true },
	["2HWeapon"] = { ["weapon"] = true, ["two_hand_weapon"] = true, ["twohand"] = true, ["staff"] = true, ["attack_staff"] = true, ["warstaff"] = true, ["bow"] = true,  ["axe"] = true, ["sword"] = true, ["mace"] = true, ["2h_sword"] = true, ["2h_axe"] = true, ["2h_mace"] = true },
	["1HAxe"] = { ["weapon"] = true, ["one_hand_weapon"] = true, ["onehand"] = true, ["axe"] = true},
	["1HSword"] = { ["weapon"] = true, ["one_hand_weapon"] = true, ["onehand"] = true, ["sword"] = true, ["rapier"] = true },
	["1HMace"] = { ["weapon"] = true, ["one_hand_weapon"] = true, ["onehand"] = true, ["mace"] = true, ["sceptre"] = true },
	["Dagger"] = { ["weapon"] = true, ["one_hand_weapon"] = true, ["onehand"] = true, ["attack_dagger"] = true, ["dagger"] = true, ["rune_dagger"] = true },
	["Wand"] = { ["weapon"] = true, ["one_hand_weapon"] = true, ["onehand"] = true, ["wand"] = true, ["weapon_can_roll_minion_modifiers"] = true },
	["Claw"] = { ["weapon"] = true, ["one_hand_weapon"] = true, ["onehand"] = true, ["claw"] = true },
	["Staff"] = { ["weapon"] = true, ["two_hand_weapon"] = true, ["twohand"] = true, ["staff"] = true, ["attack_staff"] = true, ["warstaff"] = true },
	["Bow"] = { ["weapon"] = true, ["two_hand_weapon"] = true, ["twohand"] = true, ["bow"] = true },
	["2HAxe"] = { ["weapon"] = true, ["two_hand_weapon"] = true, ["twohand"] = true, ["axe"] = true, ["2h_axe"] = true },
	["2HSword"] = { ["weapon"] = true, ["two_hand_weapon"] = true, ["twohand"] = true, ["sword"] = true, ["2h_sword"] = true },
	["2HMace"] = { ["weapon"] = true, ["two_hand_weapon"] = true, ["twohand"] = true, ["mace"] = true, ["2h_mace"] = true },
	["FishingRod"] = { ["fishing_rod"] = true },
	["AbyssJewel"] = { ["default"] = true, ["abyss_jewel"] = true, ["abyss_jewel_melee"] = true, ["abyss_jewel_ranged"] = true, ["abyss_jewel_summoner"] = true, ["abyss_jewel_caster"] = true },
	["BaseJewel"] = { ["default"] = true, ["jewel"] = true, ["not_int"] = true, ["not_str"] = true, ["not_dex"] = true },
	["AnyJewel"] = { ["default"] = true, ["jewel"] = true, ["not_int"] = true, ["not_str"] = true, ["not_dex"] = true, ["abyss_jewel"] = true, ["abyss_jewel_melee"] = true, ["abyss_jewel_ranged"] = true, ["abyss_jewel_summoner"] = true, ["abyss_jewel_caster"] = true },
	["Flask"] = { ["default"] = true, ["flask"] = true, ["hybrid_flask"] = true, ["utility_flask"] = true, ["mana_flask"] = true, ["life_flask"] = true, ["expedition_flask"] = true, ["critical_utility_flask"] = true }
}

local craftedCategoryTags = {
	["Ring"] = { "Ring" },
	["Amulet"] = { "Amulet" },
	["Belt"] = { "Belt" },
	["Chest"] = { "Body Armour" },
	["Helmet"] = { "Helmet" },
	["Gloves"] = { "Gloves" },
	["Boots"] = { "Boots" },
	["Quiver"] = { "Quiver" },
	["Shield"] = { "Shield" },
	["1HWeapon"] = { "One Handed Sword", "Thrusting One Handed Sword", "One Handed Axe", "One Handed Mace", "Dagger", "Wand", "Claw", "Sceptre" },
	["2HWeapon"] = { "Fishing Rod", "Two Handed Sword", "Staff", "Two Handed Mace", "Two Handed Axe" },
	["1HAxe"] = { "One Handed Axe" },
	["1HSword"] = { "One Handed Sword", "Thrusting One Handed Sword" },
	["1HMace"] = { "One Handed Mace", "Sceptre" },
	["Dagger"] = { "Dagger" },
	["Wand"] = { "Wand" },
	["Claw"] = { "Claw" },
	["Staff"] = { "Staff" },
	["Bow"] = { "Bow" },
	["2HAxe"] = { "Two Handed Axe" },
	["2HSword"] = { "Two Handed Sword" },
	["2HMace"] = { "Two Handed Mace" },
	["FishingRod"] = { "Fishing Rod" },
	["AbyssJewel"] = { "Jewel" },
	["BaseJewel"] = { "Jewel" },
	["AnyJewel"] = { "Jewel" },
	["Flask"] = { "Flask" }
}

local tradeStatCategoryIndices = {
	["Explicit"] = 2,
	["Implicit"] = 3,
	["Corrupted"] = 3,
	["Scourge"] = 6,
	["Eater"] = 3,
	["Exarch"] = 3,
	["Synthesis"] = 3,
	["PassiveNode"] = 2,
}

local influenceSuffixes = { "_shaper", "_elder", "_adjudicator", "_basilisk", "_crusader", "_eyrie"}
local influenceDropdownNames = { "None" }
local hasInfluenceModIds = { }
for i, curInfluenceInfo in ipairs(itemLib.influenceInfo) do
	influenceDropdownNames[i + 1] = curInfluenceInfo.display
	hasInfluenceModIds[i] = "pseudo.pseudo_has_" .. string.lower(curInfluenceInfo.display) .. "_influence"
end

-- slots that allow eldritch mods (non-unique only)
local eldritchModSlots = {
	["Body Armour"] = true,
	["Helmet"] = true,
	["Gloves"] = true,
	["Boots"] = true
}

local MAX_FILTERS = 35

local function logToFile(...)
	ConPrintf(...)
end

local TradeQueryGeneratorClass = newClass("TradeQueryGenerator", function(self, queryTab)
	self:InitMods()
	self.queryTab = queryTab
	self.itemsTab = queryTab.itemsTab
	self.calcContext = { }

end)

local function fetchStats()
	local tradeStats = ""
	local easy = common.curl.easy()
	easy:setopt_url("https://www.pathofexile.com/api/trade/data/stats")
	easy:setopt_useragent("Path of Building/" .. launch.versionNumber)
	easy:setopt_writefunction(function(data)
		tradeStats = tradeStats..data
		return true
	end)
	easy:perform()
	easy:close()
	return tradeStats
end

local function stripInfluenceSuffix(key)
	local influenceSuffixPos = nil
	for _, suffix in ipairs(influenceSuffixes) do
		influenceSuffixPos = key:find(suffix)
		if influenceSuffixPos ~= nil then
			return key:sub(1, influenceSuffixPos - 1)
		end
	end
	return key
end

local function canModSpawnForItemCategory(mod, category)
	-- Synthesis modifiers have an empty weightKey (i.e., = {}). This was stripped from
	-- client side back in league 3.10. Web-based Synthesis approximate use "stale" info.
	-- To consider Synthesis mods we have to assume each mod can exist on any item base
	-- Will be enabled when we have a mapping of mods to base types
	--if mod.type == "Synthesis" then
		-- return true
	--end
	if mod.types then -- crafted mods
		for _, key in ipairs(craftedCategoryTags[category]) do
			if mod.types[key] then
				return true
			end
		end
	else
		local tags = itemCategoryTags[category]
		for i, key in ipairs(mod.weightKey) do
			local influenceStrippedKey = stripInfluenceSuffix(key)
			if key ~= "default" and mod.affix:find("Elevated") ~= nil and tags[influenceStrippedKey] == true then
				return true
			elseif key ~= "default" and mod.type == "Corrupted" and tags[influenceStrippedKey] == true then
				return true
			elseif mod.weightVal[i] > 0 and tags[influenceStrippedKey] == true then
				return true
			end
		end
	end
	return false
end

function TradeQueryGeneratorClass.WeightedRatioOutputs(baseOutput, newOutput, statWeights)
	local meanStatDiff = 0
	local function ratioModSums(...)
		local baseModSum = 0
		local newModSum = 0
		for _, mod in ipairs({ ... }) do
			baseModSum = baseModSum + (baseOutput[mod] or 0)
			newModSum = newModSum + (newOutput[mod] or 0)
		end

		if baseModSum == math.huge then
			return 0
		else
			if newModSum == math.huge then
				return data.misc.maxStatIncrease
			else
				return math.min(newModSum / ((baseModSum ~= 0) and baseModSum or 1), data.misc.maxStatIncrease)
			end
		end
	end
	for _, statTable in ipairs(statWeights) do
		if statTable.stat == "FullDPS" and not GlobalCache.useFullDPS then
			meanStatDiff = meanStatDiff + ratioModSums("TotalDPS", "TotalDotDPS", "CombinedDPS") * statTable.weightMult
		else
			meanStatDiff = meanStatDiff + ratioModSums(statTable.stat) * statTable.weightMult
		end
	end
	return meanStatDiff
end

function TradeQueryGeneratorClass:ProcessMod(modId, mod, tradeQueryStatsParsed, itemCategoriesMask, itemCategoriesOverride)
	if type(modId) == "string" and modId:find("HellscapeDownside") ~= nil then -- skip scourge downsides, they often don't follow standard parsing rules, and should basically never be beneficial anyways
		goto continue
	end

	for index, modLine in ipairs(mod) do
		if modLine:find("Grants Level") or modLine:find("inflict Decay") then -- skip mods that grant skills / decay, as they will often be overwhelmingly powerful but don't actually fit into the build
			goto nextModLine
		end

		local statOrder = modLine:find("Nearby Enemies have %-") ~= nil and mod.statOrder[index + 1] or mod.statOrder[index] -- hack to get minus res mods associated with the correct statOrder
		local modType = (mod.type == "Prefix" or mod.type == "Suffix") and (type(modId) == "string" and modId:find("AfflictionNotable") and "PassiveNode" or "Explicit") or mod.type
		if modType == "ScourgeUpside" then modType = "Scourge" end

		-- Special cases
		local specialCaseData = { }
		if mod.group and (mod.group:find("Local") or mod.group:find("Shield")) and modLine:find("Chance to Block$") then
			specialCaseData.overrideModLine = "+#% Chance to Block"
			modLine = modLine .. " (Shields)"
		elseif modLine == "You can apply an additional Curse" then
			specialCaseData.overrideModLineSingular = "You can apply an additional Curse"
			modLine = "You can apply 1 additional Curses"
		elseif modLine == "Bow Attacks fire an additional Arrow" then
			specialCaseData.overrideModLineSingular = "Bow Attacks fire an additional Arrow"
			modLine = "Bow Attacks fire 1 additional Arrows"
		elseif modLine == "Projectiles Pierce an additional Target" then
			specialCaseData.overrideModLineSingular = "Projectiles Pierce an additional Target"
			modLine = "Projectiles Pierce 1 additional Targets"
		elseif modLine == "Has 1 Abyssal Socket" then
			specialCaseData.overrideModLineSingular = "Has 1 Abyssal Socket"
			modLine = "Has 1 Abyssal Sockets"
		end

		-- If this is the first tier for this mod, find matching trade mod and init the entry
		if not self.modData[modType] then
			logToFile("Unhandled Mod Type: %s", modType)
			goto continue
		end

		local function swapInverse(modLine)
			local priorStr = modLine
			local inverseKey
			if modLine:match("increased") then
				modLine = modLine:gsub("([^ ]+) increased", "-%1 reduced")
				if modLine ~= priorStr then inverseKey = "increased" end
			elseif modLine:match("reduced") then
				modLine = modLine:gsub("([^ ]+) reduced", "-%1 increased")
				if modLine ~= priorStr then inverseKey = "reduced" end
			elseif modLine:match("more") then
				modLine = modLine:gsub("([^ ]+) more", "-%1 less")
				if modLine ~= priorStr then inverseKey = "more" end
			elseif modLine:match("less") then
				modLine = modLine:gsub("([^ ]+) less", "-%1 more")
				if modLine ~= priorStr then inverseKey = "less" end
			elseif modLine:match("expires ([^ ]+) slower") then
				modLine = modLine:gsub("([^ ]+) slower", "-%1 faster")
				if modLine ~= priorStr then inverseKey = "slower" end
			elseif modLine:match("expires ([^ ]+) faster") then
				modLine = modLine:gsub("([^ ]+) faster", "-%1 slower")
				if modLine ~= priorStr then inverseKey = "faster" end
			end
			return modLine, inverseKey
		end

		local uniqueIndex = tostring(statOrder).."_"..mod.group
		local inverse = false
		local inverseKey
		::reparseMod::
		if self.modData[modType][uniqueIndex] == nil then
			local tradeMod = nil
			-- Try to match to a local mod fallback to global if no match
			if mod.group:match("Local") then
				local matchLocalStr = (modLine .. " (Local)"):gsub("[#()0-9%-%+%.]","")
				for _, entry in pairs(tradeQueryStatsParsed.localResults[tradeStatCategoryIndices[modType]].entries) do
					if entry.text:gsub("[#()0-9%-%+%.]","") == matchLocalStr then
						tradeMod = entry
						specialCaseData.overrideModLine = entry.text:sub(1,-9)
						break
					end
				end
			end
			if tradeMod == nil then
				local matchStr = modLine:gsub("[#()0-9%-%+%.]","")
				for _, entry in ipairs(tradeQueryStatsParsed.result[tradeStatCategoryIndices[modType]].entries) do
					if entry.text:gsub("[#()0-9%-%+%.]","") == matchStr then
						tradeMod = entry
						break
					end
				end
			end
			if tradeMod == nil then
				if inverse then
					logToFile("Unable to match %s mod: %s", modType, modLine)
					goto nextModLine
				else -- try swapping increased / decreased and signed and other similar mods.
					modLine, inverseKey = swapInverse(modLine)
					inverse = true
					if inverseKey then
						goto reparseMod
					else
						logToFile("Unable to match %s mod: %s", modType, modLine)
						goto nextModLine
					end
				end
			end

			self.modData[modType][uniqueIndex] = { tradeMod = tradeMod, specialCaseData = specialCaseData, inverseKey = inverseKey }
		elseif self.modData[modType][uniqueIndex].inverseKey and modLine:match(self.modData[modType][uniqueIndex].inverseKey) then
			inverse = true
			modLine = swapInverse(modLine)
		end

		-- tokenize the numerical variables for this mod and store the sign if there is one
		local tokens = { }
		local poundPos, tokenizeOffset = 0, 0
		while true do
			poundPos = self.modData[modType][uniqueIndex].tradeMod.text:find("#", poundPos + 1)
			if poundPos == nil then
				break
			end

			local startPos, endPos, sign, min, max = modLine:find("([%+%-]?)%(?(%d+%.?%d*)%-?(%d*%.?%d*)%)?", poundPos + tokenizeOffset)

			if endPos == nil then
				logToFile("[GMD] Error extracting tokens from '%s' for tradeMod '%s'", modLine, self.modData[modType][uniqueIndex].tradeMod.text)
				goto nextModLine
			end

			max = #max > 0 and tonumber(max) or tonumber(min)

			tokenizeOffset = tokenizeOffset + (endPos - startPos)
			
			if inverse then
				sign = nil
				min = -min
				max = -max
				if min > max then
					local temp = max
					max = min
					min = temp
				end
			end

			t_insert(tokens, min)
			t_insert(tokens, max)
			if sign ~= nil then
				self.modData[modType][uniqueIndex].sign = sign
			end
		end

		if #tokens ~= 0 and #tokens ~= 2 and #tokens ~= 4 then
			logToFile("Unexpected # of tokens found for mod: %s", mod[i])
			goto nextModLine
		end

		-- Update the min and max values available for each item category
		for category, _ in pairs(itemCategoriesOverride or itemCategoriesMask or itemCategoryTags) do
			if itemCategoriesOverride or canModSpawnForItemCategory(mod, category) then
				if self.modData[modType][uniqueIndex][category] == nil then
					self.modData[modType][uniqueIndex][category] = { min = 999999, max = -999999 }
				end

				local modRange = self.modData[modType][uniqueIndex][category]
				if #tokens == 0 then
					modRange.min = 1
					modRange.max = 1
				elseif #tokens == 2 then
					modRange.min = math.min(modRange.min, tokens[1])
					modRange.max = math.max(modRange.max, tokens[2])
				elseif #tokens == 4 then
					modRange.min = math.min(modRange.min, (tokens[1] + tokens[3]) / 2)
					modRange.max = math.max(modRange.max, (tokens[2] + tokens[4]) / 2)
				end
			end
		end
		::nextModLine::
	end
	::continue::
end

function TradeQueryGeneratorClass:GenerateModData(mods, tradeQueryStatsParsed, itemCategoriesMask, itemCategoriesOverride)
	for modId, mod in pairs(mods) do
		self:ProcessMod(modId, mod, tradeQueryStatsParsed, itemCategoriesMask, itemCategoriesOverride)
	end
end

function TradeQueryGeneratorClass:InitMods()
	local queryModFilePath = "Data/QueryMods.lua"

	local file = io.open(queryModFilePath,"r")
	if file then
		file:close()
		self.modData = LoadModule(queryModFilePath)
		return
	end

	self.modData = {
		["Explicit"] = { },
		["Implicit"] = { },
		["Corrupted"] = { },
		["Scourge"] = { },
		["Eater"] = { },
		["Exarch"] = { },
		["Synthesis"] = { },
		["PassiveNode"] = { },
	}

	-- originates from: https://www.pathofexile.com/api/trade/data/stats
	local tradeStats = fetchStats()
	tradeStats:gsub("\n", " ")
	local tradeQueryStatsParsed = dkjson.decode(tradeStats)

	-- Create second table only containing local mods this should speedup generation slightly
	tradeQueryStatsParsed.localResults = { }
	for modTypeId, modType in ipairs(tradeQueryStatsParsed.result) do
		tradeQueryStatsParsed.localResults[modTypeId] = { label = modType.label, entries = { } }
		for modId, mod in ipairs(modType.entries) do
			if mod.text:match("(Local)") then
				tradeQueryStatsParsed.localResults[modTypeId].entries[modId] = mod
			end
		end
	end

	-- explicit, corrupted, scourge, and jewel mods
	local regularItemMask = { }
	for category, _ in pairs(itemCategoryTags) do
		if category ~= "Flask" and category ~= "AbyssJewel" and category ~= "BaseJewel" and category ~= "AnyJewel" then
			regularItemMask[category] = true
		end
	end
	self:GenerateModData(data.itemMods.Item, tradeQueryStatsParsed, regularItemMask)
	self:GenerateModData(data.itemMods.Jewel, tradeQueryStatsParsed, { ["BaseJewel"] = true, ["AnyJewel"] = true })
	self:GenerateModData(data.itemMods.JewelAbyss, tradeQueryStatsParsed, { ["AbyssJewel"] = true, ["AnyJewel"] = true })
	self:GenerateModData(data.itemMods.Flask, tradeQueryStatsParsed, { ["Flask"] = true })

	-- Special handling for essences
	for _, essenceItem in pairs(data.essences) do
		for tag, modId in pairs(essenceItem.mods) do
			local itemCategoriesOverride = {} -- build a list of relevant categories.
			for category, tags in pairs(craftedCategoryTags) do
				for _, matchTag in pairs(tags) do
					if tag == matchTag  then
						itemCategoriesOverride[category] = tags
					end
				end
			end
			self:ProcessMod(modId, data.itemMods.Item[modId], tradeQueryStatsParsed, regularItemMask, itemCategoriesOverride)
		end
	end

	regularItemMask.Flask = true -- Update mask as flasks can have crafted mods.
	self:GenerateModData(data.masterMods, tradeQueryStatsParsed, regularItemMask)
	self:GenerateModData(data.veiledMods, tradeQueryStatsParsed, regularItemMask)

	-- megalomaniac
	local clusterNotableMods = {}
	for k, v in pairs(data.itemMods.JewelCluster) do
		if k:find("AfflictionNotable") then
			clusterNotableMods[k] = v
		end
	end
	self:GenerateModData(clusterNotableMods, tradeQueryStatsParsed)

	-- Base item implicit mods. A lot of this code is duplicated from generateModData(), but with important small logical flow changes to handle the format differences
	for baseName, entry in pairs(data.itemBases) do
		if entry.implicit ~= nil then
			local stats = { }
			for modLine in string.gmatch(entry.implicit, "([^".."\n".."]+)") do
				if modLine:find("Grants Level") then -- skip mods that grant skills, as they will often be overwhelmingly powerful but don't actually fit into the build
					goto continue
				end

				local modType = "Implicit"

				local tradeMod = nil
				local matchStr = modLine:gsub("[#()0-9%-%+%.]","")
				for _, entry in ipairs(tradeQueryStatsParsed.result[tradeStatCategoryIndices[modType]].entries) do
					if entry.text:gsub("[#()0-9%-%+%.]","") == matchStr then
						tradeMod = entry
						break
					end
				end

				if tradeMod == nil then
					goto continue
					logToFile("Unable to match %s mod: %s", modType, modLine)
				end
				-- base item implicits don't have stat orders, so use the trade mod id instead
				local statOrder = tradeMod.id

				-- If this is the first tier for this mod, init the entry
				local uniqueIndex = tostring(statOrder)
				if self.modData[modType][uniqueIndex] == nil then
					self.modData[modType][uniqueIndex] = { tradeMod = tradeMod, specialCaseData = { } }
				end

				-- tokenize the numerical variables for this mod and store the sign if there is one
				local tokens = { }
				local poundPos, tokenizeOffset = 0, 0
				while true do
					poundPos = self.modData[modType][uniqueIndex].tradeMod.text:find("#", poundPos + 1)
					if poundPos == nil then
						break
					end
					startPos, endPos, sign, min, max = modLine:find("([%+%-]?)%(?(%d+%.?%d*)%-?(%d*%.?%d*)%)?", poundPos + tokenizeOffset)

					if endPos == nil then
						logToFile("[Init] Error extracting tokens from '%s' for tradeMod '%s'", modLine, self.modData[modType][uniqueIndex].tradeMod.text)
						goto continue
					end

					tokenizeOffset = tokenizeOffset + (endPos - startPos)
					t_insert(tokens, min)
					t_insert(tokens, #max > 0 and tonumber(max) or tonumber(min))
					if sign ~= nil then
						self.modData[modType][uniqueIndex].sign = sign
					end
				end

				if #tokens ~= 0 and #tokens ~= 2 and #tokens ~= 4 then
					logToFile("Unexpected # of tokens found for mod: %s", modLine)
					goto continue
				end

				-- Update the min and max values available for each item category
				for category, categoryTags in pairs(itemCategoryTags) do
					local tagMatch = false
					for tag, value in pairs(entry.tags) do
						if tag ~= "default" and categoryTags[tag] == true then
							tagMatch = true
							break
						end
					end

					if tagMatch then
						if self.modData[modType][uniqueIndex][category] == nil then
							self.modData[modType][uniqueIndex][category] = { min = 999999, max = -999999, subType = entry.subType }
						end

						local modRange = self.modData[modType][uniqueIndex][category]
						if #tokens == 0 then
							modRange.min = 1
							modRange.max = 1
						elseif #tokens == 2 then
							modRange.min = math.min(modRange.min, tokens[1])
							modRange.max = math.max(modRange.max, tokens[2])
						elseif #tokens == 4 then
							modRange.min = math.min(modRange.min, (tokens[1] + tokens[3]) / 2)
							modRange.max = math.max(modRange.max, (tokens[2] + tokens[4]) / 2)
						end
					end
				end
				::continue::
			end
		end
	end

	local queryModsFile = io.open(queryModFilePath, 'w')
	queryModsFile:write("-- This file is automatically generated, do not edit!\n-- Stat data (c) Grinding Gear Games\n\n")
	queryModsFile:write("return " .. stringify(self.modData))
	queryModsFile:close()
end

function TradeQueryGeneratorClass:GenerateModWeights(modsToTest)
	local start = GetTime()
	for _, entry in pairs(modsToTest) do
		if entry[self.calcContext.itemCategory] ~= nil then
			if self.alreadyWeightedMods[entry.tradeMod.id] ~= nil then -- Don't calculate the same thing twice (can happen with corrupted vs implicit)
				goto continue
			elseif self.calcContext.options.includeTalisman == false and entry[self.calcContext.itemCategory].subType == "Talisman" then -- Talisman implicits take up a lot of query slots, so we have an option to skip them
				goto continue
			end

			-- Test with a value halfway (or configured default Item Affix Quality) between the min and max available for this mod in this slot. Note that this can generate slightly different values for the same mod as implicit vs explicit.
			local modValue = math.ceil((entry[self.calcContext.itemCategory].max - entry[self.calcContext.itemCategory].min) * ( main.defaultItemAffixQuality or 0.5 ) + entry[self.calcContext.itemCategory].min)
			local modValueStr = (entry.sign and entry.sign or "") .. tostring(modValue)

			-- Apply override text for special cases
			local modLine
			if modValue == 1 and entry.specialCaseData.overrideModLineSingular ~= nil then
				modLine = entry.specialCaseData.overrideModLineSingular
			elseif entry.specialCaseData.overrideModLine ~= nil then
				modLine = entry.specialCaseData.overrideModLine
			else
				modLine = entry.tradeMod.text
			end
			modLine = modLine:gsub("#",modValueStr)

			self.calcContext.testItem.explicitModLines[1] = { line = modLine, custom = true }
			self.calcContext.testItem:BuildAndParseRaw()

			if (self.calcContext.testItem.modList ~= nil and #self.calcContext.testItem.modList == 0) or (self.calcContext.testItem.slotModList ~= nil and #self.calcContext.testItem.slotModList[1] == 0 and #self.calcContext.testItem.slotModList[2] == 0) then
				logToFile("Failed to test %s mod: %s", self.calcContext.itemCategory, modLine)
			end

			local output = self.calcContext.calcFunc({ repSlotName = self.calcContext.slot.slotName, repItem = self.calcContext.testItem }, { nodeAlloc = true })
			local meanStatDiff = TradeQueryGeneratorClass.WeightedRatioOutputs(self.calcContext.baseOutput, output, self.calcContext.options.statWeights) * 1000 - (self.calcContext.baseStatValue or 0)
			if meanStatDiff > 0.01 then
				t_insert(self.modWeights, { tradeModId = entry.tradeMod.id, weight = meanStatDiff / modValue, meanStatDiff = meanStatDiff, invert = entry.sign == "-" and true or false })
			end
			self.alreadyWeightedMods[entry.tradeMod.id] = true

			local now = GetTime()
			if now - start > 50 then
				-- Would be nice to update x/y progress on the popup here, but getting y ahead of time has a cost, and the visual seems to update on a significant delay anyways so it's not very useful
				coroutine.yield()
				start = now
			end
		end
		::continue::
	end
end

function TradeQueryGeneratorClass:GeneratePassiveNodeWeights(nodesToTest)
	local start = GetTime()
	for _, entry in pairs(nodesToTest) do
		if self.alreadyWeightedMods[entry.tradeMod.id] ~= nil then
			goto continue
		end
		
		local nodeName = entry.tradeMod.text:match("1 Added Passive Skill is (.*)") or entry.tradeMod.text:match("Allocates (.*)")
		if not nodeName then
			goto continue
		end
		local node = self.itemsTab.build.spec.tree.clusterNodeMap[nodeName] or self.itemsTab.build.spec.tree.notableMap[nodeName]
		
		local baseOutput = self.calcContext.baseOutput
		local output = self.calcContext.calcFunc({ addNodes = { [node] = true } }, { requirementsItems = true, requirementsGems = true, skills = true })
		local meanStatDiff = TradeQueryGeneratorClass.WeightedRatioOutputs(baseOutput, output, self.calcContext.options.statWeights) * 1000 - (self.calcContext.baseStatValue or 0)
		if meanStatDiff > 0.01 then
			t_insert(self.modWeights, { tradeModId = entry.tradeMod.id, weight = meanStatDiff, meanStatDiff = meanStatDiff, invert = false })
		end
		self.alreadyWeightedMods[entry.tradeMod.id] = true
		
		local now = GetTime()
		if now - start > 50 then
			-- Would be nice to update x/y progress on the popup here, but getting y ahead of time has a cost, and the visual seems to update on a significant delay anyways so it's not very useful
			coroutine.yield()
			start = now
		end
		::continue::
	end
end

function TradeQueryGeneratorClass:OnFrame()
	if self.calcContext.co == nil then
		return
	end

	local res, errMsg = coroutine.resume(self.calcContext.co, self)
	if launch.devMode and not res then
		error(errMsg)
	end
	if coroutine.status(self.calcContext.co) == "dead" then
		self.calcContext.co = nil
		self:FinishQuery()
	end
end

function TradeQueryGeneratorClass:StartQuery(slot, options)
	-- Figure out what type of item we're searching for
	local existingItem = slot and self.itemsTab.items[slot.selItemId]
	local testItemType = existingItem and existingItem.baseName or "Unset Amulet"
	local itemCategoryQueryStr
	local itemCategory
	local special = { }
	if options.special then
		if options.special.itemName == "Megalomaniac" then
			special = {
				queryFilters = {},
				queryExtra = {
					name = "Megalomaniac",
					type = "Medium Cluster Jewel"
				},
				calcNodesInsteadOfMods = true,
			}
		end
	elseif slot.slotName == "Weapon 2" or slot.slotName == "Weapon 1" then
		if existingItem then
			if existingItem.type == "Shield" then
				itemCategoryQueryStr = "armour.shield"
				itemCategory = "Shield"
			elseif existingItem.type == "Quiver" then
				itemCategoryQueryStr = "armour.quiver"
				itemCategory = "Quiver"
			elseif existingItem.type == "Bow" then
				itemCategoryQueryStr = "weapon.bow"
				itemCategory = "Bow"
			elseif existingItem.type == "Staff" then
				itemCategoryQueryStr = "weapon.staff"
				itemCategory = "Staff"
			elseif existingItem.type == "Two Handed Sword" then
				itemCategoryQueryStr = "weapon.twosword"
				itemCategory = "2HSword"
			elseif existingItem.type == "Two Handed Axe" then
				itemCategoryQueryStr = "weapon.twoaxe"
				itemCategory = "2HAxe"
			elseif existingItem.type == "Two Handed Mace" then
				itemCategoryQueryStr = "weapon.twomace"
				itemCategory = "2HMace"
			elseif existingItem.type == "Fishing Rod" then
				itemCategoryQueryStr = "weapon.rod"
				itemCategory = "FishingRod"
			elseif existingItem.type == "One Handed Sword" then
				itemCategoryQueryStr = "weapon.onesword"
				itemCategory = "1HSword"
			elseif existingItem.type == "One Handed Axe" then
				itemCategoryQueryStr = "weapon.oneaxe"
				itemCategory = "1HAxe"
			elseif existingItem.type == "One Handed Mace" or existingItem.type == "Sceptre" then
				itemCategoryQueryStr = "weapon.onemace"
				itemCategory = "1HMace"
			elseif existingItem.type == "Wand" then
				itemCategoryQueryStr = "weapon.wand"
				itemCategory = "Wand"
			elseif existingItem.type == "Dagger" then
				itemCategoryQueryStr = "weapon.dagger"
				itemCategory = "Dagger"
			elseif existingItem.type == "Claw" then
				itemCategoryQueryStr = "weapon.claw"
				itemCategory = "Claw"
			elseif existingItem.type:find("Two Handed") ~= nil then
				itemCategoryQueryStr = "weapon.twomelee"
				itemCategory = "2HWeapon"
			elseif existingItem.type:find("One Handed") ~= nil then
				itemCategoryQueryStr = "weapon.one"
				itemCategory = "1HWeapon"
			else
				logToFile("'%s' is not supported for weighted trade query generation", existingItem.type)
				return
			end
		else
			-- Item does not exist in this slot so assume 1H weapon
			itemCategoryQueryStr = "weapon.one"
			itemCategory = "1HWeapon"
		end
	elseif slot.slotName == "Body Armour" then
		itemCategoryQueryStr = "armour.chest"
		itemCategory = "Chest"
	elseif slot.slotName == "Helmet" then
		itemCategoryQueryStr = "armour.helmet"
		itemCategory = "Helmet"
	elseif slot.slotName == "Gloves" then
		itemCategoryQueryStr = "armour.gloves"
		itemCategory = "Gloves"
	elseif slot.slotName == "Boots" then
		itemCategoryQueryStr = "armour.boots"
		itemCategory = "Boots"
	elseif slot.slotName == "Amulet" then
		itemCategoryQueryStr = "accessory.amulet"
		itemCategory = "Amulet"
	elseif slot.slotName == "Ring 1" or slot.slotName == "Ring 2" then
		itemCategoryQueryStr = "accessory.ring"
		itemCategory = "Ring"
	elseif slot.slotName == "Belt" then
		itemCategoryQueryStr = "accessory.belt"
		itemCategory = "Belt"
	elseif slot.slotName:find("Abyssal") ~= nil then
		itemCategoryQueryStr = "jewel.abyss"
		itemCategory = "AbyssJewel"
	elseif slot.slotName:find("Jewel") ~= nil then
		itemCategoryQueryStr = "jewel"
		itemCategory = options.jewelType .. "Jewel"
		if itemCategory == "AbyssJewel" then
			itemCategoryQueryStr = "jewel.abyss"
		elseif itemCategory == "BaseJewel" then
			itemCategoryQueryStr = "jewel.base"
		end
	elseif slot.slotName:find("Flask") ~= nil then
		itemCategoryQueryStr = "flask"
		itemCategory = "Flask"
	else
		logToFile("'%s' is not supported for weighted trade query generation", existingItem and existingItem.type or "n/a")
		return
	end

	-- Create a temp item for the slot with no mods
	local itemRawStr = "Rarity: RARE\nStat Tester\n" .. testItemType
	local testItem = new("Item", itemRawStr)

	-- Apply any requests influences
	if options.influence1 > 1 then
		testItem[itemLib.influenceInfo[options.influence1 - 1].key] = true
	end
	if options.influence2 > 1 then
		testItem[itemLib.influenceInfo[options.influence2 - 1].key] = true
	end

	-- Calculate base output with a blank item
	local calcFunc, baseOutput = self.itemsTab.build.calcsTab:GetMiscCalculator()
	local baseItemOutput = slot and calcFunc({ repSlotName = slot.slotName, repItem = testItem }, { nodeAlloc = true }) or baseOutput
	-- make weights more human readable
	local compStatValue = TradeQueryGeneratorClass.WeightedRatioOutputs(baseOutput, baseItemOutput, options.statWeights) * 1000

	-- Test each mod one at a time and cache the normalized Stat (configured earlier) diff to use as weight
	self.modWeights = { }
	self.alreadyWeightedMods = { }

	self.calcContext = {
		itemCategoryQueryStr = itemCategoryQueryStr,
		itemCategory = itemCategory,
		special = special,
		testItem = testItem,
		baseOutput = baseOutput,
		baseStatValue = compStatValue,
		calcFunc = calcFunc,
		options = options,
		slot = slot,
	}

	-- OnFrame will pick this up and begin the work
	self.calcContext.co = coroutine.create(self.ExecuteQuery)

	-- Open progress tracking blocker popup
	local controls = { }
	controls.progressText = new("LabelControl", {"TOP",nil,"TOP"}, 0, 30, 0, 16, string.format("Calculating Mod Weights..."))
	self.calcContext.popup = main:OpenPopup(280, 65, "Please Wait", controls)
end

function TradeQueryGeneratorClass:ExecuteQuery()
	if self.calcContext.special.calcNodesInsteadOfMods then
		self:GeneratePassiveNodeWeights(self.modData.PassiveNode)
		return
	end
	self:GenerateModWeights(self.modData["Explicit"])
	self:GenerateModWeights(self.modData["Implicit"])
	if self.calcContext.options.includeCorrupted then
		self:GenerateModWeights(self.modData["Corrupted"])
	end
	if self.calcContext.options.includeScourge then
		self:GenerateModWeights(self.modData["Scourge"])
	end
	if self.calcContext.options.includeEldritch then
		self:GenerateModWeights(self.modData["Eater"])
		self:GenerateModWeights(self.modData["Exarch"])
	end
	if self.calcContext.options.includeSynthesis then
		self:GenerateModWeights(self.modData["Synthesis"])
	end
end

function TradeQueryGeneratorClass:FinishQuery()
	-- Calc original item Stats without anoint or enchant, and use that diff as a basis for default min sum.
	local originalItem = self.calcContext.slot and self.itemsTab.items[self.calcContext.slot.selItemId]
	self.calcContext.testItem.explicitModLines = { }
	if originalItem then
		for _, modLine in ipairs(originalItem.explicitModLines) do
			t_insert(self.calcContext.testItem.explicitModLines, modLine)
		end
		for _, modLine in ipairs(originalItem.scourgeModLines) do
			t_insert(self.calcContext.testItem.explicitModLines, modLine)
		end
		for _, modLine in ipairs(originalItem.implicitModLines) do
			t_insert(self.calcContext.testItem.explicitModLines, modLine)
		end
		for _, modLine in ipairs(originalItem.crucibleModLines) do
			t_insert(self.calcContext.testItem.explicitModLines, modLine)
		end
	end
	self.calcContext.testItem:BuildAndParseRaw()

	local originalOutput = originalItem and self.calcContext.calcFunc({ repSlotName = self.calcContext.slot.slotName, repItem = self.calcContext.testItem }, { nodeAlloc = true }) or self.calcContext.baseOutput
	local currentStatDiff = TradeQueryGeneratorClass.WeightedRatioOutputs(self.calcContext.baseOutput, originalOutput, self.calcContext.options.statWeights) * 1000 - (self.calcContext.baseStatValue or 0)
	
	-- Sort by mean Stat diff rather than weight to more accurately prioritize stats that can contribute more
	table.sort(self.modWeights, function(a, b)
		return a.meanStatDiff > b.meanStatDiff
	end)
	
	-- A megalomaniac is not being compared to anything and the currentStatDiff will be 0, so just go for an arbitrary min weight - in this case triple the weight of the worst evaluated node.
	local megalomaniacSpecialMinWeight = self.calcContext.special.itemName == "Megalomaniac" and self.modWeights[#self.modWeights] * 3
	-- This Stat diff value will generally be higher than the weighted sum of the same item, because the stats are all applied at once and can thus multiply off each other.
	-- So apply a modifier to get a reasonable min and hopefully approximate that the query will start out with small upgrades.
	local minWeight = megalomaniacSpecialMinWeight or currentStatDiff * 0.5
	
	-- Generate trade query str and open in browser
	local filters = 0
	local queryTable = {
		query = {
			filters = self.calcContext.special.queryFilters or {
				type_filters = {
					filters = {
						category = { option = self.calcContext.itemCategoryQueryStr },
						rarity = { option = "nonunique" }
					}
				}
			},
			status = { option = "online" },
			stats = {
				{
					type = "weight",
					value = { min = minWeight },
					filters = { }
				}
			}
		},
		sort = { ["statgroup.0"] = "desc" },
		engine = "new"
	}
	
	for k, v in pairs(self.calcContext.special.queryExtra or {}) do
		queryTable.query[k] = v
	end

	local andFilters = { type = "and", filters = { } }

	local options = self.calcContext.options
	if options.influence1 > 1 then
		t_insert(andFilters.filters, { id = hasInfluenceModIds[options.influence1 - 1] })
		filters = filters + 1
	end
	if options.influence2 > 1 then
		t_insert(andFilters.filters, { id = hasInfluenceModIds[options.influence2 - 1] })
		filters = filters + 1
	end

	if #andFilters.filters > 0 then
		t_insert(queryTable.query.stats, andFilters)
	end

	for _, entry in pairs(self.modWeights) do
		t_insert(queryTable.query.stats[1].filters, { id = entry.tradeModId, value = { weight = (entry.invert == true and entry.weight * -1 or entry.weight) } })
		filters = filters + 1
		if filters == MAX_FILTERS then
			break
		end
	end

	if options.maxPrice and options.maxPrice > 0 then
		queryTable.query.filters.trade_filters = {
			filters = {
				price = {
					option = options.maxPriceType,
					max = options.maxPrice
				}
			}
		}
	end

	if options.maxLevel and options.maxLevel > 0 then
		queryTable.query.filters.req_filters = {
			disabled = false,
			filters = {
				lvl = {
					max = options.maxLevel
				}
			}
		}
	end

	if options.sockets and options.sockets > 0 then
		queryTable.query.filters.socket_filters = {
			disabled = false,
			filters = {
				sockets = {
					max = options.sockets,
					min = options.sockets
				}
			}
		}
	end

	if options.links and options.links > 0 then
		if not queryTable.query.filters.socket_filters then
			queryTable.query.filters.socket_filters = {
				disabled = false,
				filters = {
					links = {
						max = options.links,
						min = options.links
					}
				}
			}
		else -- do not overwrite options.sockets
			queryTable.query.filters.socket_filters.filters["links"] = {
				max = options.links,
				min = options.links
			}
		end
	end

	local errMsg = nil
	if #queryTable.query.stats[1].filters == 0 then
		-- No mods to filter
		errMsg = "Could not generate search, found no mods to search for"
		if GlobalCache.numActiveSkillInFullDPS == 0 then
			errMsg = "Could not generate search, change active skill or enable FullDPS on some skills"
		end
	end

	local queryJson = dkjson.encode(queryTable)
	self.requesterCallback(self.requesterContext, queryJson, errMsg)

	-- Close blocker popup
	main:ClosePopup()
end

function TradeQueryGeneratorClass:RequestQuery(slot, context, statWeights, callback)
	self.requesterCallback = callback
	self.requesterContext = context

	local controls = { }
	local options = { }
	local popupHeight = 110

	local isJewelSlot = slot and slot.slotName:find("Jewel") ~= nil
	local isAbyssalJewelSlot = slot and slot.slotName:find("Abyssal") ~= nil
	local isAmuletSlot = slot and slot.slotName == "Amulet"
	local isEldritchModSlot = slot and eldritchModSlots[slot.slotName] == true

	controls.includeCorrupted = new("CheckBoxControl", {"TOP",nil,"TOP"}, -40, 30, 18, "Corrupted Mods:", function(state) end)
	controls.includeCorrupted.state = not context.slotTbl.alreadyCorrupted and (self.lastIncludeCorrupted == nil or self.lastIncludeCorrupted == true)
	controls.includeCorrupted.enabled = not context.slotTbl.alreadyCorrupted

	-- removing checkbox until synthesis mods are supported
	--controls.includeSynthesis = new("CheckBoxControl", {"TOPRIGHT",controls.includeEldritch,"BOTTOMRIGHT"}, 0, 5, 18, "Synthesis Mods:", function(state) end)
	--controls.includeSynthesis.state = (self.lastIncludeSynthesis == nil or self.lastIncludeSynthesis == true)

	local lastItemAnchor = controls.includeCorrupted
	local includeScourge = self.queryTab.pbLeagueRealName == "Standard" or self.queryTab.pbLeagueRealName == "Hardcore"

	local function updateLastAnchor(anchor, height)
		lastItemAnchor = anchor
		popupHeight = popupHeight + (height or 23)
	end

	if context.slotTbl.unique then
		options.special = { itemName = context.slotTbl.slotName }
	end

	if not isJewelSlot and not isAbyssalJewelSlot and includeScourge then
		controls.includeScourge = new("CheckBoxControl", {"TOPRIGHT",lastItemAnchor,"BOTTOMRIGHT"}, 0, 5, 18, "Scourge Mods:", function(state) end)
		controls.includeScourge.state = (self.lastIncludeScourge == nil or self.lastIncludeScourge == true)
		updateLastAnchor(controls.includeScourge)
	end

	if isAmuletSlot then
		controls.includeTalisman = new("CheckBoxControl", {"TOPRIGHT",lastItemAnchor,"BOTTOMRIGHT"}, 0, 5, 18, "Talisman Mods:", function(state) end)
		controls.includeTalisman.state = (self.lastIncludeTalisman == nil or self.lastIncludeTalisman == true)
		updateLastAnchor(controls.includeTalisman)
	end

	if isEldritchModSlot then
		controls.includeEldritch = new("CheckBoxControl", {"TOPRIGHT",lastItemAnchor,"BOTTOMRIGHT"}, 0, 5, 18, "Eldritch Mods:", function(state) end)
		controls.includeEldritch.state = (self.lastIncludeEldritch == true)
		updateLastAnchor(controls.includeEldritch)
	end

	if isJewelSlot then
		controls.jewelType = new("DropDownControl", {"TOPLEFT",lastItemAnchor,"BOTTOMLEFT"}, 0, 5, 100, 18, { "Any", "Base", "Abyss" }, function(index, value) end)
		controls.jewelType.selIndex = self.lastJewelType or 1
		controls.jewelTypeLabel = new("LabelControl", {"RIGHT",controls.jewelType,"LEFT"}, -5, 0, 0, 16, "Jewel Type:")
		updateLastAnchor(controls.jewelType)
	elseif slot and not isAbyssalJewelSlot then
		controls.influence1 = new("DropDownControl", {"TOPLEFT",lastItemAnchor,"BOTTOMLEFT"}, 0, 5, 100, 18, influenceDropdownNames, function(index, value) end)
		controls.influence1.selIndex = self.lastInfluence1 or 1
		controls.influence1Label = new("LabelControl", {"RIGHT",controls.influence1,"LEFT"}, -5, 0, 0, 16, "Influence 1:")

		controls.influence2 = new("DropDownControl", {"TOPLEFT",controls.influence1,"BOTTOMLEFT"}, 0, 5, 100, 18, influenceDropdownNames, function(index, value) end)
		controls.influence2.selIndex = self.lastInfluence2 or 1
		controls.influence2Label = new("LabelControl", {"RIGHT",controls.influence2,"LEFT"}, -5, 0, 0, 16, "Influence 2:")
		updateLastAnchor(controls.influence2, 46)
	end

	-- Add max price limit selection dropbox
	local currencyTable = {
		{ name = "Chaos Orb Equivalent", id = nil },
		{ name = "Chaos Orb", id = "chaos" },
		{ name = "Divine Orb", id = "divine" },
		{ name = "Orb of Alchemy", id = "alch" },
		{ name = "Orb of Alteration", id = "alt" },
		{ name = "Chromatic Orb", id = "chrome" },
		{ name = "Exalted Orb", id = "exalted" },
		{ name = "Blessed Orb", id = "blessed" },
		{ name = "Cartographer's Chisel", id = "chisel" },
		{ name = "Gemcutter's Prism", id = "gcp" },
		{ name = "Jeweller's Orb", id = "jewellers" },
		{ name = "Orb of Scouring", id = "scour" },
		{ name = "Orb of Regret", id = "regret" },
		{ name = "Orb of Fusing", id = "fusing" },
		{ name = "Orb of Chance", id = "chance" },
		{ name = "Regal Orb", id = "regal" },
		{ name = "Vaal Orb", id = "vaal" }
	}
	local currencyDropdownNames = { }
	for _, currency in ipairs(currencyTable) do
		t_insert(currencyDropdownNames, currency.name)
	end
	controls.maxPrice = new("EditControl", {"TOPLEFT",lastItemAnchor,"BOTTOMLEFT"}, 0, 5, 70, 18, nil, nil, "%D")
	controls.maxPriceType = new("DropDownControl", {"LEFT",controls.maxPrice,"RIGHT"}, 5, 0, 150, 18, currencyDropdownNames, nil)
	controls.maxPriceLabel = new("LabelControl", {"RIGHT",controls.maxPrice,"LEFT"}, -5, 0, 0, 16, "^7Max Price:")
	updateLastAnchor(controls.maxPrice)

	controls.maxLevel = new("EditControl", {"TOPLEFT",lastItemAnchor,"BOTTOMLEFT"}, 0, 5, 100, 18, nil, nil, "%D")
	controls.maxLevelLabel = new("LabelControl", {"RIGHT",controls.maxLevel,"LEFT"}, -5, 0, 0, 16, "Max Level:")
	updateLastAnchor(controls.maxLevel)

	-- basic filtering by slot for sockets and links, Megalomaniac does not have slot and Sockets use "Jewel nodeId"
	if slot and not slot.slotName:find("Jewel") and not slot.slotName:find("Flask") then
		controls.sockets = new("EditControl", {"TOPLEFT",lastItemAnchor,"BOTTOMLEFT"}, 0, 5, 70, 18, nil, nil, "%D")
		controls.socketsLabel = new("LabelControl", {"RIGHT",controls.sockets,"LEFT"}, -5, 0, 0, 16, "# of Sockets:")
		updateLastAnchor(controls.sockets)

		if not slot.slotName:find("Belt") and not slot.slotName:find("Ring") and not slot.slotName:find("Amulet") then
			controls.links = new("EditControl", {"TOPLEFT",lastItemAnchor,"BOTTOMLEFT"}, 0, 5, 70, 18, nil, nil, "%D")
			controls.linksLabel = new("LabelControl", {"RIGHT",controls.links,"LEFT"}, -5, 0, 0, 16, "# of Links:")
			updateLastAnchor(controls.links)
		end
	end

	for i, stat in ipairs(statWeights) do
		controls["sortStatType"..tostring(i)] = new("LabelControl", {"TOPLEFT",lastItemAnchor,"BOTTOMLEFT"}, 0, i == 1 and 5 or 3, 70, 16, i < (#statWeights < 6 and 10 or 5) and s_format("^7%.2f: %s", stat.weightMult, stat.label) or ("+ "..tostring(#statWeights - 4).." Additional Stats"))
		lastItemAnchor = controls["sortStatType"..tostring(i)]
		popupHeight = popupHeight + 19
		if i == 1 then
			controls.sortStatLabel = new("LabelControl", {"RIGHT",lastItemAnchor,"LEFT"}, -5, 0, 0, 16, "^7Stat to Sort By:")
		elseif i == 5 then
			-- tooltips do not actually work for labels
			lastItemAnchor.tooltipFunc = function(tooltip)
				tooltip:Clear()
				tooltip:AddLine(16, "Sorts the weights by the stats selected multiplied by a value")
				tooltip:AddLine(16, "Currently sorting by:")
				for i, stat in ipairs(statWeights) do
					if i > 4 then
						tooltip:AddLine(16, s_format("%s: %.2f", stat.label, stat.weightMult))
					end
				end
			end
			break
		end
	end
	popupHeight = popupHeight + 4

	controls.generateQuery = new("ButtonControl", { "BOTTOM", nil, "BOTTOM" }, -45, -10, 80, 20, "Execute", function()
		main:ClosePopup()

		if controls.includeCorrupted then
			self.lastIncludeCorrupted, options.includeCorrupted = controls.includeCorrupted.state, controls.includeCorrupted.state
		end
		if controls.includeSynthesis then
			self.lastIncludeSynthesis, options.includeSynthesis = controls.includeSynthesis.state, controls.includeSynthesis.state
		end
		if controls.includeEldritch then
			self.lastIncludeEldritch, options.includeEldritch = controls.includeEldritch.state, controls.includeEldritch.state
		end
		if controls.includeScourge then
			self.lastIncludeScourge, options.includeScourge = controls.includeScourge.state, controls.includeScourge.state
		end
		if controls.includeTalisman then
			self.lastIncludeTalisman, options.includeTalisman = controls.includeTalisman.state, controls.includeTalisman.state
		end
		if controls.influence1 then
			self.lastInfluence1, options.influence1 = controls.influence1.selIndex, controls.influence1.selIndex
		else
			options.influence1 = 1
		end
		if controls.influence2 then
			self.lastInfluence2, options.influence2 = controls.influence2.selIndex, controls.influence2.selIndex
		else
			options.influence2 = 1
		end
		if controls.jewelType then
			self.lastJewelType = controls.jewelType.selIndex
			options.jewelType = controls.jewelType.list[controls.jewelType.selIndex]
		end
		if controls.maxPrice.buf then
			options.maxPrice = tonumber(controls.maxPrice.buf)
			options.maxPriceType = currencyTable[controls.maxPriceType.selIndex].id
		end
		if controls.maxLevel.buf then
			options.maxLevel = tonumber(controls.maxLevel.buf)
		end
		if controls.sockets and controls.sockets.buf then
			options.sockets = tonumber(controls.sockets.buf)
		end
		if controls.links and controls.links.buf then
			options.links = tonumber(controls.links.buf)
		end
		options.statWeights = statWeights

		self:StartQuery(slot, options)
	end)
	controls.cancel = new("ButtonControl", { "BOTTOM", nil, "BOTTOM" }, 45, -10, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(400, popupHeight, "Query Options", controls)
end