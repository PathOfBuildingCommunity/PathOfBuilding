-- Path of Building
--
-- Module: Trade Query Generator
-- Generates weighted trade queries for item upgrades
--
local curl = require("lcurl.safe")

-- TODO generate these from data files
local itemCategoryTags = {
    ["Ring"] = { ["ring"] = true },
    ["Amulet"] = { ["amulet"] = true },
    ["Belt"] = { ["belt"] = true },
    ["Chest"] = { ["body_armour"] = true, ["str_armour"] = true, ["dex_armour"] = true, ["int_armour"] = true, ["str_int_armour"] = true, ["str_dex_armour"] = true, ["str_dex_int_armour"] = true },
    ["Helmet"] = { ["helmet"] = true, ["str_armour"] = true, ["dex_armour"] = true, ["int_armour"] = true, ["str_int_armour"] = true, ["str_dex_armour"] = true, ["str_dex_int_armour"] = true },
    ["Gloves"] = { ["gloves"] = true, ["str_armour"] = true, ["dex_armour"] = true, ["int_armour"] = true, ["str_int_armour"] = true, ["str_dex_armour"] = true, ["str_dex_int_armour"] = true },
    ["Boots"] = { ["boots"] = true, ["str_armour"] = true, ["dex_armour"] = true, ["int_armour"] = true, ["str_int_armour"] = true, ["str_dex_armour"] = true, ["str_dex_int_armour"] = true },
    ["Quiver"] = { ["quiver"] = true },
    ["Shield"] = { ["shield"] = true, ["focus"] = true, ["energy_shield"] = true, ["dex_shield"] = true, ["str_shield"] = true, ["str_int_shield"] = true, ["dex_int_shield"] = true, ["str_dex_shield"] = true },
    ["1HWeapon"] = { ["weapon"] = true, ["one_hand_weapon"] = true, ["onehand"] = true, ["axe"] = true, ["sword"] = true, ["rapier"] = true, ["mace"] = true, ["sceptre"] = true, ["dagger"] = true, ["rune_dagger"] = true, ["wand"] = true, ["claw"] = true },
    ["2HWeapon"] = { ["weapon"] = true, ["two_hand_weapon"] = true, ["twohand"] = true, ["staff"] = true, ["attack_staff"] = true, ["warstaff"] = true, ["bow"] = true,  ["axe"] = true, ["sword"] = true, ["mace"] = true, ["2h_sword"] = true, ["2h_axe"] = true, ["2h_mace"] = true },
    ["AbyssJewel"] = { ["default"] = true, ["abyss_jewel"] = true, ["abyss_jewel_melee"] = true, ["abyss_jewel_ranged"] = true, ["abyss_jewel_summoner"] = true, ["abyss_jewel_caster"] = true },
    ["BaseJewel"] = { ["default"] = true, ["not_int"] = true, ["not_str"] = true, ["not_dex"] = true },
    ["AnyJewel"] = { ["default"] = true, ["not_int"] = true, ["not_str"] = true, ["not_dex"] = true, ["abyss_jewel"] = true, ["abyss_jewel_melee"] = true, ["abyss_jewel_ranged"] = true, ["abyss_jewel_summoner"] = true, ["abyss_jewel_caster"] = true }
}

local tradeStatCategoryIndices = {
    ["Explicit"] = 2,
    ["Implicit"] = 3,
    ["Corrupted"] = 3,
    ["Scourge"] = 6
}

local influenceSuffixes = { "_shaper", "_elder", "_adjudicator", "_basilisk", "_crusader", "_eyrie"}
local influenceDropdownNames = { "None" }
local hasInfluenceModIds = { }
for i, curInfluenceInfo in ipairs(itemLib.influenceInfo) do
    influenceDropdownNames[i + 1] = curInfluenceInfo.display
    hasInfluenceModIds[i] = "pseudo.pseudo_has_" .. string.lower(curInfluenceInfo.display) .. "_influence"
end


