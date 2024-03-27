-- Path of Building
--
-- Module: Config Options
-- List of options for the Configuration tab.
--

local m_min = math.min
local m_max = math.max
local s_format = string.format

local function applyPantheonDescription(tooltip, mode, index, value)
	tooltip:Clear()
	if value.val == "None" then
		return
	end
	local applyModes = { BODY = true, HOVER = true }
	if applyModes[mode] then
		local god = data.pantheons[value.val]
		for _, soul in ipairs(god.souls) do
			local name = soul.name
			local lines = { }
			for _, mod in ipairs(soul.mods) do
				table.insert(lines, mod.line)
			end
			tooltip:AddLine(20, '^8'..name)
			tooltip:AddLine(14, '^6'..table.concat(lines, '\n'))
			tooltip:AddSeparator(10)
		end
	end
end

local function banditTooltip(tooltip, mode, index, value)
	local banditBenefits = {
		["None"] = "Grants 2 Passive Skill Points",
		["Oak"] = "Regenerate 1% of Life per second\n2% additional Physical Damage Reduction\n20% increased Physical Damage",
		["Kraityn"] = "6% increased Attack and Cast Speed\n10% chance to Avoid Elemental Ailments\n6% increased Movement Speed",
		["Alira"] = "Regenerate 5 Mana per second\n+20% to Critical Strike Multiplier\n+15% to all Elemental Resistances",
	}
	local applyModes = { BODY = true, HOVER = true }
	tooltip:Clear()
	if applyModes[mode] then
		tooltip:AddLine(14, '^8'..banditBenefits[value.val])
	end
end

local function bossSkillsTooltip(tooltip, mode, index, value)
	local applyModes = { BODY = true, HOVER = true }
	tooltip:Clear()
	if applyModes[mode] then
		tooltip:AddLine(14, [[
^7Used to fill in defaults for specific boss skills if the boss config is not set

Bosses' damage is modified by roll range configuration, defaulted at a 70% roll, at the normal monster level for your character level (capped at 85)
Fill in the exact damage numbers if more precision is needed]])
		if value.val ~= "None" then
			tooltip:AddLine(14, '\n^7'..value.val..": "..data.bossSkills[value.val].tooltip)
		end
	end
end

local function LowLifeTooltip(modList, build)
	local out = 'You will automatically be considered to be on Low ^xE05030Life ^7if you have at least '..100 - build.calcsTab.mainOutput.LowLifePercentage..'% ^xE05030Life ^7reserved'
	out = out..'\nbut you can use this option to force it if necessary.'
	return out
end

local function FullLifeTooltip(modList, build)
	local out = 'You can be considered to be on Full ^xE05030Life ^7if you have at least '..build.calcsTab.mainOutput.FullLifePercentage..'% ^xE05030Life ^7left.'
	out = out..'\nYou will automatically be considered to be on Full ^xE05030Life ^7if you have Chaos Inoculation,'
	out = out..'\nbut you can use this option to force it if necessary.'
	return out
end

