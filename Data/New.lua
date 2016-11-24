--
-- Upcoming skills/bases/uniques will live here until their mods/rolls are finalised
--

local gems = data.gems


local itemBases = data.itemBases
itemBases["Blue Pearl Amulet"] = {
	type = "Amulet",
	implicit = "(48-56)% increased Mana Regeneration Rate",
	req = { level = 77 },
}
itemBases["Marble Amulet"] = {
	type = "Amulet",
	implicit = "(1.2-1.6)% of Life Regenerated per second",
	req = { level = 74 },
}
itemBases["Steel Ring"] = {
	type = "Ring",
	implicit = "Adds (3-4) to (10-14) Physical Damage to Attacks",
	req = { level = 80 },
}
itemBases["Opal Ring"] = {
	type = "Ring",
	implicit = "(15-25)% increased Elemental Damage",
	req = { level = 80 },
}
itemBases["Vanguard Belt"] = {
	type = "Belt",
	implicit = "+(260-320) to Armour and Evasion Rating",
	req = { level = 70 },
}
itemBases["Crystal Belt"] = {
	type = "Belt",
	implicit = "+(60-80) to maximum Energy Shield",
	req = { level = 79 },
}
itemBases["Bone Helmet"] = {
	type = "Helmet",
	implicit = "Minions deal (30 to 40)% increased Damage",
	armour = { armourBase = 172, energyShieldBase = 50, },
	req = { level = 75, str = 76, int = 76, },
}
itemBases["Fingerless Silk Gloves"] = {
	type = "Gloves",
	implicit = "(12-16)% increased Spell Damage",
	armour = { energyShieldBase = 56 },
	req = { level = 73, int = 95 },
}
itemBases["Gripped Gloves"] = {
	type = "Gloves",
	implicit = "(14-18)% increased Projectile Attack Damage",
	armour = { evasionBase = 191 },
	req = { level = 73, dex = 95 },
}
itemBases["Spiked Gloves"] = {
	type = "Gloves",
	implicit = "(16-20)% increased Melee Damage",
	armour = { armourBase = 191 },
	req = { level = 73, str = 95 },
}
itemBases["Two-Toned Boots"] = {
	type = "Boots",
	implicit = "",
	armour = { armourBase = 109, energyShieldBase = 32 },
	req = { level = 72, str = 62, int = 62 },
}
itemBases["Breach Ring"] = {
	type = "Ring",
	implicit = "Properties are doubled while in a Breach",
	req = { level = 48 },
}

