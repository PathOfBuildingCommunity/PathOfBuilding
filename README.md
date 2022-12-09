# Path of Building Community Fork
## Formerly known as LocalIdentity Fork

This is a fork of Openarl's Path Of Building that includes many extra features not in the base version of PoB
* Adds support for new and updated uniques from league 3.8 onwards
* Pantheon support
* Impale DPS support
* Enemy armour and physical damage reduction calculations
* Catalysts
* Dual influence crafting
* Search for all dropdown boxes
* Barrage Support skill gem
* Ensnaring Arrow support
* Thread of Hope support
* Crimson Dance support
* Void Shot support
* Delve helmet mod support
* Breakdown for aura and curse effect
* List of recently imported accounts to the Import/Export Build tab
* More tree highlighting options for node power
* Support for fossil mods in the crafting window. Including correct parsing for some mods that previously didn't work (e.g., 60% chance to deal 100% more poison/bleed damage)
* Add parsing for more nodes on the tree (i.e., Slayer, Champion, Berserker, Chieftain, Hierophant, Trickster, Assassin, Necromancer and Elementalist ascendancy nodes)
* Add oil combinations to notables on the passive tree
* Support for Elusive and Nightblade support gem
* Incremental shock values (not a locked 50%)
* Fixed Close Combat and Multistrike to have their correct damage values
* Logic for melee distance scaling attack multipliers (Close Combat and Slayer's Impact node)
* Withered now shows on the configuration screen
* Support for Ryslatha's Coil, Vaal Arc Lucky Buff, Perquil's Toe and more

## Download
Head over to the [Releases](https://github.com/PathOfBuildingCommunity/PathOfBuilding/releases) page to download the install wizard or portable zip.

## Contribute
You can find instructions on how to contribute code and bug reports [here](CONTRIBUTING.md).

## Changelog
You can find the full version history [here](CHANGELOG.md).

Welcome to Path of Building, an offline build planner for Path of Exile!
## Features
* Comprehensive offence + defence calculations:
  * Calculate your skill DPS, damage over time, life/mana/ES totals and much more!
  * Can factor in auras, buffs, charges, curses, monster resistances and more, to estimate your effective DPS
  * Also calculates life/mana reservations
  * Shows a summary of character stats in the side bar, as well as a detailed calculations breakdown tab which can show you how the stats were derived
  * Supports all skills and support gems, and most passives and item modifiers
    * Throughout the program, supported modifiers will show in blue and unsupported ones in red
  * Full support for minions
* Passive skill tree planner:
  * Support for jewels including most radius/conversion jewels
  * Features alternate path tracing (mouse over a sequence of nodes while holding shift, then click to allocate them all)
  * Fully integrated with the offence/defence calculations; see exactly how each node will affect your character!
  * Can import PathOfExile.com and PoEPlanner.com passive tree links; links shortened with PoEURL.com also work
* Skill planner:
  * Add any number of main or supporting skills to your build
  * Supporting skills (auras, curses, buffs) can be toggled on and off
  * Automatically applies Socketed Gem modifiers from the item a skill is socketed into
  * Automatically applies support gems granted by items
* Item planner:
  * Add items from in game by copying and pasting them straight into the program!
  * Automatically adds quality to non-corrupted items
  * Fully integrated with the offence/defence calculations; see exactly how much of an upgrade a given item is!
  * Contains a searchable database of all uniques that are currently in game (and some that aren't yet!)
    * You can choose the modifier rolls when you add a unique to your build
    * Includes all league-specific items and legacy variants
  * Features an item crafting system:
    * You can select from any of the game's base item types
    * You can select prefix/suffix modifiers from lists
    * Custom modifiers can be added, with Master and Essence modifiers available
  * Also contains a database of rare item templates:
    * Allows you to create rare items for your build to approximate the gear you will be using
    * Choose which modifiers appear on each item, and the rolls for each modifier, to suit your needs
    * Has templates that should cover the majority of builds (inb4 'why is there no coral amulet?')
* Other features:
  * You can import passive tree, items, and skills from existing characters
  * Share builds with other users by generating a share code
  * Automatic updating; most updates will only take a couple of seconds to apply
  * Somewhat more open source than usual (look in "%ProgramData%\Path of Building" if you're interested)

## Screenshots
![ss1](https://user-images.githubusercontent.com/23911/153694681-cbc7b83a-970c-4020-b9e3-2a09f0808e38.png)
![ss2](https://user-images.githubusercontent.com/23911/153694692-0309bab1-6776-43ac-bb5a-6cc40265c7c7.png)
![ss3](https://user-images.githubusercontent.com/23911/153694693-2471e491-6ed9-47ae-abcc-a3bff81cdc7c.png)

## Licence

[MIT](https://opensource.org/licenses/MIT)

For 3rd-party licences, see [LICENSE](LICENSE.md).
The licencing information is considered to be part of the documentation.
