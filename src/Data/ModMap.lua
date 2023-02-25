-- This is currently made by hand but should be auto generated
-- Item data (c) Grinding Gear Games

return {
	Prefix = {
		{ val = "NONE", label = "None" },
		{ val = { var = "enemyHasPhysicalReduction", type = "list", tooltip = "'Armoured'", label = "Enemy Physical Damage reduction:", list = {{val=0,label="None"},{val=20,label="20% (Low tier)"},{val=30,label="30% (Mid tier)"},{val=40,label="40% (High tier)"}}, apply = function(val, modList, enemyModList, mapModEffect)
			enemyModList:NewMod("PhysicalDamageReduction", "BASE", val * mapModEffect, "Config")
		end }, label = "Enemy Physical Damage reduction:" },
		{ val = { var = "enemyIsHexproof", type = "check", tooltip = "'Hexproof'", apply = function(val, modList, enemyModList, mapModEffect)
			enemyModList:NewMod("Hexproof", "FLAG", true, "Config")
		end }, label = "Enemy is Hexproof?" },
		{ val = { var = "enemyHasLessCurseEffectOnSelf", type = "list", tooltip = "'Hexwarded'", label = "Less effect of Curses on enemy:", list = {{val=0,label="None"},{val=25,label="25% (Low tier)"},{val=40,label="40% (Mid tier)"},{val=60,label="60% (High tier)"}}, apply = function(val, modList, enemyModList, mapModEffect)	
			if val ~= 0 then
				enemyModList:NewMod("CurseEffectOnSelf", "MORE", -val * mapModEffect, "Config")
			end
		end }, label = "Less effect of Curses on enemy:" },
		{ val = { var = "enemyHasResistances", type = "list", tooltip = "'Resistant'", label = "Enemy has Elemental / ^xD02090Chaos ^7Resist:", list = {{val=0,label="None"},{val="LOW",label="20% / 15% (Low tier)"},{val="MID",label="30% / 20% (Mid tier)"},{val="HIGH",label="40% / 25% (High tier)"}}, apply = function(val, modList, enemyModList, mapModEffect)
			local map = { ["LOW"] = {20,15}, ["MID"] = {30,20}, ["HIGH"] = {40,25} }
			if map[val] then
				enemyModList:NewMod("ElementalResist", "BASE", map[val][1] * mapModEffect, "Config")
				enemyModList:NewMod("ChaosResist", "BASE", map[val][2] * mapModEffect, "Config")
			end
		end }, label = "Enemy has Elemental / ^xD02090Chaos ^7Resist:" },
	},
	Suffix = {
		{ val = "NONE", label = "None" },
		{ val = { var = "playerHasElementalEquilibrium", type = "check", label = "Player has Elemental Equilibrium?", tooltip = "'of Balance'", apply = function(val, modList, enemyModList, mapModEffect)
			modList:NewMod("Keystone", "LIST", "Elemental Equilibrium", "Config")
		end }, label = "Player has Elemental Equilibrium?" }, 
		{ val = { var = "playerCannotLeech", type = "check", label = "Cannot Leech ^xE05030Life ^7/ ^x7070FFMana?", tooltip = "'of Congealment'", apply = function(val, modList, enemyModList, mapModEffect)
			enemyModList:NewMod("CannotLeechLifeFromSelf", "FLAG", true, "Config")
			enemyModList:NewMod("CannotLeechManaFromSelf", "FLAG", true, "Config")
		end }, label = "Cannot Leech ^xE05030Life ^7/ ^x7070FFMana?" },
		{ val = { var = "playerGainsReducedFlaskCharges", type = "list", label = "Gains reduced Flask Charges:", tooltip = "'of Drought'", list = {{val=0,label="None"},{val=30,label="30% (Low tier)"},{val=40,label="40% (Mid tier)"},{val=50,label="50% (High tier)"}}, apply = function(val, modList, enemyModList, mapModEffect)
			if val ~= 0 then
				modList:NewMod("FlaskChargesGained", "INC", -val * mapModEffect, "Config")
			end
		end }, label = "Gains reduced Flask Charges:" },
		{ val = { var = "playerHasMinusMaxResist", type = "count", label = "-X% maximum Resistances:", tooltip = "'of Exposure'\nMid tier: 5-8%\nHigh tier: 9-12%", apply = function(val, modList, enemyModList, mapModEffect)
			if val ~= 0 then
				modList:NewMod("FireResistMax", "BASE", -val * mapModEffect, "Config")
				modList:NewMod("ColdResistMax", "BASE", -val * mapModEffect, "Config")
				modList:NewMod("LightningResistMax", "BASE", -val * mapModEffect, "Config")
				modList:NewMod("ChaosResistMax", "BASE", -val * mapModEffect, "Config")
			end
		end }, label = "-X% maximum Resistances:" },
		{ val = { var = "playerHasLessAreaOfEffect", type = "list", label = "Less Area of Effect:", tooltip = "'of Impotence'", list = {{val=0,label="None"},{val=15,label="15% (Low tier)"},{val=20,label="20% (Mid tier)"},{val=25,label="25% (High tier)"}}, apply = function(val, modList, enemyModList, mapModEffect)
			if val ~= 0 then
				modList:NewMod("AreaOfEffect", "MORE", -val * mapModEffect, "Config")
			end
		end }, label = "Less Area of Effect:" },
		{ val = { var = "enemyCanAvoidElementalAilment", type = "list", label = "Enemy avoid Elemental Ailments:", tooltip = "'of Insulation'", list = {{val=0,label="None"},{val=30,label="30% (Low tier)"},{val=50,label="50% (Mid tier)"},{val=70,label="70% (High tier)"}}, apply = function(val, modList, enemyModList, mapModEffect)	
			if val ~= 0 then
				enemyModList:NewMod("AvoidElementalAilments", "BASE", val * mapModEffect, "Config")
			end
		end }, label = "Enemy avoid Elemental Ailments:" },
		{ val = { var = "enemyCanAvoidNonElementalAilment", type = "list", label = "Enemy avoid Poison and Bleed:", tooltip = "'Impervious'", list = {{val=0,label="None"},{val=20,label="20% (Low tier)"},{val=35,label="35% (Mid tier)"},{val=50,label="50% (High tier)"}}, apply = function(val, modList, enemyModList, mapModEffect)	
			if val ~= 0 then
				enemyModList:NewMod("AvoidPoison", "BASE", val * mapModEffect, "Config")
				enemyModList:NewMod("AvoidBleed", "BASE", val * mapModEffect, "Config")
			end
		end }, label = "Enemy avoid Poison and Bleed:" },
		{ val = { var = "enemyHasIncreasedAccuracy", type = "list", label = "Unlucky Dodge / Enemy has inc. Accuracy:", tooltip = "'of Miring'", list = {{val=0,label="None"},{val=30,label="30% (Low tier)"},{val=40,label="40% (Mid tier)"},{val=50,label="50% (High tier)"}}, apply = function(val, modList, enemyModList, mapModEffect)
			if val ~= 0 then
				modList:NewMod("DodgeChanceIsUnlucky", "FLAG", true, "Config")
				enemyModList:NewMod("Accuracy", "INC", val * mapModEffect, "Config")
			end
		end }, label = "Unlucky Dodge / Enemy has inc. Accuracy:" },
		{ val = { var = "playerHasLessArmourAndBlock", type = "list", label = "Reduced Block Chance / less Armour:", tooltip = "'of Rust'", list = {{val=0,label="None"},{val="LOW",label="20% / 20% (Low tier)"},{val="MID",label="30% / 25% (Mid tier)"},{val="HIGH",label="40% / 30% (High tier)"}}, apply = function(val, modList, enemyModList, mapModEffect)
			local map = { ["LOW"] = {20,20}, ["MID"] = {30,25}, ["HIGH"] = {40,30} }
			if map[val] then
				modList:NewMod("BlockChance", "INC", -map[val][1] * mapModEffect, "Config")
				modList:NewMod("Armour", "MORE", -map[val][2] * mapModEffect, "Config")
			end
		end }, label = "Reduced Block Chance / less Armour:" },
		{ val = { var = "playerHasPointBlank", type = "check", label = "Player has Point Blank?", tooltip = "'of Skirmishing'", apply = function(val, modList, enemyModList, mapModEffect)
			modList:NewMod("Keystone", "LIST", "Point Blank", "Config")
		end }, label = "Player has Point Blank?" },
		{ val = { var = "playerHasLessLifeESRecovery", type = "list", label = "Less Recovery Rate of ^xE05030Life ^7and ^x88FFFFEnergy Shield:", tooltip = "'of Smothering'", list = {{val=0,label="None"},{val=20,label="20% (Low tier)"},{val=40,label="40% (Mid tier)"},{val=60,label="60% (High tier)"}}, apply = function(val, modList, enemyModList, mapModEffect)
			if val ~= 0 then
				modList:NewMod("LifeRecoveryRate", "MORE", -val * mapModEffect, "Config")
				modList:NewMod("EnergyShieldRecoveryRate", "MORE", -val * mapModEffect, "Config")
			end
		end }, label = "Less Recovery Rate of ^xE05030Life ^7and ^x88FFFFEnergy Shield:" },
		{ val = { var = "playerCannotRegenLifeManaEnergyShield", type = "check", label = "Cannot Regen ^xE05030Life^7, ^x7070FFMana ^7or ^x88FFFFES?", tooltip = "'of Stasis'", apply = function(val, modList, enemyModList, mapModEffect)
			modList:NewMod("NoLifeRegen", "FLAG", true, "Config")
			modList:NewMod("NoEnergyShieldRegen", "FLAG", true, "Config")
			modList:NewMod("NoManaRegen", "FLAG", true, "Config")
		end }, label = "Cannot Regen ^xE05030Life^7, ^x7070FFMana ^7or ^x88FFFFES?" },
		{ val = { var = "enemyTakesReducedExtraCritDamage", type = "count", label = "Enemy takes red. Extra Crit Damage:", tooltip = "'of Toughness'\nLow tier: 25-30%\nMid tier: 31-35%\nHigh tier: 36-40%" , apply = function(val, modList, enemyModList, mapModEffect)
			if val ~= 0 then
				enemyModList:NewMod("SelfCritMultiplier", "INC", -val * mapModEffect, "Config")
			end
		end }, label = "Enemy takes red. Extra Crit Damage:" },
	}
}