data.uniques.new = {
[[
Ngamahu's Flame
Colossus Mallet
Unreleased: true
Requires Level 59, 188 Str
20% increased Stun Duration on Enemies
200% increased Physical Damage
8% increased Attack Speed
50% of Physical Damage converted to Fire Damage
Damage Penetrates 20% Fire Resistance
20% chance to Attack with level 16 Molten Burst on Melee Hit
]],[[
Voll's Vision
Praetor Crown
Unreleased: true
Requires Level 68, 62 Str, 91 Int
+276 to Armour
+27% to Fire Resistance
+10% to Chaos Resistance
20% increased Light Radius
12% increased maximum Life if you wear no Corrupted items
Regenerate 100 Life per second if you wear no Corrupted items
]],[[
Tukohama's Fortress
Ebony Tower Shield
Unreleased: true
Requires Level 61, 159 Str
40% increased Totem Damage
+100 to maximum Life
Blood Magic
Can have up to 1 additional Totem summoned at a time
+300 Armour per active Totem
]],[[
Ewar's Mirage
Antique Rapier
Unreleased: true
Requires Level 26, 89 Dex
+30% to Global Critical Strike Multiplier
55% increased Elemental Damage with Weapons
Adds 1 to 48 Lightning Damage
21% increased Attack Speed
Attacks Chain an additional time when in Main Hand
Attacks have an additional Projectile when in Off Hand
]],[[
Shade of Solaris
Sage Wand
Unreleased: true
Requires Level 30, 119 Int
(17 to 21)% increased Spell Damage
Gain 20% of Elemental Damage as Extra Chaos Damage
Critical Strikes deal no Damage
120% increased Spell Damage if you've dealt a Critical Strike Recently
]],[[
Xoph's Nurture
Bone Bow
Unreleased: true
League: Breach
Requires Level 23, 80 Dex
83% increased Physical Damage
+25 Life gained on Killing Ignited Enemies
Gain 20% of Physical Damage as Extra Fire Damage
10% chance to Ignite
]],[[
Xoph's Inception
Citadel Bow
Unreleased: true
League: Breach
Requires Level 64, 185 Dex
237% increased Physical Damage
50% of Physical Damage Converted to Fire Damage
10% chance to Ignite
Ignites you cause also affect other nearby Enemies
Recover 94 Life when you Ignite an Enemy
]],[[
Xoph'ethakk's Heart
Amber Amulet
Unreleased: true
League: Breach
Requires Level 35
+(20 to 30) to Strength
+27 to Strength
21% increased Fire Damage
+28 to maximum Life
+37% to Fire Resistance
Cover Enemies in Ash when they Hit you
]],[[
Xoph'ethula's Heart
Amber Amulet
Unreleased: true
League: Breach
Requires Level 64
+(20 to 30) to Strength
10% increased maximum Life
+30% to Fire Resistance
10% increased Strength
Damage Penetrates 10% Fire Resistance
Cover Enemies in Ash when they Hit you
Avatar of Fire
]],[[
The Formless Flame
Siege Helmet
Unreleased: true
League: Breach
Requires Level 48, 101 Str
+111 to Armour
+44 to maximum Life
-20 Fire Damage taken when Hit
Armour is increased by Uncapped Fire Resistance
]],[[
The Formless Inferno
Royal Burgonet
Unreleased: true
League: Breach
Requires Level 65, 148 Str
157% increased Armour
-20 Fire Damage taken when Hit
8% of Physical Damage taken as Fire Damage
-30% to Cold and Lightning Resistances
Armour is increased by Uncapped Fire Resistance
]],[[
The Infinite Pursuit
Goliath Greaves
Unreleased: true
League: Breach
Requires Level 54, 95 Str
+60 to maximum Life
20% increased Movement Speed
15% increased Movement Speed while Bleeding
10% increased Physical Damage Reduction while Stationary
10% increased Physical Damage taken while Moving
20% chance to be inflicted with Bleeding when Hit by an Attack
]],[[
The Red Trail
Titan Greaves
Unreleased: true
League: Breach
Requires Level 68, 120 Str
72% increased Armour
+67 to maximum Life
25% increased Movement Speed
Gain a Frenzy Charge on Hit while Bleeding
15% increased Movement Speed while Bleeding
10% increased Physical Damage Reduction while Stationary
50% chance to be inflicted with Bleeding when Hit by an Attack
]],


[[
The Brass Dome
Gladiator Plate
Requires Level 65, 177 Str
30% reduced Chance to Block Attacks and Spells
(600 to 650)% increased Armour
10% reduced Movement Speed
50% increased Shock Duration on You
Take no Extra Damage from Critical Strikes
]],[[
Voidwalker
Murder Boots
Evasion: (386 to 450)
Energy Shield: (52 to 61)
Requires Level 69, 82 Dex, 42 Int
+(30 to 50) to Dexterity
(140 to 180)% increased Evasion and Energy Shield
30% increased Movement Speed
20% chance to Avoid Projectiles while Phasing
You have Phasing if you've Killed Recently
Projectiles Pierce while Phasing
]],[[
Kitava's Thirst 
Zealot Helmet
Armour: (177–187)
Energy Shield: (53–56)
Requires Level 44, 50 Str, 50 Int
15% reduced Cast Speed
(70 to 80)% increased Armour and Energy Shield
+(30 to 50) to maximum Mana
30% chance to Cast Socketed Spells when 
you Spend at least 100 Mana to Use a Skill
]],[[
Kondo's Pride 
Ezomyte Blade
Two Handed Sword
Physical Damage: (226–418 to 256–475)
Critical Strike Chance: 5.00%
Attacks per Second: 1.25
Requires Level 61, 113 Str, 113 Dex
18% increased Accuracy Rating
(270 to 320)% increased Physical Damage
0.6% of Physical Attack Damage Leeched as Life
50% increased Melee Damage against Bleeding Enemies
Cannot Leech Life from Critical Strikes
30% chance to Blind Enemies on Critical Strike
Causes Bleeding on Melee Critical Strike
]],[[
Obscurantis 
Lion Pelt
Requires Level 70, 150 Dex
+(300 to 500) to Accuracy Rating
(100 to 120)% increased Evasion Rating
+(50 to 80) to maximum Life
1% increased Projectile Attack Damage per 200 Accuracy Rating
]],[[
Slivertongue 
Harbinger Bow
Bow
Requires Level 68, 212 Dex
(30 to 50)% increased Critical Strike Chance
Adds (60-75) to (170-220) Physical Damage
100% increased Critical Strike Chance with arrows that Fork
Arrows that Pierce cause Bleeding
Arrows always Pierce after Chaining
]],[[
Snakepit 
Sapphire Ring
Requires Level 68
+(20 to 30)% to Cold Resistance
(20 to 40)% increased Cold Damage
(5 to 10)% increased Cast Speed
Spells have an additional Projectile
]],[[
Brain Rattler 
Meatgrinder
Two Handed Mace
Physical Damage: (143–437 to 163–487)
Critical Strike Chance: 5.00%
Attacks per Second: 1.25
Requires Level 63, 212 Str
20% increased Stun Duration on Enemies
Adds (80-100) to (320–370) Physical Damage
50% of Physical Damage Converted to Lightning Damage
15% chance to Shock
10% chance to Cause Monsters to Flee
Enemies you Shock have 30% reduced Cast Speed
Enemies you Shock have 20% reduced Movement Speed
]],[[
Razor of the Seventh Sun 
Midnight Blade
One Handed Sword
Requires Level 68, 113 Str, 113 Dex
18% increased Accuracy Rating
Adds (65-75) to (110-130) Physical Damage
100% increased Burning Damage if you've Ignited an Enemy Recently
Recovery 1% of Maximum Life when you Ignite an Enemy
100% increased Melee Physical Damage against Ignited Enemies
]],[[
Eye of Innocence 
Citrine Amulet
Requires Level 68
+(16 to 24) to Strength and Dexterity
10% chance to Ignite
(50 to 70)% increased Damage while Ignited
Take 100 Fire Damage when you Ignite an Enemy
2% of Fire Damage Leeched as Life while Ignited
]],[[
Cospri's Malice 
Jewelled Foil
One Handed Sword
Elemental Damage: (80–160 to 100–200)
Critical Strike Chance: 5.50%
Attacks per Second: (1.73–1.82)
Requires Level 68, 212 Dex, 257 Int
+30% to Global Critical Strike Multiplier
No Physical Damage
Adds (80–100) to (160–200) Cold Damage
Adds (40–60) to (90–110) Cold Damage to Spells
(8 to 14)% increased Attack Speed
+257 Intelligence Requirement
60% increased Critical Strike Chance against Chilled Enemies
Cast a Socketed Cold Skill on Melee Critical Strike
]],[[
The Scourge
Terror Claw
Claws
Physical Damage: 15–60
Critical Strike Chance: 6.30%
Attacks per Second: 1.50
Requires Level 70, 113 Dex, 113 Int
2% of Physical Attack Damage Leeched as Life
Adds (35-50) to (100-125) Physical Damage
(10 to 15)% increased Attack Speed
Minions have (10 to 15)% increased Attack Speed
10% Chance to summon a Spectral Wolf on Kill
Increases and reductions to Minion Damage also affects you
70% increased Minion Damage if you have Hit Recently
]],[[
Unending Hunger 
Cobalt Jewel
Minions have (5 to 8)% increased Radius of Area Skills
20% chance for Spectres to gain Soul Eater on Kill for 30 seconds
with 50 Intelligence from Allocated Passives in Radius
]],[[
The Warden's Brand 
Iron Ring
Requires Level 30
Adds 1 to 4 Physical Damage to Attacks
Adds (5–15) to (25–50) Physical Damage to Attacks
30% reduced Attack Speed
15% chance to gain a Frenzy Charge when you Stun an Enemy
]],[[
Praxis 
Paua Ring
Requires Level 22
+(20 to 25) to maximum Mana
+(30 to 60) to maximum Mana
(3 to 6) Mana Regenerated per second
−(4 to 8) to Mana Cost of Skills
8% of Damage taken gained as Mana when Hit
]],[[
Valyrium 
Moonstone Ring
Requires Level 38
+(15 to 25) to maximum Energy Shield
+(10 to 20) to maximum Energy Shield
+(20 to 30)% to Fire Resistance
−40% to Cold Resistance
Stun Threshold is based on Energy Shield instead of Life
]],[[
Shaper's Touch 
Crusader Gloves
Armour: (194)
Energy Shield: (57)
Requires Level 66, 51 Str, 51 Int
(80 to 120)% increased Armour and Energy Shield
+2 Accuracy Rating per 2 Intelligence
+1 Life per 4 Dexterity
+1 Mana per 4 Strength
1% increased Energy Shield per 10 Strength
1% increased Evasion Rating per 10 Intelligence
1% increased Melee Physical Damage per 10 Dexterity
]],[[
Starforge 
Infernal Sword
Two Handed Sword
Physical Damage: (285–590 to 342–708)
Critical Strike Chance: 5.00%
Attacks per Second: (1.31–1.35)
Requires Level 67, 113 Str, 113 Dex
30% increased Accuracy Rating
(400 to 500)% increased Physical Damage
(5 to 8)% increased Attack Speed
+(90 to 100) to maximum Life
20% increased Area of Effect for Attacks
Deal no Elemental Damage
Your Physical Damage can Shock
]]
}