-- This is not a complete list as most mods get caught with the find "Local" check, or don't overlap with non-local mods so we don't care. Some groups
-- are also shared between local and non-local mods, so a group only approach is not viable.
local localOnlyModGroups = {
    ["BaseLocalDefences"] = true,
    ["BaseLocalDefencesAndLife"] = true,
    ["LocalIncreasedPhysicalDamagePercentAndAccuracyRating"] = true,
    ["LocalPhysicalDamagePercent"] = true,
    ["DefencesPercent"] = true,
    ["DefencesPercentAndStunRecovery"] = true,
    ["LocalAttributeRequirements"] = true,
    ["DefencesPercentSuffix"] = true
}

local modData = {
    ["Explicit"] = { },
    ["Implicit"] = { },
    ["Corrupted"] = { },
    ["Scourge"] = { },
}

local MAX_FILTERS = 36

local function logToFile(...)
    --ConPrintf(...)
    --local f = io.open('../TradeQueryLog.log', 'a')
    --f:write(string.format(...))
    --f:write("\n")
    --f:close()
end

local TradeQueryGeneratorClass = newClass("TradeQueryGenerator", function(self, itemsTab)
    self:InitMods()
    self.itemsTab = itemsTab
    self.calcContext = { }

    table.insert(main.onFrameFuncs, function()
        self:OnFrame()
    end)
end)

-- TODO: fetching stats this way is almost certainly abusing the API. If this code gets merged, need to swap this to storing a local copy. If storing
-- a local copy, it would also make sense to run the entire InitMods logic offline as well and store that resulting table instead of this raw data.
local function fetchStats()
    local tradeStats = ""
	local easy = common.curl.easy()
	easy:setopt_url("https://www.pathofexile.com/api/trade/data/stats")
    easy:setopt_useragent("Chrome/79")
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

local function canModSpawnForItemCategory(mod, tags)
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
    return false
end

