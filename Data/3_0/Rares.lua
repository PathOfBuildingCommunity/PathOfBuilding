-- Item data (c) Grinding Gear Games

local modSets = {
	["inc Ar"] = [[
{range:.75}(0-132)% increased Armour]],
	["inc Ev"] = [[
{range:.75}(0-132)% increased Evasion Rating]],
	["inc ES"] = [[
{range:.75}(0-132)% increased Energy Shield
{range:0}(0-56)% increased Energy Shield]],
	["inc Ar/Ev"] = [[
{range:.75}(0-132)% increased Armour and Evasion]],
	["inc Ar/ES"] = [[
{range:.75}(0-132)% increased Armour and Energy Shield
{range:0}(0-56)% increased Armour and Energy Shield]],
	["inc Ev/ES"] = [[
{range:.75}(0-132)% increased Evasion and Energy Shield
{range:0}(0-56)% increased Evasion and Energy Shield]],
	["str"] = [[
{range:0}+(0-55) to Strength]],
	["dex"] = [[
{range:0}+(0-55) to Dexterity]],
	["int"] = [[
{range:0}+(0-55) to Intelligence]],
	["res"] = [[
{range:0}+(0-48)% to Fire Resistance
{range:0}+(0-48)% to Cold Resistance
{range:0}+(0-48)% to Lightning Resistance
{range:0}+(0-35)% to Chaos Resistance]],
	["gloves"] = [[
{range:0}Adds (0-6) to (0-10) Physical Damage to Attacks
{range:0}Adds (0-10) to (0-18) Fire Damage to Attacks
{range:0}Adds (0-9) to (0-16) Cold Damage to Attacks
{range:0}Adds (0-2) to (0-28) Lightning Damage to Attacks
Suffixes:
{range:0}(0-16)% increased Attack Speed
{range:0}+(0-400) to Accuracy Rating]],
	["shield"] = [[
{res}
{range:0}+(0-16)% to all Elemental Resistances
{range:0}(0-69)% increased Mana Regeneration Rate
{range:0}(0-109)% increased Critical Strike Chance for Spells
{range:0}+(0-6)% Chance to Block]],
	["amulet"] = [[
Prefixes:
{range:0}+(0-89) to maximum Life
{range:0}+(0-73) to maximum Mana
{range:0}+(0-51) to maximum Energy Shield
{range:0}Adds (0-15) to (0-26) Physical Damage to Attacks
{range:0}Adds (0-25) to (0-45) Fire Damage to Attacks
{range:0}Adds (0-22) to (0-40) Cold Damage to Attacks
{range:0}Adds (0-7) to (0-72) Lightning Damage to Attacks
{range:0}(0-22)% increased Armour
{range:0}(0-22)% increased Evasion Rating
{range:0}(0-22)% increased Energy Shield
{range:0}(0-26)% increased Spell Damage
{range:0}(0-42)% increased Elemental Damage with Weapons
Suffixes:
{str}
{dex}
{int}
{range:0}+(0-32) to all Attributes
{res}
{range:0}+(0-16)% to all Elemental Resistances
{range:0}(0-13)% increased Cast Speed
{range:0}(0-69)% increased Mana Regeneration Rate
{range:0}+(0-400) to Accuracy Rating
{range:0}(0-38)% increased Global Critical Strike Chance
{range:0}+(0-38)% to Global Critical Strike Multiplier
{range:0}(0-17)% increased Fire Damage
{range:0}(0-17)% increased Cold Damage
{range:0}(0-17)% increased Lightning Damage]],
	["ring"] = [[
{range:0}+(0-79) to maximum Life
{range:0}+(0-73) to maximum Mana
{range:0}+(0-47) to maximum Energy Shield
{range:0}+(0-170) to Evasion Rating
{range:0}Adds (0-9) to (0-15) Physical Damage to Attacks
{range:0}Adds (0-25) to (0-45) Fire Damage to Attacks
{range:0}Adds (0-22) to (0-40) Cold Damage to Attacks
{range:0}Adds (0-7) to (0-72) Lightning Damage to Attacks
{range:0}(0-42)% increased Elemental Damage with Weapons
Suffixes:
{str}
{dex}
{int}
{range:0}+(0-16) to all Attributes
{res}
{range:0}+(0-16)% to all Elemental Resistances
{range:0}(0-7)% increased Cast Speed
{range:0}(0-7)% increased Attack Speed
{range:0}(0-69)% increased Mana Regeneration Rate
{range:0}+(0-400) to Accuracy Rating
{range:0}(0-12)% increased Fire Damage
{range:0}(0-12)% increased Cold Damage
{range:0}(0-12)% increased Lightning Damage]],
	["belt"] = [[
Prefixes:
{range:0}+(0-99) to maximum Life
{range:0}+(0-51) to maximum Energy Shield
{range:0}+(0-460) to Armour
{range:0}(0-42)% increased Elemental Damage with Weapons
{range:0}(0-20)% increased Flask Life Recovery rate
{range:0}(0-20)% increased Flask Mana Recovery rate
Suffixes:
{str}
{res}
{range:0}(0-20)% increased Flask Charges gained
{range:0}(0-20)% reduced Flask Charges used
{range:0}(0-20)% increased Flask effect duration]],
	["phys 1h pre"] = [[
Prefixes:
{range:.5}(0-179)% increased Physical Damage
{range:.5}(0-79)% increased Physical Damage
{range:.5}Adds (0-27) to (0-49) Physical Damage]],
	["phys 2h pre"] = [[
Prefixes:
{range:.5}(0-179)% increased Physical Damage
{range:.5}(0-79)% increased Physical Damage
{range:.5}Adds (0-38) to (0-68) Physical Damage]],
	["elem 1h pre"] = [[
Prefixes:
{range:0}Adds (0-61) to (0-106) Fire Damage
{range:0}Adds (0-50) to (0-87) Cold Damage
{range:0}Adds (0-13) to (0-166) Lightning Damage
{range:.5}(0-42)% increased Elemental Damage with Weapons]],
	["elem 2h pre"] = [[
Prefixes:
{range:0}Adds (0-91) to (0-160) Fire Damage
{range:0}Adds (0-75) to (0-131) Cold Damage
{range:0}Adds (0-19) to (0-250) Lightning Damage
{range:.5}(0-42)% increased Elemental Damage with Weapons]],
	["melee suf"] = [[
Suffixes:
{range:.5}(0-27)% increased Attack Speed
{range:.5}(0-38)% increased Critical Strike Chance
{range:.5}+(0-38)% to Global Critical Strike Multiplier
{range:0}+(0-320) to Accuracy Rating]],
	["ranged suf"] = [[
Suffixes:
{range:.5}(0-16)% increased Attack Speed
{range:.5}(0-38)% increased Critical Strike Chance
{range:.5}+(0-38)% to Global Critical Strike Multiplier
{range:0}+(0-360) to Accuracy Rating]],
	["phys 1h"] = [[
{phys 1h pre}
{range:0}Adds (0-72) to (0-123) Chaos Damage
{melee suf}]],
	["phys 2h"] = [[
{phys 2h pre}
{range:0}Adds (0-108) to (0-185) Chaos Damage
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
{range:0}(0-25)% increased Cast Speed
{range:0}(0-69)% increased Mana Regeneration Rate
{range:0}(0-109)% increased Critical Strike Chance for Spells
{range:0}+(0-38)% to Global Critical Strike Multiplier
{range:0}(0-30)% increased Fire Damage
{range:0}(0-30)% increased Cold Damage
{range:0}(0-30)% increased Lightning Damage]],
	["spell 1h"] = [[
Prefixes:
{range:.5}(0-79)% increased Spell Damage
{range:.5}(0-39)% increased Spell Damage
{range:0}Adds (0-49) to (0-85) Fire Damage to Spells
{range:0}Adds (0-40) to (0-69) Cold Damage to Spells
{range:0}Adds (0-10) to (0-133) Lightning Damage to Spells
{spell suf}]],
	["spell 2h"] = [[
Prefixes:
{range:.5}(0-115)% increased Spell Damage
{range:.5}(0-55)% increased Spell Damage
{range:0}Adds (0-65) to (0-115) Fire Damage to Spells
{range:0}Adds (0-60) to (0-104) Cold Damage to Spells
{range:0}Adds (0-15) to (0-200) Lightning Damage to Spells
{spell suf}]],
	["jewel pre"] = [[
Prefixes:
{range:0}(0-16)% increased Physical Damage
{range:0}(0-16)% increased Fire Damage
{range:0}(0-16)% increased Cold Damage
{range:0}(0-16)% increased Lightning Damage
{range:0}(0-16)% increased Chaos Damage
{range:0}(0-16)% increased Totem Damage
{range:0}(0-7)% increased maximum Life]],
	["jewel suf"] = [[
Suffixes:
{range:0}+(0-16) to Strength
{range:0}+(0-16) to Dexterity
{range:0}+(0-16) to Intelligence
{range:0}(0-10)% increased Damage
{range:0}(0-12)% increased Projectile Damage
{range:0}(0-12)% increased Damage over Time
{range:0}(0-12)% increased Area Damage
{range:0}(0-4)% increased Attack and Cast Speed
{range:0}(0-5)% increased Attack Speed]],
}

