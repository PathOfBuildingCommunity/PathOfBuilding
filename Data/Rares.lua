-- Item data (c) Grinding Gear Games

local modSets = {
	["inc Ar"] = [[
{range:.75}(0 to 132)% increased Armour]],
	["inc Ev"] = [[
{range:.75}(0 to 132)% increased Evasion Rating]],
	["inc ES"] = [[
{range:.75}(0 to 132)% increased Energy Shield
{range:0}(0 to 56)% increased Energy Shield]],
	["inc Ar/Ev"] = [[
{range:.75}(0 to 132)% increased Armour and Evasion]],
	["inc Ar/ES"] = [[
{range:.75}(0 to 132)% increased Armour and Energy Shield
{range:0}(0 to 56)% increased Armour and Energy Shield]],
	["inc Ev/ES"] = [[
{range:.75}(0 to 132)% increased Evasion and Energy Shield
{range:0}(0 to 56)% increased Evasion and Energy Shield]],
	["str"] = [[
{range:0}+(0 to 55) to Strength]],
	["dex"] = [[
{range:0}+(0 to 55) to Dexterity]],
	["int"] = [[
{range:0}+(0 to 55) to Intelligence]],
	["res"] = [[
{range:0}+(0 to 48)% to Fire Resistance
{range:0}+(0 to 48)% to Cold Resistance
{range:0}+(0 to 48)% to Lightning Resistance
{range:0}+(0 to 35)% to Chaos Resistance]],
	["shield"] = [[
{res}
{range:0}+(0 to 16)% to all Elemental Resistances
{range:0}(0 to 69)% increased Mana Regeneration Rate
{range:0}(0 to 109)% increased Critical Strike Chance for Spells
{range:0}+(0 to 6)% Chance to Block]],
	["amulet"] = [[
Prefixes:
{range:0}+(0 to 89) to maximum Life
{range:0}+(0 to 73) to maximum Mana
{range:0}+(0 to 51) to maximum Energy Shield
{range:0}Adds (0-15 to 0-26) Physical Damage to Attacks
{range:0}(0 to 22)% increased Armour
{range:0}(0 to 22)% increased Evasion Rating
{range:0}(0 to 22)% increased Energy Shield
{range:0}(0 to 26)% increased Spell Damage
{range:0}(0 to 42)% increased Elemental Damage with Weapons
Suffixes:
{str}
{dex}
{int}
{range:0}+(0 to 32) to all Attributes
{res}
{range:0}+(0 to 16)% to all Elemental Resistances
{range:0}(0 to 13)% increased Cast Speed
{range:0}(0 to 69)% increased Mana Regeneration Rate
{range:0}+(0 to 400) to Accuracy Rating
{range:0}(0 to 38)% increased Global Critical Strike Chance
{range:0}+(0 to 38)% to Global Critical Strike Multiplier
{range:0}(0 to 17)% increased Fire Damage
{range:0}(0 to 17)% increased Cold Damage
{range:0}(0 to 17)% increased Lightning Damage]],
	["ring"] = [[
Prefixes:
{range:0}+(0 to 79) to maximum Life
{range:0}+(0 to 73) to maximum Mana
{range:0}+(0 to 47) to maximum Energy Shield
{range:0}+(0 to 170) to Evasion Rating
{range:0}Adds (0-9 to 0-15) Physical Damage to Attacks
{range:0}(0 to 42)% increased Elemental Damage with Weapons
Suffixes:
{str}
{dex}
{int}
{range:0}+(0 to 16) to all Attributes
{res}
{range:0}+(0 to 16)% to all Elemental Resistances
{range:0}(0 to 7)% increased Cast Speed
{range:0}(0 to 7)% increased Attack Speed
{range:0}(0 to 69)% increased Mana Regeneration Rate
{range:0}+(0 to 400) to Accuracy Rating
{range:0}(0 to 12)% increased Fire Damage
{range:0}(0 to 12)% increased Cold Damage
{range:0}(0 to 12)% increased Lightning Damage]],
	["belt"] = [[
Prefixes:
{range:0}+(0 to 99) to maximum Life
{range:0}+(0 to 51) to maximum Energy Shield
{range:0}+(0 to 460) to Armour
{range:0}(0 to 42)% increased Elemental Damage with Weapons
Suffixes:
{str}
{res}]],
	["phys 1h pre"] = [[
Prefixes:
{range:.5}(0 to 179)% increased Physical Damage
{range:.5}(0 to 79)% increased Physical Damage
{range:.5}Adds (0-25 to 0-45) Physical Damage]],
	["phys 2h pre"] = [[
Prefixes:
{range:.5}(0 to 179)% increased Physical Damage
{range:.5}(0 to 79)% increased Physical Damage
{range:.5}Adds (0-38 to 0-68) Physical Damage]],
	["elem 1h pre"] = [[
Prefixes:
{range:0}Adds (0-61 to 0-106) Fire Damage
{range:0}Adds (0-50 to 0-87) Cold Damage
{range:0}Adds (0-13 to 0-166) Lightning Damage
{range:.5}(0 to 42)% increased Elemental Damage with Weapons]],
	["elem 2h pre"] = [[
Prefixes:
{range:0}Adds (0-91 to 0-160) Fire Damage
{range:0}Adds (0-75 to 0-131) Cold Damage
{range:0}Adds (0-19 to 0-250) Lightning Damage
{range:.5}(0 to 42)% increased Elemental Damage with Weapons]],
	["melee suf"] = [[
Suffixes:
{range:.5}(0 to 27)% increased Attack Speed
{range:.5}(0 to 38)% increased Critical Strike Chance
{range:.5}+(0 to 38)% to Global Critical Strike Multiplier
{range:0}+(0 to 320) to Accuracy Rating]],
	["ranged suf"] = [[
Suffixes:
{range:.5}(0 to 16)% increased Attack Speed
{range:.5}(0 to 38)% increased Critical Strike Chance
{range:.5}+(0 to 38)% to Global Critical Strike Multiplier
{range:0}+(0 to 360) to Accuracy Rating]],
	["phys 1h"] = [[
{phys 1h pre}
{melee suf}]],
	["phys 2h"] = [[
{phys 2h pre}
{melee suf}]],
	["elem 1h"] = [[
{elem 1h pre}
{melee suf}]],
	["elem 2h"] = [[
{elem 2h pre}
{melee suf}]],
	["spell suf"] = [[
Suffixes:
{int}
{range:0}(0 to 25)% increased Cast Speed
{range:0}(0 to 69)% increased Mana Regeneration Rate
{range:0}(0 to 109)% increased Critical Strike Chance for Spells
{range:0}+(0 to 38)% to Global Critical Strike Multiplier
{range:0}(0 to 30)% increased Fire Damage
{range:0}(0 to 30)% increased Cold Damage
{range:0}(0 to 30)% increased Lightning Damage]],
	["spell 1h"] = [[
Prefixes:
{range:.5}(0 to 79)% increased Spell Damage
{range:.5}(0 to 39)% increased Spell Damage
{range:0}Adds (0-49 to 0-85) Fire Damage to Spells
{range:0}Adds (0-40 to 0-69) Cold Damage to Spells
{range:0}Adds (0-10 to 0-133) Lightning Damage to Spells
{spell suf}]],
	["spell 2h"] = [[
Prefixes:
{range:.5}(0 to 115)% increased Spell Damage
{range:.5}(0 to 55)% increased Spell Damage
{range:0}Adds (0-65 to 0-115) Fire Damage to Spells
{range:0}Adds (0-60 to 0-104) Cold Damage to Spells
{range:0}Adds (0-15 to 0-200) Lightning Damage to Spells
{spell suf}]],
}

