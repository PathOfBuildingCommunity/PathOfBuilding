This syntax is used all over the codebase, but there are two locations that hold the majority of them: [ModParser](../src/Modules/ModParser.lua) and [Skill Stats](../src/Data/SkillStatMap.lua).

The standard format of a mod looks like this: `mod(ModName, ModType, Value, source, modFlags, keywordFlags, extraTags)`  See the function declaration [here](../src/Modules/ModTools.lua#L20-L46)

### ModName
Used as a key, so you can reference this mod elsewhere in PoB.  Can really be anything, but look around the codebase to find ones you need (e.g. "Damage", "Life", "PhysicalDamageGainAsLightning", etc)
### ModType
- "BASE": used for flat values that add to other base values (e.g. Flat added damage, flat life, flat evasion)
- "INC": used for increased and reduced mods that stack additively.  Use a negative value to represent "reduced".
- "MORE": used for more and less mods that stack multiplicatively.  Use a negative value to represent "less".
- "OVERRIDE": used when you want to ignore any calculations done on this mod and just use the value (e.g. "your resistances are 78%" from Loreweave)
- "FLAG": used for conditions.  Value will be true/false when this type is used.
  - When you need the "FLAG" ModType, consider using the function `flag(name, source, modFlags, keywordFlags, extraTags)` instead. This method shortens the code and clarifies the intent. For example, `flag("ZealotsOath", { type = "Condition", var = "UsingFlask" })` is the same as `mod("ZealotsOath", "FLAG", true, { type = "Condition", var = "UsingFlask" })`
### Value
This represents the raw value of the mod.  When it's used in the skills to map from the skill data, this will be `nil`, as it pulls the number from the gem based on the level.
### Source
This is where the mod comes from.  Often it will be automatically filled in, coming from a tree node, gem, or item.  If you do need to specify it for some reason, it's a string, and you can use "Tree:[nodeId]" as a special value to show a tree inset on hover.
### Mod Flags
These are bitwise flags that say what the mod can apply to.  See a full list [here](../src/Data/Global.lua) under `ModFlag`.  If you want to use several flags at once, make use of `bit.bor` and `bor` (ModParser.lua uses this alias) to combine them.  When combined, all of the flags have to match.  If you only need one to match, use the "ModFlagOr" tag instead.
### Keyword Flags
These function similarly to the mod flags, and use the `KeywordFlag` group in `Global.lua`.  These are usually based off of the flags on the gem itself. If you want to use several flags at once, make use of `bit.bor` and `bor` (ModParser.lua uses this alias) to combine them.  When combined, only one of the flags has to match.  If you need them all to match, use the "KeywordFlagAnd" tag instead. 
### Extra Tags
Often a mod will only apply under certain conditions, apply multiple times based on other stats, etc.  The syntax for that depends heavily on the first parameter, "type".  There can be an infinite number of these tags at the end of a mod, so multiple can apply at one time.  Some parameters, like `actor` or `neg` can be used on all of the types.  Below are different types and the other parameters they need to function.

* Condition: Used for conditions on the player that need to be in place before the mod applies (e.g. CritRecently, Shocked, etc.)
    * var: Contains the name of the condition
    * neg: (defaults to false) Boolean that negates the condition
    * In order to set a condition, use "Condition:[name]" as a FLAG mod
* ActorCondition: Used for conditions on an enemy or a minion.
    * var: Contains the name of the condition
    * neg: (defaults to false) Boolean that negates the condition
    * actor: Can be "enemy" or "parent".  "parent" is used when giving a mod to a minion that is based on a condition on the player (its controller).  e.g. `mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HavePhysicalGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),`
* Multiplier: Multiplies the mod by this variable
    * var: mod to multiply by
    * limit: The maximum number the mod can go up to
    * limitTotal: boolean that changes the behavior of limit to apply after multiplication.  Defaults to false.
* MultiplierThreshold: Similar to a condition that only applies when the variable is above a specified threshold
    * var: name of the mod
    * threshold: number to reach before the mod applies
* PerStat: Similar to Multiplier, but is used for character stats instead of arbitrary multiplier like number of sockets
    * stat: The stat to multiply by
    * div: Defaults to 1.  Divide by this number after calculation, rounding down.  Useful for mods that say "per 5 strength", for example
* StatThreshold: Similar to MultiplierThreshold
    * stat: The name of the stat
    * threshold: number to reach before the mod applies
* PercentStat: Used for mods based on percentages of other stats (e.g. Agnostic)
    * stat: The name of the stat
    * percent: value of the percent
* SkillType: This type is for mods that affect all skills of a certain type
    * skillType: An enum value in Global.lua
* SkillName: Similar to SkillType, but specifies the name of the skill, usually for enchantments
    * skillName: The English name of the skill (e.g. "Decoy Totem")
* GlobalEffect: This is used largely for buffs and curses that affect actors even when it's not the main skill
    * effectType: Can be "Guard", "Buff", "Debuff", "Aura", "AuraDebuff", "Curse".  These apply to you, you, enemies, you + minions, enemies, and enemies, respectively
    * effectName: String to specify where the global effect comes from
    * effectEnemyCond: Specify a condition so this mod applies to the enemy when that condition is fulfilled
    * effectStackVar: Multiplies the mod by this variable (usually another mod)
    * modCond: Apply the mod when the actor has this condition
    * unscaleable: boolean that determines whether this buff can be scaled by buff effect
* DistanceRamp: A rare type that is used on skills and effects that do different things at different distances from the character
    * ramp: Numbers to multiply the mod by at different distances.  e.g. `ramp = {{35,0},{70,1}}` means the mod does nothing at 35 units, but has its full value at 70 units.
* ModFlagOr: Used when you only need one ModFlag to match, e.g. `["with axes or swords"] = { flags = ModFlag.Hit, tag = { type = "ModFlagOr", modFlags = bor(ModFlag.Axe, ModFlag.Sword) } },` needs `Hit`, but can use either of the other two flags
    * modFlags: Use `bor` as if you were adding ModFlags normally
* KeywordFlagAnd: Used when you need all of the KeywordFlags to match
    * keywordFlags: Use `bor` as if you were adding KeywordFlags normally