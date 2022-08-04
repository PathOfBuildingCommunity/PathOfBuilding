In this tutorial, we'll step through the logic in `ModParser.lua`.  This module takes care of parsing mods from any item, passive node, or pantheon in the game.  This won't be comprehensive, since there are many patterns, and a lot of examples to work off of.  If you'd like to follow along, the code starts [here](../src/Modules/ModParser.lua#L3453).  Having a good understanding of [Lua patterns](https://www.lua.org/pil/20.2.html) will also be invaluable here (If you know regex, patterns will be similar, but less powerful and a different syntax).

#### Jewels
The first mods parsed are mods from jewels with a radius.  Jewels with a radius care about the nodes around them.  Since PoB doesn't know where these jewels will be placed when parsing the mod, a function is prepared for when the jewel has access to this information.  Any variable data are passed along much like other mods via pattern capture (i.e. anywhere you see `cap1`, `cap2`, etc., corresponds to a captured number from the Lua pattern)  See [`CalcSetup.buildModListForNode()`](../src/Modules/CalcSetup.lua#L76) for the code that handles actually calling the function to modify any nodes.  There are several helper functions specific to each type of jewel, but they all boil down to this function (which can be used on its own, when necessary):
- `function(node, out, data)`
  - `node`: The node that is being affected within the radius.  Can use things like `node.type` to determine notable or keystone, for example
  - `out`: Instance of `ModListClass`, used for altering or replacing the mod originally on the node
  - `data`: other data that might be relevant.  Mostly just used for preserving the source with `data.modSource`

There are 4 categories of jewels that have a helper function:
- Jewels that modify nodes in their radius (`jewelOtherFuncs`).  Uses customized functions for each jewel most of the time.
    - `getSimpleConv(srcList, dst, type, remove, factor)`
      - `srcList`: List of stats that will be affected in the radius
      - `dst`: Stat that those stats should apply to as well or instead
      - `type`: The type of increase that should apply (usually "INC" or "BASE")
      - `remove`: boolean that says whether or not to remove the original stats
      - `factor`: If the conversion shouldn't apply the full value, apply this factor instead
- Jewels that modify themselves based on stats allocated in their radius
  - `getPerStat(dst, modType, flags, stat, factor)`
    - The first three parameters correspond to name, modType, and flags in the [mod syntax](./modSyntax.md), where only `ModFlag`s are used
    - `stat`: The stat we're multiplying the `dst` stat by
    - `factor`: If the stats aren't 1:1, use this factor to change that
- Jewels that modify themselves based on stats unallocated in their radius.  This uses the same `getPerStat` function as above.
- Threshold jewels, which give stats after 40 of that stat is reached in their radius
  - `getThreshold(attrib, name, modType, value, ...)`
    - `attrib`: The attribute we need to reach a threshold for
    - The rest of the parameters are covered in the [mod syntax](./modSyntax.md)
- Cluster jewels, which parse simply what mods to add to their nodes and which notables to add as well.

### Scanning for matching text

The next steps all use the `scan` function to match text. It looks for the earliest and longest match from the given pattern list. If a match is found, it returns the value from the list, the remaining unmatched text, and any captures associated with the matched pattern.  For example, passing in "15% increased fire damage", and a table containing the key "^(%d+)%% increased" would return the value corresponding to the key, "fire damage", and 15.

### Special mods - `specialModList`
This is the largest list of `ModParser` and it's a catch-all for mods that don't fit a standard format (and aren't numerous enough to change the parsing logic to accommodate their format).  If the mod has a component captured via Lua pattern, a function can be used to capture the number(s) or other captured text.  E.g. `["lose ([%d%.]+) mana per second"] = function(num) return { mod("ManaDegen", "BASE", num) } end,`

Otherwise everything in this list can be done using the standard [mod syntax](./modSyntax.md)

***
## Parts of a "standard mod"
The mod we'll demonstrate adding is "Attack skills deal 20% increased damage while holding a Shield" from the Solidity notable on the passive tree.

### PreFlags - `preFlagList`

The first step in the process is scanning the text for text that matches one in the preFlag list.  In this case, we find `["^attack skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Attack },` and save that flag for later, continuing on with "20% increased damage while holding a Shield".

### Skill Tag - `preSkillNameList`

This looks for a skill name at the start of the line, usually used for enchantments.  Our example is not based on a skill, so we continue with the rest of the line.

### Mod form - `formList`

This is the meat of the mod parsing logic.  Most mods will match one of these styles.  In our case, we match `["^(%d+)%% increased"] = "INC",`, store the 20% off to be eventually used as `modValue`, and continue with "damage while holding a shield".

### Mod Tags - `modTagList`

This logic is run through twice, so we can have up to two tags after a mod to restrict it.  In our case, we only have one tag, and it matches on `["while holding a shield"] = { tag = { type = "Condition", var = "UsingShield" } },` and we continue on with "damage" as the only thing left of our line.

### Mod Name - `modNameList`
Finally we look through `modNameList` and match the remainder of our line on `["damage"] = "Damage",`, leaving us with nothing remaining in our line.

# Putting it all together #

Our example is fairly simple, as some mod forms will slightly alter mod names and values to be compatible with with names used elsewhere in PoB.  Regardless, once we have the mod name, type, value, and tags, we can combine them all into a mod as defined in the [mod syntax](./modSyntax.md).

## Important notes and tips ##

- `ModParser.lua` is actually not where most mods really come from.  When you refresh the dev mode version of PoB with `Ctrl` + `F5`, `ModParser.lua` runs and regenerates `ModCache.lua`, which stores the actual parsed version of the mod.  `ModParser.lua` only gets used if the mod doesn't already exist somewhere when loading PoB (passive tree, unique list, or rare item list).  If you hold left alt while hovering over a mod, you can see how it gets parsed: ![Parsed Mod](https://i.imgur.com/ArVupKs.png)

  If you're missing something, you can also see what is unable to be parsed: ![Unparsed Mods](https://i.imgur.com/RiIH0u4.png)

- All mods get converted to lower case before getting parsed, so when adding a new one make sure it's also lowercase.

- When adding a mod, see if you can add a new flag, or mod tag, before adding it to `specialModList`.  It makes the code much cleaner overall.

- When a mod changes, keep in mind backwards compatibility.  Since mods in most builds contain just the raw mod text, and are not tied to the underlying mod from GGG's data, we need to keep old mod wordings intact so those keep working on older builds.  This is especially true for mods that have gone legacy (i.e. can still exist in game)

### Miscellaneous

There are a few flags you might see attached to mods that are defined in [this section](../src/Modules/ModParser.lua#L3662).  These have to do with enemy or minion modifiers, or mods that don't directly affect the player.