local rares = {
-- Helmet
[[
Armour Helmet
Eternal Burgonet
Prefixes:
{inc Ar}
{range:.75}+(0-138) to Armour
{range:.75}+(0-99) to maximum Life
{range:0}+(0-2) to Level of Socketed Minion Gems
Suffixes:
{range:0}+(0-400) to Accuracy Rating
{str}
{int}
{res}
]],[[
Evasion Helmet
Lion Pelt
Prefixes:
{inc Ev}
{range:.75}+(0-138) to Evasion Rating
{range:.75}+(0-99) to maximum Life
{range:0}+(0-2) to Level of Socketed Minion Gems
Suffixes:
{range:0}+(0-400) to Accuracy Rating
{dex}
{int}
{res}
]],[[
Energy Shield Helmet
Hubris Circlet
Prefixes:
{inc ES}
{range:.75}+(0-72) to maximum Energy Shield
{range:.75}+(0-99) to maximum Life
{range:0}+(0-73) to maximum Mana
{range:0}+(0-2) to Level of Socketed Minion Gems
Suffixes:
{range:0}+(0-400) to Accuracy Rating
{int}
{res}
]],[[
Armour/Evasion Helmet
Nightmare Bascinet
Prefixes:
{inc Ar/Ev}
{range:0}+(0-138) to Armour
{range:0}+(0-138) to Evasion Rating
{range:.75}+(0-99) to maximum Life
{range:0}+(0-2) to Level of Socketed Minion Gems
Suffixes:
{range:0}+(0-400) to Accuracy Rating
{str}
{dex}
{int}
{res}
]],[[
Armour/Energy Shield Helmet
Praetor Crown
Prefixes:
{inc Ar/ES}
{range:0}+(0-138) to Armour
{range:0}+(0-72) to maximum Energy Shield
{range:.75}+(0-99) to maximum Life
{range:0}+(0-73) to maximum Mana
{range:0}+(0-2) to Level of Socketed Minion Gems
Suffixes:
{range:0}+(0-400) to Accuracy Rating
{str}
{int}
{res}
]],[[
Armour/Energy Shield Helmet
Bone Helmet
Minions deal (30-40)% increased Damage
Prefixes:
{inc Ar/ES}
{range:0}+(0-138) to Armour
{range:0}+(0-72) to maximum Energy Shield
{range:.75}+(0-99) to maximum Life
{range:0}+(0-73) to maximum Mana
{range:0}+(0-2) to Level of Socketed Minion Gems
Suffixes:
{range:0}+(0-400) to Accuracy Rating
{str}
{int}
{res}
]],[[
Evasion/Energy Shield Helmet
Deicide Mask
Prefixes:
{inc Ev/ES}
{range:0}+(0-138) to Evasion Rating
{range:0}+(0-72) to maximum Energy Shield
{range:.75}+(0-99) to maximum Life
{range:0}+(0-73) to maximum Mana
{range:0}+(0-2) to Level of Socketed Minion Gems
Suffixes:
{range:0}+(0-400) to Accuracy Rating
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
{range:.75}+(0-80) to Armour
{range:.75}+(0-89) to maximum Life
{gloves}
{str}
{dex}
{res}
]],[[
Armour Gloves
Spiked Gloves
(16-20)% increased Melee Damage
Prefixes:
{inc Ar}
{range:.75}+(0-80) to Armour
{range:.75}+(0-89) to maximum Life
{gloves}
{str}
{dex}
{res}
]],[[
Evasion Gloves
Slink Gloves
Prefixes:
{inc Ev}
{range:.75}+(0-80) to Evasion Rating
{range:.75}+(0-89) to maximum Life
{gloves}
{dex}
{res}
]],[[
Evasion Gloves
Gripped Gloves
(14-18)% increased Projectile Attack Damage
Prefixes:
{inc Ev}
{range:.75}+(0-80) to Evasion Rating
{range:.75}+(0-89) to maximum Life
{gloves}
{dex}
{res}
]],[[
Energy Shield Gloves
Sorcerer Gloves
Prefixes:
{inc ES}
{range:.75}+(0-48) to maximum Energy Shield
{range:.75}+(0-89) to maximum Life
{range:0}+(0-73) to maximum Mana
{gloves}
{dex}
{int}
{res}
]],[[
Energy Shield Gloves
Fingerless Silk Gloves
(12-16)% increased Spell Damage
Prefixes:
{inc ES}
{range:.75}+(0-48) to maximum Energy Shield
{range:.75}+(0-89) to maximum Life
{range:0}+(0-73) to maximum Mana
{gloves}
{dex}
{int}
{res}
]],[[
Armour/Evasion Gloves
Dragonscale Gauntlets
Prefixes:
{inc Ar/Ev}
{range:0}+(0-80) to Armour
{range:0}+(0-80) to Evasion Rating
{range:.75}+(0-89) to maximum Life
{gloves}
{str}
{dex}
{res}
]],[[
Armour/Energy Shield Gloves
Crusader Gloves
Prefixes:
{inc Ar/ES}
{range:0}+(0-80) to Armour
{range:0}+(0-48) to maximum Energy Shield
{range:.75}+(0-89) to maximum Life
{range:0}+(0-73) to maximum Mana
{gloves}
{str}
{dex}
{int}
{res}
]],[[
Evasion/Energy Shield Gloves
Murder Mitts
Prefixes:
{inc Ev/ES}
{range:0}+(0-80) to Evasion Rating
{range:0}+(0-48) to maximum Energy Shield
{range:.75}+(0-89) to maximum Life
{range:0}+(0-73) to maximum Mana
{gloves}
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
{range:.75}+(0-400) to Armour
{range:.75}+(0-119) to maximum Life
Suffixes:
{str}
{res}
]],[[
Armour Chest
Astral Plate
+(8-12)% to all Elemental Resistances
Prefixes:
{inc Ar}
{range:.75}+(0-400) to Armour
{range:.75}+(0-119) to maximum Life
Suffixes:
{str}
{res}
]],[[
Evasion Chest
Assassin's Garb
3% increased Movement Speed
Prefixes:
{inc Ev}
{range:.75}+(0-400) to Evasion Rating
{range:.75}+(0-119) to maximum Life
Suffixes:
{dex}
{res}
]],[[
Evasion Chest
Zodiac Leather
Prefixes:
{inc Ev}
{range:.75}+(0-400) to Evasion Rating
{range:.75}+(0-119) to maximum Life
Suffixes:
{dex}
{res}
]],[[
Energy Shield Chest
Vaal Regalia
Prefixes:
{inc ES}
{range:.75}+(0-145) to maximum Energy Shield
{range:.75}+(0-119) to maximum Life
{range:0}+(0-73) to maximum Mana
Suffixes:
{int}
{res}
]],[[
Armour/Evasion Chest
Triumphant Lamellar
Prefixes:
{inc Ar/Ev}
{range:0}+(0-400) to Armour
{range:0}+(0-400) to Evasion Rating
{range:.75}+(0-119) to maximum Life
Suffixes:
{str}
{dex}
{res}
]],[[
Armour/Energy Shield Chest
Saintly Chainmail
Prefixes:
{inc Ar/ES}
{range:0}+(0-400) to Armour
{range:0}+(0-145) to maximum Energy Shield
{range:.75}+(0-119) to maximum Life
{range:0}+(0-73) to maximum Mana
Suffixes:
{str}
{int}
{res}
]],[[
Evasion/Energy Shield Chest
Carnal Armour
+(20-25) to maximum Mana
Prefixes:
{inc Ev/ES}
{range:0}+(0-400) to Evasion Rating
{range:0}+(0-145) to maximum Energy Shield
{range:.75}+(0-119) to maximum Life
{range:0}+(0-73) to maximum Mana
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
{range:0}+(0-80) to Armour
{range:.75}+(0-89) to maximum Life
{range:1}(0-30)% increased Movement Speed
Suffixes:
{str}
{res}
]],[[
Evasion Boots
Slink Boots
Prefixes:
{inc Ev}
{range:0}+(0-80) to Evasion Rating
{range:.75}+(0-89) to maximum Life
{range:1}(0-30)% increased Movement Speed
Suffixes:
{dex}
{res}
]],[[
Energy Shield Boots
Sorcerer Boots
Prefixes:
{inc ES}
{range:0}+(0-48) to maximum Energy Shield
{range:.75}+(0-89) to maximum Life
{range:0}+(0-73) to maximum Mana
{range:1}(0-30)% increased Movement Speed
Suffixes:
{int}
{res}
]],[[
Armour/Evasion Boots
Dragonscale Boots
Prefixes:
{inc Ar/Ev}
{range:0}+(0-80) to Armour
{range:0}+(0-80) to Evasion Rating
{range:.75}+(0-89) to maximum Life
{range:1}(0-30)% increased Movement Speed
Suffixes:
{str}
{dex}
{res}
]],[[
Armour/Energy Shield Boots
Crusader Boots
Prefixes:
{inc Ar/ES}
{range:0}+(0-80) to Armour
{range:0}+(0-48) to maximum Energy Shield
{range:.75}+(0-89) to maximum Life
{range:0}+(0-73) to maximum Mana
{range:1}(0-30)% increased Movement Speed
Suffixes:
{str}
{int}
{res}
]],[[
Evasion/Energy Shield Boots
Murder Boots
Prefixes:
{inc Ev/ES}
{range:0}+(0-80) to Evasion Rating
{range:0}+(0-48) to maximum Energy Shield
{range:.75}+(0-89) to maximum Life
{range:0}+(0-73) to maximum Mana
{range:1}(0-30)% increased Movement Speed
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
{range:.75}+(0-400) to Armour
{range:.75}+(0-109) to maximum Life
Suffixes:
{str}
{shield}
]],[[
Evasion Shield
Imperial Buckler
Prefixes:
{inc Ev}
{range:.75}+(0-400) to Evasion Rating
{range:.75}+(0-109) to maximum Life
Suffixes:
{dex}
{shield}
]],[[
Energy Shield Shield
Titanium Spirit Shield
Prefixes:
{inc ES}
{range:.75}+(0-135) to maximum Energy Shield
{range:.75}+(0-109) to maximum Life
{range:0}+(0-73) to maximum Mana
{range:0}(0-79)% increased Spell Damage
Suffixes:
{int}
{shield}
]],[[
Armour/Evasion Shield
Elegant Round Shield
120% increased Block Recovery
Prefixes:
{inc Ar/Ev}
{range:0}+(0-400) to Armour
{range:0}+(0-400) to Evasion Rating
{range:.75}+(0-109) to maximum Life
Suffixes:
{str}
{dex}
{shield}
]],[[
Armour/Energy Shield Shield
Archon Kite Shield
+12% to all Elemental Resistances
Prefixes:
{inc Ar/ES}
{range:0}+(0-400) to Armour
{range:0}+(0-135) to maximum Energy Shield
{range:.75}+(0-109) to maximum Life
{range:0}+(0-73) to maximum Mana
Suffixes:
{str}
{int}
{shield}
]],[[
Evasion/Energy Shield Shield
Supreme Spiked Shield
Reflects (221-260) Physical Damage to Melee Attackers
Prefixes:
{inc Ev/ES}
{range:0}+(0-400) to Evasion Rating
{range:0}+(0-135) to maximum Energy Shield
{range:.75}+(0-109) to maximum Life
{range:0}+(0-73) to maximum Mana
Suffixes:
{dex}
{int}
{shield}
]],
-- Amulets
[[
Amulet
Amber Amulet
+(20-30) to Strength
{amulet}
]],[[
Amulet
Jade Amulet
+(20-30) to Dexterity
{amulet}
]],[[
Amulet
Lapis Amulet
+(20-30) to Intelligence
{amulet}
]],[[
Amulet
Onyx Amulet
+(10-16) to all Attributes
{amulet}
]],[[
Amulet
Agate Amulet
+(16-24) to Strength and Intelligence
{amulet}
]],[[
Amulet
Turquoise Amulet
+(16-24) to Dexterity and Intelligence
{amulet}
]],[[
Amulet
Citrine Amulet
+(16-24) to Strength and Dexterity
{amulet}
]],[[
Amulet
Paua Amulet
(20-30)% increased Mana Regeneration Rate
{amulet}
]],[[
Amulet
Marble Amulet
(1.2-1.6)% of Life Regenerated per second
{amulet}
]],[[
Amulet
Blue Pearl Amulet
(48-56)% increased Mana Regeneration Rate
{amulet}
]],
-- Rings
[[
Ring
Paua Ring
+(20-25) to Maximum Mana
Prefixes:
{ring}
]],[[
Ring
Moonstone Ring
+(15-25) to maximum Energy Shield
Prefixes:
{ring}
]],[[
Ring
Diamond Ring
(20 to 30)% increased Global Critical Strike Chance
Prefixes:
{ring}
]],[[
Ring
Ruby Ring
+(20 to 30)% to Fire Resistance
Prefixes:
{ring}
]],[[
Ring
Sapphire Ring
+(20 to 30)% to Cold Resistance
Prefixes:
{ring}
]],[[
Ring
Topaz Ring
+(20 to 30)% to Lightning Resistance
Prefixes:
{ring}
]],[[
Ring
Amethyst Ring
+(9 to 13)% to Chaos Resistance
Prefixes:
{ring}
]],[[
Ring
Ruby Ring
+(20 to 30)% to Fire Resistance
Prefixes:
{ring}
]],[[
Ring
Coral Ring
+(20 to 30) to maximum Life
Prefixes:
{ring}
]],[[
Ring
Prismatic Ring
+(8 to 10)% to all Elemental Resistances
Prefixes:
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
Prefixes:
{ring}
]],[[
Ring
Unset Ring
Has 1 Socket
Prefixes:
+(0 to 3) to Level of Socketed Gems
{ring}
]],[[
Ring
Steel Ring
Adds (3-4) to (10-14) Physical Damage to Attacks
Prefixes:
{ring}
]],[[
Ring
Opal Ring
(15-25)% increased Elemental Damage
Prefixes:
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
]],[[
Belt
Crystal Belt
+(60-80) to maximum Energy Shield
{belt}
]],[[
Belt
Vanguard Belt
+(260-320) to Armour and Evasion Rating
{belt}
]],
-- Quivers
[[
Quiver
Spike-Point Arrow Quiver
(20 to 30)% increased Global Critical Strike Chance
Prefixes:
{range:.75}+(0 to 99) to maximum Life
{range:.5}Adds (0-6) to (0-10) Physical Damage to Attacks
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
50% increased Critical Strike Chance
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
{range:0}Adds (0-72) to (0-123) Chaos Damage
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
+38 Life gained for each Enemy hit by Attacks
+14 Mana gained for each Enemy hit by Attacks
{phys 1h}
]],[[
Elemental Claw
Imperial Claw
+46 Life gained for each Enemy hit by Attacks
{elem 1h}
]],[[
Physical Dagger
Ambusher
30% increased Global Critical Strike Chance
{phys 1h}
]],[[
Elemental Dagger
Ambusher
30% increased Global Critical Strike Chance
{elem 1h}
]],[[
Spell Dagger
Platinum Kris
50% increased Global Critical Strike Chance
{spell 1h}
{range:.0}(0-27)% increased Attack Speed
]],[[
Vagan Dagger
Royal Skean
30% increased Global Critical Strike Chance
Prefixes:
Hits can't be Evaded
{range:0}Adds (0-61) to (0-106) Fire Damage
{range:0}Adds (0-50) to (0-87) Cold Damage
{range:0}Adds (0-13) to (0-166) Lightning Damage
{range:.5}(0-79)% increased Spell Damage
Suffixes:
{range:.5}(0-16)% increased Attack Speed
{range:.5}(0-38)% increased Critical Strike Chance
]],[[
Spell Sceptre
Void Sceptre
40% increased Elemental Damage
{spell 1h}
]],[[
Physical 1H Mace
Behemoth Mace
6% increased Attack Speed
{phys 1h}
]],[[
Physical Sceptre
Void Sceptre
40% increased Elemental Damage
{phys 1h}
]],[[
Elemental 1H Mace
Behemoth Mace
6% increased Attack Speed
{elem 1h}
]],[[
Elemental Sceptre
Void Sceptre
40% increased Elemental Damage
{elem 1h}
]],[[
Physical 2H Mace
Coronal Maul
6% increased Area of Effect of Area Skills
{phys 2h}
]],[[
Elemental 2H Mace
Coronal Maul
6% increased Area of Effect of Area Skills
{elem 2h}
]],[[
Physical Staff
Eclipse Staff
100% increased Global Critical Strike Chance
{phys 2h}
]],[[
Elemental Staff
Eclipse Staff
100% increased Global Critical Strike Chance
{elem 2h}
]],[[
Spell Staff
Eclipse Staff
100% increased Global Critical Strike Chance
{spell 2h}
]],[[
+3 Fire Staff
Maelstrom Staff
20% Chance to Block
Prefixes:
{range:1}+(0-1) to Level of Socketed Gems
{range:1}+(0-2) to Level of Socketed Fire Gems
{range:.5}(0-115)% increased Spell Damage
{range:0}Adds (0-65) to (0-115) Fire Damage to Spells
{range:0}Adds (0-60) to (0-104) Cold Damage to Spells
{range:0}Adds (0-15) to (0-200) Lightning Damage to Spells
{spell suf}
]],[[
+3 Cold Staff
Maelstrom Staff
20% Chance to Block
Prefixes:
{range:1}+(0-1) to Level of Socketed Gems
{range:1}+(0-2) to Level of Socketed Cold Gems
{range:.5}(0-115)% increased Spell Damage
{range:0}Adds (0-65) to (0-115) Fire Damage to Spells
{range:0}Adds (0-60) to (0-104) Cold Damage to Spells
{range:0}Adds (0-15) to (0-200) Lightning Damage to Spells
{spell suf}
]],[[
+3 Lightning Staff
Maelstrom Staff
20% Chance to Block
Prefixes:
{range:1}+(0-1) to Level of Socketed Gems
{range:1}+(0-2) to Level of Socketed Lightning Gems
{range:.5}(0-115)% increased Spell Damage
{range:0}Adds (0-65) to (0-115) Fire Damage to Spells
{range:0}Adds (0-60) to (0-104) Cold Damage to Spells
{range:0}Adds (0-15) to (0-200) Lightning Damage to Spells
{spell suf}
]],[[
+3 Chaos Staff
Maelstrom Staff
20% Chance to Block
Prefixes:
{range:1}+(0-1) to Level of Socketed Gems
{range:1}+(0-2) to Level of Socketed Chaos Gems
{range:.5}(0-115)% increased Spell Damage
{range:0}Adds (0-65) to (0-115) Fire Damage to Spells
{range:0}Adds (0-60) to (0-104) Cold Damage to Spells
{range:0}Adds (0-15) to (0-200) Lightning Damage to Spells
{spell suf}
]],[[
Physical 1H Sword
Tiger Hook
6% chance to Dodge Attacks
{phys 1h}
]],[[
Physical 1H Sword
Jewelled Foil
+25% to Global Critical Strike Multiplier
{phys 1h}
]],[[
Elemental 1H Sword
Eternal Sword
+475 to Accuracy Rating
{elem 1h}
]],[[
Elemental 1H Sword
Jewelled Foil
+25% to Global Critical Strike Multiplier
{elem 1h}
]],[[
Physical 2H Sword
Exquisite Blade
+60% to Global Critical Strike Multiplier
{phys 2h}
]],[[
Elemental 2H Sword
Reaver Sword
40% increased Accuracy Rating
{elem 2h}
]],[[
Physical Wand
Imbued Wand
(33-37)% increased Spell Damage
{phys 1h pre}
{range:0}Adds (0-72) to (0-123) Chaos Damage
{ranged suf}
]],[[
Elemental Wand
Imbued Wand
(33-37)% increased Spell Damage
{elem 1h pre}
{ranged suf}
]],[[
Spell Wand
Prophecy Wand
(36-40)% increased Spell Damage
{spell 1h}
]],
-- Jewels
[[
Jewel
Crimson Jewel
{jewel pre}
{range:0}(0-18)% increased Armour
{range:0}(0-14)% increased Physical Damage with One Handed Melee Weapons
{range:0}(0-14)% increased Physical Damage with Two Handed Melee Weapons
{range:0}(0-6)% increased Attack Speed with One Handed Melee Weapons
{range:0}(0-6)% increased Attack Speed with Two Handed Melee Weapons
{range:0}(0-18)% increased Critical Strike Chance with One Handed Melee Weapons
{range:0}(0-18)% increased Critical Strike Chance with Two Handed Melee Weapons
{range:0}+(0-18)% to Critical Strike Multiplier with One Handed Melee Weapons
{range:0}+(0-18)% to Critical Strike Multiplier with Two Handed Melee Weapons
{jewel suf}
{range:0}(0-12)% increased Melee Damage
{range:0}(0-12)% increased Global Critical Strike Chance
{range:0}(0-14)% increased Melee Critical Strike Chance
{range:0}+(0-12)% to Global Critical Strike Multiplier
{range:0}+(0-15)% to Melee Critical Strike Multiplier
]],[[
Jewel
Viridian Jewel
{jewel pre}
{range:0}(0-18)% increased Evasion Rating
{range:0}(0-16)% increased Trap Damage
{range:0}(0-16)% increased Mine Damage
{range:0}(0-16)% increased Physical Damage with Bows
{range:0}(0-14)% increased Physical Damage with One Handed Melee Weapons
{range:0}(0-14)% increased Physical Damage with Two Handed Melee Weapons
{range:0}(0-8)% increased Attack Speed with Bows
{range:0}(0-6)% increased Attack Speed with One Handed Melee Weapons
{range:0}(0-6)% increased Attack Speed with Two Handed Melee Weapons
{range:0}(0-18)% increased Critical Strike Chance with One Handed Melee Weapons
{range:0}(0-18)% increased Critical Strike Chance with Two Handed Melee Weapons
{range:0}+(0-18)% to Critical Strike Multiplier with One Handed Melee Weapons
{range:0}+(0-18)% to Critical Strike Multiplier with Two Handed Melee Weapons
{jewel suf}
{range:0}(0-12)% increased Melee Damage
{range:0}(0-12)% increased Global Critical Strike Chance
{range:0}(0-14)% increased Melee Critical Strike Chance
{range:0}+(0-12)% to Global Critical Strike Multiplier
{range:0}+(0-15)% to Melee Critical Strike Multiplier
]],[[
Jewel
Cobalt Jewel
{jewel pre}
{range:0}(0-8)% increased maximum Energy Shield
{range:0}(0-6)% faster start of Energy Shield Recharge
{range:0}(0-16)% increased Trap Damage
{range:0}(0-16)% increased Mine Damage
{range:0}Minions deal (0-16)% increased Damage
{range:0}Minions have (0-12)% increased maximum Life
{range:0}(0-16)% increased Physical Damage with Wands
{range:0}(0-8)% increased Attack Speed with Wands
{range:0}(0-16)% increased Spell Damage while wielding a Staff
{range:0}(0-16)% increased Spell Damage while holding a Shield
{range:0}(0-5)% increased Cast Speed while wielding a Staff
{range:0}(0-5)% increased Cast Speed while holding a Shield
{jewel suf}
{range:0}(0-4)% increased Cast Speed
{range:0}(0-12)% increased Spell Damage
{range:0}(0-12)% increased Global Critical Strike Chance
{range:0}(0-14)% increased Critical Strike Chance for Spells
{range:0}+(0-12)% to Global Critical Strike Multiplier
{range:0}+(0-15)% to Critical Strike Multiplier for Spells
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