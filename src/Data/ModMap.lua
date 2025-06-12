-- This is currently made by hand but should be auto generated
-- Item data (c) Grinding Gear Games

return {
	AffixData = {
		-- defensive prefixes
		["Armoured"] = {
			type = "list",
			label = "Enemy Physical Damage reduction:",
			tooltipLines = { "+%d%% Monster Physical Damage Reduction" },
			values = { 20, 30, 40 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageReduction", "BASE", values[val] * mapModEffect, "Map mod Armoured")
			end
		},
		["Hexproof"] = {
			type = "check",
			label = "Enemy is Hexproof?",
			tooltipLines = { "Monsters are Hexproof" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("Hexproof", "FLAG", true, "Map mod Hexproof")
			end
		},
		["Hexwarded"] = {
			type = "list",
			label = "Less effect of Curses on enemy:",
			tooltipLines = { "%d%% less effect of Curses on Monsters" },
			values = { 25, 40, 60 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("CurseEffectOnSelf", "MORE", -values[val] * mapModEffect, "Map mod Hexwarded")
			end
		},
		["Resistant"] = {
			type = "list",
			label = "Enemy has Elemental / ^xD02090Chaos ^7Resist:",
			tooltipLines = { "+%d%% Monster Elemental Resistances", "+%d%% Monster Chaos Resistance" },
			values = { { 20, 15 }, { 30, 20 }, { 40, 25 } },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("ElementalResist", "BASE", values[val][1] * mapModEffect, "Map mod Resistant")
				enemyModList:NewMod("ChaosResist", "BASE", values[val][2] * mapModEffect, "Map mod Resistant")
			end
		},
		["Unwavering"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% more Monster Life", "Monsters cannot be Stunned" },
			values = { { { 15, 19 } }, { { 20, 24 } }, { { 25, 30 } },  },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("AvoidStun", "BASE", 100, "Map mod Unwavering")
				enemyModList:NewMod("Life", "MORE", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100) * mapModEffect, "Map mod Unwavering")
			end
		},
		["Fecund"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% more Monster Life" },
			values = { { 20, 29 }, { 30, 39 }, { 40, 49 } },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Life", "MORE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Fecund")
			end
		},
		["Unstoppable"] = {
			type = "check",
			tooltipLines = { "Monsters cannot be Taunted", "Monsters' Action Speed cannot be modified to below Base Value", "Monsters' Movement Speed cannot be modified to below Base Value" },
			values = { { 0 } },
			apply = function(val, mapModEffect, modList, enemyModList)
				-- MISSING: Monsters cannot be Taunted
				enemyModList:NewMod("MinimumActionSpeed", "MAX", 100, "Map mod Unstoppable")
			end
		},
		["Impervious"] = {
			type = "list",
			tooltipLines = { "Monsters have a %d%% chance to avoid Poison, Impale, and Bleeding" },
			values = { 20, 35, 50 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("AvoidPoison", "BASE", values[val] * mapModEffect, "Map mod Impervious")
				enemyModList:NewMod("AvoidImpale", "BASE", values[val] * mapModEffect, "Map mod Impervious")
				enemyModList:NewMod("AvoidBleed", "BASE", values[val] * mapModEffect, "Map mod Impervious")
			end
		},
		["Oppressive"] = {
			type = "list",
			tooltipLines = { "Monsters have +%d%% chance to Suppress Spell Damage" },
			values = { 30, 45, 60 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("SpellSuppressionChance", "BASE", values[val] * mapModEffect, "Map mod Oppressive")
			end
		},
		["Buffered"] = {
			type = "count",
			tooltipLines = { "Monsters gain (%d to %d)%% of Maximum Life as Extra Maximum Energy Shield" },
			values = { { 20, 29 }, { 30, 39 }, { 40, 49 } },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("LifeGainAsEnergyShield", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Buffered")
			end
		},
		["Titan's"] = {
			type = "list",
			tooltipLines = { "Unique Boss has %d%% increased Life", "Unique Boss has %d%% increased Area of Effect" },
			values = { { 25, 45 }, { 30, 55 }, { 35, 70 } },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Life", "MORE", values[val][1] * mapModEffect, "Map mod Titan's", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("AreaOfEffect", "INC", values[val][2] * mapModEffect, "Map mod Titan's", { type = "Condition", var = "RareOrUnique" })
			end
		},
		-- offensive prefixes
		["Savage"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% increased Monster Damage" },
			values = { { 14, 17 }, { 18, 21 }, { 22, 25 } },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Damage", "INC", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Savage")
			end
		},
		["Burning"] = {
			type = "count",
			tooltipLines = { "Monsters deal (%d to %d)%% extra Physical Damage as Fire" },
			values = { { 50, 69 }, { 70, 89 }, { 90, 110 } },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsFire", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Burning")
			end
		},
		["Freezing"] = {
			type = "count",
			tooltipLines = { "Monsters deal (%d to %d)%% extra Physical Damage as Cold" },
			values = { { 50, 69 }, { 70, 89 }, { 90, 110 } },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsCold", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Freezing")
			end
		},
		["Shocking"] = {
			type = "count",
			tooltipLines = { "Monsters deal (%d to %d)%% extra Physical Damage as Lightning" },
			values = { { 50, 69 }, { 70, 89 }, { 90, 110 } },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsLightning", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Shocking")
			end
		},
		["Profane"] = {
			type = "count",
			tooltipLines = { "Monsters gain (%d to %d)%% of their Physical Damage as Extra Chaos Damage", "Monsters Inflict Withered for %d seconds on Hit" },
			values = { { { 0, 0 }, { 0, 0 } }, { { 21, 25 }, { 100 } }, { { 31, 35 }, { 100 } },  },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsChaos", "BASE", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100) * mapModEffect, "Map mod Profane")
				modList:NewMod("Condition:CanBeWithered", "FLAG", true, "Map mod Profane")
			end
		},
		["Fleet"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% increased Monster Movement Speed", "(%d to %d)%% increased Monster Attack Speed", "(%d to %d)%% increased Monster Cast Speed" },
			values = { { { 15, 20 }, { 20, 25 }, { 20, 25 } }, { { 20, 25 }, { 25, 35 }, { 25, 35 } }, { { 25, 30 }, { 35, 45 }, { 35, 45 } },  },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				-- attack and cast is the same so applying it once, movespeed does not matter
				enemyModList:NewMod("Speed", "INC", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100) * mapModEffect, "Map mod Fleet")
			end
		},
		["Conflagrating"] = {
			type = "check",
			tooltipLines = { "All Monster Damage from Hits always Ignites" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("IgniteChance", "BASE", 100, "Map mod Conflagrating")
				enemyModList:NewMod("AllDamageIgnites", "FLAG", true, "Map mod Conflagrating")
			end
		},
		["Impaling"] = {
			type = "list",
			tooltipLines = { "Monsters' Attacks have %d%% chance to Impale on Hit" },
			values = { 25, 40, 60 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("ImpaleChance", "BASE", values[val] * mapModEffect, "Map mod Impaling", ModFlag.Attack)
			end
		},
		["Empowered"] = {
			type = "list",
			tooltipLines = { "Monsters have a %d%% chance to Ignite, Freeze and Shock on Hit" },
			values = { 0, 15, 20 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("ElementalAilmentChance", "BASE", values[val] * mapModEffect, "Map mod Empowered")
			end
		},
		["Overlord's"] = {
			type = "list",
			tooltipLines = { "Unique Boss deals %d%% increased Damage", "Unique Boss has %d%% increased Attack and Cast Speed" },
			values = { { 15, 20 }, { 20, 25 }, { 25, 30 } },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Damage", "INC", values[val][1] * mapModEffect, "Map mod Overlord's", { type = "Condition", var = "RareOrUnique" })
				enemyModList:NewMod("Speed", "INC", values[val][2] * mapModEffect, "Map mod Overlord's", { type = "Condition", var = "RareOrUnique" })
			end
		},
		-- reflect prefixes
		["Punishing"] = {
			type = "list",
			tooltipLines = { "Monsters reflect %d%% of Physical Damage" },
			values = { 13, 15, 18 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end
		},
		["Mirrored"] = {
			type = "list",
			tooltipLines = { "Monsters reflect %d%% of Elemental Damage" },
			values = { 13, 15, 18 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end
		},
		-- suffixes
		["of Balance"] = {
			type = "check",
			label = "Player has Elemental Equilibrium?",
			tooltipLines = { "Players cannot inflict Exposure" },
			apply = function(val, mapModEffect, modList, enemyModList)
				-- Players cannot inflict Exposure
				-- modList:NewMod("Keystone", "LIST", "Elemental Equilibrium", "Map mod of Balance") -- OLD MOD
			end
		},
		["of Congealment"] = {
			type = "check",
			label = "Cannot Leech ^xE05030Life ^7/ ^x7070FFMana?",
			tooltipLines = { "Monsters cannot be Leeched from" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("CannotLeechLifeFromSelf", "FLAG", true, "Map mod of Congealment")
				enemyModList:NewMod("CannotLeechManaFromSelf", "FLAG", true, "Map mod of Congealment")
				--missing cannot leech es?
			end
		},
		["of Drought"] = {
			type = "list",
			label = "Gains reduced Flask Charges:",
			tooltipLines = { "Players gain %d%% reduced Flask Charges" },
			values = { 30, 40, 50 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("FlaskChargesGained", "INC", -values[val] * mapModEffect, "Map mod of Drought")
			end
		},
		["of Exposure"] = {
			type = "count",
			label = "-X% maximum Resistances:",
			tooltip = "Mid tier: 5-8%\nHigh tier: 9-12%",
			tooltipLines = { "Players have minus (%d to %d)%% to all maximum Resistances" },
			values = { { 0, 0 }, { 5, 8 }, { 9, 12 } },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				if values[val][2] ~= 0 then
					local roll = (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect
					modList:NewMod("FireResistMax", "BASE", -roll, "Map mod of Exposure")
					modList:NewMod("ColdResistMax", "BASE", -roll, "Map mod of Exposure")
					modList:NewMod("LightningResistMax", "BASE", -roll, "Map mod of Exposure")
					modList:NewMod("ChaosResistMax", "BASE", -roll, "Map mod of Exposure")
				end
			end
		},
		["of Impotence"] = {
			type = "list",
			label = "Less Area of Effect:",
			tooltipLines = { "Players have %d%% less Area of Effect" },
			values = { 15, 20, 25 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("AreaOfEffect", "MORE", -values[val] * mapModEffect, "Map mod of Impotence")
			end
		},
		["of Insulation"] = {
			type = "list",
			label = "Enemy avoid Elemental Ailments:",
			tooltipLines = { "Monsters have %d%% chance to Avoid Elemental Ailments" },
			values = { 30, 50, 70 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("AvoidElementalAilments", "BASE", values[val] * mapModEffect, "Map mod of Insulation")
			end
		},
		["of Miring"] = {
			type = "list",
			label = "Unlucky Dodge / Enemy has inc. Accuracy:",
			tooltipLines = { "Monsters have %d%% increased Accuracy Rating", "Players have minus %d%% to amount of Suppressed Spell Damage Prevented" },
			values = { { 10, 30 }, { 15, 40 }, { 20, 50 } },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				-- modList:NewMod("DodgeChanceIsUnlucky", "FLAG", true, "Map mod of Miring") -- OLD MOD
				modList:NewMod("SpellSuppressionEffect", "BASE", -values[val][1] * mapModEffect, "Map mod of Miring")
				enemyModList:NewMod("Accuracy", "INC", values[val][2] * mapModEffect, "Map mod of Miring")
			end
		},
		["of Rust"] = {
			type = "list",
			label = "Reduced Block Chance / less Armour:",
			tooltipLines = { "Players have %d%% less Armour", "Players have %d%% reduced Chance to Block" },
			values = { { 20, 20 }, { 30, 25 }, { 40, 30 } },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("BlockChance", "INC", -values[val][1] * mapModEffect, "Map mod of Rust")
				modList:NewMod("Armour", "MORE", -values[val][2] * mapModEffect, "Map mod of Rust")
			end
		},
		["of Smothering"] = {
			type = "list",
			label = "Less Recovery Rate of ^xE05030Life ^7and ^x88FFFFEnergy Shield:",
			tooltipLines = { "Players have %d%% less Recovery Rate of Life and Energy Shield" },
			values = { 20, 40, 60 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("LifeRecoveryRate", "MORE", -values[val] * mapModEffect, "Map mod of Smothering")
				modList:NewMod("EnergyShieldRecoveryRate", "MORE", -values[val] * mapModEffect, "Map mod of Smothering")
			end
		},
		["of Stasis"] = {
			type = "check",
			label = "Cannot Regen ^xE05030Life^7, ^x7070FFMana ^7or ^x88FFFFES?",
			tooltipLines = { "Players cannot Regenerate Life, Mana or Energy Shield" },
			apply = function(val, mapModEffect, modList, enemyModList)
				modList:NewMod("NoLifeRegen", "FLAG", true, "Map mod of Stasis")
				modList:NewMod("NoEnergyShieldRegen", "FLAG", true, "Map mod of Stasis")
				modList:NewMod("NoManaRegen", "FLAG", true, "Map mod of Stasis")
			end
		},
		["of Toughness"] = {
			type = "count",
			tooltipLines = { "Monsters take (%d to %d)%% reduced Extra Damage from Critical Strikes" },
			values = { { 25, 30 }, { 31, 35 }, { 36, 40 } },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("SelfCritMultiplier", "INC", -(values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod of Toughness")
			end
		},
		["of Fatigue"] = {
			type = "list",
			tooltipLines = { "Players have %d%% less Cooldown Recovery Rate" },
			values = { 20, 30, 40 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("CooldownRecovery", "MORE", -values[val] * mapModEffect, "Map mod of Fatigue")
			end
		},
		["of Transience"] = {
			type = "list",
			tooltipLines = { "Buffs on Players expire %d%% faster" },
			values = { 30, 50, 70 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
			end
		},
		["of Doubt"] = {
			type = "list",
			tooltipLines = { "Players have %d%% reduced effect of Non-Curse Auras from Skills" },
			values = { 25, 40, 60 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("AuraEffect", "INC", -values[val] * mapModEffect, "Map mod of Doubt", { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.AppliesCurse, neg = true })
			end
		},
		["of Imprecision"] = {
			type = "list",
			tooltipLines = { "Players have %d%% less Accuracy Rating" },
			values = { 15, 20, 25 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("Accuracy", "MORE", -values[val] * mapModEffect, "Map mod of Imprecision")
			end
		},
		["of Blinding"] = {
			type = "check",
			tooltipLines = { "Monsters Blind on Hit" },
			apply = function(val, mapModEffect, modList, enemyModList)
				--SHOULD THIS BE SUPPORTED? (as a flag to make "are you blinded" show on config?)
			end
		},
		["of Venom"] = {
			type = "check",
			tooltipLines = { "Monsters Poison on Hit" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("PoisonChance", "BASE", 100, "Map mod of Venom")
			end
		},
		["of Deadliness"] = {
			type = "count",
			tooltipLines = { "Monsters have (%d to %d)%% increased Critical Strike Chance", "+(%d to %d)%% to Monster Critical Strike Multiplier" },
			values = { { { 160, 200 }, { 30, 35 } }, { { 260, 300 }, { 36, 40 } }, { { 360, 400 }, { 41, 45 } },  },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("CritChance", "INC", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100) * mapModEffect, "Map mod of Deadliness")
				enemyModList:NewMod("CritMultiplier", "BASE", (values[val][2][1] + (values[val][2][2] - values[val][2][1]) * rollRange / 100) * mapModEffect, "Map mod of Deadliness")
			end
		},
		-- other Prefixes
		["Abhorrent"] = { }, -- Area is inhabited by Abominations
		["Antagonist's"] = { }, -- (20-30)% increased number of Rare Monsters
		["Bipedal"] = { }, -- Area is inhabited by Humanoids
		["Capricious"] = { }, -- Area is inhabited by Goatmen
		["Ceremonial"] = { }, -- Area contains many Totems
		["Chaining"] = { }, -- Monsters' skills Chain 2 additional times
		["Demonic"] = { }, -- Area is inhabited by Demons
		["Emanant"] = { }, -- Area is inhabited by ranged monsters
		["Enthralled"] = { }, -- Unique Bosses are Possessed
		["Feasting"] = { }, -- Area is inhabited by Cultists of Kitava
		["Feral"] = { }, -- Area is inhabited by Animals
		["Haunting"] = { }, -- Area is inhabited by Ghosts
		["Lunar"] = { }, -- Area is inhabited by Lunaris fanatics
		["Multifarious"] = { }, -- Area has increased monster variety
		["Skeletal"] = { }, -- Area is inhabited by Skeletons
		["Slithering"] = { }, -- Area is inhabited by Sea Witches and their Spawn
		["Solar"] = { }, -- Area is inhabited by Solaris fanatics
		["Splitting"] = { }, -- Monsters fire 2 additional Projectiles
		["Twinned"] = { }, -- Area contains two Unique Bosses
		["Undead"] = { }, -- Area is inhabited by Undead
		-- other Suffixes
		["of Bloodlines"] = { }, -- (20-30)% more Magic Monsters
		["of Carnage"] = { }, -- Monsters Maim on Hit with Attacks
		["of Consecration"] = { }, -- Area has patches of Consecrated Ground
		["of Desecration"] = { }, -- Area has patches of desecrated ground
		["of Endurance"] = { }, -- Monsters gain an Endurance Charge on Hit
		["of Enervation"] = { }, -- Monsters steal Power, Frenzy and Endurance charges on Hit
		["of Flames"] = { }, -- Area has patches of Burning Ground
		["of Frenzy"] = { }, -- Monsters gain a Frenzy Charge on Hit
		["of Giants"] = { }, -- Monsters have 45% increased Area of Effect
		["of Ice"] = { }, -- Area has patches of Chilled Ground
		["of Impedance"] = { }, -- Monsters Hinder on Hit with Spells
		["of Lightning"] = { }, -- Area has patches of Shocked Ground which increase Damage taken by 20%
		["of Power"] = { }, -- Monsters gain a Power Charge on Hit
	},
	Prefix = {
		{ val = "NONE", label = "None" },
		{ val = "Armoured", label = "Enemy Phys D R" .. "                                Physical Damage reduction".."Armoured" },
		{ val = "Hexproof", label = "Enemy is Hexproof?" .. "                                ".."Hexproof" },
		{ val = "Hexwarded", label = "Less Curse effect" .. "                                of Curses on enemy".."Hexwarded" },
		{ val = "Resistant", label = "Enemy Resist" .. "                                has Elemental / Chaos".."Resistant" },
		{ val = "Unstoppable", label = "Enemy Cannot Be Slowed                                 Monsters Taunted Action Speed modified below base value".."Unstoppable" },
		{ val = "Impervious", label = "avoid Poison and Bleed:" .. "                                Enemy ".."Impervious" },
		{ val = "Savage", label = "Enemy Inc Damage" .. "                                has increased Damage".."Savage" },
		{ val = "Burning", label = "Enemy Phys As Fire                                 Monsters deal to extra Physical Damage".."Burning" },
		{ val = "Freezing", label = "Enemy Phys As Cold                                 Monsters deal to extra Physical Damage".."Freezing" },
		{ val = "Shocking", label = "Enemy Phys As Lightning                                 Monsters deal to extra Physical Damage".."Shocking" },
		{ val = "Profane", label = "Enemy Phys As Chaos                                 Monsters deal to extra Physical Damage Inflict Withered for seconds on Hit Profane" },
		{ val = "Fleet", label = "Enemy Inc Speed                                 to increased Monster Movement Attack Cast".."Fleet" },
		{ val = "Impaling", label = "Enemy Impale                                 Monsters have chance to with Attacks Impaling" },
		{ val = "Conflagrating", label = "Hits always Ignites                                 All Monster Damage from Conflagrating" },
		{ val = "Empowered", label = "Elemental Ailments on Hit                                 Monsters have chance to cause Empowered" },
		{ val = "Overlord's", label = "Boss Inc Damage / Speed                                 Unique deals increased has Attack and Cast".."Overlord's" },
	},
	Suffix = {
		{ val = "NONE", label = "None" },
		{ val = "of Congealment", label = "Cannot Leech" .."                                Life / Mana".."of Congealment" },
		{ val = "of Drought", label = "reduced Flask Charges" .. "                                Gains".."of Drought" },
		{ val = "of Exposure", label = "-X% maximum Res" .. "                                Resistances".."of Exposure" },
		{ val = "of Impotence", label = "Less Area of Effect:" .. "                                ".."of Impotence" },
		{ val = "of Insulation", label = "avoid Elemental Ailments:" .. "                                Enemy".."of Impotence" },
		{ val = "of Miring", label = "Enemy has inc. Accuracy: / Players have to amount of Suppressed Spell Damage Prevented" .. "                                ".."of Miring" },
		{ val = "of Rust", label = "Reduced Block Chance / less Armour:" .. "                                ".."of Rust" },
		{ val = "of Smothering", label = "Less Recovery Rate of ^xE05030Life ^7and ^x88FFFFEnergy Shield:" .. "                                ".."of Smothering" },
		{ val = "of Stasis", label = "Cannot Regen" .. "                                Life, Mana or ES".."of Stasis" },
		{ val = "of Toughness", label = "Enemy takes red. Extra Crit Damage:" .. "                                ".."of Toughness" },
		{ val = "of Fatigue", label = "Less Cooldown Recovery                                 Players have Rate".."of Fatigue" },
		{ val = "of Doubt", label = "Reduced Aura Effect                                 Players have Non-Curse Auras from Skills".."of Doubt" },
		{ val = "of Imprecision", label = "Less Accuracy                                 Players have Rating".."of Imprecision" },
		{ val = "of Venom", label = "Poison On Hit                                 Monsters of Venom" },
		{ val = "of Deadliness", label = "Enemy Critical Strike                                 Monsters have to increased Chance Monster Multiplier".."of Deadliness" },
	},
}