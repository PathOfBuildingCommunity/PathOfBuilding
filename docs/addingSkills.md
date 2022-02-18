Skills in Path of Building are generated from what is called a template file.  These template files are used when exporting data from the ggpk and can be found [here](../src/Export/Skills).  While this tutorial will focus on the [combined data files](../src/Data/Skills) know that any changes will be overwritten unless added to the template files.  The script that combines these template files with the game data can be found [here](../src/Export/Scripts/skills.lua)

## Template files

A template file for a new skill can consist of the following directives, which tell the export script what to put in the final file.  Other fields that end up in 

### #skill grantedEffectId [displayName]
This directive initializes all the data for the skill and emits the skill header.  `grantedEffectId` matches up with the name defined in the ggpk, in the `GrantedEffects` table.  `displayName` is optional, but can override the display name from the game data if needed

### #flags
Sets the base flags for an active skill, like projectile, attack, or minion, for example.  These flags are then used, along with the SkillTypes gotten from the ggpk, to add different KeywordFlags and ModFlags to the skill.  The available flags include the following, and add a KeywordFlag or ModFlag of the same name unless otherwise stated:
  * melee
  * attack
  * spell
  * projectile
  * area
  * hit
  * brand
  * totem
  * trap
  * mine
  * chaining
  * warcry
  * duration
  * curse
  * hex

### #mods
This directive does nothing but ensure the mods that come with the skill are included after exporting.  This will almost always be included

### #baseMod
This directive is used when there are mods associated with the skill that don't come in the statMap (see the statMap section below)

### #noGem
This directive is used when a new skill shouldn't have a gem associated with it.  Some skills have a gem internally, but it's not one that can be socketed in gear, so this is used to disable it (e.g. Bone Armour)

## Combined data

The most important tables constructed from the game data are the `stats` table, and the `levels` table.  Taking a look at just one row in `levels`, there is a list of numbers, followed by named entries, such as `levelRequirement`, `damageEffectiveness`, etc.  This list of numbers maps directly to each entry in the `stats` table.  Notice that not all of the stats have a number in the first part of the `levels` row.  These extra stats are usually for booleans/flags that are always true.
* For example, here are the two tables for Fireball:
  ```lua
  stats = {
		"spell_minimum_base_fire_damage",
		"spell_maximum_base_fire_damage",
		"base_chance_to_ignite_%",
		"fireball_base_radius_up_to_+_at_longer_ranges",
		"base_is_projectile",
		"quality_display_active_skill_ignite_damage_is_gem",
	},
	levels = {
		[1] = { 0.80000001192093, 1.2000000476837, 25, 0, damageEffectiveness = 2.4, critChance = 6, levelRequirement = 1, statInterpolation = { 3, 3, 1, 1, }, cost = { Mana = 6, }, },
		[2] = { 0.80000001192093, 1.2000000476837, 25, 0, damageEffectiveness = 2.4, critChance = 6, levelRequirement = 2, statInterpolation = { 3, 3, 1, 1, }, cost = { Mana = 6, }, },
		[3] = { 0.80000001192093, 1.2000000476837, 25, 1, damageEffectiveness = 2.4, critChance = 6, levelRequirement = 4, statInterpolation = { 3, 3, 1, 1, }, cost = { Mana = 7, }, },
  ```
  The value for `spell_minimum_base_fire_damage` would be 0.80000001192093, the value for `base_chance_to_ignite_%` would be 25, and since `base_is_projectile` doesn't have a number, it's just a flag on the skill to properly factor in projectile mods.
  
Each of these stats are mapped to a mod in Path of Building either via `SkillStatMap.lua`, or if the stat is specific to this particular skill (e.g. `spectral_helix_rotations_%` would only apply to Spectral Helix) in `statMap` in this same table.  If a mapping exists in both places, the one local to this skill will take precedence.  The corresponding mod will have `nil` in place of its normal value, and that value instead comes from this row in the `levels` table.

Notice how these stat numbers don't really align with damage numbers in any meaningful way for active skills.  The stat numbers are interpolated by the numbers in the corresponding position in the `statInterpolation` table in the same row.
* 1 means take the number as-is.  This is the most common interpolation
* 2 means apply a linear interpolation: `statValue = round(prevStat + (nextStat - prevStat) * (actorLevel - prevReq) / (nextReq - prevReq))`
* 3 means apply an effectiveness interpolation.  Take this formula for current effectiveness and multiply by the first two values in the gem level's row: `(3.885209 + 0.360246 * (actorLevel - 1)) * (grantedEffect.baseEffectiveness or 1) * (1 + (grantedEffect.incrementalEffectiveness or 0)) ^ (actorLevel - 1)`
  - For example, a level 20 Fireball (as of this writing) deals 1095 to 1643 damage.  To get those numbers we'd apply the formula like so: `(3.885209 + 0.360246 * (70 - 1)) * (2.9384000301361 or 1) * (1 + (0.041200000792742 or 0)) ^ (70 - 1)` ends up being 1369.26, and multiplied by the lower value for the level 20 row (0.80000001192093) you get 1095 minimum damage.  Do the same thing for the higher value in that same row (1.2000000476837) and you get 1643 maximum damage.

The code for this can be found in `CalcTools.lua` starting [here](../src/Modules/CalcTools.lua#L166)

## Skill Parts

Many times a skill will have different components that each do different types of damage, or the skill can be used in more than one way that changes the damage output.  To support these different modes or parts of a skill, add a table called `parts` to the skill that contains multiple entries of the form: `{ name = <Part name>, }`.  Making mods based on the skill part the user chooses simply requires the `SkillPart` tag to be added to a mod: `{ type = "SkillPart", skillPart = 2 }`

## Pre Functions (preFuncs)

Some skills rely on knowing something more about the character before they can calculate damage or some other property.  One example is Righteous Fire, as it has to know the player (or totem's) life and ES totals before running the calculation.  To do this, a calculator will call a function, giving it `activeSkill` and `output` as parameters.  This function will live alongside the skill and is completely custom.  There are 4 preFuncs that can currently be used:
* initialFunc - This is called before anything else is done in CalcOffence, allowing for special mods to be added to the player
* preSkillTypeFunc - This is called before the flag-specific logic is called in CalcOffence.  For example, if you needed to calculate ChainCount differently, you could add the mod here
* preDamageFunc - This is called before the final damage passes are done.  This is the most used of all the preFuncs, so there are plenty of examples to search for.
* preDotFunc - This is run before damage over time is calculated.  The only current example is Burning Arrow, for its 5 stack multiplier.

## Adding skills

1. Add `#skill grantedEffectId` to the appropriate template file for the skill
2. Add `#mods` below that
3. [Export the skills](../CONTRIBUTING.md#exporting-ggpk-data-from-path-of-exile) to combine it with the game data
4. If there are stats in the `stats` table that aren't recognized already in `SkillStatMap.lua`, add a `statMap` table to the template file to map them properly to a mod.
5. Add other directives/options if needed

## Adding minions

* The minion itself has to be added to `Minion.txt`.  This file uses different directives to construct the data, but the most important ones are `#monster monsterVariety monsterName`, `#limit modName`, and `#emit`. `monsterVariety` uses the Id from `MonsterVarieties`, while `monsterName` will be referenced in the skill gem.  `#limit` sets a limit on summoned monsters based on a multiplier calculated elsewhere on the character, and `#emit` works similarly to the `#mods` directive on skills.
* The only extra thing that needs to be added to the base skill is a table called `minionList` that contains the names of all the minions that skill can summon (`monsterName` from the previous step).
* Some minions have skills of their own.  These skills can be added like any other skill to `minion.txt`.

