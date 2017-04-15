--
-- Upcoming skills/bases/uniques will live here until their mods/rolls are finalised
--

local gems = data.gems


local itemBases = data.itemBases


data.uniques.new = {
-- Equippable items
[[
Tidebreaker
Imperial Maul
Requires Level 65, 212 Str
30% increased Stun Duration on Enemies
Socketed Gems are Supported by Level 20 Endurance Charge on Melee Stun
Adds (60–70) to (300–350) Physical Damage
+40 to Intelligence
10% increased Physical Damage per Endurance Charge
(20–30)% reduced Enemy Stun Threshold with this Weapon
]],[[
Martyr of Innocence
Highborn Staff
Requires Level 52, 89 Str, 89 Int
18% Chance to Block
(12–16)% Chance to Block 
Adds (350–400) to (500–600) Fire Damage 
Adds (130–150) to (200–250) Fire Damage to Spells
100% increased Fire Damage if you have been Hit Recently
Damage Penetrates 15% of Fire Resistance if you have Blocked Recently
Immune to Freeze and Chill while Ignited
Grants level 15 Vengeance Skill
]],[[
Garukhan's Flight
Stealth Boots
Requires Level 62, 117 Dex
(80–120)% increased Evasion Rating
30% increased Movement Speed
Immune to Burning Ground, Shocked Ground and Chilled Ground
Regenerate 100 Life per second while moving
+1 to Maximum Life per 10 Dexterity
]],[[
Gruthkul's Pelt
Wyrmscale Doublet
Requiress Level 38, 57 Str, 57 Dex
(60-100)% increased Physical Damage
+(130-160) to maximum Life
+(20-40)% to Cold Resistance
2% of Life Regenerated per second
15% increased Character Size
Spell Skills deal no Damage
Your Spells are disabled
]],[[
The Baron
Close Helmet
Requires Level 26, 58 Str
+2 to Level of Socketed Minion Gems
+(20–40) to Strength
Minions have 20% increased maximum Life
Your Strength is added to your Minions
+1 to maximum number of Zombies per 300 Strength
With 1000 or more Strength 2% of Damage dealt by your Zombies is Leeched to you as Life
]],[[
Bisco's Collar
Gold Amulet
Requires Level 30
(12-20)% increased Rarity of Items found
150% increased Rarity of Items Dropped by Slain Magic Enemies
100% increased Quantity of Items Dropped by Slain Normal Enemies
]],[[
Bisco's Leash
Heavy Belt
Requires Level 30
+(25-35) to Strength
5% increased Quantity of Items found
+(20–40)% to Cold Resistance
Rampage
1% increased Rarity of Items found per 15 Rampage Kills
]],[[
The Wise Oak
Bismuth Flask
Requires Level 8
Implicits: 0
During Flask Effect, 10% reduced Damage taken of each Element for which your Uncapped
Elemental Resistance is lowest
During Flask Effect, Damage Penetrates 20% Resistance of each Element for which your
Uncapped Elemental Resistance is highest
]],[[
Ahn's Heritage
Colossal Tower Shield
Requires Level 67, 159 Str
(50-100)% increased Armour
+(60-80) to maximum Life
-1 to maximum Endurance Charges
-10% to maximum Block Chance
+6% Chance to Block
+3% to all maximum Resistances while you have no Endurance Charges
You have Onslaught while at maximum Endurance Charges
]],[[
Haemophilia
Serpentscale Gauntlets
Requires Level 43, 34 Str, 34 Dex
+(20–30) to Strength 
25% increased Damage over Time 
Attacks have 25% chance to cause Bleeding 
(25–40)% increased Attack Damage against Bleeding Enemies 
Bleeding Enemies you Kill Explode, dealing 5% of
their Maximum Life as Physical Damage 
25% reduced Bleed duration
]],[[
Ryslatha's Coil
Studded Belt
Requires Level: 20
(20–30)% increased Stun Duration on Enemies 
+(20–40) to Strength 
Adds 1 to (15–20) Physical Damage to Attacks 
Gain 50 Life when you Stun an Enemy 
20% less Minimum Physical Attack Damage 
20% more Maximum Physical Attack Damage
]],
-- Theshold jewels
[[
Fight for Survival
Viridian Jewel
Limited to: 2
Radius: Medium
(10–15)% increased Cold Damage
With at least 40 Dexterity in Radius, Frost
Blades Melee Damage Penetrates 15% Cold Resistance
With at least 40 Dexterity in Radius, Frost Blades has 25% increased Projectile Speed
]],[[
Omen on the Winds
Viridian Jewel
Limited to: 2
Radius: Medium
16% increased Damage against Chilled Enemies
With at least 40 Dexterity in Radius, Ice Shot has 25% increased Area of Effect
With at least 40 Dexterity in Radius, Ice Shot has 50% chance of Projectiles Piercing
]],[[
Frozen Trail
Cobalt Jewel
Limited to: 2
Radius: Medium
(7–10)% increased Projectile Damage
With at least 40 Intelligence in Radius, Frostbolt fires 2 additional Projectiles
With at least 40 Intelligence in Radius, Frostbolt Projectiles gain 40% increased Projectile
Speed per second
]],[[
Inevitability
Cobalt Jewel
Limited to: 2
Radius: Medium
(10–15)% increased Fire Damage
With at least 40 Intelligence in Radius, Magma Orb fires an additional Projectile
With at least 40 Intelligence in Radius, Magma Orb
has 10% increased Area of Effect per Chain
]],[[
Overwhelming Odds
Crimson Jewel
Limited to: 2
Radius: Medium
(10-15)% increased Physical Damage
With at least 40 Strength in Radius, Cleave grants Fortify on Hit
With at least 40 Strength in Radius, Cleave has 3% increased Area of
Effect per Nearby Enemy
]],[[
Collateral Damage
Viridian Jewel
Limited to: 2
Radius: Medium
(10–15)% increased Physical Damage
With at least 40 Dexterity in Radius, Shrapnel Shot has 25% increased Area of Effect
With at least 40 Dexterity in Radius, Shrapnel Shot's
cone has a 50% chance to deal Double Damage
]],[[
Might and Influence
Viridian Jewel
Limited to: 1
Radius: Medium
(10–15)% increased Physical Damage
With at least 40 Dexterity in Radius, Dual Strike has a 20% chance
to deal Double Damage with the Main-Hand Weapon
With at least 40 Dexterity in Radius, Dual Strike deals Off-Hand Splash Damage
to surrounding targets
]],[[
First Snow
Cobalt Jewel
Limited to: 2
Radius: Medium
(7–10)% increased Projectile Damage 
With at least 40 Intelligence in Radius, Freezing Pulse fires 2 additional Projectiles
With at least 40 Intelligence in Radius, 25% increased Freezing Pulse Damage if
you've Shattered an Enemy Recently
]],[[
Ring of Blades
Viridian Jewel
Limited to: 1
Radius: Medium
(10–15)% increased Physical Damage 
With at least 40 Dexterity in Radius, Ethereal Knives fires Projectiles in a Nova
With at least 40 Dexterity in Radius, Ethereal Knives fires 10 additional Projectiles
]],[[
Sudden Ignition
Viridian Jewel
Limited to: 1
Radius: Medium
(10–15)% increased Fire Damage 
With at least 40 Dexterity in Radius, Burning
Arrow can inflict an additional Ignite on an Enemy
]],[[
Violent Dead
Cobalt Jewel
Limited to: 2
Radius: Medium
Minions deal (8–12)% increased Damage 
With at least 40 Intelligence in Radius, Raised
Zombies' Slam Attack has 100% increased Cooldown Recovery Speed
With at least 40 Intelligence in Radius, Raised Zombies' Slam
Attack deals 30% increased Damage
]],[[
Wildfire
Crimson Jewel
Limited to: 2
Radius: Medium
(10–15)% increased Fire Damage 
With at least 40 Strength in Radius, Molten Strike fires 2 additional Projectiles
With at least 40 Strength in Radius, Molten Strike has 25% increased Area of Effect
]],[[
Winter Burial
Crimson Jewel
Limited to: 2
Radius: Medium
(10–15)% increased Cold Damage 
With at least 40 Strength in Radius, Glacial Hammer deals
Cold-only Splash Damage to surrounding targets
With at least 40 Strength in Radius, 25% of Glacial
Hammer Physical Damage converted to Cold Damage
]],
}