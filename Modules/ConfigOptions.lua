-- Path of Building
--
-- Module: Config Options
-- List of options for the Configuration tab.
--

local m_min = math.min
local m_max = math.max

return {
	-- Section: General options
	{ section = "General", col = 1 },
	{ var = "resistancePenalty", type = "list", label = "Resistance penalty:", ifVer = "3_0", list = {{val=0,label="None"},{val=-30,label="Act 5 (-30%)"},{val=nil,label="Act 10 (-60%)"}} },
	{ var = "enemyLevel", type = "count", label = "Enemy Level:", tooltip = "This overrides the default enemy level used to estimate your hit and evade chances.\nThe default level is your character level, capped at 84, which is the same value\nused in-game to calculate the stats on the character sheet." },
	{ var = "enemyPhysicalHit", type = "count", label = "Enemy Physical Hit Damage:", tooltip = "This overrides the default damage amount used to estimate your physical damage reduction from armour.\nThe default is 1.5 times the enemy's base damage, which is the same value\nused in-game to calculate the estimate shown on the character sheet." },
	{ var = "detonateDeadCorpseLife", type = "count", label = "Enemy Corpse Life:", tooltip = "Sets the maximum life of the target corpse for Detonate Dead and similar skills.\nFor reference, a level 70 monster has "..data["3_0"].monsterLifeTable[70].." base life, and a level 80 monster has "..data["3_0"].monsterLifeTable[80]..".", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "corpseLife", value = val }, "Config")
	end },
	{ var = "conditionStationary", type = "count", label = "Are you stationary?", ifCond = "Stationary", 
		tooltip = "Applies mods that use `while stationary` and `per/every second while stationary`",
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
	{ var = "conditionFullLife", type = "check", label = "Are you always on Full Life?", tooltip = "You will automatically be considered to be on Full Life if you have Chaos Inoculation,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullLife", "FLAG", true, "Config")
	end },
	{ var = "conditionLowLife", type = "check", label = "Are you always on Low Life?", ifCond = "LowLife", tooltip = "You will automatically be considered to be on Low Life if you have at least 65% life reserved,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LowLife", "FLAG", true, "Config")
	end },
	{ var = "conditionFullEnergyShield", type = "check", label = "Are you always on Full Energy Shield?", ifCond = "FullEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullEnergyShield", "FLAG", true, "Config")
	end },
	{ var = "conditionHaveEnergyShield", type = "check", label = "Do you always have Energy Shield?", ifCond = "HaveEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveEnergyShield", "FLAG", true, "Config")
	end },
	{ var = "minionsConditionFullLife", type = "check", label = "Are your minions always on Full Life?", ifMinionCond = "FullLife", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:FullLife", "FLAG", true, "Config") }, "Config")
	end },
	{ var = "minionsConditionCreatedRecently", type = "check", label = "Have your minions been created Recently?", ifCond = "MinionsCreatedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MinionsCreatedRecently", "FLAG", true, "Config")
	end },
	{ var = "igniteMode", type = "list", label = "Ignite calculation mode:", tooltip = "Controls how the base damage for ignite is calculated:\nAverage Damage: Ignite is based on the average damage dealt, factoring in crits and non-crits.\nCrit Damage: Ignite is based on crit damage only.", list = {{val="AVERAGE",label="Average Damage"},{val="CRIT",label="Crit Damage"}} },
	{ var = "lifeRegenMode", type = "list", label = "Life regen calculation mode:", tooltip = "Controls how life regeneration is calculated:\nMinimum: Does not include burst regen.\nAverage: Averages out burst regen over time.\nBurst: Includes full burst regen in the calculation.", list = {{val="MIN",label="Minimum"},{val="AVERAGE",label="Average"},{val="FULL",label="Burst"}}, apply = function(val, modList, enemyModList)
		if val == "AVERAGE" then
			modList:NewMod("Condition:LifeRegenBurstAvg", "FLAG", true, "Config")
		elseif val == "FULL" then
			modList:NewMod("Condition:LifeRegenBurstFull", "FLAG", true, "Config")
		end
	end },
	{ var = "EhpCalcMode", type = "list", label = "EHP calc calculation mode:", tooltip = "Controls which types of damage the EHP calculation uses:\nAverage: Uses the Averages of all the damage types.\nMinimum: Calculates each one and uses the worst one.\nThe rest  are the specific types damage", list = {{val="Average",label="Average"},{val="Minimum",label="Minimum"},{val="Melee",label="Melee"},{val="Projectile",label="Projectile"},{val="Spell",label="Spell"},{val="SpellProjectile",label="SpellProjectile"}} }, 

	-- Section: Skill-specific options
	{ section = "Skill Options", col = 2 },
	{ label = "Arcanist Brand:", ifSkill = "Arcanist Brand" },
	{ var = "targetBrandedEnemy", type = "check", label = "Skills are targeting the Branded Enemy?", ifSkill = "Arcanist Brand", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TargetingBrandedEnemy", "FLAG", true, "Config")
	end },
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
	{ label = "Banner Skills:", ifSkillList = { "Dread Banner", "War Banner" } },
	{ var = "bannerPlanted", type = "check", label = "Is Banner Planted?", ifSkillList = { "Dread Banner", "War Banner" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BannerPlanted", "FLAG", true, "Config", { type = "SkillName", skillNameList = { "Dread Banner", "War Banner" } })
	end },
	{ var = "bannerStages", type = "count", label = "Banner Stages:", ifSkillList = { "Dread Banner", "War Banner" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:BannerStage", "BASE", m_min(val, 50), "Config", { type = "SkillName", skillNameList = { "Dread Banner", "War Banner" } })
	end },
	{ label = "Bladestorm:", ifSkill = "Bladestorm" },
	{ var = "bladestormInBloodstorm", type = "check", label = "Are you in a Bloodstorm?", ifSkill = "Bladestorm", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BladestormInBloodstorm", "FLAG", true, "Config", { type = "SkillName", skillName = "Bladestorm" })
	end },
	{ var = "bladestormInSandstorm", type = "check", label = "Are you in a Sandstorm?", ifSkill = "Bladestorm", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BladestormInSandstorm", "FLAG", true, "Config", { type = "SkillName", skillName = "Bladestorm" })
	end },
	{ label = "Bonechill Support:", ifSkill = "Bonechill" },
	{ var = "bonechillEffect", type = "count", label = "Effect of Chill:", tooltip = "The effect of Chill is automatically calculated if you have a guaranteed source of Chill,\nbut you can use this to override the effect if necessary.", ifSkill = "Bonechill", apply = function(val, modList, enemyModList)
		modList:NewMod("BonechillEffect", "OVERRIDE", m_min(val, 30), "Config")
		modList:NewMod("DesiredBonechillEffect", "BASE", m_min(val, 30), "Config")
	end },
	{ label = "Brand Skills:", ifSkillList = { "Armageddon Brand", "Storm Brand", "Arcanist Brand", "Penance Brand", "Wintertide Brand" } }, -- I barely resisted the temptation to label this "Generic Brand:"
	{ var = "BrandsAttachedToEnemy", type = "count", label = "# of Brands attached to the enemy", ifSkillList = { "Armageddon Brand", "Storm Brand", "Arcanist Brand", "Penance Brand", "Wintertide Brand" }, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ConfigBrandsAttachedToEnemy", "BASE", val, "Config")
	end },
	{ var = "BrandsInLastQuarter", type = "check", label = "Last 25% of Attached Duration?", ifCond = "BrandLastQuarter", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BrandLastQuarter", "FLAG", true, "Config")
	end },
	{ label = "Dark Pact:", ifSkill = "Dark Pact" },
	{ var = "darkPactSkeletonLife", type = "count", label = "Skeleton Life:", ifSkill = "Dark Pact", tooltip = "Sets the maximum life of the skeleton that is being targeted.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "skeletonLife", value = val }, "Config", { type = "SkillName", skillName = "Dark Pact" })
	end },
	{ label = "Deathmark:", ifSkill = "Deathmark" },
	{ var = "deathmarkDeathmarkActive", type = "check", label = "Is the enemy Deathmarked?", ifSkill = "Deathmark", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EnemyHasDeathmark", "FLAG", true, "Config")
	end },
	{ label = "Feeding Frenzy:", ifSkill = "Feeding Frenzy" },
	{ var = "feedingFrenzyFeedingFrenzyActive", type = "check", label = "Is Feeding Frenzy active?", ifSkill = "Feeding Frenzy", tooltip = "Feeding Frenzy grants:\n10% more Minion Damage\n10% increased Minion Movement Speed\n10% increased Minion Attack and Cast Speed", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FeedingFrenzyActive", "FLAG", true, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Damage", "MORE", 10, "Feeding Frenzy") }, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("MovementSpeed", "INC", 10, "Feeding Frenzy") }, "Config")
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Speed", "INC", 10, "Feeding Frenzy") }, "Config")
	end },
	{ label = "Herald of Agony:", ifSkill = "Herald of Agony" },
	{ var = "heraldOfAgonyVirulenceStack", type = "count", label = "# of Virulence Stacks:", ifSkill = "Herald of Agony", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:VirulenceStack", "BASE", m_min(val, 40), "Config")
	end },
	{ label = "Ice Nova:", ifSkill = "Ice Nova" },
	{ var = "iceNovaCastOnFrostbolt", type = "check", label = "Cast on Frostbolt?", ifSkill = "Ice Nova", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastOnFrostbolt", "FLAG", true, "Config", { type = "SkillName", skillName = "Ice Nova" })
	end },
	{ label = "Infusion:", ifSkill = "Infused Channelling" },
	{ var = "infusedChannellingInfusion", type = "check", label = "Is Infusion active?", ifSkill = "Infused Channelling", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:InfusionActive", "FLAG", true, "Config")
	end },
	{ label = "Innervate:", ifSkill = "Innervate" },
	{ var = "innervateInnervation", type = "check", label = "Is Innervation active?", ifSkill = "Innervate", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:InnervationActive", "FLAG", true, "Config")
	end },
	{ label = "Intensify:", ifSkill = "Intensify" },
	{ var = "intensifyIntensity", type = "count", label = "# of Intensity:", ifSkill = "Intensify", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Intensity", "BASE", val, "Config")
	end },
	{ label = "Meat Shield:", ifSkill = "Meat Shield" },
	{ var = "meatShieldEnemyNearYou", type = "check", label = "Is the enemy near you?", ifSkill = "Meat Shield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MeatShieldEnemyNearYou", "FLAG", true, "Config")
	end },
	{ label = "Perforate:", ifSkill = "Perforate"},
	{ var = "perforateSpikeOverlap", type = "count", label = "# of Overlapping Spikes:", tooltip = "Affects the DPS of Perforate in Blood Stance.\nMaximum is limited by the number of Spikes of Perforate.", ifSkill = "Perforate", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PerforateSpikeOverlap", "BASE", val, "Config", { type = "SkillName", skillName = "Perforate" })
	end },
	{ label = "Raise Spectre:", ifSkill = "Raise Spectre" },
	{ var = "raiseSpectreSpectreLevel", type = "count", label = "Spectre Level:", ifSkill = "Raise Spectre", ifVer = "2_6", tooltip = "Sets the level of the raised spectre.\nThe default level is the level requirement of the Raise Spectre skill.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "minionLevel", value = val }, "Config", { type = "SkillName", skillName = "Raise Spectre" })
	end },
	{ var = "raiseSpectreEnableCurses", type = "check", label = "Enable curses:", ifSkill = "Raise Spectre", tooltip = "Enable any curse skills that your spectres have.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillType", skillType = SkillType.Curse }, { type = "SkillName", skillName = "Raise Spectre", summonSkill = true })
	end },
	{ var = "raiseSpectreBladeVortexBladeCount", type = "count", label = "Blade Vortex blade count:", ifSkillList = {"DemonModularBladeVortexSpectre","GhostPirateBladeVortexSpectre"}, tooltip = "Sets the blade count for Blade Vortex skills used by spectres.\nDefault is 1; maximum is 5.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "dpsMultiplier", value = val }, "Config", { type = "SkillId", skillId = "DemonModularBladeVortexSpectre" })
		modList:NewMod("SkillData", "LIST", { key = "dpsMultiplier", value = val }, "Config", { type = "SkillId", skillId = "GhostPirateBladeVortexSpectre" })
	end },
	{ var = "raiseSpectreKaomFireBeamTotemStage", type = "count", label = "Scorching Ray Totem stage count:", ifSkill = "KaomFireBeamTotemSpectre", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:KaomFireBeamTotemStage", "BASE", val, "Config")
	end },
	{ var = "raiseSpectreEnableSummonedUrsaRallyingCry", type = "check", label = "Enable Summoned Ursa's Rallying Cry:", ifSkill = "DropBearSummonedRallyingCry", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "DropBearSummonedRallyingCry" })
	end },
	{ label = "Raise Spiders:", ifSkill = "Raise Spiders" },
	{ var = "raiseSpidersSpiderCount", type = "count", label = "# of Spiders:", ifSkill = "Raise Spiders", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:RaisedSpider", "BASE", m_min(val, 20), "Config")
	end },
	{ label = "Animate Weapon:", ifSkillList = {"Animate Weapon","Animate Guardian's Weapon"} },
	{ var = "animateWeaponWeaponCount", type = "count", label = "# of Weapons:", ifSkillList = {"Animate Weapon","Animate Guardian's Weapon"}, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:AnimatedWeapon", "BASE", m_min(val, 50), "Config")
	end },
	{ label = "Siphoning Trap:", ifSkill = "Siphoning Trap" },
	{ var = "siphoningTrapAffectedEnemies", type = "count", label = "# of Enemies affected:", ifSkill = "Siphoning Trap", tooltip = "Sets the number of enemies affected by Siphoning Trap.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyAffectedBySiphoningTrap", "BASE", val, "Config")
		modList:NewMod("Condition:SiphoningTrapSiphoning", "FLAG", true, "Config")
	end },
	{ label = "Snipe:", ifSkill = "Snipe" },
	{ var = "configSnipeStages", type = "count", label = "# of Snipe stages:", ifSkill = "Snipe", tooltip = "Sets the number of stages reached before releasing Snipe.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SnipeStage", "BASE", m_min(val, 6), "Config")
	end },
	{ label = "Stance Skills:", ifSkillList = { "Blood and Sand", "Flesh and Stone", "Lacerate", "Bladestorm", "Perforate" } },
	{ var = "bloodSandStance", type = "list", label = "Stance:", ifSkillList = { "Blood and Sand", "Flesh and Stone", "Lacerate", "Bladestorm", "Perforate" }, list = {{val="BLOOD",label="Blood Stance"},{val="SAND",label="Sand Stance"}}, apply = function(val, modList, enemyModList)
		if val == "SAND" then
			modList:NewMod("Condition:SandStance", "FLAG", true, "Config")
		end
	end },
	{ var = "changedStance", type = "check", label = "Changed Stance recently?", ifCond = "ChangedStanceRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChangedStanceRecently", "FLAG", true, "Config")
	end },
	{ label = "Summon Holy Relic:", ifSkill = "Summon Holy Relic" },
	{ var = "summonHolyRelicEnableHolyRelicBoon", type = "check", label = "Enable Holy Relic's Boon Aura:", ifSkill = "Summon Holy Relic", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "RelicTriggeredNova" })
	end },
	{ label = "Summon Lightning Golem:", ifSkill = "Summon Lightning Golem" },
	{ var = "summonLightningGolemEnableWrath", type = "check", label = "Enable Wrath Aura:", ifSkill = "Summon Lightning Golem", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "LightningGolemWrath" })
	end },
	{ label = "Toxic Rain:", ifSkill = "Toxic Rain" },
	{ var = "toxicRainPodOverlap", type = "count", label = "# of Overlapping Pods:", tooltip = "Maximum is limited by the number of Projectiles.", ifSkill = "Toxic Rain", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "podOverlapMultiplier", value = val }, "Config", { type = "SkillName", skillName = "Toxic Rain" })
	end },
	{ label = "Vortex:", ifSkill = "Vortex" },
	{ var = "vortexCastOnFrostbolt", type = "check", label = "Cast on Frostbolt?", ifSkill = "Vortex", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastOnFrostbolt", "FLAG", true, "Config", { type = "SkillName", skillName = "Vortex" })
	end },
	{ label = "Warcry Skills:", ifFlag = "warcry" },
	{ var = "multiplierWarcryPower", type = "count", label = "Warcry Power:", ifFlag = "warcry", tooltip = "Power determines how strong your Warcry buffs will be, and is based on the total strength of nearby enemies.\nPower is assumed to be 20 if your target is a Boss, but you can override it here if necessary.\nEach Normal enemy grants 1 Power\nEach Magic enemy grants 2 Power\nEach Rare enemy grants 10 Power\nEach Unique enemy grants 20 Power", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:WarcryPower", "OVERRIDE", val, "Config")
	end },
	{ label = "Wave of Conviction:", ifSkill = "Wave of Conviction" },
	{ var = "waveOfConvictionExposureType", type = "list", label = "Exposure Type:", ifSkill = "Wave of Conviction", list = {{val=0,label="None"},{val="Fire",label="Fire"},{val="Cold",label="Cold"},{val="Lightning",label="Lightning"}}, apply = function(val, modList, enemyModList)
		if val == "Fire" then
			modList:NewMod("Condition:WaveOfConvictionFireExposureActive", "FLAG", true, "Config")
		elseif val == "Cold" then
			modList:NewMod("Condition:WaveOfConvictionColdExposureActive", "FLAG", true, "Config")
		elseif val == "Lightning" then
			modList:NewMod("Condition:WaveOfConvictionLightningExposureActive", "FLAG", true, "Config")
		end
	end },
	{ label = "Winter Orb:", ifSkill = "Winter Orb" },
	{ var = "winterOrbStages", type = "count", label = "Stages:", ifSkill = "Winter Orb", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:WinterOrbStage", "BASE", val, "Config", { type = "SkillName", skillName = "Winter Orb" })
	end },
	{ var = "wintertideBrandStage", type = "count", label = "Wintertide Brand Stages:", ifSkill = "Wintertide Brand", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:WintertideBrandStage", "BASE", val, "Config", { type = "SkillName", skillName = "Wintertide Brand" })
	end },

	-- Section: Map modifiers/curses
	{ section = "Map Modifiers and Player Debuffs", col = 2 },
	{ label = "Map Prefix Modifiers:" },
	{ var = "enemyHasPhysicalReduction", type = "list", label = "Enemy Physical Damage reduction:", tooltip = "'Armoured'", list = {{val=0,label="None"},{val=20,label="20% (Low tier)"},{val=30,label="30% (Mid tier)"},{val=40,label="40% (High tier)"}}, apply = function(val, modList, enemyModList)	
		enemyModList:NewMod("PhysicalDamageReduction", "BASE", val, "Config")
	end },
	{ var = "enemyIsHexproof", type = "check", label = "Enemy is Hexproof?", tooltip = "'Hexproof'", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Hexproof", "FLAG", true, "Config")
	end },
	{ var = "enemyHasLessCurseEffectOnSelf", type = "list", label = "Less effect of Curses on Enemy:", tooltip = "'Hexwarded'", list = {{val=0,label="None"},{val=25,label="25% (Low tier)"},{val=40,label="40% (Mid tier)"},{val=60,label="60% (High tier)"}}, apply = function(val, modList, enemyModList)	
		if val ~= 0 then
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -val, "Config")
		end
	end },
	{ var = "enemyCanAvoidPoisonBlindBleed", type = "list", label = "Enemy avoid Poison/Blind/Bleed:", tooltip = "'Impervious'", list = {{val=0,label="None"},{val=25,label="25% (Low tier)"},{val=45,label="45% (Mid tier)"},{val=65,label="65% (High tier)"}}, apply = function(val, modList, enemyModList)	
		if val ~= 0 then
			enemyModList:NewMod("AvoidPoison", "BASE", val, "Config")
			enemyModList:NewMod("AvoidBleed", "BASE", val, "Config")
		end
	end },
	{ var = "enemyHasResistances", type = "list", label = "Enemy has Elemental/Chaos Resist:", tooltip = "'Resistant'", list = {{val=0,label="None"},{val="LOW",label="20%/15% (Low tier)"},{val="MID",label="30%/20% (Mid tier)"},{val="HIGH",label="40%/25% (High tier)"}}, apply = function(val, modList, enemyModList)
		local map = { ["LOW"] = {20,15}, ["MID"] = {30,20}, ["HIGH"] = {40,25} }
		if map[val] then
			enemyModList:NewMod("ElementalResist", "BASE", map[val][1], "Config")
			enemyModList:NewMod("ChaosResist", "BASE", map[val][2], "Config")
		end
	end },
	{ label = "Map Suffix Modifiers:" },
	{ var = "playerHasElementalEquilibrium", type = "check", label = "Player has Elemental Equilibrium?", tooltip = "'of Balance'", apply = function(val, modList, enemyModList)
		modList:NewMod("Keystone", "LIST", "Elemental Equilibrium", "Config")
	end },
	{ var = "playerCannotLeech", type = "check", label = "Cannot Leech Life/Mana?", tooltip = "'of Congealment'", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("CannotLeechLifeFromSelf", "FLAG", true, "Config")
		enemyModList:NewMod("CannotLeechManaFromSelf", "FLAG", true, "Config")
	end },
	{ var = "playerGainsReducedFlaskCharges", type = "list", label = "Gains reduced Flask Charges:", tooltip = "'of Drought'", list = {{val=0,label="None"},{val=30,label="30% (Low tier)"},{val=40,label="40% (Mid tier)"},{val=50,label="50% (High tier)"}}, apply = function(val, modList, enemyModList)
		if val ~= 0 then
			modList:NewMod("FlaskChargesGained", "INC", -val, "Config")
		end
	end },
	{ var = "playerHasMinusMaxResist", type = "count", label = "-X% maximum Resistances:", tooltip = "'of Exposure'\nMid tier: 5-8%\nHigh tier: 9-12%", apply = function(val, modList, enemyModList)
		if val ~= 0 then
			modList:NewMod("FireResistMax", "BASE", -val, "Config")
			modList:NewMod("ColdResistMax", "BASE", -val, "Config")
			modList:NewMod("LightningResistMax", "BASE", -val, "Config")
			modList:NewMod("ChaosResistMax", "BASE", -val, "Config")
		end
	end },
	{ var = "playerHasLessAreaOfEffect", type = "list", label = "Less Area of Effect:", tooltip = "'of Impotence'", list = {{val=0,label="None"},{val=15,label="15% (Low tier)"},{val=20,label="20% (Mid tier)"},{val=25,label="25% (High tier)"}}, apply = function(val, modList, enemyModList)
		if val ~= 0 then
			modList:NewMod("AreaOfEffect", "MORE", -val, "Config")
		end
	end },
	{ var = "enemyCanAvoidStatusAilment", type = "list", label = "Enemy avoid Elem. Status Ailments:", tooltip = "'of Insulation'", list = {{val=0,label="None"},{val=30,label="30% (Low tier)"},{val=60,label="60% (Mid tier)"},{val=90,label="90% (High tier)"}}, apply = function(val, modList, enemyModList)	
		if val ~= 0 then
			enemyModList:NewMod("AvoidIgnite", "BASE", val, "Config")
			enemyModList:NewMod("AvoidShock", "BASE", val, "Config")
			enemyModList:NewMod("AvoidFreeze", "BASE", val, "Config")
		end
	end },
	{ var = "enemyHasIncreasedAccuracy", type = "list", label = "Unlucky Dodge/Enemy has inc. Accuracy:", tooltip = "'of Miring'", list = {{val=0,label="None"},{val=30,label="30% (Low tier)"},{val=40,label="40% (Mid tier)"},{val=50,label="50% (High tier)"}}, apply = function(val, modList, enemyModList)
		if val ~= 0 then
			modList:NewMod("DodgeChanceIsUnlucky", "FLAG", true, "Config")
			enemyModList:NewMod("Accuracy", "INC", val, "Config")
		end
	end },
	{ var = "playerHasLessArmourAndBlock", type = "list", label = "Reduced Block Chance/less Armour:", tooltip = "'of Rust'", list = {{val=0,label="None"},{val="LOW",label="20%/20% (Low tier)"},{val="MID",label="30%/25% (Mid tier)"},{val="HIGH",label="40%/30% (High tier)"}}, apply = function(val, modList, enemyModList)
		local map = { ["LOW"] = {20,20}, ["MID"] = {30,25}, ["HIGH"] = {40,30} }
		if map[val] then
			modList:NewMod("BlockChance", "INC", -map[val][1], "Config")
			modList:NewMod("Armour", "MORE", -map[val][2], "Config")
		end
	end },
	{ var = "playerHasPointBlank", type = "check", label = "Player has Point Blank?", tooltip = "'of Skirmishing'", apply = function(val, modList, enemyModList)
		modList:NewMod("Keystone", "LIST", "Point Blank", "Config")
	end },
	{ var = "playerHasLessLifeESRecovery", type = "list", label = "Less Recovery Rate of Life and Energy Shield:", tooltip = "'of Smothering'", list = {{val=0,label="None"},{val=20,label="20% (Low tier)"},{val=40,label="40% (Mid tier)"},{val=60,label="60% (High tier)"}}, apply = function(val, modList, enemyModList)
		if val ~= 0 then
			modList:NewMod("LifeRecoveryRate", "MORE", -val, "Config")
			modList:NewMod("EnergyShieldRecoveryRate", "MORE", -val, "Config")
		end
	end },
	{ var = "playerCannotRegenLifeManaEnergyShield", type = "check", label = "Cannot Regen Life, Mana or ES?", tooltip = "'of Stasis'", apply = function(val, modList, enemyModList)
		modList:NewMod("NoLifeRegen", "FLAG", true, "Config")
		modList:NewMod("NoEnergyShieldRegen", "FLAG", true, "Config")
		modList:NewMod("NoManaRegen", "FLAG", true, "Config")
	end },
	{ var = "enemyTakesReducedExtraCritDamage", type = "count", label = "Enemy takes red. Extra Crit Damage:", tooltip = "'of Toughness'\nLow tier: 25-30%\nMid tier: 31-35%\nHigh tier: 36-40%" , apply = function(val, modList, enemyModList)
		if val ~= 0 then
			enemyModList:NewMod("SelfCritMultiplier", "INC", -val, "Config")
		end
	end },
	{ var = "multiplierSextant", type = "count", label = "# of Sextants affecting the area", ifMult = "Sextant", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Sextant", "BASE", m_min(val, 5), "Config")
	end },
	{ label = "Player is cursed by:" },
	{ var = "playerCursedWithAssassinsMark", type = "count", label = "Assassin's Mark:", tooltip = "Sets the level of Assassin's Mark to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "AssassinsMark", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithConductivity", type = "count", label = "Conductivity:", tooltip = "Sets the level of Conductivity to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { skillId = "Conductivity", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithDespair", type = "count", ifVer = "3_0", label = "Despair:", tooltip = "Sets the level of Despair to apply to the player.", apply = function(val, modList, enemyModList)
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
	{ var = "useInspirationCharges", type = "check", label = "Do you use Inspiration Charges?", ifMult = "InspirationCharge", apply = function(val, modList, enemyModList)
		modList:NewMod("UseInspirationCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideInspirationCharges", type = "count", label = "# of Inspiration Charges (if not maximum):", ifOption = "useInspirationCharges", apply = function(val, modList, enemyModList)
		modList:NewMod("InspirationCharges", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useGhostShrouds", type = "check", label = "Do you use Ghost Shrouds?", ifMult = "GhostShroud", apply = function(val, modList, enemyModList)
		modList:NewMod("UseGhostShrouds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "overrideGhostShrouds", type = "count", label = "# of Ghost Shrouds (if not maximum):", ifOption = "useGhostShrouds", apply = function(val, modList, enemyModList)
		modList:NewMod("GhostShrouds", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "minionsUsePowerCharges", type = "check", label = "Do your minions use Power Charges?", ifFlag = "haveMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("UsePowerCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsUseFrenzyCharges", type = "check", label = "Do your minions use Frenzy Charges?", ifFlag = "haveMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("UseFrenzyCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "minionsUseEnduranceCharges", type = "check", label = "Do your minions use Endur. Charges?", ifFlag = "haveMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("UseEnduranceCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" }) }, "Config")
	end },
	{ var = "multiplierRampage", type = "count", label = "# of Rampage Kills:", tooltip = "Maximum Rampage is 1000\nYou lose Rampage if you do not get a Kill within 5 seconds\nRampage grants:\n1% increased Movement Speed per 20 Rampage\n2% increased Damage per 20 Rampage", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:Rampage", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFocused", type = "check", label = "Are you Focussed?", ifCond = "Focused", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Focused", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffOnslaught", type = "check", label = "Do you have Onslaught?", tooltip = "In addition to allowing any 'while you have Onslaught' modifiers to apply,\nthis will enable the Onslaught buff itself. (20% increased Attack/Cast/Movement Speed)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Onslaught", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffUnholyMight", type = "check", label = "Do you have Unholy Might?", tooltip = "This will enable the Unholy Might buff. (Gain 30% of Physical Damage as Extra Chaos Damage)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UnholyMight", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffPhasing", type = "check", label = "Do you have Phasing?", ifCond = "Phasing", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Phasing", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffFortify", type = "check", label = "Do you have Fortify?", ifCond = "Fortify", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Fortify", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffTailwind", type = "check", label = "Do you have Tailwind?", tooltip = "In addition to allowing any 'while you have Tailwind' modifiers to apply,\nthis will enable the Tailwind buff itself. (You are 10% faster)", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Tailwind", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffAdrenaline", type = "check", label = "Do you have Adrenaline?", tooltip = "This will enable the Adrenaline buff:\n100% increased Damage\n25% increased Attack, Cast and Movement Speed\n10% additional Physical Damage Reduction", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Adrenaline", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffVaalArcLuckyHits", type = "check", label = "Do you have Vaal Arc's Lucky Buff?", ifCond = "CanBeLucky",  tooltip = "Damage with Arc Hits is rolled twice, maximum roll is used", apply = function(val, modList, enemyModList)
		modList:NewMod("LuckyHits", "FLAG", true, "Config", { type = "Condition", varList = { "Combat", "CanBeLucky" } }, { type = "SkillName", skillNameList = { "Arc", "Vaal Arc" } })
	end },
	{ var = "buffElusive", type = "check", label = "Are you Elusive?", ifCond = "CanBeElusive", tooltip = "In addition to allowing any 'while Elusive' modifiers to apply,\nthis will enable the Elusive buff itself. (15% Attack and Spell Dodge, 30% increased Movement Speed)\nThe effect of Elusive decays over time.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Elusive", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanBeElusive" })
		modList:NewMod("Elusive", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanBeElusive" })
	end },
	{ var = "buffDivinity", type = "check", label = "Do you have Divinity?", ifCond = "Divinity", tooltip = "This will enable the Divinity buff:\n50% more Elemental Damage\n20% less Elemental Damage Taken", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Divinity", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierRage", type = "count", label = "Rage:", ifCond = "CanGainRage", tooltip = "Base Maximum Rage is 50\nYou lose 1 Rage every 0.5 seconds if you have not been Hit or gained Rage Recently\nInherent effects from having Rage are:\n1% increased Attack Damage per 1 Rage\n1% increased Attack Speed per 2 Rage\n1% increased Movement Speed per 5 Rage", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:RageStack", "BASE", val, "Config", { type = "IgnoreCond" }, { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainRage" })
	end },
	{ var = "conditionLeeching", type = "check", label = "Are you Leeching?", ifCond = "Leeching", tooltip = "You will automatically be considered to be Leeching if you have 'Life Leech effects are not removed on full life',\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeechingLife", type = "check", label = "Are you Leeching Life?", ifCond = "LeechingLife", implyCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LeechingLife", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeechingEnergyShield", type = "check", label = "Are you Leeching Energy Shield?", ifCond = "LeechingEnergyShield", implyCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LeechingEnergyShield", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeechingMana", type = "check", label = "Are you Leeching Mana?", ifCond = "LeechingMana", implyCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LeechingMana", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsingFlask", type = "check", label = "Do you have a Flask active?", ifCond = "UsingFlask", tooltip = "This is automatically enabled if you have a flask active,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsingFlask", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHaveTotem", type = "check", label = "Do you have a Totem summoned?", ifCond = "HaveTotem", tooltip = "You will automatically be considered to have a Totem if your main skill is a Totem,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveTotem", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "TotemsSummoned", type = "count", label = "# of Summoned Totems (if not maximum):", ifSkillList = { "Spell Totem", "Ballista Totem", "Siege Ballista", "Artillery Ballista", "Shrapnel Ballista", "Ancestral Protector", "Ancestral Warchief", "Vaal Ancestral Warchief" }, tooltip = "This also implies that you have a Totem summoned.\nThis will affect all \"per Summoned Totem\" modifiers, even for non-Totem skills.", apply = function(val, modList, enemyModList)
		modList:NewMod("TotemsSummoned", "OVERRIDE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:HaveTotem", "FLAG", val >= 1, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNearbyAlly", type = "count", label = "# of Nearby Allies", ifMult = "NearbyAlly", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyAlly", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNearbyCorpse", type = "count", label = "# of Nearby Corpses", ifMult = "NearbyCorpse", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyCorpse", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierSummonedMinion", type = "count", label = "# of Summoned Minions", ifMult = "SummonedMinion", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:SummonedMinion", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnConsecratedGround", type = "check", label = "Are you on Consecrated Ground?", tooltip = "In addition to allowing any 'while on Consecrated Ground' modifiers to apply,\nthis will apply the 6% life regen modifier granted by Consecrated Ground.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnConsecratedGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnFungalGround", type = "check", label = "Are you on Fungal Ground?", ifCond = "OnFungalGround", tooltip = "Allies on your Fungal Ground gain 10% of Non-Chaos Damage as extra Chaos Damage", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnFungalGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnBurningGround", type = "check", label = "Are you on Burning Ground?", ifCond = "OnBurningGround", implyCond = "Burning", tooltip = "This also implies that you are Burning.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnBurningGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Burning", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnChilledGround", type = "check", label = "Are you on Chilled Ground?", ifCond = "OnChilledGround", implyCond = "Chilled", tooltip = "This also implies that you are Chilled.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnChilledGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnShockedGround", type = "check", label = "Are you on Shocked Ground?", ifCond = "OnShockedGround", implyCond = "Shocked", tooltip = "This also implies that you are Shocked.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnShockedGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBurning", type = "check", label = "Are you Burning?", ifCond = "Burning", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Burning", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnited", type = "check", label = "Are you Ignited?", ifCond = "Ignited", implyCond = "Burning", tooltip = "This also implies that you are Burning.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Ignited", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChilled", type = "check", label = "Are you Chilled?", ifCond = "Chilled", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFrozen", type = "check", label = "Are you Frozen?", ifCond = "Frozen", implyCond = "Chilled", tooltip = "This also implies that you are Chilled.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Frozen", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShocked", type = "check", label = "Are you Shocked?", ifCond = "Shocked", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("DamageTaken", "INC", 15, "Shock", { type = "Condition", var = "Shocked" })
	end },
	{ var = "conditionBleeding", type = "check", label = "Are you Bleeding?", ifCond = "Bleeding", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionPoisoned", type = "check", label = "Are you Poisoned?", ifCond = "Poisoned", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Poisoned", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierPoisonOnSelf", type = "count", label = "# of Poison on You:", ifMult = "PoisonStack", implyCond = "Poisoned", tooltip = "This also implies that you are Poisoned.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PoisonStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionAgainstDamageOverTime", type = "check", label = "Are you against Damage over Time?", ifCond = "AgainstDamageOverTime", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AgainstDamageOverTime", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNearbyEnemies", type = "count", label = "# of nearby Enemies:", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyEnemies", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:OnlyOneNearbyEnemy", "FLAG", val == 1, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierNearbyRareOrUniqueEnemies", type = "countAllowZero", label = "# of nearby Rare or Unique Enemies:", ifMult = "NearbyRareOrUniqueEnemies", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:NearbyRareOrUniqueEnemies", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Multiplier:NearbyEnemies", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:AtMostOneNearbyRareOrUniqueEnemy", "FLAG", val <= 1, "Config", { type = "Condition", var = "Combat" })
		enemyModList:NewMod("Condition:NearbyRareOrUniqueEnemy", "FLAG", val >= 1, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitRecently", type = "check", label = "Have you Hit Recently?", ifCond = "HitRecently", tooltip = "You will automatically be considered to have Hit Recently if your main skill is self-cast,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
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
	{ var = "conditionKilledRecently", type = "check", label = "Have you Killed Recently?", ifCond = "KilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierKilledRecently", type = "count", label = "# of Enemies Killed Recently", ifMult = "EnemyKilledRecently", implyCond = "KilledRecently", tooltip = "This also implies that you have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyKilledRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:KilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledLast3Seconds", type = "check", label = "Have you Killed in the last 3 Seconds?", ifCond = "KilledLast3Seconds", implyCond = "KilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledLast3Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledPosionedLast2Seconds", type = "check", label = "Killed poisoned enemy in the last 2 Seconds?", ifCond = "KilledPosionedLast2Seconds", implyCond = "KilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledPosionedLast2Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsNotSummonedInPastTwoSeconds", type = "check", label = "No summoned Totems in the past 2 seconds?", ifCond = "NoSummonedTotemsInPastTwoSeconds", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:NoSummonedTotemsInPastTwoSeconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsKilledRecently", type = "check", label = "Have your Totems Killed Recently?", ifCond = "TotemsKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TotemsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedBrandRecently", type = "check", label = "Have you used a Brand Skill recently?", ifCond = "UsedBrandRecently",  apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedBrandRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierTotemsKilledRecently", type = "count", label = "# of Enemies Killed by Totems Recently", ifMult = "EnemyKilledByTotemsRecently", implyCond = "TotemsKilledRecently", tooltip = "This also implies that your Totems have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyKilledByTotemsRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:TotemsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionMinionsKilledRecently", type = "check", label = "Have your Minions Killed Recently?", ifCond = "MinionsKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MinionsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionMinionsDiedRecently", type = "check", label = "Has a Minion Died Recently?", ifCond = "MinionsDiedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:MinionsDiedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierMinionsKilledRecently", type = "count", label = "# of Enemies Killed by Minions Recently", ifMult = "EnemyKilledByMinionsRecently", implyCond = "MinionsKilledRecently", tooltip = "This also implies that your Minions have Killed Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnemyKilledByMinionsRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:MinionsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledAffectedByDoT", type = "check", label = "Killed Enemy affected by your DoT Recently?", ifCond = "KilledAffectedByDotRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledAffectedByDotRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierShockedEnemyKilledRecently", type = "count", label = "# of Shocked Enemies Killed Recently:", ifMult = "ShockedEnemyKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ShockedEnemyKilledRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFrozenEnemyRecently", type = "check", label = "Have you Frozen an Enemy Recently?", ifCond = "FrozenEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FrozenEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionChilledEnemyRecently", type = "check", label = "Have you Chilled an Enemy Recently?", ifCond = "ChilledEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ChilledEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShatteredEnemyRecently", type = "check", label = "Have you Shattered an Enemy Recently?", ifCond = "ShatteredEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ShatteredEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnitedEnemyRecently", type = "check", label = "Have you Ignited an Enemy Recently?", ifCond = "IgnitedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:IgnitedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShockedEnemyRecently", type = "check", label = "Have you Shocked an Enemy Recently?", ifCond = "ShockedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ShockedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionStunnedEnemyRecently", type = "check", label = "Have you Stunned an Enemy Recently?", ifCond = "StunnedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StunnedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierPoisonAppliedRecently", type = "count", label = "# of Poisons applied Recently:", ifMult = "PoisonAppliedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PoisonAppliedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierManaSpentRecently", type = "count", label = "# of Mana spent Recently", ifMult = "ManaSpentRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ManaSpentRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenHitRecently", type = "check", label = "Have you been Hit Recently?", ifCond = "BeenHitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierBeenHitRecently", type = "count", label = "# of Have you been Hit Recently:", ifMult = "BeenHitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:BeenHitRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", 1 <= val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenCritRecently", type = "check", label = "Have you been Crit Recently?", ifCond = "BeenCritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenSavageHitRecently", type = "check", label = "Have you been Savage Hit Recently?", ifCond = "BeenSavageHitRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenSavageHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByFireDamageRecently", type = "check", label = "Have you been hit by Fire Recently?", ifCond = "HitByFireDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByFireDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByColdDamageRecently", type = "check", label = "Have you been hit by Cold Recently?", ifCond = "HitByColdDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByColdDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByLightningDamageRecently", type = "check", label = "Have you been hit by Light. Recently?", ifCond = "HitByLightningDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByLightningDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitBySpellDamageRecently", type = "check", label = "Have you taken Spell Damage Recently?", ifCond = "HitBySpellDamageRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitBySpellDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTakenFireDamageFromEnemyHitRecently", type = "check", label = "Taken Fire Damage from Enemy Hit Recently?", ifCond = "TakenFireDamageFromEnemyHitRecently", implyCond = "BeenHitRecently", tooltip = "This also implies that you have been Hit Recently.", apply = function(val, modList, enemyModList)
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
	{ var = "conditionEnergyShieldRechargeRecently", type = "check", label = "Energy Shield Recharge started Recently?", ifCond = "EnergyShieldRechargeRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EnergyShieldRechargeRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionStoppedTakingDamageOverTimeRecently", type = "check", label = "Have you stopped taking DoT recently?", ifCond = "StoppedTakingDamageOverTimeRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:StoppedTakingDamageOverTimeRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffPendulum", type = "check", ifVer = "2_6", label = "Is Pendulum of Destruction active?", ifNode = 57197, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:PendulumOfDestruction", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffPendulum", type = "list", ifVer = "3_0", label = "Is Pendulum of Destruction active?", ifNode = 57197, list = {{val=0,label="None"},{val="AREA",label="Area of Effect"},{val="DAMAGE",label="Elemental Damage"}}, apply = function(val, modList, enemyModList)
		if val == "AREA" then
			modList:NewMod("Condition:PendulumOfDestructionAreaOfEffect", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		elseif val == "DAMAGE" then
			modList:NewMod("Condition:PendulumOfDestructionElementalDamage", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		end
	end },
	{ var = "buffConflux", type = "list", label = "Conflux Buff:", ifNode = 51391, list = {{val=0,label="None"},{val="CHILLING",label="Chilling"},{val="SHOCKING",label="Shocking"},{val="IGNITING",label="Igniting"},{val="ALL",label="Chill + Shock + Ignite"}}, apply = function(val, modList, enemyModList)
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
	{ var = "buffBastionOfHope", type = "check", label = "Is Bastion of Hope active?", ifNode = 39728, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BastionOfHopeActive", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffNgamahuFlamesAdvance", type = "check", label = "Is Ngamahu, Flame's Advance active?", ifNode = 50692, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:NgamahuFlamesAdvance", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffHerEmbrace", type = "check", label = "Are you in Her Embrace?", ifCond = "HerEmbrace", tooltip = "This option is specific to Oni-Goroshi.", apply = function(val, modList, enemyModList)
		modList:NewMod("HerEmbrace", "FLAG", true, "Config", { type = "Condition", var = "Combat" }, { type = "Condition", var = "CanGainHerEmbrace" })
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
	{ var = "conditionCastLast1Seconds", type = "check", label = "Have you Cast a Spell in the last second?", ifCond = "CastLast1Seconds", implyCond = "CastSpellRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastLast1Seconds", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedFireSkillRecently", type = "check", label = "Have you used a Fire Skill Recently?", ifCond = "UsedFireSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedFireSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedColdSkillRecently", type = "check", label = "Have you used a Cold Skill Recently?", ifCond = "UsedColdSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedColdSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedMinionSkillRecently", type = "check", label = "Have you used a Minion Skill Recently?", ifCond = "UsedMinionSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently.\nYou will automatically be considered to have used a Minion skill Recently if your main skill is a minion skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedMinionSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:UsedSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedTravelSkillRecently", type = "check", label = "Have you used a Travel Skill Recently?", ifCond = "UsedTravelSkillRecently", implyCond = "UsedSkillRecently", tooltip = "This also implies that you have used a Skill Recently..", apply = function(val, modList, enemyModList)
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
	{ var = "multiplierMineDetonatedRecently", type = "count", label = "# of Mines Detonated Recently:", ifMult = "MineDetonatedRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:MineDetonatedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierTrapTriggeredRecently", type = "count", label = "# of Traps Triggered Recently:", ifMult = "TrapTriggeredRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:TrapTriggeredRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionThrownTrapOrMineRecently", type = "check", label = "Have you thrown a Trap or Mine Recently?", ifCond = "TrapOrMineThrownRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TrapOrMineThrownRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCursedEnemyRecently", type = "check", label = "Have you Cursed and Enemy Recently?",  ifCond="CursedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CursedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionSpawnedCorpseRecently", type = "check", label = "Spawned a corpse Recently?", ifCond = "SpawnedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SpawnedCorpseRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConsumedCorpseRecently", type = "check", label = "Consumed a corpse Recently?", ifCond = "ConsumedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ConsumedCorpseRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierCorpseConsumedRecently", type = "count", label = "# of Corpses Consumed Recently:", ifMult = "CorpseConsumedRecently", implyCond = "ConsumedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:CorpseConsumedRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:ConsumedCorpseRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierEnduranceChargesLostRecently", type = "count", label = "# of Endurance Charges lost Recently:", ifMult = "EnduranceChargesLostRecently", implyCond = "LostEnduranceChargeInPast8Sec", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnduranceChargesLostRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:LostEnduranceChargeInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTauntedEnemyRecently", type = "check", label = "Taunted an Enemy Recently?", ifCond = "TauntedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TauntedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLostEnduranceChargeInPast8Sec", type = "check", label = "Lost an Endurance Charge in the past 8s?", ifNode = 32249, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LostEnduranceChargeInPast8Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedFireSkillInPast10Sec", type = "check", ifVer = "2_6", label = "Have you used a Fire Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedFireSkillInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedColdSkillInPast10Sec", type = "check", ifVer = "2_6", label = "Have you used a Cold Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedColdSkillInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedLightningSkillInPast10Sec", type = "check", ifVer = "2_6", label = "Have you used a Light. Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedLightningSkillInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedHitFromUniqueEnemyRecently", type = "check", ifVer = "2_6", label = "Blocked hit from a Unique Recently?", ifNode = 63490, implyCond = "BlockedRecently", tooltip = "This also implies that you have Blocked Recently.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedHitFromUniqueEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Condition:BlockedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedHitFromUniqueEnemyInPast10Sec", type = "check", ifVer = "3_0", label = "Blocked hit from a Unique in the past 10s?", ifNode = 63490, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedHitFromUniqueEnemyInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "BlockedPast10Sec", type = "count", label = "Number of times you've blocked in the past 10s", ifNode = 63490, apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:BlockedPast10Sec", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionImpaledRecently", type = "check", ifVer="3_0", ifCond = "ImpaledRecently", label = "Impaled an Enemy recently?", apply = function(val, modList, enemyModLIst)
		modList:NewMod("Condition:ImpaledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierImpalesOnEnemy", type = "countAllowZero", label = "# of Impales on Enemy (if not maximum):", ifFlag = "impale", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:ImpaleStacks", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierBleedsOnEnemy", type = "count", label = "# of Bleeds on Enemy (if not maximum):", ifFlag = "bleed", tooltip = "Set number of Bleeds if using Crimson Dance node. Implies enemy is Bleeding", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:BleedStacks", "BASE", val, "Config", { type = "Condition", var = "Combat" })
		enemyModList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierFragileRegrowth", type = "count", label = "# of Fragile Regrowth Stacks:", ifMult = "FragileRegrowthCount", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:FragileRegrowthCount", "BASE", m_min(val,10), "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledUniqueEnemy", type = "check", ifVer = "3_0", label = "Killed Rare or Unique Enemy Recently?", ifNode = 3184, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledUniqueEnemy", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHaveArborix", type = "check", label = "Do you have Iron Reflexes?", ifCond = "HaveArborix", tooltip = "This option is specific to Arborix",apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveIronReflexes", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Keystone", "LIST", "Iron Reflexes", "Config")
	end },	
	{ var = "conditionHaveAugyre", type = "list", label = "Augyre rotating buff", ifCond = "HaveAugyre", list = {{val="EleOverload",label="Elemental Overload"},{val="ResTechnique",label="Resolute Technique"}}, tooltip = "This option is specific to Augyre", apply = function(val, modList, enemyModList)
		if val == "EleOverload" then
			modList:NewMod("Condition:HaveElementalOverload", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
			modList:NewMod("Keystone", "LIST", "Elemental Overload", "Config")
		elseif val == "ResTechnique" then
			modList:NewMod("Condition:HaveResoluteTechnique", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
			modList:NewMod("Keystone", "LIST", "Resolute Technique", "Config")
		end
	end },	
	{ var = "conditionHaveVulconus", type = "check", label = "Do you have Avatar Of Fire?", ifCond = "HaveVulconus", tooltip = "This option is specific to Vulconus", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveAvatarOfFire", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
		modList:NewMod("Keystone", "LIST", "Avatar of Fire", "Config")
	end },
	{ var = "conditionHaveManaStorm", type = "check", label = "Do you have Manastorm's Lightning Buff?", ifCond = "HaveManaStorm", tooltip = "This option is enable Manastorm's Lightning Damage Buff\nWhen you cast a Spell, Sacrifice all Mana to gain Added Maximum Lightning Damage\nequal to 25% of Sacrificed Mana for 4 Seconds", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:SacrificeManaForLightning", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	-- Section: Effective DPS options
	{ section = "For Effective DPS", col = 1 },
	{ var = "critChanceLucky", type = "check", label = "Is your Crit Chance Lucky?", apply = function(val, modList, enemyModList)
		modList:NewMod("CritChanceLucky", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "skillForkCount", type = "count", label = "# of times Skill has Forked:", ifFlag = "forking", apply = function(val, modList, enemyModList)
		modList:NewMod("ForkedCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "skillChainCount", type = "count", label = "# of times Skill has Chained:", ifFlag = "chaining", apply = function(val, modList, enemyModList)
		modList:NewMod("ChainCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "meleeDistance", type = "count", label = "Melee distance to enemy:", ifFlag = "melee" },
	{ var = "projectileDistance", type = "count", label = "Projectile travel distance:", ifFlag = "projectile" },
	{ var = "conditionAtCloseRange", type = "check", label = "Is the enemy at Close Range?", ifCond = "AtCloseRange", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AtCloseRange", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyMoving", type = "check", label = "Is the enemy Moving?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Moving", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFullLife", type = "check", label = "Is the enemy on Full Life?", ifEnemyCond = "FullLife", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:FullLife", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyLowLife", type = "check", label = "Is the enemy on Low Life?", ifEnemyCond = "LowLife", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:LowLife", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyCursed", type = "check", label = "Is the enemy Cursed?", ifEnemyCond = "Cursed", tooltip = "Your enemy will automatically be considered to be Cursed if you have at least one curse enabled,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Cursed", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBleeding", type = "check", label = "Is the enemy Bleeding?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyPoisoned", type = "check", label = "Is the enemy Poisoned?", ifEnemyCond = "Poisoned", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Poisoned", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierPoisonOnEnemy", type = "count", label = "# of Poison on Enemy:", implyCond = "Poisoned", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:PoisonStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierWitheredStackCount", type = "count", label = "# of Withered Stacks:", ifCond = "CanWither", tooltip = "Withered applies 6% increased Chaos Damage Taken to the enemy, up to 15 stacks.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Multiplier:WitheredStack", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierEnsnaredStackCount", type = "count", label = "# of Ensnare Stacks:", ifCond = "CanEnsnare", tooltip = "While ensnared, enemies take increased Projectile Damage from Attack Hits\nEnsnared enemies always count as moving, and have less movement speed while trying to break the snare.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:EnsnareStackCount", "BASE", val, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:Moving", "FLAG", true, "Config", { type = "MultiplierThreshold", actor = "enemy", var = "EnsnareStackCount", threshold = 1 })
	end },
	{ var = "conditionEnemyMaimed", type = "check", label = "Is the enemy Maimed?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Maimed", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyHindered", type = "check", label = "Is the enemy Hindered?", ifEnemyCond = "Hindered", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Hindered", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBlinded", type = "check", label = "Is the enemy Blinded?", tooltip = "In addition to allowing 'against Blinded Enemies' modifiers to apply,\nthis will lessen the enemy's chance to hit, and thereby increase your evade chance.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Blinded", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyTaunted", type = "check", label = "Is the enemy Taunted?", ifEnemyCond = "Taunted", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Taunted", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBurning", type = "check", label = "Is the enemy Burning?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Burning", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyIgnited", type = "check", label = "Is the enemy Ignited?", implyCond = "Burning", tooltip = "This also implies that the enemy is Burning.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Ignited", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyScorched", type = "check", ifFlag = "inflictScorch", label = "Is the enemy Scorched?", tooltip = "Scorched enemies have lowered elemental resistances, up to -30%.\nThis option will also allow you to input the effect of Scorched.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Scorched", "FLAG", true, "Config", { type = "Condition", var = "Effective" }, { type = "ActorCondition", actor = "enemy", var = "CanInflictScorch" })
	end },
	{ var = "conditionScorchedEffect", type = "count", label = "Effect of Scorched:", ifOption = "conditionEnemyScorched", tooltip = "This effect will only be applied while you can inflict Scorched.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ElementalResist", "BASE", -m_min(val, 30), "Config", { type = "Condition", var = "Scorched" }, { type = "ActorCondition", actor = "enemy", var = "CanInflictScorch" })
	end },
	{ var = "conditionEnemyChilled", type = "check", label = "Is the enemy Chilled?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyChilledByYourHits", type = "check", ifEnemyCond = "ChilledByYourHits", label = "Is the enemy Chilled by your Hits?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:ChilledByYourHits", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFrozen", type = "check", label = "Is the enemy Frozen?", implyCond = "Chilled", tooltip = "This also implies that the enemy is Chilled.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Frozen", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBrittle", type = "check", ifFlag = "inflictBrittle", label = "Is the enemy Brittle?", tooltip = "Hits against Brittle enemies have up to +15% Critical Strike Chance.\nThis option will also allow you to input the effect of Brittle.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Brittle", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionBrittleEffect", type = "count", label = "Effect of Brittle:", ifOption = "conditionEnemyBrittle", tooltip = "This effect will only be applied while you can inflict Brittle.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("SelfCritChance", "BASE", m_min(val, 15), "Config", { type = "Condition", var = "Brittle" }, { type = "ActorCondition", actor = "enemy", var = "CanInflictBrittle" })
	end },
	{ var = "conditionEnemyShocked", type = "check", label = "Is the enemy Shocked?", tooltip = "In addition to allowing any 'against Shocked Enemies' modifiers to apply,\nthis will allow you to input the effect of the Shock applied to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:ShockedConfig", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionShockEffect", type = "count", label = "Effect of Shock:", ifOption = "conditionEnemyShocked", tooltip = "If you have a guaranteed source of Shock,\nthe strongest one will apply instead unless this option would apply a stronger Shock.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ShockVal", "BASE", val, "Shock", { type = "Condition", var = "ShockedConfig" })
		enemyModList:NewMod("DesiredShockVal", "BASE", val, "Shock", { type = "Condition", var = "ShockedConfig", neg = true })
	end },
	{ var = "conditionEnemyOnShockedGround", type = "check", label = "Is the enemy on Shocked Ground?", tooltip = "This also implies that the enemy is Shocked.", ifEnemyCond = "OnShockedGround", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		enemyModList:NewMod("Condition:OnShockedGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemySapped", type = "check", ifFlag = "inflictSap", label = "Is the enemy Sapped?", tooltip = "Sapped enemies deal less damage, up to 20%.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Sapped", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierFreezeShockIgniteOnEnemy", type = "count", label = "# of Freeze/Shock/Ignite on Enemy:", ifMult = "FreezeShockIgniteOnEnemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:FreezeShockIgniteOnEnemy", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyIntimidated", type = "check", ifVer = "2_6", label = "Is the enemy Intimidated?", tooltip = "This adds the following modifiers:\n10% increased Damage Taken by enemy", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("DamageTaken", "INC", 10, "Intimidate")
	end },
	{ var = "conditionEnemyIntimidated", type = "check", ifVer = "3_0", label = "Is the enemy Intimidated?", tooltip = "This adds the following modifiers:\n10% increased Attack Damage Taken by enemy", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("DamageTaken", "INC", 10, "Intimidate", ModFlag.Attack)
	end },
	{ var = "conditionEnemyUnnerved", type = "check", ifVer = "3_0", label = "Is the enemy Unnerved?", tooltip = "This adds the following modifiers:\n10% increased Spell Damage Taken by enemy", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("DamageTaken", "INC", 10, "Unnerve", ModFlag.Spell)
	end },
	{ var = "conditionEnemyCoveredInAsh", type = "check", label = "Is the enemy covered in Ash?", tooltip = "This adds the following modifiers:\n20% less enemy Movement Speed\n20% increased Fire Damage Taken by enemy", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireDamageTaken", "INC", 20, "Ash")
	end },
	{ var = "conditionEnemyOnConsecratedGround", type = "check", label = "Is the enemy on consecrated ground?", tooltip = "In addition to allowing any relevant modifiers to apply,\nthis will cause your hits have 100% increased Critical Strike Chance on the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:OnConsecratedGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
		modList:NewMod("CritChance", "INC", 100, "Config", { type = "ActorCondition", actor = "enemy", var = "OnConsecratedGround" })
	end },
	{ var = "conditionEnemyOnFungalGround", type = "check", label = "Is the enemy on fungal ground?", ifCond = "OnFungalGround", tooltip = "Enemies on your Fungal Ground deal 10% less Damage", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:OnFungalGround", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyInChillingArea", type = "check", label = "Is the enemy in a chilling area?", ifEnemyCond = "InChillingArea", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:InChillingArea", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyRareOrUnique", type = "check", label = "is the enemy Rare or Unique?", ifEnemyCond = "EnemyRareOrUnique", tooltip = "Your enemy will automatically be considered to be Unique if one of the Boss options is selected.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "enemyIsBoss", type = "list", ifVer = "2_6", label = "Is the enemy a Boss?", tooltip = "Standard Boss adds the following modifiers:\n60% less Effect of your Curses\n+30% to enemy Elemental Resistances\n+15% to enemy Chaos Resistance\n\nShaper/Guardian adds the following modifiers:\n80% less Effect of your Curses\n+40% to enemy Elemental Resistances\n+25% to enemy Chaos Resistance\n50% less Duration of Bleed\n50% less Duration of Poison\n50% less Duration of Ignite", list = {{val="NONE",label="No"},{val=true,label="Standard Boss"},{val="SHAPER",label="Shaper/Guardian"}}, apply = function(val, modList, enemyModList)
		if val == true then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -60, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 30, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 15, "Boss")
		elseif val == "SHAPER" then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -80, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 40, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 25, "Boss")
			enemyModList:NewMod("SelfBleedDuration", "MORE", -50, "Boss")
			enemyModList:NewMod("SelfPoisonDuration", "MORE", -50, "Boss")
			enemyModList:NewMod("SelfIgniteDuration", "MORE", -50, "Boss")
		end
	end },
	{ var = "enemyIsBoss", type = "list", ifVer = "3_0", label = "Is the enemy a Boss?", tooltip = "Standard Boss adds the following modifiers:\n33% less Effect of your Curses\n+40% to enemy Elemental Resistances\n+25% to enemy Chaos Resistance\n\nShaper/Guardian adds the following modifiers:\n66% less Effect of your Curses\n+50% to enemy Elemental Resistances\n+30% to enemy Chaos Resistance\n+33% to enemy Armour\n\nSirus adds the following modifiers:\n66% less Effect of your Curses\n+50% to enemy Elemental Resistances\n+30% to enemy Chaos Resistance\n+100% to enemy Armour", list = {{val="NONE",label="No"},{val="Uber Atziri",label="Standard Boss"},{val="Shaper",label="Shaper/Guardian"},{val="Sirus",label="Sirus"}}, apply = function(val, modList, enemyModList)
		if val == "Uber Atziri" then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -33, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 40, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 25, "Boss")
			enemyModList:NewMod("AilmentThreshold", "BASE", 2190202, "Boss")
			modList:NewMod("Multiplier:WarcryPower", "BASE", 20, "Boss")
		elseif val == "Shaper" then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -66, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 50, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 30, "Boss")
			enemyModList:NewMod("Armour", "MORE", 33, "Boss")
			enemyModList:NewMod("AilmentThreshold", "BASE", 44360789, "Boss")
			modList:NewMod("Multiplier:WarcryPower", "BASE", 20, "Boss")
		elseif val == "Sirus" then
			enemyModList:NewMod("Condition:RareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -66, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 50, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 30, "Boss")
			enemyModList:NewMod("Armour", "MORE", 100, "Boss")
			enemyModList:NewMod("AilmentThreshold", "BASE", 37940148, "Boss")
			modList:NewMod("Multiplier:WarcryPower", "BASE", 20, "Boss")
		end
	end },
	{ var = "enemyAwakeningLevel", type = "count", label = "Awakening Level:", tooltip = "Each Awakening Level gives Bosses 3% more Life.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Life", "MORE", 3 * m_min(val, 8), "Config")
		modList:NewMod("AwakeningLevel", "BASE", m_min(val, 8), "Config")
	end },
	{ var = "enemyPhysicalReduction", type = "integer", label = "Enemy Phys. Damage Reduction:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("PhysicalDamageReduction", "BASE", val, "Config")
	end },
	{ var = "enemyFireResist", type = "integer", label = "Enemy Fire Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireResist", "BASE", val, "Config")
	end },
	{ var = "enemyColdResist", type = "integer", label = "Enemy Cold Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ColdResist", "BASE", val, "Config")
	end },
	{ var = "enemyLightningResist", type = "integer", label = "Enemy Lightning Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("LightningResist", "BASE", val, "Config")
	end },
	{ var = "enemyChaosResist", type = "integer", label = "Enemy Chaos Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ChaosResist", "BASE", val, "Config")
	end },
	{ var = "enemyConditionHitByFireDamage", type = "check", label = "Enemy was Hit by Fire Damage?", ifNode = 39085, apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HitByFireDamage", "FLAG", true, "Config")
	end },
	{ var = "enemyConditionHitByColdDamage", type = "check", label = "Enemy was Hit by Cold Damage?", ifNode = 39085, apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HitByColdDamage", "FLAG", true, "Config")
	end },
	{ var = "enemyConditionHitByLightningDamage", type = "check", label = "Enemy was Hit by Light. Damage?", ifNode = 39085, apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:HitByLightningDamage", "FLAG", true, "Config")
	end },
	{ var = "EEIgnoreHitDamage", type = "check", label = "Ignore Skill Hit Damage?", ifNode = 39085, tooltip = "This option prevents EE from being reset by the hit damage of your main skill." },
}