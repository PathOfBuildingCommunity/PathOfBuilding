### 1.4.153.1 - 2019/12/12
 * Add 3.9 Passive Tree
 * Add 3.9 Unique Changes
 * Add support for Ryslathas Coil
 * Add support for Perquils Toe
 * Add support for Vaal Arc Lucky Buff
 * Add support for Chain of Command's mods
 * Add support for Warcried recently
 * Fix Minion DPS sorting bug for Uniques and tree
 * Fix Toxic Rain/Rain of Arrows pierce bug
 * Fix radius calcualtion for Jewels 
 * Fix Impale calculations for certain skills
      * Barrage, Blade Flurry, Blast Rain, Double Strike, Lacerate, Scourge Arrow,
  	    Cleave, Dual Strike, Riposte, Viper Strike, Static Strike
 * Counter attack skills now show proper damage for each hit instead of DPS when using Impale
 * Update many uniques that had incorrect wordings

### 1.4.152.8 - 2019/12/09
 * Add Support for Greater Spell Echo
 * Widen manage passives trees drop down box
 * Rampage now appears as a box on the configs page
 * Show Impale DPS in sidebar for minions
 * Add The Ivory Tower Body armour (3.9 preview)
 * Add Mistwall Buckler Shield (3.9 preview)
 * Add support for Manastorms' lightning damage buff
 * Add support for Arborix and its mods
 * Add support for Augyre and its mods 
 * Add support for Vulconus and its mods
 * Add support for new Coated Shrapnel mod
 * Add support for Inquisitors increased damage on consecrated ground Sanctuary node
 * Add support for Golem Commanders increased damage node
 * Add increased area rampage mod support on Sinvicta's Mettle
 * Add proper support for Champions' Master of Metal node (set the number of impales for this to work)
 * Add Carion golem to list of golems that work with primordial harmony
 * Add Bane of Legends node attack speed buff
 * Add tooltip to Rage to list its effects
 * Update Edge of Madness
 * Fix Delve more bleed and poison damage mods to only apply to attacks and give more realistic damage numbers
 
### 1.4.152.7 - 2019/12/03
 * Add sorting for DPS including Impale and average hit damage
 * Add Impale DPS breakdown numbers
 * Change Impale DPS display in sidebar to make it more clear
 * Fix Primordial chain golem damage not working properly
 * Fix withering touch not applying withered damage increases
 * Fix Eternity shroud Elemental as Extra Chaos roll
 * Fix crash related to Impale calculations for Shield charge and Spectral Shield Throw

### 1.4.152.6 - 2019/12/02
 * Fully implement impale DPS calculations
 * Support for increased buff effect per golem and damage per golem
 * Update uniques with changes 3.8
 * Add new 3.9 uniques and changes from teasers so far
 * Added 100% increased crit chance from consecrated ground
 * Add support for Triad Grips
 * Add support for spell dodge boot enchant
 * Add support for remaining fossil mods
 * Cap shock effect at 50%
 * Fix totem limits
 * Fix elemental hit threshold gems again
 * Fix double damage on heavy strike
 * Fix minion resistance on raise spectre gem
 * Fix bones of ullur mod
 * Fix Perandus Signet mod
 * Fix red nightmare block chance
 * Trim image file sizes

### 1.4.152.5 - 2019/10/08
 * Withered debuff now appears on the config page
 * Ignite DPS for node power now works
 * Fixed some of the wording for impale
 * Added Impale chance and damage multiplier to the side bar so it will now show the differences when choosing impale gems or impale nodes on the tree
 * Added a feature requests section to the README.md file

### 1.4.152.4 - 2019/10/08
 * Readded +1 to socketed gems mod on daggers
 * Add parsing for max chaos resistance
 * Combat focus now works properly with Elemental Hit and Wild Strike

### 1.4.152.3 - 2019/10/06
 * Implemented logic for melee distance scaling attack multipliers (Close combat and Slayers Impact node)
 * Add counterattack double damage bonus from Gladiators Painforged node
 * Implement parsing for all of Slayer's nodes
 * Add support for Assassins Mistwalker node and Ascendants  node for Assassin
 * Add support for travel skills cooldown recovery
 * Add Badge of Brotherhood mod parsing
 * Add incremental shock values instead of the default locked value of 50%
 
### 1.4.152.2 - 2019/10/05
 * Added a display for current Elusive effect in the Calcs tab, which only shows up while Elusive.
 * Nightblade Support now gives Crit Multi and Base Crit Chance to attacks while using Claws or Daggers.
 * Elusive is implemented specifically for Claws/Daggers on Nightblade, and is added as a global Skill Mod 
   for Withering Step and any future gems which give the stat.
 * Added Vermillion ring base

### 1.4.152.1 - 2019/10/05
 * Updates uniques with 3.8 Changes
 * Adds new 3.8 uniques
 * Fix tempered flesh/mind not working
 * Fix minion regen nodes on the tree not being parsed correctly
 * Not all unique mods are parsed correctly

### 1.4.152 - 2019/09/15
 * Added support for anointments that grant notable passives
 * Added support for Transfiguration of Body/Mind/Soul
 * Added missing Legion uniques, and applied unique balance changes from 3.7 (thanks PJacek)
 * Added the missing bonuses from the Feeding Frenzy buff
 * Added the following spectres to the spectre library:
    * Desecrated Saint
    * Foreman
	* Freezing Wolf
    * Lunaris Concubine
	* Lunarsworn Wintermage
    * Slave Driver
 * Fixed modifiers to Golem buff effect not applying to the buff from Summon Carrion Golem

### 1.4.151 - 2019/09/09
 * Fixed error with Minion Instability

### 1.4.150 - 2019/09/09
 * Added the following new gems:
    * Cobra Lash
	* Icicle Mine
	* Pestilent Strike
    * Plague Bearer (mostly non-functional)
	* Stormblast Mine
	* Summon Carrion Golem
	* Summon Skitterbots
	* Venom Gyre
	* Withering Step (non-functional)
	* Charged Mines
	* Deathmark (The enemy can be set as Deathmarked in the Skill Options section of the Configuration tab)
	* Feeding Frenzy (Feeding Frenzy can be activated in Skill Options)
	* High-Impact Mine
	* Infernal Legion
	* Meat Shield (The enemy can be set as being "Near you" in Skill Options)
	* Nightblade (non-functional)
	* Swift Assembly
 * Added support for the new Mine changes:
    * When a Mine skill is selected, a new Active Mines option appears
	* The skill's Mana Reservation will be multiplied by the number of Active Mines specified
    * The various Mine auras are all supported; the stack count is determined by the Active Mines option
 * Applied the skill reworks and balance changes for 3.8.0
 * Updated item bases, mods, and enchantments for 3.8.0
 * Added support for global Spell Skill Gem modifiers, and updated the +X Staff rare templates
 * Updated minion Accuracy values
 * Added support for the Added Chaos Damage granted by Despair
 * The additional Critical Strike Chance granted by Assassin's Mark now works correctly
 * The "less Mana Cost of Skills" stat on Sanctuary of Thought no longer incorrectly affects Mana Reservation
 * "+X to level of all Minion Skill Gems" no longer incorrectly applies to Support Gems

### 1.4.149 - 2019/09/05
 * Fixed Vaal Pact not working

### 1.4.148 - 2019/09/05
 * Fixed crash with Resolute Technique
 * Fixed Poison DPS not being calculated

### 1.4.147 - 2019/09/05
 * Added 3.8.0 passive tree

### 1.4.146 - 2019/06/09
 * Fixed Blood and Sand having the wrong maximum gem level

### 1.4.145 - 2019/06/09
 * Fixed passive tree art

### 1.4.144 - 2019/06/09
 * Updated passive tree
 * Fixed Shield Charge not getting the correct damage stats

### 1.4.143 - 2019/06/09
 * Fixed various weapon modifiers not working correctly
 * Fixed error that could occur when comparing 3.6 and 3.7 trees
 * Fixed the chain count modifier on Snakepit not applying correctly

### 1.4.142 - 2019/06/09
 * Added the following new gems:
    * Berserk
    * Bladestorm (the buffs from the storms can be enabled in the Skill Options section of the Configuration tab)
	* Blood and Sand (you can switch stances in Skill Options)
	* Chain Hook
    * Dash
	* Flesh and Stone (you can switch stances in Skill Options)
	* Frostblink
	* Perforate
	* Precision
	* Pride
    * Steelskin
	* Close Combat (mostly non-functional)
	* Impale (the Impale mechanic is still unsupported)
	* Pulverise
	* Rage
	* Shockwave
 * Applied the skill reworks and balance changes for 3.7.0
    * Note that Cast While Channelling will not work correctly for the time being due to some significant changes
 * Updated item bases and mods for 3.7.0
 * Applied the accuracy changes from 3.7.0

### 1.4.141 - 2019/06/06
 * Fixed Rage degeneration applying incorrectly (again)

### 1.4.140 - 2019/06/06
 * Fixed Rage degeneration applying incorrectly

### 1.4.139 - 2019/06/06
 * The Rage option in the Configuration tab will now correctly show when the relevant passives are allocated

### 1.4.138 - 2019/06/05
 * Passive tree updated to 3.7.0
 * Added support for multiple passive tree versions in one build:
    * Trees in existing builds will default to the 3.6 tree
    * New builds (or new trees in existing builds) will use the 3.7 tree
    * Old trees can be converted to the latest version using a button that will appear at the bottom of the 
	  Tree tab when viewing an old tree; this creates a copy of the tree, so you can switch back if needed

### 1.4.137 - 2019/04/10
 * Fixed issue preventing Cast while Channelling from working correctly

### 1.4.136 - 2019/04/07
 * You can now import characters from the console realms
 * Updated item mods and skill gems to account for changes in recent patches
 * Fixed issue preventing Icestorm's duration from scaling from Intelligence
 
### 1.4.135 - 2019/03/14
 * Fixed crafted mods on imported items not being recognised
 * Storm Call now correctly shows DPS instead of just average damage

### 1.4.134 - 2019/03/12
 * Fixed various issues with importing fractured and synthesised items
 * Fixed issues with stat comparisons in weapon tooltips

### 1.4.133 - 2019/03/12
 * The debuff durations of Bane and Soulrend are now correctly affected by Temporal Chains
 * Bane is now correctly affected by modifiers to Curse Skills
 * Synthesised items can now be imported

