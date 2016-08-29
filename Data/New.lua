--
-- Upcoming skills/bases/uniques will live here until their mods/rolls are finalised
--

local gems = data.gems


local itemBases = data.itemBases
itemBases["Bone Helmet"] = {
	type = "Helmet",
	implicit = "Minions deal (31 to 40)% increased Damage",
	armour = { armourBase = 172, energyShieldBase = 50, },
	req = { level = 75, str = 76, int = 76, },
}
itemBases["Crystal Belt"] = {
	type = "Belt",
	implicit = "+73 to maximum Energy Shield",
	req = { level = 79 },
}
itemBases["Fingerless Silk Gloves"] = {
	type = "Gloves",
	implicit = "13% increased Spell Damage",
	armour = { energyShieldBase = 56 },
	req = { level = 73, int = 95 },
}
itemBases["Gripped Gloves"] = {
	type = "Gloves",
	implicit = "15% increased Projectile Attack Damage",
	armour = { evasionBase = 191 },
	req = { level = 93, dex = 95 },
}
itemBases["Marble Amulet"] = {
	type = "Amulet",
	implicit = "1.2% of Life Regenerated per second",
	req = { level = 74 },
}
itemBases["Steel Ring"] = {
	type = "Ring",
	implicit = "Adds 3 to 11 Physical Damage to Attacks",
	req = { level = 80 },
}
itemBases["Vanguard Belt"] = {
	type = "Belt",
	implicit = "+346 to Armour and Evasion Rating",
	req = { level = 70 },
}
itemBases["Two-Toned Boots"] = {
	type = "Boots",
	implicit = "",
	armour = { armourBase = 109, energyShieldBase = 32 },
	req = { level = 72, str = 62, int = 62 },
}


data.uniques.new = {
[[
The Brass Dome
Gladiator Plate
Unreleased: true
Requires Level 65, 177 Str
30% reduced Chance to Block Attacks and Spells
647% increased Armour
10% reduced Movement Speed
50% increased Shock Duration on You
Take no Extra Damage from Critical Strikes
]],[[
Kitava's Thirst
Zealot Helmet
Unreleased: true
Requires Level 44, 50 Str, 50 Int
15% reduced Cast Speed
72% increased Armour and Energy Shield
+34 to maximum Mana
30% chance to Cast Socketed Skills when you use a Skill that costs at least 100 Mana
]],[[
Kondo's Pride
Ezomyte Blade
Unreleased: true
Requires Level 61, 113 Str, 113 Dex
18% increased Accuracy Rating
308% increased Physical Damage
0.6% of Physical Attack Damage Leeched as Life
50% increased Melee Damage against Bleeding Enemies
Cannot Leech Life from Critical Strikes
30% chance to Blind Enemies on Critical Strike
Causes Bleeding on Melee Critical Strike
]],[[
Obscurantis 
Lion Pelt
Unreleased: true
Requires Level 70, 150 Dex
+495 to Accuracy Rating
112% increased Evasion Rating
+51 to maximum Life
1% increased Projectile Attack Damage per 200 Accuracy Rating
]],[[
Praxis 
Paua Ring
Unreleased: true
Requires Level 22
+(20 to 25) to maximum Mana
+48 to maximum Mana
5.3 Mana Regenerated per second
-4 to Mana Cost of Skills
8% of Damage taken gained as Mana when Hit
]],[[
Valyrium 
Moonstone Ring
Unreleased: true
Requires Level 38
+(15 to 25) to maximum Energy Shield
+(10 to 20) to maximum Energy Shield
+(20 to 30)% to Fire Resistance
-40% to Cold Resistance
Stun Threshold is based on Energy Shield instead of Life
]],[[
Slivertongue 
Harbinger Bow
Bow
Unreleased: true
Requires Level 68, 212 Dex
(30 to 50)% increased Critical Strike Chance
Adds 70 to 200 Physical Damage
100% increased Critical Strike Chance with arrows that Fork
Arrows that Pierce cause Bleeding
Arrows always Pierce after Chaining
]],[[
Snakepit 
Sapphire Ring
Unreleased: true
Requires Level 68
+(20 to 30)% to Cold Resistance
33% increased Cold Damage
7% increased Cast Speed
Spells have an additional Projectile
]],[[
Brain Rattler 
Meatgrinder
Two Handed Mace
Unreleased: true
Requires Level 63, 212 Str
20% increased Stun Duration on Enemies
Adds 99 to 327 Physical Damage
50% of Physical Damage Converted to Lightning Damage
15% chance to Shock
10% chance to Cause Monsters to Flee
Enemies you Shock have 30% reduced Cast Speed
Enemies you Shock have 20% reduced Movement Speed
]],[[
Razor of the Seventh Sun 
Midnight Blade
One Handed Sword
Unreleased: true
Requires Level 68, 113 Str, 113 Dex
18% increased Accuracy Rating
Adds 72 to 127 Physical Damage
100% increased Burning Damage if you've Ignited an Enemy Recently
Recovery 1% of Maximum Life when you Ignite an Enemy
100% increased Melee Physical Damage against Ignited Enemies
]],[[
Eye of Innocence 
Citrine Amulet
Unreleased: true
Requires Level 68
+(16 to 24) to Strength and Dexterity
10% chance to Ignite
53% increased Damage while Ignited
Take 100 Fire Damage when you Ignite an Enemy
2% of Fire Damage Leeched as Life while Ignited
]]
}