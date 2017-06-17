-- Path of Building
--
-- Module: Config Tab
-- Configuration tab for the current build.
--
local launch, main = ...

local t_insert = table.insert
local m_max = math.max
local m_floor = math.floor

local gameVersionDropList = {
	{ label = "2.6 (Atlas of Worlds)", version = "2_6", versionPretty = "2.6" },
	{ label = "3.0 (Fall of Oriath)", version = "3_0", versionPretty = "3.0" },
}

local varList = {
	{ section = "General", col = 1 },
	{ var = "enemyLevel", type = "number", label = "Enemy Level:", tooltip = "This overrides the default enemy level used to estimate your hit and evade chances.\nThe default level is your character level, capped at 84, which is the same value\nused in-game to calculate the stats on the character sheet." },
	{ var = "enemyPhysicalHit", type = "number", label = "Enemy Physical Hit Damage:", tooltip = "This overrides the default damage amount used to estimate your physical damage reduction from armour.\nThe default is 1.5 times the enemy's base damage, which is the same value\nused in-game to calculate the estimate shown on the character sheet." },
	{ var = "conditionLowLife", type = "check", label = "Are you always on Low Life?", ifCond = "LowLife", tooltip = "You will automatically be considered to be on Low Life if you have at least 65% life reserved,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:LowLife", "FLAG", true, "Config")
	end },
	{ var = "conditionFullLife", type = "check", label = "Are you always on Full Life?", ifCond = "FullLife", tooltip = "You will automatically be considered to be on Full Life if you have Chaos Innoculation,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullLife", "FLAG", true, "Config")
	end },
	{ var = "conditionFullEnergyShield", type = "check", label = "Are you always on Full Energy Shield?", ifCond = "FullEnergyShield", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FullEnergyShield", "FLAG", true, "Config")
	end },
	{ var = "igniteMode", type = "list", label = "Ignite calculation mode:", tooltip = "Controls how the base damage for ignite is calculated:\nAverage Damage: Ignite is based on the average damage dealt, factoring in crits and non-crits.\nCrit Damage: Ignite is based on crit damage only.", list = {{val="AVERAGE",label="Average Damage"},{val="CRIT",label="Crit Damage"}} },
	{ section = "Skill Options", col = 2 },
	{ label = "Detonate Dead", ifSkill = "Detonate Dead" },
	{ var = "detonateDeadCorpseLife", type = "number", label = "Corpse Life:", ifSkillList = { "Detonate Dead", "Vaal Detonate Dead" }, tooltip = "Sets the maximum life of the corpse that is being detonated.\nFor reference, a level 70 monster has "..data.monsterLifeTable[70].." base life, and a level 80 monster has "..data.monsterLifeTable[80]..".", apply = function(val, modList, enemyModList)
		modList:NewMod("SkillData", "LIST", { key = "corpseLife", value = val }, "Config", { type = "SkillName", skillName = "Detonate Dead" })
	end },
	{ label = "Ice Nova", ifSkill = "Ice Nova" },
	{ var = "iceNovaCastOnFrostbolt", type = "check", label = "Cast on Frostbolt?", ifSkill = "Ice Nova", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastOnFrostbolt", "FLAG", true, "Config", { type = "SkillName", skillName = "Ice Nova" })
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
	{ label = "Vortex", ifSkill = "Vortex" },
	{ var = "vortexCastOnFrostbolt", type = "check", label = "Cast on Frostbolt?", ifSkill = "Vortex", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:CastOnFrostbolt", "FLAG", true, "Config", { type = "SkillName", skillName = "Vortex" })
	end },
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
	{ var = "conditionOnConsecratedGround", type = "check", label = "Are you on Consecrated Ground?", tooltip = "In addition to allowing any 'while on Consecrated Ground' modifiers to apply,\nthis will apply the 4% life regen modifier granted by Consecrated Ground.", apply = function(val, modList, enemyModList)
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
	{ var = "conditionFrozenEnemyRecently", type = "check", label = "Have you Frozen an Enemy Recently?", ifCond = "FrozenEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:FrozenEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnitedEnemyRecently", type = "check", label = "Have you Ignited an Enemy Recently?", ifCond = "IgnitedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:IgnitedEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
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
	{ var = "conditionUsedFireSkillInPast10Sec", type = "check", label = "Used a Fire Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedFireSkillInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedColdSkillInPast10Sec", type = "check", label = "Used a Cold Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedColdSkillInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedLightningSkillInPast10Sec", type = "check", label = "Used a Light. Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:UsedLightningSkillInPast10Sec", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedHitFromUniqueEnemyRecently", type = "check", label = "Blocked hit from a Unique Recently?", ifNode = 63490, apply = function(val, modList, enemyModList)
		modList:NewMod("Condition:BlockedHitFromUniqueEnemyRecently", "FLAG", true, "Config", { type = "Condition", var = "Combat" })
	end },
	{ section = "For Effective DPS", col = 1 },
	{ var = "critChanceLucky", type = "check", label = "Is your Crit Chance Lucky?", apply = function(val, modList, enemyModList)
		modList:NewMod("CritChanceLucky", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "projectileDistance", type = "number", label = "Projectile travel distance:", ifFlag = "projectile" },
	{ var = "conditionEnemyMoving", type = "check", label = "Is the enemy Moving?", ifFlag = "bleed", apply = function(val, modList, enemyModList, build)
		if build.targetVersion == "2_6" then
			modList:NewMod("Damage", "MORE", 500, "Movement", 0, KeywordFlag.Bleed)
		else
			modList:NewMod("Damage", "MORE", 100, "Movement", 0, KeywordFlag.Bleed)
		end
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
	{ var = "conditionEnemyBleeding", type = "check", label = "Is the enemy Bleeding?", ifEnemyCond = "Bleeding", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Bleeding", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyPoisoned", type = "check", label = "Is the enemy Poisoned?", ifEnemyCond = "Poisoned", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Poisoned", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "multiplierPoisonOnEnemy", type = "number", label = "# of Poison on Enemy:", ifMult = "PoisonOnEnemy", apply = function(val, modList, enemyModList)
		modList:NewMod("Multiplier:PoisonOnEnemy", "BASE", val, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyMaimed", type = "check", label = "Is the enemy Maimed?", ifEnemyCond = "Maimed", apply = function(val, modList, enemyModList)
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
	{ var = "conditionEnemyBurning", type = "check", label = "Is the enemy Burning?", ifEnemyCond = "Burning", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Burning", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyIgnited", type = "check", label = "Is the enemy Ignited?", ifEnemyCond = "Ignited", tooltip = "This also implies that the enemy is Burning.", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Ignited", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyChilled", type = "check", label = "Is the enemy Chilled?", ifEnemyCond = "Chilled", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("Condition:Chilled", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFrozen", type = "check", label = "Is the enemy Frozen?", ifEnemyCond = "Frozen", apply = function(val, modList, enemyModList)
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
	{ var = "enemyIsBoss", type = "list", label = "Is the enemy a Boss?", tooltip = "Standard Boss adds the following modifiers:\n60% less Effect of your Curses\n+30% to enemy Elemental Resistances\n+15% to enemy Chaos Resistance\n\nShaper/Guardian adds the following modifiers:\n80% less Effect of your Curses\n+40% to enemy Elemental Resistances\n+25% to enemy Chaos Resistance\n50% less Duration of Bleed\n50% less Duration of Poison\n50% less Duration of Ignite", list = {{val="NONE",label="No"},{val=true,label="Standard Boss"},{val="SHAPER",label="Shaper/Guardian"}}, apply = function(val, modList, enemyModList)
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

local ConfigTabClass = common.NewClass("ConfigTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build

	self.input = { }

	self.sectionList = { }
	self.varControls = { }

	self:BuildModList()

	local lastSection
	for _, varData in ipairs(varList) do
		if varData.section then
			lastSection = common.New("SectionControl", {"TOPLEFT",self,"TOPLEFT"}, 0, 0, 360, 0, varData.section)
			lastSection.varControlList = { }
			lastSection.col = varData.col
			lastSection.height = function(self)
				local height = 20
				for _, varControl in pairs(self.varControlList) do
					if varControl:IsShown() then
						height = height + 20
					end
				end
				return m_max(height, 32)
			end
			t_insert(self.sectionList, lastSection)
			t_insert(self.controls, lastSection)
		else
			local control
			if varData.type == "check" then
				control = common.New("CheckBoxControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 18, nil, function(state)
					self.input[varData.var] = state
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end) 
			elseif varData.type == "number" then
				control = common.New("EditControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 90, 18, "", nil, "^%-%d", 6, function(buf)
					self.input[varData.var] = tonumber(buf)
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end) 
			elseif varData.type == "list" then
				control = common.New("DropDownControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 118, 16, varData.list, function(index, value)
					self.input[varData.var] = value.val
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			else 
				control = common.New("Control", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 16, 16)
			end
			if varData.ifNode then
				control.shown = function()
					return self.build.spec.allocNodes[varData.ifNode]
				end
				control.tooltip = function()
					return "This option is specific to '"..self.build.spec.nodes[varData.ifNode].dn.."'."..(varData.tooltip and "\n"..varData.tooltip or "")
				end
			elseif varData.ifCond or varData.ifEnemyCond then
				control.shown = function()
					if varData.ifCond then
						return self.build.calcsTab.mainEnv.conditionsUsed[varData.ifCond]
					else
						return self.build.calcsTab.mainEnv.enemyConditionsUsed[varData.ifEnemyCond]
					end
				end
				control.tooltip = function()
					if launch.devMode and IsKeyDown("ALT") then
						local out = varData.tooltip or ""
						local list
						if varData.ifCond then
							list = self.build.calcsTab.mainEnv.conditionsUsed[varData.ifCond]
						else
							list = self.build.calcsTab.mainEnv.enemyConditionsUsed[varData.ifEnemyCond]
						end
						for _, mod in ipairs(list) do
							out = (#out > 0 and out.."\n" or out) .. modLib.formatMod(mod) .. "|" .. mod.source
						end
						return out
					else
						return varData.tooltip
					end
				end
			elseif varData.ifMult then
				control.shown = function()
					return self.build.calcsTab.mainEnv.multipliersUsed[varData.ifMult]
				end
				control.tooltip = function()
					if launch.devMode and IsKeyDown("ALT") then
						local out = varData.tooltip or ""
						for _, mod in ipairs(self.build.calcsTab.mainEnv.multipliersUsed[varData.ifMult]) do
							out = (#out > 0 and out.."\n" or out) .. modLib.formatMod(mod) .. "|" .. mod.source
						end
						return out
					else
						return varData.tooltip
					end
				end
			elseif varData.ifFlag then
				control.shown = function()
					return self.build.calcsTab.mainEnv.player.mainSkill.skillFlags[varData.ifFlag] -- O_O
				end
				control.tooltip = varData.tooltip
			elseif varData.ifSkill or varData.ifSkillList then
				control.shown = function()
					if varData.ifSkillList then
						for _, skillName in ipairs(varData.ifSkillList) do
							if self.build.calcsTab.mainEnv.skillsUsed[skillName] then
								return true
							end
						end
					else
						return self.build.calcsTab.mainEnv.skillsUsed[varData.ifSkill]
					end
				end
				control.tooltip = varData.tooltip
			else
				control.tooltip = varData.tooltip
			end
			t_insert(self.controls, common.New("LabelControl", {"RIGHT",control,"LEFT"}, -4, 0, 0, DrawStringWidth(14, "VAR", varData.label) > 228 and 12 or 14, "^7"..varData.label))
			if varData.var then
				self.varControls[varData.var] = control
			end
			t_insert(self.controls, control)
			t_insert(lastSection.varControlList, control)
		end
	end

	-- Special control for game version selector
	self.controls.gameVersion = common.New("DropDownControl", {"TOPLEFT",self.sectionList[1],"TOPLEFT"}, 234, 0, 118, 16, gameVersionDropList, function(index, value)
		if value.version ~= build.targetVersion then
			main:OpenConfirmPopup("Convert Build", colorCodes.WARNING.."Warning:^7 Converting a build to a different game version may have side effects.\nFor example, if the passive tree has changed, then some passives may be deallocated.\nYou should create a backup copy of the build before proceeding.", "Convert to "..value.versionPretty, function()
				if build.unsaved then
					build:OpenSavePopup("VERSION", value.version)
				else
					if build.dbFileName then
						build.targetVersion = value.version
						build:SaveDBFile()
					end
					build:Shutdown()
					build:Init(build.dbFileName, build.buildName, nil, value.version)
				end
			end)
		end
	end)
	t_insert(self.controls, common.New("LabelControl", {"RIGHT",self.controls.gameVersion,"LEFT"}, -4, 0, 0, 14, "^7Game Version:"))
	t_insert(self.sectionList[1].varControlList, 1, self.controls.gameVersion)

	self.controls.scrollBar = common.New("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, 0, 0, 18, 0, 50, "VERTICAL", true)
end)

function ConfigTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if node.elem == "Input" then
			if not node.attrib.name then
				launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing name attribute", fileName)
				return true
			end
			if node.attrib.number then
				self.input[node.attrib.name] = tonumber(node.attrib.number)
			elseif node.attrib.string then
				self.input[node.attrib.name] = node.attrib.string
			elseif node.attrib.boolean then
				self.input[node.attrib.name] = node.attrib.boolean == "true"
			else
				launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing number, string or boolean attribute", fileName)
				return true
			end
		end
	end
	self:BuildModList()
	self:UpdateControls()
	self:ResetUndo()
end

function ConfigTabClass:Save(xml)
	for k, v in pairs(self.input) do
		if v then
			local child = { elem = "Input", attrib = {name = k} }
			if type(v) == "number" then
				child.attrib.number = tostring(v)
			elseif type(v) == "boolean" then
				child.attrib.boolean = tostring(v)
			else
				child.attrib.string = tostring(v)
			end
			t_insert(xml, child)
		end
	end
	self.modFlag = false
end

function ConfigTabClass:UpdateControls()
	for var, control in pairs(self.varControls) do
		if control._className == "EditControl" then
			control:SetText(tostring(self.input[var] or ""))
		elseif control._className == "CheckBoxControl" then
			control.state = self.input[var]
		elseif control._className == "DropDownControl" then
			control:SelByValue(self.input[var], "val")
		end
	end
end

function ConfigTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	if not main.popups[1] then
		-- >_>
		self.controls.gameVersion:SelByValue(self.build.targetVersion, "version")
	end

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
				self.build.buildFlag = true
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
				self.build.buildFlag = true
			end
		end
	end

	self:ProcessControlsInput(inputEvents, viewPort)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyUp" then
			if event.key == "WHEELDOWN" then
				self.controls.scrollBar:Scroll(1)
			elseif event.key == "WHEELUP" then
				self.controls.scrollBar:Scroll(-1)
			end
		end
	end

	local maxCol = m_floor((viewPort.width - 10) / 370)
	local maxColY = 0
	local colY = { }
	for _, section in ipairs(self.sectionList) do
		local y = 14
		section.shown = true
		local doShow = false
		for _, varControl in ipairs(section.varControlList) do
			if varControl:IsShown() then
				doShow = true
				local width, height = varControl:GetSize()
				varControl.y = y + (18 - height) / 2
				y = y + 20
			end
		end
		section.shown = doShow
		if doShow then
			local width, height = section:GetSize()
			local col
			if section.col and (colY[section.col] or 0) + height + 28 <= viewPort.height then
				col = section.col
			else
				col = 1
				for c = 2, maxCol do
					colY[c] = colY[c] or 0
					if colY[c] < colY[col] then
						col = c
					end
				end
			end
			colY[col] = colY[col] or 0
			section.x = 10 + (col - 1) * 370
			section.y = colY[col] + 18
			colY[col] = colY[col] + height + 18
			maxColY = m_max(maxColY, colY[col])
		end
	end

	self.controls.scrollBar.height = viewPort.height
	self.controls.scrollBar:SetContentDimension(maxColY + 10, viewPort.height)
	for _, section in ipairs(self.sectionList) do
		section.y = section.y - self.controls.scrollBar.offset
	end

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)
end

function ConfigTabClass:BuildModList()
	local modList = common.New("ModList")
	self.modList = modList
	local enemyModList = common.New("ModList")
	self.enemyModList = enemyModList
	local input = self.input
	for _, varData in ipairs(varList) do
		if varData.apply then
			if varData.type == "check" then
				if input[varData.var] then
					varData.apply(true, modList, enemyModList, self.build)
				end
			elseif varData.type == "number" then
				if input[varData.var] and input[varData.var] ~= 0 then
					varData.apply(input[varData.var], modList, enemyModList, self.build)
				end
			elseif varData.type == "list" then
				if input[varData.var] then
					varData.apply(input[varData.var], modList, enemyModList, self.build)
				end
			end
		end
	end
end

function ConfigTabClass:ImportCalcSettings()
	local input = self.input
	local calcsInput = self.build.calcsTab.input
	local function import(old, new)
		input[new] = calcsInput[old]
		calcsInput[old] = nil
	end
	import("Cond_LowLife", "conditionLowLife")
	import("Cond_FullLife", "conditionFullLife")
	import("buff_power", "usePowerCharges")
	import("buff_frenzy", "useFrenzyCharges")
	import("buff_endurance", "useEnduranceCharges")
	import("CondBuff_Onslaught", "buffOnslaught")
	import("CondBuff_Phasing", "buffPhasing")
	import("CondBuff_Fortify", "buffFortify")
	import("CondBuff_UsingFlask", "conditionUsingFlask")
	import("buff_pendulum", "usePendulum")
	import("CondEff_EnemyCursed", "conditionEnemyCursed")
	import("CondEff_EnemyBleeding", "conditionEnemyBleeding")
	import("CondEff_EnemyPoisoned", "conditionEnemyPoisoned")
	import("CondEff_EnemyBurning", "conditionEnemyBurning")
	import("CondEff_EnemyIgnited", "conditionEnemyIgnited")
	import("CondEff_EnemyChilled", "conditionEnemyChilled")
	import("CondEff_EnemyFrozen", "conditionEnemyFrozen")
	import("CondEff_EnemyShocked", "conditionEnemyShocked")
	import("effective_physicalRed", "enemyPhysicalReduction")
	import("effective_fireResist", "enemyFireResist")
	import("effective_coldResist", "enemyColdResist")
	import("effective_lightningResist", "enemyLightningResist")
	import("effective_chaosResist", "enemyChaosResist")
	import("effective_enemyIsBoss", "enemyIsBoss")
	self:BuildModList()
	self:UpdateControls()
end

function ConfigTabClass:CreateUndoState()
	return copyTable(self.input)
end

function ConfigTabClass:RestoreUndoState(state)
	wipeTable(self.input)
	for k, v in pairs(state) do
		self.input[k] = v
	end
	self:UpdateControls()
	self:BuildModList()
end
