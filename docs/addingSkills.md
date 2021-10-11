Skills in Path of Building are generated from what is called a template file.  These template files are used when exporting data from the ggpk and can be found [here](../src/Export/Skills).  While this tutorial will focus on the [combined data files](../src/Data/Skills) know that any changes will be overwritten unless added to the template files.  The script that combines these template files with the game data can be found [here](../src/Export/Scripts/skills.lua)

## Template files

A template file for a new skill can consist of the following directives, which tell the export script what to put in the final file.

### #skill grantedEffectId [displayName]
This directive initializes all the data for the skill and emits the skill header.  `grantedEffectId` matches up with the name defined in the ggpk, in the `GrantedEffects` table.  `displayName` is optional, but can override the display name from the game data if needed

### #flags
Sets the base flags for an active skill, like projectile, attack, or minion, for example

### #mods
This directive does nothing but ensure the mods that come with the skill are included after exporting.  This will almost always be included

### #baseMod
This directive is used when there are mods associated with the skill that don't come in the statMap (see the statMap section below)

### #noGem
This directive is used when a new skill doesn't have a gem associated with it.  Skills from uniques are some that fall in this category

## Combined data

The most important tables constructed from the game data are the `stats` table, and the `levels` table.  Taking a look at just one row in `levels`, there will be a list of numbers, followed by named entries, such as `levelRequirement`, `damageEffectiveness`, etc.  Each of these stats are mapped to a mod in Path of Building either via `SkillStatMap.lua`, or if the stat is specific to this particular skill (e.g. `spectral_helix_rotations_%` would only apply to Spectral Helix) in `skillStatMap` in this same table.  The corresponding mod will have `nil` in place of its normal value, and that value instead comes from this row in the `levels` table.  Notice that not all of the stats have a number in the first part of the `levels` row.  These extra stats are usually for booleans/flags that are always true.

Notice how these stat numbers don't really align with damage numbers in any meaningful way for active skills.  The stat numbers are interpolated by the numbers in the corresponding position in the `statInterpolation` table in the same row.
* 1 means take the number as-is.  This is the most common interpolation
* 2 means apply a linear interpolation: `statValue = round(prevStat + (nextStat - prevStat) * (actorLevel - prevReq) / (nextReq - prevReq))`
* 3 means apply an effectiveness interpolation.  Take this formula for current effectiveness and multiply by the gem level: `(3.885209 + 0.360246 * (actorLevel - 1)) * (grantedEffect.baseEffectiveness or 1) * (1 + (grantedEffect.incrementalEffectiveness or 0)) ^ (actorLevel - 1)` 

The code for this can be found in `CalcTools.lua` starting [here](../src/Modules/CalcTools.lua#L166)

## Adding skills

1. Add `#skill grantedEffectId` to the appropriate template file for the skill
2. Add `#mods` below that
3. [Export the skills](../CONTRIBUTING.md#exporting-ggpk-data-from-path-of-exile) to combine it with the game data
4. If there are stats in the `stats` table that aren't recognized already in `SkillStatMap.lua`, add a `statMap` table to the template file to map them properly to a mod.
5. Add other mods via `#baseMod` if needed.

## Adding minions

* The minion itself has to be added to `Minion.txt`.  This file uses different directives to construct the data, but the most important ones are `#monster monsterVariety monsterName`, `#limit modName`, and `#emit`. `monsterVariety` uses the Id from `MonsterVarieties`, while `monsterName` will be referenced in the skill gem.  `#limit` sets a limit on summoned monsters based on a multiplier calculated elsewhere on the character, and `#emit` works similarly to the `#mods` directive on skills.
* The only extra thing that needs to be added to the base skill is a table called `minionList` that contains the names of all the minions that skill can summon (`monsterName` from the previous step).
* Some minions have skills of their own.  These skills can be added like any other skill to `minion.txt`.