### 1.4.132 - 2019/03/10
 * Added the following new gems:
    * Bane
	* Divine Ire
	* Purifying Flame
	* Malevolence
	* Soulrend
	* Wave of Conviction (the type of Exposure being applied can be set in the Configuration tab)
	* Zealotry
	* Energy Leech
	* Intensify (Intensity stacks can be set in the Configuration tab)
	* Unleash (does not currently affect DPS)
 * Applied the reworks for the following gems:
    * Holy Flame Totem
	* Storm Burst (DPS calculation isn't currently accurate)
	* Infused Channelling (Infusion can be enabled in the Configuration tab)
 * Added the following skills and supports from uniques:
    * Lightning Aegis
	* Precision
	* Blessing (the aura and reservation durations for supported skills can be found in the Calcs tab)
 * Applied all skill balance changes for 3.6
 * Added the following 3.6 uniques: (thanks PJacek)
    * Circle of Regret
    * The Eternity Shroud
	* Garb of the Ephemeral (Divinity can be enabled in the Configuration tab)
	* Maloney's Mechanism
	* Offering of the Serpent
    * Vixen's Entrapment
 * Updated the passive tree
 * Updated item bases and mods for 3.6
 * Winter Orb's hit rate is now correctly affected by modifiers to Cast Speed

### 1.4.131 - 2019/03/08
 * Updated boss curse effect penalty
 * Removed min/max Crit Chance limits
 * Fixed the passive tree node location popup showing the wrong locations

### 1.4.130 - 2019/03/07
 * Passive tree updated to 3.6
 * Added the following 3.6 uniques: (thanks PJacek)
    * Bottled Faith
    * Circle of Nostalgia
    * Hyrri's Truth (except the Precision skill)
    * March of the Legion (except the Blessing support)
	* Mask of the Tribunal
	* Nebulis
    * Perepiteia (except the Lightning Aegis skill)
	* Storm's Gift
 * Added most 3.5 uniques (thanks Patchumz and PJacek)
 * Added support for Energy Shield Leech
 * The stat comparisons in tooltips for non-equipped two handed weapons now show the changes from replacing both
   weapons if you are dual wielding, rather than your main hand weapon only
 * Added base radius values for Dark Pact (24), Vaal Blight (20), and Wither (18)
 * Fixed issue preventing local life on hit modifiers from working correctly
 * Storm Call now shows DPS as well as average damage
 * Decay DPS is now only shown if the skill can deal Chaos Damage
 * Fixed error when trying to add a custom modifier to Abyss Jewels

### 1.4.129 - 2019/01/13
 * "while Focussed" modifiers are now correctly recognised
 * "+X to minimum Endurance Charges" now works correctly

### 1.4.128 - 2019/01/11
 * Fixed issue preventing Empower and Enhance supports from working

### 1.4.127 - 2019/01/06
 * Fixed error when showing tooltip for Abyssal Cry
 * Fixed error when Gruthkul's Pelt is used in builds that contain spells
 * Fixed error when opening builds containing certain Spectres

### 1.4.126 - 2019/01/04
 * Fixed mana cost multipliers on support gems not applying

### 1.4.125 - 2019/01/04
 * Fixed Blasphemy mana reservation
 * Fixed error that sometimes occurred when adding gems

### 1.4.124 - 2019/01/03
 * Hovering over a gem in the Skills tab will now show the gem's full tooltip, including stats
 * Fixed new issue causing Configuration tab options to not appear

### 1.4.123 - 2019/01/02
 * Fixed issue causing Configuration tab options to sometimes fail to appear when appropriate
 * Fixed error when adding crafted modifiers to items

### 1.4.122 - 2019/01/01
 * Updated the crafting bench options for 3.5
 * Added support for most of the new craft modifiers
 * Applied the weapon restriction changes from 3.5
 * Adrenaline can now always be enabled (as it is no longer exclusive to Champion)
 * Fixed issue with modifiers to socketed gem level applying twice

### 1.4.121 - 2018/12/12
 * Applied the unique balance changes for 3.5
 * Added base radius values for Vortex (20), Armageddon Brand (18/8), Winter Orb (16), and the Banner skills (40)
 * Fixed issue with certain conditional skill stats not working correctly
    * This notably caused Elemental Hit to deal all elements at once

### 1.4.120 - 2018/12/11
 * Added skill parts to Shattering Steel to show both projectile and cone damage
 * Fixed Claw Crit Chance conversion from Rigwald's Curse
 * Fixed node power calculations for minion builds

### 1.4.119 - 2018/12/09
 * Added additional skill parts to Ice Spear to simulate all projectiles hitting the target
 * Added support for the various Brand and Banner-related passive skills
 * Fixed issue with node power generating incorrectly for certain builds
 * Fixed Vortex showing an infinite cast rate
 * Fixed removable charge counts being incorrectly calculated; this affected Discharge's DPS
 * Fixed Vile Toxins' damage bonus not applying

### 1.4.118 - 2018/12/09
 * Added the following new gems:
    * Armageddon Brand
	* Storm Brand
	* Brand Recall
	* Dread Banner
	* War Banner
	* Lancing Steel
	* Shattering Steel
	* Winter Orb
	* Bonechill (partial; only the Cold Damage Taken over Time portion works)
	* Multiple Totems
 * Applied all skill balance changes for 3.5
 * Applied all item base balance changes for 3.5
 * Updated/added many uniques from Incursion and Delve (thanks PJacek)
 * Corrected the implicits on a number of unique swords (thanks baranio)
 * Fixed the rolls on Impresence's Armour modifier (thanks nathanrobb)
 * Removed errant "Cannot be Frozen" modifier from Crystal Vault (thanks bblarney)
 * Fixed certain curse stats having the wrong sign (positive instead of negative, or vice versa)
 * Fixed some remaining cases of modifiers being attributed to the wrong skill gem in the Calcs tab
 * The Virulence bonuses for Herald of Agony's Agony Crawler no longer incorrectly apply to Phantasms
 * Fixed loading of 2.6 builds
 
### 1.4.117 - 2018/12/06
 * Passive tree updated to 3.5
 * Added support for Far Shot, and the related Ascendant Deadeye projectile damage scaling

### 1.4.116 - 2018/10/31
 * Vaal Arc's Chain damage bonus now works correctly
 * Fixed the leech percentage on Blood Rage
 * Fixed the Damage penalty on Spell Totem Support
 
### 1.4.115 - 2018/10/29
 * Added the following spectres to the spectre library:
    * Bone Husk
	* Bone Stalker
	* Colossus Crusher
	* Risen Vaal Fanatic (all variants)
	* Stoneskin Flayer
 * Fixed the Slam and Crusade Slam abilities used by Sentinels
 * Fixed Temporal Chains' Effects Expire Slower stat
 * Fixed error when using Summoned Ursa's Rallying Cry skill
 * Fixed an issue where modifiers from skills sometimes had the wrong source in the Calcs tab
 
### 1.4.114 - 2018/10/27
 * Added the following minions:
    * Bestial Rhoa
	* Bestial Snek
	* Bestial Ursa
	   * You can enable the Rallying Cry skill in the Skill Options section of the Configuration tab
 * Added the following spectres to the spectre library:
	* Enhanced Vaal Fallen (the DPS for their Elemental Hit skill might not be correct)
    * Kiln Mother
 * Fixed the Cast Speed from Haste not applying correctly
 * Fixed Spectre's Curse skills not working correctly
 * Fixed Assassin's Mark's Crit Multiplier stat
 * Fixed the missing DPS multiplier on Ice Golem's Cyclone skill
 * Fixed the interaction between Unnatural Instinct and Might of the Meek

### 1.4.113 - 2018/10/26
 * Added the following spectres to the spectre library:
    * Host Chieftain
    * Risen Vaal Advocate (Physical)
	* Risen Vaal Advocate (Fire)
	* Risen Vaal Advocate (Chaos)
 * Fixed the missing Cyclone skill on Dancing Dervish
 * Fixed more instances of buff effects not applying (Vaal Ancestral Warchief, Lightning Golem's Wrath)

### 1.4.112 - 2018/10/26
 * Fixed a bug preventing certain buff/aura affects from applying; this affected Herald of Agony, Haste, and Vaal RF

### 1.4.111 - 2018/10/26
 * Vaal Earthquake's DPS should now be calculated correctly
 * Fixed error with "X of the Grave" glove enchantments
 * Fixed error when loading a build with Vaal Double Strike

### 1.4.110 - 2018/10/26
As of this update I am once again able to add and update minions/spectres, which hadn't been possible since 3.0:
 * Added the following minions:
    * Agony Crawler (Herald of Agony)
	   * You can set the Virulence stack count in the Skill Options section of the Configuration tab
	* Sentinel of Purity (Herald of Purity)
	* Sentinel of Dominance (Dominating Blow; only the Normal variant)
	* Holy Relic
	    * You can enable the regeneration aura in the Skill Options section of the Configuration tab
	* Summoned Phantasm (including Soulwrest's Summon Phantasm skill)
 * Added the following spectres to the spectre library:
	* Alpine Shaman
	* Frost Sentinel
	* Kitava's Herald
	* Risen Vaal Advocate (Lightning)
	* Sandworn Slaves
	* Solar Guard
	* Solaris Champion
	* Tukohama's Vanguard
	   * The stage count for the Scorching Ray Totem can be set in the Skill Options section of the Configuration tab
	* Wicker Man
 * Minion Accuracy values are now more correct
 * Minion Armour values are now calculated and displayed in the Calcs tab

### 1.4.109 - 2018/10/25
 * Applied the skill changes from 3.4.2
 * Updated the passive tree export links to 3.4
 * Added support for Hierophant's Illuminated Devotion
 * The increased Damage per Block Chance Elder Shield modifier is now correctly recognised
 * Fixed error that occurred when importing weapons with Abyssal Sockets

### 1.4.108 - 2018/09/08
 * Applied the skill and enchantment fixes from 3.4.1
 * The "more Physical Damage over Time" stat on Vicious Projectiles no longer incorrectly applies to Poison
    * This issue resulted in significantly overstated DPS for most Projectile Poison builds; I apologise for any inconvenience
	   and/or shattered dreams resulting from this oversight
 * The buffs from the Vaal and non-Vaal Ancestral Warchief skills no longer stack
 * The passive tree can do longer be dragged infinitely in any direction
 
### 1.4.107 - 2018/09/01
 * The per-stage bonus for Scourge Arrow now correctly applies to the thorn arrows

### 1.4.106 - 2018/09/01
 * Added support for the "50% less X Damage" modifiers on the Combat Focus jewels

### 1.4.105 - 2018/09/01
 * Added Helmet enchantments for the new skills
 * Applied balance changes to existing unique items
 * Applied the change to base Trap Throwing Time from 3.4

### 1.4.104 - 2018/09/01
 * Fixed error message caused by Spiritual Command
 
### 1.4.103 - 2018/09/01
 * Added the following new uniques: 
    * Aul's Uprising
	* Cerberus Limb
	* Chaber Cairn
	* Curtain Call
	* Demon Stitcher
	* The Eternal Apple
	* Geofri's Legacy
	* The Grey Spire
	* Mark of Submission
	* Perquil's Toe
	* The Primordial Chain
	* Soulwrest (except the Summon Phantasm skill)
	* Unnatural Instinct
	* Command of the Pit
	* Crown of the Tyrant
	* Doryani's Delusion
	* Hale Negator
 * Updated item modifiers for crafting
 * Added support for the "40% chance to deal 100% more Poison" modifier on Master Toxicist
 * Gathering Winds now applies Tailwind to your Minions
 * Modifiers to Minion Attack and Cast Speed are now correctly converted by Spiritual Command

### 1.4.102 - 2018/09/01
 * Fixed issue preventing Total DPS from being calculated for dual wielding attack builds
 * Toxic Rain's DoT is now affected by modifiers to Area Damage

### 1.4.101 - 2018/09/01
 * Static Strike is now fully updated for 3.4

### 1.4.100 - 2018/09/01
 * Consecrated Path and Smite are now correctly affected by Melee modifiers
 * Earthquake's Aftershock damage multiplier now works correctly

### 1.4.99 - 2018/09/01
 * Added the new skills for 3.4:
    * Vaal Ancestral Warchief
	* Consecrated Path
	* Herald of Agony (except the Minion, sorry!)
	* Herald of Purity (except the Minion)
	* Smite
	* Scourge Arrow
	* Summon Holy Relic (except... the Minion)
	* Toxic Rain
	* Withering Touch
 * Applied all changes to existing skills for 3.4
 * Flesh Binder's Caustic Ground effect now works correctly

### 1.4.98 - 2018/08/29
 * Modifiers to Damage over Time with Bow Skills now work correctly
 * Acrobatics now works correctly

### 1.4.97 - 2018/08/29
 * Passive tree updated to 3.4
 * Other changes for 3.4 are still to come
 * Vaal Righteous Fire is now correctly affected by modifiers to Area Damage
 * Corrected the range of the explicit increased Spell Damage stat on Shimmeron
 * Armour/Evasion/ES can no longer be negative
 * Bubbling Flasks' Instant Recovery percentage is no longer incorrectly affected by Flask Effect modifiers (as in 2.6)

### 1.4.96 - 2018/06/11
 * Fixed an issue preventing certain skill-specific modifiers from applying; particularly for skills used by Minions
    * Notably, this fixes the Zombie Slam modifiers from Flesh Binder and Violent Dead
 * The "+ to Level of Socketed AoE Gems" modifier now applies correctly
 * Corrected the level requirement on Stormwall
 * Cold Snap's DoT is now correctly affected by Area Damage modifiers

 In other news, Path of Building has now been downloaded over 1,000,000 times!

### 1.4.95 - 2018/06/08
 * Added the following new uniques:
	* Sinvicta's Mettle
	* Unyielding Flame
    * Architect's Hand
	* Transcendent Flesh
	* Tempered Mind
	* Transcendent Mind
	* Tempered Spirit
	* Transcendent Spirit
 * Updated the rolls on many new uniques
 * Updated the passive tree; in particular, this corrects the positioning of the Overcharged cluster
 * You can now apply 2 corrupted implicits to an item
 * Uniques in the unique database now show their source (if drop-limited) and upgrades (e.g Prophecy/Blessing/Vial)
 * Aura/buff/curse skills are now correctly enabled by default when importing
 * Slavedriver's Hand now correctly converts Attack and Cast Speed modifiers to Trap Throwing Speed

### 1.4.94 - 2018/06/03
 * Fixed several issues with sorting gems by DPS
 * Updated the game version selector
 * Trap Support no longer incorrectly has a cooldown
 * Flamethrower Trap is now correctly affected by Area Damage modifiers
 * Fixed issue preventing certain item-granted skills from working correctly
 * Fixed error that could occur when adding item-granted skills (such as Aspects)

### 1.4.93 - 2018/06/02
 * Applied the 3.3 changes to:
    * Item bases and modifiers, including corrupted implicits
    * Skill enchantments
    * Unique items
 * Fire, Ice, and Lightning Traps no longer incorrectly show a cooldown
 * Removed non-functional option for Charged Dash

### 1.4.92 - 2018/06/02
 * Added/updated all skill gems for 3.3
 * Aura/buff/curse skills can now be enabled/disabled in the Skills tab independantly of the skill gem itself
 * Fixed the "Onslaught on Low Mana" modifier on Dance of the Offered and Omeyocan (thanks ExaltedShard)
 * Quartz Infusion now correctly enables Phasing when you have Onslaught
 * The "Used a Movement Skill Recently" option now correctly enables for all Movement skills

### 1.4.91 - 2018/06/01
 * Added the missing limit to Pure Talent
 * Slavedriver's hand no longer incorrectly converts Attack Speed modifiers to Trap Throwing Speed for Attack traps
 * Fixed error when hovering over "Total Increased" in the Calcs tab on certain builds

### 1.4.90 - 2018/05/31
 * Added the following announced uniques for 3.3:
    * Zeel's Amplifier
	* Soul Catcher
	* Soul Ripper
 * Added the following very old uniques:
    * Eyes of the Greatwolf
 * The Character Import process has been improved:
    * The last account and character imported to the current build are now remembered
	* The character list can now be filtered by league
 * Ctrl+F now focuses the search fields in the Tree and Items tabs
 * Added options to the Configuration tab for:
    * # of Enemies Killed Recently
	* # of Enemies Killed by Totems Recently
	* # of Enemies Killed by Minions Recently
 * Enabling the Elemental Equilibrium Map Modifier option now correctly shows the EE-related options
 
### 1.4.89 - 2018/05/31
 * 3.2 Shadow passive trees will now migrate to 3.3 without a full reset

### 1.4.88 - 2018/05/30
 * Sorting unique flasks by DPS now works correctly
 * Fixed issue where Slavedriver's Hand was granting Blood Magic to all skills
 * Fixed a rare issue in which nodes in Ascendant could be unallocated without properly removing dependant nodes

### 1.4.87 - 2018/05/30
 * Passive tree updated to 3.3
 * The unique items list can now be sorted by DPS
 * Added the following announced uniques for 3.3:
    * Combat Focus
    * Earendel's Embrace
	* Slavedriver's Hand
	* Tempered Flesh
	* Apep's Slumber
	* Apep's Supremacy
	* Coward's Chains
	* Coward's Legacy
	* Dance of the Offered
	* Omeyocan
	* Story of the Vaal (partial; random conversion is not supported)
	* Fate of the Vaal (partial; random conversion is not supported)
	* Mask of the Spirit Drinker
	* Mask of the Stitched Demon
	* Sacrificial Heart
	* Zerphi's Heart
 * Added the following uniques from mid-3.2:
    * Chains of Command
	* Corona Solaris
	* Gluttony
 * Added an option to the Configuration tab for "Have you Shattered an Enemy Recently"
 * Added the missing league tags on the Bestiary uniques
 * Modifiers to Action Speed (e.g Tailwind) now correctly affect Trap Throwing Speed, Mine Laying Speed, and Totem Placement speed
 * Projectile Weakness's added Knockback chance is now factored into the Knockback calculations
 * The damage-per-Ailment-type modifier on Yoke of Suffering is now supported (thanks chollinger)
 * The Global Physical Damage stat on Prismatic Eclipse is now correctly recognised
 * The increased Damage to Pierced targets modifier on Drillneck is now correctly recognised
 * Enlighten no longer incorrectly applies to skills granted by items
 * Modifiers to Burning Damage no longer incorrectly apply to Poison sourced from Fire Damage
 
### 1.4.86 - 2018/05/08
 * Fixed the importing of character passive trees
 * The "no/all equipped items are corrupted" modifiers on Voll's/Malachai's Vision are now recognised correctly
 * Fixed error when setting Spectre level above 100 (thanks Faust)

### 1.4.85 - 2018/03/22
 * Added Helmet enchantments for Spectral Shield Throw and Tectonic Slam
 * Added Light Radius Mod to the Other Defences section of the Calcs tab
 * Fixed issue preventing additional Projectile enchantments for Bow skills from being recognised
 * Fixed the conditional damage multiplier on Hypothermia
 * Fixed an error that sometimes occurred when trying to craft a jewel

### 1.4.84 - 2018/03/21
 * Added the following new uniques:
	* All 16 uniques from the Bestiary bosses (including all granted skills and associated mechanics)
    * Asenath's Chant
	* The Effigon
	* Hyrri's Demise
	* Indigon (partial)
	* Loreweave
	* Malachai's Awakening
	* Sanguine Gambol
	* Voidforge (partial; the random extra damage cannot be simulated yet)
 * Updated the modifier rolls on Panquetzalibizapizzatli
 * Updated the modifier rolls on several other new uniques
 * Updated the stat parsing to account for various stat wording changes made in 3.2
    * Notably, this fixes the various additional Arrow/Projectile stats that were no longer being recognised
 * Added support for the Icicle Burst skill granted by Cameria's Avarice
 * Added options to the Configuration tab to override the number of Power/Frenzy/Endurance Charges used when they are enabled
 * Added an option to the Configuration tab for "Energy Shield Recharge started Recently?"
 * Fixed error caused by Zizaran trying to add mods onto an item

### 1.4.83 - 2018/03/03
 * Added the following new uniques:
    * Crystal Vault
	* Dreadbeak
	* Dreadsurge
	* Duskblight
	* Frostferno
    * Geofri's Devotion
	* Mark of the Elder
	* Mark of the Red Covenant
	* Mark of the Shaper
	* Mirebough
	* Sunspite
    * Timetwist
	* Wildwrap
    * Winterweave
 * Updated Doryani's Fist with the new stat wording; this stops it from incorrectly benefiting Spectral Shield Throw

### 1.4.82 - 2018/03/03
 * Fixed a few odd UI glitches when using Summon Phantasm on Kill with an active skill that has multiple parts
    * A side effect is that the sidebar stat box now expands upwards to fill any empty space below the main skill selector

### 1.4.81 - 2018/03/02
 * Added the 3 new skill gems introduced in 3.2
    * Summoned Phantasms are not fully supported, as their projectile spell cannot be added yet
 * Applied the minion changes for 3.2

### 1.4.80 - 2018/03/02
 * The maximum Chain count for chaining skills is now shown in the "Skill type-specific Stats" section of the Calcs tab
 * Added an option to the Configuration tab for "# of times Skill has Chained"
    * This allows all per-Chain modifiers to work, including Ricochet
 * Added an option to the Configuration tab for "# of Poisons applied Recently"
 * Added the following new uniques:
    * The Nomad
	* The Tactician
    * Windshriek

### 1.4.79 - 2018/03/01
 * Added an option to the Configuration tab for "Is there only one nearby Enemy?"
 * Updated Gladiator's "Blocked a Hit from a Unique Enemy" option to reflect the 3.2 change ("Recently" -> "past 10 seconds")
 * Added support for White Wind's "while your off hand is empty" condition (thanks chollinger)
 * Rage is now correctly enabled when taking War Bringer
 * The life loss from Rage is now factored into Life Regen
 * Fixed the missing increased Physical Damage modifier on Cameria's Avarice
 * Fixed the missing flat Physical Damage modifier on Disintegrator
 * Vaal Summon Skeletons now correctly benefits from modifiers that apply to Summon Skeleton
 * Updated the passive tree export links to 3.2.0

### 1.4.78 - 2018/03/01
 * Passive tree updated to 3.2; most of the new nodes and mechanics are supported, with the notable exceptions being:
    * Hierophant's Arcane Surge nodes
	* Elementalist's Golem nodes
 * Added support for action speed modifiers (Tailwind, Temporal Chains, Chill/Freeze)
 * Added the following new uniques:
    * Cameria's Avarice
	* The Dancing Duo
	* Stormfire
 * Corrected the tooltip for the Intimidate option in 3.0 builds

### 1.4.77 - 2018/02/24
 * Added Might of the Meek
 * Improved the handling of radius jewels; this mainly addresses issues with overlapping jewels
    * Notably, threshold jewels will now correctly handle nearby nodes that have converted attributes

### 1.4.76 - 2018/02/23
 * Added Atziri's Reflection
 * Unique items can now be made Elder/Shaper
 * Corrected the stat ranges on Ahn's Might
 * Prismatic Eclipse's "+ Melee Weapon Range per White Socket" modifier now works correctly
 * The second variant selection on Watcher's Eye is now correctly preserved when the build is saved
 * The artwork for the passive tree is now loaded asynchronously, which should improve startup time

### 1.4.75 - 2018/02/22
I apologise for the lack of updates recently; I hadn't had time to work on this, but I will be
putting in a fair bit of work over the coming weeks.
 * Added the following uniques announced for 3.2:
   * Disintegrator (including Siphoning Charge support)
   * Gorgon's Gaze (excluding the Summon Petrification Statue skill)
   * Voidfletcher (partial)
   * Doedre's Malevolence
   * Fox's Fortune
   * Greedtrap
   * Panquetzalitzibitzipretzeliztli
   * The Stormwall
   * Craiceann's items will be implemented once I find out what the hell Crab Barriers are
 * Added Helmet enchantments for the new skills added in 3.1
 * Elder modifiers now correctly appear on crafted Shields
 * Reservation calculations should now always be accurate when you have increased Mana Reserved
 * Fixed error that could appear when editing certain Elder or Shaper items
 * Intimidate's increased Damage bonus now correctly applies to Attack Damage only
 * Oni-Goroshi's Her Embrace no longer persists after the item is unequipped
 * Added support for the added Critical Strike Chance to Socketed Attacks/Spells stats on Shaper/Elder helmets
 * The reduced Elemental Damage taken modifier on Nebuloch now functions correctly
 * Hidden Potential's increased Damage modifier should now be correctly recognised
 * Fixed the missing defences on Magna Eclipsis
 * Fixed the typo in Beltimber Blade's name
 * Corrected the Life roll on the Physical variant of Impresence

### 1.4.74 - 2017/12/25
 * Added support for the Her Embrace buff granted by Oni-Goroshi
    * It can be enabled using a new option in the Combat section of the Configuration tab
 * You can now choose the aura modifiers on Watcher's Eye
 * Added an option to the Configuration tab for "Have you Shocked an Enemy Recently?"
 * Added an option to the Configuration tab for "Have you used a Minion Skill Recently?"
 * The "Your X Damage can Poison" stats on Volkuur's Guidance should now be correctly recognised
 * Fixed issue with the damage calculations for Bodyswap
 * Fixed error caused by setting the travel distance option for Charged Dash

### 1.4.73 - 2017/12/25
 * Fixed error that occured when changing some items to Shaper or Elder

### 1.4.72 - 2017/12/25
 * Added 2 Abyssal Socket variants to the Abyss league uniques
 * Cremation now correctly benefits from modifiers to Area Damage

### 1.4.71 - 2017/12/25
This update adds full support for Abyss Jewels:
 * You can now socket Abyss Jewels in items that have Abyssal Sockets
 * Item modifiers that interact with Abyss Jewels are now supported
 * Abyss Jewels can now be crafted using the "Craft item..." option
 * Abyss Jewels socketed in items will now be imported when importing a character's Items and Skills
 
This update also adds support for item sockets:
 * An item's sockets are now shown in the tooltip
 * When editing an item you can now edit the sockets and links
 * Item modifiers that interact with socket colours are now supported (e.g Prismatic Eclipse)

This update also adds support for Shaper/Elder items:
 * Item tooltips now indicate if an item is a Shaper or Elder Item
    * These items will need to be re-imported to be recognised as such
 * When editing a Normal, Magic or Rare item you can set the item to be Shaper or Elder
 * When crafting an item, setting it to Shaper or Elder will enable the corresponding modifiers

Other changes:
 * Added Oni-Goroshi
 * Added support for the Elemental Penetration support provided by Shroud of the Lightless
 * Corrected the Critical Strike Chance per Power Charge modifier on Shimmeron
 * Corrected the radius values of several skills that were updated in 3.1
 * Fixed exported passive tree links to use the correct tree version

### 1.4.70 - 2017/12/17
 * Added the following new uniques:
    * Ahn's Contempt
	* Augyre
	* Beltimer Blade
	* Blasphemer's Grasp
	   * Detection/counting of equipped of Elder Items does not work yet
	* Darkness Enthroned
	   * Does not function, as support for socketing Abyss Jewels in items is not implemented yet
	* Hopeshredder
	* Impresence (non-Cold variants)
	* Inpulsa's Broken Heart (mostly non-functional for now)
	* Lightpoacher (mostly non-functional; however Spirit Burst is supported)
	* Magna Eclipsis
	* Shimmeron
	* Shroud of the Lightless
	* Tombfist (mostly non-functional for now)
	* Vulconus
 * Added Corpse Explosion skill parts to the following skills:
    * Bodyswap
    * Cremation
    * Detonate Dead (this allows the Spell part to benefit from Spell modifiers)
	* Volatile Dead
 * Updated rolls on many of the new uniques
 * Added an option to the Configuration tab for "Are you always moving?"
 * Corrected the maximum stack count for Wither (thanks DragoonZ)
 * "Adds X to Y <Type> Damage to <Weapon> Attacks" stats should now be recognised correctly
 * The "more Life" stat on Minion Life Support should now work correctly

### 1.4.69 - 2017/12/09
 * Added the following new uniques:
    * Balefire
	* Cyclopean Coil
	* Gloomfang
	* Grelwood Shank
	* Impresence
	* Nebuloch
	* Watcher's Eye
 * Updated Ahn's Might with its final mods
 * Removed the obsolete 4x DPS multiplier from Lightning Tendrils

### 1.4.68 - 2017/12/09
 * Added the following new uniques:
    * Bloodbond (including partial support for the Blood Offering skill; only the damage bonus works at present)
	* Bubonic Trail (including the Death Walk skill)
    * Coralito's Signature
	* The Golden Rule
	* Invictus Solaris
    * Iron Heart
	* Kalisa's Grace
	* The Long Winter
	* Oskarm
	* Soul's Wick
 * The "Corpse Life" option has been moved from the Skill Options section to the General section of the
   Configuration tab, as it is now used by several skills
 * Added an option to the Configuration tab for "# of Poison on You"

### 1.4.67 - 2017/12/09
 * Fixed error that occurs when trying to import a character's items

### 1.4.66 - 2017/12/09
 * Added support for the new skill gems
    * Most should be fully or almost fully functional, with the exception of Mirrage Archer
 * Added the following new uniques:
    * Arborix
    * Cane of Unravelling
    * Doedre's Skin
    * Giantsbane
    * Leper's Alms
    * Memory Vault
    * Pure Talent
    * Ralakesh's Impatience
    * Stormcharger
    * The Hungry Loop
       * Note that it may not be fully functional for a while due to the difficulty involved in handling it
    * The Poet's Pen
    * Vix Lunaris
    * White Wind
    * Wraithlord
    * Yoke of Suffering
 * Applied the 3.1 changes to the following uniques:
	* Rise of the Phoenix (thanks twiz-ahk)
    * Queen of the Forest (thanks xmesaj2)
	* Atziri's Acuity
	* The Baron
	* Doomfletch/Doomfletch's Prism
	* Lion's Roar
    * Omen on the Winds
	* Witchfire Brew
	* Other uniques are awaiting confirmation of wording changes
 * Added Dialla's Malefaction and Malachai's Mark
    * Note that Dialla's Malefaction is non-functional as it requires significant changes to support it

The following changes are courtesy of eps1lon:
 * Added an option to the Configuration tab for "Used a Movement Skill Recently"
 * Fixed variants for Berek's Pass's increased Fire Damage stat

### 1.4.65 - 2017/12/07
Apologies for the lack of updates recently; I've been very busy. I'll try and manage a few more updates over the
coming weeks, but I can't make any promises yet.
 * Passive tree updated to 3.1
 * You can now rename builds and folders to change only the case of letters
 * Node tooltips now correctly update when cancelling alternate path tracing
 * Fixed Discharge's damage penalty when triggered
 * Fixed Multistrike's attack speed bonus to only apply to Melee attacks
 * Fixed various Skeleton-related modifiers that were being recognised but were not functioning correctly
 * Fixed issue where the program's UI wouldn't be correctly scaled when opened in a non-maximised state

### 1.4.64 - 2017/10/01
 * Trap Throwing Time, Mine Laying Time, and Totem Placement Time are now calculated and shown in the sidebar
    * Special thanks to aggixx for measuring the base time of those animations
 * Trap Cooldown is now shown in the sidebar (in addition to the Calcs tab)
 * Trap Trigger Radius and Mine Detonation Radius are now calculated and shown in the Calcs tab
 * Added support for Vaal Breach
 * All Configuration tab options upon which any Support gems depend are now permanently visible, even if enabling
   them would have no effect
 * Corrected the "Elemental Resistances while on Low Life" stat on Honourhome
 * The Melee Damage buff from Phase Run now correctly excludes Totem skills

This update also reworked the program's window initialisation code.
The most visible change is that the program's main window now opens while the program is initialising, but this
rework is primarily intended to solve three uncommon issues:
 * The program would crash when launched on a non-primary monitor on certain systems
 * The program's UI would be offset when running on systems with certain Intel HD Graphics driver versions
 * The program would crash when launched using Wine

### 1.4.63 - 2017/09/16
 * Added descriptions for support gems
 * The Caustic Cloud from Beacon of Corruption is now correctly affected by Area Damage modifiers on the minion
 * Gaining immunity to Curses now correctly prevents self-Curses from applying
 * Buffs granted by support gems are no longer incorrectly affected by buff effect modifiers of the linked skill
 * Fixed issue causing gem sorting and stat differences to be incorrect when Empower/Enhance/Enlighten are selected

### 1.4.62 - 2017/09/01
 * The instant Leech modifier on Atziri's Acuity should now be recognised correctly
 * Fixed issue preventing modifiers to the damage of Channelling skills from applying to Damage over Time
 * Fixed issue causing the Innervation buff to apply regardless of the setting in the Configuration tab

### 1.4.61 - 2017/08/21
 * The Secondary Durations for Blight, Frost Bomb and Phase Run are now calculated and shown in the Calcs tab
 * Added an option to the Configuration tab for "# of Shocked Enemies Killed Recently"
 * Added support for the "Your Spells are disabled" modifier on Gruthkul's Pelt
 * Poison/Bleed Chance on weapons is now correctly local

### 1.4.60 - 2017/08/21
 * The main Socket Group selector in the sidebar now shows the Socket Group tooltip when you hover over it
 * Updated the skill data for Charged Dash to reflect the changes made in 3.0.1
 * Modifiers that apply when holding a Shield now correctly apply when Necromantic Aegis is allocated
 * The stat comparison for Total DPS inc. Poison is now more intuitive when gaining or losing the ability to Poison
 * Updated the "Is the enemy a Boss?" option to remove the Ailment Duration modifiers from Shaper/Guardian
 * Corrected the base Energy Shield roll on Martyr's Crown
 * Corrected the Critical Strike Multiplier penalty on Ungil's Harmony
 * Updated the Poison Chance modifiers on Snakebite and Cospri's Will

### 1.4.59 - 2017/08/14
With this update, new builds will default to 3.0, and the version selection dialog will no longer display.
Builds can still be converted to 2.6 via the Configuration tab. All 2.6 builds will continue to work as normal, 
however from this point some new features may only be available for 3.0 builds.
 * The Helmet enchantments for the new skills are now available in the item enchanting system
 * The resistance penalties from completing Act 5/10 can now be disabled using a new option in the Configuration tab
 * Removed the attack rate cap for Blink/Mirror Arrow clones, which is no longer present in 3.0
 * An explanatory message is now shown in the sidebar if the main skill is disabled (e.g if no compatible weapon is equipped)
 * Fixed the Burning Damage roll on Pyre
 * Fixed the flat Physical Damage rolls on Widowmaker
 * Fixed the Elemental Resistances roll on Immortal Flesh
 * Fixed issue preventing Socketed Gem modifiers from applying to gems socketed into the alternate weapon set

### 1.4.58 - 2017/08/09
 * Added all of the new uniques
 * Added support for the Void Gaze skill granted by Eber's Unification
 * Added support for the Storm Cascade skill granted by The Rippling Thoughts
 * The other skills granted by the new uniques are only partially supported at the moment (no support for the minions)
 * Charged Dash now has a "Travel distance" option in the Configuration tab
 * Updated the total available passive skill points
 * Burn faster/Burn slower should both now be calculated correctly
 * Modifiers to life/mana/ES recovery rate should now only affect recovery over time
 * The build list now uses natural sort order (so "Foo 50" comes before "Foo 100")
 * The gem selection dropdown now accepts "active" as a filter keyword in additional to other gem tags (such as "support")

For 2.6 builds:
 * The link created when exporting the passive tree now opens in the 2.6.2 version of the offical passive tree viewer

### 1.4.57 - 2017/08/05
 * Now that 3.0 is live, the warning that was shown before importing to 3.0 builds is now shown for 2.6 builds instead
 * The program now behaves correctly when attempting to import from an account with a private profile

For 3.0 builds:
 * Lioneye's Fall now correctly transforms modifiers that grant Ailment Damage while wielding melee weapons

### 1.4.56 - 2017/08/04
 * AoE Radius is now shown in the sidebar and stat comparison tooltips
 * The duration of Wither is now correctly affected by Temporal Chains
 * Frozen enemies are now correctly considered to be chilled as well

For 3.0 builds:
 * Updated skills and item modifiers from the patch data
 * Updated the Bleeding bonus damage against moving enemies
 * Added support for the Death Aura skill granted by Death's Oath
 * Equipping Varunastra now correctly allows "Ailment Damage while wielding X" modifiers of the appropriate types 
   to apply (thanks Spawnbroker)

### 1.4.55 - 2017/08/04
 * Fixed an issue where the stat difference tooltip on the gem enable checkbox would sometimes fail to update
 * Added an option to the Configuration tab for "Are you Bleeding?"

For 3.0 builds:
 * The Innervation buff can now be enabled using a new option to the Skill Options section of the Configuration tab
 * Dark Pact now uses the Totem's life when linked to Spell Totem
 * The increased Chaos Damage taken from the Spreading Rot jewel now applies when "Is the enemy Hindered?" is enabled
 
### 1.4.54 - 2017/08/03
 * Modifiers to Burn rate should now be simulated correctly

For 3.0 builds:
 * Added support for the %-of-Life damage scaling for Dark Pact
    * Note that the values are not final, and will change when the patch is released
	* For Cast on Skeleton, the skeleton life must be input in the Configuration tab
 * Corrected the charge bonuses which weren't reverted properly
 * Fixed the "Elemental Damage added as Chaos" modifier on Atziri's Promise; re-import from the unique DB
 * Fixed the new life modifier on Death's Oath

### 1.4.53 - 2017/08/03
 * Added Inya's Epiphany, Volkuur's Guidance and The Coming Calamity
 * Fixed an issue where the effect of the Conflux Buff option would persist after Shaper of Desolation is deallocted

For 3.0 builds:
 * Updated the passive tree to the final version
 * Updated the charge bonuses
 * Applied most of the unique changes that hadn't already been applied
 
Still to be added:
 * Some skill changes (waiting for the patch data to become available)
 * The new skill granted by Death's Oath
 * The changes to Shock and Chill

### 1.4.52 - 2017/07/30
 * Fixed an issue where attack skills could fail to utilise weapons in the second weapon set

For 3.0 builds:
 * Added preliminary support for Charged Dash, Dark Pact, and Storm Burst

### 1.4.51 - 2017/07/29
For 3.0 builds:
 * Applied the unique flask changes from the Beta patch
 * Added the new threshold jewels from the Beta patch
 * The Ruthless Blow damage multiplier now correctly applies to Melee Damage only

### 1.4.50 - 2017/07/29
 * Fixed an error that could occur when dragging items into builds with Animate Weapon

For 3.0 builds:
 * Applied the passive tree, skill, charge and item base changes from the Beta patch

### 1.4.49 - 2017/07/27
 * Added an option to the Configuration tab to activate the periodic Block chance buff from Bastion of Hope
 * The stat difference tooltip shown in the gem list should now be correct when the default gem level or quality are set

### 1.4.48 - 2017/07/27
This update brings several improvements to the Skills tab:
 * The gem selection list has been improved:
    * Compatible support gems are now sorted to the top of the list
	* Gems are sorted by DPS by default; this can be disabled per-build using a new option below the Socket Group list
	* The check mark that designates compatible support gems is now coloured according to the effect it has on your DPS;
	  green/red indicates a DPS increase/decrease, and yellow indicates no change 
	* Aura, buff and curse skill gems are now marked with a plus sign that is coloured in the same way as the check mark
 * Added two options below the Socket Group list for default gem level and quality; these are saved per-build
 * Gem slots are no longer removed when empty, but can instead be removed using the new "X" button to the left of the slot

Other changes:
 * Added the recently announced 3.0 uniques 
 * Added options to the Configuration tab for "Are you always stationary?" and "Are your minions always on Full Life?"
 * Corrected the ranges on Mantra of Flames

For 2.6 builds:
 * Converted the rare templates to the new template style

For 3.0 builds:
 * The Decay modifier from Essence of Delirium should now be recognised correctly

### 1.4.47 - 2017/07/18
 * Added support for Mantra of Flames
    * Note that the buff count is not guaranteed to be correct under all conditions

For 3.0 builds:
 * Updated Arcane Surge with the changes from the Beta patch

### 1.4.46 - 2017/07/18
 * The passive tree search field can now also match node type (keystone/notable/normal)
 * Modifiers that apply to gems socketed in items can now apply to minions summoned by those gems
 * Improved the program's startup time

For 3.0 builds:
 * Fixed error when using The Consuming Dark

### 1.4.45 - 2017/07/17
 * Fixed issue causing tooltips in the Shared Items list to display modifier ranges instead of specific values
 * Fixed the node location display in the Items tab covering jewel tooltips
 * Fixed issue preventing affixes on pre-1.4.18 crafted Flasks and Jewels from being recognised

For 3.0 builds:
 * Updated many uniques with changes from Beta

### 1.4.44 - 2017/07/14
 * The Item Crafting UI has been improved:
    * Tiers of modifiers are now collapsed into a single entry in the affix selectors
	* Sliders now appears below each affix selector that allow you to set both the tier and roll of the modifier
 * The Items tab now shows a vertical scroll bar when necessary
 * Knockback Chance/Distance calculations have been added to the Other Effects section of the Calcs tab
 * Various minor tweaks and fixes

For 3.0 builds:
 * Applied the skill and passive tree changes from the Beta patch

### 1.4.43 - 2017/07/06
 * Spectral Spirits (from Essence of Insanity) are now considered to always be on Full Life

For 3.0 builds:
 * Arcane Surge can now applied by Totem skills (as placing the totem can trigger the buff)
 * Fixed error when trying to use the 3.0 version of Drillneck

### 1.4.42 - 2017/07/06
For 3.0 builds:
 * Applied the skill, passive tree, and unique changes from the Beta patch
 * Added the Doryani's Touch skill granted by Doryani's Fist
 * Added Arcane Surge, Onslaught and Ruthless support gems

### 1.4.41 - 2017/07/03
This update introduces a new style of rare template which utilises the item crafting system.
These templates are available on the same set of bases and with the same sets of pre-selected modifiers as the
old templates, but since they are crafted items they have access to all possible modifiers instead of a subset.
These templates are only being trialed for 3.0 builds at present, but if the feedback is positive then they will be 
back-ported to 2.6 as well.
Other changes:
 * Added support for the Conflux buffs granted by Shaper of Desolation, using a new option in the Configuration tab
 * Fixed error that occured when trying to copy an item set

### 1.4.40 - 2017/07/01
 * Added support for Manifest Dancing Dervish
 * With that addition, the program should now support all active and support skills currently in-game
 * Animated Guardians now correctly benefit from inherent Dual Wielding bonuses
 * Glove enchantment skills no longer incorrectly benefit from support gems

### 1.4.39 - 2017/06/30
 * You can now apply enchantments to Gloves
 * Added support for all Glove enchantment skills
 * Various minor tweaks and fixes

### 1.4.38 - 2017/06/29
 * Added support for Devouring Totem
 * Added basic support for Conversion Trap (calculations for mana cost, cooldown and duration)
 * With the addition of support for those skills, the program now has support for all skill gems currently in-game
 * Fixed issue introduced in 1.4.37 that prevented minions from gaining block chance from Necromantic Aegis shields
 * The Melee Damage bonus from the Punisher buff is now correctly Physical-only
 * Modifiers to the effect of Fortify should now apply correctly

### 1.4.37 - 2017/06/26
This update adds support for item sets:
 * Item sets allow you to easily switch between different gear configurations in your build
 * In the Items tab, click "Manage..." above the item slots to add or manage item sets
 * There's also a shared item set list, which allows you to share entire sets of items between your builds

Other changes:
 * Added support for Animate Weapon and Animate Guardian
    * These skills utilise the new item set system; to equip items on Animated minions, create a new item set and
	  equip the items, then select the item set in the dropdown in the sidebar
 * You can now zoom the passive tree with Page Up/Down in addition to the scroll wheel and Ctrl+Left/Right Click
 * Various minor tweaks and fixes

### 1.4.36 - 2017/06/22
 * The Consuming Dark is now properly supported; previously, both Chaos and Physical would Poison

For 3.0 builds:
 * Updated item affixes; this will correct various oddities, such as missing affix names or incorrect values

### 1.4.35 - 2017/06/21
 * Added skill parts to Reave and Vaal Reave for selecting the stage count

For 3.0 builds:
 * Updated many uniques with changes from the 3.0 beta
 * The split Net Regen calculation for Mind over Matter now only occurs when Life Regen is the dominant regen source
    * This should fix the interaction between MoM and LL RF

### 1.4.34 - 2017/06/19
 * Bleed and Ignite DPS are now shown in the Minion section of the sidebar
 * The Mana Regen and ES Recharge calculations now correctly handle Recovery modifiers

For 3.0 builds:
 * The damage of Minion Ailments have been corrected; previously they were using the same damage ratios as players,
   when in fact they now deal 50% less Poison and Ignite damage, and 86% less Bleeding against stationary targets
    * Note that the player damage ratios were increased in 3.0, so this restores minions to their previous damage

### 1.4.33 - 2017/06/18
For 3.0 builds:
 * Updated the wording of various passives
   * Many conditional modifiers on passives will now apply to Ailments
 * Frostbolt and Ice Nova now have a "Cast on Frostbolt?" option in the Configuration tab to enable the 40% more Damage
 * Updated poison and bleed damage ratios to 20% and 70% respectively
 * The Bleed, Poison and Ignite sections of the Calcs tab now include breakdowns of the source damage for those ailments
 * The breakdowns for Bleed, Poison and Ignite DPS have had some minor improvements in wording
 * Damage Multiplier for Ailments from Critical Strikes is now displayed in the Crits section of the Calcs tab
    * It should also now be calculated correctly
 * All sources of added base damage should now apply to Ailments if they can also apply to the hit

### 1.4.32 - 2017/06/17
 * Fixed error caused by Punishment

For 3.0 builds:
 * The "# of Poison on Enemy" option in the Configuration tab now works for Vile Toxins

### 1.4.31 - 2017/06/16
 * The Buff/Debuff Skill lists in the Calcs tab now have breakdowns that list all the modifiers granted by those skills
 * Added an option to the Configuration tab for "Are you always on full Energy Shield?"
 * Fixed issue causing gems with a low maximum level to sometimes be assigned the wrong default level
 * Fixed issue causing the slot dropdown in the Skills tab to fail to update correctly under some conditions

For 3.0 builds:
 * The new support gems have been updated with the new data from the beta patch
 * Applied the following changes from the beta patch:
    * Blade Vortex's per-blade damage multiplier now applies to Ailments
    * Flameblast's per-stage damage multiplier no longer applies to Decay
	* Incinerate's per-stage damage multiplier no longer applies to Decay
	* Blade Flurry's per-stage damage multiplier no longer applies to Decay
 * Minion's Decay DPS is now shown in the sidebar
 * Immolate and Hypothermia's conditional modifiers now apply to Ailments
 * Unbound Ailments's modifier to Effect of Ailments should now function correctly
 * Fixed issue causing the "increased Physical Damage taken" stat from Maim Support to sometimes apply multiple times

### 1.4.30 - 2017/06/16
 * Mind over Matter is now displayed in the Damage Taken section of the Calcs tab, instead of Other Defences

For 3.0 builds:
 * Mind over Matter is now factored into the Net Regen calculation; Net Life Regen and Net Mana Regen are calculated
   and displayed separately
 
### 1.4.29 - 2017/06/15
 * Fixed an error that occasionally appeared when editing gems in the Skills tab

For 3.0 builds:
 * Damage multipliers for skill parts (e.g Flameblast stages) should now correctly apply to Decay

### 1.4.28 - 2017/06/14
For 3.0 builds:
 * Deadly Ailments' Ailment Damage modifier should now correctly apply to Ignite
 * Fixed error caused by setting quality on Unbound Ailments

### 1.4.27 - 2017/06/14
 * Added support for the additional totem modifier on Skirmish

For 3.0 builds:
 * Added preliminary support for the 11 new support gems
    * Note that these gems are still using pre-release data, so some stats may change once the beta patch is available

### 1.4.26 - 2017/06/12
 * Added Bramble Cobra to the spectre library
 * Added support for the Chaos degen from Forbidden Taste

For 3.0 builds:
 * Damage multipliers for skill parts (e.g Flameblast stages) should now correctly apply to Damaging Ailments
 * Added damage from buffs (e.g Heralds, Anger) should now correctly apply to Damaging Ailments
 * Fixed the multiplier on Remote Mine

### 1.4.25 - 2017/06/11
 * Added options to the Options dialog to show thousands separators in the sidebar or Calcs tab
 * Fixed error that could result from importing a character into a 3.0 build
 * A warning is now shown before importing a character into a 3.0 build
 
### 1.4.24 - 2017/06/09
 * Converting builds between game versions will now automatically update the names of gems that been renamed

For 3.0 builds:
 * Updated the base damage for Zombies, Raging Spirits and Skeleton Warriors
 * The duration penalty from Rapid Decay should now apply correctly

### 1.4.23 - 2017/06/09
 * Fixed issue causing some of the item type filters in the unique and rare databases to disable the other filters

For 3.0 builds:
 * Modifiers to Area Damage should now apply to all instances of Area Damage over Time (Righteous Fire, Vortex, etc)
 * Modifiers to Skill Effect Duration will now apply to Puncture's Bleed and Viper Strike's Poison
 * The Decay calculation has been updated to account for the Damage over Time changes
 * Elemental Damage with Attacks now correctly affects Ignite
 
### 1.4.22 - 2017/06/09
 * Fixed bug causing certain skill stats to be ignored; this notably affected Blade Vortex and Wither

For 3.0 builds:
 * Applied the Damage over Time changes
    * The new DoT code hasn't been tested as thoroughly as it needs to be, so it may have mistakes
 * Updated the bandit rewards
 * Reverted some unintended changes to minion's skills made in 1.4.21

### 1.4.21 - 2017/06/08
For 3.0 builds:
 * Updated skills (except for skills used by minions and spectres)
 * Updated item bases
 * Updated item modifiers (affixes, corrupted, master)
 * Vaal Pact should now work correctly

### 1.4.20 - 2017/06/08
 * You can now create builds for the 3.0 beta:
    * You can choose the game version when creating a Build
	* You can convert a build between versions using the new "Game Version" option in the Configuration tab
	* All existing builds default to 2.6

For 3.0 builds:
 * The passive tree has been updated
 * Other changes (such as the Damage over Time overhaul) are still to come

### 1.4.19 - 2017/06/07
 * The build list now has support for folders
 * Importing from a build code no longer requires you to name the build before importing
 * Fixed an error that could appear while using the item text editor

### 1.4.18 - 2017/06/03
 * The "Craft item..." feature has been significantly enhanced:
    * Modifiers are now available for all item types, not just Flasks and Jewels
	* The affix lists now obey all restrictions that prevent certain modifiers from appearing together
	   * For example, selecting "inc. Attack Speed with Bows" on a jewel will exclude "inc. Physical Damage with Axes"
 * You can now add custom modifiers to Magic and Rare items using the new "Add modifier.." button
    * For applicable item types you can choose from Master and Essence modifiers, in addition to writing your own modifier
	* All master mods have been removed from the rare templates, since they can easily be added using the new option
 * Additional type filters have been added to the Unique and Rare databases
 * Added a "# of Poison on Enemy" option to the Configuration tab for Growing Agony
 * The Poison section in the Calcs tab now displays Max Poison Stacks
 * Added Merveil's Blessed to the spectre library
 * Orb of Storms no longer incorrectly benefits from modifiers to area damage
 * Various minor tweaks and fixes
 
### 1.4.17 - 2017/05/29
 * Added base radius for Zombie's slam
 * Minions (including Spectres) will now show the correct attack range for their melee skills
 * Fixed an error that would appear when equipping Blood of Corruption
 * Corrected the radius for Infernal Blow

### 1.4.16 - 2017/05/27
 * Items can now be corrupted via the new "Corrupt..." button that appears when viewing the item
 * Explosive Arrow's additional radius per fuse is now factored into the area calculation
 * Fixed an error that would sometimes appear when editing gems in the Skills tab

### 1.4.15 - 2017/05/26
This update adds support for level and attribute requirements:
 * Item tooltips now show level and attribute requirements
    * Level requirements shown for items imported from in-game may be lower than in-game; this cannot be avoided
	* Some previously-imported items may display a more accurate level requirement if they are re-imported
 * The gem selectors in the Skills tab now have tooltips that show level and attribute requirements, plus some other details
 * The sidebar now shows your attribute requirements if they aren't met
 * The Attributes section of the Calcs tab now shows attribute requirements, with detailed breakdowns

Other changes:
 * Witchfire Brew's Vulnerability aura now interacts correctly with Umbilicus Immortalis

### 1.4.14 - 2017/05/24
 * Added an option to the Configuration tab for "Have you been Crit Recently?"
 * Fixed some issues with item templates and the All items/Shared items lists

### 1.4.13 - 2017/05/20
 * Detonate Dead now has an input in the Configuration tab for "Corpse Life"
 * Added support for Hungry Abyss

### 1.4.12 - 2017/05/19
 * The Items tab now has a "Shared items" list which is shared between all of your builds
 * Added an Options screen, accessed via a new button at the bottom left corner. The following options have been added:
    * Proxy server: specifies the proxy that the program should use when updating or importing characters
	* Build save path: overrides the default save location for builds
	* Node Power colours: changes the colour scheme used for the node power display
 * The breakdowns for hit damage types now show the percentage of total hit damage that is being dealt as that type
 * The stat differences shown in passive skill tooltips can now be toggled on and off by pressing Ctrl+D
 * Some friendly toasts have set up camp in the bottom left corner, and may appear occasionally to convey various messages
 * With the new installer versions, the program will always update itself when started for the first time, but will still
   start even if the update check fails

### 1.4.11 - 2017/05/16
 * Fixed a stack overflow error that could occur when trying to view breakdowns in the Calcs tab
 * Fixed interaction between weapon swap and skills granted by items
 * Consolidated the program's various list controls; their appearence and behaviour should be largely unchanged,
   aside from some minor enhancements
 * Various minor tweaks and fixes

### 1.4.10 - 2017/05/12
 * Added support for weapon swap:
    * You can switch between the two weapon sets using the new buttons above the Weapon 1 slot on the Items tab
	* Skills in the inactive weapon set are automatically disabled
	* Switching weapon sets will automatically update the main skill selection if the current main skill is socketed in the
	  set being deactivated and there is a skill socketed in the set being activated
	* Importing character items will now import both weapon sets
 * Added support for "X% chance to deal Double Damage" modifiers
 * The comparison tooltip for passive trees now displays the number of refund points needed to switch to that tree
 * Added an option to the Configuration tab for "# of Freeze/Shock/Ignite on Enemy" (for The Taming)
 * Fixed several anomalies in the handling of duplicate support gems

Also, for those interested in supporting the development of the program I now have a Patreon page.
You can find the link in the About window.

### 1.4.9 - 2017/05/08
 * AoE Radius and Weapon Range are now calculated and displayed in the "Skill type-specific Stats" section of the Calcs tab
    * The breakdowns for those calculations feature a visual display of the area size
	* The base radius values of some skills are not known, so they will not be shown
 * Explosive Arrow now has separate skill parts for 1 fuse and 5 fuses
 * Added support for Convocation
 * Rallying Cry's buff is now able to affect minions
 * The character limit for build names has been increased to 100; the build list has also been widened
 * Spells of the correct type will now be considered to be Triggered when socketed into Mjolner and Cospri's Malice
 * Infernal Blow no longer incorrectly benefits from modifiers to area damage

### 1.4.8 - 2017/05/02
 * Added a Physical Damage Reduction estimate for Armour; by default the estimate is made using the same damage value
   used in-game on the character sheet, but it can be overriden using a new option in the Configuration tab
 * Added a new "Damage Taken" section to the Calcs tab that shows the incoming damage multipliers for each damage type
    * These factor in mitigation (resistances/armour) and modifiers to damage taken
	* The multipliers for hits and DoTs are calculated and shown separately
	* The multiplier for Physical hit damage includes the Physical Damage Reduction estimate mentioned above
 * Added self-degen calculations for Righteous Fire and Blood Rage:
    * The sidebar will display "Total Degen" and "Net Regen" (Total Regen minus Total Degen)
    * Detailed breakdowns for these calculations can be found in the new Damage Taken section of the Calcs tab
 * Added combined avoidance chances for Melee/Projectile/Spell to the Other Defences section of the Calcs tab which
   factor in evasion, block, and dodge
 * Added support for Arrow Dancing
 * The "increase maximum Life if no worn Items are Corrupted" stat on Voll's Vision should now apply correctly
 * Corrected the range of the life modifier on The Perfect Form
 * Corrected The Alyardex's variants
 * Fixed issue that prevented the program's title bar from appearing at low screen resolutions
 
### 1.4.7 - 2017/04/20
 * A new section has been added to the Configuration tab for Map Modifiers and Player Debuffs
    * This section contains options for simulating many map modifiers, as well as self-curses
 * Added support for Self-Flagellation
 * Corrected the range of the increased Physical Damage modifier on Edge of Madness

### 1.4.6 - 2017/04/20
 * Fixed bug introduced in 1.4.5 that prevented Onslaught and Unholy Might from applying correctly
 * The minion modifiers on the jewel templates are now correctly hidden when their value is set to 0

### 1.4.5 - 2017/04/19
 * Added support for Goatman Fire-raiser's Magma Orb skill
 * Demigod items and legacy (pre-1.2.0) quiver types can now be imported
 * Fixed issue causing the enchanting UI to only show enchantments for the first skill in each socket group
 * Fixed issue preventing the life/mana leech boot enchantment from working

### 1.4.4 - 2017/04/17
This update fixes two issues affecting the damage calculations for minions.
As a result, the calculated DPS for many minion skills will change to some degree:
 * All golem skills will gain up to 25% DPS
 * Other minion's attacks will generally lose up to 30% DPS, but some may gain DPS
 * Other minion's spells are generally unaffected, but some will gain up to 10% DPS
 * Zombies, Skeleton Warriors and Raging Spirits are not affected

Other changes:
 * Improved the DPS calculation for Blade Vortex skills used by spectres:
	* The blade count can be set using a new option for Raise Spectre in the Configuration tab
    * The skills now have a hit rate override, which allows the DPS to be calculated properly
 * Added support for the Raise Spiders skill granted by Arakaali's Fang
 * Added support for the Spectral Spirits skill granted by Essence of Insanity
 * Added the attack rate cap for Blink/Mirror Arrow clones

### 1.4.3 - 2017/04/16
 * Added Fighting Bull, Kraityn's Sniper, Shadow Lurker and Kaom's Chosen to the spectre library
 * Added options to the Configuration tab to enable charges for all minions
 * Corrected the minion damage modifier on the Cobalt Jewel template, and added the minion life modifier
 * Fixed issue causing minions to trigger Elemental Equilibrium
 
### 1.4.2 - 2017/04/16
 * Added support for Beacon of Corruption's Caustic Cloud (adds an extra 'Caustic Cloud' skill to your minions)
 * Added Goatman Fire-raiser, Towering Figment, Noisome Ophidian and Pocked Lanternbearer/Illuminator to the spectre library
 * Fixed the flat mana modifier on Grand Spectrum

### 1.4.1 - 2017/04/16
 * Added Slashed Miscreation, Spectral Scoundrel and Cannibal Fire-eater to the spectre library
    * The DPS for monster versions of Blade Vortex won't be accurate yet
 * Added support for the modifier on The Anima Stone that grants an additional golem with 3 Primordial jewels
 * The Zombie's Slam skill should now count as a melee skill
 * Minion and Totem Elemental Resistances Support now correctly applies resistances to minions
 * Fixed the minion damage conversion from The Scourge
 * Fixed the golem damage modifier on Primordial Harmony
 * Fixed the Zombie Slam modifiers on Violent Dead

### 1.4.0 - 2017/04/15
This update adds support for Minions:
 * Added support for the following skills:
    * Blink Arrow
	* Mirror Arrow
	* Raise Spectre:
	   * A library of commonly used spectres has been added; with Raise Spectre selected as the main skill,
	     you can click "Manage Spectres..." to browse it and add spectres to your build
	   * The level of the spectre can be set via a new option in the Configuration tab
	   * Spectre curses are disabled by default, and can be enabled in the Configuration tab
	* Raise Zombie
	* Summon Raging Spirit
	* Summon Skeletons
	* Vaal Summon Skeletons (except generals)
	* Summon Spectal Wolf (from The Scourge)
 * Added minion support for:
	* Summon Chaos Golem
	* Summon Flame Golem
	* Summon Ice Golem
	* Summon Lightning Golem (the Wrath aura can be enabled via a new option in the Configuration tab)
	* Summon Stone Golem
 * Added support for:
    * Minion Instability (adds an extra 'Minion Instability' skill to your minions)
	* Necromantic Aegis
    * Most minion-related helmet enchantments

Other changes:
 * A new section has been added to the Configuration tab for skill-specific options
    * The section will only appear if at least one of your skills have options
    * The only options added so far are those mentioned above, but more will be added later
 * Skill cooldowns are now calculated and displayed
 * Corrected or updated the wording of modifiers on several uniques
 * Fixed several "NaN" values that could appear for mana-related stats when Blood Magic is allocated

### 1.3.26 - 2017/04/08
 * Modifiers to Area of Effect of Aura Skills now correctly apply to curses supported by Blasphemy
 * Corrected the implicits on Maraketh One-Handed Swords (thanks sherardy)

### 1.3.25 - 2017/04/06
 * You can now export and import builds directly to/from Pastebin.com links
 * Added support for the "Claw X also apply to Unarmed" modifiers on Rigwald's Curse
 * The conditional penetration modifier on imported copies of The Wise Oak should now be recognised correctly

### 1.3.24 - 2017/04/05
This update adds support for Life/Mana Leech and Life/Mana/ES Gain on Hit:
 * All sources of Leech and Gain on Hit are supported, including "Damage dealt by your Totems is Leeched to you"
 * For skills with a known hit rate (i.e skills that show DPS instead of Average Damage), the combined rate of recovery
   from Leech and Gain on Hit is displayed in the sidebar
 * For other skills, the total amount leeched/gained from one hit is displayed instead
 * Detailed breakdowns of Leech and Gain on Hit can be found in the new "Leech & Gain on Hit" section in the Calcs tab

 Other changes:
 * Added support for the additional Siege Ballista totems modifier on Iron Commander
 * The "%Inc Armour from Tree" and "%Inc Evasion from Tree" sidebar stats now include "increased Evasion Rating and Armour"
 * Various minor tweaks and fixes

### 1.3.23 - 2017/03/31
 * Helmets and Boots can now be enchanted via the new "Apply Enchantment..." button that appears when viewing the item
 * Added support for more helmet enchants; the vast majority of them should now work
 * Added support for the conditional penetration stat on The Wise Oak
 * Corrected the base of Lycosidae
 * The quality bonus on Blood Rage now applies correctly
 
### 1.3.22 - 2017/03/28
 * The sidebar can now displays two Crit Chance values:
    1. Crit Chance:
	   * This is the skill's "real" crit chance, as displayed in the in-game character sheet
	   * If your crit chance is capped, this value will always be 95%, unlike your effective crit chance (which can be lower)
	2. Effective Crit Chance:
	   * This is the value previously shown as "Crit Chance"
	   * This estimates your true crit chance, factoring in accuracy and "Crit Chance is Lucky"
 * Added an option to the Configuration tab for "Are you Leeching?" 
 * Essence Drain now uses "Average Damage" mode
 * Phasing is now enabled automatically if you have Quartz Infusion and maximum frenzy charges
 * The Red/Green/Blue Nightmare jewels now correctly apply to the conditional resistance stats in the Sanctuary cluster
 * Corrected the crit chance modifier on Pre-2.0.0 Windripper
 * Updated "The Oak" to mirror the changes to Springleaf in 2.6
 * The program should now correctly prompt to save the current build before updating
 
### 1.3.21 - 2017/03/20
With this update, the handling of buffs and debuffs has been improved:
 * Having multiple copies of the same flask or buff/debuff skill active is now handled correctly
   * When multiple copies are present, the highest value of each stat is used
 * The enemy curse limit is now calculated and respected; when the limit is exceeded:
   * Blasphemy curses take priority over other curses
   * The Vulnerability aura from Witchfire Brew takes priority over non-Blasphemy curses
   * Otherwise, curses are prioritised according to their ordering in the Skills tab

Other changes:
 * Punishment is now supported (this was mostly made possible by the buff overhaul)
 * Generosity is now supported
 * Block Chance Reduction is now supported (although it has no effect)
 * Several uniques have received minor corrections to the wording of stats

### 1.3.20 - 2017/03/17
 * Added skill parts to Vaal Fireball that match those on Fireball
 * Reverted the rounding change from the previous update, as the change in the game has been reverted also
 * Fixed issue that caused passive node stats to lose tags (such as conditions) when converted by certain jewels
 * Corrected the implicits on many item bases that received undocumented buffs in 2.6
 * Various minor tweaks and fixes

### 1.3.19 - 2017/03/09
 * Changed the rounding method for flask/aura/buff/curse effect to reflect the change in 2.6
 * Relics can now be imported, and copied from in-game
 * Fixed behaviour of the "Both slashes" skill part of Lacerate when only using one weapon
 * Corrected the implicits of Maraketh sceptres
 * Various minor tweaks and fixes

### 1.3.18 - 2017/03/05
 * Added support for threshold jewels:
    * Most of the relevant modifiers from threshold jewels should now be supported
	* The tooltips for jewel sockets now indicate which types of threshold jewels will work there
 * Added and updated many new uniques (shoutout to chuanhsing for the list on PoEDB)
 * Applied the remaining balance changes to unique items (including threshold jewels)
 * Updated all item bases (thanks Patrick for doing most of the work)
    * Claw and Sword uniques and templates have been updated to account for the new implicits
 * Corrected the conversion on Wild Strike

### 1.3.17 - 2017/03/04
 * Updated skill data to 2.6
 * Minor update of the passive tree data; this fixes the Storm Weaver pathing
 * Added many new uniques

### 1.3.16 - 2017/03/03
 * Added a skill part to Lacerate to simulate the target being hit by both slashes
 * Added support for the "Damage while you have no Frenzy Charges" modifier on Daresso's Passion
 * Updated the conversion values of Wild Strike, Ice Shot and Frost Blades (thanks viromancer)

### 1.3.15 - 2017/03/02
 * The skill gem search field can now search by gem tag (e.g 'support' or 'aura')
 * Removed the bonus Energy Shield from Vaal Discipline
 * Node location displays in the Items and Calcs tabs will now render correctly
 * Fixed error that resulted from entering certain characters into search fields

### 1.3.14 - 2017/03/02
This update implements the AoE changes for 2.6:
 * Changed the Area Radius Modifier output in the Calcs tab to Area of Effect Modifier
 * Updated the stats for Increased Area of Effect, Concentrated Effect and Melee Splash
 * Changed Area Radius modifiers on uniques to Area of Effect
 * Changed the Area of Effect value on Illuminated Devotion to match that listed in the patch notes
 * The area of effect of many skills will be incorrect until all the data is made available in the patch

Other changes:
 * Added support for the "Arrows that Pierce cause Bleeding" stat on Slivertongue
 * Added support for the increased Golem Buff Effect stat on Primordial Eminence
 * Corrected the implicits added when crafting Wands and Sceptres
 * The (possibly incorrect) pathing in the Storm Weaver cluster should now render correctly
 * Fixed an error that would occur when loading certain builds

### 1.3.13 - 2017/03/02
 * Updated tree to 2.6.0

### 1.3.12 - 2017/03/02
This update brings some of the changes for 2.6; other changes are awaiting updated data.
 * Almost all balance changes to unique items have been applied
 * Implicits for most weapon types have been updated
 * Added the four new uniques announced thus far
 * A new Unset Ring template has been added, with the new + to Level of Socketed Gems modifier
 * The +2 Chaos Staff template is now +3

Other changes:
 * The "Blocked Recently" option has been replaced with separate options for "Blocked an Attack" and "Blocked a Spell"
 * Caustic Arrow's hits no longer incorrectly benefit from Area Damage
 * Ancestral Protector and Ancestral Warchief now correctly use the main hand only

### 1.3.11 - 2017/02/26
 * When importing a character you can now choose to delete existing data (jewels, skills, equipment) before importing
 * Wither now shows the secondary duration (%increased Chaos Damage Taken) instead of the primary duration (Hinder)
 * Local increased Accuracy modifiers on weapons are now correctly multiplicative with global increased Accuracy
 
### 1.3.10 - 2017/02/23
 * Added support for the helmet enchants that grant increased Buff Effect from Golems 
 * Added an option to the Configuration tab for "Is the enemy Rare or Unique?"
 * Skills that cause Bleeding now have an option in the Configuration tab for "Is the enemy Moving?"
 * Two-Toned Boots should now be handled correctly; all 3 variants should import correctly, and are available to craft

### 1.3.9 - 2017/02/23
 * Projectile skills now have an option in the Configuration tab for "Projectile travel distance"
    * Point Blank, and the scaling Pierce chance from Powerful Precision, are now supported
	* Far Shot is not supported yet, as the scaling is unknown
	* Freezing Pulse's damage and freeze chance can now scale with distance (factoring in projectile speed)

### 1.3.8 - 2017/02/22
 * Flicker Strike now shows DPS instead of Average Damage
 * Added an extra option for Elemental Equilibrium to ignore the hit damage of your main skill
 * Added options to the Configuration tab for "Taunted an Enemy Recently" and "Enemy is Taunted"

### 1.3.7 - 2017/02/22
 * The "enemy is a Boss" option in the Configuration tab now has 2 modes: Standard Boss, and Shaper/Guardian
   * Standard Boss is equivelant to the old boss setting (30/30/30/15 resists, -60% curse effect)
   * Shaper/Guardian applies: 40/40/40/25 resists, -80% curse effect, 50% less Bleed/Poison/Ignite Duration
 * Witchfire Brew's Vulnerability aura now correctly accounts for less curse effect on bosses, and now counts for Malediction

### 1.3.6 - 2017/02/21
 * Added a skill part for Barrage that calculates the DPS from all projectiles hitting the target
 * The breakdown for Crit Chance in the Calcs tab now shows how far overcapped your crit chance is
 * Empower/Enhance/Enlighten now default to level 3; Portal/Detonate Mines default to level 1
 * Fixed issue that caused some existing items to lose quality; all affected items will be fixed automatically

### 1.3.5 - 2017/02/21
 * Added support for the extra Chaos Damage from Malediction
    * The bonus only applies with "Have you killed Recently?" enabled, and scales based on the number of active curse skills
 * Added options to the Configuration tab for: 
    * Are you always on Full Energy Shield?
	* Do you have a Totem summoned?
	* Have you been hit by Fire/Cold/Lightning Recently? (for Paragon of Calamity)
	* Have you used a Warcry Recently?
	* Consumed a corpse Recently?
 * Added support for the "Consecrated Ground grants 40% increased Damage" modifier from Sanctify
 * The total Damage taken from Mana before Life is now displayed in the Other Defences section in the Calcs tab
 * The Items tab now only normalises quality on items when they are first added, allowing the quality to be edited if necessary

### 1.3.4 - 2017/02/20
 * Added support for the Offering skills and Mistress of Sacrifice

### 1.3.3 - 2017/02/19
 * Added support for Intuitive Leap
 * Added support for the Decay effect granted by Essence of Delirium
 * Added support for the Fire Burst skill granted by Essence of Hysteria

### 1.3.2 - 2017/02/18
 * Added support for the "increased Effect of Buffs on You" modifier on Ichimonji
 * Added basic support for Detonate Dead; only the base damage is used
 * The points display in the top bar will now move to the right of center if the Save/Save As buttons would cover it
 * Fixed issue preventing Unarmed from being correctly detected

### 1.3.1 - 2017/02/18
 * Added socket count to the tooltips in the passive tree selection dropdown menu
 * Added percentage values to the per-point stat differences for passive nodes
 * Flameblast's 10 Stages skill part now uses a x0.1 DPS multiplier instead of a 90% less Cast Speed modifier
    * The cast rate will now reflect the time taken to build each stage, rather than the total time to build 10 stages
	* This change will prevent an issue where adding increased cast speed would have no effect under some conditions
 * Skills that only use the main-hand when dual wielding will now be handled correctly

### 1.3.0 - 2017/02/16
This update adds support for Flasks:
 * Flask slots have been added to the Items tab. Checkboxes next to each slot allow the flasks to be individually activated.
 * All flask-related modifiers are now supported
 * Flask modifiers have been added to the belt templates; this will not affect items previously created from templates
 * All unique flasks have been added to the Uniques database
 * There will not be templates for flasks; custom flasks can be created using the new crafting system

Additionally, a new item crafting system has been added:
 * You can access it by clicking "Craft item..." in the Items tab
 * You can choose the rarity and base type of the item from lists
 * For flasks and jewels, you can choose the item's affixes from lists once you've created the item
 * For other items, modifiers must be added manually for now, so you may continue to use templates for them

Other changes:
 * You can now have multiple passive trees within one build!
    * To add more trees, select "Manage trees..." from the new dropdown at the bottom left corner of the Tree tab
    * Different trees may have different jewels socketed in them
	* Hovering over a passive tree in the dropdown will show you the stat differences from switching to that tree
 * Hovering over gem names in the gem dropdown now shows the stat differences from selecting that gem
 * Hovering over the gem enable checkbox now shows the stat differences from enabling/disabling that gem
 * Passive node stat differences now show the value per point when showing the difference from multiple passives
 * Fixed issue preventing Elemental Equilibrium from functioning correctly with skills that don't hit

### 1.2.41 - 2017/02/13
 * The program now shows the save prompt before updating if there are unsaved changes
 * Added options to the Configuration tab for: Enemy Blinded, Dealt Non-Crit Recently, Ignited/Frozen an Enemy Recently
 * Stat differences for allocating/deallocating passives will no longer be incorrect when certain radius jewels are used

### 1.2.40 - 2017/02/11
 * Movement Speed is now calculated and displayed in the sidebar and Calcs tab (in Other Defences)
 * Fixed display issue in the breakdown for ignite DPS
 * Fixed issue preventing some condition toggles from showing when related passive nodes are allocated

### 1.2.39 - 2017/02/08
This update adds full support for Dual Wielding:
 * DPS calculations for dual wield skills will now use both weapons if they are usable with the skill
 * Calculations for bleed, poison and ignite will correctly factor in both weapons
 * Dual Strike is now supported

Other changes:
 * Importing the passive tree from PoEPlanner links will now work with links created by the latest version of the site
 * Fixed error when showing the tooltip for Kondo's Pride
 * Various minor tweaks and fixes

### 1.2.38 - 2017/02/05
 * Fixed error when hovering over a passive node with a main skill that isn't compatible with the equipped weapons

### 1.2.37 - 2017/02/05
 * Attack skills will now only work if your equipped weapons can be used with that skill
 * Dual Wield attack skills will now use the off hand weapon if the main hand isn't compatible with the skill
    * If both weapons are compatible the calculations will still only use the main hand; full dual wield support is coming soon
 * Added skill parts to Blast Rain to allow calculation of DPS against a target that's being hit by all 4 explosions
 * Added a "Have you Blocked Recently?" option to the Configuration tab
 * Added the block chance buff for Tempest Shield

### 1.2.36 - 2017/01/31
 * Condition toggles in the Configuration tab will now only appear if the condition is actually used by the build
 * Added support for "Ignited Enemies Burn faster" modifiers
 * Added options to the Configuration tab for "Are you on Shocked/Burning/Chilled Ground"
 * Character imports will now work even if the capitalisation of the account name is incorrect

### 1.2.35 - 2017/01/29
With this update, the way the program handles the calculation of crit damage has been improved.
Damage for crits and non-crits are now calculated and tallied separately, and combined later, instead of only
calculating non-crit damage, and deriving crit damage from that. This has allowed for the following changes:
 * Inevitable Judgement is now supported!
 * Other modifiers that only apply to crit or non-crit damage are now supported:
    * Choir of the Storm's increased lightning damage modifier
	* Marylene's Fallacy's less damage on non-critical strikes

Additionally, the handling of secondary effects (bleed, poison, ignite, shock, and freeze) has been improved.
The calculations for base damage and overall chance to inflict can now handle having different chances to inflict on
crits and non-crits. This has allowed for the following changes:
 * Ignite/shock/freeze calculations now account for the guaranteed chance to inflict on critical strike
    * This will greatly improve the accuracy of ignite DPS calculations for crit-based builds when in "Average Damage" mode,
	  as ignite's base damage will be heavily skewed in favour of crit
 * Modifiers that grant a chance to poison/bleed on crit are now supported and correctly simulated
    * The existing support for Adder's Touch has been reworked to use the new system
 * The base damage for shock and freeze is now calculated, and used to compute the maximum enemy life against
   which those effects will be able to apply; the results appear in the breakdowns for Shock/Freeze Dur. Mod

### 1.2.34 - 2017/01/27
 * IIQ/IIR totals are now shown in the "Other Effects" section in the Calcs tab
 * Enabling the "on Consecrated Ground" option now applies the 4% life regen granted by that ground effect

### 1.2.33 - 2017/01/21
 * The aura effects granted by Unwavering Faith and Commander of Darkness now correctly benefit from aura effect modifiers
 * The calculation of crit chance now factors in accuracy when in Effective DPS mode

### 1.2.32 - 2017/01/15
 * The program now calculates Total Damage per Ignite and Total DPS inc. Ignite when you have Emberwake equipped
 * Added a "Have you been Savage Hit Recently?" option to the Configuration tab
 * The calculation of Total DPS inc. Poison now factors in hit chance
 * Fixed the bonus crit chance for Ice Spear's second form
 * Vaal skills now correctly benefit from Vaal skill modifiers
 * The breakdown for poison duration now correctly displays the poison duration modifier instead of the skill modifier

### 1.2.31 - 2017/01/08
 * Added two new templates for sceptre attack builds
 * Corrected the implicits on the wand and sceptre templates
 * Fixed the rounding on life/mana reservation calculations
 * Fixed the "additional Block Chance with Staves" modifier

### 1.2.30 - 2016/12/30
 * Added options to the Configuration tab for "Are you Ignited/Frozen/Shocked"
 * Discharge's damage penalty when triggered will now apply correctly
 * Skin of the Loyal and Skin of the Lords' Energy Shield values are now correctly removed
 
### 1.2.29 - 2016/12/26
 * Added an "Enemy is Hindered" option to the Configuration tab
 * Added a "Crit Chance is Lucky" option to the Configuration tab

### 1.2.28 - 2016/12/22
 * Added skill parts to Blade Vortex to enable calculation of DPS with different blade counts
    * Blade Vortex now has a hit rate override which replaces the cast rate when calculating the skill's DPS
	* This will allow you to see the skill's true DPS at a given blade count
 * The calculation of Ignite base damage can now be controlled using a new option in the Configuration tab

### 1.2.27 - 2016/12/21
 * Cast when Channelling now overrides the cast rate of the triggered skill, allowing the DPS of that skill 
   to be calculated correctly
 * Added an option to the Configuration tab to enable the Intimidate debuff on the enemy
 * Jewel tooltips on the passive tree can now be hidden by holding Shift
 * Corrected a display issue in the breakdown for Bleed that showed the wrong percentage of base damage
 * Energised Armour now correctly converts the ES-from-Shield node in the Mind Barrier cluster
 * Many skill-specific modifiers (such as helmet enchants) that weren't previously recognised should now be working
 * New installer versions are available, and are recommended if you need to install the program again
    * The new standalone install no longer forces an update check when run for the first time, and will never ask for
	  administrator privileges to update itself (as currently happens when certain files need to be updated)

### 1.2.26 - 2016/12/14
 * The sidebar now displays a DPS or Average Hit total that factors in Poison
 * Added support for the Bone Nova skill granted by Uul-Netol's Embrace
 * Added support for the Molten Burst skill granted by Ngamahu's Flame
 * Fixed the handling of mana costs for totem-cast auras
 * Corrected the no-crit-multiplier modifier on Kongor's Undying Rage

### 1.2.25 - 2016/12/13
 * Added support for the Abberath's Fury skill granted by Abberath's Hooves
 * Added support for the Lightning Bolt skill granted by Choir of the Storm and Voice of the Storm
 * Fixed a conflict between the Physical to Lightning support gem and certain skill conversions

### 1.2.24 - 2016/12/10
 * Added attributes to the jewel templates
 * You can now zoom the tree by Ctrl+Left/Right-Clicking, in addition to using the mousewheel
 * Added support for the Block/Dodge conversion modifiers on the 3 Nightmare jewels

### 1.2.23 - 2016/12/10
 * Added and updated more uniques from 2.5.0
 * Added a new skill part to Blade Flurry that approximates the DPS from releasing every time you hit 6 stages
 * Added support for the Cast on Melee Kill and Cast while Channelling support gems

### 1.2.22 - 2016/12/04
 * Added many more uniques from 2.5.0, and updated mods on others
 * Updated existing uniques that were changed in 2.5.0

### 1.2.21 - 2016/12/03
 * Updated the skill data to 2.5.0
 * Added the Elreon flat chaos mod to the ring and amulet templates
 * Added support for the "Auras you Cast" modifiers in Guardian and Necromancer
 * Passives/items that affect mana cost will now display the mana cost change in green if the cost is reduced,
   and red if the cost is increased (i.e the reverse of the behaviour for other stats)
 * Skills that cannot miss will now correctly have a 100% chance to hit
 * Fixed issue that could cause the stat comparisons in item and passive node tooltips to show incorrect values if 
   Elemental Equilibrium is used
 * The error messages displayed when a character import fails due to connection issues are now more readable
 * Fixed the program's saved window position becoming invalid if the program was closed while minimised

### 1.2.20 - 2016/12/02
 * Added 'The Pandemonius', 'Light of Lunaris', 'The Surrender' and 'Malachai's Vision'
 * Added support for the Minion and Totem Elemental Resistances gem
    * The new elemental damage multiplier has been added to this gem
 * Added support for the Spell Damage->Attack Damage modifier on Crown of Eyes
 * Imported items no longer have their quality normalised
 * Fixed Avatar of Fire not working after the passive tree update
 * Fixed bug preventing Cold Steel from applying both conversions
 * Corrected the ranges of the crit multipler modifiers on the jewel templates
 * Various minor tweaks and fixes

### 1.2.19 - 2016/11/30
 * Updated the passive tree to 2.5.0
 * Added 'The Halcyon'
 * Added an "enemy at Close Range" condition for Chin Sol
 * Corrected the projectile damage taken stat on Projectile Weakness
 * Fixed error that could result from loading certain builds saved prior to version 1.0.27

### 1.2.18 - 2016/11/29
 * Added 3 new Jewel templates
 * Added 'Tulfall'
 * Creating a new build now opens an unnamed build rather than asking for a build name
    * You will be prompted to name the build when saving
	* The program now opens a new build when run for the first time
 * Added support for Elemental Equilibrium; when this passive is allocated, new options will appear in the Configuration tab
   to allow you to indicate which damage types the enemy has been hit by before being hit by your main skill
    * The enemy's resistances will update after the skill's hit damage is calculated, so that any damage over time effects are
	  calculated correctly

### 1.2.17 - 2016/11/28
 * Added 'Tulborn' and 'Voice of the Storm'
 * Added support for Mastermind of Discord; when this passive is allocated, new options will appear in the Configuration tab
   to allow you to indicate which skill types you are using
 * Conversion modifiers are now listed in the breakdowns for hit damage in the Calcs tab
 * Added 2x multiplier to Cyclone's DPS to match the in-game tooltip
 * Fixed bug preventing the buff from Summon Lightning Golem from applying correctly

### 1.2.16 - 2016/11/25
 * The build list can now be sorted by name, class or time of last edit
 * The save prompt will now show when closing the program if there are unsaved changes
 * Fixed issue caused by right-clicking a jewel socket on the passive tree when there's no jewels in the build
 * Various minor tweaks and fixes

### 1.2.15 - 2016/11/25
 * Added all uniques so far announced for 2.5.0
    * Most of their special modifiers should be working; as usual anything in blue should work, anything in red won't
	* Note that for Shade of Solaris you must set the "Have you Crit Recently" condition in the Configuration tab
 * You can now edit an item's text to change the name, base type or modifiers:
    * Double-click on an item, then click "Edit..."
	* When in the item editor, hovering over the Save button will show the item's tooltip
	* You can also create items from scratch using this method, with the new "Create custom..." button
	* This feature is mainly a stopgap until a more usable item editor is implemented
 * When copying an item from the "All items" list, the modifier ranges are now preserved
    * This means you can copy items that have been created from templates without losing the modifiers
 * The rare templates have been updated, with some new bases and modifiers added
 * Added several conditions to the Configuration tab
 * Various minor tweaks and fixes

### 1.2.14 - 2016/11/23
 * Added a Notes tab

### 1.2.13 - 2016/11/22
 * The breakdown for crit chance now includes the "additional chance to receive a Critical Strike" from Assassin's Mark
 * Added support for the "increased extra damage from Critical Strikes" modifier on Assassin's Mark
 * Added support for Toxic Delivery
    * The extra chaos and bleed damage modifiers require their respective conditions to be enabled in the Configuration tab
 * Improved the program's startup time

### 1.2.12 - 2016/11/22
 * Hovering over the character level input will now show the experience penalties for relevant area levels
 * Fixed the "not Killed Recently" condition on "Rite of Ruin"

### 1.2.11 - 2016/11/22
 * Added support for the Minion Damage-related modifiers on The Scourge
 * Fixed error when hovering over Kongming's Stratagem

### 1.2.10 - 2016/11/21
 * Added support for Unholy Might; you can enable it in the Configuration tab in the Combat section
 * Added a Sort button to the "All items" list in the Items tab
 * Added support for the "increased Spell Damage per Block Chance" modifier on Cybil's Paw
 * Improved keyboard interaction throughout the program:
	* Enabled keyboard navigation for all lists
    * 'Enter' now accepts confirmation popups, and other popups such as "Save As"
	* Dropdown lists can be cycled with Up/Down as well as the mousewheel
 * Fixed Elreon's -mana cost modifier increasing the mana cost instead of decreasing it

### 1.2.9 - 2016/11/20
 * Blade Flurry now shows DPS instead of average damage
 * Fixed stat counts not showing for some radius jewels

### 1.2.8 - 2016/11/20
 * Fixed dodge not being capped at 75%
 * Fixed missing area damage flag on Ancestral Warchief
 * Various minor tweaks and fixes
 
### 1.2.7 - 2016/11/18
 * Added support for the 3 new skills: Blade Flurry, Blight and Scorching Ray
 * Added support for Wither
    * The debuff will apply automatically when the skill is enabled
	* Change the skill part while Wither is selected in the sidebar to choose the stack count
 * Added a "Save As" button
 * Various minor tweaks

### 1.2.6 - 2016/11/12
 * Added support for the "more Physical Damage" modifier on "Outmatch and Outlast"
 * Added a splash damage skill part to Fireball

### 1.2.5 - 2016/11/08
 * Fixed bug preventing Static Strike damage from being calculated correctly

### 1.2.4 - 2016/11/06
 * Fixed a few minor bugs

### 1.2.3 - 2016/11/04
 * Fixed an error in the Calcs tab

### 1.2.2 - 2016/11/04
 * Fixed interaction between Lioneye's Fall and Serpent Stance
 * Added support for the Cast on Critical Strike gem (just the gem, no special calculations for CoC yet)

### 1.2.1 - 2016/11/03
 * Fixed error caused by Lioneye's Fall

### 1.2.0 - 2016/11/02
With this update, the program's internal modifier system has been completely overhauled.
On its own this overhaul doesn't change much from the user's perspective, but it has opened the way for some
significant upgrades:
 * The Calcs tab has been rebuilt from the ground up to take advantage of the new modifier system:
    * The various stats and totals are now more clearly divided into sections
	* The individual sections can be minimized to their title bar, so you can hide sections you're not interested in
	* Nearly all of the stats and totals in the new Calcs tab have a breakdown view that appears when you hover over them:
	   * You can click on a stat to pin the breakdown open so you can interact with it
	   * Each breakdown view shows all the information used to calculate that stat, including all modifiers
	   * You can hover over a modifier's source name to show the item's tooltip or passive node's location
	   * Hovering over a modifier source type ('Item', 'Tree', 'Gem' etc) will show the totals from that source type
	* Most modifier totals are no longer displayed in the tab itself, since they can be found in the breakdown views. 
	  The most important ones (such as increased life from tree) are still present, however.
 * Per-stat modifiers are now supported, including, but not limited to, the modifiers from:
    * Shaper's Touch
	* Pillar of the Caged God
	* Dreamfeather
 * Icestorm is now supported! When you have The Whispering Ice equipped, a special socket group will appear
   containing the Icestorm skill. You can select it in the Main Skill dropdown, or view it in the Skills tab.
   You cannot add support gems to this group, but supports from any other group socketed in the staff will
   automatically apply to the Icestorm skill.
 * All other skills granted by items are now supported as well, and will function in the same manner as Icestorm.
   This includes "Curse Enemies with X on Hit" modifiers.
 * Low life/full life conditions are now detected automatically (>=65% life reserved/with CI respectively), 
   but you can still turn them on manually if you need to

Other changes:
 * The various configuration options in the Calcs tab have been moved to a new Configuration tab
	* Moving these into a dedicated tab will provide room for more options to be added in the future
    * The names of many options have been changed to clarify their function
	* Some options now have tooltips that explain aspects of their function
 * Unsupported modifiers are now shown in red instead of white to help convey the fact that they won't work
 * The new class background artworks have been added to the passive skill tree
 * The required level for a build's passive tree is now shown when hovering over the points display
 * The Items tab will now display both source lists (Uniques and Rares) if there's room
 * Support gem compatability is now determined using the same data the game itself uses, and should now be 100% accurate

### 1.1.11 - 2016/10/25
 * Added flat mana to ES armour rare templates

### 1.1.10 - 2016/10/23
 * Added support for the poison-at-max-frenzy modifier on Snakebite

### 1.1.9 - 2016/10/07
 * Added flat chaos damage to all physical weapon templates

### 1.1.8 - 2016/10/04
 * Added support for the "Your flasks grant" modifiers on Doryani's Invitation
 * Detection of the Unarmed state now ignores the offhand
 * Added resistance breakdown section to the Calcs tab

### 1.1.7 - 2016/10/03
 * Fixed stun modifiers from several active and support gems

### 1.1.6 - 2016/10/02
 * Fixed bug causing issues with the new jewel attribute totals when a jewel is used multiple times

### 1.1.5 - 2016/10/01
 * Jewel tooltips now show totals for any relevant attributes (Str, Dex, Int) allocated within their radius
    * For example, Eldritch Knowledge shows Intelligence, and Spire of Stone shows Strength
    * For unsupported radius jewels (particularly threshold jewels) all attributes are shown by default
 * Fixed crit chance with Trypanon deviating from 100% under some conditions
 
### 1.1.4 - 2016/09/30
 * The tooltip for socket groups now includes gems which aren't part of any of the group's active skills
    * This includes gems which aren't supported, or are disabled, and any support gems which can't apply to the active skills
 * Made some minor tweaks to the rounding in the damage calculations

### 1.1.3 - 2016/09/26
 * Fixed issue causing certain skill setups to always be added when importing even if that skill is already in the build 
 * Re-importing a skill no longer resets gem's enabled states

### 1.1.2 - 2016/09/20
 * In the gem name dropdown list, support gems are now marked with a tick if they can apply to any of the
   active skills in the current socket group
 * Fixed issue causing the spell damage modifier on Clear Mind to fail to apply when no mana is reserved

### 1.1.1 - 2016/09/20
 * Added support for more "socketed gem" modifiers, particularly those from essences
 * Fixed a few minor issues

### 1.1.0 - 2016/09/20
 * You can now import all character data: passive tree, jewels, skills and items!
    * Character import now has two options:
       * Passive Tree and Jewels: imports the passive skill tree and any jewels socketed into it
	   * Items and Skills: imports all other equipped items, and any skills socketed into them
    * When importing to an existing build:
       * The passive tree will be replaced with the imported one
       * Items (including jewels) will be added to the build, unless the item was added by a previous character import
	      * If you've previously added an item by copying it from ingame, the character import will still add it,
	        so you'll need to delete the old items after the import
	   * Skills will be added if no existing skill matches the new one ('match' meaning the same gems in the same order)
    * The only data that cannot be imported is the bandit choices, as these aren't available from the API
 * Several improvements have been made to the Skills system:
    * You can now specify multiple active gems in a single skill setup (now referred to as a socket group)
    * Hovering over an active gem will highlight the support gems which are applying to it,
	  and hovering over a support gem will highlight the active gems that it applies to
	* The skills system should now be much more accurate at determining which supports can apply to active skill gems
    * Supports granted by an item are now automatically applied to any skills socketed in that item
       * Any such supports that you've added manually will be ignored due to the next change:
    * Multiple copies of support gems are now handled correctly (only the gem with the highest level is used)
 * Modifiers that depend on the absence of enemy status effects should now only apply in effective DPS mode
 * Passive tree search now highlights using a red circle instead of flashing
 * Updated the passive skill tree data

### 1.0.29 - 2016/09/14
 * You can now import passive tree links that have been shrunk with PoEURL.com
 * You can choose to shrink passive tree links with PoEURL when exporting the passive tree
 * Vaal auras actually work now!
 * Fixed gem enabled state not being preserved when copying/pasting skills

### 1.0.28 - 2016/09/13
 * Fixed boss curse effectiveness modifier not applying
 * Fixed issue relating to Prism Guardian's Blood Magic mod

### 1.0.27 - 2016/09/13
 * More updates to 2.4.0 uniques; most of them should have the correct roll ranges now
 * Added dropdown list and autocomplete to the skill gem name field
 * Skill gems can now be individually disabled
 * Skill gems now default to level 20
 * Evade Chance is now shown in side bar
 * Passive/item stat comparisons now show percentage increase/decrease for many stats (DPS, life, etc)

### 1.0.26 - 2016/09/09
 * More updates to 2.4.0 uniques
 * Re-nerfed Voidheart
 * Hypothermia now correctly affects hits only and not damage over time
 * Fixed gems sometimes appearing to be deleted when another gem in the same socket group was removed
 * Added flat elemental damage to ring, amulet and glove templates

### 1.0.25 - 2016/09/06
 * More updates to 2.4.0 uniques
 * Removed Prophecy league tag from all uniques
 * Updated Voidheart to account for the non-nerf (poison chance is still 100%)
 * Fixed resistances disappearing from the sidebar when the values are exactly 0
 * Elemental Focus now correctly disables ignite/shock/freeze

### 1.0.24 - 2016/09/05
 * Added/updated more 2.4.0 uniques

### 1.0.23 - 2016/09/03
 * Added templates for all of the new item bases (except Two-Toned Boots, because they break things)
 * Added a few more 2.4.0 uniques and added modifier ranges to some of the existing ones

### 1.0.22 - 2016/09/03
 * You can now copy and paste skills
 * Added support for Illuminated Devotion (only Helmet/Gloves at the moment)
 * Added Leo's ES recharge prefix to the Ring templates

### 1.0.21 - 2016/09/02
 * Added support for the reservation mod on Heretic's Veil
 * Added the missing Strength tag to Warlord's Mark
 * You can now view the changelog before applying an update
 * Also added an about screen. Hi!

### 1.0.20 - 2016/09/02
 * Added Str/Dex/Int to side bar stat list (which also now has a scroll bar for users running low resolutions)
 * Skill gems list in the skills tab now colours the gem name according to the gem's colour
 * Now shows "Removing this item will give you" section for all items, not just jewels
 * You can now equip items from both the "All Items" list and the uniques/templates list by Control+Clicking the item
    * If there's two slots the item can go in, holding Shift as well will equip it in the second slot instead
    * Jewels cannot be equipped in this way (since it'll probably put them in the wrong socket) but they will 
      still be added to your build if you Ctrl-Click them in the uniques or templates lists
    * You can also now drag items from the databases straight into item slots to add and equip them in one go!
    * And also drag items from the databases into the main items list

### 1.0.19 - 2016/09/02
 * Fixed error that would occur if you set your character level to 0
 * Added support for "while Unarmed" modifiers
 * Added latest patch changes
 * Gem name input is a bit more lenient (it's somewhat case-insensitive now)

### 1.0.18 - 2016/09/02
 * Items now automatically equip when added to the build if there is an empty slot which the item can go in
 * Automatically focus the edit control in the tree import/export popups
 * Added attack speed to the spell dagger template. Whirling Blades yo!

### 1.0.17 - 2016/09/02
 * Added support for skill DPS multipliers; currently only Lightning Tendrils uses it (it has a 4x mutliplier)
 * Fixed Lioneye's Fall not converting One Handed Melee and Two Handed Melee modifiers
 * Added Accuracy Rating to helm and glove templates
 * Side bar now shows you how far over the resistance caps you are

### 1.0.16 - 2016/09/02
 * Emergency fix for the passive tree controls

### 1.0.15 - 2016/09/02
 * Added support for Cast when Damage Taken, Cast when Stunned and Cast on Death (yes, really!)
 * Added support for Radiant Faith
 * Enabled mousewheel support on number edits, and added +/- buttons (character level, gem level etc)
 * Clarified many of the field labels in the Calcs tab
 * Added some tree %inc stats to the side bar
 
### 1.0.14 - 2016/09/01
 * Fixed tags on certain multipart skills not correctly applying
 * Fixed energy shield not showing up on Sin Trek
 * Dual Wielding modifiers will now apply
    * Skills that can use both weapons still only use the main hand at the moment; that requires a bit more work to implement

### 1.0.13 - 2016/09/01
 * Added a scroll bar to the Items tab to fix the issue with low screen resolutions
    * The scroll bar will automatically jump to the right when you start editing an item, then jump back when you save it
    * This might be a little disorienting; need feedback on this
 * Also fixed some minor issues with scroll bars (mouse wheel should now work on all of them)

### 1.0.12 - 2016/09/01
 * Updated tree to 2.4.0
 * Added latest patch note changes

### 1.0.11 - 2016/09/01
 * Fixed node description searching
 * Added + to Level of Socketed Minion Gems to helmet templates

### 1.0.10 - 2016/08/31
 * Fixed crash bug affecting some users

### 1.0.9 - 2016/08/31
 * Attempted fix for a crash bug some users have been experiencing

### 1.0.8 - 2016/08/31
 * Fixed issue preventing the standalone version from updating correctly

### 1.0.7 - 2016/08/31
 * Fixed items not being deleted after confirmation

### 1.0.6 - 2016/08/31
 * Added the missing Amulet slot to the item databases' slot dropdown

### 1.0.5 - 2016/08/31
 * Added "Save" button as an alternative to Ctrl+S

### 1.0.4 - 2016/08/31
 * Attempt to fix bug causing the top of the UI to be hidden under the title bar

### 1.0.3 - 2016/08/31
 * Made some tweaks to the build list screen to ward off some possible errors

### 1.0.2 - 2016/08/31
 * Fixed an error relating to multipart skills

### 1.0.1 - 2016/08/31
 * Fixed an error in the build list screen