-- This is currently made by hand but should be auto generated
-- Item data (c) Grinding Gear Games

return {
	Prefix = {
		{ val = "NONE", label = "None" },
		{ val = "enemyHasPhysicalReduction", label = "Enemy Physical Damage reduction:" },
		{ val = "enemyIsHexproof", label = "Enemy is Hexproof?" },
		{ val = "enemyHasLessCurseEffectOnSelf", label = "Less effect of Curses on enemy:" },
		{ val = "enemyHasResistances", label = "Enemy has Elemental / ^xD02090Chaos ^7Resist:" },
	},
	Suffix = {
		{ val = "NONE", label = "None" },
		{ val = "playerHasElementalEquilibrium", label = "Player has Elemental Equilibrium?" }, 
		{ val = "playerCannotLeech", label = "Cannot Leech ^xE05030Life ^7/ ^x7070FFMana?" },
		{ val = "playerGainsReducedFlaskCharges", label = "Gains reduced Flask Charges:" },
		{ val = "playerHasMinusMaxResist", label = "-X% maximum Resistances:" },
		{ val = "playerHasLessAreaOfEffect", label = "Less Area of Effect:" },
		{ val = "enemyCanAvoidElementalAilment", label = "Enemy avoid Elemental Ailments:" },
		{ val = "enemyCanAvoidNonElementalAilment", label = "Enemy avoid Poison and Bleed:" },
		{ val = "enemyHasIncreasedAccuracy", label = "Unlucky Dodge / Enemy has inc. Accuracy:" },
		{ val = "playerHasLessArmourAndBlock", label = "Reduced Block Chance / less Armour:" },
		{ val = "playerHasPointBlank", label = "Player has Point Blank?" },
		{ val = "playerHasLessLifeESRecovery", label = "Less Recovery Rate of ^xE05030Life ^7and ^x88FFFFEnergy Shield:" },
		{ val = "playerCannotRegenLifeManaEnergyShield", label = "Cannot Regen ^xE05030Life^7, ^x7070FFMana ^7or ^x88FFFFES?" },
		{ val = "enemyTakesReducedExtraCritDamage", label = "Enemy takes red. Extra Crit Damage:" },
	},
	AffixData = {
		["enemyHasPhysicalReduction"] = { 
			type = "list",
			tooltip = "'Armoured'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {20, 30, 40}
				enemyModList:NewMod("PhysicalDamageReduction", "BASE", map[val] * mapModEffect, "Map mod Armoured")
			end 
		},
		["enemyIsHexproof"] = {
			type = "check",
			tooltip = "'Hexproof'",
			apply = function(val, modList, enemyModList, mapModEffect)
				enemyModList:NewMod("Hexproof", "FLAG", true, "Map mod Hexproof")
			end 
		},
		["enemyHasLessCurseEffectOnSelf"] = {
			type = "list",
			tooltip = "'Hexwarded'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {25, 40, 60}
				enemyModList:NewMod("CurseEffectOnSelf", "MORE", -map[val] * mapModEffect, "Map mod Hexwarded")
			end
		},
		["enemyHasResistances"] = {
			type = "list",
			tooltip = "'Resistant'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {20, 15},  {30, 20}, {40, 25} }
				enemyModList:NewMod("ElementalResist", "BASE", map[val][1] * mapModEffect, "Map mod Resistant")
				enemyModList:NewMod("ChaosResist", "BASE", map[val][2] * mapModEffect, "Map mod Resistant")
			end
		},
		["playerHasElementalEquilibrium"] = {
			type = "check",
			tooltip = "'of Balance'",
			apply = function(val, modList, enemyModList, mapModEffect)
				modList:NewMod("Keystone", "LIST", "Elemental Equilibrium", "Map mod of Balance")
			end
		},
		["playerCannotLeech"] = {
			type = "check",
			tooltip = "'of Congealment'",
			apply = function(val, modList, enemyModList, mapModEffect)
				enemyModList:NewMod("CannotLeechLifeFromSelf", "FLAG", true, "Map mod of Congealment")
				enemyModList:NewMod("CannotLeechManaFromSelf", "FLAG", true, "Map mod of Congealment")
			end
		},
		["playerGainsReducedFlaskCharges"] = {
			type = "list",
			tooltip = "'of Drought'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {30, 40, 50}
				modList:NewMod("FlaskChargesGained", "INC", -map[val] * mapModEffect, "Map mod of Drought")
			end
		},
		["playerHasMinusMaxResist"] = {
			type = "count",
			tooltip = "'of Exposure'\nMid tier: 5-8%\nHigh tier: 9-12%",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {0, 8, 12} -- Mid tier: 5-8% / High tier: 9-12%"
				if map[val] ~= 0 then
					modList:NewMod("FireResistMax", "BASE", -map[val] * mapModEffect, "Map mod of Exposure")
					modList:NewMod("ColdResistMax", "BASE", -map[val] * mapModEffect, "Map mod of Exposure")
					modList:NewMod("LightningResistMax", "BASE", -map[val] * mapModEffect, "Map mod of Exposure")
					modList:NewMod("ChaosResistMax", "BASE", -map[val] * mapModEffect, "Map mod of Exposure")
				end
			end
		},
		["playerHasLessAreaOfEffect"] = {
			type = "list",
			tooltip = "'of Impotence'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {15, 20, 25}
				modList:NewMod("AreaOfEffect", "MORE", -map[val] * mapModEffect, "Map mod of Impotence")
			end
		},
		["enemyCanAvoidElementalAilment"] = {
			type = "list",
			tooltip = "'of Insulation'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {30, 50, 70}
				enemyModList:NewMod("AvoidElementalAilments", "BASE", map[val] * mapModEffect, "Map mod of Insulation")
			end
		},
		["enemyCanAvoidNonElementalAilment"] = {
			type = "list",
			tooltip = "'Impervious'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {20, 35, 50}
				enemyModList:NewMod("AvoidPoison", "BASE", map[val] * mapModEffect, "Map mod Impervious")
				enemyModList:NewMod("AvoidBleed", "BASE", map[val] * mapModEffect, "Map mod Impervious")
			end
		},
		["enemyHasIncreasedAccuracy"] = {
			type = "list",
			tooltip = "'of Miring'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {30, 40, 50}
				modList:NewMod("DodgeChanceIsUnlucky", "FLAG", true, "Map mod of Miring")
				enemyModList:NewMod("Accuracy", "INC", map[val] * mapModEffect, "Map mod of Miring")
			end
		},
		["playerHasLessArmourAndBlock"] = {
			type = "list",
			tooltip = "'of Rust'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {20, 20}, {30, 25}, {40, 30} }
				modList:NewMod("BlockChance", "INC", -map[val][1] * mapModEffect, "Map mod of Rust")
				modList:NewMod("Armour", "MORE", -map[val][2] * mapModEffect, "Map mod of Rust")
			end
		},
		["playerHasPointBlank"] = {
			type = "check",
			tooltip = "'of Skirmishing'", 
			apply = function(val, modList, enemyModList, mapModEffect)
				modList:NewMod("Keystone", "LIST", "Point Blank", "Map mod of Skirmishing")
			end
		},
		["playerHasLessLifeESRecovery"] = {
			type = "list",
			tooltip = "'of Smothering'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {20, 40, 60}
				modList:NewMod("LifeRecoveryRate", "MORE", -map[val] * mapModEffect, "Map mod of Smothering")
				modList:NewMod("EnergyShieldRecoveryRate", "MORE", -map[val] * mapModEffect, "Map mod of Smothering")
			end
		},
		["playerCannotRegenLifeManaEnergyShield"] = {
			type = "check",
			label = "Cannot Regen ^xE05030Life^7, ^x7070FFMana ^7or ^x88FFFFES?", 
			tooltip = "'of Stasis'", 
			apply = function(val, modList, enemyModList, mapModEffect)
				modList:NewMod("NoLifeRegen", "FLAG", true, "Map mod of Stasis")
				modList:NewMod("NoEnergyShieldRegen", "FLAG", true, "Map mod of Stasis")
				modList:NewMod("NoManaRegen", "FLAG", true, "Map mod of Stasis")
			end
		},
		["enemyTakesReducedExtraCritDamage"] = {
			type = "count",
			tooltip = "'of Toughness'\nLow tier: 25-30%\nMid tier: 31-35%\nHigh tier: 36-40%",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {30, 35, 40} -- Low tier: 25-30% / Mid tier: 31-35% / High tier: 36-40%"
				enemyModList:NewMod("SelfCritMultiplier", "INC", -map[val] * mapModEffect, "Map mod of Toughness")
			end
		},
	},
}