local function generateModData(mods, tradeQueryStatsParsed)
    for modId, mod in pairs(mods) do
        if localOnlyModGroups[mod.group] == true or (modId:find("Local") ~= nil and modId:find("Socketed") == nil) then -- skip all local mods other than socket level mods
            --logToFile("Skipping local mod: %s", modId)
            goto continue
        elseif modId:find("HellscapeDownside") ~= nil then -- skip scourge downsides, they often don't follow standard parsing rules, and should basically never be beneficial anyways
            goto continue
        end

        for index, modLine in ipairs(mod) do
            if modLine:find("Grants Level") then -- skip mods that grant skills, as they will often be overwhelmingly powerful but don't actually fit into the build
                goto nextModLine
            end

            local statOrder = modLine:find("Nearby Enemies have %-") ~= nil and mod.statOrder[index + 1] or mod.statOrder[index] -- hack to get minus res mods associated with the correct statOrder
            local modType = (mod.type == "Prefix" or mod.type == "Suffix") and "Explicit" or mod.type

            -- Special cases. Should try to clean these up a bit at some point if we can find reasonable patterns to systemize
            -- TODO:
            -- Curse Enemies with Despair on Hit
            -- Curse Enemies with Elemental Weakness on Hit
            -- Curse Enemies with Vulnerability on Hit
            -- Curse Enemies with Conductivity on Hit
            -- Curse Enemies with Frostbite on Hit
            -- Curse Enemies with Enfeeble on Hit
            -- Unnerve Enemies for 4 seconds on Hit
            -- Intimidate Enemies for 4 seconds on Hit
            -- Cover Enemies in Ash when they Hit you
            -- Gain Alchemist's Genius when you use a Flask
            local specialCaseData = { }
            if statOrder == 1802 then
                specialCaseData.overrideModLine = "+#% Chance to Block"
                modLine = modLine .. " (Shields)"
            elseif statOrder == 1725 then
                specialCaseData.overrideModLineSingular = "You can apply an additional curse"
                if modLine == specialCaseData.overrideModLineSingular then
                    modLine = "You can apply 1 additional Curses"
                end
            elseif statOrder == 1366 then
                specialCaseData.overrideModLineSingular = "Bow Attacks fire an additional Arrow"
                if modLine == specialCaseData.overrideModLineSingular then
                    modLine = "Bow Attacks fire 1 additional Arrows"
                end
            end

            -- If this is the first tier for this mod, find matching trade mod and init the entry
            if modData[modType][statOrder] == nil then
                local tradeMod = nil
                local matchStr = modLine:gsub("[#()0-9%-%+%.]","")
                for _, entry in ipairs(tradeQueryStatsParsed.result[tradeStatCategoryIndices[modType]].entries) do
                    if entry.text:gsub("[#()0-9%-%+%.]","") == matchStr then
                        tradeMod = entry
                        break
                    end
                end

                if tradeMod == nil then
                    logToFile("Unable to match %s mod: %s", modType, modLine)
                    goto nextModLine
                end

                modData[modType][statOrder] = { tradeMod = tradeMod, specialCaseData = specialCaseData }
            end

            -- tokenize the numerical variables for this mod and store the sign if there is one
            local tokens = { }
            local poundPos, tokenizeOffset = 0, 0
            while true do
                poundPos = modData[modType][statOrder].tradeMod.text:find("#", poundPos + 1)
                if poundPos == nil then
                    break
                end
                startPos, endPos, sign, min, max = modLine:find("([%+%-]?)%(?(%d+%.?%d*)%-?(%d*%.?%d*)%)?", poundPos + tokenizeOffset)

                if endPos == nil then
                    logToFile("Error extracting tokens from '%s' for tradeMod '%s'", modLine, modData[modType][statOrder].tradeMod.text)
                    goto nextModLine
                end

                tokenizeOffset = tokenizeOffset + (endPos - startPos)
                table.insert(tokens, min)
                table.insert(tokens, #max > 0 and tonumber(max) or tonumber(min))
                if sign ~= nil then
                    modData[modType][statOrder].sign = sign
                end
            end

            if #tokens ~= 0 and #tokens ~= 2 and #tokens ~= 4 then
                logToFile("Unexpected # of tokens found for mod: %s", mod[i])
                goto nextModLine
            end

            -- Update the min and max values available for each item category
            for category, tags in pairs(itemCategoryTags) do
                if canModSpawnForItemCategory(mod, tags) then
                    if modData[modType][statOrder][category] == nil then
                        modData[modType][statOrder][category] = { min = 999999, max = -999999 }
                    end

                    local modRange = modData[modType][statOrder][category]
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
end

function TradeQueryGeneratorClass:InitMods()
    local tradeStats = fetchStats()
    tradeStats:gsub("\n", " ")
    local tradeQueryStatsParsed = loadstring("return " .. jsonToLua(tradeStats))()

    -- explicit, corrupted, scourge, and jewel mods
    generateModData(data.itemMods.Item, tradeQueryStatsParsed)
    generateModData(data.veiledMods, tradeQueryStatsParsed)
    generateModData(data.itemMods.Jewel, tradeQueryStatsParsed)
    generateModData(data.itemMods.JewelAbyss, tradeQueryStatsParsed)

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
                if modData[modType][statOrder] == nil then
                    modData[modType][statOrder] = { tradeMod = tradeMod }
                end

                -- tokenize the numerical variables for this mod and store the sign if there is one
                local tokens = { }
                local poundPos, tokenizeOffset = 0, 0
                while true do
                    poundPos = modData[modType][statOrder].tradeMod.text:find("#", poundPos + 1)
                    if poundPos == nil then
                        break
                    end
                    startPos, endPos, sign, min, max = modLine:find("([%+%-]?)%(?(%d+%.?%d*)%-?(%d*%.?%d*)%)?", poundPos + tokenizeOffset)

                    if endPos == nil then
                        logToFile("Error extracting tokens from '%s' for tradeMod '%s'", modLine, modData[modType][statOrder].tradeMod.text)
                        goto continue
                    end

                    tokenizeOffset = tokenizeOffset + (endPos - startPos)
                    table.insert(tokens, min)
                    table.insert(tokens, #max > 0 and tonumber(max) or tonumber(min))
                    if sign ~= nil then
                        modData[modType][statOrder].sign = sign
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
                        if categoryTags[tag] == true then
                            tagMatch = true
                            break
                        end
                    end

                    if tagMatch then
                        if modData[modType][statOrder][category] == nil then
                            modData[modType][statOrder][category] = { min = 999999, max = -999999, subType = entry.subType }
                        end

                        local modRange = modData[modType][statOrder][category]
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

            -- Test with a value halfway between the min and max available for this mod in this slot. Note that this can generate slightly different values for the same mod as implicit vs explicit.
            local modValue = math.ceil((entry[self.calcContext.itemCategory].max - entry[self.calcContext.itemCategory].min) / 2 + entry[self.calcContext.itemCategory].min)
            local modValueStr = (entry.sign and entry.sign or "") .. tostring(modValue)
            local modLine = entry.tradeMod.text:gsub("#",modValueStr)

            self.calcContext.testItem.explicitModLines[1] = { line = modLine, custom = true }
            self.calcContext.testItem:BuildAndParseRaw()

            if (self.calcContext.testItem.modList ~= nil and #self.calcContext.testItem.modList == 0) or (self.calcContext.testItem.slotModList ~= nil and #self.calcContext.testItem.slotModList[1] == 0 and #self.calcContext.testItem.slotModList[2] == 0) then
                logToFile("Failed to test %s mod: %s", self.calcContext.itemCategory, modLine)
            end

            local meanDPSDiff = self:GetDPS() - self.calcContext.baseDPS
            if meanDPSDiff > 0.01 then
                table.insert(self.modWeights, { tradeModId = entry.tradeMod.id, weight = meanDPSDiff / modValue, meanDPSDiff = meanDPSDiff, invert = entry.sign == "-" and true or false })
                self.alreadyWeightedMods[entry.tradeMod.id] = true
            end

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
    end
end

function TradeQueryGeneratorClass:GetDPS()
    local build = self.itemsTab.build

	-- Manually refresh build calcs (skip updating stat display)
	build.outputRevision = build.outputRevision + 1
	build.calcsTab:BuildOutput()

    local calcs = build.calcsTab.calcs
    local env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(build, "CALCULATOR")
	calcs.perform(env)
	local fullDPS = calcs.calcFullDPS(build, "CALCULATOR", {}, { cachedPlayerDB = cachedPlayerDB, cachedEnemyDB = cachedEnemyDB, cachedMinionDB = cachedMinionDB, env = env})
	--env.player.output.SkillDPS = fullDPS.skills

	return fullDPS.combinedDPS
end

function TradeQueryGeneratorClass:InitQuery(slot, options)
    -- Figure out what type of item we're searching for
    local existingItem = self.itemsTab.items[slot.selItemId]
    local testItemType = existingItem.baseName
    local itemCategoryQueryStr
    local itemCategory
    if slot.slotName == "Weapon 2" or slot.slotName == "Weapon 1" then
        if existingItem.type == "Shield" then
            itemCategoryQueryStr = "armour.shield"
            itemCategory = "Shield"
        elseif existingItem.type == "Quiver" then
            itemCategoryQueryStr = "armour.quiver"
            itemCategory = "Quiver"
        elseif existingItem.type == "Staff" or existingItem.type:find("Two Handed") ~= nil then
            itemCategoryQueryStr = "weapon.twomelee"
            itemCategory = "2HWeapon"
        elseif existingItem.type == "Wand" or existingItem.type == "Dagger" or existingItem.type == "Claw" or existingItem.type:find("One Handed") ~= nil then
            itemCategoryQueryStr = "weapon.one"
            itemCategory = "1HWeapon"
        else
            logToFile("'%s' is not supported for weighted trade query generation", existingItem.type)
            return
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
    else
        logToFile("'%s' is not supported for weighted trade query generation", existingItem.type)
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

	-- Unequip item in requested slot and replace with test item
	local originalItemId = slot.selItemId
    self.itemsTab:AddItem(testItem, true)
	slot:SetSelItemId(testItem.id)
	self.itemsTab:PopulateSlots()

	-- Test each mod one at a time and cache the normalized DPS diff to use as weight
    self.modWeights = { }
    self.alreadyWeightedMods = { }
    self.calcContext = {
        itemCategoryQueryStr = itemCategoryQueryStr,
        itemCategory = itemCategory,
        testItem = testItem,
        baseDPS = self:GetDPS(),
        options = options,
        slot = slot,
        originalItemId = originalItemId
    }

    self.calcContext.co = coroutine.create(self.ExecuteQuery)
end

function TradeQueryGeneratorClass:ExecuteQuery()
    -- Open progress tracking blocker popup
    local controls = { }
    controls.progressText = new("LabelControl", {"TOP",nil,"TOP"}, 0, 30, 0, 16, string.format("Calculating Mod Weights..."))
	self.calcContext.popup = main:OpenPopup(280, 65, "Please Wait", controls)

    self:GenerateModWeights(modData["Explicit"])
    self:GenerateModWeights(modData["Implicit"])
    if self.calcContext.options.includeCorrupted then
        self:GenerateModWeights(modData["Corrupted"])
    end
    if self.calcContext.options.includeScourge then
        self:GenerateModWeights(modData["Scourge"])
    end

    -- Calc original item DPS without anoint or enchant, and use that diff as a basis for default min sum.
    local originalItem = self.itemsTab.items[self.calcContext.originalItemId]
    self.calcContext.testItem.explicitModLines = { }
    for _, modLine in ipairs(originalItem.explicitModLines) do
        table.insert(self.calcContext.testItem.explicitModLines, modLine)
    end
    for _, modLine in ipairs(originalItem.scourgeModLines) do
        table.insert(self.calcContext.testItem.explicitModLines, modLine)
	end
	for _, modLine in ipairs(originalItem.implicitModLines) do
        table.insert(self.calcContext.testItem.explicitModLines, modLine)
	end
    self.calcContext.testItem:BuildAndParseRaw()
    local currentDPSDiff = self:GetDPS() - self.calcContext.baseDPS

    -- This DPS diff value will generally be higher than the weighted sum of the same item, because the stats are all applied at once and can thus multiply off each other.
    -- So apply a modifier to get a reasonable min and hopefully approximate that the query will start out with small upgrades.
    local minWeight = currentDPSDiff * 0.7

	-- Restore original item to slot
    self.itemsTab:DeleteItem(self.calcContext.testItem)
	self.calcContext.slot:SetSelItemId(self.calcContext.originalItemId)
	self.itemsTab:PopulateSlots()
	self.itemsTab.build.buildFlag = true

    -- Sort by mean DPS diff rather than weight to more accurately prioritize stats that can contribute more
    table.sort(self.modWeights, function(a, b)
        return a.meanDPSDiff > b.meanDPSDiff
    end)

	-- Generate trade query str and open in browser
    if #self.modWeights > 0 then
        local filters = 0

        -- TODO: this would be much easier to build as a lua table, but we'd need a lua to json translator
        local queryString = "https://www.pathofexile.com/trade/search/Scourge?q={\"query\":{\"filters\":{\"type_filters\":{\"filters\":{\"category\":{\"option\":\"" .. self.calcContext.itemCategoryQueryStr .. "\"},\"rarity\": {\"option\": \"nonunique\"}}}},\"status\":{\"option\":\"online\"},\"stats\":["

        local options = self.calcContext.options
        if options.influence1 > 1 or options.influence2 > 1 then
            queryString = queryString .. "{\"type\":\"and\",\"filters\":["

            if options.influence1 > 1 then
                queryString = queryString .. "{\"id\": \"" .. hasInfluenceModIds[options.influence1 - 1] .. "\"}"
                filters = filters + 1
            end
            if options.influence2 > 1 then
                if options.influence1 > 1 then
                    queryString = queryString .. ","
                end
                queryString = queryString .. "{\"id\": \"" .. hasInfluenceModIds[options.influence2 - 1] .. "\"}"
                filters = filters + 1
            end
            queryString = queryString .. "]},"
        end

        queryString = queryString .. "{\"type\":\"weight\",\"value\":{\"min\":" .. minWeight .. "},\"filters\":["

        for _, entry in pairs(self.modWeights) do
            queryString = queryString .. "{\"id\": \"" .. entry.tradeModId .. "\",\"value\": {\"weight\": " .. (entry.invert == true and "-" or "") .. entry.weight .. "}},"
            filters = filters + 1
            if filters == MAX_FILTERS then
                break
            end
        end

        queryString = queryString:sub(1, #queryString - 1)
        queryString = queryString .. "]}]},\"sort\":{\"statgroup.0\": \"desc\"}}"

        OpenURL(queryString)
    end

    -- Close blocker popup
    main:ClosePopup()
end

function TradeQueryGeneratorClass:GenerateQuery(slot)
    local controls = { }
    local options = { }
    local popupHeight = 95

    local isJewelSlot = slot.slotName:find("Jewel") ~= nil
    local isAbyssalJewelSlot = slot.slotName:find("Abyssal") ~= nil
    local isAmuletSlot = slot.slotName == "Amulet"

    controls.includeCorrupted = new("CheckBoxControl", {"TOP",nil,"TOP"}, 0, 30, 18, "Corrupted Mods:", function(state) end)
    controls.includeCorrupted.state = (self.lastIncludeCorrupted == nil or self.lastIncludeCorrupted == true)

    if not isJewelSlot and not isAbyssalJewelSlot then
        controls.includeScourge = new("CheckBoxControl", {"TOPRIGHT",controls.includeCorrupted,"BOTTOMRIGHT"}, 0, 5, 18, "Scourge Mods:", function(state) end)
        controls.includeScourge.state = (self.lastIncludeScourge  == nil or self.lastIncludeScourge == true)

        popupHeight = popupHeight + 23
    end

    if isAmuletSlot then
        controls.includeTalisman = new("CheckBoxControl", {"TOPRIGHT",controls.includeScourge,"BOTTOMRIGHT"}, 0, 5, 18, "Talisman Mods:", function(state) end)
        controls.includeTalisman.state = (self.lastIncludeTalisman  == nil or self.lastIncludeTalisman == true)

        popupHeight = popupHeight + 23
    end

    if isJewelSlot then
        controls.jewelType = new("DropDownControl", {"TOPLEFT",controls.includeCorrupted,"BOTTOMLEFT"}, 0, 5, 100, 18, { "Any", "Base", "Abyss" }, function(index, value) end)
        controls.jewelType.selIndex = self.lastJewelType or 1
        controls.jewelTypeLabel = new("LabelControl", {"RIGHT",controls.jewelType,"LEFT"}, -5, 0, 0, 16, "Jewel Type:")

        popupHeight = popupHeight + 23
    elseif not isAbyssalJewelSlot then
        controls.influence1 = new("DropDownControl", {"TOPLEFT",controls.includeTalisman and controls.includeTalisman or controls.includeScourge,"BOTTOMLEFT"}, 0, 5, 100, 18, influenceDropdownNames, function(index, value) end)
        controls.influence1.selIndex = self.lastInfluence1 or 1
        controls.influence1Label = new("LabelControl", {"RIGHT",controls.influence1,"LEFT"}, -5, 0, 0, 16, "Influence 1:")

        controls.influence2 = new("DropDownControl", {"TOPLEFT",controls.influence1,"BOTTOMLEFT"}, 0, 5, 100, 18, influenceDropdownNames, function(index, value) end)
        controls.influence2.selIndex = self.lastInfluence2 or 1
        controls.influence2Label = new("LabelControl", {"RIGHT",controls.influence2,"LEFT"}, -5, 0, 0, 16, "Influence 2:")

        popupHeight = popupHeight + 46
    end

	controls.generateQuery = new("ButtonControl", { "BOTTOM", nil, "BOTTOM" }, -45, -10, 80, 20, "Execute", function()
		main:ClosePopup()

        if controls.includeCorrupted then
            self.lastIncludeCorrupted, options.includeCorrupted = controls.includeCorrupted.state, controls.includeCorrupted.state
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

        self:InitQuery(slot, options)
    end)
	controls.cancel = new("ButtonControl", { "BOTTOM", nil, "BOTTOM" }, 45, -10, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(280, popupHeight, "Query Options", controls)
end