local rares = {
-- Helmet
[[
Armour Helmet
Eternal Burgonet
Prefixes:
{inc Ar}
{range:.75}+(0 to 138) to Armour
{range:.75}+(0 to 99) to maximum Life
{range:0}+(0 to 2) to Level of Socketed Minion Gems
Suffixes:
{str}
{int}
{res}
]],[[
Evasion Helmet
Lion Pelt
Prefixes:
{inc Ev}
{range:.75}+(0 to 138) to Evasion Rating
{range:.75}+(0 to 99) to maximum Life
{range:0}+(0 to 2) to Level of Socketed Minion Gems
Suffixes:
{dex}
{int}
{res}
]],[[
Energy Shield Helmet
Hubris Circlet
Prefixes:
{inc ES}
{range:.75}+(0 to 72) to maximum Energy Shield
{range:.75}+(0 to 99) to maximum Life
{range:0}+(0 to 2) to Level of Socketed Minion Gems
Suffixes:
{int}
{res}
]],[[
Armour/Evasion Helmet
Nightmare Bascinet
Prefixes:
{inc Ar/Ev}
{range:0}+(0 to 138) to Armour
{range:0}+(0 to 138) to Evasion Rating
{range:.75}+(0 to 99) to maximum Life
{range:0}+(0 to 2) to Level of Socketed Minion Gems
Suffixes:
{str}
{dex}
{int}
{res}
]],[[
Armour/Energy Shield Helmet
Praetor Crown
Prefixes:
{inc Ar/ES}
{range:0}+(0 to 138) to Armour
{range:0}+(0 to 72) to maximum Energy Shield
{range:.75}+(0 to 99) to maximum Life
{range:0}+(0 to 2) to Level of Socketed Minion Gems
Suffixes:
{str}
{int}
{res}
]],[[
Evasion/Energy Shield Helmet
Deicide Mask
Prefixes:
{inc Ev/ES}
{range:0}+(0 to 138) to Evasion Rating
{range:0}+(0 to 72) to maximum Energy Shield
{range:.75}+(0 to 99) to maximum Life
{range:0}+(0 to 2) to Level of Socketed Minion Gems
Suffixes:
{dex}
{int}
{res}
]],
-- Gloves
[[
Armour Gloves
Titan Gauntlets
Prefixes:
{inc Ar}
{range:.75}+(0 to 80) to Armour
{range:.75}+(0 to 89) to maximum Life
{range:0}Adds (0-6 to 0-10) Physical Damage to Attacks
Suffixes:
{range:0}(0 to 16)% increased Attack Speed
{str}
{dex}
{res}
]],[[
Evasion Gloves
Slink Gloves
Prefixes:
{inc Ev}
{range:.75}+(0 to 80) to Evasion Rating
{range:.75}+(0 to 89) to maximum Life
{range:0}Adds (0-6 to 0-10) Physical Damage to Attacks
Suffixes:
{range:0}(0 to 16)% increased Attack Speed
{dex}
{res}
]],[[
Energy Shield Gloves
Sorcerer Gloves
Prefixes:
{inc ES}
{range:.75}+(0 to 48) to maximum Energy Shield
{range:.75}+(0 to 89) to maximum Life
{range:0}Adds (0-6 to 0-10) Physical Damage to Attacks
Suffixes:
{range:0}(0 to 16)% increased Attack Speed
{dex}
{int}
{res}
]],[[
Armour/Evasion Gloves
Dragonscale Gauntlets
Prefixes:
{inc Ar/Ev}
{range:0}+(0 to 80) to Armour
{range:0}+(0 to 80) to Evasion Rating
{range:.75}+(0 to 89) to maximum Life
{range:0}Adds (0-6 to 0-10) Physical Damage to Attacks
Suffixes:
{range:0}(0 to 16)% increased Attack Speed
{str}
{dex}
{res}
]],[[
Armour/Energy Shield Gloves
Crusader Gloves
Prefixes:
{inc Ar/ES}
{range:0}+(0 to 80) to Armour
{range:0}+(0 to 48) to maximum Energy Shield
{range:.75}+(0 to 89) to maximum Life
{range:0}Adds (0-6 to 0-10) Physical Damage to Attacks
Suffixes:
{range:0}(0 to 16)% increased Attack Speed
{str}
{dex}
{int}
{res}
]],[[
Evasion/Energy Shield Gloves
Murder Mitts
Prefixes:
{inc Ev/ES}
{range:0}+(0 to 80) to Evasion Rating
{range:0}+(0 to 48) to maximum Energy Shield
{range:.75}+(0 to 89) to maximum Life
{range:0}Adds (0-6 to 0-10) Physical Damage to Attacks
Suffixes:
{range:0}(0 to 16)% increased Attack Speed
{dex}
{int}
{res}
]],
-- Body Armour
[[
Armour Chest
Glorious Plate
Prefixes:
{inc Ar}
{range:.75}+(0 to 400) to Armour
{range:.75}+(0 to 119) to maximum Life
Suffixes:
{str}
{res}
]],[[
Evasion Chest
Assassin's Garb
3% increased Movement Speed
Prefixes:
{inc Ev}
{range:.75}+(0 to 400) to Evasion Rating
{range:.75}+(0 to 119) to maximum Life
Suffixes:
{dex}
{res}
]],[[
Energy Shield Chest
Vaal Regalia
Prefixes:
{inc ES}
{range:.75}+(0 to 145) to maximum Energy Shield
{range:.75}+(0 to 119) to maximum Life
Suffixes:
{int}
{res}
]],[[
Armour/Evasion Chest
Triumphant Lamellar
Prefixes:
{inc Ar/Ev}
{range:0}+(0 to 400) to Armour
{range:0}+(0 to 400) to Evasion Rating
{range:.75}+(0 to 119) to maximum Life
Suffixes:
{str}
{dex}
{res}
]],[[
Armour/Energy Shield Chest
Saintly Chainmail
Prefixes:
{inc Ar/ES}
{range:0}+(0 to 400) to Armour
{range:0}+(0 to 145) to maximum Energy Shield
{range:.75}+(0 to 119) to maximum Life
Suffixes:
{str}
{int}
{res}
]],[[
Evasion/Energy Shield Chest
Carnal Armour
+(20 to 25) to maximum Mana
Prefixes:
{inc Ev/ES}
{range:0}+(0 to 400) to Evasion Rating
{range:0}+(0 to 145) to maximum Energy Shield
{range:.75}+(0 to 119) to maximum Life
Suffixes:
{dex}
{int}
{res}
]],
-- Boots
[[
Armour Boots
Titan Greaves
Prefixes:
{inc Ar}
{range:0}+(0 to 80) to Armour
{range:.75}+(0 to 89) to maximum Life
{range:1}(0 to 30)% increased Movement Speed
Suffixes:
{str}
{res}
]],[[
Evasion Boots
Slink Boots
Prefixes:
{inc Ev}
{range:0}+(0 to 80) to Evasion Rating
{range:.75}+(0 to 89) to maximum Life
{range:1}(0 to 30)% increased Movement Speed
Suffixes:
{dex}
{res}
]],[[
Energy Shield Boots
Sorcerer Boots
Prefixes:
{inc ES}
{range:0}+(0 to 48) to maximum Energy Shield
{range:.75}+(0 to 89) to maximum Life
{range:1}(0 to 30)% increased Movement Speed
Suffixes:
{int}
{res}
]],[[
Armour/Evasion Boots
Dragonscale Boots
Prefixes:
{inc Ar/Ev}
{range:0}+(0 to 80) to Armour
{range:0}+(0 to 80) to Evasion Rating
{range:.75}+(0 to 89) to maximum Life
{range:1}(0 to 30)% increased Movement Speed
Suffixes:
{str}
{dex}
{res}
]],[[
Armour/Energy Shield Boots
Crusader Boots
Prefixes:
{inc Ar/ES}
{range:0}+(0 to 80) to Armour
{range:0}+(0 to 48) to maximum Energy Shield
{range:.75}+(0 to 89) to maximum Life
{range:1}(0 to 30)% increased Movement Speed
Suffixes:
{str}
{int}
{res}
]],[[
Evasion/Energy Shield Boots
Murder Boots
Prefixes:
{inc Ev/ES}
{range:0}+(0 to 80) to Evasion Rating
{range:0}+(0 to 48) to maximum Energy Shield
{range:.75}+(0 to 89) to maximum Life
{range:1}(0 to 30)% increased Movement Speed
Suffixes:
{dex}
{int}
{res}
]],
-- Shields
[[
Armour Shield
Pinnacle Tower Shield
Prefixes:
{inc Ar}
{range:.75}+(0 to 400) to Armour
{range:.75}+(0 to 109) to maximum Life
Suffixes:
{range:0}+(0 to 55) to Strength
{shield}
]],[[
Evasion Shield
Imperial Buckler
Prefixes:
{inc Ev}
{range:.75}+(0 to 400) to Evasion Rating
{range:.75}+(0 to 109) to maximum Life
Suffixes:
{range:0}+(0 to 55) to Dexterity
{shield}
]],[[
Energy Shield Shield
Titanium Spirit Shield
Prefixes:
{inc ES}
{range:.75}+(0 to 135) to maximum Energy Shield
{range:.75}+(0 to 109) to maximum Life
{range:0}(0 to 79)% increased Spell Damage
Suffixes:
{range:0}+(0 to 55) to Intelligence
{shield}
]],[[
Armour/Evasion Shield
Elegant Round Shield
120% increased Block Recovery
Prefixes:
{inc Ar/Ev}
{range:0}+(0 to 400) to Armour
{range:0}+(0 to 400) to Evasion Rating
{range:.75}+(0 to 109) to maximum Life
Suffixes:
{range:0}+(0 to 55) to Strength
{range:0}+(0 to 55) to Dexterity
{shield}
]],[[
Armour/Energy Shield Shield
Archon Kite Shield
+12% to all Elemental Resistances
Prefixes:
{inc Ar/ES}
{range:0}+(0 to 400) to Armour
{range:0}+(0 to 135) to maximum Energy Shield
{range:.75}+(0 to 109) to maximum Life
Suffixes:
{range:0}+(0 to 55) to Strength
{range:0}+(0 to 55) to Intelligence
{shield}
]],[[
Evasion/Energy Shield Shield
Supreme Spiked Shield
Reflects (221 to 260) Physical Damage to Melee Attackers
Prefixes:
{inc Ev/ES}
{range:0}+(0 to 400) to Evasion Rating
{range:0}+(0 to 135) to maximum Energy Shield
{range:.75}+(0 to 109) to maximum Life
Suffixes:
{range:0}+(0 to 55) to Dexterity
{range:0}+(0 to 55) to Intelligence
{shield}
]],
-- Amulets
[[
Amulet
Amber Amulet
+(20 to 30) Strength
{amulet}
]],[[
Amulet
Jade Amulet
+(20 to 30) Dexterity
{amulet}
]],[[
Amulet
Lapis Amulet
+(20 to 30) Intelligence
{amulet}
]],[[
Amulet
Onyx Amulet
+(10 to 16) to all Attributes
{amulet}
]],[[
Amulet
Agate Amulet
+(16 to 24) to Strength and Intelligence
{amulet}
]],[[
Amulet
Turquoise Amulet
+(16 to 24) to Dexterity and Intelligence
{amulet}
]],[[
Amulet
Citrine Amulet
+(16 to 24) to Strength and Dexterity
{amulet}
]],[[
Amulet
Paua Amulet
(20 to 30)% increased Mana Regeneration Rate
{amulet}
]],
-- Rings
[[
Ring
Paua Ring
+(20 to 25) to Maximum Mana
{ring}
]],[[
Ring
Moonstone Ring
+(15 to 25) to maximum Energy Shield
{ring}
]],[[
Ring
Diamond Ring
(20 to 30)% increased Global Critical Strike Chance
{ring}
]],[[
Ring
Ruby Ring
+(20 to 30)% to Fire Resistance
{ring}
]],[[
Ring
Sapphire Ring
+(20 to 30)% to Cold Resistance
{ring}
]],[[
Ring
Topaz Ring
+(20 to 30)% to Lightning Resistance
{ring}
]],[[
Ring
Amethyst Ring
+(9 to 13)% to Chaos Resistance
{ring}
]],[[
Ring
Ruby Ring
+(20 to 30)% to Fire Resistance
{ring}
]],[[
Ring
Two-Stone Ring
Variant: Fire and Cold
Variant: Cold and Lightning
Variant: Fire and Lightning
Implicits: 3
{variant:1}+(12 to 16)% to Fire and Cold Resistances
{variant:2}+(12 to 16)% to Cold and Lightning Resistances
{variant:3}+(12 to 16)% to Fire and Lightning Resistances
{ring}
]],
-- Belts
[[
Belt
Rustic Sash
(12 to 24)% increased Physical Damage
{belt}
]],[[
Belt
Chain Belt
+(9 to 20) to maximum Energy Shield
{belt}
]],[[
Belt
Leather Belt
+(25 to 40) to maximum Life
{belt}
]],[[
Belt
Heavy Belt
+(25 to 35) to Strength
{belt}
]],
-- Quivers
[[
Quiver
Spike-Point Arrow Quiver
(20 to 30)% increased Global Critical Strike Chance
Prefixes:
{range:.75}+(0 to 99) to maximum Life
{range:.5}Adds (0-6 to 0-10) Physical Damage to Attacks
{range:.5}(0 to 42)% increased Elemental Damage with Weapons
Suffixes:
{range:.5}(0 to 12)% increased Attack Speed
{range:.5}(0 to 38)% increased Critical Strike Chance
{range:.5}+(0 to 38)% to Global Critical Strike Multiplier
]],
-- Weapons
[[
Physical 1H Axe
Runic Hatchet
12% increased Physical Damage
{phys 1h}
]],[[
Elemental 1H Axe
Vaal Hatchet
{elem 1h}
]],[[
Physical 2H Axe
Fleshripper
40% increased Critical Strike Chance
{phys 2h}
]],[[
Elemental 2H Axe
Despot Axe
{elem 2h}
]],[[
Physical Bow
Harbinger Bow
(30 to 50)% increased Critical Strike Chance
{phys 2h pre}
{ranged suf}
]],[[
Elemental Bow
Thicket Bow
{elem 1h pre}
{ranged suf}
]],[[
+3 Bow
Thicket Bow
Prefixes:
{range:1}+(0 to 1) to Level of Socketed Gems
{range:1}+(0 to 2) to Level of Socketed Bow Gems
{range:0}(0 to 30)% increased Damage over Time
Suffixes:
{range:0}(0 to 16)% increased Attack Speed
]],[[
Physical Claw
Gemini Claw
+14 Life and Mana gained for each Enemy hit
{phys 1h}
]],[[
Elemental Claw
Imperial Claw
+25 Life gained for each Enemy hit by Attacks
{elem 1h}
]],[[
Physical Dagger
Imperial Skean
40% increased Global Critical Strike Chance
{phys 1h}
]],[[
Elemental Dagger
Imperial Skean
40% increased Global Critical Strike Chance
{elem 1h}
]],[[
Spell Dagger
Platinum Kris
80% increased Global Critical Strike Chance
{spell 1h}
]],[[
Vagan Dagger
Royal Skean
40% increased Global Critical Strike Chance
Prefixes:
Hits can't be Evaded
{range:0}Adds (0-61 to 0-106) Fire Damage
{range:0}Adds (0-50 to 0-87) Cold Damage
{range:0}Adds (0-13 to 0-166) Lightning Damage
{range:.5}(0 to 79)% increased Spell Damage
Suffixes:
{range:.5}(0 to 16)% increased Attack Speed
{range:.5}(0 to 38)% increased Critical Strike Chance
]],[[
Spell Sceptre
Void Sceptre
15% increased Elemental Damage
{spell 1h}
]],[[
Physical 1H Mace
Behemoth Mace
6% increased Attack Speed
{phys 1h}
]],[[
Elemental 1H Mace
Behemoth Mace
6% increased Attack Speed
{elem 1h}
]],[[
Physical 2H Mace
Coronal Maul
6% increased Radius of Area Skills
{phys 2h}
]],[[
Elemental 2H Mace
Coronal Maul
6% increased Radius of Area Skills
{elem 2h}
]],[[
Physical Staff
Eclipse Staff
80% increased Global Critical Strike Chance
{phys 2h}
]],[[
Elemental Staff
Eclipse Staff
80% increased Global Critical Strike Chance
{elem 2h}
]],[[
Spell Staff
Eclipse Staff
80% increased Global Critical Strike Chance
{spell 2h}
]],[[
+3 Fire Staff
Maelstrom Staff
18% Chance to Block
Prefixes:
{range:1}+(0 to 1) to Level of Socketed Gems
{range:1}+(0 to 2) to Level of Socketed Fire Gems
{range:.5}(0 to 115)% increased Spell Damage
{range:0}Adds (0-65 to 0-115) Fire Damage to Spells
{range:0}Adds (0-60 to 0-104) Cold Damage to Spells
{range:0}Adds (0-15 to 0-200) Lightning Damage to Spells
{spell suf}
]],[[
+3 Cold Staff
Maelstrom Staff
18% Chance to Block
Prefixes:
{range:1}+(0 to 1) to Level of Socketed Gems
{range:1}+(0 to 2) to Level of Socketed Cold Gems
{range:.5}(0 to 115)% increased Spell Damage
{range:0}Adds (0-65 to 0-115) Fire Damage to Spells
{range:0}Adds (0-60 to 0-104) Cold Damage to Spells
{range:0}Adds (0-15 to 0-200) Lightning Damage to Spells
{spell suf}
]],[[
+3 Lightning Staff
Maelstrom Staff
18% Chance to Block
Prefixes:
{range:1}+(0 to 1) to Level of Socketed Gems
{range:1}+(0 to 2) to Level of Socketed Lightning Gems
{range:.5}(0 to 115)% increased Spell Damage
{range:0}Adds (0-65 to 0-115) Fire Damage to Spells
{range:0}Adds (0-60 to 0-104) Cold Damage to Spells
{range:0}Adds (0-15 to 0-200) Lightning Damage to Spells
{spell suf}
]],[[
+2 Chaos Staff
Maelstrom Staff
18% Chance to Block
Prefixes:
{range:1}+(0 to 1) to Level of Socketed Gems
{range:1}+(0 to 1) to Level of Socketed Chaos Gems
{range:.5}(0 to 115)% increased Spell Damage
{range:0}Adds (0-65 to 0-115) Fire Damage to Spells
{range:0}Adds (0-60 to 0-104) Cold Damage to Spells
{range:0}Adds (0-15 to 0-200) Lightning Damage to Spells
{spell suf}
]],[[
Physical 1H Sword
Tiger Hook
3% chance to Dodge Attacks
{phys 1h}
]],[[
Elemental 1H Sword
Eternal Sword
18% increased Accuracy Rating
{elem 1h}
]],[[
Physical 2H Sword
Exquisite Blade
+60% to Global Critical Strike Multiplier
{phys 2h}
]],[[
Elemental 2H Sword
Reaver Sword
18% increased Accuracy Rating
{elem 2h}
]],[[
Physical Wand
Imbued Wand
(15 to 19)% increased Spell Damage
{phys 1h pre}
{ranged suf}
]],[[
Elemental Wand
Imbued Wand
(15 to 19)% increased Spell Damage
{elem 1h pre}
{ranged suf}
]],[[
Spell Wand
Prophecy Wand
(16 to 20)% increased Spell Damage
{spell 1h}
]],
}

for i, rare in pairs(rares) do
	rares[i] = "Rarity: Rare\n"..rare
end
while true do
	local didReplace
	for key, set in pairs(modSets) do
		for i, rare in pairs(rares) do
			if rare:match("{"..key.."}") then
				didReplace = true		
				rares[i] = rare:gsub("{"..key.."}",function() return set end)
			end
		end
	end
	if not didReplace then
		break
	end
end
return rares