local function mapAffixTooltip(tooltip, mode, index, value)
	tooltip:Clear()
	if value.val == "NONE" then
		return
	end
	local applyModes = { BODY = true, HOVER = true }
	if applyModes[mode] then
		tooltip:AddLine(14, '^7'..value.val)
		local affixData = data.mapMods.AffixData[value.val] or {}
		if #affixData.tooltipLines > 0 then
			if affixData.type == "check" then
				for _, line in ipairs(affixData.tooltipLines) do
					tooltip:AddLine(14, '^7'..line)
				end
			elseif affixData.type == "list" then
				for i, tier in ipairs({"Low", "Med", "High"}) do
					tooltip:AddLine(16, '^7'..tier..": ")
					for j, line in ipairs(affixData.tooltipLines) do
						local modValue = (#affixData.tooltipLines > 1) and affixData.values[i][j] or affixData.values[i]
						if modValue == nil then
							tooltip:AddLine(14, '   ^7'..line)
						elseif modValue ~= 0 then
							tooltip:AddLine(14, '   ^7'..s_format(line, modValue))
						end
					end
				end
			elseif affixData.type == "count" then
				for i, tier in ipairs({"Low", "Med", "High"}) do
					tooltip:AddLine(16, '^7'..tier..": ")
					for j, line in ipairs(affixData.tooltipLines) do
						local modValue = {(#affixData.tooltipLines > 1) and (affixData.values[i][j] and affixData.values[i][j][1] or nil) or affixData.values[i][1], (#affixData.tooltipLines > 1) and (affixData.values[i][j] and affixData.values[i][j][2] or nil) or affixData.values[i][2]}
						if modValue[2] == nil then
							tooltip:AddLine(14, '   ^7'..line)
						elseif modValue[2] ~= 0 then
							tooltip:AddLine(14, '   ^7'..s_format(line, modValue[1], modValue[2]))
						end
					end
				end
			end
		end
	end
end

local function mapAffixDropDownFunction(val, modList, enemyModList, build)
	if val ~= "NONE" then
		local affixData = data.mapMods.AffixData[val] or {}
		if affixData.apply then
			if affixData.type == "check" then
				affixData.apply(var, (1 + (build.configTab.input['multiplierMapModEffect'] or 0)/100), modList, enemyModList)
			elseif affixData.type == "list" then
				affixData.apply(4 - (build.configTab.varControls['multiplierMapModTier'].selIndex or 1), (1 + (build.configTab.input['multiplierMapModEffect'] or 0)/100), affixData.values, modList, enemyModList)
			elseif affixData.type == "count" then
				affixData.apply(4 - (build.configTab.varControls['multiplierMapModTier'].selIndex or 1), 100, (1 + (build.configTab.input['multiplierMapModEffect'] or 0)/100), affixData.values, modList, enemyModList)
			end
		end
	end
end

return {
	-- Section: General options
	{ section = "General", col = 1 },
	{ var = "resistancePenalty", type = "list", label = "Resistance penalty:", list = {{val=0,label="None"},{val=-30,label="Act 5 (-30%)"},{val=-60,label="Act 10 (-60%)"}}, defaultIndex = 3 },
	{ var = "bandit", type = "list", label = "Bandit quest:", tooltipFunc = banditTooltip, list = {{val="None",label="Kill all"},{val="Oak",label="Help Oak"},{val="Kraityn",label="Help Kraityn"},{val="Alira",label="Help Alira"}} },
	{ var = "pantheonMajorGod", type = "list", label = "Major God:", tooltipFunc = applyPantheonDescription, list = {
		{ label = "Nothing", val = "None" },
		{ label = "Soul of the Brine King", val = "TheBrineKing" },
		{ label = "Soul of Lunaris", val = "Lunaris" },
		{ label = "Soul of Solaris", val = "Solaris" },
		{ label = "Soul of Arakaali", val = "Arakaali" },
	} },
	{ var = "pantheonMinorGod", type = "list", label = "Minor God:", tooltipFunc = applyPantheonDescription, list = {
		{ label = "Nothing", val = "None" },
		{ label = "Soul of Gruthkul", val = "Gruthkul" },
		{ label = "Soul of Yugul", val = "Yugul" },
		{ label = "Soul of Abberath", val = "Abberath" },
		{ label = "Soul of Tukohama", val = "Tukohama" },
		{ label = "Soul of Garukhan", val = "Garukhan" },
		{ label = "Soul of Ralakesh", val = "Ralakesh" },
		{ label = "Soul of Ryslatha", val = "Ryslatha" },
		{ label = "Soul of Shakari", val = "Shakari" },
	} },
	{ var = "detonateDeadCorpseLife", type = "count", label = "Enemy Corpse ^xE05030Life:", ifSkillData = "explodeCorpse", tooltip = "Sets the maximum ^xE05030life ^7of the target corpse for Detonate Dead and similar skills.\nFor reference, a level 70 monster has "..data.monsterLifeTable[70].." base ^xE05030life^7, and a level 80 monster has "..data.monsterLifeTable[80]..".", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "corpseLife", value = val }, "Config")
	end },
	{ var = "conditionStationary", type = "count", label = "Time spent stationary", ifCond = "Stationary",
		tooltip = "Applies mods that use `while stationary` and `per / every second while stationary`",
		apply = function(val, modList, enemyModList)
		if type(val) == "boolean" then
			-- Backwards compatibility with older versions that set this condition as a boolean
			val = val and 1 or 0
		end
		local sanitizedValue = m_max(0, val)
		modList:NewMod("Multiplier:StationarySeconds", "BASE", sanitizedValue, "Config")
		if sanitizedValue > 0 then
			modList:NewMod("Condition:Stationary", "FLAG", true, "Config")
		end
	end },
	{ var = "conditionMoving", type = "check", label = "Are you always moving?", ifCond = "Moving", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Moving", "FLAG", true, "Config")
	end },
	{ var = "conditionInsane", type = "check", label = "Are you insane?", ifCond = "Insane", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Insane", "FLAG", true, "Config")
	end },
	{ var = "conditionFullLife", type = "check", label = "Are you always on Full ^xE05030Life?", ifCond = "FullLife", tooltip = FullLifeTooltip, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullLife", "FLAG", true, "Config")
	end },
	{ var = "conditionLowLife", type = "check", label = "Are you always on Low ^xE05030Life?", ifCond = "LowLife", tooltip = LowLifeTooltip, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LowLife", "FLAG", true, "Config")
	end },
	{ var = "conditionFullMana", type = "check", label = "Are you always on Full ^x7070FFMana?", ifCond = "FullMana", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullMana", "FLAG", true, "Config")
	end },
	{ var = "conditionLowMana", type = "check", label = "Are you always on Low ^x7070FFMana?", ifCond = "LowMana", tooltip = "You will automatically be considered to be on Low ^x7070FFMana ^7if you have at least 50% ^x7070FFmana ^7reserved,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LowMana", "FLAG", true, "Config")
	end },
	{ var = "conditionFullEnergyShield", type = "check", label = "Are you always on Full ^x88FFFFEnergy Shield?", ifCond = "FullEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullEnergyShield", "FLAG", true, "Config")
	end },
	{ var = "conditionLowEnergyShield", type = "check", label = "Are you always on Low ^x88FFFFEnergy Shield?", ifCond = "LowEnergyShield", tooltip = "You will automatically be considered to be on Low ^x88FFFFEnergy Shield ^7if you have at least 50% ^x88FFFFES ^7reserved,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LowEnergyShield", "FLAG", true, "Config")
	end },
	{ var = "conditionHaveEnergyShield", type = "check", label = "Do you always have ^x88FFFFEnergy Shield?", ifCond = "HaveEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveEnergyShield", "FLAG", true, "Config")
	end },
	{ var = "minionsConditionFullLife", type = "check", label = "Are your Minions always on Full ^xE05030Life?", ifMinionCond = "FullLife", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:FullLife", "FLAG", true, "Config") }, "Config")
	end },
	{ var = "minionsConditionFullEnergyShield", type = "check", label = "Minion is always on Full ^x88FFFFEnergy Shield?", ifMinionCond = "FullEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:FullEnergyShield", "FLAG", true, "Config") }, "Config")
	end },
	{ var = "minionsConditionCreatedRecently", type = "check", label = "Have your Minions been created Recently?", ifCond = "MinionsCreatedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MinionsCreatedRecently", "FLAG", true, "Config")
	end },
	{ var = "igniteMode", type = "list", label = "Ailment calculation mode:", tooltip = "Controls how the base damage for applying Ailments is calculated:\n\tAverage: damage is based on the average application, including both crits and non-crits\n\tCrits Only: damage is based solely on Ailments inflicted with crits", list = {{val="AVERAGE",label="Average"},{val="CRIT",label="Crits Only"}} },
	{ var = "physMode", type = "list", label = "Random element mode:", ifFlag = "randomPhys", tooltip = "Controls how modifiers which choose a random element will function.\n\tAverage: Modifiers will grant one third of their value to ^xB97123Fire^7, ^x3F6DB3Cold^7, and ^xADAA47Lightning ^7simultaneously\n\t^xB97123Fire ^7/ ^x3F6DB3Cold ^7/ ^xADAA47Lightning^7: Modifiers will grant their full value as the specified element\nIf a modifier chooses between just two elements, the full value can only be given as those two elements.", list = {{val="AVERAGE",label="Average"},{val="FIRE",label="^xB97123Fire"},{val="COLD",label="^x3F6DB3Cold"},{val="LIGHTNING",label="^xADAA47Lightning"}} },
	{ var = "lifeRegenMode", type = "list", label = "^xE05030Life ^7regen calculation mode:", ifCond = { "LifeRegenBurstAvg", "LifeRegenBurstFull" }, tooltip = "Controls how ^xE05030life ^7regeneration is calculated:\n\tMinimum: does not include burst regen\n\tAverage: includes burst regen, averaged based on uptime\n\tBurst: includes full burst regen", list = {{val="MIN",label="Minimum"},{val="AVERAGE",label="Average"},{val="FULL",label="Burst"}}, apply = function(val, modList, enemyModList)
		if val == "AVERAGE" then
			modList:NewMod("Condition:LifeRegenBurstAvg", "FLAG", true, "Config")
		elseif val == "FULL" then
			modList:NewMod("Condition:LifeRegenBurstFull", "FLAG", true, "Config")
		end
	end },
	{ var = "resourceGainMode", type = "list", label = "Resource gain calculation mode:", ifCond = "AverageResourceGain", defaultIndex = 2, tooltip = "Controls how resource on hit/kill is calculated:\n\tMinimum: does not include chances\n\tAverage: includes chance gains, averaged based on uptime\n\tMaximum: treats all chances as certain", list = {{val="MIN",label="Minimum"},{val="AVERAGE",label="Average"},{val="MAX",label="Maximum"}}, apply = function(val, modList, enemyModList)
		if val == "AVERAGE" then
			modList:NewMod("Condition:AverageResourceGain", "FLAG", true, "Config")
		elseif val == "MAX" then
			modList:NewMod("Condition:MaxResourceGain", "FLAG", true, "Config")
		end
	end },
	{ var = "EHPUnluckyWorstOf", type = "list", label = "EHP calc unlucky:", tooltip = "Sets the EHP calc to pretend its unlucky and reduce the effects of random events", list = {{val=1,label="Average"},{val=2,label="Unlucky"},{val=4,label="Very Unlucky"}} },
	{ var = "DisableEHPGainOnBlock", type = "check", label = "Disable EHP gain on block/suppress:", ifMod = {"LifeOnBlock", "ManaOnBlock", "EnergyShieldOnBlock", "EnergyShieldOnSpellBlock", "LifeOnSuppress", "EnergyShieldOnSuppress"}, tooltip = "Sets the EHP calc to not apply gain on block and suppress effects"},
	{ var = "armourCalculationMode", type = "list", label = "Armour calculation mode:", ifCond = { "ArmourMax", "ArmourAvg" }, tooltip = "Controls how Defending with Double Armour is calculated:\n\tMinimum: never Defend with Double Armour\n\tAverage: Damage Reduction from Defending with Double Armour is proportional to chance\n\tMaximum: always Defend with Double Armour\nThis setting has no effect if you have 100% chance to Defend with Double Armour.", list = {{val="MIN",label="Minimum"},{val="AVERAGE",label="Average"},{val="MAX",label="Maximum"}}, apply = function(val, modList, enemyModList)
		if val == "MAX" then
			modList:NewMod("Condition:ArmourMax", "FLAG", true, "Config")
		elseif val == "AVERAGE" then
			modList:NewMod("Condition:ArmourAvg", "FLAG", true, "Config")
		end
	end },
	{ var = "warcryMode", type = "list", label = "Exerted/Boosted calc mode:", ifSkill = { "Fist of War", "Infernal Cry", "Ancestral Cry", "Enduring Cry", "General's Cry", "Intimidating Cry", "Rallying Cry", "Seismic Cry", "Battlemage's Cry" }, tooltip = "Controls how exerted attacks from Warcries are calculated:\nAverage: Averages out Warcry usage with cast time, attack speed and warcry cooldown.\nMax Hit: Shows maximum hit for lining up all warcries.", list = {{val="AVERAGE",label="Average"},{val="MAX",label="Max Hit"}}, apply = function(val, modList, enemyModList)
		if val == "MAX" then
			modList:NewMod("Condition:WarcryMaxHit", "FLAG", true, "Config")
		end
	end },
	{ var = "EVBypass", type = "check", label = "Disable Emperor's Vigilance Bypass", ifCond = "EVBypass", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EVBypass", "FLAG", true, "Config")
	end },
	{ var = "ignoreItemDisablers", type = "check", label = "Don't disable items", ifTagType = "DisablesItem", tooltip = "Ignore the effects of things which disable items, like Bringer of Rain" },
	{ var = "ignoreJewelLimits", type = "check", label = "Ignore Jewel Limits", tooltip = "Ignore the limits on jewels" },
	{ var = "overrideEmptyRedSockets", type = "count", label = "# of Empty ^xE05030Red^7 Sockets", ifMult = "EmptyRedSocketsInAnySlot",  tooltip = "This option allows you to override the default calculation for the number of Empty ^xE05030Red^7 Sockets.\nThe default calculation assumes enabled gems in skill socket groups fill the item in socket order disregarding gem colour.\nLeave blank for default calculation." },
	{ var = "overrideEmptyGreenSockets", type = "count", label = "# of Empty ^x70FF70Green^7 Sockets", ifMult = "EmptyGreenSocketsInAnySlot", tooltip = "This option allows you to override the default calculation for the number of Empty ^x70FF70Green^7 Sockets.\nThe default calculation assumes enabled gems in skill socket groups fill the item in socket order disregarding gem colour.\nLeave blank for default calculation." },
	{ var = "overrideEmptyBlueSockets", type = "count", label = "# of Empty ^x7070FFBlue^7 Sockets", ifMult = "EmptyBlueSocketsInAnySlot", tooltip = "This option allows you to override the default calculation for the number of Empty ^x7070FFBlue^7 Sockets.\nThe default calculation assumes enabled gems in skill socket groups fill the item in socket order disregarding gem colour.\nLeave blank for default calculation." },
	{ var = "overrideEmptyWhiteSockets", type = "count", label = "# of Empty White Sockets", ifMult = "EmptyWhiteSocketsInAnySlot", tooltip = "This option allows you to override the default calculation for the number of Empty White Sockets.\nThe default calculation assumes enabled gems in skill socket groups fill the item in socket order disregarding gem colour.\nLeave blank for default calculation." },

	-- Section: Skill-specific options
	{ section = "Skill Options", col = 2 },
	{ label = "Aspect of the Avian:", ifSkill = "Aspect of the Avian" },
	{ var = "aspectOfTheAvianAviansMight", type = "check", label = "Is Avian's Might active?", ifSkill = "Aspect of the Avian", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AviansMightActive", "FLAG", true, "Config")
	end },
	{ var = "aspectOfTheAvianAviansFlight", type = "check", label = "Is Avian's Flight active?", ifSkill = "Aspect of the Avian", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AviansFlightActive", "FLAG", true, "Config")
	end },
	{ label = "Aspect of the Cat:", ifSkill = "Aspect of the Cat" },
	{ var = "aspectOfTheCatCatsStealth", type = "check", label = "Is Cat's Stealth active?", ifSkill = "Aspect of the Cat", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CatsStealthActive", "FLAG", true, "Config")
	end },
	{ var = "aspectOfTheCatCatsAgility", type = "check", label = "Is Cat's Agility active?", ifSkill = "Aspect of the Cat", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CatsAgilityActive", "FLAG", true, "Config")
	end },
	{ label = "Aspect of the Crab:", ifSkill = "Aspect of the Crab" },
	{ var = "overrideCrabBarriers", type = "count", label = "# of Crab Barriers (if not maximum):", ifSkill = "Aspect of the Crab", apply = function(val, modList, enemyModList)
		modList:NewMod("CrabBarriers", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ label = "Aspect of the Spider:", ifSkill = "Aspect of the Spider" },
	{ var = "aspectOfTheSpiderWebStacks", type = "count", label = "# of Spider's Web Stacks:", ifSkill = "Aspect of the Spider", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraSkillMod", "LIST", { mod = modLib.createMod("Multiplier:SpiderWebApplyStack", "BASE", val) }, "Config", { type = "SkillName", skillName = "Aspect of the Spider" })
	end },
	{ label = "Banner Skills:", ifSkill = { "Dread Banner", "War Banner", "Defiance Banner" } },
	{ var = "bannerPlanted", type = "check", label = "Is Banner Planted?", ifSkill = { "Dread Banner", "War Banner", "Defiance Banner" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BannerPlanted", "FLAG", true, "Config")
	end },
	{ var = "bannerStages", type = "count", label = "Banner Stages:", ifSkill = { "Dread Banner", "War Banner", "Defiance Banner" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:BannerStage", "BASE", m_min(val, 50), "Config")
	end },
	{ label = "Barkskin:", ifSkill = "Barkskin" },
	{ var = "barkskinStacks", type = "count", label = "# of Barkskin Stacks:", ifSkill = "Barkskin", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:BarkskinStacks", "BASE",  m_min(val, 10), "Config")
		modList:NewMod("Multiplier:MissingBarkskinStacks", "BASE", m_max(-val, -10), "Config")
	end },
	{ label = "Bladestorm:", ifSkill = "Bladestorm", includeTransfigured = true },
	{ var = "bladestormInBloodstorm", type = "check", label = "Are you in a Bloodstorm?", ifSkill = "Bladestorm", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BladestormInBloodstorm", "FLAG", true, "Config", { type = "SkillName", skillName = "Bladestorm", includeTransfigured = true })
	end },
	{ var = "bladestormInSandstorm", type = "check", label = "Are you in a Sandstorm?", ifSkill = "Bladestorm", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BladestormInSandstorm", "FLAG", true, "Config", { type = "SkillName", skillName = "Bladestorm", includeTransfigured = true })
	end },
	{ label = "Blood Sacrament:", ifSkill = "Blood Sacrament" },
	{ var = "bloodSacramentReservationEHP", type = "check", label = "Count Skill Reservation towards eHP?", ifSkill = "Blood Sacrament", tooltip = "Use this option to disable the skill reservation factoring into eHP calculations",apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BloodSacramentReservationEHP", "FLAG", true, "Config")
	end },
	{ label = "Trauma:", ifFlag = "HasTrauma" },
	{ var = "traumaStacks", type = "count", label = "# of Trauma Stacks:", ifFlag = "HasTrauma", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:TraumaStacks", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ label = "Brand Skills:", ifSkill = { "Armageddon Brand", "Storm Brand", "Arcanist Brand", "Penance Brand", "Wintertide Brand" }, includeTransfigured = true }, -- I barely resisted the temptation to label this "Generic Brand:"
	{ var = "ActiveBrands", type = "count", label = "# of active Brands:", ifSkill = { "Armageddon Brand", "Storm Brand", "Arcanist Brand", "Penance Brand", "Wintertide Brand" }, includeTransfigured = true , apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ConfigActiveBrands", "BASE", val, "Config")
	end },
	{ var = "BrandsAttachedToEnemy", type = "count", label = "# of Brands attached to the enemy:", ifEnemyMult = "BrandsAttached", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ConfigBrandsAttachedToEnemy", "BASE", val, "Config")
	end },
	{ var = "targetBrandedEnemy", type = "check", label = "Skill is targeting the Branded enemy", ifCond = "TargetingBrandedEnemy", defaultState = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TargetingBrandedEnemy", "FLAG", true, "Config")
	end },
	{ var = "BrandsInLastQuarter", type = "check", label = "Last 25% of Attached Duration?", ifCond = "BrandLastQuarter", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BrandLastQuarter", "FLAG", true, "Config")
	end },
	{ label = "Carrion Golem:", ifSkill = "Summon Carrion Golem", includeTransfigured = true },
	{ var = "carrionGolemNearbyMinion", type = "count", label = "# of Nearby Non-Golem Minions:", ifSkill = "Summon Carrion Golem", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyNonGolemMinion", "BASE", val, "Config")
	end },
	{ var = "carrionGolemEqualsChaosGolem", type = "check", label = "# Carrion Golem = # Chaos Golem:", ifCond = "CarrionEqualChaosGolem", ifSkill = "Summon Chaos Golem", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CarrionEqualChaosGolem", "FLAG", true, "Config")
	end },
	{ var = "chaosGolemEqualsStoneGolem", type = "check", label = "# Chaos Golem = # Stone Golem:", ifCond = "ChaosEqualStoneGolem", ifSkill = "Summon Stone Golem", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChaosEqualStoneGolem", "FLAG", true, "Config")
	end },
	{ var = "stoneGolemEqualsCarrionGolem", type = "check", label = "# Stone Golem = # Carrion Golem:", ifCond = "StoneEqualCarrionGolem", ifSkill = "Summon Carrion Golem", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StoneEqualCarrionGolem", "FLAG", true, "Config")
	end },
	{ label = "Close Combat:", ifSkill = "Close Combat" },
	{ var = "closeCombatCombatRush", type = "check", label = "Is Combat Rush active?", ifSkill = "Close Combat", tooltip = "Combat Rush grants 20% more Attack Speed to Travel Skills not Supported by Close Combat.",apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CombatRushActive", "FLAG", true, "Config")
	end },
	{ label = "Cold Snap:", ifSkill = "Cold Snap", includeTransfigured = true },
	{ var = "ColdSnapBypassCD", type = "check", label = "Bypass CD?", ifSkill = "Cold Snap", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("CooldownRecovery", "OVERRIDE", 0, "Config", { type = "SkillName", skillName = "Cold Snap", includeTransfigured = true })
	end },
	{ label = "Consecrated Path of Endurance:", ifSkill = "Consecrated Path of Endurance" },
	{ var = "ConcPathBypassCD", type = "check", label = "Bypass CD?", ifSkill = "Consecrated Path of Endurance", defaultState = true, apply = function(val, modList, enemyModList)
		modList:NewMod("CooldownRecovery", "OVERRIDE", 0, "Config", { type = "SkillName", skillName = "Consecrated Path of Endurance" })
	end },
	{ label = "Corrupting Cry:", ifSkill = "Corrupting Cry" },
	{ var = "conditionCorruptingCryStages", type = "count", label = "# of Corrupting Cry stacks on enemy", ifSkill = "Corrupting Cry", defaultState = 1, apply = function(val, modList, enemyModList)
		-- 10 is the maximum amount of Corrupting Blood Stages. modList does not contain skill base mods at this point so hard coding it here is the cleanest way to handle the cap.
		-- It's set to 9 here with val -1 to so that it defaults to 1 stage and has max 10 stages.
		modList:NewMod("Multiplier:CorruptingCryStageAfterFirst", "BASE", m_min(val-1, 9), "Config", { type = "Condition", var = "Effective" })
	end },
	{ label = "Cruelty:", ifSkill = "Cruelty" },
	{ var = "overrideCruelty", type = "count", label = "Damage % (if not maximum):", ifSkill = "Cruelty", tooltip = "Cruelty is a buff provided by Cruelty Support which grants\nup to 40% more damage over time to the skills it supports.", apply = function(val, modList, enemyModList)
		modList:NewMod("Cruelty", "OVERRIDE", m_min(val, 40), "Config", { type = "Condition", var = "Combat" })
	end },
	{ label = "Cyclone:", ifSkill = "Cyclone", includeTransfigured = true },
	{ var = "channellingCycloneCheck", type = "check", label = "Are you Channelling Cyclone?", ifSkill = "Cyclone", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChannellingCyclone", "FLAG", true, "Config")
	end },
	{ label = "Arcane Cloak:", ifSkill = "Arcane Cloak"},
	{ var = "arcaneCloakUsedRecentlyCheck", type = "check", label = "Include in ^x7070FFMana ^7spent Recently?", ifSkill = "Arcane Cloak", tooltip = "When enabled, the mana spent by Arcane Cloak used at full mana \nwill be added to the value provided in # of ^x7070FFMana ^7spent Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ArcaneCloakUsedRecently", "FLAG", true, "Config")
	end },
	{ label = "Dark Pact:", ifSkill = "Dark Pact" },
	{ var = "darkPactSkeletonLife", type = "count", label = "Skeleton ^xE05030Life:", ifSkill = "Dark Pact", tooltip = "Sets the maximum ^xE05030Life ^7of the Skeleton that is being targeted.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "skeletonLife", value = val }, "Config", { type = "SkillName", skillName = "Dark Pact" })
	end },
	{ label = "Doom Blast:", ifSkill = "Doom Blast" },
	{ var = "doomBlastSource", type = "list", label = "Doom Blast Trigger Source:", ifSkill = "Doom Blast", list = {{val="expiration",label="Curse Expiration"},{val="replacement",label="Curse Replacement"},{val="vixen",label="Vixen's Curse"},{val="hexblast",label="Hexblast Replacement"}}, defaultIndex = 3},
	{ var = "curseOverlaps", type = "count", label = "Curse overlaps:", ifSkill = "Doom Blast", ifFlag = "UsesCurseOverlaps", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:CurseOverlaps", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ label = "Predator:", ifSkill = "Predator" },
	{ var = "deathmarkDeathmarkActive", type = "check", label = "Is the enemy marked with Signal Prey?", ifSkill = "Predator", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EnemyHasDeathmark", "FLAG", true, "Config")
	end },
	{ label = "Elemental Army:", ifSkill = "Elemental Army" },
	{ var = "elementalArmyExposureType", type = "list", label = "Exposure Type:", ifSkill = "Elemental Army", list = {{val=0,label="None"},{val="Fire",label="^xB97123Fire"},{val="Cold",label="^x3F6DB3Cold"},{val="Lightning",label="^xADAA47Lightning"}}, apply = function(val, modList, enemyModList)
		if val == "Fire" then
			modList:NewMod("FireExposureChance", "BASE", 100, "Config")
		elseif val == "Cold" then
			modList:NewMod("ColdExposureChance", "BASE", 100, "Config")
		elseif val == "Lightning" then
			modList:NewMod("LightningExposureChance", "BASE", 100, "Config")
		end
	end },
	{ label = "Embrace Madness:", ifSkill = "Embrace Madness" },
	{ var = "embraceMadnessActive", type = "check", label = "Is Embrace Madness active?", ifSkill = "Embrace Madness", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AffectedByGloriousMadness", "FLAG", true, "Config")
	end },
	{ label = "Feeding Frenzy:", ifSkill = "Feeding Frenzy" },
	{ var = "feedingFrenzyFeedingFrenzyActive", type = "check", label = "Is Feeding Frenzy active?", ifSkill = "Feeding Frenzy", tooltip = "Feeding Frenzy grants:\n\t10% more Minion Damage\n\t10% increased Minion Movement Speed\n\t10% increased Minion Attack and Cast Speed", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FeedingFrenzyActive", "FLAG", true, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Damage", "MORE", 10, "Feeding Frenzy") }, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("MovementSpeed", "INC", 10, "Feeding Frenzy") }, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Speed", "INC", 10, "Feeding Frenzy") }, "Config")
	end },
	{ label = "Flame Wall:", ifSkill = "Flame Wall" },
	{ var = "flameWallAddedDamage", type = "check", label = "Projectile Travelled through Flame Wall?", ifSkill = "Flame Wall", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FlameWallAddedDamage", "FLAG", true, "Config")
	end },
	{ label = "Flicker Strike:", ifSkill = "Flicker Strike", includeTransfigured = true },
	{ var = "FlickerStrikeBypassCD", type = "check", label = "Bypass CD?", ifSkill = "Flicker Strike", includeTransfigured = true, defaultState = true, apply = function(val, modList, enemyModList)
		modList:NewMod("CooldownRecovery", "OVERRIDE", 0, "Config", { type = "SkillName", skillName = "Flicker Strike", includeTransfigured = true })
	end },
	{ label = "Fresh Meat:", ifSkill = "Fresh Meat" },
	{ var = "freshMeatBuffs", type = "check", label = "Is Fresh Meat active?", ifSkill = "Fresh Meat", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FreshMeatActive", "FLAG", true, "Config")
	end },
	{ label = "Frost Shield:", ifSkill = "Frost Shield" },
	{ var = "frostShieldStages", type = "count", label = "Stages:", ifSkill = "Frost Shield", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:FrostShieldStage", "BASE", val, "Config")
	end },
	{ label = "Greater Harbinger of Time:", ifSkill =  "Summon Greater Harbinger of Time" },
	{ var = "greaterHarbingerOfTimeSlipstream", type = "check", label = "Is Slipstream active?:", ifSkill =  "Summon Greater Harbinger of Time", tooltip = "Greater Harbinger of Time Slipstream buff grants:\n10% increased Action Speed\nBuff affects the player and allies\nBuff has a base duration of 8s with a 10s Cooldown", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:GreaterHarbingerOfTime", "FLAG", true, "Config")
	end },
	{ label = "Harbinger of Time:", ifSkill =  "Summon Harbinger of Time" },
	{ var = "harbingerOfTimeSlipstream", type = "check", label = "Is Slipstream active?:", ifSkill =  "Summon Harbinger of Time", tooltip = "Harbinger of Time Slipstream buff grants:\n10% increased Action Speed\nBuff affects the player, allies and enemies in a small radius\nBuff has a base duration of 8s with a 20s Cooldown", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HarbingerOfTime", "FLAG", true, "Config")
	end },
	{ label = "Hex:", ifSkillFlag = "hex", ifMult = "MaxDoom" },
	{ var = "multiplierHexDoom", type = "count", label = "Doom on Hex:", ifSkillFlag = "hex", ifMult = "MaxDoom", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:HexDoomStack", "BASE", val, "Config")
	end },
	{ label = "Herald of Agony:", ifSkill = "Herald of Agony" },
	{ var = "heraldOfAgonyVirulenceStack", type = "count", label = "# of Virulence Stacks:", ifSkill = "Herald of Agony", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:VirulenceStack", "BASE", val, "Config")
	end },
	{ label = "Ice Nova:", ifSkill = "Ice Nova of Frostbolts" },
	{ var = "iceNovaCastOnFrostbolt", type = "check", label = "Cast on Frostbolt?", ifSkill = "Ice Nova of Frostbolts", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastOnFrostbolt", "FLAG", true, "Config", { type = "SkillName", skillName = "Ice Nova of Frostbolts" })
	end },
	{ label = "Infusion:", ifSkill = "Infused Channelling" },
	{ var = "infusedChannellingInfusion", type = "check", label = "Is Infusion active?", ifSkill = "Infused Channelling", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:InfusionActive", "FLAG", true, "Config")
	end },
	{ label = "Innervate:", ifSkill = "Innervate" },
	{ var = "innervateInnervation", type = "check", label = "Is Innervation active?", ifSkill = "Innervate", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:InnervationActive", "FLAG", true, "Config")
	end },
	{ label = "Intensify:", ifSkill = { "Intensify", "Crackling Lance", "Pinpoint" } },
	{ var = "intensifyIntensity", type = "count", label = "# of Intensity:", ifSkill = { "Intensify", "Crackling Lance", "Pinpoint" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Intensity", "BASE", val, "Config")
	end },
	{ label = "Link Skills:", ifSkill = { "Destructive Link", "Flame Link", "Intuitive Link", "Protective Link", "Soul Link", "Vampiric Link" } },
	{ var = "multiplierLinkedTargets", type = "count", label = "# of linked Targets:", ifSkill = { "Destructive Link", "Flame Link", "Intuitive Link", "Protective Link", "Soul Link", "Vampiric Link" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:LinkedTargets", "BASE", val, "Config")
	end },
	{ var = "linkedToMinion", type = "check", label = "Linked To Minion?", ifSkill = { "Destructive Link", "Flame Link", "Intuitive Link", "Protective Link", "Soul Link", "Vampiric Link" }, ifFlag = "Condition:CanLinkToMinions", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LinkedToMinion", "FLAG", true, "Config")
	end },
	{ var = "linkedSourceRate", type = "float", label = "Source rate for Intuitive Link", ifSkill = "Intuitive Link", apply = function(val, modList, enemyModList)
		modList:NewMod("IntuitiveLinkSourceRate", "BASE", val, "Config")
	end },
	{ label = "Meat Shield:", ifSkill = "Meat Shield" },
	{ var = "meatShieldEnemyNearYou", type = "check", label = "Is the enemy near you?", ifSkill = "Meat Shield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MeatShieldEnemyNearYou", "FLAG", true, "Config")
	end },
	{ label = "Momentum:", ifSkill = "Momentum" },
	{ var = "MomentumStacks", type = "count", label = "# of Momentum (if not average):", ifSkill = "Momentum", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:MomentumStacks", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "MomentumSwiftnessStacks", type = "count", label = "Swiftness # of Momentum Removed:", ifSkill = "Momentum", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:MomentumStacksRemoved", "BASE", val, "Config")
	end },
	{ label = "Plague Bearer:", ifSkill = "Plague Bearer"},
	{ var = "plagueBearerState", type = "list", label = "State:", ifSkill = "Plague Bearer", list = {{val="INC",label="Incubating"},{val="INF",label="Infecting"}}, apply = function(val, modList, enemyModList)
		if val == "INC" then
			modList:NewMod("Condition:PlagueBearerIncubating", "FLAG", true, "Config")
		elseif val == "INF" then
			modList:NewMod("Condition:PlagueBearerInfecting", "FLAG", true, "Config")
		end
	end },
	{ label = "Perforate:", ifSkill = "Perforate", includeTransfigured = true },
	{ var = "perforateSpikeOverlap", type = "count", label = "# of Overlapping Spikes:", tooltip = "Affects the DPS of Perforate in Blood Stance.\nMaximum is limited by the number of Spikes of Perforate.", ifSkill = "Perforate", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PerforateSpikeOverlap", "BASE", val, "Config", { type = "SkillName", skillName = "Perforate", includeTransfigured = true })
	end },
	{ label = "Physical Aegis:", ifSkill = "Physical Aegis" },
	{ var = "physicalAegisDepleted", type = "check", label = "Is Physical Aegis depleted?", ifSkill = "Physical Aegis", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:PhysicalAegisDepleted", "FLAG", true, "Config")
	end },
	{ label = "Pride:", ifSkill = "Pride" },
	{ var = "prideEffect", type = "list", label = "Pride Aura Effect:", ifSkill = { "Pride", "AzmeriDemonPhysicalDamageAura" }, list = {{val="MIN",label="Initial effect"},{val="MAX",label="Maximum effect"}}, apply = function(val, modList, enemyModList)
		if val == "MAX" then
			modList:NewMod("Condition:PrideMaxEffect", "FLAG", true, "Config")
		end
	end },
	{ label = "Rage Vortex:", ifSkill = "Rage Vortex" },
	{ var = "sacrificedRageCount", type = "count", label = "Amount of Rage Sacrificed?", ifSkill = "Rage Vortex", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:RageSacrificed", "BASE", val, "Config")
	end },
	{ label = "Raise Spectre:", ifSkill = "Raise Spectre", includeTransfigured = true },
	{ var = "raiseSpectreEnableBuffs", type = "check", defaultState = true, label = "Enable buffs:", ifSkill = "Raise Spectre", includeTransfigured = true, tooltip = "Enable any buff skills that your spectres have.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillType", skillType = SkillType.Buff }, { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true, summonSkill = true })
	end },
	{ var = "raiseSpectreEnableCurses", type = "check", defaultState = true, label = "Enable curses:", ifSkill = "Raise Spectre", includeTransfigured = true, tooltip = "Enable any curse skills that your spectres have.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillType", skillType = SkillType.Hex }, { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true, summonSkill = true })
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillType", skillType = SkillType.Mark }, { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true, summonSkill = true })
	end },
	{ var = "conditionSummonedSpectreInPast8Sec", type = "check", label = "Summoned Spectre in past 8 Seconds?", ifCond = "SummonedSpectreInPast8Sec", ifSkill = "Raise Spectre", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SummonedSpectreInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "raiseSpectreBladeVortexBladeCount", type = "count", label = "Blade Vortex blade count:", ifSkill = {"DemonModularBladeVortexSpectre","GhostPirateBladeVortexSpectre"}, tooltip = "Sets the blade count for Blade Vortex skills used by spectres.\nDefault is 1; maximum is 5.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "dpsMultiplier", value = val }, "Config", { type = "SkillId", skillId = "DemonModularBladeVortexSpectre" })
		modList:NewMod("SkillData", "LIST", { key = "dpsMultiplier", value = val }, "Config", { type = "SkillId", skillId = "GhostPirateBladeVortexSpectre" })
	end },
	{ var = "raiseSpectreKaomFireBeamTotemStage", type = "count", label = "Scorching Ray Totem stage count:", ifSkill = "KaomFireBeamTotemSpectre", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:KaomFireBeamTotemStage", "BASE", val, "Config")
	end },
	{ var = "raiseSpectreEnableSummonedUrsaRallyingCry", type = "check", label = "Enable Summoned Ursa's Rallying Cry:", ifSkill = "DropBearSummonedRallyingCry", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "DropBearSummonedRallyingCry" })
	end },
	{ var = "raiseSpectreEnableSlashingHorrorEnrage", type = "check", label = "Disable Slashing Horror's Enrage:", ifSkill = "AzmeriDualStrikeDemonFireEnrage", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = false }, "Config", { type = "SkillId", skillId = "AzmeriDualStrikeDemonFireEnrage" })
	end },
	{ var = "raiseSpectreEnableSanguimancerDemonLowLife", type = "check", label = "Sanguimancer Demon not on Low Life:", ifSkill = "ABTTAzmeriShepherdSpellDamage", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = false }, "Config", { type = "SkillId", skillId = "ABTTAzmeriShepherdSpellDamage" })
	end },
	{ label = "Raise Spiders:", ifSkill = "Raise Spiders" },
	{ var = "raiseSpidersSpiderCount", type = "count", label = "# of Spiders:", ifSkill = "Raise Spiders", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:RaisedSpider", "BASE", m_min(val, 20), "Config")
	end },
	{ label = "Raise Zombie:", ifSkill = "Raise Zombie", includeTransfigured = true, ifCond = "SummonedZombieInPast8Sec" },
	{ var = "conditionSummonedZombieInPast8Sec", type = "check", label = "Summoned Zombie in past 8 Seconds?", ifCond = "SummonedZombieInPast8Sec", ifSkill = "Raise Zombie", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SummonedZombieInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "animateWeaponLingeringBlade", type = "check", label = "Are you animating Lingering Blades?", ifSkill = "Animate Weapon", tooltip = "Enables additional damage given to Lingering Blades\nThe exact weapon is unknown but should be similar to Glass Shank", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AnimatingLingeringBlades", "FLAG", true, "Config")
	end },
	{ label = "Shrapnel Ballista:", ifSkill = "Shrapnel Ballista", includeTransfigured = true },
	{ var = "ShrapnelBallistaProjectileOverlap", type = "count", label = "# of Shotgunning Projectiles:", tooltip = "Maximum is limited by the number of Projectiles., default of 1, if Arrow nova then default of maximum projectiles", ifSkill = "Shrapnel Ballista", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "ShrapnelBallistaProjectileOverlap", value = val }, "Config", { type = "SkillName", skillName = "Shrapnel Ballista", includeTransfigured = true })
	end },
	{ label = "Sigil of Power:", ifSkill = "Sigil of Power" },
	{ var = "sigilOfPowerStages", type = "countAllowZero", label = "Stages:", ifSkill = "Sigil of Power", defaultPlaceholderState = 1, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SigilOfPowerStage", "BASE", val, "Config")
	end },
	{ label = "Siphoning Trap:", ifSkill = "Siphoning Trap" },
	{ var = "siphoningTrapAffectedEnemies", type = "count", label = "# of Enemies affected:", ifSkill = "Siphoning Trap", tooltip = "Sets the number of enemies affected by Siphoning Trap.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyAffectedBySiphoningTrap", "BASE", val, "Config")
		modList:NewMod("Condition:SiphoningTrapSiphoning", "FLAG", true, "Config")
	end },
	{ label = "Snipe:", ifSkill = "Snipe" },
	{ var = "configSnipeStages", type = "count", label = "# of Snipe stages:", ifSkill = "Snipe", tooltip = "Sets the number of stages reached before releasing Snipe.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SnipeStage", "BASE", val, "Config")
	end },
	{ label = "Trinity Support:", ifSkill = "Trinity" },
	{ var = "configResonanceCount", type = "count", label = "Lowest Resonance Count:", ifSkill = "Trinity", tooltip = "Sets the amount of resonance on the lowest element.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ResonanceCount", "BASE", m_max(m_min(val, 50), 0), "Config")
	end },
	{ label = "Spectral Wolf:", ifSkill = "Summon Spectral Wolf" },
	{ var = "configSpectralWolfCount", type = "count", label = "# of Active Spectral Wolves:", ifSkill = "Summon Spectral Wolf", tooltip = "Sets the number of active Spectral Wolves.\nThe maximum number of Spectral Wolves is 10.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SpectralWolfCount", "BASE", m_min(val, 10), "Config")
	end },
	{ label = "Stance Skills:", ifSkill = { "Blood and Sand", "Flesh and Stone", "Lacerate", "Bladestorm", "Perforate", "Perforate of Duality" } },
	{ var = "bloodSandStance", type = "list", label = "Stance:", ifSkill = { "Blood and Sand", "Flesh and Stone", "Lacerate", "Bladestorm", "Perforate", "Perforate of Duality" }, list = {{val="BLOOD",label="Blood Stance"},{val="SAND",label="Sand Stance"}}, apply = function(val, modList, enemyModList)
		if val == "SAND" then
			modList:NewMod("Condition:SandStance", "FLAG", true, "Config")
		end
	end },
	{ var = "changedStance", type = "check", label = "Changed Stance recently?", ifCond = "ChangedStanceRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChangedStanceRecently", "FLAG", true, "Config")
	end },
	{ label = "Steel Skills:", ifSkill = { "Splitting Steel of Ammunition", "Shattering Steel of Ammunition", "Lancing Steel", "Shrapnel Ballista of Steel" } },
	{ var = "shardsConsumed", type = "count", label = "Steel Shards consumed:", ifSkill = { "Splitting Steel of Ammunition", "Shattering Steel of Ammunition", "Lancing Steel", "Shrapnel Ballista of Steel" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SteelShardConsumed", "BASE", m_min(val, 12), "Config")
	end },
	{ var = "steelWards", type = "count", label = "Steel Wards:", ifSkill = "Shattering Steel of Ammunition", tooltip = "Steel Wards are gained from using Shattering Steel of Ammunition with at least 2 Steel Shards.\nYou can have up to 6 Steel Wards, and each grants +8% chance to Block Projectile Attack Damage.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SteelWardCount", "BASE", val, "Config")
	end },
	{ label = "Storm Rain:", ifSkill = "Storm Rain" },
	{ var = "stormRainBeamOverlap", type = "count", label = "# of Overlapping Beams:", ifSkill = "Storm Rain", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "beamOverlapMultiplier", value = val }, "Config", { type = "SkillName", skillName = "Storm Rain" })
	end },
	{ label = "Storm Rain of the Conduit:", ifSkill = "Storm Rain of the Conduit" },
	{ var = "stormRainActiveArrows", type = "count", label = "# of Active Arrows:", ifSkill = "Storm Rain of the Conduit", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "activeArrowMultiplier", value = val }, "Config", { type = "SkillName", skillName = "Storm Rain of the Conduit" })
	end },
	{ label = "Summon Elemental Relic:", ifSkill = "Summon Elemental Relic" },
	{ var = "summonElementalRelicEnableAngerAura", type = "check", defaultState = true, label = "Enable Anger Aura:", ifSkill = "Summon Elemental Relic", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "Anger" }, { type = "SkillName", skillName = "Summon Elemental Relic", summonSkill = true })
	end },
	{ var = "summonElementalRelicEnableHatredAura", type = "check", defaultState = true, label = "Enable Hatred Aura:", ifSkill = "Summon Elemental Relic", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "Hatred" }, { type = "SkillName", skillName = "Summon Elemental Relic", summonSkill = true })
	end },
	{ var = "summonElementalRelicEnableWrathAura", type = "check", defaultState = true, label = "Enable Wrath Aura:", ifSkill = "Summon Elemental Relic", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "Wrath" }, { type = "SkillName", skillName = "Summon Elemental Relic", summonSkill = true })
	end },
	{ label = "Summon Holy Relic:", ifSkill = "Summon Holy Relic" },
	{ var = "summonHolyRelicEnableHolyRelicBoon", type = "check", label = "Enable Holy Relic's Boon Aura:", ifSkill = "Summon Holy Relic", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HolyRelicBoonActive", "FLAG", true, "Config")
	end },
	{ label = "Summon Lightning Golem:", ifSkill = "Summon Lightning Golem", includeTransfigured = true },
	{ var = "summonLightningGolemEnableWrath", type = "check", label = "Enable Wrath Aura:", ifSkill = "Summon Lightning Golem", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "LightningGolemWrath" })
	end },
	{ label = "Summon Reaper:", ifSkill = "Summon Reaper", includeTransfigured = true },
	{ var = "summonReaperConsumeRecently", type = "check", label = "Reaper Consumed recently?", ifSkill = "Summon Reaper", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "ReaperConsumeMinionForBuff" })
	end },
	{ label = "Thirst for Blood:", ifSkill = "Thirst for Blood" },
	{ var = "nearbyBleedingEnemies", type = "count", label = "# of Nearby Bleeding Enemies:", ifSkill = "Thirst for Blood", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyBleedingEnemies", "BASE", val, "Config" )
	end },
	{ label = "Toxic Rain:", ifSkill = "Toxic Rain", includeTransfigured = true },
	{ var = "toxicRainPodOverlap", type = "count", label = "# of Overlapping Pods:", tooltip = "Maximum is limited by the number of Projectiles.", ifSkill = "Toxic Rain", includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "podOverlapMultiplier", value = val }, "Config", { type = "SkillName", skillName = "Toxic Rain", includeTransfigured = true })
	end },
	{ label = "Herald of Ash:", ifSkill = "Herald of Ash" },
	{ var = "hoaOverkill", type = "count", label = "Overkill damage:", tooltip = "Herald of Ash's base ^xB97123Burning ^7damage is equal to 25% of Overkill damage.", ifSkill = "Herald of Ash", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "hoaOverkill", value = val }, "Config", { type = "SkillName", skillName = "Herald of Ash" })
	end },
	{ label = "Vigilant Strike:", ifSkill = "Vigilant Strike" },
	{ var = "VigilantStrikeBypassCD", type = "check", label = "Bypass CD?", ifSkill = "Vigilant Strike", defaultState = true, apply = function(val, modList, enemyModList)
		modList:NewMod("CooldownRecovery", "OVERRIDE", 0, "Config", { type = "SkillName", skillName = "Vigilant Strike" })
	end },
	{ label = "Voltaxic Burst:", ifSkill = "Voltaxic Burst" },
	{ var = "voltaxicBurstSpellsQueued", type = "count", label = "# of Casts currently waiting:", ifSkill = "Voltaxic Burst", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:VoltaxicWaitingStages", "BASE", val, "Config")
	end },
	{ label = "Vortex:", ifSkill = "Vortex of Projection" },
	{ var = "vortexCastOnFrostbolt", type = "check", label = "Cast on Frostbolt?", ifSkill = "Vortex of Projection", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastOnFrostbolt", "FLAG", true, "Config", { type = "SkillName", skillName = "Vortex of Projection" })
	end },
	{ label = "Warcry Skills:", ifSkill = { "Infernal Cry", "Ancestral Cry", "Enduring Cry", "General's Cry", "Intimidating Cry", "Rallying Cry", "Seismic Cry", "Battlemage's Cry" } },
	{ var = "multiplierWarcryPower", type = "count", label = "Warcry Power:", ifSkill = { "Infernal Cry", "Ancestral Cry", "Enduring Cry", "General's Cry", "Intimidating Cry", "Rallying Cry", "Seismic Cry", "Battlemage's Cry" }, tooltip = "Power determines how strong your Warcry buffs will be, and is based on the total strength of nearby enemies.\nPower is assumed to be 20 if your target is a Boss, but you can override it here if necessary.\n\tEach Normal enemy grants 1 Power\n\tEach Magic enemy grants 2 Power\n\tEach Rare enemy grants 10 Power\n\tEach Unique enemy grants 20 Power", apply = function(val, modList, enemyModList)
		modList:NewMod("WarcryPower", "OVERRIDE", val, "Config")
	end },
	{ label = "Wave of Conviction:", ifSkill = "Wave of Conviction" },
	{ var = "waveOfConvictionExposureType", type = "list", label = "Exposure Type:", ifSkill = "Wave of Conviction", list = {{val=0,label="None"},{val="Fire",label="^xB97123Fire"},{val="Cold",label="^x3F6DB3Cold"},{val="Lightning",label="^xADAA47Lightning"}}, apply = function(val, modList, enemyModList)
		if val == "Fire" then
			modList:NewMod("Condition:WaveOfConvictionFireExposureActive", "FLAG", true, "Config")
		elseif val == "Cold" then
			modList:NewMod("Condition:WaveOfConvictionColdExposureActive", "FLAG", true, "Config")
		elseif val == "Lightning" then
			modList:NewMod("Condition:WaveOfConvictionLightningExposureActive", "FLAG", true, "Config")
		end
	end },
	{ var = "multiplierWoCExpiredDuration", type = "count", label = "% Wave of Conviction duration expired:", ifMod = "WaveOfConvictionDurationDotMulti", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:WoCDurationExpired", "BASE", m_min(val, 100), "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "absolutionSkillDamageCountedOnce", type = "check", label = "Absolution: Count skill damage once", ifSkill = "Absolution", includeTransfigured = true, tooltip = "Your Absolution Skill Damage will not be scaled with Count setting.\nBy default it multiplies both minion count and skill hit count which leads to incorrect\nTotal DPS calculation since Absolution cannot inherently shotgun.\nDo not enable if you use Spell Totem support, Spell Cascade support or similar supports", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AbsolutionSkillDamageCountedOnce", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ label = "Molten Shell:", ifSkill = "Molten Shell" },
	{ var = "MoltenShellDamageMitigated", type = "count", label = "Damage mitigated:", tooltip = "Molten Shell reflects damage to the enemy,\nbased on the amount of damage it has mitigated.", ifSkill = "Molten Shell", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "MoltenShellDamageMitigated", value = val }, "Config", { type = "SkillName", skillName = "Molten Shell" })
	end },
	{ label = "Vaal Molten Shell:", ifSkill = "Vaal Molten Shell" },
	{ var = "VaalMoltenShellDamageMitigated", type = "count", label = "Damage mitigated:", tooltip = "Vaal Molten Shell reflects damage to the enemy,\nbased on the amount of damage it has mitigated in the last second.", ifSkill = "Vaal Molten Shell", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "VaalMoltenShellDamageMitigated", value = val }, "Config", { type = "SkillName", skillName = "Molten Shell" })
	end },
	{ label = "Multi-part area skills:", ifSkill = { "Seismic Trap", "Lightning Spire Trap", "Explosive Trap" }, includeTransfigured = true },
	{ var = "enemySizePreset", type = "list", label = "Enemy size preset:", ifSkill = { "Seismic Trap", "Lightning Spire Trap", "Explosive Trap" }, includeTransfigured = true, defaultIndex = 2, tooltip = [[
Configure the radius of an enemy hitbox which is used in calculating some area multi-hitting (shotgunning) effects.

Small sets the radius to 2.
	Most monsters and the players' character are this size.
Medium sets the radius to 3.
	This is the size of most humanoid bosses (i.e. The Maven; The Shaper; Izaro)
Large sets the radius to 5.
	This is the size of some larger bosses (i.e. King Kaom; Vaal Oversoul)
Huge sets the radius to 11.
	This is the size of some of the largest bosses (i.e. Nucleus of the Maven; Tsoagoth, The Brine King)]], list = {{val="Small",label="Small"},{val="Medium",label="Medium"},{val="Large",label="Large"},{val="Huge",label="Huge"}}, apply = function(val, modList, enemyModList, build)
		if val == "Small" then
			build.configTab.varControls['enemyRadius']:SetPlaceholder(2, false)
			modList:NewMod("EnemyRadius", "BASE", 2, "Config")
		elseif val == "Medium" then
			build.configTab.varControls['enemyRadius']:SetPlaceholder(3, false)
			modList:NewMod("EnemyRadius", "BASE", 3, "Config")
		elseif val == "Large" then
			build.configTab.varControls['enemyRadius']:SetPlaceholder(5, false)
			modList:NewMod("EnemyRadius", "BASE", 5, "Config")
		elseif val == "Huge" then
			build.configTab.varControls['enemyRadius']:SetPlaceholder(11, false)
			modList:NewMod("EnemyRadius", "BASE", 11, "Config")
		end
	end },
	{ var = "enemyRadius", type = "integer", label = "Enemy radius:", ifSkill = { "Seismic Trap", "Lightning Spire Trap", "Explosive Trap" }, includeTransfigured = true, tooltip = "Configure the radius of an enemy hitbox to calculate some area overlapping (shotgunning) effects.", apply = function(val, modList, enemyModList)
		modList:NewMod("EnemyRadius", "OVERRIDE", m_max(val, 1), "Config")
	end },
	{ var = "TotalSpectreLife", type = "integer", label = "Total Spectre Life:", ifMod = "takenFromSpectresBeforeYou", ifSkill = "Raise Spectre", includeTransfigured = true, tooltip = "The total life of your Spectres that can be taken before yours (used by jinxed juju)", apply = function(val, modList, enemyModList)
		modList:NewMod("TotalSpectreLife", "BASE", val, "Config")
	end },
	{ var = "TotalTotemLife", type = "integer", label = "Total Totem Life:", ifOption = "conditionHaveTotem", ifMod = "takenFromTotemsBeforeYou", tooltip = "The total life of your Totems (excluding Vaal Rejuvenation Totem) that can be taken before yours (used by totem mastery)", apply = function(val, modList, enemyModList)
		modList:NewMod("TotalTotemLife", "BASE", val, "Config")
	end },
	{ var = "TotalRadianceSentinelLife", type = "integer", label = "Total life pool of Sentinel of Radiance", ifMod = "takenFromRadianceSentinelBeforeYou", apply = function(val, modList, enemyModList)
		modList:NewMod("TotalRadianceSentinelLife", "BASE", val, "Config")
	end },
	{ var = "TotalVaalRejuvenationTotemLife", type = "integer", label = "Total Vaal Rejuvenation Totem Life:", ifSkill = { "Vaal Rejuvenation Totem" }, ifMod = "takenFromVaalRejuvenationTotemsBeforeYou", tooltip = "The total life of your Vaal Rejuvenation Totems that can be taken before yours", apply = function(val, modList, enemyModList)
		modList:NewMod("TotalVaalRejuvenationTotemLife", "BASE", val, "Config")
	end },
	-- Section: Map modifiers/curses
	{ section = "Map Modifiers and Player Debuffs", col = 2 },
	{ var = "multiplierSextant", type = "count", label = "# of Sextants affecting the area", ifMult = "Sextant", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Sextant", "BASE", m_min(val, 5), "Config")
	end },
	{ var = "multiplierMapModEffect", type = "count", label = "% increased effect of map mods" },
	{ var = "multiplierMapModTier", type = "list", label = "Map Tier", list = { {val = "HIGH", label = "Red"}, {val = "MED", label = "Yellow"}, {val = "LOW", label = "White"} } },
	{ label = "Map Prefix Modifiers:" },
	{ var = "MapPrefix1", type = "list", label = "Prefix", tooltipFunc = mapAffixTooltip, list = data.mapMods.Prefix, apply = mapAffixDropDownFunction },
	{ var = "MapPrefix2", type = "list", label = "Prefix", tooltipFunc = mapAffixTooltip, list = data.mapMods.Prefix, apply = mapAffixDropDownFunction },
	{ var = "MapPrefix3", type = "list", label = "Prefix", tooltipFunc = mapAffixTooltip, list = data.mapMods.Prefix, apply = mapAffixDropDownFunction },
	{ var = "MapPrefix4", type = "list", label = "Prefix", tooltipFunc = mapAffixTooltip, list = data.mapMods.Prefix, apply = mapAffixDropDownFunction },
	{ label = "Map Suffix Modifiers:" },
	{ var = "MapSuffix1", type = "list", label = "Suffix", tooltipFunc = mapAffixTooltip, list = data.mapMods.Suffix, apply = mapAffixDropDownFunction },
	{ var = "MapSuffix2", type = "list", label = "Suffix", tooltipFunc = mapAffixTooltip, list = data.mapMods.Suffix, apply = mapAffixDropDownFunction },
	{ var = "MapSuffix3", type = "list", label = "Suffix", tooltipFunc = mapAffixTooltip, list = data.mapMods.Suffix, apply = mapAffixDropDownFunction },
	{ var = "MapSuffix4", type = "list", label = "Suffix", tooltipFunc = mapAffixTooltip, list = data.mapMods.Suffix, apply = mapAffixDropDownFunction },
	{ label = "Unique Map Modifiers:" },
	{ var = "PvpScaling", type = "check", label = "PvP damage scaling in effect", tooltip = "'Hall of Grandmasters'", apply = function(val, modList, enemyModList)
		modList:NewMod("HasPvpScaling", "FLAG", true, "Config")
	end },
	{ label = "Player is cursed by:" },
	{ var = "playerCursedWithAssassinsMark", type = "count", label = "Assassin's Mark:", tooltip = "Sets the level of Assassin's Mark to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "AssassinsMark", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithConductivity", type = "count", label = "Conductivity:", tooltip = "Sets the level of Conductivity to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Conductivity", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithDespair", type = "count", label = "Despair:", tooltip = "Sets the level of Despair to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Despair", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithElementalWeakness", type = "count", label = "Elemental Weakness:", tooltip = "Sets the level of Elemental Weakness to apply to the player.\nIn mid tier maps, 'of Elemental Weakness' applies level 10.\nIn high tier maps, 'of Elemental Weakness' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "ElementalWeakness", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithEnfeeble", type = "count", label = "Enfeeble:", tooltip = "Sets the level of Enfeeble to apply to the player.\nIn mid tier maps, 'of Enfeeblement' applies level 10.\nIn high tier maps, 'of Enfeeblement' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Enfeeble", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithFlammability", type = "count", label = "Flammability:", tooltip = "Sets the level of Flammability to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Flammability", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithFrostbite", type = "count", label = "Frostbite:", tooltip = "Sets the level of Frostbite to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Frostbite", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithPoachersMark", type = "count", label = "Poacher's Mark:", tooltip = "Sets the level of Poacher's Mark to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "PoachersMark", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithProjectileWeakness", type = "count", label = "Projectile Weakness:", tooltip = "Sets the level of Projectile Weakness to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "ProjectileWeakness", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithPunishment", type = "count", label = "Punishment:", tooltip = "Sets the level of Punishment to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Punishment", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithTemporalChains", type = "count", label = "Temporal Chains:", tooltip = "Sets the level of Temporal Chains to apply to the player.\nIn mid tier maps, 'of Temporal Chains' applies level 10.\nIn high tier maps, 'of Temporal Chains' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "TemporalChains", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithVulnerability", type = "count", label = "Vulnerability:", tooltip = "Sets the level of Vulnerability to apply to the player.\nIn mid tier maps, 'of Vulnerability' applies level 10.\nIn high tier maps, 'of Vulnerability' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Vulnerability", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithWarlordsMark", type = "count", label = "Warlord's Mark:", tooltip = "Sets the level of Warlord's Mark to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "WarlordsMark", level = val, applyToPlayer = true })
	end },

	-- Section: Combat options
	{ section = "When In Combat", col = 1 },
	{ var = "usePowerCharges", type = "check", label = "Do you use Power Charges?", apply = function(val, modList, enemyModList)
		modList:NewMod("UsePowerCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overridePowerCharges", type = "count", label = "# of Power Charges (if not maximum):", ifOption = "usePowerCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("PowerCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useFrenzyCharges", type = "check", label = "Do you use Frenzy Charges?", apply = function(val, modList, enemyModList)
		modList:NewMod("UseFrenzyCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideFrenzyCharges", type = "count", label = "# of Frenzy Charges (if not maximum):", ifOption = "useFrenzyCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("FrenzyCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useEnduranceCharges", type = "check", label = "Do you use Endurance Charges?", apply = function(val, modList, enemyModList)
		modList:NewMod("UseEnduranceCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideEnduranceCharges", type = "count", label = "# of Endurance Charges (if not maximum):", ifOption = "useEnduranceCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("EnduranceCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useSiphoningCharges", type = "check", label = "Do you use Siphoning Charges?", ifMult = "SiphoningCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("UseSiphoningCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideSiphoningCharges", type = "count", label = "# of Siphoning Charges (if not maximum):", ifOption = "useSiphoningCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("SiphoningCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useChallengerCharges", type = "check", label = "Do you use Challenger Charges?", ifMult = "ChallengerCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("UseChallengerCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideChallengerCharges", type = "count", label = "# of Challenger Charges (if not maximum):", ifOption = "useChallengerCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("ChallengerCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useBlitzCharges", type = "check", label = "Do you use Blitz Charges?", ifMult = "BlitzCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("UseBlitzCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideBlitzCharges", type = "count", label = "# of Blitz Charges (if not maximum):", ifOption = "useBlitzCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("BlitzCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierGaleForce", type = "count", label = "# of Gale Force:", ifFlag = "Condition:CanGainGaleForce", tooltip = "Base maximum Gale Force is 10.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:GaleForce", "BASE", val, "Config", { type = "IgnoreCond" }, { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainGaleForce" })
	end },
	{ var = "overrideInspirationCharges", type = "countAllowZero", label = "# of Inspiration Charges (if not maximum):", ifMult = "InspirationCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("InspirationCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useGhostShrouds", legacy = true, type = "check", label = "Do you use Ghost Shrouds?", ifMult = "GhostShroud", apply = function(val, modList, enemyModList)
		modList:NewMod("UseGhostShrouds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideGhostShrouds", type = "count", label = "# of Ghost Shrouds (if not maximum):", ifOption = "useGhostShrouds", apply = function(val, modList, enemyModList)
		modList:NewMod("GhostShrouds", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "waitForMaxSeals", type = "check", label = "Do you wait for Max Unleash Seals?", ifFlag = "HasSeals", apply = function(val, modList, enemyModList)
		modList:NewMod("UseMaxUnleash", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "repeatMode", type = "list", label = "Repeat Mode:", ifCond = "alwaysFinalRepeat", list = {
		{val="NONE",label="None"},
		{val="AVERAGE",label="Average"},
		{val="FINAL",label="Final only"},
		{val="FINAL_DPS",label="Final (all hits use final)"}
	}, defaultIndex = 2, apply = function(val, modList, enemyModList)
		if val == "AVERAGE" then
			modList:NewMod("Condition:averageRepeat", "FLAG", true, "Config")
		elseif val == "FINAL" or val == "FINAL_DPS" then
			modList:NewMod("Condition:alwaysFinalRepeat", "FLAG", true, "Config")
		end
	end },
	{ var = "ruthlessSupportMode", type = "list", label = "Ruthless Support Mode:", ifSkill = "Ruthless", tooltip = "Controls how the hit/ailment effect of Ruthless Support is calculated:\n\tAverage: damage is based on the average application\n\tMax Effect: damage is based on maximum effect", list = {{val="AVERAGE",label="Average"},{val="MAX",label="Max Effect"}} },
	{ var = "overrideBloodCharges", type = "countAllowZero", label = "# of Blood Charges (if not maximum):", ifMult = "BloodCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("BloodCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideSpiritCharges", type = "countAllowZero", label = "# of Spirit Charges:", ifMult = "SpiritCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("SpiritCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionsUsePowerCharges", type = "check", label = "Do your Minions use Power Charges?", ifFlag = "haveMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("UsePowerCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsUseFrenzyCharges", type = "check", label = "Do your Minions use Frenzy Charges?", ifFlag = "haveMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("UseFrenzyCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsUseEnduranceCharges", type = "check", label = "Do your Minions use Endur. Charges?", ifFlag = "haveMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("UseEnduranceCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsOverridePowerCharges", type = "count", label = "# of Power Charges (if not maximum):", ifFlag = "haveMinion", ifOption = "minionsUsePowerCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("PowerCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsOverrideFrenzyCharges", type = "count", label = "# of Frenzy Charges (if not maximum):", ifFlag = "haveMinion", ifOption = "minionsUseFrenzyCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("FrenzyCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsOverrideEnduranceCharges", type = "count", label = "# of Endurance Charges (if not maximum):", ifFlag = "haveMinion", ifOption = "minionsUseEnduranceCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("EnduranceCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "multiplierRampage", type = "count", label = "# of Rampage Kills:", ifFlag = "Condition:Rampage", tooltip = "Rampage grants the following, up to 1000 stacks:\n\t1% increased Movement Speed per 20 Rampage\n\t2% increased Damage per 20 Rampage\nYou lose Rampage if you do not get a Kill within 5 seconds.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Rampage", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierSoulEater", type = "count", label = "# of Soul Eater Stacks:", ifFlag = "Condition:CanHaveSoulEater", tooltip = "Soul Eater grants the following, up to a base of 45 stacks:\n\t5% increased Attack Speed\n\t5% increased Cast Speed\n\t1% increased character size per stack.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SoulEaterStack", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFocused", type = "check", label = "Are you Focused?", ifCond = "Focused", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Focused", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffLifetap", type = "check", label = "Do you have Lifetap?", ifCond = "Lifetap", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Lifetap", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("FlaskLifeRecovery", "INC", 20, "Lifetap")
	end },
	{ var = "buffOnslaught", type = "check", label = "Do you have Onslaught?", tooltip = "In addition to allowing any 'while you have Onslaught' modifiers to apply,\nthis will enable the Onslaught buff itself. (Grants 20% increased Attack, Cast, and Movement Speed)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Onslaught", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffArcaneSurge", type = "check", label = "Do you have Arcane Surge?", tooltip = "In addition to allowing any 'while you have Arcane Surge' modifiers to apply,\nthis will enable the Arcane Surge buff itself. (Grants 10% increased cast speed and 30% increased Mana Regeneration rate)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ArcaneSurge", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionBuffOnslaught", type = "check", label = "Do your minions have Onslaught?", ifFlag = "haveMinion", tooltip = "In addition to allowing any 'while your minions have Onslaught' modifiers to apply,\nthis will enable the Onslaught buff itself. (Grants 20% increased Attack, Cast, and Movement Speed)", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:Onslaught", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) })
	end },
	{ var = "buffUnholyMight", type = "check", label = "Do you have Unholy Might?", tooltip = "This will enable the Unholy Might buff.\n(Grants 100% of Physical Damage converted to ^xD02090Chaos ^7Damage)\n(25% chance to apply Wither on Hit)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UnholyMight", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:CanWither", "FLAG", true, "Unholy Might", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionbuffUnholyMight", type = "check", label = "Do your minions have Unholy Might?", ifFlag = "haveMinion", tooltip = "This will enable the Unholy Might buff on your minions.\n(Grants 100% of Physical Damage converted to ^xD02090Chaos ^7Damage)\n(25% chance to apply Wither on Hit)", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:UnholyMight", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) })
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:CanWither", "FLAG", true, "Unholy Might", { type = "Condition", var = "Combat" }) })
	end },
	{ var = "buffChaoticMight", type = "check", label = "Do you have Chaotic Might?", tooltip = "This will enable the Chaotic Might buff.\n(Grants 30% of Physical Damage as Extra ^xD02090Chaos ^7Damage)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChaoticMight", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionbuffChaoticMight", type = "check", label = "Do your minions have Chaotic Might?", ifFlag = "haveMinion", tooltip = "This will enable the Chaotic Might buff on your minions.\n(Grants 30% of Physical Damage as Extra ^xD02090Chaos ^7Damage)", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:ChaoticMight", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) })
	end },
	{ var = "buffPhasing", type = "check", label = "Do you have Phasing?", ifCond = "Phasing", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Phasing", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffFortification", type = "check", label = "Are you Fortified?", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Fortified", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideFortification", type = "count", label = "# of Fortification Stacks (if not maximum):", ifFlag = "Condition:Fortified", tooltip = "You have 1% less damage taken from hits per stack of fortification:\nHas a default cap of 20 stacks.", apply = function(val, modList, enemyModList)
		modList:NewMod("FortificationStacks", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffTailwind", type = "check", label = "Do you have Tailwind?", tooltip = "In addition to allowing any 'while you have Tailwind' modifiers to apply,\nthis will enable the Tailwind buff itself. (Grants 8% increased Action Speed)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Tailwind", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffAdrenaline", type = "check", label = "Do you have Adrenaline?", tooltip = "This will enable the Adrenaline buff, which grants:\n\t100% increased Damage\n\t25% increased Attack, Cast and Movement Speed\n\t10% additional Physical Damage Reduction", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Adrenaline", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChangedStanceLastSecond", type = "check", label = "Changed Stance in the last 1s?", ifCond = "StanceChangeLastSecond", tooltip = "'Changing Stance' occurs by activating a Stance skill while it's toggled on", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StanceChangeLastSecond", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffAlchemistsGenius", type = "check", label = "Do you have Alchemist's Genius?", ifFlag = "Condition:CanHaveAlchemistGenius", tooltip = "This will enable the Alchemist's Genius buff:\n20% increased Flask Charges gained\n10% increased effect of Flasks", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AlchemistsGenius", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanHaveAlchemistGenius" })
	end },
	{ var = "buffVaalArcLuckyHits", type = "check", label = "Do you have Vaal Arc's Lucky Buff?", ifFlag = "Condition:CanBeLucky",  tooltip = "Causes Damage with Arc Hits to be rolled twice, and the maximum roll used.", apply = function(val, modList, enemyModList)
		modList:NewMod("LuckyHits", "FLAG", true, "Config", { type = "Condition", varList = { "Combat", "CanBeLucky" } }, { type = "SkillName", skillName = "Arc", includeTransfigured = true })
	end },
	{ var = "buffElusive", type = "check", label = "Are you Elusive?", ifFlag = "Condition:CanBeElusive", tooltip = "In addition to allowing any 'while Elusive' modifiers to apply,\nthis will enable the Elusive buff itself:\n\t15% Chance to Avoid all Damage from Hits\n\t30% increased Movement Speed\nThe effect of Elusive decays over time.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Elusive", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanBeElusive" })
		modList:NewMod("Elusive", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanBeElusive" })
	end },
	{ var = "overrideBuffElusive", type = "count", label = "Effect of Elusive (if not average):", ifOption = "buffElusive", tooltip = "If you have a guaranteed source of Elusive, the strongest one will apply. \nYou can change this to see various buff values", apply = function(val, modList, enemyModList)
		modList:NewMod("ElusiveEffect", "OVERRIDE", val, "Config", {type = "GlobalEffect", effectType = "Buff" })
	end },
	{ var = "buffDivinity", type = "check", label = "Do you have Divinity?", ifCond = "Divinity", tooltip = "This will enable the Divinity buff, which grants:\n\t50% more Elemental Damage\n\t20% less Elemental Damage taken", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Divinity", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierDefiance", type = "count", label = "Defiance:", ifMult = "Defiance", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Defiance", "BASE", m_min(val, 10), "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierRage", type = "count", label = "Rage:", ifFlag = "Condition:CanGainRage", tooltip = "Base Maximum Rage is 50, and inherently grants the following:\n\t1% increased Attack Damage per 1 Rage\n\t1% increased Attack Speed per 2 Rage\n\t1% increased Movement Speed per 5 Rage\nYou lose 1 Rage every 0.5 seconds if you have not been Hit or gained Rage Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:RageStack", "BASE", val, "Config", { type = "IgnoreCond" }, { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainRage" })
	end },
	{ var = "conditionLeeching", type = "check", label = "Are you Leeching?", ifCond = "Leeching", tooltip = "You will automatically be considered to be Leeching if you have '^xE05030Life ^7Leech effects are not removed at Full ^xE05030Life^7',\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeechingLife", type = "check", label = "Are you Leeching ^xE05030Life?", ifCond = "LeechingLife", implyCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LeechingLife", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeechingEnergyShield", type = "check", label = "Are you Leeching ^x88FFFFEnergy Shield?", ifCond = "LeechingEnergyShield", implyCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LeechingEnergyShield", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeechingMana", type = "check", label = "Are you Leeching ^x7070FFMana?", ifCond = "LeechingMana", implyCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LeechingMana", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionsConditionLeechingEnergyShield", type = "check", label = "Minion is Leeching ^x88FFFFEnergy Shield?", ifMinionCond = "LeechingEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:LeechingEnergyShield", "FLAG", true, "Config") }, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:Leeching", "FLAG", true, "Config") }, "Config")
	end },
	{ var = "conditionUsingFlask", type = "check", label = "Do you have a Flask active?", ifCond = "UsingFlask", tooltip = "This is automatically enabled if you have a flask active,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsingFlask", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHaveTotem", type = "check", label = "Do you have a Totem summoned?", ifCond = "HaveTotem", tooltip = "You will automatically be considered to have a Totem if your main skill is a Totem,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveTotem", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSummonedTotemRecently", type = "check", label = "Have you Summoned a Totem Recently?", ifCond = "SummonedTotemRecently", tooltip = "You will automatically be considered to have Summoned a Totem Recently if your main skill is a Totem,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SummonedTotemRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "TotemsSummoned", type = "count", label = "# of Summoned Totems (if not maximum):", ifStat = "TotemsSummoned", ifFlag = "totem", implyCond = "HaveTotem", tooltip = "This also implies that you have a Totem summoned.\nThis will affect all 'per Summoned Totem' modifiers, even for non-Totem skills.", apply = function(val, modList, enemyModList)
		modList:NewMod("TotemsSummoned", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:HaveTotem", "FLAG", val >= 1, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSummonedGolemInPast8Sec", type = "check", label = "Summoned Golem in past 8 Seconds?", ifCond = "SummonedGolemInPast8Sec", implyCond = "SummonedGolemInPast10Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SummonedGolemInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSummonedGolemInPast10Sec", type = "check", label = "Summoned Golem in past 10 Seconds?", ifCond = "SummonedGolemInPast10Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SummonedGolemInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNearbyAlly", type = "count", label = "# of Nearby Allies:", ifMult = "NearbyAlly", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyAlly", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNearbyCorpse", type = "count", label = "# of Nearby Corpses:", ifMult = "NearbyCorpse", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyCorpse", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierSummonedMinion", type = "count", label = "# of Summoned Minions:", ifMult = "SummonedMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SummonedMinion", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnConsecratedGround", type = "check", label = "Are you on Consecrated Ground?", tooltip = "In addition to allowing any 'while on Consecrated Ground' modifiers to apply,\nConsecrated Ground grants 5% ^xE05030Life ^7Regeneration to players and allies.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnConsecratedGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:OnConsecratedGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) })
	end },
	{ var = "conditionOnCausticGround", type = "check", label = "Are you on Caustic Ground?", ifCond = "OnCausticGround", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnCausticGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnFungalGround", type = "check", label = "Are you on Fungal Ground?", ifCond = "OnFungalGround", tooltip = "Allies on your Fungal Ground gain 10% of Non-Chaos Damage as extra ^xD02090Chaos ^7Damage.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnFungalGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnBurningGround", type = "check", label = "Are you on ^xB97123Burning ^7Ground?", ifCond = "OnBurningGround", implyCond = "Burning", tooltip = "This also implies that you are ^xB97123Burning.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnBurningGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Burning", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnChilledGround", type = "check", label = "Are you on ^x3F6DB3Chilled ^7Ground?", ifCond = "OnChilledGround", implyCond = "Chilled", tooltip = "This also implies that you are ^x3F6DB3Chilled.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnChilledGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnShockedGround", type = "check", label = "Are you on ^xADAA47Shocked ^7Ground?", ifCond = "OnShockedGround", implyCond = "Shocked", tooltip = "This also implies that you are ^xADAA47Shocked.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnShockedGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlinded", type = "check", label = "Are you Blinded?", ifCond = "Blinded", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Blinded", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBurning", type = "check", label = "Are you ^xB97123Burning?", ifCond = "Burning", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Burning", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnited", type = "check", label = "Are you ^xB97123Ignited?", ifCond = "Ignited", implyCond = "Burning", tooltip = "This also implies that you are ^xB97123Burning.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Ignited", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionScorched", type = "check", label = "Are you ^xB97123Scorched?", ifCond = "Scorched", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Scorched", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChilled", type = "check", label = "Are you ^x3F6DB3Chilled?", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChilledEffect", type = "count", label = "Effect of ^x3F6DB3Chill:", ifOption = "conditionChilled", apply = function(val, modList, enemyModList)
		modList:NewMod("ChillVal", "OVERRIDE", val, "Chill", { type = "Condition", var = "Chilled" })
	end },
	{ var = "conditionSelfChill", type = "check", label = "Did you ^x3F6DB3Chill ^7yourself?", ifOption = "conditionChilled", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChilledSelf", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFrozen", type = "check", label = "Are you ^x3F6DB3Frozen?", ifCond = "Frozen", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Frozen", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBrittle", type = "check", label = "Are you ^x3F6DB3Brittle?", ifCond = "Brittle", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Brittle", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShocked", type = "check", label = "Are you ^xADAA47Shocked?", ifCond = "Shocked", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("DamageTaken", "INC", 15, "Shock", { type = "Condition", var = "Shocked" })
	end },
	{ var = "conditionSapped", type = "check", label = "Are you ^xADAA47Sapped?", ifCond = "Sapped", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Sapped", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBleeding", type = "check", label = "Are you Bleeding?", ifCond = "Bleeding", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionPoisoned", type = "check", label = "Are you Poisoned?", ifCond = "Poisoned", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Poisoned", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCanBeCurseImmune", type = "check", label = "Are you Immune to Curses?", ifFlag = "Condition:CanBeCurseImmune", apply = function(val, modList, enemyModList)
		modList:NewMod("AvoidCurse", "BASE", 100, "Config", { type = "Condition", var = "Combat" }, { type = "GlobalEffect", effectType = "Global", unscalable = true })
	end },
	{ var = "multiplierPoisonOnSelf", type = "count", label = "# of Poison on You:", ifMult = "PoisonStack", implyCond = "Poisoned", tooltip = "This also implies that you are Poisoned.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PoisonStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierWitheredStackCountSelf", type = "countAllowZero", label = "# of Withered Stacks on you:", ifFlag = "Condition:CanBeWithered", tooltip = "Withered applies 6% increased ^xD02090Chaos ^7Damage Taken to the self, up to 15 stacks.", defaultPlaceholderState = 15, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:WitheredStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierNearbyEnemies", type = "count", label = "# of nearby Enemies:", ifMult = "NearbyEnemies", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyEnemies", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:OnlyOneNearbyEnemy", "FLAG", val == 1, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNearbyRareOrUniqueEnemies", type = "countAllowZero", label = "# of nearby Rare or Unique Enemies:", ifMult = "NearbyRareOrUniqueEnemies", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyRareOrUniqueEnemies", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Multiplier:NearbyEnemies", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:AtMostOneNearbyRareOrUniqueEnemy", "FLAG", val <= 1, "Config", { type = "Condition", var = "Combat" })
		enemyModList:NewMod("Condition:NearbyRareOrUniqueEnemy", "FLAG", val >= 1, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitRecently", type = "check", label = "Have you Hit Recently?", ifCond = "HitRecently", tooltip = "You will automatically be considered to have Hit Recently if your main skill Hits and is self-cast,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitSpellRecently", type = "check", label = "Have you Hit with a Spell Recently?", ifCond = "HitSpellRecently", implyCond = "HitRecently", tooltip = "This also implies that you have Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitSpellRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:HitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCritRecently", type = "check", label = "Have you Crit Recently?", ifCond = "CritRecently", implyCond = "SkillCritRecently", tooltip = "This also implies that your Skills have Crit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:SkillCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSkillCritRecently", type = "check", label = "Have your Skills Crit Recently?", ifCond = "SkillCritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SkillCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCritWithHeraldSkillRecently", type = "check", label = "Have your Herald Skills Crit Recently?", ifCond = "CritWithHeraldSkillRecently", implyCond = "SkillCritRecently", tooltip = "This also implies that your Skills have Crit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CritWithHeraldSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "LostNonVaalBuffRecently", type = "check", label = "Lost a Non-Vaal Guard Skill buff recently?", ifCond = "LostNonVaalBuffRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LostNonVaalBuffRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionNonCritRecently", type = "check", label = "Have you dealt a Non-Crit Recently?", ifCond = "NonCritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:NonCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChannelling", type = "check", label = "Are you Channelling?", ifCond = "Channelling", tooltip = "You will automatically be considered to be Channeling if your main skill is a channelled skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Channelling", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierChannelling", type = "count", label = "Channeling for # seconds:", ifMult = "ChannellingTime", implyCond = "Channelling", tooltip = "This also implies that you are channelling", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ChannellingTime", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Channelling", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitRecentlyWithWeapon", type = "check", label = "Have you Hit Recently with Your Weapon?", ifCond = "HitRecentlyWithWeapon", tooltip = "This also implies that you have Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitRecentlyWithWeapon", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledRecently", type = "check", label = "Have you Killed Recently?", ifCond = "KilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierKilledRecently", type = "count", label = "# of Enemies Killed Recently:", ifMult = "EnemyKilledRecently", implyCond = "KilledRecently", tooltip = "This also implies that you have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyKilledRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:KilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledLast3Seconds", type = "check", label = "Have you Killed in the last 3 Seconds?", ifCond = "KilledLast3Seconds", implyCond = "KilledRecently", tooltip = "This also implies that you have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledLast3Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledPoisonedLast2Seconds", type = "check", label = "Killed a poisoned enemy in the last 2 Seconds?", ifCond = "KilledPoisonedLast2Seconds", implyCond = "KilledRecently", tooltip = "This also implies that you have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledPoisonedLast2Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledTauntedEnemyRecently", type = "check", label = "Killed a taunted enemy recently?", ifCond = "KilledTauntedEnemyRecently", implyCondList = {"KilledRecently", "TauntedEnemyRecently" }, tooltip = "This also implies that you have killed and taunted recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledTauntedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsNotSummonedInPastTwoSeconds", type = "check", label = "No summoned Totems in the past 2 seconds?", ifCond = "NoSummonedTotemsInPastTwoSeconds", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:NoSummonedTotemsInPastTwoSeconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsKilledRecently", type = "check", label = "Have your Totems Killed Recently?", ifCond = "TotemsKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TotemsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsHitRecently", type = "check", label = "Have your Totems Hit Recently?", ifCond = "HitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TotemsHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsHitSpellRecently", type = "check", label = "Have your Totems Hit with a Spell Recently?", ifCond = "TotemsHitSpellRecently", implyCond = "TotemsHitRecently", tooltip = "This also implies that you Totems have Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TotemsHitSpellRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:TotemsHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedBrandRecently", type = "check", label = "Have you used a Brand Skill recently?", ifCond = "UsedBrandRecently",  apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedBrandRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierTotemsKilledRecently", type = "count", label = "# of Enemies Killed by Totems Recently:", ifMult = "EnemyKilledByTotemsRecently", implyCond = "TotemsKilledRecently", tooltip = "This also implies that your Totems have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyKilledByTotemsRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:TotemsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionMinionsKilledRecently", type = "check", label = "Have your Minions Killed Recently?", ifCond = "MinionsKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MinionsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionMinionsDiedRecently", type = "check", label = "Has a Minion Died Recently?", ifCond = "MinionsDiedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MinionsDiedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierMinionsKilledRecently", type = "count", label = "# of Enemies Killed by Minions Recently:", ifMult = "EnemyKilledByMinionsRecently", implyCond = "MinionsKilledRecently", tooltip = "This also implies that your Minions have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyKilledByMinionsRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:MinionsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledAffectedByDoT", type = "check", label = "Killed enemy affected by your DoT Recently?", ifCond = "KilledAffectedByDotRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledAffectedByDotRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierShockedEnemyKilledRecently", type = "count", label = "# of ^xADAA47Shocked ^7Enemies Killed Recently:", ifMult = "ShockedEnemyKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ShockedEnemyKilledRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierShockedNonShockedEnemyRecently", type = "count", label = "# of Non-^xADAA47Shocked ^7Enemies ^xADAA47Shocked ^7 Recently:", ifMult = "ShockedNonShockedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ShockedNonShockedEnemyRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFrozenEnemyRecently", type = "check", label = "Have you ^x3F6DB3Frozen ^7an enemy Recently?", ifCond = "FrozenEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FrozenEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChilledEnemyRecently", type = "check", label = "Have you ^x3F6DB3Chilled ^7an enemy Recently?", ifCond = "ChilledEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChilledEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShatteredEnemyRecently", type = "check", label = "Have you ^x3F6DB3Shattered ^7an enemy Recently?", ifCond = "ShatteredEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ShatteredEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnitedEnemyRecently", type = "check", label = "Have you ^xB97123Ignited ^7an enemy Recently?", ifCond = "IgnitedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:IgnitedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierIgniteAppliedRecently", type = "count", label = "# of ^xB97123Ignites ^7applied Recently:", ifMult = "IgniteAppliedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:IgniteAppliedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShockedEnemyRecently", type = "check", label = "Have you ^xADAA47Shocked ^7an enemy Recently?", ifCond = "ShockedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ShockedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionStunnedEnemyRecently", type = "check", label = "Have you Stunned an enemy Recently?", ifCond = "StunnedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StunnedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionStunnedRecently", type = "check", label = "Have you been Stunned Recently?", ifCond = "StunnedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StunnedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierPoisonAppliedRecently", type = "count", label = "# of Poisons applied Recently:", ifMult = "PoisonAppliedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PoisonAppliedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierLifeSpentRecently", type = "count", label = "# of ^xE05030Life ^7spent Recently:", ifMult = "LifeSpentRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:LifeSpentRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierManaSpentRecently", type = "count", label = "# of ^x7070FFMana ^7spent Recently:", ifMult = "ManaSpentRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ManaSpentRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenHitRecently", type = "check", label = "Have you been Hit Recently?", ifCond = "BeenHitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierBeenHitRecently", type = "count", label = "# of times you have been Hit Recently:", ifMult = "BeenHitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:BeenHitRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", 1 <= val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenHitByAttackRecently", type = "check", label = "Have you been Hit by an Attack Recently?", ifCond = "BeenHitByAttackRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenHitByAttackRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenCritRecently", type = "check", label = "Have you been Crit Recently?", ifCond = "BeenCritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConsumed12SteelShardsRecently", type = "check", label = "Consumed 12 Steel Shards Recently?", ifCond = "Consumed12SteelShardsRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Consumed12SteelShardsRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionGainedPowerChargeRecently", type = "check", label = "Gained a Power Charge Recently?", ifCond = "GainedPowerChargeRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:GainedPowerChargeRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionGainedFrenzyChargeRecently", type = "check", label = "Gained a Frenzy Charge Recently?", ifCond = "GainedFrenzyChargeRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:GainedFrenzyChargeRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenSavageHitRecently", type = "check", label = "Have you taken a Savage Hit Recently?", ifCond = "BeenSavageHitRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenSavageHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByFireDamageRecently", type = "check", label = "Have you been hit by ^xB97123Fire ^7Recently?", ifCond = "HitByFireDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByFireDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByColdDamageRecently", type = "check", label = "Have you been hit by ^x3F6DB3Cold ^7Recently?", ifCond = "HitByColdDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByColdDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByLightningDamageRecently", type = "check", label = "Have you been hit by ^xADAA47Light. ^7Recently?", ifCond = "HitByLightningDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByLightningDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitBySpellDamageRecently", type = "check", label = "Have you taken Spell Damage Recently?", ifCond = "HitBySpellDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitBySpellDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTakenFireDamageFromEnemyHitRecently", type = "check", label = "Taken ^xB97123Fire ^7Damage from enemy Hit Recently?", ifCond = "TakenFireDamageFromEnemyHitRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TakenFireDamageFromEnemyHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedRecently", type = "check", label = "Have you Blocked Recently?", ifCond = "BlockedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedAttackRecently", type = "check", label = "Have you Blocked an Attack Recently?", ifCond = "BlockedAttackRecently", implyCond = "BlockedRecently", tooltip = "This also implies that you have Blocked Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedAttackRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BlockedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedSpellRecently", type = "check", label = "Have you Blocked a Spell Recently?", ifCond = "BlockedSpellRecently", implyCond = "BlockedRecently", tooltip = "This also implies that you have Blocked Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedSpellRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BlockedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionEnergyShieldRechargeRecently", type = "check", label = "^x88FFFFEnergy Shield ^7Recharge started Recently?", ifCond = "EnergyShieldRechargeRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EnergyShieldRechargeRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionEnergyShieldRechargePastTwoSec", type = "check", label = "^x88FFFFES ^7Recharge started past 2 seconds?", ifCond = "EnergyShieldRechargePastTwoSec", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EnergyShieldRechargePastTwoSec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionStoppedTakingDamageOverTimeRecently", type = "check", label = "Have you stopped taking DoT recently?", ifCond = "StoppedTakingDamageOverTimeRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StoppedTakingDamageOverTimeRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConvergence", type = "check", label = "Do you have Convergence?", ifFlag = "Condition:CanGainConvergence", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Convergence", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainConvergence" })
	end },
	{ var = "buffPendulum", type = "list", label = "Is Pendulum of Destruction active?", ifCond = "PendulumOfDestructionAreaOfEffect", list = {{val=0,label="None"},{val="AREA",label="Area of Effect"},{val="DAMAGE",label="Elemental Damage"}}, apply = function(val, modList, enemyModList)
		if val == "AREA" then
			modList:NewMod("Condition:PendulumOfDestructionAreaOfEffect", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		elseif val == "DAMAGE" then
			modList:NewMod("Condition:PendulumOfDestructionElementalDamage", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
	end },
	{ var = "buffConflux", type = "list", label = "Conflux Buff:", ifCond = "ChillingConflux", list = {{val=0,label="None"},{val="CHILLING",label="^x3F6DB3Chilling"},{val="SHOCKING",label="^xADAA47Shocking"},{val="IGNITING",label="^xB97123Igniting"},{val="ALL",label="^x3F6DB3Chill ^7+ ^xADAA47Shock ^7+ ^xB97123Ignite"}}, apply = function(val, modList, enemyModList)
		if val == "CHILLING" or val == "ALL" then
			modList:NewMod("Condition:ChillingConflux", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
		if val == "SHOCKING" or val == "ALL" then
			modList:NewMod("Condition:ShockingConflux", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
		if val == "IGNITING" or val == "ALL" then
			modList:NewMod("Condition:IgnitingConflux", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
	end },
	{ var = "highestDamageType", type = "list", ifFlag = "ChecksHighestDamage", label = "Highest damage type Override:", tooltip = "Determines whether modifiers that depend on the highest damage type apply.", list = {{val="NONE",label="Default"},{val="Physical",label="Physical"},{val="Lightning",label="Lightning"},{val="Cold",label="Cold"},{val="Fire",label="Fire"},{val="Chaos",label="Chaos"}}, apply = function(val, modList, enemyModList)
		if val ~= "NONE" then
			modList:NewMod("Condition:"..val.."IsHighestDamageType", "FLAG", true, "Config")
			modList:NewMod("IsHighestDamageTypeOVERRIDE", "FLAG", true, "Config")
		end
	end },
	{ var = "buffHeartstopper", type = "list", label = "Heartstopper Mode:", ifCond = "HeartstopperHIT", list = {{val=0,label="None"},{val="AVERAGE",label="Average"},{val="HIT",label="Hit"},{val="DOT",label="Damage over Time"}}, apply = function(val, modList, enemyModList)
		if val == "HIT" then
			modList:NewMod("Condition:HeartstopperHIT", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		elseif val == "DOT" then
			modList:NewMod("Condition:HeartstopperDOT", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		elseif val == "AVERAGE" then
			modList:NewMod("Condition:HeartstopperAVERAGE", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
	end },
	{ var = "buffBastionOfHope", type = "check", label = "Is Bastion of Hope active?", ifCond = "BastionOfHopeActive", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BastionOfHopeActive", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffNgamahuFlamesAdvance", type = "check", label = "Is Magmatic Strikes active?", ifCond = "NgamahuFlamesAdvance", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:NgamahuFlamesAdvance", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffHerEmbrace", type = "check", label = "Are you in Her Embrace?", ifCond = "HerEmbrace", tooltip = "This option is specific to Oni-Goroshi.", apply = function(val, modList, enemyModList)
		modList:NewMod("HerEmbrace", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainHerEmbrace" })
	end },
	{ var = "conditionChampionIntimidate", type = "check", label = "Is Champion's Intimidate active?", ifEnemyCond = "ChampionIntimidate", defaultState = true, apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:ChampionIntimidate", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedSkillRecently", type = "check", label = "Have you used a Skill Recently?", ifCond = "UsedSkillRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierSkillUsedRecently", type = "count", label = "# of Skills Used Recently:", ifMult = "SkillUsedRecently", implyCond = "UsedSkillRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SkillUsedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionAttackedRecently", type = "check", label = "Have you Attacked Recently?", ifCond = "AttackedRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have Attacked Recently if your main skill is an attack,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AttackedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCastSpellRecently", type = "check", label = "Have you Cast a Spell Recently?", ifCond = "CastSpellRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have Cast a Spell Recently if your main skill is a spell,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastSpellRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNonInstantSpellCastRecently", type = "count", label = "# of Non-Instant Spells Cast Recently:", ifMult = "NonInstantSpellCastRecently", implyCond = "CastSpellRecently", tooltip = "Only the number of different spells you cast count", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NonInstantSpellCastRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLinkedRecently", type = "check", label = "Have you Linked recently?", ifCond = "LinkedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LinkedRecently", "FLAG", true, "Config")
	end },
	{ var = "conditionStunnedWhileCastingRecently", type = "check", label = "Stunned while Casting Recently?", ifCond = "StunnedWhileCastingRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StunnedWhileCastingRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCastLast1Seconds", type = "check", label = "Have you Cast a Spell in the last second?", ifCond = "CastLast1Seconds", implyCond = "CastSpellRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastLast1Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierCastLast8Seconds", type = "count", label = "How many spells cast in the last 8 seconds?", ifMult = "CastLast8Seconds", tooltip = "Only non-instant spells you cast count", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:CastLast8Seconds", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSuppressedRecently", type = "check", label = "Have you Suppressed Recently?", ifCond = "SuppressedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SuppressedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierHitsSuppressedRecently", type = "count", label = "# of Hits Suppressed Recently:", ifMult = "HitsSuppressedRecently", implyCond = "SuppressedRecently", tooltip = "This also implies that you have Suppressed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:HitsSuppressedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:SuppressedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedFireSkillRecently", type = "check", label = "Have you used a ^xB97123Fire ^7Skill Recently?", ifCond = "UsedFireSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedFireSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedColdSkillRecently", type = "check", label = "Have you used a ^x3F6DB3Cold ^7Skill Recently?", ifCond = "UsedColdSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedColdSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedMinionSkillRecently", type = "check", label = "Have you used a Minion Skill Recently?", ifCond = "UsedMinionSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have used a Minion skill Recently if your main skill is a Minion skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedMinionSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedTravelSkillRecently", type = "check", label = "Have you used a Travel Skill Recently?", ifCond = "UsedTravelSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently..", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedTravelSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedMovementSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedDashRecently", type = "check", label = "Have you cast Dash Recently?", ifCond = "CastDashRecently", implyCondList = { "UsedTravelSkillRecently", "UsedMovementSkillRecently", "UsedSkillRecently"}, tooltip = "This also implies that you have used a Skill Recently..", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastDashRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedTravelSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedMovementSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedMovementSkillRecently", type = "check", label = "Have you used a Movement Skill Recently?", ifCond = "UsedMovementSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have used a Movement skill Recently if your main skill is a movement skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedMovementSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedVaalSkillRecently", type = "check", label = "Have you used a Vaal Skill Recently?", ifCond = "UsedVaalSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have used a Vaal skill Recently if your main skill is a Vaal skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedVaalSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSoulGainPrevention", type = "check", label = "Do you have Soul Gain Prevention?", ifCond = "SoulGainPrevention", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SoulGainPrevention", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedWarcryRecently", type = "check", label = "Have you used a Warcry Recently?", ifCond = "UsedWarcryRecently", implyCondList = {"UsedWarcryInPast8Seconds", "UsedSkillRecently"}, tooltip = "This also implies that you have used a Skill Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedWarcryRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedWarcryInPast8Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedWarcryInPast8Seconds", type = "check", label = "Used a Warcry in the past 8 seconds?", ifCond = "UsedWarcryInPast8Seconds", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedWarcryInPast8Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierAffectedByWarcryBuffDuration", type = "count", label = "# of seconds Affected by a Warcry Buff:", ifMult = "AffectedByWarcryBuffDuration", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:AffectedByWarcryBuffDuration", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "DetonatedMinesRecently", type = "check", label = "Have you Detonated a Mine Recently", ifCond = "DetonatedMinesRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:DetonatedMinesRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierMineDetonatedRecently", type = "count", label = "# of Mines Detonated Recently:", ifMult = "MineDetonatedRecently", implyCond = "DetonatedMinesRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:MineDetonatedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "TriggeredTrapsRecently", type = "check", label = "Have you Triggered a Trap Recently?", ifCond = "TriggeredTrapsRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TriggeredTrapsRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierTrapTriggeredRecently", type = "count", label = "# of Traps Triggered Recently:", ifMult = "TrapTriggeredRecently", implyCond = "TriggeredTrapRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:TrapTriggeredRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionThrownTrapOrMineRecently", type = "check", label = "Have you thrown a Trap or Mine Recently?", ifCond = "TrapOrMineThrownRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TrapOrMineThrownRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCursedEnemyRecently", type = "check", label = "Have you Cursed an enemy Recently?",  ifCond="CursedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CursedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionCastMarkRecently", type = "check", label = "Have you cast a Mark Spell Recently?", ifCond = "CastMarkRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastMarkRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionSpawnedCorpseRecently", type = "check", label = "Spawned a corpse Recently?", ifCond = "SpawnedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SpawnedCorpseRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConsumedCorpseRecently", type = "check", label = "Consumed a corpse Recently?", ifCond = "ConsumedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ConsumedCorpseRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConsumedCorpseInPast2Sec", type = "check", label = "Consumed a corpse in the past 2s?", ifCond = "ConsumedCorpseInPast2Sec", implyCond = "ConsumedCorpseRecently",tooltip = "This also implies you have 'Consumed a corpse Recently'", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ConsumedCorpseInPast2Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierCorpseConsumedRecently", type = "count", label = "# of Corpses Consumed Recently:", ifMult = "CorpseConsumedRecently", implyCond = "ConsumedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:CorpseConsumedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:ConsumedCorpseRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionRavenousCorpseConsumed", type = "check", label = "Has Ravenous consumed a corpse?", ifSkill = "Ravenous", implyCond = "ConsumedCorpseRecently", tooltip = "Corpse must be the same type as the monster you're fighting.\nThis also implies you have 'Consumed a corpse Recently'", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:RavenousCorpseConsumed", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierWarcryUsedRecently", type = "count", label = "# of Warcries Used Recently:", ifMult = "WarcryUsedRecently", implyCondList = {"UsedWarcryRecently", "UsedWarcryInPast8Seconds", "UsedSkillRecently"}, tooltip = "This also implies you have 'Used a Warcry Recently', 'Used a Warcry in the past 8 seconds', and 'Used a Skill Recently'", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:WarcryUsedRecently", "BASE", m_min(val, 100), "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedWarcryRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedWarcryInPast8Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTauntedEnemyRecently", type = "check", label = "Taunted an enemy Recently?", ifCond = "TauntedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TauntedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLostEnduranceChargeInPast8Sec", type = "check", label = "Lost an Endurance Charge in the past 8s?", ifCond = "LostEnduranceChargeInPast8Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LostEnduranceChargeInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierEnduranceChargesLostRecently", type = "count", label = "# of Endurance Charges lost Recently:", ifMult = "EnduranceChargesLostRecently", implyCond = "LostEnduranceChargeInPast8Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnduranceChargesLostRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:LostEnduranceChargeInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedHitFromUniqueEnemyInPast10Sec", type = "check", label = "Blocked a Hit from a Unique enemy in the past 10s?", ifCond = "BlockedHitFromUniqueEnemyInPast10Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedHitFromUniqueEnemyInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledUniqueEnemy", type = "check", label = "Killed a Rare or Unique enemy Recently?", ifCond = "KilledUniqueEnemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledUniqueEnemy", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "BlockedPast10Sec", type = "count", label = "Number of times you've Blocked in the past 10s", ifCond = "BlockedHitFromUniqueEnemyInPast10Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:BlockedPast10Sec", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionImpaledRecently", type = "check", ifCond = "ImpaledRecently", label = "Impaled an enemy recently?", apply = function(val, modList, enemyModLIst)
		modList:NewMod("Condition:ImpaledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierImpalesOnEnemy", type = "countAllowZero", label = "# of Impales on enemy (if not maximum):", ifFlag = "impale", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:ImpaleStacks", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierBleedsOnEnemy", type = "count", label = "# of Bleeds on enemy (if not maximum):", ifFlag = "Condition:HaveCrimsonDance", tooltip = "Sets current number of Bleeds on the enemy if using the Crimson Dance keystone.\nThis also implies that the enemy is Bleeding.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:BleedStacks", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		enemyModList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierFragileRegrowth", type = "count", label = "# of Fragile Regrowth Stacks:", ifMult = "FragileRegrowthCount", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:FragileRegrowthCount", "BASE", m_min(val,10), "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHaveArborix", type = "check", label = "Do you have Iron Reflexes?", ifFlag = "Condition:HaveArborix", tooltip = "This option is specific to Arborix.",apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveIronReflexes", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Keystone", "LIST", "Iron Reflexes", "Config")
	end },	
	{ var = "conditionHaveAugyre", type = "list", label = "Augyre rotating buff:", ifFlag = "Condition:HaveAugyre", list = {{val="EleOverload",label="Elemental Overload"},{val="ResTechnique",label="Resolute Technique"}}, tooltip = "This option is specific to Augyre.", apply = function(val, modList, enemyModList)
		if val == "EleOverload" then
			modList:NewMod("Condition:HaveElementalOverload", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
			modList:NewMod("Keystone", "LIST", "Elemental Overload", "Config")
		elseif val == "ResTechnique" then
			modList:NewMod("Condition:HaveResoluteTechnique", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
			modList:NewMod("Keystone", "LIST", "Resolute Technique", "Config")
		end
	end },	
	{ var = "conditionHaveVulconus", type = "check", label = "Do you have Avatar Of Fire?", ifFlag = "Condition:HaveVulconus", tooltip = "This option is specific to Vulconus.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveAvatarOfFire", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Keystone", "LIST", "Avatar of Fire", "Config")
	end },
	{ var = "conditionHaveManaStorm", type = "check", label = "Do you have Manastorm's Buff?", ifFlag = "Condition:HaveManaStorm", tooltip = "This option enables Manastorm's ^xADAA47Lightning ^7Damage Buff.\n(When you cast a Spell, Sacrifice all ^x7070FFMana ^7to gain Added Maximum ^xADAA47Lightning ^7Damage\nequal to 50% of Sacrificed ^x7070FFMana ^7for 4 seconds)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SacrificeManaForLightning", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "GamblesprintMovementSpeed", type = "list", label = "Gamblesprint Movement Speed", defaultIndex=5, list={{val=-40,label="-40%"},{val=-20,label="-20%"},{val=0,label="0%"},{val=20,label="20%"},{val=30,label="30%"},{val=40,label="40%"},{val=60,label="60%"},{val=80,label="80%"},{val=100,label="100%"}}, ifFlag = "Condition:HaveGamblesprint", tooltip = "This option sets the Movement Speed from Gamblesprint boots.", apply = function(val, modList, enemyModList)
		modList:NewMod("MovementSpeed", "INC", val, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "HaveGamblesprint" })
	end },
	{ var = "EverlastingSacrifice", type = "check", label = "Do you have Everlasting Sacrifice?", ifFlag = "Condition:EverlastingSacrifice", tooltip = "This option enables the Everlasting Sacrifice buff that grants +5% to all maximum resists.", apply = function(val, modList , enemyModList)
		modList:NewMod("ElementalResistMax", "BASE", 5, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "EverlastingSacrifice"})
		modList:NewMod("ChaosResistMax", "BASE", 5, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "EverlastingSacrifice"})
	end },
	{ var = "buffFanaticism", type = "check", label = "Do you have Fanaticism?", ifFlag = "Condition:CanGainFanaticism", tooltip = "This will enable the Fanaticism buff itself. (Grants 75% more cast speed, reduced skill cost, and increased area of effect)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Fanaticism", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainFanaticism" })
	end },
	{ var = "multiplierPvpTvalueOverride", type = "count", label = "PvP Tvalue override (ms):", ifFlag = "isPvP", tooltip = "Tvalue in milliseconds. This overrides the Tvalue of a given skill, for instance any with fixed Tvalues, or modified Tvalues", apply = function(val, modList, enemyModList)
		modList:NewMod("MultiplierPvpTvalueOverride", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierPvpDamage", type = "count", label = "Custom PvP Damage multiplier percent:", ifFlag = "isPvP", tooltip = "This multiplies the damage of a given skill in pvp, for instance any with damage multiplier specific to pvp (from skill or support or item like sire of shards)", apply = function(val, modList, enemyModList)
		modList:NewMod("PvpDamageMultiplier", "MORE", val - 100, "Config")
	end },
	-- Section: Effective DPS options
	{ section = "For Effective DPS", col = 1 },
	{ var = "skillForkCount", type = "count", label = "# of times Skill has Forked:", ifFlag = "forking", apply = function(val, modList, enemyModList)
		modList:NewMod("ForkedCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "skillChainCount", type = "count", label = "# of times Skill has Chained:", ifStat = { "Chain", "ChainRemaining" }, ifFlag = "chaining", apply = function(val, modList, enemyModList)
		modList:NewMod("ChainCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "skillPierceCount", type = "count", label = "# of times Skill has Pierced:", ifStat = "PiercedCount", ifFlag = "piercing", apply = function(val, modList, enemyModList)
		modList:NewMod("PiercedCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "meleeDistance", type = "count", label = "Melee distance to enemy:", ifTagType = "MeleeProximity", ifFlag = "melee" },
	{ var = "projectileDistance", type = "count", label = "Projectile travel distance:", ifTagType = "DistanceRamp", ifFlag = "projectile" },
	{ var = "conditionAtCloseRange", type = "check", label = "Is the enemy at Close Range?", ifCond = "AtCloseRange", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AtCloseRange", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyMoving", type = "check", label = "Is the enemy Moving?", ifMod = "BleedChance", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Moving", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFullLife", type = "check", label = "Is the enemy on Full ^xE05030Life?", ifEnemyCond = "FullLife", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:FullLife", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyLowLife", type = "check", label = "Is the enemy on Low ^xE05030Life?", ifEnemyCond = "LowLife", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:LowLife", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyCursed", type = "check", label = "Is the enemy Cursed?", ifEnemyCond = "Cursed", tooltip = "The enemy will automatically be considered to be Cursed if you have at least one curse enabled,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Cursed", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyStunned", type = "check", label = "Is the enemy Stunned?", ifEnemyCond = "Stunned", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Stunned", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBleeding", type = "check", label = "Is the enemy Bleeding?", ifEnemyCond = "Bleeding", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "overrideBleedStackPotential", type = "count", label = "Bleed Stack Potential override:", ifOption = "conditionEnemyBleeding", tooltip = "Allows you to manually set the Stack Potential value for a skill.\nStack Potential equates to the number of times you are able to inflict a Bleed on an enemy before the duration of your first Bleed expires", apply = function(val, modList, enemyModList)
		modList:NewMod("BleedStackPotentialOverride", "OVERRIDE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionSingleBleed", type = "check", label = "Cap to Single Bleed on enemy?", ifCond = "SingleBleed", tooltip = "This is for Blood Sap Tincture, but will limit you to only applying a single Bleed on the enemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SingleBleed", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierRuptureStacks", type = "count", label = "# of Rupture stacks?", ifFlag = "Condition:CanInflictRupture", tooltip = "Rupture applies 25% more bleed damage and 25% faster bleeds for 3 seconds, up to 3 stacks", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:RuptureStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("DamageTaken", "MORE", 25, "Rupture", nil, KeywordFlag.Bleed, { type = "Multiplier", var = "RuptureStack", limit = 3 }, { type = "ActorCondition", actor = "enemy", var = "CanInflictRupture" })
		enemyModList:NewMod("BleedExpireRate", "MORE", 25, "Rupture", nil, KeywordFlag.Bleed, { type = "Multiplier", var = "RuptureStack", limit = 3 }, { type = "ActorCondition", actor = "enemy", var = "CanInflictRupture" })
	end },
	{ var = "conditionEnemyPoisoned", type = "check", label = "Is the enemy Poisoned?", ifEnemyCond = "Poisoned", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Poisoned", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierPoisonOnEnemy", type = "count", label = "# of Poison on enemy:", ifEnemyMult = "PoisonStack", implyCond = "Poisoned", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:PoisonStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionSinglePoison", type = "check", label = "Cap to Single Poison on enemy?", ifCond = "SinglePoison", tooltip = "This is for low tolerance, but will limit you to only applying a single poison on the enemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SinglePoison", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierCurseExpiredOnEnemy", type = "count", label = "#% of Curse Expired on enemy:", ifEnemyMult = "CurseExpired", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:CurseExpired", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierCurseDurationExpiredOnEnemy", type = "count", label = "Curse Duration Expired on enemy:", ifEnemyMult = "CurseDurationExpired", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:CurseDurationExpired", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierWitheredStackCount", type = "count", label = "# of Withered Stacks:", ifFlag = "Condition:CanWither", tooltip = "Withered applies 6% increased ^xD02090Chaos ^7Damage Taken to the enemy, up to 15 stacks.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:WitheredStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierCorrosionStackCount", type = "count", label = "# of Corrosion Stacks:", ifFlag = "Condition:CanCorrode", tooltip = "Each stack of Corrosion applies -5000 to total Armour and -1000 to total ^x33FF77Evasion Rating ^7to the enemy.\nCorrosion lasts 4 seconds and refreshes the duration of existing Corrosion stacks\nCorrosion has no stack limit", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:CorrosionStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Armour", "BASE", -5000, "Corrosion", { type = "Multiplier", var = "CorrosionStack" }, { type = "ActorCondition", actor = "enemy", var = "CanCorrode" })
		enemyModList:NewMod("Evasion", "BASE", -1000, "Corrosion", { type = "Multiplier", var = "CorrosionStack" }, { type = "ActorCondition", actor = "enemy", var = "CanCorrode" })
	end },
	{ var = "multiplierEnsnaredStackCount", type = "count", label = "# of Ensnare Stacks:", ifSkill = "Ensnaring Arrow", tooltip = "While ensnared, enemies take increased Projectile Damage from Attack Hits\nEnsnared enemies always count as moving, and have less movement speed while trying to break the snare.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnsnareStackCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:Moving", "FLAG", true, "Config", { type = "MultiplierThreshold", actor = "enemy", var = "EnsnareStackCount", threshold = 1 })
	end },
	{ var = "conditionEnemyMaimed", type = "check", label = "Is the enemy Maimed?", ifEnemyCond = "Maimed", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Maimed", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyHindered", type = "check", label = "Is the enemy Hindered?", ifEnemyCond = "Hindered", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Hindered", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBlinded", type = "check", label = "Is the enemy Blinded?", tooltip = "In addition to allowing 'against Blinded Enemies' modifiers to apply,\n Blind applies the following effects.\n -20% Accuracy \n -20% ^x33FF77Evasion", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Blinded", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "overrideBuffBlinded", type = "count", label = "Effect of Blind (if not maximum):", ifOption = "conditionEnemyBlinded", tooltip = "If you have a guaranteed source of Blind, the strongest one will apply.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("BlindEffect", "OVERRIDE", val, "Config", {type = "GlobalEffect", effectType = "Buff" })
	end },
	{ var = "conditionEnemyTaunted", type = "check", label = "Is the enemy Taunted?", ifEnemyCond = "Taunted", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Taunted", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyDebilitated", type = "check", label = "Is the enemy Debilitated?", ifMod = "DebilitateChance", tooltip = "Debilitated enemies deal 10% less damage.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Debilitated", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyPacified", type = "check", label = "Is the enemy Pacified?", ifSkill = "Pacify", tooltip = "Enemies are Pacified after 60% of Pacify's duration has expired", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Pacified", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBurning", type = "check", label = "Is the enemy ^xB97123Burning?", ifEnemyCond = "Burning", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Burning", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyIgnited", type = "check", label = "Is the enemy ^xB97123Ignited?", ifEnemyCond = "Ignited", implyCond = "Burning", tooltip = "This also implies that the enemy is ^xB97123Burning.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Ignited", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "overrideIgniteStackPotential", type = "count", label = "^xB97123Ignite^7 Stack Potential override:", ifOption = "conditionEnemyIgnited", tooltip = "Allows you to manually set the Stack Potential value for a skill.\nStack Potential equates to the number of times you are able to inflict an Ignite on an enemy before the duration of your first Ignite expires", apply = function(val, modList, enemyModList)
		modList:NewMod("IgniteStackPotentialOverride", "OVERRIDE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyScorched", type = "check", ifFlag = "inflictScorch", label = "Is the enemy ^xB97123Scorched?", tooltip = "^xB97123Scorched ^7enemies have lowered elemental resistances, up to -30%.\nThis option will also allow you to input the effect of ^xB97123Scorched.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Scorched", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:ScorchedConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionScorchedEffect", type = "count", label = "Effect of ^xB97123Scorched:", ifOption = "conditionEnemyScorched", tooltip = "This effect will only be applied while you can inflict ^xB97123Scorched.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ScorchVal", "BASE", val, "Config", { type = "Condition", var = "ScorchedConfig" })
		enemyModList:NewMod("DesiredScorchVal", "BASE", val, "Scorch", { type = "Condition", var = "ScorchedConfig", neg = true })
	end },
	{ var = "conditionEnemyOnScorchedGround", type = "check", label = "Is the enemy on ^xB97123Scorched ^7Ground?", tooltip = "This also implies that the enemy is ^xB97123Scorched.", ifEnemyCond = "OnScorchedGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Scorched", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:OnScorchedGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyChilled", type = "check", label = "Is the enemy ^x3F6DB3Chilled?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:ChilledConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierChilledByYouSeconds", type = "count", label = "Seconds of chill on enemy?", ifEnemyCond = "ChilledByYou", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:ChilledByYouSeconds", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		enemyModList:NewMod("Condition:ChilledByYou", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyChilledEffect", type = "count", label = "Effect of ^x3F6DB3Chill:", ifOption = "conditionEnemyChilled", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ChillVal", "BASE", val, "Chill", { type = "Condition", var = "ChilledConfig" })
		enemyModList:NewMod("DesiredChillVal", "BASE", val, "Chill", { type = "Condition", var = "ChilledConfig", neg = true })
	end },
	{ var = "conditionEnemyChilledByYourHits", type = "check", ifEnemyCond = "ChilledByYourHits", label = "Is the enemy ^x3F6DB3Chilled ^7by your Hits?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:ChilledByYourHits", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFrozen", type = "check", label = "Is the enemy ^x3F6DB3Frozen?", ifEnemyCond = "Frozen", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Frozen", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierFrozenByYouSeconds", type = "count", label = "Seconds of freeze on enemy?", ifEnemyCond = "FrozenByYou", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:FrozenByYouSeconds", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		enemyModList:NewMod("Condition:FrozenByYou", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBrittle", type = "check", ifFlag = "inflictBrittle", label = "Is the enemy ^x3F6DB3Brittle?", tooltip = "Hits against ^x3F6DB3Brittle ^7enemies have up to +6% Critical Strike Chance.\nThis option will also allow you to input the effect of ^x3F6DB3Brittle.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Brittle", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:BrittleConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionBrittleEffect", type = "count", label = "Effect of ^x3F6DB3Brittle:", ifOption = "conditionEnemyBrittle", tooltip = "This effect will only be applied while you can inflict ^x3F6DB3Brittle.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("BrittleVal", "BASE", val, "Config", { type = "Condition", var = "BrittleConfig" })
		enemyModList:NewMod("DesiredBrittleVal", "BASE", val, "Brittle", { type = "Condition", var = "BrittleConfig", neg = true })
	end },
	{ var = "conditionEnemyOnBrittleGround", type = "check", label = "Is the enemy on ^xADAA47Brittle ^7Ground?", tooltip = "This also implies that the enemy is ^xADAA47Brittle.", ifEnemyCond = "OnBrittleGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Brittle", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:OnBrittleGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyShocked", type = "check", label = "Is the enemy ^xADAA47Shocked?", tooltip = "In addition to allowing any 'against ^xADAA47Shocked ^7Enemies' modifiers to apply,\nthis will allow you to input the effect of the ^xADAA47Shock ^7applied to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:ShockedConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionShockEffect", type = "count", label = "Effect of ^xADAA47Shock:", ifOption = "conditionEnemyShocked", tooltip = "If you have a guaranteed source of ^xADAA47Shock^7,\nthe strongest one will apply instead unless this option would apply a stronger ^xADAA47Shock.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ShockVal", "BASE", val, "Shock", { type = "Condition", var = "ShockedConfig" })
		enemyModList:NewMod("DesiredShockVal", "BASE", val, "Shock", { type = "Condition", var = "ShockedConfig", neg = true })
	end },
	{ var = "conditionEnemyOnShockedGround", type = "check", label = "Is the enemy on ^xADAA47Shocked ^7Ground?", tooltip = "This also implies that the enemy is ^xADAA47Shocked.", ifEnemyCond = "OnShockedGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:OnShockedGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemySapped", type = "check", ifFlag = "inflictSap", label = "Is the enemy ^xADAA47Sapped?", tooltip = "^xADAA47Sapped ^7enemies deal less damage, up to 20%.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Sapped", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:SappedConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionSapEffect", type = "count", label = "Effect of ^xADAA47Sap:", ifOption = "conditionEnemySapped", tooltip = "If you have a guaranteed source of ^xADAA47Sap^7,\nthe strongest one will apply instead unless this option would apply a stronger ^xADAA47Sap.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("SapVal", "BASE", val, "Sap", { type = "Condition", var = "SappedConfig" })
		enemyModList:NewMod("DesiredSapVal", "BASE", val, "Sap", { type = "Condition", var = "SappedConfig", neg = true })
	end },
	{ var = "conditionEnemyOnSappedGround", type = "check", label = "Is the enemy on ^xADAA47Sapped ^7Ground?", tooltip = "This also implies that the enemy is ^xADAA47Sapped.", ifEnemyCond = "OnSappedGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Sapped", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:OnSappedGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierFreezeShockIgniteOnEnemy", type = "count", label = "# of ^x3F6DB3Freeze ^7/ ^xADAA47Shock ^7/ ^xB97123Ignite ^7on enemy:", ifMult = "FreezeShockIgniteOnEnemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:FreezeShockIgniteOnEnemy", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFireExposure", type = "check", label = "Is the enemy Exposed to ^xB97123Fire?", ifFlag = "applyFireExposure", tooltip = "This applies -10% ^xB97123Fire Resistance ^7to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireExposure", "BASE", -10, "Config", { type = "Condition", var = "Effective" }, { type = "ActorCondition", actor = "enemy", var = "CanApplyFireExposure" })
	end },
	{ var = "conditionEnemyColdExposure", type = "check", label = "Is the enemy Exposed to ^x3F6DB3Cold?", ifFlag = "applyColdExposure", tooltip = "This applies -10% ^x3F6DB3Cold Resistance ^7to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ColdExposure", "BASE", -10, "Config", { type = "Condition", var = "Effective" }, { type = "ActorCondition", actor = "enemy", var = "CanApplyColdExposure" })
	end },
	{ var = "conditionEnemyLightningExposure", type = "check", label = "Is the enemy Exposed to ^xADAA47Lightning?", ifFlag = "applyLightningExposure", tooltip = "This applies -10% ^xADAA47Lightning Resistance ^7to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("LightningExposure", "BASE", -10, "Config", { type = "Condition", var = "Effective" }, { type = "ActorCondition", actor = "enemy", var = "CanApplyLightningExposure" })
	end },
	{ var = "conditionEnemyIntimidated", type = "check", label = "Is the enemy Intimidated?", tooltip = "Intimidated enemies take 10% increased Attack Damage.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Intimidated", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyCrushed", type = "check", label = "Is the enemy Crushed?", tooltip = "Crushed enemies have 15% reduced Physical Damage Reduction.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Crushed", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionNearLinkedTarget", type = "check", label = "Is the enemy near you Linked target?", ifEnemyCond = "NearLinkedTarget", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:NearLinkedTarget", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyUnnerved", type = "check", label = "Is the enemy Unnerved?", tooltip = "Unnerved enemies take 10% increased Spell Damage.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Unnerved", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyCoveredInAsh", type = "check", label = "Is the enemy covered in Ash?", tooltip = "Covered in Ash applies the following to the enemy:\n\t20% increased ^xB97123Fire ^7Damage taken\n\t20% less Movement Speed", apply = function(val, modList, enemyModList)
		modList:NewMod("CoveredInAshEffect", "BASE", 20, "Covered in Ash")
	end },
	{ var = "conditionEnemyCoveredInFrost", type = "check", label = "Is the enemy covered in Frost?", tooltip = "Covered in Frost applies the following to the enemy:\n\t20% increased ^x3F6DB3Cold ^7Damage taken\n\t50% less Critical Strike Chance", apply = function(val, modList, enemyModList)
		modList:NewMod("CoveredInFrostEffect", "BASE", 20, "Covered in Frost")
	end },
	{ var = "conditionEnemyOnConsecratedGround", type = "check", label = "Is the enemy on Consecrated Ground?", ifEnemyCond = "OnConsecratedGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:OnConsecratedGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyHaveEnergyShield", type = "check", label = "Does the enemy have ^x88FFFFEnergy Shield^7?", ifEnemyCond = "HaveEnergyShield", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HaveEnergyShield", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyOnProfaneGround", type = "check", label = "Is the enemy on Profane Ground?", ifFlag = "Condition:CreateProfaneGround", tooltip = "Enemies on Profane Ground receive the following modifiers:\n\t-10% to all Resistances\n\t100% increased chance to be Critically Hit", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:OnProfaneGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("ElementalResist", "BASE", -10, "Config", { type = "Condition", var = "OnProfaneGround" })
		enemyModList:NewMod("ChaosResist", "BASE", -10, "Config", { type = "Condition", var = "OnProfaneGround" })
		enemyModList:NewMod("SelfCritChance", "INC", 100, "Config", { type = "Condition", var = "OnProfaneGround" })
	end },
	{ var = "multiplierEnemyAffectedByGraspingVines", type = "count", label = "# of Grasping Vines affecting enemy:", ifMult = "GraspingVinesAffectingEnemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:GraspingVinesAffectingEnemy", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyOnFungalGround", type = "check", label = "Is the enemy on Fungal Ground?", ifCond = "OnFungalGround", tooltip = "Enemies on your Fungal Ground deal 10% less Damage.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:OnFungalGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyInChillingArea", type = "check", label = "Is the enemy in a ^x3F6DB3Chilling ^7area?", ifEnemyCond = "InChillingArea", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:InChillingArea", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyInFrostGlobe", type = "check", label = "Is the enemy in the Frost Shield area?", ifEnemyCond = "EnemyInFrostGlobe", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:EnemyInFrostGlobe", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "enemyConditionHitByFireDamage", type = "check", label = "Enemy was Hit by ^xB97123Fire ^7Damage?", ifFlag = "ElementalEquilibrium", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HitByFireDamage", "FLAG", true, "Config")
	end },
	{ var = "enemyConditionHitByColdDamage", type = "check", label = "Enemy was Hit by ^x3F6DB3Cold ^7Damage?", ifFlag = "ElementalEquilibrium", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HitByColdDamage", "FLAG", true, "Config")
	end },
	{ var = "enemyConditionHitByLightningDamage", type = "check", label = "Enemy was Hit by ^xADAA47Light. ^7Damage?", ifFlag = "ElementalEquilibrium", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HitByLightningDamage", "FLAG", true, "Config")
	end },
	{ var = "enemyInRFOrScorchingRay", type = "check", label = "Is the enemy in RF or Scorching Ray:", ifCond = "InRFOrScorchingRay", ifSkill = { "Righteous Fire", "Scorching Ray" }, includeTransfigured = true, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:InRFOrScorchingRay", "FLAG", true, "Config")
	end },
	{ var = "EEIgnoreHitDamage", type = "check", label = "Ignore Skill Hit Damage?", ifFlag = "ElementalEquilibrium", tooltip = "This option prevents EE from being reset by the hit damage of your main skill." },
	{ var = "conditionBetweenYouAndLinkedTarget", type = "check", label = "Is the enemy in your Link beams?", ifEnemyCond = "BetweenYouAndLinkedTarget", tooltip = "This option sets whether an enemy is between you and your linked target.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:BetweenYouAndLinkedTarget", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFireResZero", type = "check", label = "Enemy hit you with ^xB97123Fire Damage^7?", ifFlag = "Condition:HaveTrickstersSmile", tooltip = "This option sets whether or not the enemy has hit you with ^xB97123Fire Damage^7 in the last 4 seconds.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireResist", "OVERRIDE", 0, "Config", { type = "Condition", var = "Effective"}, { type = "ActorCondition", actor = "enemy", var = "HaveTrickstersSmile" })
	end },
	{ var = "conditionEnemyColdResZero", type = "check", label = "Enemy hit you with ^x3F6DB3Cold Damage^7?", ifFlag = "Condition:HaveTrickstersSmile", tooltip = "This option sets whether or not the enemy has hit you with ^x3F6DB3Cold Damage^7 in the last 4 seconds.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ColdResist", "OVERRIDE", 0, "Config", { type = "Condition", var = "Effective"}, { type = "ActorCondition", actor = "enemy", var = "HaveTrickstersSmile" })
	end },
	{ var = "conditionEnemyLightningResZero", type = "check", label = "Enemy hit you with ^xADAA47Light. Damage^7?", ifFlag = "Condition:HaveTrickstersSmile", tooltip = "This option sets whether or not the enemy has hit you with ^xADAA47Lightning Damage^7 in the last 4 seconds.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("LightningResist", "OVERRIDE", 0, "Config", { type = "Condition", var = "Effective"}, { type = "ActorCondition", actor = "enemy", var = "HaveTrickstersSmile" })
	end },
	-- Section: Enemy Stats
	{ section = "Enemy Stats", col = 3 },
	{ var = "enemyLevel", type = "count", label = "Enemy Level:", tooltip = "This overrides the default enemy level used to estimate your hit and ^x33FF77evade ^7chance.\n\nThe default level for normal enemies and standard bosses is 83.\nTheir default level is capped by your character level.\n\nThe default level for pinnacle bosses is 84, and the default level for uber pinnacle bosses is 85.\nTheir default level is not capped by your character level." },
	{ var = "conditionEnemyRareOrUnique", type = "check", label = "Is the enemy Rare or Unique?", ifEnemyCond = "EnemyRareOrUnique", tooltip = "The enemy will automatically be considered to be Unique if they are a Boss,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "enemyIsBoss", type = "list", label = "Is the enemy a Boss?", defaultIndex = 1, tooltip = data.enemyIsBossTooltip, list = {{val="None",label="No"},{val="Boss",label="Standard Boss"},{val="Pinnacle",label="Guardian/Pinnacle Boss"},{val="Uber",label="Uber Pinnacle Boss"}}, apply = function(val, modList, enemyModList, build)
		-- These defaults are here so that the placeholders get reset correctly
		build.configTab.varControls['enemySpeed']:SetPlaceholder(700, true)
		build.configTab.varControls['enemyCritChance']:SetPlaceholder(5, true)
		build.configTab.varControls['enemyCritDamage']:SetPlaceholder(30, true)
		if val == "None" then
			local defaultResist = ""
			build.configTab.varControls['enemyLightningResist']:SetPlaceholder(defaultResist, true)
			build.configTab.varControls['enemyColdResist']:SetPlaceholder(defaultResist, true)
			build.configTab.varControls['enemyFireResist']:SetPlaceholder(defaultResist, true)
			build.configTab.varControls['enemyChaosResist']:SetPlaceholder(defaultResist, true)

			local defaultLevel = 83
			build.configTab.varControls['enemyLevel']:SetPlaceholder("", true)
			build.configTab:UpdateLevel()
			if build.configTab.enemyLevel then
				defaultLevel = build.configTab.enemyLevel
			end

			local defaultDamage = round(data.monsterDamageTable[defaultLevel] * 1.5)
			build.configTab.varControls['enemyPhysicalDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyLightningDamage']:SetPlaceholder("", true)
			build.configTab.varControls['enemyColdDamage']:SetPlaceholder("", true)
			build.configTab.varControls['enemyFireDamage']:SetPlaceholder("", true)
			build.configTab.varControls['enemyChaosDamage']:SetPlaceholder("", true)

			local defaultPen = ""
			build.configTab.varControls['enemyPhysicalOverwhelm']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyLightningPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyColdPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyFirePen']:SetPlaceholder(defaultPen, true)

			build.configTab.varControls['enemyArmour']:SetPlaceholder(data.monsterArmourTable[defaultLevel], true)
			build.configTab.varControls['enemyEvasion']:SetPlaceholder(data.monsterEvasionTable[defaultLevel], true)
		elseif val == "Boss" then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("AilmentThreshold", "MORE", 488, "Boss")
			modList:NewMod("WarcryPower", "BASE", 20, "Boss")
			modList:NewMod("Multiplier:EnemyPower", "BASE", 20, "Boss")

			local defaultEleResist = 40
			build.configTab.varControls['enemyLightningResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyColdResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyFireResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyChaosResist']:SetPlaceholder(25, true)

			local defaultLevel = 83
			build.configTab.varControls['enemyLevel']:SetPlaceholder("", true)
			build.configTab:UpdateLevel()
			if build.configTab.enemyLevel then
				defaultLevel = build.configTab.enemyLevel
			end

			local defaultDamage = round(data.monsterDamageTable[defaultLevel] * 1.5  * data.misc.stdBossDPSMult)
			build.configTab.varControls['enemyPhysicalDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyLightningDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyColdDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyFireDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyChaosDamage']:SetPlaceholder(round(defaultDamage / 2.5), true)

			local defaultPen = ""
			build.configTab.varControls['enemyPhysicalOverwhelm']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyLightningPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyColdPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyFirePen']:SetPlaceholder(defaultPen, true)

			build.configTab.varControls['enemyArmour']:SetPlaceholder(data.monsterArmourTable[defaultLevel], true)
			build.configTab.varControls['enemyEvasion']:SetPlaceholder(data.monsterEvasionTable[defaultLevel], true)
		elseif val == "Pinnacle" then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("Condition:PinnacleBoss", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("AilmentThreshold", "MORE", 404, "Boss")
			modList:NewMod("WarcryPower", "BASE", 20, "Boss")
			modList:NewMod("Multiplier:EnemyPower", "BASE", 20, "Boss")

			local defaultEleResist = 50
			build.configTab.varControls['enemyLightningResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyColdResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyFireResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyChaosResist']:SetPlaceholder(30, true)

			local defaultLevel = 84
			build.configTab.varControls['enemyLevel']:SetPlaceholder(defaultLevel, true)
			build.configTab:UpdateLevel()
			if build.configTab.enemyLevel then
				defaultLevel = m_max(build.configTab.enemyLevel, defaultLevel)
			end

			local defaultDamage = round(data.monsterDamageTable[defaultLevel] * 1.5  * data.misc.pinnacleBossDPSMult)
			build.configTab.varControls['enemyPhysicalDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyLightningDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyColdDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyFireDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyChaosDamage']:SetPlaceholder(round(defaultDamage / 2.5), true)

			build.configTab.varControls['enemyLightningPen']:SetPlaceholder(data.misc.pinnacleBossPen, true)
			build.configTab.varControls['enemyColdPen']:SetPlaceholder(data.misc.pinnacleBossPen, true)
			build.configTab.varControls['enemyFirePen']:SetPlaceholder(data.misc.pinnacleBossPen, true)

			build.configTab.varControls['enemyArmour']:SetPlaceholder(round(data.monsterArmourTable[defaultLevel] * (data.bossStats.PinnacleArmourMean/100)), true)
			build.configTab.varControls['enemyEvasion']:SetPlaceholder(round(data.monsterEvasionTable[defaultLevel] * (data.bossStats.PinnacleEvasionMean/100)), true)
		elseif val == "Uber" then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("Condition:PinnacleBoss", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("DamageTaken", "MORE", -70, "Boss")
			enemyModList:NewMod("AilmentThreshold", "MORE", 404, "Boss")
			modList:NewMod("WarcryPower", "BASE", 20, "Boss")
			modList:NewMod("Multiplier:EnemyPower", "BASE", 20, "Boss")

			local defaultEleResist = 50
			build.configTab.varControls['enemyLightningResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyColdResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyFireResist']:SetPlaceholder(defaultEleResist, true)
			build.configTab.varControls['enemyChaosResist']:SetPlaceholder(30, true)

			local defaultLevel = 85
			build.configTab.varControls['enemyLevel']:SetPlaceholder(defaultLevel, true)
			build.configTab:UpdateLevel()
			if build.configTab.enemyLevel then
				defaultLevel = m_max(build.configTab.enemyLevel, defaultLevel)
			end

			local defaultDamage = round(data.monsterDamageTable[defaultLevel] * 1.5  * data.misc.uberBossDPSMult)
			build.configTab.varControls['enemyPhysicalDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyLightningDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyColdDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyFireDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyChaosDamage']:SetPlaceholder(round(defaultDamage / 4), true)

			build.configTab.varControls['enemyLightningPen']:SetPlaceholder(data.misc.uberBossPen, true)
			build.configTab.varControls['enemyColdPen']:SetPlaceholder(data.misc.uberBossPen, true)
			build.configTab.varControls['enemyFirePen']:SetPlaceholder(data.misc.uberBossPen, true)

			build.configTab.varControls['enemyArmour']:SetPlaceholder(round(data.monsterArmourTable[defaultLevel] * (data.bossStats.UberArmourMean/100)), true)
			build.configTab.varControls['enemyEvasion']:SetPlaceholder(round(data.monsterEvasionTable[defaultLevel] * (data.bossStats.UberEvasionMean/100)), true)
		end
	end },
	{ var = "deliriousPercentage", type = "list", label = "Delirious Effect:", list = {{val=0,label="None"},{val="20Percent",label="20% Delirious"},{val="40Percent",label="40% Delirious"},{val="60Percent",label="60% Delirious"},{val="80Percent",label="80% Delirious"},{val="100Percent",label="100% Delirious"}}, tooltip = "Delirium scales enemy 'less Damage Taken' as well as enemy 'increased Damage dealt'\nAt 100% effect:\nEnemies Deal 30% Increased Damage\nEnemies take 80% Less Damage", apply = function(val, modList, enemyModList)
		if val == "20Percent" then
			enemyModList:NewMod("DamageTaken", "MORE", -16, "20% Delirious")
			enemyModList:NewMod("Damage", "INC", 6, "20% Delirious")
		end
		if val == "40Percent" then
			enemyModList:NewMod("DamageTaken", "MORE", -32, "40% Delirious")
			enemyModList:NewMod("Damage", "INC", 12, "40% Delirious")
		end
		if val == "60Percent" then
			enemyModList:NewMod("DamageTaken", "MORE", -48, "60% Delirious")
			enemyModList:NewMod("Damage", "INC", 18, "60% Delirious")
		end
		if val == "80Percent" then
			enemyModList:NewMod("DamageTaken", "MORE", -64, "80% Delirious")
			enemyModList:NewMod("Damage", "INC", 24, "80% Delirious")
		end
		if val == "100Percent" then
			enemyModList:NewMod("DamageTaken", "MORE", -80, "100% Delirious")
			enemyModList:NewMod("Damage", "INC", 30, "100% Delirious")
		end
	end },
	{ var = "enemyPhysicalReduction", type = "integer", label = "Enemy Phys. Damage Reduction:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("PhysicalDamageReduction", "BASE", val, "EnemyConfig")
	end },
	{ var = "enemyLightningResist", type = "integer", label = "Enemy ^xADAA47Lightning Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("LightningResist", "BASE", val, "EnemyConfig")
	end },
	{ var = "enemyColdResist", type = "integer", label = "Enemy ^x3F6DB3Cold Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ColdResist", "BASE", val, "EnemyConfig")
	end },
	{ var = "enemyFireResist", type = "integer", label = "Enemy ^xB97123Fire Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireResist", "BASE", val, "EnemyConfig")
	end },
	{ var = "enemyChaosResist", type = "integer", label = "Enemy ^xD02090Chaos Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ChaosResist", "BASE", val, "EnemyConfig")
	end },
	{ var = "enemyMaxResist", type = "check", label = "Enemy Max Resistance is always 75%", tooltip = "Enemy Maximum resistance is increased by the resistance configurations \nThis locks it at the default value", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("DoNotChangeMaxResFromConfig", "FLAG", true, "EnemyConfig")
	end },
	{ var = "enemyBlockChance", type = "integer", label = "Enemy Block Chance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("BlockChance", "BASE", val, "Config")
	end },
	{ var = "enemyEvasion", type = "count", label = "Enemy Base ^x33FF77Evasion:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Evasion", "BASE", val, "Config")
	end },
	{ var = "enemyArmour", type = "count", label = "Enemy Base Armour:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Armour", "BASE", val, "Config")
	end },
	{ var = "presetBossSkills", type = "list", label = "Boss Skill Preset", tooltipFunc = bossSkillsTooltip, list = data.bossSkillsList, apply = function(val, modList, enemyModList, build)
		if not (val == "None") then
			local bossData = data.bossSkills[val]
			local isUber = build.configTab.varControls['enemyIsBoss'].list[build.configTab.varControls['enemyIsBoss'].selIndex].val == "Uber"
			if bossData.earlierUber and build.configTab.varControls['enemyIsBoss'].list[build.configTab.varControls['enemyIsBoss'].selIndex].val == "Pinnacle" then
				isUber = true
			end
			local defaultDamage = ""
			build.configTab.varControls['enemyPhysicalDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyLightningDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyColdDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyFireDamage']:SetPlaceholder(defaultDamage, true)
			build.configTab.varControls['enemyChaosDamage']:SetPlaceholder(defaultDamage, true)
			
			local rollRangeMult = m_min(m_max(build.configTab.input['enemyDamageRollRange'] or build.configTab.varControls['enemyDamageRollRange'].placeholder, 0), 100)
			for damageType, damageMult in pairs(bossData.DamageMultipliers) do
				if isUber and bossData.UberDamageMultiplier then
					build.configTab.varControls['enemy'..damageType..'Damage']:SetPlaceholder(round(data.monsterDamageTable[build.configTab.enemyLevel] * (damageMult[1] + rollRangeMult * damageMult[2]) * bossData.UberDamageMultiplier), true)
				else
					build.configTab.varControls['enemy'..damageType..'Damage']:SetPlaceholder(round(data.monsterDamageTable[build.configTab.enemyLevel] * (damageMult[1] + rollRangeMult * damageMult[2])), true)
				end
			end

			local defaultPen = ""
			build.configTab.varControls['enemyPhysicalOverwhelm']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyLightningPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyColdPen']:SetPlaceholder(defaultPen, true)
			build.configTab.varControls['enemyFirePen']:SetPlaceholder(defaultPen, true)
			
			if bossData.DamagePenetrations then
				for penType, pen in pairs(bossData.DamagePenetrations) do
					if isUber and bossData.UberDamagePenetrations and bossData.UberDamagePenetrations[penType] then
						build.configTab.varControls['enemy'..penType]:SetPlaceholder(bossData.UberDamagePenetrations[penType], true)
					else
						build.configTab.varControls['enemy'..penType]:SetPlaceholder(pen, true)
					end
				end
			end
			
			if bossData.DamageType then
				build.configTab.varControls['enemyDamageType']:SelByValue(bossData.DamageType, "val")
				build.configTab.input['enemyDamageType'] = bossData.DamageType
			end
			build.configTab.varControls['enemyDamageType'].enabled = false
			
			if isUber and bossData.UberSpeed then
				build.configTab.varControls['enemySpeed']:SetPlaceholder(bossData.UberSpeed, true)
			elseif bossData.speed then
				build.configTab.varControls['enemySpeed']:SetPlaceholder(bossData.speed, true)
			end
			if bossData.critChance then
				build.configTab.varControls['enemyCritChance']:SetPlaceholder(bossData.critChance, true)
			end
			
			modList:NewMod("BossSkillActive", "FLAG", true, "Config")

			-- boss specific mods
			if val == "Atziri Flameblast" and isUber then
				enemyModList:NewMod("Damage", "INC", 60, "Alluring Abyss Map Mod")
			end
			if bossData.additionalStats then
				local additionalStats = isUber and bossData.additionalStats.uber or bossData.additionalStats.base
				if additionalStats then
					for k, v in pairs(additionalStats) do
						if tostring(v) == "flag" then
							enemyModList:NewMod(k, "FLAG", true, "BossSkillAdditionalData")
						else
							enemyModList:NewMod(k, "BASE", v, "BossSkillAdditionalData")
						end
					end
				end
			end
		else
			build.configTab.varControls['enemyDamageType'].enabled = true
		end
	end },
	{ var = "enemyDamageRollRange", type = "integer", label = "Enemy Skill Roll Range %:", ifFlag = "BossSkillActive", tooltip = "The percentage of the roll range the enemy hits for \n eg at 100% the enemy deals its maximum damage", defaultPlaceholderState = 70, hideIfInvalid = true },
	{ var = "enemyDamageType", type = "list", label = "Enemy Damage Type:", tooltip = "Controls which types of damage the EHP calculation uses:\n\tAverage: uses the Average of all typed damage types (not Untyped)\n\nIf a specific damage type is selected, that will be the only type used.", list = {{val="Average",label="Average"},{val="Untyped",label="Untyped"},{val="Melee",label="Melee"},{val="Projectile",label="Projectile"},{val="Spell",label="Spell"},{val="SpellProjectile",label="Projectile Spell"}} },
	{ var = "enemySpeed", type = "integer", label = "Enemy attack / cast time in ms:", defaultPlaceholderState = 700 },
	{ var = "enemyMultiplierPvpDamage", type = "count", label = "Custom PvP Damage multiplier percent:", ifFlag = "isPvP", tooltip = "This multiplies the damage of a given skill in pvp, for instance any with damage multiplier specific to pvp (from skill or support or item like sire of shards)", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("MultiplierPvpDamage", "BASE", val, "Config")
	end },
	{ var = "enemyCritChance", type = "integer", label = "Enemy critical strike chance:", defaultPlaceholderState = 5 },
	{ var = "enemyCritDamage", type = "integer", label = "Enemy critical strike multiplier:", defaultPlaceholderState = 30 },
	{ var = "enemyPhysicalDamage", type = "integer", label = "Enemy Skill Physical Damage:", tooltip = "This overrides the default damage amount used to estimate your damage reduction from armour.\nThe default is 1.5 times the enemy's base damage, which is the same value\nused in-game to calculate the estimate shown on the character sheet."},
	{ var = "enemyPhysicalOverwhelm", type = "integer", label = "Enemy Skill Physical Overwhelm:"},
	{ var = "enemyLightningDamage", type = "integer", label = "Enemy Skill ^xADAA47Lightning Damage:"},
	{ var = "enemyLightningPen", type = "integer", label = "Enemy Skill ^xADAA47Lightning Pen:"},
	{ var = "enemyColdDamage", type = "integer", label = "Enemy Skill ^x3F6DB3Cold Damage:"},
	{ var = "enemyColdPen", type = "integer", label = "Enemy Skill ^x3F6DB3Cold Pen:"},
	{ var = "enemyFireDamage", type = "integer", label = "Enemy Skill ^xB97123Fire Damage:"},
	{ var = "enemyFirePen", type = "integer", label = "Enemy Skill ^xB97123Fire Pen:"},
	{ var = "enemyChaosDamage", type = "integer", label = "Enemy Skill ^xD02090Chaos Damage:"},
	
	-- Section: Custom mods
	{ section = "Custom Modifiers", col = 1 },
	{ var = "customMods", type = "text", label = "", doNotHighlight = true,
		apply = function(val, modList, enemyModList, build)
			for line in val:gmatch("([^\n]*)\n?") do
				local strippedLine = StripEscapes(line):gsub("^[%s?]+", ""):gsub("[%s?]+$", "")
				local mods, extra = modLib.parseMod(strippedLine)

				if mods and not extra then
					local source = "Custom"
					for i = 1, #mods do
						local mod = mods[i]

						if mod then
							mod = modLib.setSource(mod, source)
							modList:AddMod(mod)
						end
					end
				end
			end
		end,
		inactiveText = function(val)
			local inactiveText = ""
			for line in val:gmatch("([^\n]*)\n?") do
				local strippedLine = StripEscapes(line):gsub("^[%s?]+", ""):gsub("[%s?]+$", "")
				local mods, extra = modLib.parseMod(strippedLine)
				inactiveText = inactiveText .. ((mods and not extra) and colorCodes.MAGIC or colorCodes.UNSUPPORTED).. (IsKeyDown("ALT") and strippedLine or line) .. "\n"
			end
			return inactiveText
		end,
		tooltip = function(modList)
			if not launch.devModeAlt then
				return
			end

			local out
			for _, mod in ipairs(modList) do
				if mod.source == "Custom" then
					out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
				end
			end
			return out
		end},
}
