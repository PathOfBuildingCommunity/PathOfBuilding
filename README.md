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
  * Can import PathOfExile.com and PoEPlanner.com passive tree links; links shortened with PoEURL.com also work
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
  * You can import passive tree, items, and skills from existing characters
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
 * Fixed gems sometimes appearing to be deleted when another gem in the same socketGroup was removed
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