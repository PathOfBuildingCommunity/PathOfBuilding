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
	{ var = "enemyLevel", type = "number", label = "Enemy Level:", tooltip = "This overrides the default enemy level used to estimate your hit and evade chances.\nThe default level is your character level, capped at 84, which is the same value\nused in-game to calculate the stats on the character sheet." },
	{ var = "enemyPhysicalHit", type = "number", label = "Enemy Physical Hit Damage:", tooltip = "This overrides the default damage amount used to estimate your physical damage reduction from armour.\nThe default is 1.5 times the enemy's base damage, which is the same value\nused in-game to calculate the estimate shown on the character sheet." },
	{ var = "detonateDeadCorpseLife", type = "number", label = "Enemy Corpse Life:", tooltip = "Sets the maximum life of the target corpse for Detonate Dead and similar skills.\nFor reference, a level 70 monster has "..data["3_0"].monsterLifeTable[70].." base life, and a level 80 monster has "..data["3_0"].monsterLifeTable[80]..".", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "corpseLife", value = val }, "Config")
	end },
	{ var = "conditionStationary", type = "check", label = "Are you always stationary?", ifCond = "Stationary", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Stationary", "FLAG", true, "Config")
	end },
	{ var = "conditionMoving", type = "check", label = "Are you always moving?", ifCond = "Moving", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Moving", "FLAG", true, "Config")
	end },
	{ var = "conditionFullLife", type = "check", label = "Are you always on Full Life?", tooltip = "You will automatically be considered to be on Full Life if you have Chaos Innoculation,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullLife", "FLAG", true, "Config")
	end },
	{ var = "conditionLowLife", type = "check", label = "Are you always on Low Life?", ifCond = "LowLife", tooltip = "You will automatically be considered to be on Low Life if you have at least 65% life reserved,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LowLife", "FLAG", true, "Config")
	end },
	{ var = "conditionFullEnergyShield", type = "check", label = "Are you always on Full Energy Shield?", ifCond = "FullEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullEnergyShield", "FLAG", true, "Config")
	end },
	{ var = "minionsConditionFullLife", type = "check", label = "Are your minions always on Full Life?", ifMinionCond = "FullLife", apply = function(val, modList, enemyModList)
		modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Condition:FullLife", "FLAG", true, "Config") }, "Config")
	end },
	{ var = "igniteMode", type = "list", label = "Ignite calculation mode:", tooltip = "Controls how the base damage for ignite is calculated:\nAverage Damage: Ignite is based on the average damage dealt, factoring in crits and non-crits.\nCrit Damage: Ignite is based on crit damage only.", list = {{val="AVERAGE",label="Average Damage"},{val="CRIT",label="Crit Damage"}} },

	-- Section: Skill-specific options
	{ section = "Skill Options", col = 2 },
	{ label = "Charged Dash:", ifSkill = "Charged Dash" },
	{ var = "chargedDashTravelDistance", type = "number", label = "Travel distance:", ifSkill = "Charged Dash", tooltip = "Sets the travel distance used to calculate the distance damage bonus.\nThe maximum distance is 60 units.", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ChargedDashDistance", "BASE", m_max(0, m_min(val, 60)) / 60, "Config")
	end },
	{ label = "Dark Pact:", ifSkill = "Dark Pact" },
	{ var = "darkPactSkeletonLife", type = "number", label = "Skeleton Life:", ifSkill = "Dark Pact", tooltip = "Sets the maximum life of the skeleton that is being targeted.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "skeletonLife", value = val }, "Config", { type = "SkillName", skillName = "Dark Pact" })
	end },
	{ label = "Ice Nova:", ifSkill = "Ice Nova" },
	{ var = "iceNovaCastOnFrostbolt", type = "check", label = "Cast on Frostbolt?", ifSkill = "Ice Nova", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastOnFrostbolt", "FLAG", true, "Config", { type = "SkillName", skillName = "Ice Nova" })
	end },
	{ label = "Innervate", ifSkill = "Innervate" },
	{ var = "innervateInnervation", type = "check", label = "Is Innervation active?", ifSkill = "Innervate", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Innervation", "FLAG", true, "Config")
	end },
	{ label = "Raise Spectre:", ifSkill = "Raise Spectre" },
	{ var = "raiseSpectreSpectreLevel", type = "number", label = "Spectre Level:", ifSkill = "Raise Spectre", tooltip = "Sets the level of the raised spectre.\nThe default level is the level requirement of the Raise Spectre skill.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "minionLevel", value = val }, "Config", { type = "SkillName", skillName = "Raise Spectre" })
	end },
	{ var = "raiseSpectreEnableCurses", type = "check", label = "Enable curses:", ifSkill = "Raise Spectre", tooltip = "Enable any curse skills that your spectres have.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillType", skillType = SkillType.Curse }, { type = "SkillName", skillName = "Raise Spectre", summonSkill = true })
	end },
	{ var = "raiseSpectreBladeVortexBladeCount", type = "number", label = "Blade Vortex blade count:", ifSkillList = {"DemonModularBladeVortexSpectre","GhostPirateBladeVortexSpectre"}, tooltip = "Sets the blade count for Blade Vortex skills used by spectres.\nDefault is 1; maximum is 5.", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "dpsMultiplier", value = val }, "Config", { type = "SkillId", skillId = "DemonModularBladeVortexSpectre" })
		modList:NewMod("SkillData", "LIST", { key = "dpsMultiplier", value = val }, "Config", { type = "SkillId", skillId = "GhostPirateBladeVortexSpectre" })
	end },
	{ label = "Summon Lightning Golem:", ifSkill = "Summon Lightning Golem" },
	{ var = "summonLightningGolemEnableWrath", type = "check", label = "Enable Wrath Aura:", ifSkill = "Summon Lightning Golem", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "enable", value = true }, "Config", { type = "SkillId", skillId = "LightningGolemWrath" })
	end },
	{ label = "Vortex:", ifSkill = "Vortex" },
	{ var = "vortexCastOnFrostbolt", type = "check", label = "Cast on Frostbolt?", ifSkill = "Vortex", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastOnFrostbolt", "FLAG", true, "Config", { type = "SkillName", skillName = "Vortex" })
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
	{ var = "playerHasMinusMaxResist", type = "number", label = "-X% maximum Resistances:", tooltip = "'of Exposure'\nMid tier: 5-8%\nHigh tier: 9-12%", apply = function(val, modList, enemyModList)
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
	{ var = "playerHasLessArmourandBlock", type = "list", label = "Reduced Block Chance/less Armour:", tooltip = "'of Rust'", list = {{val=0,label="None"},{val="LOW",label="20%/20% (Low tier)"},{val="MID",label="30%/25% (Mid tier)"},{val="HIGH",label="40%/30% (High tier)"}}, apply = function(val, modList, enemyModList)
		local map = { ["LOW"] = {20,20}, ["MID"] = {30,25}, ["HIGH"] = {40,30} }
		if map[val] then
			modList:NewMod("BlockChance", "INC", -map[val][1], "Config")
			modList:NewMod("Armour", "MORE", -map[val][2], "Config")
		end
	end },
	{ var = "playerHasPointBlank", type = "check", label = "Player has Point Blank?", tooltip = "'of Skirmishing'", apply = function(val, modList, enemyModList)
		modList:NewMod("Keystone", "LIST", "Point Blank", "Config")
	end },
	{ var = "playerHasLessLifeESRecovery", type = "list", label = "Less Recovery of Life and Energy Shield:", tooltip = "'of Smothering'", list = {{val=0,label="None"},{val=20,label="20% (Low tier)"},{val=40,label="40% (Mid tier)"},{val=60,label="60% (High tier)"}}, apply = function(val, modList, enemyModList)
		if val ~= 0 then
			modList:NewMod("LifeRecovery", "MORE", -val, "Config")
			modList:NewMod("EnergyShieldRecovery", "MORE", -val, "Config")
		end
	end },
	{ var = "playerCannotRegenLifeManaEnergyShield", type = "check", label = "Cannot Regen Life, Mana or ES?", tooltip = "'of Stasis'", apply = function(val, modList, enemyModList)
		modList:NewMod("NoLifeRegen", "FLAG", true, "Config")
		modList:NewMod("NoEnergyShieldRegen", "FLAG", true, "Config")
		modList:NewMod("NoManaRegen", "FLAG", true, "Config")
	end },
	{ var = "enemyTakesReducedExtraCritDamage", type = "number", label = "Enemy takes red. Extra Crit Damage:", tooltip = "'of Toughness'\nLow tier: 25-30%\nMid tier: 31-35%\nHigh tier: 36-40%" , apply = function(val, modList, enemyModList)
		if val ~= 0 then
			enemyModList:NewMod("SelfCritMultiplier", "INC", -val, "Config")
		end
	end },
	{ label = "Player is cursed by:" },
	{ var = "playerCursedWithAssassinsMark", type = "number", label = "Assassin's Mark:", tooltip = "Sets the level of Assassin's Mark to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Assassin's Mark", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithConductivity", type = "number", label = "Conductivity:", tooltip = "Sets the level of Conductivity to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Conductivity", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithElementalWeakness", type = "number", label = "Elemental Weakness:", tooltip = "Sets the level of Elemental Weakness to apply to the player.\nIn mid tier maps, 'of Elemental Weakness' applies level 10.\nIn high tier maps, 'of Elemental Weakness' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Elemental Weakness", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithEnfeeble", type = "number", label = "Enfeeble:", tooltip = "Sets the level of Enfeeble to apply to the player.\nIn mid tier maps, 'of Enfeeblement' applies level 10.\nIn high tier maps, 'of Enfeeblement' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Enfeeble", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithFlammability", type = "number", label = "Flammability:", tooltip = "Sets the level of Flammability to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Flammability", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithFrostbite", type = "number", label = "Frostbite:", tooltip = "Sets the level of Frostbite to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Frostbite", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithPoachersMark", type = "number", label = "Poacher's Mark:", tooltip = "Sets the level of Poacher's Mark to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Poacher's Mark", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithProjectileWeakness", type = "number", label = "Projectile Weakness:", tooltip = "Sets the level of Projectile Weakness to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Projectile Weakness", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithPunishment", type = "number", label = "Punishment:", tooltip = "Sets the level of Punishment to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Punishment", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithTemporalChains", type = "number", label = "Temporal Chains:", tooltip = "Sets the level of Temporal Chains to apply to the player.\nIn mid tier maps, 'of Temporal Chains' applies level 10.\nIn high tier maps, 'of Temporal Chains' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Temporal Chains", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithVulnerability", type = "number", label = "Vulnerability:", tooltip = "Sets the level of Vulnerability to apply to the player.\nIn mid tier maps, 'of Vulnerability' applies level 10.\nIn high tier maps, 'of Vulnerability' applies level 15.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Vulnerability", level = val, applyToPlayer = true })
	end },
	{ var = "playerCursedWithWarlordsMark", type = "number", label = "Warlord's Mark:", tooltip = "Sets the level of Warlord's Mark to apply to the player.", apply = function(val, modList, enemyModList)
		modList:NewMod("ExtraCurse", "LIST", { name = "Warlord's Mark", level = val, applyToPlayer = true })
	end },

	-- Section: Combat options
	{ section = "When In Combat", col = 1 },
	{ var = "usePowerCharges", type = "check", label = "Do you use Power Charges?", apply = function(val, modList, enemyModList)
		modList:NewMod("UsePowerCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useFrenzyCharges", type = "check", label = "Do you use Frenzy Charges?", apply = function(val, modList, enemyModList)
		modList:NewMod("UseFrenzyCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "useEnduranceCharges", type = "check", label = "Do you use Endurance Charges?", apply = function(val, modList, enemyModList)
		modList:NewMod("UseEnduranceCharges", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
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
	{ var = "conditionLeeching", type = "check", label = "Are you Leeching?", ifCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Leeching", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsingFlask", type = "check", label = "Do you have a Flask active?", ifCond = "UsingFlask", tooltip = "This is automatically enabled if you have a flask active,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsingFlask", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHaveTotem", type = "check", label = "Do you have a Totem summoned?", ifCond = "HaveTotem", tooltip = "You will automatically be considered to have a Totem if your main skill is a Totem,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HaveTotem", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnConsecratedGround", type = "check", label = "Are you on Consecrated Ground?", tooltip = "In addition to allowing any 'while on Consecrated Ground' modifiers to apply,\nthis will apply the 6% life regen modifier granted by Consecrated Ground.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnConsecratedGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnBurningGround", type = "check", label = "Are you on Burning Ground?", ifCond = "OnBurningGround", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnBurningGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnChilledGround", type = "check", label = "Are you on Chilled Ground?", ifCond = "OnChilledGround", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnChilledGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnShockedGround", type = "check", label = "Are you on Shocked Ground?", ifCond = "OnShockedGround", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:OnShockedGround", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnited", type = "check", label = "Are you Ignited?", ifCond = "Ignited", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Ignited", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFrozen", type = "check", label = "Are you Frozen?", ifCond = "Frozen", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Frozen", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShocked", type = "check", label = "Are you Shocked?", ifCond = "Shocked", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBleeding", type = "check", label = "Are you Bleeding?", ifCond = "Bleeding", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionPoisoned", type = "check", label = "Are you Poisoned?", ifCond = "Poisoned", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:Poisoned", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierPoisonOnSelf", type = "number", label = "# of Poison on You:", ifMult = "PoisonOnSelf", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PoisonOnSelf", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionHitRecently", type = "check", label = "Have you Hit Recently?", ifCond = "HitRecently", tooltip = "You will automatically be considered to have Hit Recently if your main skill is self-cast,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCritRecently", type = "check", label = "Have you Crit Recently?", ifCond = "CritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionNonCritRecently", type = "check", label = "Have you dealt a Non-Crit Recently?", ifCond = "NonCritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:NonCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledRecently", type = "check", label = "Have you Killed Recently?", ifCond = "KilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsKilledRecently", type = "check", label = "Have your Totems Killed Recently?", ifCond = "TotemsKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TotemsKilledRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledAffectedByDoT", type = "check", label = "Killed Enemy affected by your DoT Recently?", ifCond = "KilledAffectedByDotRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:KilledAffectedByDotRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "multiplierShockedEnemyKilledRecently", type = "number", label = "# of Shocked Enemies Killed Recently:", ifMult = "ShockedEnemyKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:ShockedEnemyKilledRecently", "BASE", val, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFrozenEnemyRecently", type = "check", label = "Have you Frozen an Enemy Recently?", ifCond = "FrozenEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FrozenEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnitedEnemyRecently", type = "check", label = "Have you Ignited an Enemy Recently?", ifCond = "IgnitedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:IgnitedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShockedEnemyRecently", type = "check", label = "Have you Shocked an Enemy Recently?", ifCond = "ShockedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ShockedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenHitRecently", type = "check", label = "Have you been Hit Recently?", ifCond = "BeenHitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenCritRecently", type = "check", label = "Have you been Crit Recently?", ifCond = "BeenCritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenCritRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenSavageHitRecently", type = "check", label = "Have you been Savage Hit Recently?", ifCond = "BeenSavageHitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BeenSavageHitRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByFireDamageRecently", type = "check", label = "Have you been hit by Fire Recently?", ifCond = "HitByFireDamageRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByFireDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByColdDamageRecently", type = "check", label = "Have you been hit by Cold Recently?", ifCond = "HitByColdDamageRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByColdDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByLightningDamageRecently", type = "check", label = "Have you been hit by Light. Recently?", ifCond = "HitByLightningDamageRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:HitByLightningDamageRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedAttackRecently", type = "check", label = "Have you Blocked an Attack Recently?", ifCond = "BlockedAttackRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedAttackRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedSpellRecently", type = "check", label = "Have you Blocked a Spell Recently?", ifCond = "BlockedSpellRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedSpellRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffPendulum", type = "check", label = "Is Pendulum of Destruction active?", ifNode = 57197, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:PendulumOfDestruction", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
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
		modList:NewMod("Condition:BastionOfHope", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffHerEmbrace", type = "check", label = "Are you in Her Embrace?", ifCond = "HerEmbrace", tooltip = "This option is specific to Oni-Goroshi.", apply = function(val, modList, enemyModList)
		modList:NewMod("HerEmbrace", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionAttackedRecently", type = "check", label = "Have you Attacked Recently?", ifNode = 3154, tooltip = "You will automatically be considered to have Attacked Recently if your main skill is an attack,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AttackedRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCastSpellRecently", type = "check", label = "Have you Cast a Spell Recently?", ifNode = 3154, tooltip = "You will automatically be considered to have Cast a Spell Recently if your main skill is a spell,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastSpellRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedWarcryRecently", type = "check", label = "Have you used a Warcry Recently?", ifCond = "UsedWarcryRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedWarcryRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConsumedCorpseRecently", type = "check", label = "Consumed a corpse Recently?", ifCond = "ConsumedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:ConsumedCorpseRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTauntedEnemyRecently", type = "check", label = "Taunted an Enemy Recently?", ifCond = "TauntedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:TauntedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedFireSkillRecently", type = "check", label = "Have you used a Fire Skill Recently?", ifCond = "UsedFireSkillRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedFireSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedColdSkillRecently", type = "check", label = "Have you used a Cold Skill Recently?", ifCond = "UsedColdSkillRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedColdSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedMinionSkillRecently", type = "check", label = "Have you used a Minion Skill Recently?", ifCond = "UsedMinionSkillRecently", tooltip = "You will automatically be considered to have used a Minion skill Recently if your main skill is a minion skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedMinionSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedMovementSkillRecently", type = "check", label = "Have you used a Movement Skill Recently?", ifCond = "UsedMovementSkillRecently", tooltip = "You will automatically be considered to have used a Movement skill Recently if your main skill is a movement skill,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedMovementSkillRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedFireSkillInPast10Sec", type = "check", label = "Have you used a Fire Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedFireSkillInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedColdSkillInPast10Sec", type = "check", label = "Have you used a Cold Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedColdSkillInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedLightningSkillInPast10Sec", type = "check", label = "Have you used a Light. Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedLightningSkillInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedHitFromUniqueEnemyRecently", type = "check", label = "Blocked hit from a Unique Recently?", ifNode = 63490, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedHitFromUniqueEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },

	-- Section: Effective DPS options
	{ section = "For Effective DPS", col = 1 },
	{ var = "critChanceLucky", type = "check", label = "Is your Crit Chance Lucky?", apply = function(val, modList, enemyModList)
		modList:NewMod("CritChanceLucky", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "projectileDistance", type = "number", label = "Projectile travel distance:", ifFlag = "projectile" },
	{ var = "conditionEnemyMoving", type = "check", label = "Is the enemy Moving?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Moving", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFullLife", type = "check", label = "Is the enemy on Full Life?", ifEnemyCond = "FullLife", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:FullLife", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyLowLife", type = "check", label = "Is the enemy on Low Life?", ifEnemyCond = "LowLife", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:LowLife", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionAtCloseRange", type = "check", label = "Is the enemy at Close Range?", ifCond = "AtCloseRange", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:AtCloseRange", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
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
	{ var = "multiplierPoisonOnEnemy", type = "number", label = "# of Poison on Enemy:", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PoisonOnEnemy", "BASE", val, "Config", { type = "Condition", var = "Effective" })
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
	{ var = "conditionEnemyIgnited", type = "check", label = "Is the enemy Ignited?", ifEnemyCond = "Ignited", tooltip = "This also implies that the enemy is Burning.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Ignited", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyChilled", type = "check", label = "Is the enemy Chilled?", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFrozen", type = "check", label = "Is the enemy Frozen?", ifEnemyCond = "Frozen", tooltip = "This also implies that the enemy is Chilled.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Frozen", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyShocked", type = "check", label = "Is the enemy Shocked?", tooltip = "In addition to allowing any 'against Shocked Enemies' modifiers to apply,\nthis will apply Shock's Damage Taken modifier to the enemy.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Shocked", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierFreezeShockIgniteOnEnemy", type = "number", label = "# of Freeze/Shock/Ignite on Enemy:", ifMult = "FreezeShockIgniteOnEnemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:FreezeShockIgniteOnEnemy", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyIntimidated", type = "check", label = "Is the enemy Intimidated?", tooltip = "This adds the following modifiers:\n10% increased Damage Taken by enemy", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("DamageTaken", "INC", 10, "Intimidate")
	end },
	{ var = "conditionEnemyCoveredInAsh", type = "check", label = "Is the enemy covered in Ash?", tooltip = "This adds the following modifiers:\n20% less enemy Movement Speed\n20% increased Fire Damage Taken by enemy", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireDamageTaken", "INC", 20, "Ash")
	end },
	{ var = "conditionEnemyRareOrUnique", type = "check", label = "is the enemy Rare or Unique?", ifCond = "EnemyRareOrUnique", tooltip = "Your enemy will automatically be considered to be Unique if one of the Boss options is selected.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:EnemyRareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "enemyIsBoss", type = "list", ifVer = "2_6", label = "Is the enemy a Boss?", tooltip = "Standard Boss adds the following modifiers:\n60% less Effect of your Curses\n+30% to enemy Elemental Resistances\n+15% to enemy Chaos Resistance\n\nShaper/Guardian adds the following modifiers:\n80% less Effect of your Curses\n+40% to enemy Elemental Resistances\n+25% to enemy Chaos Resistance\n50% less Duration of Bleed\n50% less Duration of Poison\n50% less Duration of Ignite", list = {{val="NONE",label="No"},{val=true,label="Standard Boss"},{val="SHAPER",label="Shaper/Guardian"}}, apply = function(val, modList, enemyModList)
		if val == true then
			modList:NewMod("Condition:EnemyRareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -60, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 30, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 15, "Boss")
		elseif val == "SHAPER" then
			modList:NewMod("Condition:EnemyRareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -80, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 40, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 25, "Boss")
			enemyModList:NewMod("SelfBleedDuration", "MORE", -50, "Boss")
			enemyModList:NewMod("SelfPoisonDuration", "MORE", -50, "Boss")
			enemyModList:NewMod("SelfIgniteDuration", "MORE", -50, "Boss")
		end
	end },
	{ var = "enemyIsBoss", type = "list", ifVer = "3_0", label = "Is the enemy a Boss?", tooltip = "Standard Boss adds the following modifiers:\n60% less Effect of your Curses\n+30% to enemy Elemental Resistances\n+15% to enemy Chaos Resistance\n\nShaper/Guardian adds the following modifiers:\n80% less Effect of your Curses\n+40% to enemy Elemental Resistances\n+25% to enemy Chaos Resistance", list = {{val="NONE",label="No"},{val=true,label="Standard Boss"},{val="SHAPER",label="Shaper/Guardian"}}, apply = function(val, modList, enemyModList)
		if val == true then
			modList:NewMod("Condition:EnemyRareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -60, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 30, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 15, "Boss")
		elseif val == "SHAPER" then
			modList:NewMod("Condition:EnemyRareOrUnique", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -80, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 40, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 25, "Boss")
		end
	end },
	{ var = "enemyPhysicalReduction", type = "number", label = "Enemy Phys. Damage Reduction:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("PhysicalDamageReduction", "BASE", val, "Config")
	end },
	{ var = "enemyFireResist", type = "number", label = "Enemy Fire Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireResist", "BASE", val, "Config")
	end },
	{ var = "enemyColdResist", type = "number", label = "Enemy Cold Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ColdResist", "BASE", val, "Config")
	end },
	{ var = "enemyLightningResist", type = "number", label = "Enemy Lightning Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("LightningResist", "BASE", val, "Config")
	end },
	{ var = "enemyChaosResist", type = "number", label = "Enemy Chaos Resistance:", apply = function(val, modList, enemyModList)
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