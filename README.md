# Path of Building

Welcome to Path of Building, an offline build planner for Path of Exile!
## Features
* Comprehensive offence + defence calculations:
  * Calculate your skill DPS, damage over time, life/mana/ES totals and much more!
  * Can factor in auras, buffs, charges, curses, monster resistances and more, to estimate your effective DPS
  * Also calculates life/mana reservations
  * Shows a summary of character stats in the side bar, as well as a detailed calcs breakdown tab which can show you how the stats were derived
  * Supports most skills, support gems, passives and item modifiers
    * Throughout the program, supported modifiers will show in blue and unsupported ones in red
    * Most minion skill are unsupported at present (except for golems, which can provide buffs to you)
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
  * Automatically applies support gems granted by items
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