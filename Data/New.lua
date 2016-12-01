--
-- Upcoming skills/bases/uniques will live here until their mods/rolls are finalised
--

local gems = data.gems


local itemBases = data.itemBases
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
(17-21)% increased Spell Damage
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
+(20-30) to Strength
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
+(20-30) to Strength
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
]],[[
Voice of the Storm
Lapis Amulet
Unreleased: true
League: Breach
+(20-30) to Intelligence
+15 to all Attributes
14% increased maximum Mana
Critical Strike Chance is increased by Uncapped Lightning Resistance
Lightning strikes when you deal a Critical Strike
]],[[
Tulborn
Spiraled Wand
Unreleased: true
League: Breach
(15-19)% increased Spell Damage
12% increased Cast Speed
50% chance to gain a Power Charge on Killing a Frozen Enemy
Adds 10 to 20 Cold Damage to Spells per Power Charge
+21 Mana gained on Killing a Frozen Enemy
]],[[
Tulfall
Tornado Wand
Unreleased: true
League: Breach
(35-39)% increased Spell Damage
11% increased Cast Speed
50% chance to gain a Power Charge on Killing a Frozen Enemy
Adds 15 to 25 Cold Damage to Spells per Power Charge
Lose all Power Charges on reaching Maximum Power Charges
Gain a Frenzy Charge on reaching Maximum Power Charges
11% increased Cold Damage per Frenzy Charge
]],[[
The Halcyon
Jade Amulet
Unreleased: true
League: Breach
+(20-30) to Dexterity
18% increased Cold Damage
+38% to Cold Resistance
30% increased Freeze Duration on Enemies
10% chance to Freeze
60% increased Damage if you've Frozen an Enemy Recently
]],
}