-- This is currently made by hand but should be auto generated
-- Item data (c) Grinding Gear Games

return {
	AffixData = {
		-- defensive prefixes
		["Armoured"] = {
			type = "list",
			tooltipLines = { "+%d%% Monster Physical Damage Reduction" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageReduction", "BASE", values[val] * mapModEffect, "Map mod Armoured")
			end,
			values = {
				[1] = 20,
				[2] = 30,
				[3] = 40,
				[4] = 40,
			},
		},
		["Hexproof"] = {
			type = "check",
			tooltipLines = { "Monsters are Hexproof" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("Hexproof", "FLAG", true, "Map mod Hexproof")
			end,
		},
		["Hexwarded"] = {
			type = "list",
			tooltipLines = { "%d%% less effect of Curses on Monsters" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("CurseEffectOnSelf", "MORE", -values[val] * mapModEffect, "Map mod Hexwarded")
			end,
			values = {
				[1] = 25,
				[2] = 40,
				[3] = 60,
				[4] = 60,
			},
		},
		["Resistant"] = {
			type = "list",
			tooltipLines = { "+%d%% Monster Chaos Resistance", "+%d%% Monster Elemental Resistances" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("ElementalResist", "BASE", values[val][2] * mapModEffect, "Map mod Resistant")
				enemyModList:NewMod("ChaosResist", "BASE", values[val][1] * mapModEffect, "Map mod Resistant")
			end,
			values = {
				[1] = { 15, 20 },
				[2] = { 20, 30 },
				[3] = { 25, 40 },
				[4] = { 25, 40 },
			},
		},
		["Unwavering"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% more Monster Life", "Monsters cannot be Stunned" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("AvoidStun", "BASE", 100, "Map mod Unwavering")
				enemyModList:NewMod("Life", "MORE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Unwavering")
			end,
			values = {
				[1] = { 15, 19 },
				[2] = { 20, 24 },
				[3] = { 25, 30 },
				[4] = { 25, 30 },
			},
		},
		["Fecund"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% more Monster Life" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Life", "MORE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Fecund")
			end,
			values = {
				[1] = { 20, 29 },
				[2] = { 30, 39 },
				[3] = { 40, 49 },
				[4] = { 40, 49 },
			},
		},
		["Fecund UBER"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% more Monster Life" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Life", "MORE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Fecund")
			end,
			values = {
				[4] = { 90, 100 },
			},
		},
		["Unstoppable"] = {
			type = "check",
			tooltipLines = { "Monsters cannot be Taunted", "Monsters' Action Speed cannot be modified to below Base Value", "Monsters' Movement Speed cannot be modified to below Base Value" },
			apply = function(val, mapModEffect, modList, enemyModList)
				-- MISSING: Monsters cannot be Taunted
				enemyModList:NewMod("MinimumActionSpeed", "MAX", 100, "Map mod Unstoppable")
			end,
		},
		["Impervious"] = {
			type = "list",
			tooltipLines = { "Monsters have a %d%% chance to avoid Poison, Impale, and Bleeding" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("AvoidPoison", "BASE", values[val] * mapModEffect, "Map mod Impervious")
				enemyModList:NewMod("AvoidImpale", "BASE", values[val] * mapModEffect, "Map mod Impervious")
				enemyModList:NewMod("AvoidBleed", "BASE", values[val] * mapModEffect, "Map mod Impervious")
			end,
			values = {
				[1] = 20,
				[2] = 35,
				[3] = 50,
				[4] = 50,
			},
		},
		["Oppressive"] = {
			type = "list",
			tooltipLines = { "Monsters have +%d%% chance to Suppress Spell Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("SpellSuppressionChance", "BASE", values[val] * mapModEffect, "Map mod Oppressive")
			end,
			values = {
				[1] = 30,
				[2] = 45,
				[3] = 60,
				[4] = 60,
			},
		},
		["Oppressive UBER"] = {
			type = "list",
			tooltipLines = { "Monsters have +%d%% chance to Suppress Spell Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("SpellSuppressionChance", "BASE", values[val] * mapModEffect, "Map mod Oppressive")
			end,
			values = {
				[4] = 100,
			},
		},
		["Buffered"] = {
			type = "count",
			tooltipLines = { "Monsters gain (%d to %d)%% of Maximum Life as Extra Maximum Energy Shield" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("LifeGainAsEnergyShield", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Buffered")
			end,
			values = {
				[1] = { 20, 29 },
				[2] = { 30, 39 },
				[3] = { 40, 49 },
				[4] = { 40, 49 },
			},
		},
		["Buffered UBER"] = {
			type = "count",
			tooltipLines = { "Monsters gain (%d to %d)%% of Maximum Life as Extra Maximum Energy Shield" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("LifeGainAsEnergyShield", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Buffered")
			end,
			values = {
				[4] = { 70, 80 },
			},
		},
		["Titan's"] = {
			type = "list",
			tooltipLines = { "Unique Boss has %d%% increased Life", "Unique Boss has %d%% increased Area of Effect" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Life", "MORE", values[val][1] * mapModEffect, "Map mod Titan's", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("AreaOfEffect", "INC", values[val][2] * mapModEffect, "Map mod Titan's", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { 25, 45 },
				[2] = { 30, 55 },
				[3] = { 35, 70 },
				[4] = { 35, 70 },
			},
		},
		-- offensive prefixes
		["Savage"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% increased Monster Damage" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Damage", "INC", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Savage")
			end,
			values = {
				[1] = { 14, 17 },
				[2] = { 18, 21 },
				[3] = { 22, 25 },
				[4] = { 22, 25 },
			},
		},
		["Savage UBER"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% increased Monster Damage" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Damage", "INC", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Savage")
			end,
			values = {
				[4] = { 30, 40 },
			},
		},
		["Burning"] = {
			type = "count",
			tooltipLines = { "Monsters deal (%d to %d)%% extra Physical Damage as Fire" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsFire", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Burning")
			end,
			values = {
				[1] = { 50, 69 },
				[2] = { 70, 89 },
				[3] = { 90, 110 },
				[4] = { 90, 110 },
			},
		},
		["Freezing"] = {
			type = "count",
			tooltipLines = { "Monsters deal (%d to %d)%% extra Physical Damage as Cold" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsCold", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Freezing")
			end,
			values = {
				[1] = { 50, 69 },
				[2] = { 70, 89 },
				[3] = { 90, 110 },
				[4] = { 90, 110 },
			},
		},
		["Shocking"] = {
			type = "count",
			tooltipLines = { "Monsters deal (%d to %d)%% extra Physical Damage as Lightning" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsLightning", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Shocking")
			end,
			values = {
				[1] = { 50, 69 },
				[2] = { 70, 89 },
				[3] = { 90, 110 },
				[4] = { 90, 110 },
			},
		},
		["Profane"] = {
			type = "count",
			tooltipLines = { "Monsters gain (%d to %d)%% of their Physical Damage as Extra Chaos Damage", "Monsters Inflict Withered for %d seconds on Hit" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				if values[val] then
					enemyModList:NewMod("PhysicalDamageGainAsChaos", "BASE", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100) * mapModEffect, "Map mod Profane")
					modList:NewMod("Condition:CanBeWithered", "FLAG", true, "Map mod Profane")
				end
			end,
			values = {
				[2] = { { 21, 25 }, { 100 } },
				[3] = { { 31, 35 }, { 100 } },
				[4] = { { 31, 35 }, { 100 } },
			},
		},
		["Profane UBER"] = {
			type = "count",
			tooltipLines = { "Monsters gain (%d to %d)%% of their Physical Damage as Extra Chaos Damage" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				if values[val] then
					enemyModList:NewMod("PhysicalDamageGainAsChaos", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Profane")
				end
			end,
			values = {
				[4] = { 80, 100 },
			},
		},
		["Fleet"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% increased Monster Movement Speed", "(%d to %d)%% increased Monster Attack Speed", "(%d to %d)%% increased Monster Cast Speed" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				-- attack and cast is the same so applying it once, movespeed does not matter
				enemyModList:NewMod("Speed", "INC", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100) * mapModEffect, "Map mod Fleet")
			end,
			values = {
				[1] = { { 15, 20 }, { 20, 25 }, { 20, 25 } },
				[2] = { { 20, 25 }, { 25, 35 }, { 25, 35 } },
				[3] = { { 25, 30 }, { 35, 45 }, { 35, 45 } },
			},
		},
		["Fleet UBER"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% increased Monster Movement Speed", "(%d to %d)%% increased Monster Attack Speed", "(%d to %d)%% increased Monster Cast Speed" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				-- attack and cast is the same so applying it once, movespeed does not matter
				enemyModList:NewMod("Speed", "INC", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100) * mapModEffect, "Map mod Fleet")
			end,
			values = {
				[4] = { { 35, 45 }, { 35, 45 }, { 25, 30 } },
			},
		},
		["Conflagrating"] = {
			type = "check",
			tooltipLines = { "All Monster Damage from Hits always Ignites" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("IgniteChance", "BASE", 100, "Map mod Conflagrating")
				enemyModList:NewMod("AllDamageIgnites", "FLAG", true, "Map mod Conflagrating")
			end,
		},
		["Impaling"] = {
			type = "list",
			tooltipLines = { "Monsters' Attacks have %d%% chance to Impale on Hit" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("ImpaleChance", "BASE", values[val] * mapModEffect, "Map mod Impaling", ModFlag.Attack)
			end,
			values = {
				[1] = 25,
				[2] = 40,
				[3] = 60,
				[4] = 60,
			},
		},
		["Impaling UBER"] = {
			type = "list",
			tooltipLines = { "Monsters' Attacks Impale on Hit", "When a fifth Impale is inflicted on a Player, Impales are removed to Reflect their Physical Damage multiplied by their remaining Hits to that Player and their Allies within %d.%d metres" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				if val == 4 then
					enemyModList:NewMod("ImpaleChance", "BASE", values[val][2] * mapModEffect, "Map mod Impaling", ModFlag.Attack)
				end
			end,
			values = {
				[4] = { 5, 100 },
			},
		},
		["Empowered"] = {
			type = "list",
			tooltipLines = { "Monsters have a %d%% chance to Ignite, Freeze and Shock on Hit" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				if values[val] then
					enemyModList:NewMod("ElementalAilmentChance", "BASE", values[val] * mapModEffect, "Map mod Empowered")
				end
			end,
			values = {
				[2] = 15,
				[3] = 20,
				[4] = 20,
			},
		},
		["Overlord's"] = {
			type = "list",
			tooltipLines = { "Unique Boss deals %d%% increased Damage", "Unique Boss has %d%% increased Attack and Cast Speed" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Damage", "INC", values[val][1] * mapModEffect, "Map mod Overlord's", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("Speed", "INC", values[val][2] * mapModEffect, "Map mod Overlord's", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { 15, 20 },
				[2] = { 20, 25 },
				[3] = { 25, 30 },
				[4] = { 25, 30 },
			},
		},
		-- reflect prefixes
		["Punishing"] = {
			type = "list",
			tooltipLines = { "Monsters reflect %d%% of Physical Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end,
			values = {
				[1] = 13,
				[2] = 15,
				[3] = 18,
				[4] = 18,
			},
		},
		["Punishing UBER"] = {
			type = "list",
			tooltipLines = { "Monsters reflect %d%% of Physical Damage", "Monsters reflect %d%% of Elemental Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end,
			values = {
				[4] = { 20, 20 },
			},
		},
		["Mirrored"] = {
			type = "list",
			tooltipLines = { "Monsters reflect %d%% of Elemental Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end,
			values = {
				[1] = 13,
				[2] = 15,
				[3] = 18,
				[4] = 18,
			},
		},
		-- suffixes
		["of Balance"] = {
			type = "check",
			label = "Player has Elemental Equilibrium?",
			tooltipLines = { "Players cannot inflict Exposure" },
			apply = function(val, mapModEffect, modList, enemyModList)
				-- Players cannot inflict Exposure
				-- modList:NewMod("Keystone", "LIST", "Elemental Equilibrium", "Map mod of Balance") -- OLD MOD
			end,
		},
		["of Congealment"] = {
			type = "check",
			tooltipLines = { "Monsters cannot be Leeched from" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("CannotLeechLifeFromSelf", "FLAG", true, "Map mod of Congealment")
				enemyModList:NewMod("CannotLeechManaFromSelf", "FLAG", true, "Map mod of Congealment")
				--missing cannot leech es?
			end,
		},
		["of Drought"] = {
			type = "list",
			tooltipLines = { "Players gain %d%% reduced Flask Charges" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("FlaskChargesGained", "INC", -values[val] * mapModEffect, "Map mod of Drought")
			end,
			values = {
				[1] = 30,
				[2] = 40,
				[3] = 50,
				[4] = 50,
			},
		},
		["of Exposure"] = {
			type = "count",
			tooltipLines = { "Players have minus (%d to %d)%% to all maximum Resistances" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				if values[val] then
					local roll = (values[val][2] + (values[val][1] - values[val][2]) * rollRange / 100) * mapModEffect
					modList:NewMod("FireResistMax", "BASE", -roll, "Map mod of Exposure")
					modList:NewMod("ColdResistMax", "BASE", -roll, "Map mod of Exposure")
					modList:NewMod("LightningResistMax", "BASE", -roll, "Map mod of Exposure")
					modList:NewMod("ChaosResistMax", "BASE", -roll, "Map mod of Exposure")
				end
			end,
			values = {
				[2] = { 8, 5 },
				[3] = { 12, 9 },
				[4] = { 12, 9 },
			},
		},
		["of Exposure UBER"] = {
			type = "list",
			tooltipLines = { "Players have minus %d%% to all maximum Resistances" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				if val == 4 then
					modList:NewMod("FireResistMax", "BASE", -values[val], "Map mod of Exposure")
					modList:NewMod("ColdResistMax", "BASE", -values[val], "Map mod of Exposure")
					modList:NewMod("LightningResistMax", "BASE", -values[val], "Map mod of Exposure")
					modList:NewMod("ChaosResistMax", "BASE", -values[val], "Map mod of Exposure")
				end
			end,
			values = {
				[4] = 20,
			},
		},
		["of Impotence"] = {
			type = "list",
			tooltipLines = { "Players have %d%% less Area of Effect" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("AreaOfEffect", "MORE", -values[val] * mapModEffect, "Map mod of Impotence")
			end,
			values = {
				[1] = 15,
				[2] = 20,
				[3] = 25,
				[4] = 25,
			},
		},
		["of Impotence UBER"] = {
			type = "count",
			tooltipLines = { "Players have (%d to %d)%% less Area of Effect" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				if val == 4 then
					modList:NewMod("AreaOfEffect", "MORE", -(values[val][2] + (values[val][1] - values[val][2]) * 100 / 100) * mapModEffect, "Map mod of Impotence")
				end
			end,
			values = {
				[4] = { 30, 25 },
			},
		},
		["of Insulation"] = {
			type = "list",
			tooltipLines = { "Monsters have %d%% chance to Avoid Elemental Ailments" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("AvoidElementalAilments", "BASE", values[val] * mapModEffect, "Map mod of Insulation")
			end,
			values = {
				[1] = 30,
				[2] = 50,
				[3] = 70,
				[4] = 70,
			},
		},
		["of Miring"] = {
			type = "list",
			tooltipLines = { "Monsters have %d%% increased Accuracy Rating", "Players have minus %d%% to amount of Suppressed Spell Damage Prevented" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("SpellSuppressionEffect", "BASE", -values[val][1] * mapModEffect, "Map mod of Miring")
				enemyModList:NewMod("Accuracy", "INC", values[val][2] * mapModEffect, "Map mod of Miring")
			end,
			values = {
				[1] = { 10, 30 },
				[2] = { 15, 40 },
				[3] = { 20, 50 },
				[4] = { 20, 50 },
			},
		},
		["of Miring UBER"] = {
			type = "count",
			tooltipLines = { "Players have (%d to %d)%% less Defences" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				modList:NewMod("Defences", "MORE", -(values[val][2] + (values[val][1] - values[val][2]) * 100 / 100) * mapModEffect, "Map mod of Miring")
			end,
			values = {
				[4] = { 30, 25 },
			},
		},
		["of Rust"] = {
			type = "list",
			tooltipLines = { "Players have %d%% less Armour", "Players have %d%% reduced Chance to Block" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("BlockChance", "INC", -values[val][1] * mapModEffect, "Map mod of Rust")
				modList:NewMod("Armour", "MORE", -values[val][2] * mapModEffect, "Map mod of Rust")
			end,
			values = {
				[1] = { 20, 20 },
				[2] = { 30, 25 },
				[3] = { 40, 30 },
				[4] = { 40, 30 },
			},
		},
		["of Smothering"] = {
			type = "list",
			tooltipLines = { "Players have %d%% less Recovery Rate of Life and Energy Shield" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("LifeRecoveryRate", "MORE", -values[val] * mapModEffect, "Map mod of Smothering")
				modList:NewMod("EnergyShieldRecoveryRate", "MORE", -values[val] * mapModEffect, "Map mod of Smothering")
			end,
			values = {
				[1] = 20,
				[2] = 40,
				[3] = 60,
				[4] = 60,
			},
		},
		["of Stasis"] = {
			type = "check",
			tooltipLines = { "Players cannot Regenerate Life, Mana or Energy Shield" },
			apply = function(val, mapModEffect, modList, enemyModList)
				modList:NewMod("NoLifeRegen", "FLAG", true, "Map mod of Stasis")
				modList:NewMod("NoEnergyShieldRegen", "FLAG", true, "Map mod of Stasis")
				modList:NewMod("NoManaRegen", "FLAG", true, "Map mod of Stasis")
			end,
		},
		["of Toughness"] = {
			type = "count",
			tooltipLines = { "Monsters take (%d to %d)%% reduced Extra Damage from Critical Strikes" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("SelfCritMultiplier", "INC", -(values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod of Toughness")
			end,
			values = {
				[1] = { 25, 30 },
				[2] = { 31, 35 },
				[3] = { 36, 40 },
				[4] = { 36, 40 },
			},
		},
		["of Toughness UBER"] = {
			type = "count",
			tooltipLines = { "Monsters take (%d to %d)%% reduced Extra Damage from Critical Strikes" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("SelfCritMultiplier", "INC", -(values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod of Toughness")
			end,
			values = {
				[4] = { 35, 45 },
			},
		},
		["of Fatigue"] = {
			type = "list",
			tooltipLines = { "Players have %d%% less Cooldown Recovery Rate" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("CooldownRecovery", "MORE", -values[val] * mapModEffect, "Map mod of Fatigue")
			end,
			values = {
				[1] = 20,
				[2] = 30,
				[3] = 40,
				[4] = 40,
			},
		},
		["of Transience"] = {
			type = "list",
			tooltipLines = { "Buffs on Players expire %d%% faster" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end,
			values = {
				[1] = 30,
				[2] = 50,
				[3] = 70,
				[4] = 70,
			},
		},
		["of Transience UBER"] = {
			type = "list",
			tooltipLines = { "Buffs on Players expire %d%% faster" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end,
			values = {
				[4] = 100,
			},
		},
		["of Doubt"] = {
			type = "list",
			tooltipLines = { "Players have %d%% reduced effect of Non-Curse Auras from Skills" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("AuraEffect", "INC", -values[val] * mapModEffect, "Map mod of Doubt", { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.AppliesCurse, neg = true })
			end,
			values = {
				[1] = 25,
				[2] = 40,
				[3] = 60,
				[4] = 60,
			},
		},
		["of Imprecision"] = {
			type = "list",
			tooltipLines = { "Players have %d%% less Accuracy Rating" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("Accuracy", "MORE", -values[val] * mapModEffect, "Map mod of Imprecision")
			end,
			values = {
				[1] = 15,
				[2] = 20,
				[3] = 25,
				[4] = 25,
			},
		},
		["of Blinding"] = {
			type = "check",
			tooltipLines = { "Monsters Blind on Hit" },
			apply = function(val, mapModEffect, modList, enemyModList)
				--SHOULD THIS BE SUPPORTED? (as a flag to make "are you blinded" show on config?)
			end,
		},
		["of Venom"] = {
			type = "check",
			tooltipLines = { "Monsters Poison on Hit" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("PoisonChance", "BASE", 100, "Map mod of Venom")
			end,
		},
		["of Deadliness"] = {
			type = "count",
			tooltipLines = { "Monsters have (%d to %d)%% increased Critical Strike Chance", "+(%d to %d)%% to Monster Critical Strike Multiplier" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("CritChance", "INC", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100) * mapModEffect, "Map mod of Deadliness")
				enemyModList:NewMod("CritMultiplier", "BASE", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100) * mapModEffect, "Map mod of Deadliness")
			end,
			values = {
				[1] = { { 160, 200 }, { 30, 35 } },
				[2] = { { 260, 300 }, { 36, 40 } },
				[3] = { { 360, 400 }, { 41, 45 } },
				[4] = { { 360, 400 }, { 41, 45 } },
			},
		},
		["of Deadliness UBER"] = {
			type = "count",
			tooltipLines = { "Monsters have (%d to %d)%% increased Critical Strike Chance", "+(%d to %d)%% to Monster Critical Strike Multiplier" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("CritChance", "INC", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100) * mapModEffect, "Map mod of Deadliness")
				enemyModList:NewMod("CritMultiplier", "BASE", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100) * mapModEffect, "Map mod of Deadliness")
			end,
			values = {
				[4] = { { 650, 700 }, { 70, 75 } },
			},
		},
		-- other Prefixes
		["Abhorrent"] = { }, -- Area is inhabited by Abominations
		["Afflicting"] = { }, -- All Monster Damage can Ignite, Freeze and Shock", "Monsters Ignite, Freeze and Shock on Hit
		["Antagonist's"] = { }, -- (20-30)% increased number of Rare Monsters
		["Bipedal"] = { }, -- Area is inhabited by Humanoids
		["Capricious"] = { }, -- Area is inhabited by Goatmen
		["Ceremonial"] = { }, -- Area contains many Totems
		["Chaining"] = { }, -- Monsters' skills Chain 2 additional times
		["Cycling"] = { }, -- Players and their Minions deal no damage for 3 out of every 10 seconds
		["Demonic"] = { }, -- Area is inhabited by Demons
		["Emanant"] = { }, -- Area is inhabited by ranged monsters
		["Enthralled"] = { }, -- Unique Bosses are Possessed
		["Equalising"] = { }, -- Rare and Unique Monsters remove 5% of Life, Mana and Energy Shield from Players or their Minions on Hit
		["Feasting"] = { }, -- Area is inhabited by Cultists of Kitava
		["Feral"] = { }, -- Area is inhabited by Animals
		["Grasping"] = { }, -- Monsters inflict 2 Grasping Vines on Hit
		["Haunting"] = { }, -- Area is inhabited by Ghosts
		["Hungering"] = { }, -- Area contains Drowning Orbs
		["Lunar"] = { }, -- Area is inhabited by Lunaris fanatics
		["Magnifying"] = { }, -- Monsters have 100% increased Area of Effect", "Monsters fire 2 additional Projectiles
		["Multifarious"] = { }, -- Area has increased monster variety
		["Parasitic"] = { }, -- 15% of Damage Players' Totems take from Hits is taken from their Summoner's Life instead
		["Prismatic"] = { }, -- Monsters gain (180-200)% of their Physical Damage as Extra Damage of a random Element
		["Protected"] = { }, -- +50% Monster Physical Damage Reduction", "+35% Monster Chaos Resistance", "+55% Monster Elemental Resistances
		["Retributive"] = { }, -- Players are Marked for Death for 10 seconds", "after killing a Rare or Unique monster
		["Sabotaging"] = { }, -- Player Skills which Throw Mines throw 1 fewer Mine", "Player Skills which Throw Traps throw 1 fewer Trap
		["Searing"] = { }, -- Area contains Runes of the Searing Exarch
		["Skeletal"] = { }, -- Area is inhabited by Skeletons
		["Slithering"] = { }, -- Area is inhabited by Sea Witches and their Spawn
		["Solar"] = { }, -- Area is inhabited by Solaris fanatics
		["Splitting"] = { }, -- Monsters fire 2 additional Projectiles
		["Stalwart"] = { }, -- Monsters have +50% Chance to Block Attack Damage
		["Synthetic"] = { }, -- Map Boss is accompanied by a Synthesis Boss
		["Twinned"] = { }, -- Area contains two Unique Bosses
		["Ultimate"] = { }, -- Players are assaulted by Bloodstained Sawblades
		["Undead"] = { }, -- Area is inhabited by Undead
		["Valdo's"] = { }, -- Rare monsters in area are Shaper-Touched
		["Volatile"] = { }, -- Rare Monsters have Volatile Cores
		-- other Suffixes
		["Decaying"] = { }, -- Area contains Unstable Tentacle Fiends
		["of Bloodlines"] = { }, -- (20-30)% increased Magic Monsters
		["of Carnage"] = { }, -- Monsters Maim on Hit with Attacks
		["of Collection"] = { }, -- The Maven interferes with Players
		["of Consecration"] = { }, -- Area has patches of Consecrated Ground
		["of Deceleration"] = { }, -- Players have 3% reduced Action Speed for each time they've used a Skill Recently
		["of Defiance"] = { }, -- Debuffs on Monsters expire 100% faster
		["of Desecration"] = { }, -- Area has patches of desecrated ground
		["of Desolation"] = { }, -- Area has patches of Awakeners' Desolation
		["of Domination"] = { }, -- Unique Monsters have a random Shrine Buff
		["of Endurance"] = { }, -- Monsters gain an Endurance Charge on Hit
		["of Enervation"] = { }, -- Monsters steal Power, Frenzy and Endurance charges on Hit
		["of Flames"] = { }, -- Area has patches of Burning Ground
		["of Frenzy"] = { }, -- Monsters gain a Frenzy Charge on Hit
		["of Giants"] = { }, -- Monsters have 45% increased Area of Effect
		["of Ice"] = { }, -- Area has patches of Chilled Ground
		["of Imbibing"] = { }, -- Players are targeted by a Meteor when they use a Flask
		["of Impedance"] = { }, -- Monsters Hinder on Hit with Spells
		["of Lightning"] = { }, -- Area has patches of Shocked Ground which increase Damage taken by 20%
		["of Penetration"] = { }, -- Monster Damage Penetrates 15% Elemental Resistances
		["of Petrification"] = { }, -- Area contains Petrification Statues
		["of Power"] = { }, -- Monsters gain a Power Charge on Hit
		["of Revolt"] = { }, -- Players' Minions have 50% less Attack Speed", "Players' Minions have 50% less Cast Speed", "Players' Minions have 50% less Movement Speed
		["of Splinters"] = { }, -- 25% chance for Rare Monsters to Fracture on death
		["of the Juggernaut"] = { }, -- Monsters cannot be Stunned", "Monsters' Action Speed cannot be modified to below Base Value", "Monsters' Movement Speed cannot be modified to below Base Value
	},
	Prefix = {
		{ val = "Armoured", label = "Enemy Physical Damage reduction                                                                  Monster Armoured" },
		{ val = "Hexproof", label = "Enemy is Hexproof?                                                                  Monsters are Hexproof" },
		{ val = "Hexwarded", label = "Less effect of Curses on enemy                                                                  Monsters Hexwarded" },
		{ val = "Resistant", label = "Enemy has Elemental / ^xD02090Chaos ^7Resist                                                                  Monster Resistances Resistant" },
		{ val = "Unstoppable", label = "Enemy Cannot Be Slowed                                                                  Taunted Monsters' Action Speed modified below Base Value Movement Unstoppable" },
		{ val = "Impervious", label = "Enemy chance to avoid Poison and Bleed                                                                  Monsters have Poison, Impale, Bleeding Impervious" },
		{ val = "Savage", label = "Enemy Increased Damage                                                                  to Monster Savage", range = true },
		{ val = "Savage UBER", label = "Enemy Increased Damage                                                                  to Monster Savage UBER", range = true },
		{ val = "Burning", label = "Enemy Physical As Extra Fire                                                                  Monsters deal to Damage Burning", range = true },
		{ val = "Freezing", label = "Enemy Physical As Extra Cold                                                                  Monsters deal to Damage Freezing", range = true },
		{ val = "Shocking", label = "Enemy Physical As Extra Lightning                                                                  Monsters deal to Damage Shocking", range = true },
		{ val = "Profane", label = "Enemy Physical As Extra Chaos                                                                  Monsters gain to their Damage Inflict Withered for seconds Hit Profane", range = true },
		{ val = "Profane UBER", label = "Enemy Physical As Extra Chaos                                                                  Monsters gain to their Damage Profane UBER", range = true },
		{ val = "Fleet", label = "Enemy Increased Speed                                                                  to Monster Movement Attack Cast Fleet", range = true },
		{ val = "Fleet UBER", label = "Enemy Increased Speed                                                                  to Monster Movement Attack Cast Fleet UBER", range = true },
		{ val = "Conflagrating", label = "Enemy Hits always Ignites                                                                  All Monster Damage from Conflagrating" },
		{ val = "Impaling", label = "Enemy chance to Impale                                                                  Monsters' Attacks have Hit Impaling" },
		{ val = "Impaling UBER", label = "Enemy chance to Impale                                                                  Monsters' Attacks Hit When fifth is inflicted Player, Impales are removed Reflect their Physical Damage multiplied by remaining Hits that and Allies within metres Impaling UBER" },
		{ val = "Empowered", label = "Enemy Elemental Ailments chance on Hit                                                                  Monsters have to Ignite, Freeze and Shock Empowered" },
		{ val = "Overlord's", label = "Boss Increased Damage / Speed                                                                  Unique deals has Attack and Cast Overlord's" },
	},
	Suffix = {
		{ val = "of Congealment", label = "Cannot Leech ^xE05030Life ^7/ ^x7070FFMana                                                                  Monsters be Leeched from of Congealment" },
		{ val = "of Drought", label = "Gain reduced Flask Charges                                                                  Players of Drought" },
		{ val = "of Exposure", label = "-X% maximum Resistances                                                                  Players have minus to all of Exposure", range = true },
		{ val = "of Exposure UBER", label = "-X% maximum Resistances                                                                  Players have minus to all of Exposure UBER" },
		{ val = "of Impotence", label = "Less Area of Effect:                                                                  Players have of Impotence" },
		{ val = "of Impotence UBER", label = "Less Area of Effect:                                                                  Players have to of Impotence UBER", range = true },
		{ val = "of Insulation", label = "Enemy chance to avoid Elemental Ailments                                                                  Monsters have of Insulation" },
		{ val = "of Miring", label = "Enemy has inc. Accuracy: / Players have to amount of Suppressed Spell Damage Prevented                                                                  Monsters increased Rating minus of Miring" },
		{ val = "of Miring UBER", label = "Less Global Defences                                                                  Players have to of Miring UBER", range = true },
		{ val = "of Rust", label = "Reduced Block Chance / less Armour                                                                  Players have to of Rust" },
		{ val = "of Smothering", label = "Less Recovery Rate of ^xE05030Life ^7and ^x88FFFFEnergy Shield                                                                  Players have of Smothering" },
		{ val = "of Stasis", label = "Cannot Regenerate ^xE05030Life^7, ^x7070FFMana ^7or ^x88FFFFES                                                                  Players Life, Energy Shield of Stasis" },
		{ val = "of Toughness", label = "Enemy takes reduced Extra Crit Damage                                                                  Monsters from Critical Strikes of Toughness", range = true },
		{ val = "of Toughness UBER", label = "Enemy takes reduced Extra Crit Damage                                                                  Monsters from Critical Strikes of Toughness UBER", range = true },
		{ val = "of Fatigue", label = "Less Cooldown Recovery Rate                                                                 Players have of Fatigue" },
		{ val = "of Doubt", label = "Reduced Non-Curse Aura Effect                                                                  Players have Non-Curse Auras from Skills of Doubt" },
		{ val = "of Imprecision", label = "Less Accuracy Rating                                                                  Players have of Imprecision" },
		{ val = "of Venom", label = "Enemy chance to Poison on Hit                                                                  Monsters of Venom" },
		{ val = "of Deadliness", label = "Enemy Critical Strike                                                                  Monsters have to increased Chance Multiplier of Deadliness", range = true },
		{ val = "of Deadliness UBER", label = "Enemy Critical Strike                                                                  Monsters have to increased Chance Multiplier of Deadliness UBER", range = true },
	},
}