-- This is currently made by hand but should be auto generated
-- Item data (c) Grinding Gear Games

return {
	AffixData = {
		-- defensive prefixes
		["Armoured"] = { 
			type = "list",
			tooltip = "'Armoured'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {20, 30, 40}
				enemyModList:NewMod("PhysicalDamageReduction", "BASE", map[val] * mapModEffect, "Map mod Armoured")
			end 
		},
		["Hexproof"] = {
			type = "check",
			tooltip = "'Hexproof'",
			apply = function(val, modList, enemyModList, mapModEffect)
				enemyModList:NewMod("Hexproof", "FLAG", true, "Map mod Hexproof")
			end 
		},
		["Hexwarded"] = {
			type = "list",
			tooltip = "'Hexwarded'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {25, 40, 60}
				enemyModList:NewMod("CurseEffectOnSelf", "MORE", -map[val] * mapModEffect, "Map mod Hexwarded")
			end
		},
		["Resistant"] = {
			type = "list",
			tooltip = "'Resistant'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {20, 15},  {30, 20}, {40, 25} }
				enemyModList:NewMod("ElementalResist", "BASE", map[val][1] * mapModEffect, "Map mod Resistant")
				enemyModList:NewMod("ChaosResist", "BASE", map[val][2] * mapModEffect, "Map mod Resistant")
			end
		},
		["Unwavering"] = {
			type = "count",
			tooltip = "'Unwavering'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {15, 19}, {20, 24}, {25, 30} }
				-- Low tier: 15–19% / Mid tier: 20–24% / High tier: 25–30%"
				enemyModList:NewMod("AvoidStun", "BASE", 100, "Map mod Unwavering")
				enemyModList:NewMod("Life", "MORE", map[val][2] * mapModEffect, "Map mod Unwavering")
			end
		},
		["Fecund"] = {
			type = "count",
			tooltip = "'Fecund'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {20, 29}, {30, 39}, {40, 49} }
				-- Low tier: 20–29% / Mid tier: 30–39% / High tier: 40–49%"
				enemyModList:NewMod("Life", "MORE", map[val][2] * mapModEffect, "Map mod Fecund")
			end
		},
		["Unstoppable"] = {
			type = "check",
			tooltip = "'Unstoppable'",
			apply = function(val, modList, enemyModList, mapModEffect)
				-- MISSING: Monsters cannot be Taunted
				enemyModList:NewMod("MinimumActionSpeed", "MAX", 100, "Map mod Unstoppable")
			end 
		},
		["Impervious"] = {
			type = "list",
			tooltip = "'Impervious'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { 20, 35, 50 }
				enemyModList:NewMod("AvoidPoison", "BASE", map[val] * mapModEffect, "Map mod Impervious")
				enemyModList:NewMod("AvoidImpale", "BASE", map[val] * mapModEffect, "Map mod Impervious")
				enemyModList:NewMod("AvoidBleed", "BASE", map[val] * mapModEffect, "Map mod Impervious")
			end
		},
		["Oppressive"] = {
			type = "list",
			tooltip = "'Oppressive'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { 30, 45, 60 }
				enemyModList:NewMod("SpellSuppressionChance", "BASE", map[val] * mapModEffect, "Map mod Oppressive")
			end
		},
		["Buffered"] = {
			type = "count",
			tooltip = "'Buffered'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {20, 29}, {30, 39}, {40, 49} }
				-- Low tier: 20–29% / Mid tier: 30–39% / High tier: 40–49%"
				enemyModList:NewMod("LifeGainAsEnergyShield", "BASE", map[val][2] * mapModEffect, "Map mod Buffered")
			end
		},
		["Titan's"] = {}, -- Unique Boss has 25|30|35% increased Life / Unique Boss has 45|55|70% increased Area of Effect
		-- offensive prefixes
		["Savage"] = {
			type = "count",
			tooltip = "'Savage'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {14, 17}, {18, 21}, {22, 25} }
				-- Low tier: 14–17% / Mid tier: 18–21% / High tier: 22–25%"
				enemyModList:NewMod("Damage", "INC", map[val][2] * mapModEffect, "Map mod Savage")
			end
		},
		["Burning"] = {
			type = "count",
			tooltip = "'Burning'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {50, 69}, {70, 89}, {90, 110} } 
				-- Low tier: 50–69% / Mid tier: 70–89% / High tier: 90–110%"
				enemyModList:NewMod("PhysicalDamageGainAsFire", "BASE", map[val][2] * mapModEffect, "Map mod Burning")
			end
		},
		["Freezing"] = {
			type = "count",
			tooltip = "'Freezing'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {50, 69}, {70, 89}, {90, 110} } 
				-- Low tier: 50–69% / Mid tier: 70–89% / High tier: 90–110%"
				enemyModList:NewMod("PhysicalDamageGainAsCold", "BASE", map[val][2] * mapModEffect, "Map mod Freezing")
			end
		},
		["Shocking"] = {
			type = "count",
			tooltip = "'Shocking'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {50, 69}, {70, 89}, {90, 110} } 
				-- Low tier: 50–69% / Mid tier: 70–89% / High tier: 90–110%"
				enemyModList:NewMod("PhysicalDamageGainAsLightning", "BASE", map[val][2] * mapModEffect, "Map mod Shocking")
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
			tooltip = "'of Balance'",
			apply = function(val, modList, enemyModList, mapModEffect)
				-- Players cannot inflict Exposure
				-- modList:NewMod("Keystone", "LIST", "Elemental Equilibrium", "Map mod of Balance") -- OLD MOD
			end
		},
		["of Congealment"] = {
			type = "check",
			tooltip = "'of Congealment'",
			apply = function(val, modList, enemyModList, mapModEffect)
				enemyModList:NewMod("CannotLeechLifeFromSelf", "FLAG", true, "Map mod of Congealment")
				enemyModList:NewMod("CannotLeechManaFromSelf", "FLAG", true, "Map mod of Congealment")
			end
		},
		["of Drought"] = {
			type = "list",
			tooltip = "'of Drought'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {30, 40, 50}
				modList:NewMod("FlaskChargesGained", "INC", -map[val] * mapModEffect, "Map mod of Drought")
			end
		},
		["of Exposure"] = {
			type = "count",
			tooltip = "'of Exposure'\nMid tier: 5-8%\nHigh tier: 9-12%",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {0, 0}, {5, 8}, {9, 12} }
				-- Mid tier: 5-8% / High tier: 9-12%"
				if map[val] ~= 0 then
					modList:NewMod("FireResistMax", "BASE", -map[val][2] * mapModEffect, "Map mod of Exposure")
					modList:NewMod("ColdResistMax", "BASE", -map[val][2] * mapModEffect, "Map mod of Exposure")
					modList:NewMod("LightningResistMax", "BASE", -map[val][2] * mapModEffect, "Map mod of Exposure")
					modList:NewMod("ChaosResistMax", "BASE", -map[val][2] * mapModEffect, "Map mod of Exposure")
				end
			end
		},
		["of Impotence"] = {
			type = "list",
			tooltip = "'of Impotence'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {15, 20, 25}
				modList:NewMod("AreaOfEffect", "MORE", -map[val] * mapModEffect, "Map mod of Impotence")
			end
		},
		["of Insulation"] = {
			type = "list",
			tooltip = "'of Insulation'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {30, 50, 70}
				enemyModList:NewMod("AvoidElementalAilments", "BASE", map[val] * mapModEffect, "Map mod of Insulation")
			end
		},
		["Impervious"] = {
			type = "list",
			tooltip = "'Impervious'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {20, 35, 50}
				enemyModList:NewMod("AvoidPoison", "BASE", map[val] * mapModEffect, "Map mod Impervious")
				enemyModList:NewMod("AvoidBleed", "BASE", map[val] * mapModEffect, "Map mod Impervious")
			end
		},
		["of Miring"] = {
			type = "list",
			tooltip = "'of Miring'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {30, 40, 50}
				-- modList:NewMod("DodgeChanceIsUnlucky", "FLAG", true, "Map mod of Miring") -- OLD MOD
				-- Players have -10|15|20% to amount of Suppressed Spell Damage Prevented
				enemyModList:NewMod("Accuracy", "INC", map[val] * mapModEffect, "Map mod of Miring")
			end
		},
		["of Rust"] = {
			type = "list",
			tooltip = "'of Rust'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {20, 20}, {30, 25}, {40, 30} }
				modList:NewMod("BlockChance", "INC", -map[val][1] * mapModEffect, "Map mod of Rust")
				modList:NewMod("Armour", "MORE", -map[val][2] * mapModEffect, "Map mod of Rust")
			end
		},
		["of Skirmishing"] = {
			-- old map mod, doesnt exist anymore?
			type = "check",
			tooltip = "'of Skirmishing'", 
			apply = function(val, modList, enemyModList, mapModEffect)
				modList:NewMod("Keystone", "LIST", "Point Blank", "Map mod of Skirmishing")
			end
		},
		["of Smothering"] = {
			type = "list",
			tooltip = "'of Smothering'",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = {20, 40, 60}
				modList:NewMod("LifeRecoveryRate", "MORE", -map[val] * mapModEffect, "Map mod of Smothering")
				modList:NewMod("EnergyShieldRecoveryRate", "MORE", -map[val] * mapModEffect, "Map mod of Smothering")
			end
		},
		["of Stasis"] = {
			type = "check",
			label = "Cannot Regen ^xE05030Life^7, ^x7070FFMana ^7or ^x88FFFFES?", 
			tooltip = "'of Stasis'", 
			apply = function(val, modList, enemyModList, mapModEffect)
				modList:NewMod("NoLifeRegen", "FLAG", true, "Map mod of Stasis")
				modList:NewMod("NoEnergyShieldRegen", "FLAG", true, "Map mod of Stasis")
				modList:NewMod("NoManaRegen", "FLAG", true, "Map mod of Stasis")
			end
		},
		["of Toughness"] = {
			type = "count",
			tooltip = "'of Toughness'\nLow tier: 25-30%\nMid tier: 31-35%\nHigh tier: 36-40%",
			apply = function(val, modList, enemyModList, mapModEffect)
				local map = { {25, 30}, {31, 35}, {36, 40} } 
				-- Low tier: 25-30% / Mid tier: 31-35% / High tier: 36-40%"
				enemyModList:NewMod("SelfCritMultiplier", "INC", -map[val][2] * mapModEffect, "Map mod of Toughness")
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
		{ val = "Armoured", label = "Enemy Physical Damage reduction:" },
		{ val = "Hexproof", label = "Enemy is Hexproof?" },
		{ val = "Hexwarded", label = "Less effect of Curses on enemy:" },
		{ val = "Resistant", label = "Enemy has Elemental / ^xD02090Chaos ^7Resist:" },
		{ val = "Savage", label = "Enemy has increased Damage" },
	},
	Suffix = {
		{ val = "NONE", label = "None" },
		{ val = "of Balance", label = "Player has Elemental Equilibrium?" }, 
		{ val = "of Congealment", label = "Cannot Leech ^xE05030Life ^7/ ^x7070FFMana?" },
		{ val = "of Drought", label = "Gains reduced Flask Charges:" },
		{ val = "of Exposure", label = "-X% maximum Resistances:" },
		{ val = "of Impotence", label = "Less Area of Effect:" },
		{ val = "of Insulation", label = "Enemy avoid Elemental Ailments:" },
		{ val = "Impervious", label = "Enemy avoid Poison and Bleed:" },
		{ val = "of Miring", label = "Unlucky Dodge / Enemy has inc. Accuracy:" },
		{ val = "of Rust", label = "Reduced Block Chance / less Armour:" },
		{ val = "of Smothering", label = "Less Recovery Rate of ^xE05030Life ^7and ^x88FFFFEnergy Shield:" },
		{ val = "of Stasis", label = "Cannot Regen ^xE05030Life^7, ^x7070FFMana ^7or ^x88FFFFES?" },
		{ val = "of Toughness", label = "Enemy takes red. Extra Crit Damage:" },
	},
}