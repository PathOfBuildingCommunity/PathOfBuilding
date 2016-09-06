# Path of Building

Welcome to Path of Building, an offline build planner for Path of Exile!
## Features
* Comprehensive offence + defence calculations:
  * Calculate your skill DPS, damage over time, life/mana/ES totals and much more!
  * Can factor in auras, buffs, charges, curses, monster resistances and more, to estimate your effective DPS
  * Also calculates life/mana reservations
  * Shows a summary of character stats in the side bar, as well as a detailed calcs breakdown tab which can show you how the stats were derived
  * Supports most skills, support gems, passives and item modifiers
    * Throughout the program, supported modifiers will show in blue and unsupported ones in white
    * Most minion skill are unsupported at present (except for golems, which can provide buffs to you)
    * Trigger gems are generally unsupported (Cast on Crit, etc)
    * No support for flasks yet
* Passive skill tree planner:
  * Support for jewels including most radius/conversion jewels
  * Features alternate path tracing (mouse over a sequence of nodes while holding shift, then click to allocate them all)
  * Fully intergrated with the offence/defence calculations; see exactly how each node will affect your character!
  * Can import PathOfExile.com and PoEPlanner.com passive tree links
  * You can also import the passive tree from one of your characters!
* Skill planner:
  * Add any number of main or supporting skills to your build
  * Supporting skills (auras, curses, buffs) can be toggled on and off
  * Automatically applies Socketed Gem modifiers from the item a skill is socketed into
* Item planner:
  * Add items from in game by copying and pasting them straight into the program!
  * Automatically adds quality to non-corrupted items
  * Fully intergrated with the offence/defence calculations; see exactly how much of an upgrade a given item is!
  * Contains a searchable database of all uniques that are currently in game (and some that aren't yet!)
    * You can choose the modifier rolls when you add a unique to your build
    * Includes all league-specific items and legacy variants
  * Also contains a database of rare item templates:
    * Allows you to create rare items for your build to approximate the gear you will be using
    * Choose which modifiers appear on each item, and the rolls for each modifier, to suit your needs
    * Has templates that should cover the majority of builds (inb4 'why is there no coral amulet?')
* Other features:
  * Share builds with other users by generating a share code
  * Automatic updating; most updates will only take a couple of seconds to apply
  * Somewhat more open source than usual (look in %ProgramData%\Path of Building if you're interested)
  * More to be added later if I'm not busy playing Atlas of Worlds ;)
  
## Download
Head over to the [Releases](https://github.com/Openarl/PathOfBuilding/releases) page to download the installer.

## Screenshots
![ss1](https://cloud.githubusercontent.com/assets/19189971/18089779/f0fe23fa-6f04-11e6-8ed7-ff7d5b9f867a.png)
![ss2](https://cloud.githubusercontent.com/assets/19189971/18089778/f0f923f0-6f04-11e6-89c2-b2c1410d3583.png)
![ss3](https://cloud.githubusercontent.com/assets/19189971/18089780/f0ff234a-6f04-11e6-8c88-6193fe59a5c4.png)

## Changelog
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