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
-- 2.5.0
[[
Ngamahu's Flame
Abyssal Axe
Two Hand Axes
Physical Damage: (200.1 to 227.7)–(301.6 to 343.2)
Critical Strike Chance: 5.00%
Attacks per Second: (1.35 to 1.40)
Weapon Range: 11
Requires Level 55, 128 Str, 60 Dex
(190-230)% increased Physical Damage
(8-12)% increased Attack Speed
50% of Physical Damage Converted to Fire Damage
Damage Penetrates 20% Fire Resistance
20% chance to attack with Level 16 Molten Burst on Melee Hit
]],[[
Voll's Vision
Praetor Crown
Armour: (676 to 716)
Energy Shield: 63
Requires Level 68, 62 Str, 91 Int
+(260-300) to Armour
+(20-40)% to Fire Resistance
+(8-16)% to Chaos Resistance
20% increased Light Radius
(8-12)% increased maximum Life if no worn Items are Corrupted
Regenerate 100 Life per second if no worn Items are Corrupted
]],[[
Malachai's Vision
Praetor Crown
Armour: 140
Energy Shield: 63
Requires Level 68, 62 Str, 91 Int
Adds (13-17) to (29-37) Chaos Damage
+(200-250) to maximum Energy Shield
+(30-50)% to Cold Resistance
+(15-20)% to Lightning Resistance
Regenerate 100 Energy Shield per second if all worn items are Corrupted
Regenerate 35 Mana per second if all worn items are Corrupted
Corrupted
]],[[
Tukohama's Fortress
Ebony Tower Shield
Chance to Block: 25%
Armour: 358
Requires Level 61, 159 Str
40% increased Totem Damage
+(80-100) to maximum Life
Can have up to 1 additional Totem summoned at a time
+300 Armour per active Totem
Blood Magic
]],[[
Ewar's Mirage
Antique Rapier
Thrusting One Hand Swords
Physical Damage: 10–40
Elemental Damage: 1–(45 to 55)
Critical Strike Chance: 6.50%
Attacks per Second: (1.51 to 1.59)
Weapon Range: 12
Requires Level 26, 89 Dex
+30% to Global Critical Strike Multiplier
(40-55)% increased Elemental Damage with Weapons
Adds 1 to (45-55) Lightning Damage
(16-22)% increased Attack Speed
Attacks Chain an additional time when in Main Hand
Attacks have an additional Projectile when in Off Hand
]],[[
Shade of Solaris
Sage Wand
Wands
Physical Damage: 15–28
Critical Strike Chance: 9.00%
Attacks per Second: 1.20
Weapon Range: 120
Requires Level 30, 119 Int
(17-21)% increased Spell Damage
Gain (10-20)% of Elemental Damage as Extra Chaos Damage
Critical Strikes deal no Damage
120% increased Spell Damage if you've dealt a Critical Strike Recently
]],[[
Light of Lunaris
Jingling Spirit Shield
Chance to Block: (26% to 28%)
Energy Shield: (60 to 72)
Requires Level 28, 71 Int
10% increased Spell Damage
(60-80)% increased Critical Strike Chance for Spells
(100-140)% increased Energy Shield
+(3-5)% Chance to Block
+1% to Critical Strike Multiplier per 1% Block Chance
+25% to Critical Strike Multiplier if you've dealt a Non-Critical Strike Recently
]],[[
Duskdawn
Maelström Staff
Staves
Physical Damage: 57–119
Critical Strike Chance: 6.40%
Attacks per Second: 1.20
Weapon Range: 11
Requires Level 64, 113 Str, 113 Int
18% Chance to Block
4% Chance to Block
(60-80)% increased Critical Strike Chance for Spells
Gain (10-20)% of Elemental Damage as Extra Chaos Damage
+1% to Critical Strike Multiplier per 1% Block Chance
+60% to Critical Strike Multiplier if you've dealt a Non-Critical Strike Recently
120% increased Spell Damage if you've dealt a Critical Strike Recently
]],[[
The Brine Crown
Prophet Crown
Armour: (390 to 429)
Energy Shield: (80 to 88)
Requires Level 63, 85 Str, 62 Int
(100-120)% increased Armour and Energy Shield
+(60-70) to maximum Life
+(20-40)% to Cold Resistance
Cannot be Frozen
+800 Armour while stationary
60% increased Mana Regeneration Rate while stationary
15% chance to create Chilled Ground when Hit with an Attack
]],[[
Arakaali's Fang
Fiend Dagger
Daggers
Physical Damage: (72.9 to 96)–(259.2 to 318)
Chaos Damage: 1–59
Critical Strike Chance: 7.00%
Attacks per Second: 1.20
Weapon Range: 8
Requires Level 53, 58 Dex, 123 Int
60% increased Global Critical Strike Chance
(170-200)% increased Physical Damage
Adds (8-13) to (20-30) Physical Damage
Adds 1 to 59 Chaos Damage
20% chance to Cast level 1 Raise Spiders on Kill
15% chance to Poison on Hit
]],[[
Abberath's Hooves
Goathide Boots
Evasion: 36
Requires Level 12, 26 Dex
+(20-30) to Strength
15% increased Movement Speed
(6-10)% chance to Ignite
Ignite a nearby Enemy on Killing an Ignited Enemy
Casts level 7 Abberath's Fury when equipped
1% increased Fire Damage per 20 Strength
Burning Hoofprints
]],[[
Lycosidae
Splintered Tower Shield
Chance to Block: (27% to 29%)
Armour: (128 to 168)
Requires 10 Str
+(120-160) to Armour
+(30-40) to maximum Life
Your hits can't be Evaded
+(3-5)% Chance to Block
Adds 250 to 300 Cold Damage to Counterattacks
]],[[
Perseverance
Vanguard Belt
Requires Level 78
+(260-320) to Armour and Evasion Rating
(4-8)% increased maximum Life
+(20-40)% to Cold Resistance
1% increased Attack Damage per 300 of the lowest of Armour and Evasion Rating
(14-20)% chance to gain Fortify on Melee Stun
You have Onslaught while you have Fortify
]],[[
Kitava's Feast
Void Axe
Two Hand Axes
Physical Damage: (266 to 304)–(399 to 456)
Critical Strike Chance: 5.00%
Attacks per Second: 1.25
Weapon Range: 11
Requires Level 68, 149 Str, 76 Dex
Socketed Gems are supported by level 25 Melee Splash
(250-300)% increased Physical Damage
1% of Physical Attack Damage Leeched as Life
1% of Physical Attack Damage Leeched as Mana
Recover 5% of Maximum Life on Kill
Enemies you hit are destroyed on Kill
]],[[
Primordial Might
Crimson Jewel
(25-30)% increased Damage if you Summoned a Golem in the past 8 seconds
Golems Summoned in the past 8 seconds deal (35-45)% increased Damage
Golems have (18-22)% increased Maximum Life
Your Golems are aggressive
Primordial
]],[[
Primordial Harmony
Cobalt Jewel
Golem Skills have (20-30)% increased Cooldown Recovery Speed
Golems have (10-15)% increased Cooldown Recovery Speed
(16-20)% increased Golem Damage for each Type of Golem you have Summoned
Golems regenerate 2% of their Maximum Life per second
Primordial
]],[[
Primordial Eminence
Viridian Jewel
Golems have (16-20)% increased Attack and Cast Speed
30% increased Effect of Buffs granted by your Golems
Golems have +(800-1000) to Armour
]],[[
The Anima Stone
Prismatic Jewel
Limited to: 1
Can Summon up to 1 additional Golem at a time
If you have 3 Primordial Jewels, can Summon up to 1 additional Golem at a time
]],
-- Breach
[[
Xoph's Inception
Bone Bow
League: Breach
Requires Level 23, 80 Dex
(70-90)% increased Physical Damage
+(20-30) Life gained on Killing Ignited Enemies
Gain 20% of Physical Damage as Extra Fire Damage
10% chance to Ignite
]],[[
Xoph's Nurture
Citadel Bow
League: Breach
Requires Level 64, 185 Dex
(250-300)% increased Physical Damage
50% of Physical Damage Converted to Fire Damage
10% chance to Ignite
Ignites your Skills cause spread to other Enemies within a Radius of 12
Recover (40-60) Life when you Ignite an Enemy
]],[[
The Formless Flame
Siege Helmet
League: Breach
Requires Level 48, 101 Str
+(100-120) to Armour
+(40-50) to maximum Life
-20 Fire Damage taken when Hit
Armour is increased by Uncapped Fire Resistance
]],[[
The Formless Inferno
Royal Burgonet
League: Breach
Armour: (590 to 721)
Requires Level 65, 148 Str
(80-120)% increased Armour
+(40-50) to maximum Life
-30% to Fire Resistance
8% of Physical Damage taken as Fire Damage
Armour is increased by Uncapped Fire Resistance
]],[[
Xoph's Heart
Amber Amulet
League: Breach
Requires Level 35
+(20-30) to Strength
+(20-30) to Strength
25% increased Fire Damage
+(25-35) to maximum Life
+(20-40)% to Fire Resistance
Cover Enemies in Ash when they Hit you
]],[[
Xoph's Blood
Amber Amulet
League: Breach
Requires Level 64
+(20-30) to Strength
10% increased maximum Life
+(20-40)% to Fire Resistance
10% increased Strength
Damage Penetrates 10% Fire Resistance
Cover Enemies in Ash when they Hit you
Avatar of Fire
]],[[
Tulborn
Spiraled Wand
League: Breach
Requires Level 24, 83 Int
(15-19)% increased Spell Damage
(10-15)% increased Cast Speed
50% chance to gain a Power Charge on Killing a Frozen Enemy
Adds 10 to 20 Cold Damage to Spells per Power Charge
+(20-25) Mana gained on Killing a Frozen Enemy
]],[[
Tulfall
Tornado Wand
League: Breach
Requires Level 65, 212 Int
(35-39)% increased Spell Damage
(10-15)% increased Cast Speed
50% chance to gain a Power Charge on Killing a Frozen Enemy
Adds 15 to 25 Cold Damage to Spells per Power Charge
Lose all Power Charges on reaching Maximum Power Charges
Gain a Frenzy Charge on reaching Maximum Power Charges
(10-15)% increased Cold Damage per Frenzy Charge
]],[[
The Snowblind Grace
Coronal Leather
League: Breach
Requires Level 49, 134 Dex
+(30-40) to Dexterity
(30-50)% increased Evasion Rating
+(40-60) to maximum Life
10% chance to Dodge Spell Damage
25% increased Arctic Armour Buff Effect
Evasion Rating is increased by Uncapped Cold Resistance
]],[[
The Perfect Form
Zodiac Leather
League: Breach
Requires Level 65, 197 Dex
(30-50)% increased Evasion Rating
+(50-70) to maximum Life
-30% to Cold Resistance
(5-10)% increased Dexterity
100% reduced Arctic Armour Mana Reservation
Evasion Rating is increased by Uncapped Cold Resistance
Phase Acrobatics
]],[[
The Halcyon
Jade Amulet
League: Breach
Requires Level 35
+(20-30) to Dexterity
(10-20)% increased Cold Damage
+(35-40)% to Cold Resistance
30% increased Freeze Duration on Enemies
10% chance to Freeze
60% increased Damage if you've Frozen an Enemy Recently
]],[[
The Pandemonius
Jade Amulet
League: Breach
Requires Level 64
+(20-30) to Dexterity
(20-30)% increased Cold Damage
+35% to Cold Resistance
Chill Enemy for 1 second when Hit
Blind Chilled Enemies on Hit
Damage Penetrates 20% Cold Resistance against Chilled Enemies
]],[[
Hand of Thought and Motion
Blinder
League: Breach
Requires Level 22, 41 Dex, 41 Int
+10 Life gained for each Enemy hit by Attacks
(20-25)% increased Elemental Damage with Weapons
Adds 1 to (50-60) Lightning Damage
(10-15)% increased Attack Speed
Adds 1-3 Lightning Damage to Attacks per 10 Intelligence
]],[[
Hand of Wisdom and Action
Imperial Claw
League: Breach
Requires Level 68, 131 Dex, 95 Int
+25 Life gained for each Enemy hit by Attacks
(25-30)% increased Elemental Damage with Weapons
(8-12)% increased Dexterity
(8-12)% increased Intelligence
Adds 1-6 Lightning Damage to Attacks per 10 Intelligence
1% increased Attack Speed per 25 Dexterity
]],[[
Esh's Mirror
Thorium Spirit Shield
League: Breach
Requires Level 53, 128 Int
+(20-30) to Intelligence
+(40-70) to maximum Life
(80-100)% increased Energy Shield
+(35-40)% to Lightning Resistance
Adds 1-10 Lightning Damage for each Shocked Enemy you've Killed Recently
Shock Reflection
]],[[
Esh's Visage
Vaal Spirit Shield
League: Breach
Requires Level 62, 159 Int
5% increased Spell Damage
+(40-70) to maximum Life
(240-260)% increased Energy Shield
+(30-40)% to Lightning Resistance
+(17-29)% to Chaos Resistance
Chaos Damage does not bypass Energy Shield while not on Low Life or Low Mana
Reflect Shocks applied to you to all Nearby Enemies
]],[[
Voice of the Storm
Lapis Amulet
League: Breach
Requires Level 40
+(20-30) to Intelligence
+(10-15) to all Attributes
(10-20)% increased maximum Mana
Critical Strike Chance is increased by Uncapped Lightning Resistance
Cast Level 12 Lightning Bolt when you deal a Critical Strike
]],[[
Choir of the Storm
Lapis Amulet
League: Breach
Requires Level 69
+(20-30) to Intelligence
(10-20)% increased maximum Mana
-30% to Lightning Resistance
Critical Strike Chance is increased by Uncapped Lightning Resistance
Critical Strikes deal 50% increased Lightning Damage
Cast Level 20 Lightning Bolt when you deal a Critical Strike
]],[[
Uul-Netol's Kiss
Labrys
League: Breach
Requires Level 49, 122 Str, 53 Dex
(140-170)% increased Physical Damage
15% reduced Attack Speed
25% chance to Curse Enemies with level 10 Vulnerability on Hit
Attacks Cause Bleeding when Hitting Cursed Enemies
]],[[
Uul-Netol's Embrace
Vaal Axe
Two Hand Axes
League: Breach
Physical Damage: (300.2 to 331.8)–(497.8 to 550.2)
Critical Strike Chance: 5.00%
Attacks per Second: (0.84 to 0.90)
Weapon Range: 11
Requires Level 64, 158 Str, 76 Dex
(280-320)% increased Physical Damage
(30-25)% reduced Attack Speed
Attacks Cause Bleeding when Hitting Cursed Enemies
Attack with level 20 Bone Nova when you Kill a Bleeding Enemy
]],[[
The Infinite Pursuit
Goliath Greaves
League: Breach
Requires Level 54, 95 Str
+(30-60) to maximum Life
20% increased Movement Speed
Moving while Bleeding doesn't cause you to take extra Damage
15% increased Movement Speed while Bleeding
50% chance to be inflicted with Bleeding when Hit by an Attack
]],[[
The Red Trail
Titan Greaves
League: Breach
Requires Level 68, 120 Str
(60-80)% increased Armour
+(50-70) to maximum Life
25% increased Movement Speed
Gain a Frenzy Charge on Hit while Bleeding
15% increased Movement Speed while Bleeding
10% additional Physical Damage Reduction while stationary
50% chance to be inflicted with Bleeding when Hit by an Attack
]],[[
The Anticipation
Ezomyte Tower Shield
League: Breach
Requires Level 64, 159 Str
(120-160)% increased Armour
+(50-70) to maximum Life
+6% Chance to Block
+1000 Armour if you've Blocked Recently
Permanently Intimidate Enemies on Block
]],[[
The Surrender
Ezomyte Tower Shield
League: Breach
Requires Level 64, 159 Str
Grants level 30 Reckoning Skill
(130-170)% increased Armour
+(65-80) to maximum Life
Recover 250 Life when you Block
+6% Chance to Block
+1500 Armour if you've Blocked Recently
]],[[
Severed in Sleep
Cutlass
League: Breach
Requires Level 38, 55 Str, 79 Dex
18% increased Accuracy Rating
+(10-15) to all Attributes
Minions deal (20-30)% increased Damage
Minions have +17% to Chaos Resistance
Minions Poison Enemies on Hit
Minions Recover 20% of Maximum Life on Killing a Poisoned Enemy
]],[[
United in Dream
Cutlass
League: Breach
One Hand Swords
Physical Damage: 11–44
Critical Strike Chance: 5.00%
Attacks per Second: 1.55
Weapon Range: 9
Requires Level 69, 55 Str, 79 Dex
18% increased Accuracy Rating
Grants level 15 Envy Skill
Minions deal (30-40)% increased Damage
Minions have +29% to Chaos Resistance
Minions Poison Enemies on Hit
Minions Leech 5% of Damage as Life against Poisoned Enemies
]],[[
Skin of the Loyal
Simple Robe
League: Breach
Sockets cannot be modified
+1 to Level of Socketed Gems
100% increased Global Defences
]],[[
Skin of the Lords
Simple Robe
League: Breach
Variant: Acrobatics
Variant: Ancestral Bond
Variant: Arrow Dancing
Variant: Avatar of Fire
Variant: Blood Magic
Variant: Conduit
Variant: Eldritch Battery
Variant: Elemental Equilibrium
Variant: Elemental Overload
Variant: Ghost Reaver
Variant: Iron Grip
Variant: Iron Reflexes
Variant: Mind Over Matter
Variant: Minion Instability
Variant: Pain Attunement
Variant: Phase Acrobatics
Variant: Point Blank
Variant: Resolute Technique
Variant: Unwavering Stance
Variant: Vaal Pact
Variant: Zealot's Oath
Sockets cannot be modified
+1 to Level of Socketed Gems
100% increased Global Defences
You can only Socket Corrupted Gems in this item
{variant:1}Acrobatics
{variant:2}Ancestral Bond
{variant:3}Arrow Dancing
{variant:4}Avatar of Fire
{variant:5}Blood Magic
{variant:6}Conduit
{variant:7}Eldritch Battery
{variant:8}Elemental Equilibrium
{variant:9}Elemental Overload
{variant:10}Ghost Reaver
{variant:11}Iron Grip
{variant:12}Iron Reflexes
{variant:13}Mind Over Matter
{variant:14}Minion Instability
{variant:15}Pain Attunement
{variant:16}Phase Acrobatics
{variant:17}Point Blank
{variant:18}Resolute Technique
{variant:19}Unwavering Stance
{variant:20}Vaal Pact
{variant:21}Zealot's Oath
]],[[
The Red Dream
Crimson Jewel
League: Breach
Radius: Large
Gain 5% of Fire Damage as Extra Chaos Damage
Passives granting Fire Resistance or all Elemental Resistances in Radius
also grant an equal chance to gain an Endurance Charge on Kill
]],[[
The Red Nightmare
Crimson Jewel
League: Breach
Limited to: 1
Radius: Large
Gain 5% of Fire Damage as Extra Chaos Damage
Passives granting Fire Resistance or all Elemental Resistances in Radius
also grant Chance to Block at 35% of its value
Passives granting Fire Resistance or all Elemental Resistances in Radius
also grant an equal chance to gain an Endurance Charge on Kill
]],[[
The Green Dream
Viridian Jewel
League: Breach
Radius: Large
Gain 5% of Cold Damage as Extra Chaos Damage
Passives granting Cold Resistance or all Elemental Resistances in Radius
also grant an equal chance to gain a Frenzy Charge on Kill
]],[[
The Green Nightmare
Viridian Jewel
League: Breach
Limited to: 1
Radius: Large
Gain 5% of Cold Damage as Extra Chaos Damage
Passives granting Cold Resistance or all Elemental Resistances in Radius
also grant Chance to Dodge Attacks at 35% of its value
Passives granting Cold Resistance or all Elemental Resistances in Radius
also grant an equal chance to gain a Frenzy Charge on Kill
]],[[
The Blue Dream
Cobalt Jewel
League: Breach
Radius: Large
Gain 5% of Lightning Damage as Extra Chaos Damage
Passives granting Lightning Resistance or all Elemental Resistances in Radius
also grant an equal chance to gain a Power Charge on Kill
]],[[
The Blue Nightmare
Cobalt Jewel
League: Breach
Limited to: 1
Radius: Large
Gain 5% of Lightning Damage as Extra Chaos Damage
Passives granting Lightning Resistance or all Elemental Resistances in Radius
also grant Chance to Block Spells at 35% of its value
Passives granting Lightning Resistance or all Elemental Resistances in Radius
also grant an equal chance to gain a Power Charge on Kill
]],[[
Presence of Chayula
Onyx Amulet
League: Breach
Requires Level 60
+(10-16) to all Attributes
30% increased Rarity of Items found
+60% to Chaos Resistance
Cannot be Stunned
20% of Maximum Life Converted to Energy Shield
]],
}