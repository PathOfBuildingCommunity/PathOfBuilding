-- This is currently made by hand but should be auto generated
-- Item data (c) Grinding Gear Games

local t_insert = table.insert
local s_format = string.format


local mapTierCache = { }
local mapTiers = {"Low", "Med", "High", "T17"}
local tooltipGenerator = function(affixData, tier)
	local tooltip = {}
	if #affixData.tooltipLines > 0 then
		if affixData.type == "check" then
			for _, line in ipairs(affixData.tooltipLines) do
				t_insert(tooltip, {14, '^7'..line})
			end
		elseif affixData.type == "list" then
			if affixData.values[tier] then
				t_insert(tooltip, {16, '^7'..mapTiers[tier]..": "})
				for i, line in ipairs(affixData.tooltipLines) do
					local modValue = (#affixData.tooltipLines > 1) and affixData.values[tier][i] or affixData.values[tier]
					if modValue == nil then
						t_insert(tooltip, {14, '   ^7'..line})
					elseif modValue ~= 0 then
						t_insert(tooltip, {14, '   ^7'..s_format(line, modValue)})
					end
				end
			end
		elseif affixData.type == "count" then
			if affixData.values[tier] then
				t_insert(tooltip, {16, '^7'..mapTiers[tier]..": "})
				for i, line in ipairs(affixData.tooltipLines) do
					local modValue = {(#affixData.tooltipLines > 1) and (affixData.values[tier][i] and affixData.values[tier][i][1] or nil) or affixData.values[tier][1], (#affixData.tooltipLines > 1) and (affixData.values[tier][i] and affixData.values[tier][i][2] or nil) or affixData.values[tier][2]}
					if modValue[2] == nil then
						t_insert(tooltip, {14, '   ^7'..line})
					elseif modValue[2] ~= 0 then
						t_insert(tooltip, {14, '   ^7'..s_format(line, modValue[1], modValue[2])})
					end
				end
			end
		end
	end
	return (#tooltip > 0) and tooltip
end


return {
	AffixData = {
		-- defensive prefixes
		["Armoured"] = {
			order = 1,
			modType= "Prefix",
			type = "list",
			label = "Enemy Physical Damage reduction                                                                  Monster Armoured",
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
		["Cycling UBER"] = {
			order = 2,
			modType= "Prefix",
			type = "check",
			label = "Players Deal no Damage 3 out of 10 seconds                                                                  and their Minions for every Cycling UBER",
			tooltipLines = { "Players and their Minions deal no damage for 3 out of every 10 seconds" },
			apply = function(val, mapModEffect, modList, enemyModList)
				modList:NewMod("DPS", "MORE", -30, "Map mod Cycling")
			end,
		},
		["Hexproof"] = {
			order = 3,
			modType= "Prefix",
			type = "check",
			label = "Enemy is Hexproof?                                                                  Monsters are Hexproof",
			tooltipLines = { "Monsters are Hexproof" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("Hexproof", "FLAG", true, "Map mod Hexproof")
			end,
		},
		["Hexwarded"] = {
			order = 4,
			modType= "Prefix",
			type = "list",
			label = "Less effect of Curses on enemy                                                                  Monsters Hexwarded",
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
			order = 5,
			modType= "Prefix",
			type = "list",
			label = "Enemy has Elemental / ^xD02090Chaos ^7Resist                                                                  Monster Resistance Resistances Resistant",
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
			order = 6,
			modType= "Prefix",
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
			order = 7,
			modType= "Prefix",
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
			order = 8,
			modType= "Prefix",
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
			order = 9,
			modType= "Prefix",
			type = "check",
			label = "Enemy Cannot Be Slowed                                                                  Monsters Taunted Monsters' Action Speed modified below Base Value Movement Unstoppable",
			tooltipLines = { "Monsters cannot be Taunted", "Monsters' Action Speed cannot be modified to below Base Value", "Monsters' Movement Speed cannot be modified to below Base Value" },
			apply = function(val, mapModEffect, modList, enemyModList)
				-- MISSING: Monsters cannot be Taunted
				enemyModList:NewMod("MinimumActionSpeed", "MAX", 100, "Map mod Unstoppable")
			end,
		},
		["Impervious"] = {
			order = 10,
			modType= "Prefix",
			type = "list",
			label = "Enemy chance to avoid Poison and Bleed                                                                  Monsters have Poison, Impale, Bleeding Impervious",
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
			order = 11,
			modType= "Prefix",
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
			order = 12,
			modType= "Prefix",
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
			order = 13,
			modType= "Prefix",
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
			order = 14,
			modType= "Prefix",
			type = "count",
			tooltipLines = { "Monsters gain (%d to %d)%% of Maximum Life as Extra Maximum Energy Shield" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("LifeGainAsEnergyShield", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Buffered")
			end,
			values = {
				[4] = { 70, 80 },
			},
		},
		["Stalwart UBER"] = {
			order = 15,
			modType= "Prefix",
			type = "list",
			label = "Enemy Block Chance                                                                  Monsters have to Attack Damage Stalwart UBER",
			tooltipLines = { "Monsters have +%d%% Chance to Block Attack Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("BlockChance", "BASE", values[val] * mapModEffect, "Map mod Stalwart", ModFlag.Attack)
			end,
			values = {
				[4] = 50,
			},
		},
		["Titan's"] = {
			order = 16,
			modType= "Prefix",
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
			order = 17,
			modType= "Prefix",
			type = "count",
			label = "Enemy Increased Damage                                                                  to Monster Savage",
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
			order = 18,
			modType= "Prefix",
			type = "count",
			label = "Enemy Increased Damage                                                                  to Monster Savage UBER",
			tooltipLines = { "(%d to %d)%% increased Monster Damage" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Damage", "INC", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Savage")
			end,
			values = {
				[4] = { 30, 40 },
			},
		},
		["Burning"] = {
			order = 19,
			modType= "Prefix",
			type = "count",
			label = "Enemy Physical As Extra Fire                                                                  Monsters deal to Damage Burning",
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
			order = 20,
			modType= "Prefix",
			type = "count",
			label = "Enemy Physical As Extra Cold                                                                  Monsters deal to Damage Freezing",
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
			order = 21,
			modType= "Prefix",
			type = "count",
			label = "Enemy Physical As Extra Lightning                                                                  Monsters deal to Damage Shocking",
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
			order = 22,
			modType= "Prefix",
			type = "count",
			label = "Enemy Physical As Extra Chaos                                                                  Monsters gain to their Damage Inflict Withered for seconds Hit Profane",
			tooltipLines = { "Monsters gain (%d to %d)%% of their Physical Damage as Extra Chaos Damage", "Monsters Inflict Withered for 10 seconds on Hit" },
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
			order = 23,
			modType= "Prefix",
			type = "count",
			label = "Enemy Physical As Extra Chaos                                                                  Monsters gain to their Damage Profane UBER",
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
		["Prismatic UBER"] = {
			order = 24,
			modType= "Prefix",
			type = "count",
			label = "Enemy Physical As Extra Random                                                                  Monsters gain to of their Damage Element Prismatic UBER",
			tooltipLines = { "Monsters gain (%d to %d)%% of their Physical Damage as Extra Damage of a random Element" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				if values[val] then
					enemyModList:NewMod("PhysicalDamageGainAsRandom", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Prismatic")
				end
			end,
			values = {
				[4] = { 180, 200 },
			},
		},
		["Fleet"] = {
			order = 25,
			modType= "Prefix",
			type = "count",
			label = "Enemy Increased Speed                                                                  to Monster Movement Attack Cast Fleet",
			tooltipLines = { "(%d to %d)%% increased Monster Movement Speed", "(%d to %d)%% increased Monster Attack Speed", "(%d to %d)%% increased Monster Cast Speed" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				-- attack and cast is the same so applying it once, movespeed does not matter
				enemyModList:NewMod("Speed", "INC", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100) * mapModEffect, "Map mod Fleet")
			end,
			values = {
				[1] = { { 15, 20 }, { 20, 25 }, { 20, 25 } },
				[2] = { { 20, 25 }, { 25, 35 }, { 25, 35 } },
				[3] = { { 25, 30 }, { 35, 45 }, { 35, 45 } },
				[4] = { { 25, 30 }, { 35, 45 }, { 35, 45 } },
			},
		},
		["Equalising UBER"] = {
			order = 27,
			modType= "Prefix",
			type = "list",
			tooltipLines = { "Rare and Unique Monsters remove %d%% of Life, Mana and Energy Shield from Players or their Minions on Hit" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end,
			values = {
				[4] = 5,
			},
		},
		["Afflicting UBER"] = {
			order = 28,
			modType= "Prefix",
			type = "check",
			label = "Enemy Hits always Ignites, Freezes and Shocks                                                                  All Monster Damage can Ignite, Monsters Afflicting UBER",
			tooltipLines = { "All Monster Damage can Ignite, Freeze and Shock", "Monsters Ignite, Freeze and Shock on Hit" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("IgniteChance", "BASE", 100, "Map mod Afflicting")
				enemyModList:NewMod("AllDamageIgnites", "FLAG", true, "Map mod Afflicting")
			end,
		},
		["Conflagrating"] = {
			order = 29,
			modType= "Prefix",
			type = "check",
			label = "Enemy Hits always Ignites                                                                  All Monster Damage from Conflagrating",
			tooltipLines = { "All Monster Damage from Hits always Ignites" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("IgniteChance", "BASE", 100, "Map mod Conflagrating")
				enemyModList:NewMod("AllDamageIgnites", "FLAG", true, "Map mod Conflagrating")
			end,
		},
		["Impaling"] = {
			order = 30,
			modType= "Prefix",
			type = "list",
			label = "Enemy chance to Impale                                                                  Monsters' Attacks have Hit Impaling",
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
			order = 31,
			modType= "Prefix",
			type = "list",
			label = "Enemy chance to Impale                                                                  Monsters' Attacks Hit When fifth is inflicted Player, Impales are removed Reflect their Physical Damage multiplied by remaining Hits that and Allies within metres Impaling UBER",
			tooltipLines = { "Monsters' Attacks Impale on Hit", "When a fifth Impale is inflicted on a Player, Impales are removed to Reflect their Physical Damage multiplied by their remaining Hits to that Player and their Allies within X metres" },
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
			order = 32,
			modType= "Prefix",
			type = "list",
			label = "Enemy Elemental Ailments chance on Hit                                                                  Monsters have to Ignite, Freeze and Shock Empowered",
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
			order = 33,
			modType= "Prefix",
			type = "list",
			label = "Boss Increased Damage / Speed                                                                  Unique deals has Attack and Cast Overlord's",
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
			order = 34,
			modType= "Prefix",
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
			order = 35,
			modType= "Prefix",
			type = "list",
			tooltipLines = { "Monsters reflect %d%% of Physical Damage", "Monsters reflect %d%% of Elemental Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end,
			values = {
				[4] = { 20, 20 },
			},
		},
		["Mirrored"] = {
			order = 36,
			modType= "Prefix",
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
			order = 37,
			modType= "Suffix",
			type = "check",
			OldLabel = "Player has Elemental Equilibrium?",
			tooltipLines = { "Players cannot inflict Exposure" },
			apply = function(val, mapModEffect, modList, enemyModList)
				-- Players cannot inflict Exposure
				-- modList:NewMod("Keystone", "LIST", "Elemental Equilibrium", "Map mod of Balance") -- OLD MOD
			end,
		},
		["of Congealment"] = {
			order = 38,
			modType= "Suffix",
			type = "check",
			label = "Cannot Leech ^xE05030Life ^7/ ^x7070FFMana                                                                  Monsters be Leeched from of Congealment",
			tooltipLines = { "Monsters cannot be Leeched from" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("CannotLeechLifeFromSelf", "FLAG", true, "Map mod of Congealment")
				enemyModList:NewMod("CannotLeechManaFromSelf", "FLAG", true, "Map mod of Congealment")
				--missing cannot leech es?
			end,
		},
		["of Drought"] = {
			order = 39,
			modType= "Suffix",
			type = "list",
			label = "Gain reduced Flask Charges                                                                  Players of Drought",
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
			order = 40,
			modType= "Suffix",
			type = "count",
			label = "-X% maximum Resistances                                                                  Players have minus to all of Exposure",
			tooltipLines = { "Players have minus (%d to %d)%% to all maximum Resistances" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				if values[val] then
					local roll = (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect
					modList:NewMod("FireResistMax", "BASE", -roll, "Map mod of Exposure")
					modList:NewMod("ColdResistMax", "BASE", -roll, "Map mod of Exposure")
					modList:NewMod("LightningResistMax", "BASE", -roll, "Map mod of Exposure")
					modList:NewMod("ChaosResistMax", "BASE", -roll, "Map mod of Exposure")
				end
			end,
			values = {
				[2] = { 5, 8 },
				[3] = { 9, 12 },
				[4] = { 9, 12 },
			},
		},
		["of Exposure UBER"] = {
			order = 41,
			modType= "Suffix",
			type = "list",
			label = "-X% maximum Resistances                                                                  Players have minus to all of Exposure UBER",
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
		["of Penetration UBER"] = {
			order = 42,
			modType= "Suffix",
			type = "list",
			label = "Enemy Penetrates Elemental Resistances                                                                  Monster Damage of Penetration UBER",
			tooltipLines = { "Monster Damage Penetrates %d%% Elemental Resistances" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
					enemyModList:NewMod("ElementalPenetration", "BASE", values[val] * mapModEffect, "Map mod Penetration")
			end,
			values = {
				[4] = 15,
			},
		},
		["of Impotence"] = {
			order = 43,
			modType= "Suffix",
			type = "list",
			label = "Less Area of Effect:                                                                  Players have of Impotence",
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
			order = 44,
			modType= "Suffix",
			type = "count",
			label = "Less Area of Effect:                                                                  Players have to of Impotence UBER",
			tooltipLines = { "Players have (%d to %d)%% less Area of Effect" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				if val == 4 then
					modList:NewMod("AreaOfEffect", "MORE", -(values[val][1] + (values[val][2] - values[val][1]) * 100 / 100) * mapModEffect, "Map mod of Impotence")
				end
			end,
			values = {
				[4] = { 25, 30 },
			},
		},
		["of Insulation"] = {
			order = 45,
			modType= "Suffix",
			type = "list",
			label = "Enemy chance to avoid Elemental Ailments                                                                  Monsters have of Insulation",
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
			order = 46,
			modType= "Suffix",
			type = "list",
			label = "Enemy has inc. Accuracy: / Players have to amount of Suppressed Spell Damage Prevented                                                                  Monsters increased Rating minus of Miring",
			tooltipLines = { "Players have minus %d%% to amount of Suppressed Spell Damage Prevented", "Monsters have %d%% increased Accuracy Rating" },
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
			order = 47,
			modType= "Suffix",
			type = "count",
			label = "Less Global Defences                                                                  Players have to of Miring UBER",
			tooltipLines = { "Players have (%d to %d)%% less Defences" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				modList:NewMod("Defences", "MORE", -(values[val][1] + (values[val][2] - values[val][1]) * 100 / 100) * mapModEffect, "Map mod of Miring")
			end,
			values = {
				[4] = { 25, 30 },
			},
		},
		["of Rust"] = {
			order = 48,
			modType= "Suffix",
			type = "list",
			label = "Reduced Block Chance / less Armour                                                                  Players have to of Rust",
			tooltipLines = { "Players have %d%% reduced Chance to Block", "Players have %d%% less Armour" },
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
			order = 49,
			modType= "Suffix",
			type = "list",
			label = "Less Recovery Rate of ^xE05030Life ^7and ^x88FFFFEnergy Shield                                                                  Players have of Smothering",
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
			order = 50,
			modType= "Suffix",
			type = "check",
			label = "Cannot Regenerate ^xE05030Life^7, ^x7070FFMana ^7or ^x88FFFFES                                                                  Players Life, Energy Shield of Stasis",
			tooltipLines = { "Players cannot Regenerate Life, Mana or Energy Shield" },
			apply = function(val, mapModEffect, modList, enemyModList)
				modList:NewMod("NoLifeRegen", "FLAG", true, "Map mod of Stasis")
				modList:NewMod("NoEnergyShieldRegen", "FLAG", true, "Map mod of Stasis")
				modList:NewMod("NoManaRegen", "FLAG", true, "Map mod of Stasis")
			end,
		},
		["of Toughness"] = {
			order = 51,
			modType= "Suffix",
			type = "count",
			label = "Enemy takes reduced Extra Crit Damage                                                                  Monsters from Critical Strikes of Toughness",
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
			order = 52,
			modType= "Suffix",
			type = "count",
			label = "Enemy takes reduced Extra Crit Damage                                                                  Monsters from Critical Strikes of Toughness UBER",
			tooltipLines = { "Monsters take (%d to %d)%% reduced Extra Damage from Critical Strikes" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("SelfCritMultiplier", "INC", -(values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod of Toughness")
			end,
			values = {
				[4] = { 35, 45 },
			},
		},
		["of Fatigue"] = {
			order = 53,
			modType= "Suffix",
			type = "list",
			label = "Less Cooldown Recovery Rate                                                                  Players have of Fatigue",
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
		["of Deceleration UBER"] = {
			order = 54,
			modType= "Suffix",
			type = "list",
			label = "Reduced Action Speed for each Skill used Recently                                                                  Players have time they've of Deceleration UBER",
			tooltipLines = { "Players have %d%% reduced Action Speed for each time they've used a Skill Recently" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("ActionSpeed", "INC", -values[val] * mapModEffect, "Map mod of Deceleration", { type = "Multiplier", var = "SkillUsedRecently" })
			end,
			values = {
				[4] = 3,
			},
		},
		["of Revolt UBER"] = {
			order = 55,
			modType= "Suffix",
			type = "list",
			label = "Less Minion Speed                                                                  Players' Minions have less Attack Cast Movement of Revolt UBER",
			tooltipLines = { "Players' Minions have %d%% less Attack Speed", "Players' Minions have %d%% less Cast Speed", "Players' Minions have %d%% less Movement Speed" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Speed", "MORE", -values[val][1] * mapModEffect, "Map mod of Revolt", ModFlag.Attack) }, "Map mod of Revolt")
				modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("Speed", "MORE", -values[val][2] * mapModEffect, "Map mod of Revolt", ModFlag.Cast) }, "Map mod of Revolt")
				modList:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("MovementSpeed", "MORE", -values[val][3] * mapModEffect, "Map mod of Revolt") }, "Map mod of Revolt")
			end,
			values = {
				[4] = { 50, 50, 50 },
			},
		},
		["of Defiance UBER"] = {
			order = 56,
			modType= "Suffix",
			type = "list",
			tooltipLines = { "Debuffs on Monsters expire %d%% faster" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end,
			values = {
				[4] = 100,
			},
		},
		["of Transience"] = {
			order = 57,
			modType= "Suffix",
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
			order = 58,
			modType= "Suffix",
			type = "list",
			tooltipLines = { "Buffs on Players expire %d%% faster" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end,
			values = {
				[4] = 100,
			},
		},
		["of Doubt"] = {
			order = 59,
			modType= "Suffix",
			type = "list",
			label = "Reduced Non-Curse Aura Effect                                                                  Players have Auras from Skills of Doubt",
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
			order = 60,
			modType= "Suffix",
			type = "list",
			label = "Less Accuracy Rating                                                                  Players have of Imprecision",
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
			order = 61,
			modType= "Suffix",
			type = "check",
			tooltipLines = { "Monsters Blind on Hit" },
			apply = function(val, mapModEffect, modList, enemyModList)
				--SHOULD THIS BE SUPPORTED? (as a flag to make "are you blinded" show on config?)
			end,
		},
		["of Venom"] = {
			order = 62,
			modType= "Suffix",
			type = "check",
			label = "Enemy chance to Poison on Hit                                                                  Monsters of Venom",
			tooltipLines = { "Monsters Poison on Hit" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("PoisonChance", "BASE", 100, "Map mod of Venom")
			end,
		},
		["of Deadliness"] = {
			order = 63,
			modType= "Suffix",
			type = "count",
			label = "Enemy Critical Strike                                                                  Monsters have to increased Chance Multiplier of Deadliness",
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
			order = 64,
			modType= "Suffix",
			type = "count",
			label = "Enemy Critical Strike                                                                  Monsters have to increased Chance Multiplier of Deadliness UBER",
			tooltipLines = { "Monsters have (%d to %d)%% increased Critical Strike Chance", "+(%d to %d)%% to Monster Critical Strike Multiplier" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("CritChance", "INC", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100) * mapModEffect, "Map mod of Deadliness")
				enemyModList:NewMod("CritMultiplier", "BASE", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100) * mapModEffect, "Map mod of Deadliness")
			end,
			values = {
				[4] = { { 650, 700 }, { 70, 75 } },
			},
		},
		-- Cleansing Altar
		-- Cleansing Altar Boss
		["CleansingAltarDownsideBossArmour"] = {
			type = "list",
			tooltipLines = { "+%d to Armour" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Armour", "BASE", values[val], "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = 50000,
			},
		},
		["CleansingAltarDownsideBossIncreasedArmourAndEvasion"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% increased Armour", "(%d to %d)%% increased Evasion Rating" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Armour", "INC", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("Evasion", "INC", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { { 100, 200 }, { 100, 200 } },
			},
		},
		["CleansingAltarDownsideBossFireAndChaosResist"] = {
			type = "list",
			tooltipLines = { "+%d%% to Fire Resistance", "+%d%% to maximum Fire Resistance", "+%d%% to Chaos Resistance", "+%d%% to maximum Chaos Resistance" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("FireResist", "BASE", values[val][1], "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("FireResistMax", "BASE", values[val][2], "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("ChaosResist", "BASE", values[val][3], "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("ChaosResistMax", "BASE", values[val][4], "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { 80, 10, 80, 10 },
			},
		},
		["CleansingAltarDownsideBossPenetrateElementalResist"] = {
			type = "count",
			tooltipLines = { "Gain (%d to %d)%% of Physical Damage as Extra Damage of a random Element", "Damage Penetrates (%d to %d)%% of Enemy Elemental Resistances" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsRandom", "BASE", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("ElementalPenetration", "BASE", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { { 15, 25 }, { 50, 80 } },
			},
		},
		["CleansingAltarDownsideBossPhysToAddAsChaos"] = {
			type = "count",
			tooltipLines = { "Gain (%d to %d)%% of Physical Damage as Extra Chaos Damage", "Poison on Hit", "All Damage from Hits can Poison" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsChaos", "BASE", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("PoisonChance", "BASE", 100, "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("AllDamagePoisons", "FLAG", true, "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { { 70, 130 } },
			},
		},
		["CleansingAltarDownsideBossPhysToAddAsFire"] = {
			type = "count",
			tooltipLines = { "Gain (%d to %d)%% of Physical Damage as Extra Fire Damage", "Hits always Ignite", "All Damage can Ignite" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsFire", "BASE", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("IgniteChance", "BASE", 100, "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("AllDamageIgnites", "FLAG", true, "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { { 70, 130 } },
			},
		},
		-- Cleansing Altar Monster
		-- Cleansing Altar Player
		["CleansingAltarDownsidePlayerIncreasedFlaskChargesUsed"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% increased Flask Charges used", "(%d to %d)%% reduced Flask Effect Duration" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				modList:NewMod("FlaskChargesUsed", "INC", (values[val][1][2] + (values[val][1][1] - values[val][1][2]) * rollRange / 100), "Altar Player Downside")
				modList:NewMod("FlaskDuration", "INC", -(values[val][2][2] + (values[val][2][1] - values[val][2][2]) * rollRange / 100), "Altar Player Downside")
			end,
			values = {
				[1] = { { 20, 40 }, { 60, 40 } },
			},
		},
		["CleansingAltarDownsidePlayerChaosDegenDuringFlaskDuration"] = {
			type = "list",
			tooltipLines = { "Take %d Chaos Damage per second during any Flask Effect" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("ChaosDegen", "BASE", values[val], "Altar Player Downside", { type = "Condition", var = "UsingFlask" })
			end,
			values = {
				[1] = 600,
			},
		},
		["CleansingAltarDownsidePlayerChaosMonsterAura"] = {
			type = "list",
			tooltipLines = { "Nearby Enemies Gain %d%% of their Physical Damage as Extra Chaos Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsChaos", "BASE", values[val], "Altar Player Downside")
			end,
			values = {
				[1] = 100,
			},
		},
		["CleansingAltarDownsidePlayerFireMonsterAura"] = {
			type = "list",
			tooltipLines = { "Nearby Enemies Gain %d%% of their Physical Damage as Extra Fire Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsFire", "BASE", values[val], "Altar Player Downside")
			end,
			values = {
				[1] = 100,
			},
		},
		["CleansingAltarDownsidePlayerReducedArmourAndEvasion"] = {
			type = "list",
			tooltipLines = { "minus %d to Armour", "minus %d to Evasion Rating" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("Armour", "BASE", -values[val][1], "Altar Player Downside")
				modList:NewMod("Evasion", "BASE", -values[val][2], "Altar Player Downside")
			end,
			values = {
				[1] = { 3000, 3000 },
			},
		},
		["CleansingAltarDownsidePlayerReducedFireAndChaosResist"] = {
			type = "count",
			tooltipLines = { "-(%d to %d)%% to Fire Resistance", "-(%d to %d)%% to Chaos Resistance" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				local roll = (values[val][1][2] + (values[val][1][1] - values[val][1][2]) * rollRange / 100)
				modList:NewMod("FireResist", "BASE", -roll, "Altar Player Downside")
				modList:NewMod("ChaosResist", "BASE", -roll, "Altar Player Downside")
			end,
			values = {
				[1] = { { 60, 40 }, { 60, 40 } },
			},
		},
		["CleansingAltarDownsidePlayerScorched"] = {
			type = "count",
			tooltipLines = { "All Damage taken from Hits can Scorch you", "(%d to %d)%% chance to be Scorched when Hit" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
			end,
			values = {
				[1] = { 25, 35 },
			},
		},
		-- Tangled Altar
		-- Tangled Altar Boss
		["TangledAltarDownsideBossMaxLifeAsEnergyShield"] = {
			type = "count",
			tooltipLines = { "Gain (%d to %d)%% of Maximum Life as Extra Maximum Energy Shield" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("LifeGainAsEnergyShield", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { 50, 70 },
			},
		},
		["TangledAltarDownsideBossPhysicalDamageReduction"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% additional Physical Damage Reduction" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageReduction", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { 50, 70 },
			},
		},
		["TangledAltarDownsideBossSuppressSpells"] = {
			type = "count",
			tooltipLines = { "+%d%% chance to Suppress Spell Damage", "Prevent +(%d to %d)%% of Suppressed Spell Damage" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("SpellSuppressionChance", "BASE", values[val][1][1], "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("SpellSuppressionEffect", "BASE", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { { 100 }, { 20, 30 } },
			},
		},
		["TangledAltarDownsideBossColdAndLightningResist"] = {
			type = "list",
			tooltipLines = { "+%d%% to Cold Resistance", "+%d%% to maximum Cold Resistance", "+%d%% to Lightning Resistance", "+%d%% to maximum Lightning Resistance" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("ColdResist", "BASE", values[val][1], "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("ColdResistMax", "BASE", values[val][2], "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("LightningResist", "BASE", values[val][3], "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("LightningResistMax", "BASE", values[val][4], "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { 80, 10, 80, 10 },
			},
		},
		["TangledAltarDownsideBossPenetrateElementalResistances"] = {
			type = "count",
			tooltipLines = { "Damage Penetrates (%d to %d)%% of Enemy Elemental Resistances", "Gain (%d to %d)%% of Physical Damage as Extra Damage of a random Element" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsRandom", "BASE", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("ElementalPenetration", "BASE", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { { 15, 25 }, { 50, 80 } },
			},
		},
		["TangledAltarDownsideBossPhysToAddAsCold"] = {
			type = "count",
			tooltipLines = { "Gain (%d to %d)%% of Physical Damage as Extra Cold Damage", "All Damage with Hits can Chill" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsCold", "BASE", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { { 70, 130 } },
			},
		},
		["TangledAltarDownsideBossPhysToAddAsLightning"] = {
			type = "count",
			tooltipLines = { "Gain (%d to %d)%% of Physical Damage as Extra Lightning Damage", "Hits always Shock", "All Damage can Shock" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsLightning", "BASE", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100), "Altar Boss Downside", { type = "Condition", var = "RareOrUnique" })
			end,
			values = {
				[1] = { { 70, 130 } },
			},
		},
		-- Tangled Altar Monster
		-- Tangled Altar Player
		["TangledAltarDownsidePlayerReducedPhysicalDamageReduction"] = {
			type = "count",
			tooltipLines = { "minus (%d to %d)%% additional Physical Damage Reduction" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				modList:NewMod("PhysicalDamageReduction", "BASE", -(values[val][2] + (values[val][1] - values[val][2]) * rollRange / 100), "Altar Player Downside")
			end,
			values = {
				[1] = { 60, 40 },
			},
		},
		["TangledAltarDownsidePlayerReducedColdAndLightningResist"] = {
			type = "count",
			tooltipLines = { "-(%d to %d)%% to Cold Resistance", "-(%d to %d)%% to Lightning Resistance" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				local roll = (values[val][1][2] + (values[val][1][1] - values[val][1][2]) * rollRange / 100)
				modList:NewMod("ColdResist", "BASE", -roll, "Altar Player Downside")
				modList:NewMod("LightningResist", "BASE", -roll, "Altar Player Downside")
			end,
			values = {
				[1] = { { 60, 40 }, { 60, 40 } },
			},
		},
		["TangledAltarDownsidePlayerTaintedEndurance"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% reduced Recovery Rate of Life, Mana and Energy Shield per Endurance Charge" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				local roll = (values[val][2] + (values[val][1] - values[val][2]) * rollRange / 100)
				modList:NewMod("LifeRecoveryRate", "INC", -roll, "Altar Player Downside", { type = "Multiplier", var = "EnduranceCharge" })
				modList:NewMod("ManaRecoveryRate", "INC", -roll, "Altar Player Downside", { type = "Multiplier", var = "EnduranceCharge" })
				modList:NewMod("EnergyShieldRecoveryRate", "INC", -roll, "Altar Player Downside", { type = "Multiplier", var = "EnduranceCharge" })
			end,
			values = {
				[1] = { 20, 10 },
			},
		},
		["TangledAltarDownsidePlayerTaintedFrenzy"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% reduced Defences per Frenzy Charge" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				modList:NewMod("Defences", "INC", -(values[val][2] + (values[val][1] - values[val][2]) * rollRange / 100), "Altar Player Downside", { type = "Multiplier", var = "FrenzyCharge" })
			end,
			values = {
				[1] = { 50, 30 },
			},
		},
		["TangledAltarDownsidePlayerTaintedPower"] = {
			type = "count",
			tooltipLines = { "-(%d to %d)%% to Critical Strike Multiplier per Power Charge" },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				modList:NewMod("CritMultiplier", "BASE", -(values[val][2] + (values[val][1] - values[val][2]) * rollRange / 100), "Altar Player Downside", { type = "Multiplier", var = "PowerCharge" })
			end,
			values = {
				[1] = { 40, 20 },
			},
		},
		["TangledAltarDownsidePlayerColdMonsterAura"] = {
			type = "list",
			tooltipLines = { "Nearby Enemies Gain %d%% of their Physical Damage as Extra Cold Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsCold", "BASE", values[val], "Altar Player Downside")
			end,
			values = {
				[1] = 100,
			},
		},
		["TangledAltarDownsidePlayerLightningMonsterAura"] = {
			type = "list",
			tooltipLines = { "Nearby Enemies Gain %d%% of their Physical Damage as Extra Lightning Damage" },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsLightning", "BASE", values[val], "Altar Player Downside")
			end,
			values = {
				[1] = 100,
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
		-- other CleansingAltares
		["CleansingAltarDownsideBossConsecrateOnHit"] = { }, -- Create Consecrated Ground on Hit, lasting 6 seconds
		["CleansingAltarDownsideBossCoveredInAshOnHit"] = { }, -- Gain (50-80)% of Physical Damage as Extra Fire Damage", "Cover Enemies in Ash on Hit
		["CleansingAltarDownsideBossHinderAura"] = { }, -- Nearby Enemies are Hindered, with 40% reduced Movement Speed
		["CleansingAltarDownsideBossRemoveFlaskChargeOnHit"] = { }, -- Enemies lose 6 Flask Charges every 3 seconds and cannot gain Flask Charges for 6 seconds after being Hit
		["CleansingAltarDownsideMonsterArmour"] = { }, -- +50000 to Armour
		["CleansingAltarDownsideMonsterBurningGroundOnDeath"] = { }, -- Drops Burning Ground on Death, lasting 3 seconds
		["CleansingAltarDownsideMonsterChaosDamage"] = { }, -- Gain (70-130)% of Physical Damage as Extra Chaos Damage
		["CleansingAltarDownsideMonsterConsecratedGroundOnDeath"] = { }, -- Create Consecrated Ground on Death, lasting 6 seconds
		["CleansingAltarDownsideMonsterExposureOnHit"] = { }, -- Gain (70-130)% of Physical Damage as Extra Damage of a random Element", "Inflict Fire, Cold, and Lightning Exposure on Hit
		["CleansingAltarDownsideMonsterFireAndChaosResist"] = { }, -- +10% to maximum Fire Resistance", "+80% to Fire Resistance", "+10% to maximum Chaos Resistance", "+80% to Chaos Resistance
		["CleansingAltarDownsideMonsterFireDamage"] = { }, -- Gain (70-130)% of Physical Damage as Extra Fire Damage
		["CleansingAltarDownsideMonsterFlaskDegenOnHit"] = { }, -- Enemies lose 6 Flask Charges every 3 seconds and cannot gain Flask Charges for 6 seconds after being Hit
		["CleansingAltarDownsideMonsterIncreasedArea"] = { }, -- (70-130)% increased Area of Effect
		["CleansingAltarDownsideMonsterIncreasedEvasion"] = { }, -- (250-500)% increased Evasion Rating
		["CleansingAltarDownsidePlayerBurningGroundWhenHit"] = { }, -- (15-20)% chance for Enemies to drop Burning Ground when Hitting you, no more than once every 2 seconds
		["CleansingAltarDownsidePlayerCurseReflect"] = { }, -- Curses you inflict are reflected back to you
		["CleansingAltarDownsidePlayerMeteorOnFlaskUse"] = { }, -- 30% chance to be targeted by a Meteor when you use a Flask
		-- other TangledAltares
		["TangledAltarDownsideBossBlindOnHit"] = { }, -- 100% Global chance to Blind Enemies on hit", "(100-200)% increased Blind Effect
		["TangledAltarDownsideBossCoveredInFrostOnHit"] = { }, -- Gain (50-80)% of Physical Damage as Extra Cold Damage", "Cover Enemies in Frost on Hit
		["TangledAltarDownsideMonsterChilledGroundOnDeath"] = { }, -- Drops Chilled Ground on Death, lasting 3 seconds
		["TangledAltarDownsideMonsterColdAndLightningResist"] = { }, -- +10% to maximum Cold Resistance", "+80% to Cold Resistance", "+10% to maximum Lightning Resistance", "+80% to Lightning Resistance
		["TangledAltarDownsideMonsterColdDamage"] = { }, -- Gain (70-130)% of Physical Damage as Extra Cold Damage
		["TangledAltarDownsideMonsterExtraProjectiles"] = { }, -- Skills fire (3-5) additional Projectiles
		["TangledAltarDownsideMonsterGraspingVineStackOnHit"] = { }, -- Inflict 1 Grasping Vine on Hit
		["TangledAltarDownsideMonsterLightningDamage"] = { }, -- Gain (70-130)% of Physical Damage as Extra Lightning Damage
		["TangledAltarDownsideMonsterOverwhelm"] = { }, -- Hits have (50-80)% chance to ignore Enemy Physical Damage Reduction
		["TangledAltarDownsideMonsterPhysicalDamageReduction"] = { }, -- (50-80)% additional Physical Damage Reduction
		["TangledAltarDownsideMonsterRemoveChargeOnHit"] = { }, -- 100% chance to remove a random Charge from Enemy on Hit
		["TangledAltarDownsideMonsterShockedGroundOnDeath"] = { }, -- 100% chance to create Shocked Ground on Death, lasting 3 seconds
		["TangledAltarDownsideMonsterSpeed"] = { }, -- (30-50)% increased Attack Speed", "(30-50)% increased Cast Speed", "(30-50)% increased Movement Speed
		["TangledAltarDownsideMonsterSupressSpells"] = { }, -- Prevent +(20-30)% of Suppressed Spell Damage", "+100% chance to Suppress Spell Damage
		["TangledAltarDownsidePlayerChilledGroundWhenHit"] = { }, -- (25-35)% chance for Enemies to drop Chilled Ground when Hitting you, no more than once every 2 seconds
		["TangledAltarDownsidePlayerNonDamagingAilmentsReflectedToSelf"] = { }, -- Non-Damaging Ailments you inflict are reflected back to you
		["TangledAltarDownsidePlayerRandomProjectileDirection"] = { }, -- Projectiles are fired in random directions
		["TangledAltarDownsidePlayerSapped"] = { }, -- All Damage taken from Hits can Sap you", "(25-35)% chance to be Sapped when Hit
		["TangledAltarDownsidePlayerShockedGroundWhenHit"] = { }, -- (25-35)% chance for Enemies to drop Shocked Ground when Hitting you, no more than once every 2 seconds
	},
	Prefix = function(build)
		local List = {}
		local tier = (build.configTab and build.configTab.varControls["multiplierMapModTier"].selIndex or 4)
		if mapTierCache["Prefix"..tier] then
			return mapTierCache["Prefix"..tier]
		end
		for affixName, affix in pairs(data.mapMods.AffixData) do
			if affix.modType == "Prefix" and (affix.type == "check" or affix.values and affix.values[tier]) and affix.label then
				t_insert(List, { val = affixName, label = affix.label, tooltip = tooltipGenerator(affix, tier), range = (affix.type == "count") or nil})
			end
		end
		table.sort(List, function(a, b) return data.mapMods.AffixData[a.val].order < data.mapMods.AffixData[b.val].order end)
		mapTierCache["Prefix"..tier] = List
		return List
	end,
	Suffix = function(build)
		local List = {}
		local tier = (build.configTab and build.configTab.varControls["multiplierMapModTier"].selIndex or 4)
		if mapTierCache["Suffix"..tier] then
			return mapTierCache["Suffix"..tier]
		end
		for affixName, affix in pairs(data.mapMods.AffixData) do
			if affix.modType == "Suffix" and (affix.type == "check" or affix.values and affix.values[tier]) and affix.label then
				t_insert(List, { val = affixName, label = affix.label, tooltip = tooltipGenerator(affix, tier), range = (affix.type == "count") or nil})
			end
		end
		table.sort(List, function(a, b) return data.mapMods.AffixData[a.val].order < data.mapMods.AffixData[b.val].order end)
		mapTierCache["Suffix"..tier] = List
		return List
	end,
	CleansingAltar = {
		{ val = "ALLPLAYER", label = "All Player Downsides" },
		{ val = "CleansingAltarDownsideBossArmour", label = "Boss Armour                                                                  to CleansingAltarDownsideBossArmour" },
		{ val = "CleansingAltarDownsideBossIncreasedArmourAndEvasion", label = "Boss Increased Armour And Evasion Rating                                                                  to CleansingAltarDownsideBossIncreasedArmourAndEvasion", range = true },
		{ val = "CleansingAltarDownsideBossFireAndChaosResist", label = "Boss Fire and Chaos Resistances                                                                  to maximum CleansingAltarDownsideBossFireAndChaosResist" },
		--{ val = "CleansingAltarDownsideBossPenetrateElementalResist", label = "Boss Phys as Random and Penetration                                                                  Gain to of Physical Damage Extra Penetrates Enemy Resistances CleansingAltarDownsideBossPenetrateElementalResist", range = true },
		{ val = "CleansingAltarDownsideBossPhysToAddAsChaos", label = "Boss Physical As Chaos                                                                  Gain of Damage Extra Poison Hit All from Hits can CleansingAltarDownsideBossPhysToAddAsChaos", range = true },
		{ val = "CleansingAltarDownsideBossPhysToAddAsFire", label = "Boss Physical As Fire                                                                  Hits always Ignite Gain of Damage Extra All can CleansingAltarDownsideBossPhysToAddAsFire", range = true },
		{ val = "CleansingAltarDownsidePlayerIncreasedFlaskChargesUsed", label = "Reduced Flask Sustain                                                                  to Effect Duration CleansingAltarDownsidePlayerIncreasedFlaskChargesUsed", range = true },
		{ val = "CleansingAltarDownsidePlayerChaosDegenDuringFlaskDuration", label = "Chaos Degen During Flask                                                                  Take Damage per second any Effect CleansingAltarDownsidePlayerChaosDegenDuringFlaskDuration" },
		{ val = "CleansingAltarDownsidePlayerChaosMonsterAura", label = "Physical As Chaos Aura                                                                  Nearby Enemies Gain of their Damage Extra CleansingAltarDownsidePlayerChaosMonsterAura" },
		{ val = "CleansingAltarDownsidePlayerFireMonsterAura", label = "Physical As Fire Aura                                                                  Nearby Enemies Gain of their Damage Extra CleansingAltarDownsidePlayerFireMonsterAura" },
		{ val = "CleansingAltarDownsidePlayerReducedArmourAndEvasion", label = "Minus Armour and Evasion Rating                                                                  to CleansingAltarDownsidePlayerReducedArmourAndEvasion" },
		{ val = "CleansingAltarDownsidePlayerReducedFireAndChaosResist", label = "Minus Fire and Chaos Resistances                                                                  - to CleansingAltarDownsidePlayerReducedFireAndChaosResist", range = true },
	},
	TangledAltar = {
		{ val = "ALLPLAYER", label = "All Player Downsides" },
		{ val = "TangledAltarDownsideBossPhysicalDamageReduction", label = "Boss Physical Damage Reduction                                                                  to additional TangledAltarDownsideBossPhysicalDamageReduction", range = true },
		--{ val = "TangledAltarDownsideBossSuppressSpells", label = "Boss Spell Suppression                                                                  Prevent to of Suppressed Damage chance TangledAltarDownsideBossSuppressSpells", range = true },
		{ val = "TangledAltarDownsideBossColdAndLightningResist", label = "Boss Cold and Lightning Resistances                                                                  to maximum TangledAltarDownsideBossColdAndLightningResist" },
		--{ val = "TangledAltarDownsideBossPenetrateElementalResistances", label = "Boss Phys as Random and Penetration                                                                  Gain to of Physical Damage Extra Penetrates Enemy TangledAltarDownsideBossPenetrateElementalResistances", range = true },
		{ val = "TangledAltarDownsideBossPhysToAddAsCold", label = "Boss Physical As Cold                                                                  Gain of Damage Extra All with Hits can Chill TangledAltarDownsideBossPhysToAddAsCold", range = true },
		{ val = "TangledAltarDownsideBossPhysToAddAsLightning", label = "Boss Physical As Lightning                                                                  Hits always Shock Gain of Damage Extra All can TangledAltarDownsideBossPhysToAddAsLightning", range = true },
		{ val = "TangledAltarDownsidePlayerReducedPhysicalDamageReduction", label = "Minus Physical Damage Reduction                                                                  to additional TangledAltarDownsidePlayerReducedPhysicalDamageReduction", range = true },
		{ val = "TangledAltarDownsidePlayerReducedColdAndLightningResist", label = "Minus Cold and Lightning Resistances                                                                  - to TangledAltarDownsidePlayerReducedColdAndLightningResist", range = true },
		{ val = "TangledAltarDownsidePlayerTaintedEndurance", label = "Minus Recovery Rate Per Endurance Charge                                                                  to reduced of Life, Mana and Energy Shield TangledAltarDownsidePlayerTaintedEndurance", range = true },
		{ val = "TangledAltarDownsidePlayerTaintedFrenzy", label = "Minus Defences Per Frenzy Charge                                                                  to reduced TangledAltarDownsidePlayerTaintedFrenzy", range = true },
		{ val = "TangledAltarDownsidePlayerTaintedPower", label = "Minus Crit Multi Per Power Charge                                                                  - to Critical Strike Multiplier TangledAltarDownsidePlayerTaintedPower", range = true },
		{ val = "TangledAltarDownsidePlayerColdMonsterAura", label = "Physical As Cold Aura                                                                  Nearby Enemies Gain of their Damage Extra TangledAltarDownsidePlayerColdMonsterAura" },
		{ val = "TangledAltarDownsidePlayerLightningMonsterAura", label = "Physical As Lightning Aura                                                                  Nearby Enemies Gain of their Damage Extra TangledAltarDownsidePlayerLightningMonsterAura" },
	},
}