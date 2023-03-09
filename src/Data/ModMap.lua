-- This is currently made by hand but should be auto generated
-- Item data (c) Grinding Gear Games

return {
	AffixData = {
		-- defensive prefixes
		["Armoured"] = { 
			type = "list",
			label = "Enemy Physical Damage reduction:",
			tooltipLines = { "+%d%% Monster Physical Damage Reduction" },
			values = {20, 30, 40},
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
			values = {25, 40, 60},
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("CurseEffectOnSelf", "MORE", -values[val] * mapModEffect, "Map mod Hexwarded")
			end
		},
		["Resistant"] = {
			type = "list",
			label = "Enemy has Elemental / ^xD02090Chaos ^7Resist:",
			tooltipLines = { "+%d%% Monster Elemental Resistances", "+%d%% Monster Chaos Resistance" },
			values = { {20, 15}, {30, 20}, {40, 25} },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("ElementalResist", "BASE", values[val][1] * mapModEffect, "Map mod Resistant")
				enemyModList:NewMod("ChaosResist", "BASE", values[val][2] * mapModEffect, "Map mod Resistant")
			end
		},
		["Unwavering"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% more Monster Life", "Monsters cannot be Stunned" },
			values = { { {15, 19} }, { {20, 24} }, { {25, 30} } },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("AvoidStun", "BASE", 100, "Map mod Unwavering")
				enemyModList:NewMod("Life", "MORE", (values[val][1][1] + (values[val][1][2] - values[val][1][1]) * rollRange / 100) * mapModEffect, "Map mod Unwavering")
			end
		},
		["Fecund"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% more Monster Life" },
			values = { {20, 29}, {30, 39}, {40, 49} },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Life", "MORE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Fecund")
			end
		},
		["Unstoppable"] = {
			type = "check",
			tooltipLines = { "Monsters cannot be Taunted", "Monsters' Action Speed cannot be modified to below base value" },
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
			tooltipLines = { },
			values = { 30, 45, 60 },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("SpellSuppressionChance", "BASE", values[val] * mapModEffect, "Map mod Oppressive")
			end
		},
		["Buffered"] = {
			type = "count",
			tooltipLines = { },
			values = { {20, 29}, {30, 39}, {40, 49} },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("LifeGainAsEnergyShield", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Buffered")
			end
		},
		["Titan's"] = {}, -- Unique Boss has 25|30|35% increased Life / Unique Boss has 45|55|70% increased Area of Effect
		-- offensive prefixes
		["Savage"] = {
			type = "count",
			tooltipLines = { "(%d to %d)%% increased Monster Damage" },
			values = { {14, 17}, {18, 21}, {22, 25} },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("Damage", "INC", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Savage")
			end
		},
		["Burning"] = {
			type = "count",
			tooltipLines = { "Monsters deal (%d to %d)%% extra Physical Damage as Fire" },
			values = { {50, 69}, {70, 89}, {90, 110} },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsFire", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Burning")
			end
		},
		["Freezing"] = {
			type = "count",
			tooltipLines = { "Monsters deal (%d to %d)%% extra Physical Damage as Cold" },
			values = { {50, 69}, {70, 89}, {90, 110} },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsCold", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Freezing")
			end
		},
		["Shocking"] = {
			type = "count",
			tooltipLines = { "Monsters deal (%d to %d)%% extra Physical Damage as Lightning" },
			values = { {50, 69}, {70, 89}, {90, 110} },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("PhysicalDamageGainAsLightning", "BASE", (values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod Shocking")
			end
		},
		["Fleet"] = {}, --(15–20)|(20–25)|(25–30)% increased Monster Movement Speed / (20–25)|(25–35)|(35–45)% increased Monster Attack Speed / 0% increased Monster Cast Speed
		["Conflagrating"] = {}, -- All Monster Damage from Hits always Ignites
		["Impaling"] = {}, -- Monsters have 25|40|60% chance to Impale with Attacks
		["Empowered"] = {}, -- Monsters have a 0|15|20% chance to cause Elemental Ailments on Hit
		["Overlord's"] = {}, -- Unique Boss deals 15|20|25% increased Damage / Unique Boss has 20|25|30% increased Attack and Cast Speed
		-- reflect prefixes
		["Punishing"] = {}, -- Monsters reflect 13|15|18% of Physical Damage
		["Mirrored"] = {}, -- Monsters reflect 13|15|18% of Elemental Damage
		-- suffixes
		["of Balance"] = {
			type = "check",
			label = "Player has Elemental Equilibrium?",
			tooltipLines = { },
			apply = function(val, mapModEffect, modList, enemyModList)
				-- Players cannot inflict Exposure
				-- modList:NewMod("Keystone", "LIST", "Elemental Equilibrium", "Map mod of Balance") -- OLD MOD
			end
		},
		["of Congealment"] = {
			type = "check",
			label = "Cannot Leech ^xE05030Life ^7/ ^x7070FFMana?",
			tooltipLines = { "Cannot Leech from Monsters" },
			apply = function(val, mapModEffect, modList, enemyModList)
				enemyModList:NewMod("CannotLeechLifeFromSelf", "FLAG", true, "Map mod of Congealment")
				enemyModList:NewMod("CannotLeechManaFromSelf", "FLAG", true, "Map mod of Congealment")
			end
		},
		["of Drought"] = {
			type = "list",
			label = "Gains reduced Flask Charges:",
			tooltipLines = { "Players gain %d%% reduced Flask Charges" },
			values = {30, 40, 50},
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("FlaskChargesGained", "INC", -values[val] * mapModEffect, "Map mod of Drought")
			end
		},
		["of Exposure"] = {
			type = "count",
			label = "-X% maximum Resistances:",
			tooltip = "Mid tier: 5-8%\nHigh tier: 9-12%",
			tooltipLines = { "minus (%d to %d)%% maximum Player Resistances" },
			values = { {0, 0}, {5, 8}, {9, 12} },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				if map[val][2] ~= 0 then
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
			values = {15, 20, 25},
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("AreaOfEffect", "MORE", -values[val] * mapModEffect, "Map mod of Impotence")
			end
		},
		["of Insulation"] = {
			type = "list",
			label = "Enemy avoid Elemental Ailments:",
			tooltipLines = { "Monsters have %d%% chance to Avoid Elemental Ailments" },
			values = {30, 50, 70},
			apply = function(val, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("AvoidElementalAilments", "BASE", values[val] * mapModEffect, "Map mod of Insulation")
			end
		},
		["of Miring"] = {
			type = "list",
			label = "Unlucky Dodge / Enemy has inc. Accuracy:",
			tooltipLines = { "Monsters have %d%% increased Accuracy Rating", "Players have minus %d%% to amount of Suppressed Spell Damage Prevented" },
			values = { {10, 30}, {15, 40}, {20, 50} },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				-- modList:NewMod("DodgeChanceIsUnlucky", "FLAG", true, "Map mod of Miring") -- OLD MOD
				-- Players have -10|15|20% to amount of Suppressed Spell Damage Prevented
				enemyModList:NewMod("Accuracy", "INC", values[val][2] * mapModEffect, "Map mod of Miring")
			end
		},
		["of Rust"] = {
			type = "list",
			label = "Reduced Block Chance / less Armour:",
			tooltipLines = { "Players have %d%% less Armour", "Players have %d%% reduced Chance to Block" },
			values = { {20, 20}, {30, 25}, {40, 30} },
			apply = function(val, mapModEffect, values, modList, enemyModList)
				modList:NewMod("BlockChance", "INC", -values[val][1] * mapModEffect, "Map mod of Rust")
				modList:NewMod("Armour", "MORE", -values[val][2] * mapModEffect, "Map mod of Rust")
			end
		},
		["of Skirmishing"] = {
			-- old map mod, doesn't exist anymore?
			type = "check",
			tooltipLines = { },
			apply = function(val, mapModEffect, modList, enemyModList)
				modList:NewMod("Keystone", "LIST", "Point Blank", "Map mod of Skirmishing")
			end
		},
		["of Smothering"] = {
			type = "list",
			label = "Less Recovery Rate of ^xE05030Life ^7and ^x88FFFFEnergy Shield:",
			tooltipLines = { "Players have %d%% less Recovery Rate of Life and Energy Shield" },
			values = {20, 40, 60},
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
			values = { {25, 30}, {31, 35}, {36, 40} },
			apply = function(val, rollRange, mapModEffect, values, modList, enemyModList)
				enemyModList:NewMod("SelfCritMultiplier", "INC", -(values[val][1] + (values[val][2] - values[val][1]) * rollRange / 100) * mapModEffect, "Map mod of Toughness")
			end
		},
		["of Fatigue"] = {}, -- Players have 20|30|40% less Cooldown Recovery Rate
		["of Transience"] = {}, --  Buffs on Players expire 30|50|70% faster
		["of Doubt"] = {}, -- Players have 25|40|60% reduced effect of Non-Curse Auras from Skills
		["of Imprecision"] = {}, -- Players have 15|20|25% less Accuracy Rating
		["of Blinding"] = {}, -- Monsters Blind on Hit --SHOULD THIS BE SUPPORTED? (as a flag to make "are you blinded" show on config?)
		["of Venom"] = {}, -- Monsters Poison on Hit
		["of Deadliness"] = {}, -- Monsters have (160–200)|(260–300)|(360–400)% increased Critical Strike Chance / +(30–35)|(36–40)|(41–45)% to Monster Critical Strike Multiplier
		-- other prefixes
		["Antagonist's"] = {}, -- (20–30)% increased number of Rare Monsters
		["Anarchic"] = {}, -- Area is inhabited by 2 additional Rogue Exiles
		["Ceremonial"] = {}, -- Area contains many Totems
		["Skeletal"] = {}, -- Area is inhabited by Skeletons
		["Capricious"] = {}, -- Area is inhabited by Goatmen
		["Slithering"] = {}, -- Area is inhabited by Sea Witches and their Spawn
		["Undead"] = {}, -- Area is inhabited by Undead
		["Emanant"] = {}, -- Area is inhabited by ranged monsters
		["Feral"] = {}, -- Area is inhabited by Animals
		["Demonic"] = {}, -- Area is inhabited by Demons
		["Bipedal"] = {}, -- Area is inhabited by Humanoids
		["Solar"] = {}, -- Area is inhabited by Solaris fanatics
		["Lunar"] = {}, -- Area is inhabited by Lunaris fanatics
		["Haunting"] = {}, -- Area is inhabited by Ghosts
		["Feasting"] = {}, -- Area is inhabited by Cultists of Kitava
		["Multifarious"] = {}, -- Area has increased monster variety
		["Abhorrent"] = {}, -- Area is inhabited by Abominations
		["Otherworldly"] = {}, -- Slaying Enemies close together can attract monsters from Beyond this realm
		["Twinned"] = {}, -- Area contains two Unique Bosses
		["Enthralled"] = {}, -- Unique Bosses are Possessed
		["Chaining"] = {}, -- Monsters' skills Chain 2 additional times
		["Splitting"] = {}, -- Monsters fire 2 additional Projectiles
		-- other suffixes
		["of Bloodlines"] = {}, -- (20–30)% more Magic Monsters
		["of Giants"] = {}, --  Monsters have 45|70|100% increased Area of Effect
		["of Flames"] = {}, -- Area has patches of Burning Ground
		["of Ice"] = {}, -- Area has patches of Chilled Ground
		["of Lightning"] = {}, -- Area has patches of Shocked Ground which increase Damage taken by 20|35|50%
		["of Desecration"] = {}, -- Area has patches of desecrated ground
		["of Consecration"] = {}, -- Area has patches of Consecrated Ground
		["of Frenzy"] = {}, -- Monsters gain a Frenzy Charge on Hit
		["of Endurance"] = {}, -- Monsters gain an Endurance Charge on Hit
		["of Power"] = {}, -- Monsters gain a Power Charge on Hit
		["of Carnage"] = {}, -- Monsters Maim on Hit with Attacks
		["of Impedance"] = {}, -- Monsters Hinder on Hit with Spells
		["of Enervation"] = {}, -- Monsters steal Power, Frenzy and Endurance charges on Hit
	},
	Prefix = {
		{ val = "NONE", label = "None" },
		{ val = "Armoured", label = "Enemy Phys D R" .. "                                Physical Damage reduction".."Armoured" },
		{ val = "Hexproof", label = "Enemy is Hexproof?" .. "                                ".."Hexproof" },
		{ val = "Hexwarded", label = "Less Curse effect" .. "                                of Curses on enemy".."Hexwarded" },
		{ val = "Resistant", label = "Enemy Resist" .. "                                has Elemental / Chaos".."Resistant" },
		{ val = "Impervious", label = "avoid Poison and Bleed:" .. "                                Enemy ".."Impervious" },
		{ val = "Savage", label = "Enemy Inc Damage" .. "                                has increased Damage".."Savage" },
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
	},
}