# Changelog

## [v2.39.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.39.1) (2024/01/24)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.39.0...v2.39.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Crashes
* Fix crash when opening old builds by reverting Cluster Jewel import fix
- Fix crash when hovering attribute requirements [\#7302](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7302) ([Wires77](https://github.com/Wires77))

### User Interface
- Fix breakdown sorting for unrelated stats [\#7303](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7303) ([Wires77](https://github.com/Wires77))
- Fix charge duration not displaying in breakdown [\#7296](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7296) ([Wires77](https://github.com/Wires77))

### Fixed Bugs
- Fix mods not applying to Vaal gems correctly [\#7300](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7300) ([sida-wang](https://github.com/sida-wang))



## [v2.39.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.39.0) (2024/01/23)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.38.4...v2.39.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Add all new 3.23 Spectres [\#7127](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7127) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix longstanding issues with minion stats (more fixes will come in future updates) [\#7253](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7253) ([LocalIdentity](https://github.com/LocalIdentity), [ifnjeff](https://github.com/ifnjeff))
  * Some Minion Attacks will reduce by 10-30% DPS
  * Life values of some minions will change
  * Spectre DPS values will reduce for some monsters
  * Armour and Evasion values will drastically increase
- Add support gem DPS sorting for Skills granted by Items (e.g. Arakaali's Fang, Whispering Ice etc.) [\#6707](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6707) ([Paliak](https://github.com/Paliak), [sida-wang](https://github.com/sida-wang))
- Add That Which Was Taken jewel to unique list [\#7178](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7178) ([justjuangui](https://github.com/justjuangui))
- Add support for filtering on number of Sockets and Links in Item Trader [\#7217](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7217) ([Peechey](https://github.com/Peechey))
- Add config to set the effect of Ruthless Support [\#7237](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7237) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for resetting Search Weights in Item Trader [\#7261](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7261) ([Peechey](https://github.com/Peechey))
- Add support for Spectre buffs [\#7135](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7135) ([justjuangui](https://github.com/justjuangui))
- Show Accuracy above Life when using Precise Technique [\#6034](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6034) ([Peechey](https://github.com/Peechey))
- Add support for converting all trees to latest version [\#7200](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7200) ([Peechey](https://github.com/Peechey))
- Add breakdown for Endurance, Frenzy and Power charges [\#7222](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7222) ([duiker101](https://github.com/duiker101))

### Fixed Crashes
- Fix Crash on Beta branch when using trade search [\#7168](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7168) ([secondfry](https://github.com/secondfry))
- Fix Crash on clicking "Show All Configurations" in new build [\#7132](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7132) ([Paliak](https://github.com/Paliak))
- Fix Crash when skills granting buffs that rely on buffs are disabled [\#7223](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7223) ([Paliak](https://github.com/Paliak))

### User Interface
- Sort the Calculations Tab breakdown lists by value [\#7211](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7211) ([duiker101](https://github.com/duiker101))
- Add scrollbar to Item Trader when large number of sockets are allocated [\#7234](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7234) ([Peechey](https://github.com/Peechey))
- Fix Boneshatter missing self damage breakdown [\#7138](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7138) ([Paliak](https://github.com/Paliak))
- Fix Rage Cost of Vaal Skills not displaying correctly for Hateforge [\#7242](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7242) ([sida-wang](https://github.com/sida-wang))
- Fix Powerful/Frenzied Faith displaying incorrectly in the Timeless Jewel search [\#7251](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7251) ([sida-wang](https://github.com/sida-wang))

### Fixed Bugs
- Fix Law of the Wilds using the wrong minion data [\#7254](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7254) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Blink/Mirror Arrow of Bombarding/Prismatic using wrong Minion Skills [\#7277](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7277) ([LocalIdentity](https://github.com/LocalIdentity))
* Fix Cluster Jewel import not allocating nodes correctly [\#7270](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7270), [\#7221](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7221) ([sida-wang](https://github.com/sida-wang), [Peechey](https://github.com/Peechey))
- Fix importing of Vaal Impurity Skills and Transfigured Vaal Summon Skeletons [\#7189](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7189) ([sida-wang](https://github.com/sida-wang))
* Fix mods that apply to skill gems, not applying to their Transfigured versions [\#7126](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7126), [\#7224](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7224) ([sida-wang](https://github.com/sida-wang), [Paliak](https://github.com/Paliak))
- Fix loading of Passive Tree dropdown in Items Tab [\#7216](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7216) ([Peechey](https://github.com/Peechey))
- Cap Doom Blast expiration mode and use charge based calcs for skills that ignore tick rate [\#6720](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6720) ([Paliak](https://github.com/Paliak))
- Fix bug where Precursor's Emblem's curse mod was not working [\#7186](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7186) ([Drox346](https://github.com/Drox346))
- Fix Flask effect increasing the Culling strike threshold from Voranas Preparation [\#7164](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7164) ([Paliak](https://github.com/Paliak))
- Fix Ngamahu, Flame's Advance adding Strength to Unique jewels [\#7142](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7142) ([Paliak](https://github.com/Paliak))
- Fix Vortex of Projection damage when cast on Frostbolt from increased to more [\#7131](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7131) ([sida-wang](https://github.com/sida-wang))
- Fix Brand duration incorrectly affecting Duration of skills cast by Arcanist Brand [\#7188](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7188) ([Paliak](https://github.com/Paliak))
- Fix Trigger rate calculations when dual wielding 1h weapons [\#7137](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7137) ([Paliak](https://github.com/Paliak))
- Fixes Effective Trigger rate not accounting for Evasion roll for on Crit Triggers [\#7203](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7203) ([Paliak](https://github.com/Paliak))
- Fix Ruthless Support applying to Tawhoa's Chosen [\#7238](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7238) ([Paliak](https://github.com/Paliak))
- Fix Inspiration Charges not applying to Minion Skills [\#7243](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7243) ([sida-wang](https://github.com/sida-wang))
- Fix skill effect duration from buffs not applying to Earthquake of Amplification Aftershock [\#7249](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7249) ([sida-wang](https://github.com/sida-wang))
- Fix Poison Duration from Charms stacking with Noxious Strike [\#7248](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7248) ([sida-wang](https://github.com/sida-wang))
- Fix Base Damage from Transfigured shield skills not being applied [\#7273](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7273) ([sida-wang](https://github.com/sida-wang))
- Fix added Cooldown and added Cast Time not working correctly [\#6728](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6728) ([Paliak](https://github.com/Paliak))
- Fix Kalandra's Touch not adding to influenced items multiplier [\#7182](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7182) ([Paliak](https://github.com/Paliak))
- Fix resistance calculations when using Glimpse of Chaos and Chieftain Tasalio node [\#7201](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7201) ([sida-wang](https://github.com/sida-wang))
- Fix Oath of the Maji not stacking with Juggernaut's Unbreakable [\#7225](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7225) ([wkingston1248](https://github.com/wkingston1248))

### Accuracy Improvements
- Fix mod parsing for Militant Faith Cloistered Notable [\#7197](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7197) ([Peechey](https://github.com/Peechey))
- Fix incorrect base Mana cost of Toxic Rain with Mirage Archer [\#7170](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7170) ([Paliak](https://github.com/Paliak))
- Fix Unnatural Instinct incorrectly working with Pure Talent [\#7240](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7240) ([Paliak](https://github.com/Paliak))
- Fix Stun and Block Duration not rounding to server ticks [\#7233](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7233) ([LocalIdentity](https://github.com/LocalIdentity))



## [v2.38.4](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.38.4) (2023/12/20)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.38.3...v2.38.4)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed

### Fixed Crashes
- Fix occasional crash when loading build on Beta branch [\#7120](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7120) ([Nostrademous](https://github.com/Nostrademous))



## [v2.38.3](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.38.3) (2023/12/19)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.38.2...v2.38.3)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed

### Fixed Crashes
- Fix crash when checking the breakdown for Transfigured Eye of Winter and Infernal Blow [\#7116](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7116) ([LocalIdentity](https://github.com/LocalIdentity))

### Fixed Bugs
- Fix Oath of the Magi not working for Body Armour slot [\#7109](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7109) ([sida-wang](https://github.com/sida-wang))
- Fix Lancing Steel less damage multiplier only applying to Hits [\#7114](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7114) ([deathbeam](https://github.com/deathbeam))

### Other change
- Update The Adorned to work in Cluster Jewel sockets [\#7113](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7113) ([LocalIdentity](https://github.com/LocalIdentity))



## [v2.38.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.38.2) (2023/12/19)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.38.1...v2.38.2)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed

### Fixed Bugs
- Fix Bodyswap of Sacrifice explosion not scaling correctly [\#7104](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7104) ([LocalIdentity](https://github.com/LocalIdentity))



## [v2.38.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.38.1) (2023/12/18)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.38.0...v2.38.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed

### User Interface
- Fix tooltip for Summon Chaos Golem of the Maelstrom [\#7075](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7075) ([QuickStick123](https://github.com/QuickStick123))
- Fix Blade Blast of Dagger Detonation having a stages box [\#7095](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7095) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix "Cast on Frostbolt" config not showing for Ice Nova of Frostbolts [\#7065](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7065) ([LocalIdentity](https://github.com/LocalIdentity))

### Fixed Crashes
- Fix crash when importing some builds [\#7085](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7085) ([Paliak](https://github.com/Paliak))

### Fixed Bugs
- Fix Flicker Strike DPS being limited by cooldown [\#7078](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7078) ([sida-wang](https://github.com/sida-wang))
- Fix Replica Dragonfang's Flight not affecting Transfigured gems [\#7101](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7101) ([Paliak](https://github.com/Paliak))
- Fix Lacerate of Haemorrhage "more damage with Bleeding" using increased [\#7072](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7072) ([sida-wang](https://github.com/sida-wang))
- Fix The Adorned not applying to jewels in outer tree sockets [\#7086](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7086) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix The Adorned applying to abyss jewels in gear [\#7086](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7086) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Frost Blades of Katabasis DoT not being scaled by area damage [\#7094](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7094) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Dual Strike of Ambidexterity not using offhand attack time [\#7097](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7097) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Vaal gems loading incorrect variant after reopening a build [\#7082](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7082) ([sida-wang](https://github.com/sida-wang))
- Fix Pyroclast Mine aura not affecting the damage of other skills [\#7084](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7084) ([sida-wang](https://github.com/sida-wang))
- Fix gem mods on Forbidden Shako not working correctly with Utula's Hunger [\#7087](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7087) ([sida-wang](https://github.com/sida-wang))
- Fix "damage taken by at least x%" Ailment mods not stacking [\#7093](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7093) ([LocalIdentity](https://github.com/LocalIdentity))

### Accuracy Improvements
- Fix Devouring Diadem using legacy Ailment duration mod [\#7077](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7077) ([sida-wang](https://github.com/sida-wang))
- Fix Catalysts not working correctly on Replica Dragonfang's Flight [\#7074](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7074) ([sida-wang](https://github.com/sida-wang))
- Revert preferred slot for Unseen Strike [\#7085](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7085) ([Paliak](https://github.com/Paliak))



## [v2.38.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.38.0) (2023/12/18)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.37.0...v2.38.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Add support for new transfigured gems [\#6984](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6984), [\#7048](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7048), [\#7047](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7047), [\#7041](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7041), [\#7039](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7039) ([LocalIdentity](https://github.com/LocalIdentity), [Nostrademous](https://github.com/Nostrademous), [markoleptic](https://github.com/markoleptic), [jopotochny](https://github.com/jopotochny), [Lilylicious](https://github.com/Lilylicious))
  * Pretty much every new gem should be supported, with a select few still needing a bit more work
- Add support for selecting league for Timeless Jewel search [\#7028](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7028) ([Peechey](https://github.com/Peechey))

### Fixed Crashes
- Fix Crash when using the Adorned and items with Abyssal sockets [\#7054](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7054) ([LocalIdentity](https://github.com/LocalIdentity))

### Fixed Bugs
- Fix Tinctures when using Micro-Distillery Belt [\#7035](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7035) ([Peechey](https://github.com/Peechey))
- Fix Lord of Drought increasing curse limit [\#7040](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7040) ([Paliak](https://github.com/Paliak))
- Fix Hidden Blade not using main weapon and its Supports [\#7038](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7038) ([Paliak](https://github.com/Paliak))
- Fix Rigwald's Curse damage conversion with specific Claw mods [\#7037](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7037) ([Peechey](https://github.com/Peechey))
- Fix Ascendancy class not resetting when changing base class [\#7024](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7024) ([Lilylicious](https://github.com/Lilylicious))

### Accuracy Improvements
- Fix Minion Instability to now use player Summon speed instead of Minion Hit speed [\#7032](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7032) ([Regisle](https://github.com/Regisle))
- Fix Oath of the Maji applying when gear slot is empty [\#7057](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7057) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Rage not working when using Warlord's Mark [\#7056](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7056) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Deadly Ailments less hit damage multiplier not working [\#7055](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7055) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Forbidden Shako and Megalomaniac display error if added from the uniques list [\#7042](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7042) ([sida-wang](https://github.com/sida-wang))

### Other changes
- Add additional attributes to save data [\#7050](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7050) ([asvanberg](https://github.com/asvanberg))


## [v2.37.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.37.0) (2023/12/13)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.36.1...v2.37.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Add support for new Uniques [\#7016](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7016) ([LocalIdentity](https://github.com/LocalIdentity))
  - The Adorned
  - The Burden of Shadows
  - Nametaker

### User Interface
- Change Manastorm config option to not overrun options box [\#7008](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7008) ([Ivniinvi](https://github.com/Ivniinvi))

### Fixed Bugs
- Fix parsing for changed mod names [\#7016](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7016) ([LocalIdentity](https://github.com/LocalIdentity))
  - Storm Secret
  - Umbilicus Immortalis
  - Replica Infractem
  - Dead Reckoning
- Fix Projectile count being 1 higher on all skills [\#7006](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7006) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Ascendant nodes counting towards allocated passive skill total [\#7002](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7002) ([Regisle](https://github.com/Regisle))
- Fix Pyroclast Mine Aura Effect scaling Maximum Added Flat Damage [\#7005](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7005) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Herald of Agony quality not working [\#7017](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7017) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix error when using Trader making you unable to search for item [\#7011](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7011) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix parsing for Necromancer Offering charm not working [\#7014](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7014) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix ES from Tricksters Escape Artist when using Oath of the Maji [\#7018](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/7018) ([LocalIdentity](https://github.com/LocalIdentity))


## [v2.36.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.36.1) (2023/12/11)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.36.0...v2.36.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Crashes
- Fix Crash when opening Timeless Jewel search [\#6995](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6995) ([LocalIdentity](https://github.com/LocalIdentity))

### Fixed Bugs
- Fix crash when hovering over Masteries [\#6989](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6989) ([Wires77](https://github.com/Wires77))
- Fix negative bypass being ignored [\#6992](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6992) ([mortentc](https://github.com/mortentc))


## [v2.36.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.36.0) (2023/12/11)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.35.5...v2.36.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Update all base skill gems + minions with 3.23 changes [\#6976](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6976) ([LocalIdentity](https://github.com/LocalIdentity), [Wires77](https://github.com/Wires77))
- Add support for new Ascendancy skills [\#6976](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6976) ([LocalIdentity](https://github.com/LocalIdentity), [Wires77](https://github.com/Wires77))
- Add support for Charms [\#6977](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6977) ([Regisle](https://github.com/Regisle))
- Add support for Tinctures [\#6977](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6977) ([Regisle](https://github.com/Regisle), [LocalIdentity](https://github.com/LocalIdentity), [Wires77](https://github.com/Wires77))
- Adding new 3.23 uniques [\#6983](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6983) ([Wires77](https://github.com/Wires77))
- Add support for importing new Ascendancies [\#6956](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6956), [\#6987](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6987) ([Wires77](https://github.com/Wires77))
- Save trade search weights to build file [\#6954](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6954) ([Peechey](https://github.com/Peechey))
- Remove Pastebin as a build export option [\#6970](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6970) ([LocalIdentity](https://github.com/LocalIdentity))

### User Interface
- Add support for search Configuration tab [\#6178](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6178) ([deathbeam](https://github.com/deathbeam))
- Add support for toggling ineligible configurations in Configuration tab [\#5950](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5950) ([Peechey](https://github.com/Peechey))
- Add warning when allocating too many Azmeri Ascendancy nodes [\#6958](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6958) ([Regisle](https://github.com/Regisle))

### Fixed Bugs
- Fix ES bypass Mastery overriding Divine Flesh ES bypass [\#6965](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6965) ([mortentc](https://github.com/mortentc), [Wires77](https://github.com/Wires77))
- Fix Sin Trek and Legacy of Fury disabling life mod on Utula's Hunger [\#6969](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6969) ([Lilylicious](https://github.com/Lilylicious))
- Fix Eldritch Battery with Replica Covenant cost calculations [\#6964](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6964) ([sida-wang](https://github.com/sida-wang))


## [v2.35.5](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.35.5) (2023/12/07)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.35.4...v2.35.5)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Fix reserving life with Dissolution of the Flesh affecting eHP [\#6791](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6791) ([ProFrenchToast](https://github.com/ProFrenchToast), [LocalIdentity](https://github.com/LocalIdentity))
- Fix new Ascendancies being included in node counts [\#6949](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6949) ([Lilylicious](https://github.com/Lilylicious))


## [v2.35.4](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.35.4) (2023/12/07)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.35.3...v2.35.4)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Add socket limit warning [\#6937](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6937) ([sida-wang](https://github.com/sida-wang))

### Fixed Bugs
- Fix Vortex base damage over time values [\#6945](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6945) ([LocalIdentity](https://github.com/LocalIdentity))

### Accuracy Improvements
- Fix socketed gem count calculation [\#6937](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6937) ([sida-wang](https://github.com/sida-wang))
- Fix Evasion ES Mastery mod for ES on rings [\#6944](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6944) ([Lilylicious](https://github.com/Lilylicious))
- Update Reap + Vaal Reap quality mods [\#6942](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6942) ([henbe](https://github.com/henbe))


## [v2.35.3](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.35.3) (2023/12/06)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.35.2...v2.35.3)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Fix damage taken as mods not appearing in Calcs tab breakdown [\#6932](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6932) ([Regisle](https://github.com/Regisle), [LocalIdentity](https://github.com/LocalIdentity))
- Fix Lucky Spell Suppression chance not displaying in sidebar [\#6931](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6931) ([MoonOverMira](https://github.com/MoonOverMira))
### Accuracy Improvements
- Update Splitting Steel quality mod [\#6927](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6927) ([kayokalinauskas](https://github.com/kayokalinauskas))


## [v2.35.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.35.2) (2023/12/06)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.35.1...v2.35.2)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Fix Blade Vortex gaining damage from Unleash [\#6921](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6921) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Tailwind not applying [\#6919](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6919) ([LocalIdentity](https://github.com/LocalIdentity))

### Accuracy Improvements
- Fix Ball Lightning quality stat [\#6923](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6923) ([LocalIdentity](https://github.com/LocalIdentity))
- Remove dead Divine Ire mods [\#6922](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6922) ([LocalIdentity](https://github.com/LocalIdentity))


## [v2.35.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.35.1) (2023/12/06)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.35.0...v2.35.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Crashes
- Fix crash when importing skill tree from account [\#6915](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6915) ([Peechey](https://github.com/Peechey))
### Fixed Bugs
- Fix eHP calculations when using 'x damage taken as y' mods [\#6916](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6916) ([LocalIdentity](https://github.com/LocalIdentity))


## [v2.35.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.35.0) (2023/12/06)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.34.1...v2.35.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Add 3.23 Tree [\#6880](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6880), [\#6882](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6882), [\#6905](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6905) ([LocalIdentity](https://github.com/LocalIdentity), [Regisle](https://github.com/Regisle))
- Add support for new Ascendancy nodes [\#6893](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6893) ([LocalIdentity](https://github.com/LocalIdentity))
- Update + add support for new uniques from 3.23 [\#6883](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6883) ([sida-wang](https://github.com/sida-wang))
- Update some gems with 3.23 changes [\#6896](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6896), [\#6897](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6897) ([LocalIdentity](https://github.com/LocalIdentity), [Lilylicious](https://github.com/Lilylicious))
  - Arc + Vaal Arc, Blade Vortex + Vaal Blade Vortex, Bladefall, Boneshatter, Cobra Lash, Cold Snap + Vaal Cold Snap, Crackling Lance,
	Cyclone, Discharge, Divine Ire, Double Strike, Dual Strike, Explosive Trap, Freezing Pulse, Frenzy, General's Cry, Glacial Cascade,
	Golems skills, Ice Crash, Ice Nova + Vaal Ice Nova, Ice Spear, Kinetic Blast, Lightning Conduit, Penance Brand, 
	Power Siphon + Vaal Power Siphon, Righteous Fire + Vaal Righteous Fire, Spark, Spectral Helix, Spectral Shield Throw, Spectral Throw,
	Spellslinger, Split Arrow, Splitting Steel, Static Strike, Summon Holy Relic, Vortex
- Update experimental base types [\#6896](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6896) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Guardian's Elemental Relic Auras [\#6745](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6745) ([Regisle](https://github.com/Regisle))
- Add support for Intuitive Link [\#6732](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6732) ([Paliak](https://github.com/Paliak))
- Add support for Shrapnel Ballista's shotgunning [\#6751](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6751) ([Regisle](https://github.com/Regisle))
- Add support for enemy skill damage conversion [\#6652](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6652) ([Regisle](https://github.com/Regisle))
- Add support for enemy Resistance config to increase max res [\#6834](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6834) ([Regisle](https://github.com/Regisle))
- Add support for enemy Impale [\#6810](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6810) ([Regisle](https://github.com/Regisle))
- Add support for Anomalous Sacrifice support [\#6807](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6807) ([lepideble](https://github.com/lepideble))
- Add support for Divergent Temporal Rift [\#6823](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6823) ([Regisle](https://github.com/Regisle))
- Add support for reduced Wither effect on self [\#6811](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6811) ([Regisle](https://github.com/Regisle))
- Add support for 'if Corrupted' mod condition [\#6878](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6878) ([Paliak](https://github.com/Paliak))

### Fixed Crashes
- Fix crash when allocating Tawhoa's Chosen and adding gems to a build [\#6726](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6726) ([Paliak](https://github.com/Paliak))
- Fix crash when triggering a minion skill with Arcanist Brand [\#6852](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6852) ([Paliak](https://github.com/Paliak))
- Fix crash when triggering a skill with CwC in a staff [\#6792](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6792) ([Paliak](https://github.com/Paliak))
- Fix crash when opening help section from build list [\#6816](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6816) ([Regisle](https://github.com/Regisle))
- Fix crash when searching for a Timeless Jewel after selecting a Devotion mod [\#6858](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6858) ([Lothrik](https://github.com/Lothrik))
- Fix rare crash caused by forcing active an inactive group containing a trigger setup [\#6898](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6898) ([Paliak](https://github.com/Paliak))
- Fix rare crash when trying to save a build [\#6800](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6800) ([Paliak](https://github.com/Paliak))

### User Interface
- Add the ability to customize the colour of the tree search highlight circle [\#6866](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6866) ([admSla](https://github.com/admSla))
- Widen build selection list [\#6841](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6841) ([pHiney](https://github.com/pHiney))
- Add support for showing Split count for Projectiles [\#6738](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6738) ([Regisle](https://github.com/Regisle))
- Update text colour for some already supported mods on Gems [\#6749](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6749) ([Regisle](https://github.com/Regisle))
- Fix stat tooltip when hovering over nodes inside of Intuitive Leap / Thread of Hope [\#6717](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6717) ([Paliak](https://github.com/Paliak))
- Fix Bear Trap not appearing in Debuff section [\#6900](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6900) ([Paliak](https://github.com/Paliak))

### Fixed Bugs
- Fix Maven Slam + Exarch Ball damage being affected Suppression [\#5754](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5754) ([Regisle](https://github.com/Regisle))
- Remove the normalisation of 'x damage taken as y' mods if they total to over 100% [\#6844](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6844) ([Regisle](https://github.com/Regisle))
  - Do not have more than a total of 100% physical damage taken as mods!
- Fix Hit Chance applying twice to CoC trigger rate calculations [\#6779](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6779) ([Paliak](https://github.com/Paliak))
- Fix Channeled Melee or Attacks halving Trigger rate when Dual Wielding [\#6894](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6894) ([Lilylicious](https://github.com/Lilylicious))
- Fix Chieftain's Ngamahu, Flame's Advance node not working with Forbidden Flesh and Flame [\#6716](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6716) ([Paliak](https://github.com/Paliak))
- Fix Arcane Cloak not affecting max hit [\#6704](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6704) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Projectile mastery not adding damage to Ailments [\#6902](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6902) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Ice Golem's Ice Spear skill not being supported by Spell Echo [\#6740](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6740) ([Paliak](https://github.com/Paliak))
- Fix Accuracy rating against enemy mods affecting Accuracy stat [\#6711](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6711) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Flasks applying twice if using Ceinture of Benevolence [\#6757](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6757) ([Regisle](https://github.com/Regisle))
- Fix Widowhail multiplying mods individually and oddly interacting with weapon swaps [\#6879](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6879) ([Paliak](https://github.com/Paliak))
- Fix Slavedriver's Hand Bloodmagic mod not working [\#6793](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6793) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix rare incorrect calculations bug when Mirages use forced active skills [\#6910](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6910) ([Paliak](https://github.com/Paliak))
- Fix fullDPS not working with Flamewood [\#6899](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6899) ([Paliak](https://github.com/Paliak))
- Fix Banner Aura debuff not applying in all cases [\#6780](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6780) ([Regisle](https://github.com/Regisle))
- Fix some Banner and Consecrated Ground mods not applying to allies [\#6836](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6836) ([Regisle](https://github.com/Regisle))
- Fix Holy Relic Nova spell when triggered by Static Strike [\#6678](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6678) ([Paliak](https://github.com/Paliak))

### Accuracy Improvements
- Don't reorder gems on import if socketed into Dialla's Malefaction body armour [\#6727](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6727) ([Paliak](https://github.com/Paliak))
- Fix some Cluster Jewel nodes not being allocated on import (does not fix it completely) [\#6701](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6701) ([Wires77](https://github.com/Wires77))
- Fix Mantra of Flames not counting stacks from Trauma or Voltaxic Burst [\#6758](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6758) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix parsing for many Explode mods [\#6724](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6724) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Honoured Tattoo of the Tuatara interaction with stat conversion jewels [\#6712](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6712) ([Peechey](https://github.com/Peechey))
- Fix Summon Sentinel of Radiance having 2 burning area skills [\#6747](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6747) ([Regisle](https://github.com/Regisle))
- Fix Prismatic burst, Shockwave and Combust not listing the correct trigger skill [\#6733](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6733) ([Paliak](https://github.com/Paliak))
- Fix negative Duration values [\#6725](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6725) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix negative Damage taken Over Time values [\#6802](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6802) ([Regisle](https://github.com/Regisle))
- Fix a few 'Regen every 4 seconds' mods [\#6775](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6775) ([Regisle](https://github.com/Regisle))
- Fix Affliction charges not affecting some ailment magnitudes [\#6801](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6801) ([Paliak](https://github.com/Paliak))
- Fix Flame Wall added Fire Damage Enchant values [\#6794](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6794) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Phantasmal Flameblast AoE values [\#6813](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6813) ([LocalIdentity](https://github.com/LocalIdentity))
- Update against damage over time to apply the modFlag directly [\#6805](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6805) ([Regisle](https://github.com/Regisle))
- Increase accuracy of defensive calculations for damage over time when using Divine Flesh and Tempered by War [\#6803](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6803) ([Regisle](https://github.com/Regisle))


## [v2.34.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.34.1) (2023/09/16)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.34.0...v2.34.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Crashes
- Fix crash when using Saviour Mirages in Full DPS [\#6677](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6677) ([Paliak](https://github.com/Paliak))
- Fix crash when using Cast when Channeling with Whispering Ice [\#6681](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6681) ([Paliak](https://github.com/Paliak))
### User Interface
- Update tooltip wording for Magmatic Strikes config [\#6689](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6689) ([Paliak](https://github.com/Paliak))
- Show Warcry calculation mode when using Fist of War [\#6691](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6691) ([Paliak](https://github.com/Paliak))
### Fixed Bugs
- Fix curse mods from The Felbog Fang and Fated End applying to Mark skills [\#6687](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6687) ([Paliak](https://github.com/Paliak))
- Fix Fist of War not applying to Projectile skill parts [\#6693](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6693) ([Paliak](https://github.com/Paliak))
- Fix Divergent Arcane Cloak not scaling properly with buff effect [\#6695](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6695) ([LocalIdentity](https://github.com/LocalIdentity))
### Accuracy Improvements
- Increase accuracy of Doom Blast calculations [\#6676](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6676) ([Paliak](https://github.com/Paliak))
- Fix parsing for some mods on the Pantheon [\#6686](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6686) ([Paliak](https://github.com/Paliak))
- Assume 1 stage by default for Sigil of Power [\#6692](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6692) ([Paliak](https://github.com/Paliak))
- Fix Scorching Ray max stages calculation [\#6697](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6697) ([LocalIdentity](https://github.com/LocalIdentity))



## [v2.34.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.34.0) (2023/09/13)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.33.5...v2.34.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Implement new 3.22.1 Tattoos [\#6611](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6611) ([Wires77](https://github.com/Wires77))
- Add icons to Socket groups based on the item slot [\#6339](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6339) ([ryuukk](https://github.com/ryuukk))
- Substantially improve startup time [\#6607](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6562), [\#6635](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6635), [\#6607](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6607) ([Lancej](https://github.com/Lancej))
- Add support for limiting Node depth in Power Report generation [\#6598](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6598) ([Subtractem](https://github.com/Subtractem))
- Party tab improvements ([\#6636](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6636), [\#6143](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6143), [\#6670](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6670) ([Regisle](https://github.com/Regisle))
  * Add support for Link Skills
  * Add support for enemy conditions
  * Add support for Mine Aura's
  * Fix Vaal Aura's preventing base Aura from applying
  * Fix Doryani's Prototype, Ambu's Charge and Eye of Malice
  * Sort lists in alphabetical order
- Add support for applying Link skills to minions [\#5959](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5959), [\#6672](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6672) ([Regisle](https://github.com/Regisle))
- Add support for importing trees from poeplanner.com [\#6280](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6280) ([pHiney](https://github.com/pHiney))
- Add support for Maata's Teaching crit mod [\#6651](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6651) ([Regisle](https://github.com/Regisle))
- Add support for Momentum Support [\#6092](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6092) ([Regisle](https://github.com/Regisle))
- Add support for more Map mods [\#6626](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6626), [\#6139](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6139), [\#6626](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6626) ([Regisle](https://github.com/Regisle))
- Add support for more Stun duration mods [\#6228](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6228) ([Regisle](https://github.com/Regisle))
- Add support for ignoring weapon swap on character import [\#6503](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6503) ([Peechey](https://github.com/Peechey))
### Fixed Crashes
- Fix crash when triggering skills with Unique weapons [\#6572](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6572) ([Paliak](https://github.com/Paliak))
- Fix crash caused by trigger source being disabled [\#6560](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6560) ([Paliak](https://github.com/Paliak))
- Fix crash [\#6565](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6565) ([Paliak](https://github.com/Paliak))
### User Interface
- Add remove account button to the Import tab [\#6641](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6641) ([CrazieJester](https://github.com/CrazieJester))
- Add max equip level field to the trade query generator [\#6595](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6595) ([Kerberos9](https://github.com/Kerberos9))
- Display AoE values as metres [\#6624](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6624) ([LocalIdentity](https://github.com/LocalIdentity))
- When using F1 to open the Help window, show info for the current tab [\#6648](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6648) ([Regisle](https://github.com/Regisle))
- Add support for item Enchantment comparison when hovering over the list [\#6532](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6532) ([Peechey](https://github.com/Peechey))
- Add confirmation popup when converting Skill Trees [\#6371](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6371) ([Peechey](https://github.com/Peechey))
- Add documentation for the Skills tab to Help window [\#6660](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6660) ([nrardin](https://github.com/nrardin))
- Show version and branch in error box [\#6639](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6639) ([Lancej](https://github.com/Lancej))
### Fixed Bugs
- Fix Doom Blast trigger rate calculations [\#6568](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6568) ([Paliak](https://github.com/Paliak))
- Fix skill Mana/Life cost calculations when using Mana cost conversion Life Mastery [\#6220](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6220) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Utula's Hungers Life mod not working with some Uniques added from PoB [\#6569](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6569) ([Lilylicious](https://github.com/Lilylicious))
- Fix Utula's Hungers Life mod not working if you had life on Jewels [\#6556](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6556) ([Lilylicious](https://github.com/Lilylicious))
- Fix Fresh Meat Support incorrectly granting all Minions Adrenaline [\#6559](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6559) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Cast Speed not increasing the activation frequency of Arcanist Brand [\#6547](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6547) ([Paliak](https://github.com/Paliak))
- Fix FullDPS issues when using Mirage Archer or Minions [\#6566](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6566) ([Paliak](https://github.com/Paliak))
- Fix Energy Blade alt qualities failing to apply twice when Dual Wielding [\#6585](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6585) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Ahuana's Bite only increasing Cold damage taken instead of all damage taken [\#6610](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6610) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix CWDT calculations when linked to multiple skills [\#6615](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6615) ([Paliak](https://github.com/Paliak))
- Fix Kitava's Thirst trigger rate when Dual Wielding [\#6608](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6608) ([Paliak](https://github.com/Paliak))
- Fix Trauma Rate doubling when Dual Wielding [\#6623](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6623) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix +1 to Socketed Skill gems mod not working [\#6632](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6632) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix trigger rate for Tawhoa's Chosen [\#6665](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6665) ([Dogist](https://github.com/Dogist))
### Accuracy Improvements
- Add a legacy tag to Cluster Jewels that no longer drop [\#6604](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6604) ([LocalIdentity](https://github.com/LocalIdentity))
- Add missing variant  to Tulborn [\#6573](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6573) ([pHiney](https://github.com/pHiney))
- Fix typo in Death Rush ring [\#6576](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6576) ([Lancej](https://github.com/Lancej))
- Fix typo in Ashrend body armour [\#6578](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6578) ([Lancej](https://github.com/Lancej))
- Fix Ahuana's Bite 'Chill as though dealing' mod [\#6591](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6591) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix chance to Inflict ailments breakdown [\#6586](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6586) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix breakdown for skills that grant Ailment Immunities [\#6584](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6584) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix extra Abyssal socket appearing on Stygian Vise and Darkness Enthroned belts [\#6550](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6550) ([Lilylicious](https://github.com/Lilylicious))
- Fix some mod ranges being inverted [\#6549](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6549) ([Lilylicious](https://github.com/Lilylicious))
- Fix wording on Uul-Netol's Vow [\#6613](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6613) ([Wires77](https://github.com/Wires77))
- Fix negative EHP values from Progenesis Flask by capping its effect [\#6673](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6673) ([Regisle](https://github.com/Regisle))
- Fix calculation of increased cooldown reduction breakpoint suggestions [\#6570](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6570) ([Paliak](https://github.com/Paliak))
### Other changes
- Reduce memory usage when on the tree tab [\#6631](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6631) ([Lancej](https://github.com/Lancej))
- Add option to disable Lua JIT [\#6644](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6644) ([Lancej](https://github.com/Lancej))
- Fix Unicode input for PoeCharm [\#6669](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6669) ([Lancej](https://github.com/Lancej))

## [v2.33.5](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.33.5) (2023/08/28)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.33.4...v2.33.5)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Crashes
- Fix crash when triggering a Skill from a Weapon ([LocalIdentity](https://github.com/LocalIdentity))


## [v2.33.4](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.33.4) (2023/08/28)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.33.3...v2.33.4)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Crashes
- Fix crash when using Kitava's Thirst [\#6531](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6531) ([Paliak](https://github.com/Paliak))
- Fix crash when loading some 3.20 builds [\#6525](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6525) ([Peechey](https://github.com/Peechey))
### Fixed Bugs
- Temporarily Revert trigger rate calculations to old formula [\#6530](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6530) ([Paliak](https://github.com/Paliak))
- Fix Doom Blast overlap count not affecting DPS [\#6541](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6541) ([Paliak](https://github.com/Paliak))
- Fix Skill Effect Duration affecting Totem duration [\#6536](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6536) ([Paliak](https://github.com/Paliak))
- Prevent Tawhoa's Chosen Attacks from being Exerted [\#6535](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6535) ([Paliak](https://github.com/Paliak))
- Fix crash when adding Support gems to some skills [\#6510](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6510) ([Paliak](https://github.com/Paliak))
- Fix Mirage Archer disabling skills supported by Manaforged Arrows [\#6521](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6521) ([Paliak](https://github.com/Paliak))



## [v2.33.3](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.33.3) (2023/08/26)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.33.2...v2.33.3)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Fix Replica Dragonfang's Flight not providing levels to Vaal versions of a skill [\#6512](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6512) ([Paliak](https://github.com/Paliak))
- Fix Full DPS not working for skills granted by items e.g. Arakaali's Fang  [\#6511](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6511) ([Paliak](https://github.com/Paliak))
- Fix Militant Faith jewel not overriding small attribute tattoos [\#6514](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6514) ([LocalIdentity](https://github.com/LocalIdentity))



## [v2.33.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.33.2) (2023/08/25)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.33.1...v2.33.2)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Crashes
- Fix Flamewood Support crash when selecting Support gems [\#6499](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6499) ([Paliak](https://github.com/Paliak))
- Fixed crash when searching trade for Jewels with Chieftain's Ngamahu Ascendancy allocated [\#6502](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6502) ([Tivorak](https://github.com/Tivorak))
### Fixed Bugs
- Fix Spellblade Support not adding damage before level 14 [\#6504](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6504) ([Wires77](https://github.com/Wires77))
- Fix Flamewood support not scaling with Spell and Projectile damage [\#6505](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6505) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Flamewood Support being disabled by Ancestral Bond [\#6499](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6499) ([Paliak](https://github.com/Paliak))


## [v2.33.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.33.1) (2023/08/25)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.33.0...v2.33.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Crashes
- Fix crash when using a trigger Wand mod [\#6486](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6486) ([Paliak](https://github.com/Paliak))
- Fix crash when using a trigger Helmet Focus mod [\#6486](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6486) ([Paliak](https://github.com/Paliak))
- Fix crash when using Flamewood Support [\#6486](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6486) ([Paliak](https://github.com/Paliak))
### User Interface
- Display Channel time in the sidebar for Skills triggered by Snipe [\#6486](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6486) ([Paliak](https://github.com/Paliak))
### Fixed Bugs
- Fix Hungry Loop not recognising Elemental Army [\#6489](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6489) ([Paliak](https://github.com/Paliak))
- Fix separate Totem Duration affecting Skill Duration [\#6488](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6488) ([Paliak](https://github.com/Paliak))
- Fix Melding of the Flesh not working correctly with Chieftain Valako ascendancy [\#6490](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6490) ([Paliak](https://github.com/Paliak))
- Fix Flamewood Support not being affected by Totem mods [\#6487](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6487) ([Paliak](https://github.com/Paliak))



## [v2.33.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.33.0) (2023/08/25)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.32.2...v2.33.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Support for triggered skills has been reworked [\#6468](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6468) ([Paliak](https://github.com/Paliak))
    * Calculations of effective triggered skills trigger rate should now be more accurate
    * Improve cooldown breakpoint interactions with skills that add Cast time
    * Implemented all currently existing trigger skills that POB is capable of supporting. Including:
        * CWDT
        * Spell Slinger
        * Counter-attack skills
        * Arcanist brand
        * Tawhoa's Chosen
        * Battlemage's Cry
* Add support for Trigger Bots
* Add support for Flamewood Support
- Add Support for Guardian's minion RF skill [\#6479](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6479) ([LocalIdentity](https://github.com/LocalIdentity))
### Fixed Crashes
- Fix crash when using Ruthless Support in a Poison build [\#6473](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6473) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix crash when trying to edit Energy Blade weapon [\#6446](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6446) ([Wires77](https://github.com/Wires77))
- Fix crash when viewing resist breakdown while having Chieftains Valako Ascendancy [\#6460](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6460) ([Paliak](https://github.com/Paliak))
### User Interface
- Trigger related breakdowns should now be more descriptive [\#6468](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6468) ([Paliak](https://github.com/Paliak))
- Improve breakdowns for skills that add Cast time [\#6468](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6468) ([Paliak](https://github.com/Paliak))
- Display Cast when Damage Taken threshold in the trigger rate section [\#6468](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6468) ([Paliak](https://github.com/Paliak))
### Accuracy Improvements
- Fix inaccuracies caused by incorrect handling of skill cooldown during skill rotation simulation [\#6468](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6468) ([Paliak](https://github.com/Paliak))
- Triggers should now correctly account for source rate modifiers such as crit chance and accuracy [\#6468](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6468) ([Paliak](https://github.com/Paliak))
- Fix many self triggers counting as self-cast [\#6468](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6468) ([Paliak](https://github.com/Paliak))
- Fix incorrect handling of gems supported by more than one trigger [\#6468](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6468) ([Paliak](https://github.com/Paliak))
### Fixed Bugs
- Fix Volatility from applying multiple times when conversion is present [\#6464](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6464) ([Regisle](https://github.com/Regisle))
- Fix Chain count box not appearing sometimes [\#6471](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6471) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Cold Exposure mastery not working correctly [\#6472](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6472) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix gems not benefiting from Supports sometimes [\#6474](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6474) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Trauma Duration sometimes using skill Duration [\#6475](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6475) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Strength of Blood Keystone not working [\#6478](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6478) ([LocalIdentity](https://github.com/LocalIdentity))



## [v2.32.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.32.2) (2023/08/24)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.32.1...v2.32.2)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Bug Fixes
- Fix crash caused by usage of incorrect breakdown table [\#6452
](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6452
) ([Paliak](https://github.com/Paliak))
- Fix lua error when hovering Ascendant nodes [\#6454
](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6454
) ([Wires77](https://github.com/Wires77))



## [v2.32.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.32.1) (2023/08/24)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.32.0...v2.32.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Fix crash when opening some minion builds
- Fix Timeless jewel stats disappearing when applying a tattoo

## [v2.32.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.32.0) (2023/08/24)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.31.2...v2.32.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Add support for tattoos [\#6396](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6396) ([Wires77](https://github.com/Wires77))
- Add support for Ruthless tree [\#6367](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6367) ([Wires77](https://github.com/Wires77))
* Add support for 3.22 skill gems by [\#6418](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6418), [\#6431](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6431), [\#6436](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6436), [\#6443](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6443), [\#6425](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6425), ([LocalIdentity](https://github.com/LocalIdentity), [Lilylicious](https://github.com/Lilylicious), [Regisle](https://github.com/Regisle), [Paliak](https://github.com/Paliak), [Wires77](https://github.com/Wires77), [deathbeam](https://github.com/deathbeam))
  * Full Support
  * Locus Mine
  * Devour
  * Volatility
  * Sadism
  * Spellblade
  * Trauma
  * Corrupting Cry
  * Frigid Bond
  * Guardian's Blessing
  * Fresh Meat
  * Sacrifice
  * Controlled Blaze
- Add support for new Chieftain and Guardian ascendancy nodes [\#6288](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6288) ([Paliak](https://github.com/Paliak))
- Add initial support for Guardian minion nodes [\#6445](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6445) ([LocalIdentity](https://github.com/LocalIdentity))
- Add self-hit calculations for Scolds Bridle, Eye of Innocence and Heartbound Loop [\#6250](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6250) ([Paliak](https://github.com/Paliak))
- Add support for new Ancestor uniques [\#6426](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6426) ([LocalIdentity](https://github.com/LocalIdentity), [Wires77](https://github.com/Wires77))
- Improve startup time [\#6407](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6407) ([Lancej](https://github.com/Lancej))
### User Interface
- Help section improvements [\#6156](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6156) ([Regisle](https://github.com/Regisle))
- Add immunity flags to defence avoidance breakdown [\#6389](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6389) ([Paliak](https://github.com/Paliak))
- Removing allocated mastery from hover list [\#6374](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6374) ([Wires77](https://github.com/Wires77))
- Improve sync of tree version and version dropdown [\#6365](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6365) ([Peechey](https://github.com/Peechey))
### Fixed Bugs
- Fix nodes not being able to be allocated after converting a tree [\#6364](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6364) ([Peechey](https://github.com/Peechey))
- Fix totem duration mods not applying [\#6388](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6388) ([Paliak](https://github.com/Paliak))
- Fix DPS on Vaal Flicker when using 2x 1h weapons [\#6380](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6380) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Repeat count for minion skills [\#6376](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6376) ([Wires77](https://github.com/Wires77))
- Fix Snipe damage going negative [\#6399](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6399) ([Paliak](https://github.com/Paliak))
- Fix Snipe showing DPS values when triggering support skills [\#6415](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6415) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Doom Blast not working with Forbidden Shako [\#6393](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6393) ([Paliak](https://github.com/Paliak))
- Fix Bleed/Ignite Stack potential issues [\#6386](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6386) ([LocalIdentity](https://github.com/LocalIdentity))
### Accuracy Improvements
- Update 3.22 skill tree [\#6411](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6411) ([Regisle](https://github.com/Regisle))
- Allow setting inspiration charges to 0 [\#6421](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6421) ([Paliak](https://github.com/Paliak))
- Fix "Enemies maimed by you take inc damage over time" not in breakdown display [\#6400](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6400) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Pierce and Chain count config not appearing sometimes [\#6401](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6401) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix lower channel time stat using red text [\#6381](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6381) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix incorrect increased usage mod range on Cinderswallow Urn [\#6434](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6434) ([Paliak](https://github.com/Paliak))


## [v2.31.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.31.2) (2023/08/16)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.31.1...v2.31.2)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
* Fix issue when importing characters by @Wires77
* Fix typo with Ignite Stack Potential Override by @Wires77


## [v2.31.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.31.1) (2023/08/16)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.31.0...v2.31.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### User Interface
- Lower contrast of gem select highlight [\#6338](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6338) ([ryuukk](https://github.com/ryuukk))
### Accuracy Improvements
- Undo incorrect Explosive Arrow change [\#6335](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6335) ([Lilylicious](https://github.com/Lilylicious))
- Fix Frozen Legion benefiting from exerts [\#6331](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6331) ([Lilylicious](https://github.com/Lilylicious))
- Fix Combustion debuff not applying when a non-damaging skill precedes a damaging skill [\#6344](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6344) ([Lilylicious](https://github.com/Lilylicious))
- Fix Blood Sacrament not being capped by Cooldown [\#6351](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6351) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Tree conversion stopping you from allocating some tree nodes [\#6352](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6352) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Mana cost when using 'Wait for max unleash seals' [\#6333](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6333) ([busterw](https://github.com/busterw))


## [v2.31.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.31.0) (2023/08/15)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.30.1...v2.31.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Add 3.22 Skill tree [\#6313](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6313) ([Regisle](https://github.com/Regisle))
- Add proper support for DPS with Scourge Arrow, Divine Ire, Flameblast and Incinerate [\#6245](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6245) ([LocalIdentity](https://github.com/LocalIdentity))
- Display Channel time for skills that channel and release (Scourge Arrow, Divine Ire, Flameblast, Incinerate and Snipe) [\#6245](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6245) ([LocalIdentity](https://github.com/LocalIdentity))
- Add proper support for triggered skills with Snipe Support [\#6248](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6248) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Flamethrower Trap DPS [\#6307](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6307) ([Lilylicious](https://github.com/Lilylicious))
- Fix weighted average DPS calculation of Ignite/Bleed [\#6321](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6321) ([LocalIdentity](https://github.com/LocalIdentity))
- Show min/max DPS range for Ignite/Bleed/Poison [\#6321](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6321) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for cooldown on skills in Black Zenith gloves [\#6247](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6247) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Crucible min stages and Cooldown mods with Incinerate/Flameblast [\#6246](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6246) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for changing Tree Version [\#6312](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6312) ([Peechey](https://github.com/Peechey))
- Add clear button to text inputs [\#6282](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6282) ([TPlant](https://github.com/PJacek))
### Implemented Enhancements
- Remove Minimum Ignite Duration [\#6326](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6326) ([LocalIdentity](https://github.com/LocalIdentity))
- Imply recent Minion skill use only when using non-permanent Minions [\#6309](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6309) ([Lilylicious](https://github.com/Lilylicious))
- Improve PvP breakdowns [\#6276](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6276) ([Regisle](https://github.com/Regisle))
- Only apply Combustion Fire Resistance effect with skills that can Ignite [\#6320](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6320) ([Lilylicious](https://github.com/Lilylicious))
- Add parsing for Redeemer 'Freeze as though Dealing more Damage' mod [\#6198](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6198) ([fira](https://github.com/fira))
### Fixed Crashes
- Fix crash on 100% reduced reservation efficiency for Relic of the Pact [\#6303](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6303) ([Lilylicious](https://github.com/Lilylicious))
- Fix crash on unusable weapon swap [\#6300](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6300) ([Lilylicious](https://github.com/Lilylicious))
- Fix crash sometimes occurring when searching for Timeless Jewel [\#6242](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6242) ([Regisle](https://github.com/Regisle))
- Fix crash when hovering over life mastery mod [\#6252](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6252) ([Paliak](https://github.com/Paliak))
### User Interface
- Add a warning when exceeding jewel limits [\#6308](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6308) ([Lilylicious](https://github.com/Lilylicious))
- Make build search immediate [\#6283](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6283) ([TPlant](https://github.com/PJacek))
- Add Ctrl-M to the tree drop-down to open 'Manage Trees' dialog [\#6269](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6269) ([pHiney](https://github.com/pHiney))
- Force skill groups to display as active based on main skill [\#6317](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6317) ([Lilylicious](https://github.com/Lilylicious))
- Fix division by zero display error in resource recovery calculations [\#6264](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6264) ([TPlant](https://github.com/PJacek))
- Add Help documentation for Items tab [\#6223](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6223) ([karlji](https://github.com/karlji))
- Add name to top left Timeless Jewel socket [\#6225](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6225) ([karlji](https://github.com/karlji))
### Accuracy Improvements
- Fix Explosive Arrow Full DPS [\#5432](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5432) ([AnSq](https://github.com/AnSq))
- Fix Explosive Arrow stages scaling base damage effectiveness [\#6302](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6302) ([Lilylicious](https://github.com/Lilylicious))
- Fix Flameblast not gaining 'more' damage from first stage [\#6261](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6261) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Supreme Ego taking effect with Blood Magic [\#6199](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6199) ([mortentc](https://github.com/mortentc))
- Fix Lancing Steel hit rate calculations [\#6310](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6310) ([Lilylicious](https://github.com/Lilylicious))
- Fix default Uber boss Evasion Rating [\#6270](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6270) ([ghember](https://github.com/ghember))
- Fix defences on normal and magic Two-Toned Boots [\#6230](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6230) ([Peechey](https://github.com/Peechey))
- Fix Matua Tupuna's aura mod not affecting minions [\#6315](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6315) ([Paliak](https://github.com/Paliak))
- Fix Battlemage's Cry and Redblade Banner not working correctly [\#6301](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6301) ([Lilylicious](https://github.com/Lilylicious))
- Fix multiple instances of 'x stat is increased by overcapped y resistance' stacking [\#6299](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6299) ([Lilylicious](https://github.com/Lilylicious))
- Fix Shock Nova's 'max effect of shock' not benefiting other skills [\#6295](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6295) ([Lilylicious](https://github.com/Lilylicious))
- Fix Adjacent Animosity to work with both Attacks and Spells [\#6266](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6266) ([deathbeam](https://github.com/deathbeam))
- Fix Crucible AoE mod from applying to any skill [\#6251](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6251) ([Paliak](https://github.com/Paliak))
- Fix Energy Shield Stun avoidance if EB allocated [\#6249](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6249) ([Paliak](https://github.com/Paliak))
- Fix Spellslinger Reservation incorrectly scaling with stages [\#6286](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6286) ([mortentc](https://github.com/mortentc))
- Fix Infernal Legion ignoring support gem damage modifiers [\#6322](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6322) ([Paliak](https://github.com/Paliak))
- Fix anointed nodes doubling stats when inside radius Jewels [\#6278](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6278) ([Paliak](https://github.com/Paliak))
- Fix Life Mastery not working correctly with Skin of the Loyal [\#6291](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6291) ([Paliak](https://github.com/Paliak))
- Fix Chain count not appearing on Calcs page [\#6205](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6205) ([LocalIdentity](https://github.com/LocalIdentity))
### Fixed Bugs
- Fix sorting of taken damage values when using the power report [\#6306](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6306) ([QuickStick123](https://github.com/QuickStick123))
- Fix resistance penalty not saving [\#6292](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6292) ([Paliak](https://github.com/Paliak))
- Fix import of Forbidden Flesh/Flame when you did not match the class of the jewel [\#6293](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6293) ([Paliak](https://github.com/Paliak))
- Fix incorrect keystone source on keystones coming from items [\#6257](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6257) ([Paliak](https://github.com/Paliak))
### Other changes
- Improve load time when opening PoB [\#6224](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6224) ([Lancej](https://github.com/Lancej))


## [v2.30.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.30.1) (2023/05/05)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.30.0...v2.30.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Fix Spell Suppression being doubled with some weapon combinations [\#6196](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6196) ([mortentc](https://github.com/mortentc))


## [v2.30.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.30.0) (2023/05/05)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.29.0...v2.30.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Add support for Vaal Absolution + Vaal Domination [\#6183](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6183) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Energy Leech with Minions [\#6163](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6163) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Garb of the Ephemeral "nearby" mods [\#6144](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6144) ([Regisle](https://github.com/Regisle))
- Add support for Shapers and Maddening Presence mods [\#6144](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6144) ([Regisle](https://github.com/Regisle))
- Add cooldown value to Twister ([LocalIdentity](https://github.com/LocalIdentity))
### Fixed Crashes
- Fix crash when searching for Timeless Jewel and using filter nodes [\#6170](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6170) ([Regisle](https://github.com/Regisle))
- Fix error on disabling node power mid-generation [\#6182](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6182) ([Lilylicious](https://github.com/Lilylicious))
### User Interface
- Fix Ailments breakdown showing crit damage while you have Resolute Technique [\#6164](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6164) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix display bug for Betrayal uniques [\#6155](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6155) ([Peechey](https://github.com/Peechey))
### Fixed Bugs
- Fix Firesong and Stormshroud effects persisting after being removed from your character [\#6145](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6145) ([Lilylicious](https://github.com/Lilylicious))
- Fix local Flask effect mods not working with Mother's Embrace and Umbilicus Immortalis [\#6181](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6181) ([Regisle](https://github.com/Regisle))
- Fix Sceptres and Fishing Rods having some incorrect mods in the item crafter [\#6185](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6185) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix calculation of hybrid Mana + Life costs [\#6179](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6179) ([mortentc](https://github.com/mortentc))
- Fix Ailment avoid chance not rounding down when using Ancestral Vision [\#6174](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6174) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Suppression from Dagger mastery not working with Ancestral Vision [\#6191](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6191) ([mortentc](https://github.com/mortentc))
- Fix Trigger skills not gaining cooldown from 'CDR per x Charge' mods [\#6186](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6186) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Exsanguinate stages scaling Ignite damage when using the Crucible conversion mod [\#6161](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6161) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix socket gems mods from Ruthless appearing in the Crucible mod list [\#6192](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6192) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Cospri's Will poison mod not working [\#6157](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6157) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix player "while blind" effects working while having "Cannot be Blinded" Saboteur node [\#6162](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6162) ([LocalIdentity](https://github.com/LocalIdentity))


## [v2.29.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.29.0) (2023/04/28)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.28.0...v2.29.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Support for crafting Crucible mods on items [\#6071](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6071), [\#6104](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6104), [\#6123](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6123), [\#6077](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6077)  ([Peechey](https://github.com/Peechey), [LocalIdentity](https://github.com/LocalIdentity))
- Add ability to simulate Aura bots or curse support with new Party tab [\#4967](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4967) ([Regisle](https://github.com/Regisle))
- Add support for on-kill explosions [\#5696](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5696) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
- Add support for Vaal Firestorm, Lightning Arrow, Arctic Armour, Animate Weapon and Reap [\#6080](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6080), [\#6081](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6081), [\#6088](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6088), [\#6146](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6146), [\#6082](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6082) ([Regisle](https://github.com/Regisle), [LocalIdentity](https://github.com/LocalIdentity))
- Add ability to search for Megalomaniac in Trader [\#5714](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5714) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
- Add support for local, Essence and crafted mods in Trader [\#5735](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5735), [\#6118](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6118) ([QuickStick123](https://github.com/QuickStick123))
- Add support for hits against you overwhelm pdr [\#6110](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6110) ([QuickStick123](https://github.com/QuickStick123))
- Add support for regex OR to tree and Item search [\#5766](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5766) ([QuickStick123](https://github.com/QuickStick123))
- Add support for Master Distiller [\#6134](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6134) ([deathbeam](https://github.com/deathbeam))
- Add support for enduring flask recovery over time [\#5897](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5897) ([deathbeam](https://github.com/deathbeam))
- Add support for Damage taken from Allies life before you [\#6134](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5943)
- Add support for 'Impales to last an additional hit' mastery mod [\#6079](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6079) ([Regisle](https://github.com/Regisle))
### Fixed Crashes
- Fix infinite recursion crash with Manaforged arrows [\#6059](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6059) ([Paliak](https://github.com/Paliak))
- Fix crash when renaming tree with F2 [\#6057](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6057) ([Paliak](https://github.com/Paliak))
- Fix crash when sorting Trader results by some stats [\#6117](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6117) ([Regisle](https://github.com/Regisle))
- Fix multiple Mastery-related crashes when converting tree to new version [\#6062](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6062) ([Peechey](https://github.com/Peechey))
### User Interface
- Allow custom hex colours for positive and negative breakdown values [\#6070](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6070) ([Peechey](https://github.com/Peechey))
- Filter Timeless Jewel search by node distance [\#5741](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5741) ([Regisle](https://github.com/Regisle))
- Use nearest keystone for Timeless Jewel search name [\#6091](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6091) ([QuickStick123](https://github.com/QuickStick123))
- Improve map mod selection UI in the Configuration tab [\#6128](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6128) ([Regisle](https://github.com/Regisle))
- Add ability to sort by EHP change for gems [\#6087](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6087) ([Regisle](https://github.com/Regisle))
- Highlight borders for changed config options in config tab [\#5717](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5717) ([deathbeam](https://github.com/deathbeam))
- Adjust minimum trade weight to always show some items in results [\#5526](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5526) ([QuickStick123](https://github.com/QuickStick123))
- Fix instant Leech breakdown [\#6030](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6030) ([mortentc](https://github.com/mortentc))
- Fix colour codes leaking into formatted numbers [\#6072](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6072) ([QuickStick123](https://github.com/QuickStick123))
- Fix discontinuous mod values occurring with range tier slider [\#6056](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6056) ([QuickStick123](https://github.com/QuickStick123))
### Accuracy Improvements
- Update uniques [\#6097](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6097), [\#6038](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6038) ([QuickStick123](https://github.com/QuickStick123))
- Fix Juggernaut Unbreakable not working with Iron Reflexes + Evasion [\#6101](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6101) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Fanaticism applying to triggered skills [\#6103](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6103) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Sleight of Hand and other one-handed weapon + damage with Ailments passives [\#5923](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5923) ([Peechey](https://github.com/Peechey))
- Fix Life Mastery not including enchants [\#6068](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6068) ([Nostrademous](https://github.com/Nostrademous))
- Fix enemy chance to hit not affecting crit effect in defence calculations [\#5716](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5716) ([QuickStick123](https://github.com/QuickStick123))
- Fix burst damage when using unleash [\#6102](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6102) ([Lilylicious](https://github.com/Lilylicious))
- Fix alt quality Lacerate and Chance to Bleed Support not affecting Bleed duration [\#6116](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6116) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Bladestorm attack having 100% bleed chance [\#6115](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6115) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Vaal auras being disabled by Sublime Vision [\#6135](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6135) ([deathbeam](https://github.com/deathbeam))
- Fix local gain on hit mods [\#6130](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6130) ([QuickStick123](https://github.com/QuickStick123))
- Fix leech incorrectly auto-applying in some circumstances [\#6126](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6126) ([deathbeam](https://github.com/deathbeam))
- Fix ailment conditionals not being preemptively enabled when an ailment can be applied. [\#5948](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5948) ([Paliak](https://github.com/Paliak))
- Cap trader stat weight per mod to 100% increased [\#6121](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6121) ([QuickStick123](https://github.com/QuickStick123))
### Fixed Bugs
- Recalculate level requirement when extra skill points change [\#5947](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5947) ([Lilylicious](https://github.com/Lilylicious))
- Fix trader occasionally ignoring sort selection [\#6111](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6111) ([Edvinas-Smita](https://github.com/Edvinas-Smita))


## [v2.28.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.28.0) (2023/04/12)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Add support for Impending Doom + using it with Vixen's [\#5530](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5530) ([ha107642](https://github.com/ha107642))
- Add support for Manaforged Arrows [\#5968](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5968) ([Nostrademous](https://github.com/Nostrademous))
- Add support for 3.21 uniques [\#5999](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5999) ([QuickStick123](https://github.com/QuickStick123), [LocalIdentity](https://github.com/LocalIdentity))
- Add Forged Frostbearer Spectre [\#6014](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6014) ([LocalIdentity](https://github.com/LocalIdentity))

### Fixed Bugs
- Fix active skill mods applying to Impending Doom, Prismatic Burst, Predator and Shockwave [\#6015](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6015) ([QuickStick123](https://github.com/QuickStick123))
- Fix Petrified Blood Low Life recoverable calculation [\#6005](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6005) ([QuickStick123](https://github.com/QuickStick123))
- Fix Prismatic Burst not choosing 1 damage type for DPS [\#6022](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6022) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Chance to Bleed Support applying to Minions [\#5967](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5967) ([Peechey](https://github.com/Peechey))
- Fix 'Damage per aura' mastery incorrectly working with some gems [\#6021](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6021) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix max res Armour Mastery incorrectly applying to max Chaos res [\#6026](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6026) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Trader not calculating correct weights for hit pool [\#6010](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/6010) ([Regisle](https://github.com/Regisle))
- Fix chance to get flask charge on crit for flask breakdown [\#5856](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5856) ([deathbeam](https://github.com/deathbeam))

### Accuracy Improvements
- Update Tombfist to 3.21 [\#5998](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5998) ([QuickStick123](https://github.com/QuickStick123), [LocalIdentity](https://github.com/LocalIdentity))


## [v2.27.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.27.2) (2023/04/09)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.27.0...v2.27.2)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- Add support for Prismatic Burst [\#5969](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5969) ([Wires77](https://github.com/Wires77))
### Fixed Crashes
- Fix crash in the Trader from not having jewel data [\#5990](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5990) ([Regisle](https://github.com/Regisle))
### User Interface
- Correct display of max mana leech rate breakdown [\#5945](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5945) ([Lilylicious](https://github.com/Lilylicious))
- Fix crucible item colour [\#5989](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5989) ([QuickStick123](https://github.com/QuickStick123))
### Other changes
- Fix Flasks incorrectly having "Cannot Leech" on them [\#5981](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5981) ([Wires77](https://github.com/Wires77))
- Fix + to level of active skill gem mods not working [\#5982](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5982) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Formless Inferno, Uul-Netol's Kiss and Tulborn [\#5995](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5995) ([QuickStick123](https://github.com/QuickStick123))
- Fix Absolution Enchant Parsing [\#5980](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5980) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Snipe Support + update Assailum [\#5979](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5979) ([LocalIdentity](https://github.com/LocalIdentity))



## [v2.27.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.27.0) (2023/04/08)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.26.3...v2.27.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### New to Path of Building
- 3.21 game data update [\#5966](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5966) ([Nostrademous](https://github.com/Nostrademous))
- Add crucible modifier parsing support [\#5823](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5823) ([Nostrademous](https://github.com/Nostrademous))
- Add support for mods conditional on the modifiers of other equipped items [\#5819](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5819) ([Nostrademous](https://github.com/Nostrademous))
- Add Bloodnotch [\#5927](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5927) ([QuickStick123](https://github.com/QuickStick123))
- Set level mode to manual if default level is above 1 [\#5920](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5920) ([Lilylicious](https://github.com/Lilylicious))
- Hide the power report on loading a build and unchecking "Show node power" [\#5932](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5932) ([Lilylicious](https://github.com/Lilylicious))
- Add skill names to cost warnings [\#5931](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5931) ([Paliak](https://github.com/Paliak))
- Add support for new Low Life and Full Life Masteries [\#5904](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5904) ([Nostrademous](https://github.com/Nostrademous))
- Add support for Warcry Mastery [\#5955](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5955) ([Peechey](https://github.com/Peechey))
- Add support for repeat-based modifiers [\#5676](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5676) ([Regisle](https://github.com/Regisle))
- Add support for Saboteur Ascendancy [\#5954](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5954) ([Peechey](https://github.com/Peechey))
- Add support for "Skills Cost Life instead of 30% of Mana" Mastery [\#5913](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5913) ([Nostrademous](https://github.com/Nostrademous))
- Prompt for saving after altering the passive search string [\#5930](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5930) ([Lilylicious](https://github.com/Lilylicious))
### User Interface
- Limit separators to non-alphanumeric [\#5922](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5922) ([Lilylicious](https://github.com/Lilylicious))
### Fixed Bugs
- Fix default state validation for lists and color labels [\#5618](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5618) ([deathbeam](https://github.com/deathbeam))
- Fix tree data bug related to recovery mastery [\#5964](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5964) ([QuickStick123](https://github.com/QuickStick123))
- Fix issue where Sceptres and One Handed Maces were considered the same weapon type [\#5942](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5942) ([Peechey](https://github.com/Peechey))
- Fix Reverberation Rod to add back Controlled Destruction [\#5941](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5941) ([chx](https://github.com/chx))
- Fix Kaom's Spirit rage regen calculation behaviour [\#5951](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5951) ([Ribel38](https://github.com/Ribel38))
### Other changes
- Improve EHP calculation performance when using full DPS [\#5773](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5773) ([Regisle](https://github.com/Regisle))
- Update a few uniques for 3.21 [\#5971](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5971) ([QuickStick123](https://github.com/QuickStick123))


## [v2.26.3](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.26.3) (2023/04/05)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.26.2...v2.26.3)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Fix several Minion buffs not being calculated correctly [\#5894](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5894) ([Wires77](https://github.com/Wires77))
- Fix level-up stats from appearing on tooltips [\#5891](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5891) ([Lilylicious](https://github.com/Lilylicious))
- Fix MoM and Prevented Life loss effect interaction [\#5908](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5908) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
- Fix life loss prevention occurring on overkill damage resulting in undesired breakpoint behaviour [\#5910](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5910) ([QuickStick123](https://github.com/QuickStick123))
- Fix Ghost Reaver and Mines Leech not working [\#5888](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5888) ([QuickStick123](https://github.com/QuickStick123))
- Fix mod values on Betrayal uniques [\#5772](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5772) ([dshebib](https://github.com/dshebib))


## [v2.26.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.26.2) (2023/04/03)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.26.1...v2.26.2)

## What's Changed
### Fixed Bugs
- Fix mastery choices overlapping when they had multiple lines [\#5873](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5873) ([Wires77](https://github.com/Wires77))
- Fix gems in the Squire counting multiple times [\#5878](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5878) ([Wires77](https://github.com/Wires77))
- Fix skill stages not being editable in some cases [\#5877](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5877) ([QuickStick123](https://github.com/QuickStick123))
- Fix issue calculating defences based on overcapped resistances [\#5869](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5869) ([Regisle](https://github.com/Regisle))
- Fix Widowhail increased bonuses calculation [\#5861](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5861) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
- Fix max-hit with 100% taken as conversion [\#5865](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5865) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
- Fix Formless Inferno not increasing minion life properly [\#5874](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5874) ([Wires77](https://github.com/Wires77))



## [v2.26.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.26.1) (2023/01/03)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.25.0...v2.25.1)

## What's Changed
### Fixed Crashes
- Fix crash with Petrified Blood and eHP ([QuickStick123](https://github.com/QuickStick123))

## [v2.26.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.26.0) (2023/04/03)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.25.1...v2.26.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->
\
## What's Changed
### 3.21 Changes
- Add 3.21 tree [\#5799](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5799) ([Regisle](https://github.com/Regisle))
- Add support for new mods on the tree [\#5827](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5827), [\#5723](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5723), [\#5829](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5829), [\#5655](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5655), [\#5559](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5559), [\#1006](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/1006) ([madinsane](https://github.com/madinsane), [Paliak](https://github.com/Paliak), [QuickStick123](https://github.com/QuickStick123), [LocalIdentity](https://github.com/LocalIdentity))
- Add support for many mods on 3.21 Masteries [\#5814](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5814), [\#5834](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5834), [\#5825](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5825), [\#5833](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5833), [\#5840](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5840), [\#5841](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5841), [\#5830](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5830), [\#5818](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5818), [\#5803](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5803), [\#5808](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5808), [\#5843](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5843), [\#5842](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5842), [\#5846](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5846), [\#5828](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5828) ([Lilylicious](https://github.com/Lilylicious), [Peechey](https://github.com/Peechey), [cardbeard](https://github.com/cardbeard), [dbjorge](https://github.com/dbjorge), [MoonOverMira](https://github.com/MoonOverMira), [QuickStick123](https://github.com/QuickStick123))
- Add support for new 3.21 Uniques [\#5805](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5805), [\#5809](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5809), [\#5811](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5811), [\#5849](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5849), [\#5850](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5850), [\#5844](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5844) ([Paliak](https://github.com/Paliak), [TPlant](https://github.com/PJacek), [QuickStick123](https://github.com/QuickStick123))
- Add support for mods on uniques that were changed in 3.21 patch notes [\#5817](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5817), [\#5806](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5806) ([QuickStick123](https://github.com/QuickStick123), [ifnjeff](https://github.com/ifnjeff))
- Update Timeless Jewels to work with 3.21 tree [\#5848](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5848) ([LocalIdentity](https://github.com/LocalIdentity))

### Implemented Enhancements
- Add a Help section [\#4629](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4629) ([Regisle](https://github.com/Regisle))
- Add support for automatic character levels based on allocated nodes [\#5837](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5837) ([Lilylicious](https://github.com/Lilylicious))
- Allow Trade to weight by multiple stats [\#5507](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5507) ([Regisle](https://github.com/Regisle))
- Enable searching for Militant Faith devotion modifiers [\#5661](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5661) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
- Change pobb.in to be the default build code exporter [\#5603](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5603) ([QuickStick123](https://github.com/QuickStick123))
- Automatically apply Arcane Surge granted to you via items or nodes on the tree [\#4541](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4541) ([QuickStick123](https://github.com/QuickStick123))
- Add support for skill uses [\#5537](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5537) ([QuickStick123](https://github.com/QuickStick123))
- Add new boss skills, auto-apply uber changes if set to uber, and update non-uber pen/chaos mix [\#5612](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5612) ([Regisle](https://github.com/Regisle))
- Automatically estimate resistance penalty on import [\#5671](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5671) ([Paliak](https://github.com/Paliak))
- Update boss Armour/Evasion values and add override fields to config [\#5620](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5620) ([ybbat](https://github.com/ybbat))
- Allow for custom mod DPS multiplier (e.g 35% More DPS) [\#5670](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5670) ([Regisle](https://github.com/Regisle))
- Change Elusive to use average value by default instead of max [\#5564](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5564) ([deathbeam](https://github.com/deathbeam))
- Implement "You can't deal Damage with Skills yourself" mod from Ancestral Bond [\#5638](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5638) ([Paliak](https://github.com/Paliak))
- Add support for more mods on Precursor's emblem [\#5566](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5566) ([QuickStick123](https://github.com/QuickStick123))
- Add support for Enemy regen and Sanctum x can y [\#5565](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5565) ([QuickStick123](https://github.com/QuickStick123))
- Add support for Non-Aura cost no Life/Mana while Focused [\#5725](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5725) ([QuickStick123](https://github.com/QuickStick123))
- Add support for Cat's Stealth avoid damage [\#5728](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5728) ([QuickStick123](https://github.com/QuickStick123))
- Add support for Cane of Kulemak unveiled mods scaler [\#5685](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5685) ([Regisle](https://github.com/Regisle))
- Add support for additional cooldowns on Mirror/Blink arrow [\#5740](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5740) ([QuickStick123](https://github.com/QuickStick123))
- Automatically apply PvP multipliers to skills [\#5739](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5739) ([Regisle](https://github.com/Regisle))
- Add support for Vaal skills Soul cost and soul gain prevention [\#5742](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5742) ([Regisle](https://github.com/Regisle))
- Add support for Block chance reduction [\#5774](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5774) ([Regisle](https://github.com/Regisle))
- Add support for mods that disable other item slots [\#5664](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5664) ([Regisle](https://github.com/Regisle))
- Add support for Jewel limits [\#5666](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5666) ([Regisle](https://github.com/Regisle))

### Fixed Crashes
- Fix crash on import when an Abyss Jewel was socketed in a weapon swap weapon [\#5601](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5601) ([Paliak](https://github.com/Paliak))
- Fix issue in PoB Trader caused by sorting mode change [\#5552](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5552) ([Dullson](https://github.com/Dullson))
- Fix not being able to save trees with more than 254 nodes allocated [\#5781](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5781) ([QuickStick123](https://github.com/QuickStick123))
- Fix crash caused by very long lines on items without spaces [\#5785](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5785) ([Paliak](https://github.com/Paliak))
- Fix crash when viewing Pantheon reduced enemy Life Regen [\#5731](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5731) ([Paliak](https://github.com/Paliak))

### User Interface
- Hide config options that can be hidden by default behind conditions [\#5712](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5712) ([deathbeam](https://github.com/deathbeam))
- Improve eHP breakdown to show greater detail [\#5756](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5756) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
- Recolor mods in the 'Custom Modifiers' box to show if they are parsed or not [\#5720](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5720) ([deathbeam](https://github.com/deathbeam))
- Properly sort and group Eldritch mods in the item crafter [\#5677](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5677) ([Regisle](https://github.com/Regisle))
- Show uptime for "Enduring" Life and Mana flasks [\#5853](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5853) ([deathbeam](https://github.com/deathbeam))
- Make race uniques not show up as obtainable [\#5656](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5656) ([Regisle](https://github.com/Regisle))
- Update Trader, Item weight and sorting to use percentage change rather than absolute [\#5525](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5525) ([Regisle](https://github.com/Regisle))
- Change Blade Blast to user-configurable stages [\#5793](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5793) ([Regisle](https://github.com/Regisle))
- Add flask breakdown to Calcs tab [\#5749](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5749) ([deathbeam](https://github.com/deathbeam))
- Colourise and group defensive calc sections [\#5753](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5753) ([deathbeam](https://github.com/deathbeam))
- Add support to display coloured text in dropdowns [\#5681](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5681) ([deathbeam](https://github.com/deathbeam))
- Allow setting Blood Charges to 0 [\#5690](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5690) ([Paliak](https://github.com/Paliak))

- Fix punctuation error in Trauma calculation message [\#5574](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5574) ([Ivniinvi](https://github.com/Ivniinvi))
- Fix minor colour codes and number formatting errors in tooltips [\#5733](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5733) ([QuickStick123](https://github.com/QuickStick123))
- Fix Enabled and FullDPS checkboxes not updating when mouse shortcuts are used [\#5589](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5589) ([Dullson](https://github.com/Dullson))
- Fix Summon Skeletons enchant not appearing in filtered list [\#5643](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5643) ([Wires77](https://github.com/Wires77))
- Fix inconsistent display of additional quality and gem levels in skill group tooltip for inactive gems [\#5715](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5715) ([Paliak](https://github.com/Paliak))
- Fix cluster jewel notable compare tooltip when crafting a cluster [\#5777](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5777) ([Edvinas-Smita](https://github.com/Edvinas-Smita))

### Accuracy Improvements

- Update wording on many uniques [\#5655](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5655), [\#5684](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5684), [\#5624](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5624), [\#5623](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5623) ([QuickStick123](https://github.com/QuickStick123))
- Update Watcher's Eye Dodge mods to Suppress mods [\#5562](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5562) ([deathbeam](https://github.com/deathbeam))
- Update Vessel of Vinktar to have correct mod values [\#5800](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5800) ([DavidBindloss](https://github.com/DavidBindloss))

- Fix eHP calculation when using Eldritch Battery + Mind Over Matter + Corrupted Soul [\#5796](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5796) ([Regisle](https://github.com/Regisle))
- Fix a variety of incorrect catalyst scaling [\#4467](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4467) ([QuickStick123](https://github.com/QuickStick123))
- Fix Voltaxic missing shock effect mod [\#5561](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5561) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix missing Mana on Mindspiral [\#5616](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5616) ([QuickStick123](https://github.com/QuickStick123))
- Fix missing variant on Replica Hyrri's Truth [\#5687](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5687) ([QuickStick123](https://github.com/QuickStick123))
- Fix values of mods on Devouring Diadem [\#5567](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5567) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Vorana's March missing a fourth modifier slot [\#5776](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5776) ([hexeaktivitat](https://github.com/hexeaktivitat))
- Fix base for Saemus' gift [\#5836](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5836) ([Lilylicious](https://github.com/Lilylicious))
- Fix Entropic Devastation not having Shaper influence [\#5816](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5816) ([QuickStick123](https://github.com/QuickStick123))
- Fix support for Mace/Scepter chill Mastery node [\#5798](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5798) ([moojustice1](https://github.com/moojustice1))
- Fix range values for Point Blank / Far shot distances [\#5655](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5655) ([QuickStick123](https://github.com/QuickStick123))
- Fix Foil search to correctly assign foil to Voidborn uniques [\#5599](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5599) ([Regisle](https://github.com/Regisle))
- Fix mods incorrectly applying when wielding fishing rod [\#5691](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5691) ([QuickStick123](https://github.com/QuickStick123))
- Fix group disable not disabling support gems and two-part skills not applying support part to linked groups [\#5719](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5719) ([Paliak](https://github.com/Paliak))
- Fix Hex Master not modifying the duration of Curses to be infinite [\#5705](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5705) ([Paliak](https://github.com/Paliak))
- Fix tree version being out of date when importing character profile into an old tree [\#5768](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5768) ([QuickStick123](https://github.com/QuickStick123))
- Fix Fire Exposure/Action speed mod on Balance of Terror [\#5794](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5794) ([QuickStick123](https://github.com/QuickStick123))
- Fix Adrenaline, Her Embrace and Boot Enchant with Wilma's Requital [\#5630](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5630) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Minion overwhelm mastery incorrectly applying to spells [\#5672](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5672) ([Paliak](https://github.com/Paliak))
- Fix Galvanic Field shock effect scaling all damage instead of only hits [\#5692](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5692) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix ignite chance display [\#5645](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5645) ([raylu](https://github.com/raylu))
- Fix player-specific flask mods incorrectly applying to Minions [\#5326](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5326) ([Paliak](https://github.com/Paliak))
- Fix buff effect scaling guard absorption rate [\#5727](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5727) ([QuickStick123](https://github.com/QuickStick123))
- Fix local flask duration affecting the total amount recovered [\#5726](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5726) ([QuickStick123](https://github.com/QuickStick123))
- Fix Strength adding to Minions mod only applying at half value [\#5804](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5804) ([cardbeard](https://github.com/cardbeard))
- Fix Projectile modifiers incorrectly applying to Cremation Corpse Explosion damage, [\#5780](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5780) ([CapnJack22](https://github.com/CapnJack22))
- Fix Rational Doctrine not working while using Crystallised Omniscience [\#5710](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5710) ([QuickStick123](https://github.com/QuickStick123))
- Fix Double/Triple Damage calculations [\#5730](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5730) ([QuickStick123](https://github.com/QuickStick123))
- Add missing "Damage" tag to some golem skills [\#5639](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5639) ([Paliak](https://github.com/Paliak))
- Fix Ball Lightning Projectile Speed [\#5746](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5746) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix incorrect profane ground numbers [\#5815](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5815) ([QuickStick123](https://github.com/QuickStick123))
- Fix flask conditions for using Life and Mana flasks [\#5854](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5854) ([deathbeam](https://github.com/deathbeam))
- Fix Follow Through not applying to poison [\#5722](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5722) ([Paliak](https://github.com/Paliak))
- Stop Vaal Smite and Smite auras from stacking [\#5611](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5611) ([Paliak](https://github.com/Paliak))
- Fix skill type tags for maximum Ballista Totem mods [\#5577](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5577) ([bobanobahoba](https://github.com/bobanobahoba))
- Fix enemy negative resistance not being capped for DoT damage [\#5660](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5660) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
- Fix Vaal Lightning Strike damage effectiveness being off by 1 level [\#5760](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5760) ([Regisle](https://github.com/Regisle))

### Fixed Bugs
- Fix imported characters missing Voidborn uniques [\#5650](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5650) ([QuickStick123](https://github.com/QuickStick123))
- Fix Energy Blade not importing from PoE.ninja and on copy paste [\#5607](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5607) ([QuickStick123](https://github.com/QuickStick123))
- Fix enemy level getting out of sync due to updating later than expected [\#5709](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5709) ([QuickStick123](https://github.com/QuickStick123))
- Fix incorrect variable causing gem sorting to occur far too often [\#5763](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5763) ([Paliak](https://github.com/Paliak))
- Fix skill sets sometimes being deleted after deleting the first one [\#5765](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5765) ([deathbeam](https://github.com/deathbeam))
- Fix socket group linking not working on weapon swap and generalize socket group linking code [\#5600](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5600) ([Paliak](https://github.com/Paliak))
- Fix Energy Blade not working with socketed Abyssal jewels [\#5608](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5608) ([QuickStick123](https://github.com/QuickStick123))
- Fix more multipliers on Skill damage being incorrectly rounded. [\#5758](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5758) ([QuickStick123](https://github.com/QuickStick123))
- Prevent pathing through class starts for Split Personality [\#5651](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5651) ([Paliak](https://github.com/Paliak))


## [v2.25.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.25.1) (2023/01/06)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.25.0...v2.25.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Crashes
- Fix crash caused by item stuck on cursor when dragging [\#5550](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5550) ([Paliak](https://github.com/Paliak))
- Fix crash when using Whispering Ice with trigger support [\#5547](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5547) ([Paliak](https://github.com/Paliak))
- Fix crash caused by loading shared items too early [\#5543](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5543) ([QuickStick123](https://github.com/QuickStick123))
### Fixed Bugs
- Fixing Timeless jewels not working correctly when added via the "Find Timeless Jewel" UI [\#5522](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5522) ([QuickStick123](https://github.com/QuickStick123))
- Fix Atziri's Mirror's drop source [\#5524](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5524) ([pHiney](https://github.com/pHiney))
- Fix Blood Sacrament incorrect scaling when setting to stages more than 1 [\#5551](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5551) ([dreais](https://github.com/dreais))
- Fix Spell Suppression mastery not working with Acrobatics Keystone [\#5528](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5528) ([Paliak](https://github.com/Paliak))
- Fix magic utility flask effect not scaling Onslaught from Silver Flasks [\#5519](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5519) ([deathbeam](https://github.com/deathbeam))


## [v2.25.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.25.0) (2023/01/03)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.24.0...v2.25.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Apply enemy damage multiplier to max hit taken [\#5424](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5424) ([deathbeam](https://github.com/deathbeam))
- Add button to generate a trade link for Timeless Jewels [\#5402](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5402) ([meepen](https://github.com/meepen))
- PoB Trader
  - Add ability to generate weighted search URL without the need for POESESSID [\#5511](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5511) ([Dullson](https://github.com/Dullson))
  - Add support for Private Leagues [\#5511](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5511) ([Dullson](https://github.com/Dullson))
  - Add support for Sony and Xbox realms [\#5372](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5372) ([Nostrademous](https://github.com/Nostrademous))
  - Sort Trade league name dropdown so temporary leagues appear at the top of the list [\#5351](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5351) ([Nostrademous](https://github.com/Nostrademous))
  - Automatically adjust weighted search to prevent result clipping [\#5510](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5510) ([Dullson](https://github.com/Dullson))
  - Add support to change the sorting mode on already-fetched items [\#5500](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5500) ([Dullson](https://github.com/Dullson))
  - Improve item pricer error handling [\#5396](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5396) ([Dullson](https://github.com/Dullson))
  - Temporarily remove Synthesis mods until they are properly supported [\#5379](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5379) ([Dolmur](https://github.com/Dolmur))
  - Remove Eldritch mods checkbox from bases that are unable to roll Eldritch mods [\#5379](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5379) ([Dolmur](https://github.com/Dolmur))
  - Display item price at the bottom of the item tooltip [\#5511](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5511) ([Dullson](https://github.com/Dullson))
  - Use default item affix quality to generate mod weightings [\#5388](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5388) ([Regisle](https://github.com/Regisle))
- Add option for to select any conqueror Keystone for Timeless jewels search [\#5490](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5490) ([Regisle](https://github.com/Regisle))
- Add support for Mutewind Pennant Warcry mod [\#5384](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5384) ([andrewbelu](https://github.com/andrewbelu))
- Add support for Phantasmal Reave radius [\#5374](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5374) ([andrewbelu](https://github.com/andrewbelu))
- Add support for Sandstorm Visage crit mod [\#5398](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5398) ([andrewbelu](https://github.com/andrewbelu))
- Add Support for Frozen Sweep DPS and burst damage [\#5296](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5296) ([Lilylicious](https://github.com/Lilylicious))
- Add support for Original Sin [\#5426](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5426) ([QuickStick123](https://github.com/QuickStick123))
- Add support for Progenesis and show the amount recouped [\#5386](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5386) ([Regisle](https://github.com/Regisle))
- Add support for Rotting Legion missing Zombie mod [\#5385](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5385) ([andrewbelu](https://github.com/andrewbelu))
- Critical strike cull chance now uses hit rate to determine DPS gain [\#5378](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5378) ([andrewbelu](https://github.com/andrewbelu))
- Increased flask effect works on Silver Flask to scale Onslaught effect [\#5407](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5407) ([Fabere456](https://github.com/Fabere456))
- Add sanctum unique drop locations [\#5414](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5414) ([QuickStick123](https://github.com/QuickStick123))
- Update tree to 3.20.1 [\#5457](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5457) ([QuickStick123](https://github.com/QuickStick123))
### Fixed Crashes
- Fix crash when deleting gem level [\#5479](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5479) ([Paliak](https://github.com/Paliak))
- Fix crash when clicking sort options in node power [\#5504](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5504) ([meepen](https://github.com/meepen))
### User Interface
- Change the unique list to only display currently obtainable uniques instead of any source [\#5491](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5491) ([Regisle](https://github.com/Regisle))
- Fix odd edit behaviour with the POESESSID input box [\#5358](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5358) ([Wires77](https://github.com/Wires77))
- Fix Timeless Jewel tree radius effect not appearing on jewels added through "Find Timeless Jewel" UI [\#5440](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5440) ([LocalIdentity](https://github.com/LocalIdentity))
- Remove duplicate bleed/poison config option [\#5420](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5420) ([QuickStick123](https://github.com/QuickStick123))
### Fixed Bugs
- PoB Trader memory leak [\#5473](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5473) ([Dullson](https://github.com/Dullson))
- Max fuse calculation for Explosive Arrow [\#5349](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5349) ([Lilylicious](https://github.com/Lilylicious))
- Minion-specific mods not being included as mods for weighted search [\#5355](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5355) ([Dolmur](https://github.com/Dolmur))
- Item pricing mod calculation does now use DPS instead of average damage [\#5400](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5400) ([Urganot](https://github.com/Urganot))
- Minion-specific mods granting their effect to all Minions [\#5394](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5394) ([QuickStick123](https://github.com/QuickStick123))
- Session IDs not saving separately per imported account [\#5357](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5357) ([Wires77](https://github.com/Wires77))
- Missing skillType tags from minion skills [\#5325](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5325) ([Paliak](https://github.com/Paliak))
- Wither on hit from Balance of Terror [\#5514](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5514) ([deathbeam](https://github.com/deathbeam))
- Sort by Full DPS not working on anoints and appearing in other locations [\#5421](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5421) ([QuickStick123](https://github.com/QuickStick123))
- Kalandra's Touch not working [\#5442](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5442) ([QuickStick123](https://github.com/QuickStick123))
- Long loading times from modCache not being used during startup [\#5461](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5461) ([QuickStick123](https://github.com/QuickStick123))
- Issue parsing certain item bases [\#5452](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5452) ([Paliak](https://github.com/Paliak))
- Unique Armour/Evasion/ES/DPS tooltip being different to added item [\#5499](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5499) ([QuickStick123](https://github.com/QuickStick123))
- Energy Blade not getting disabled when removing the gem [\#5359](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5359) ([QuickStick123](https://github.com/QuickStick123))
- Divergent Cast while Channeling incorrectly adding "More" damage [\#5409](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5409) ([LocalIdentity](https://github.com/LocalIdentity))
- Rotgut variant mods [\#5410](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5410) ([LocalIdentity](https://github.com/LocalIdentity))
- Seismic Trap and Lightning Spire Trap not rounding to server ticks for wave count calculation [\#5395](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5395) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
- Missing Physical tag to Heartbound Loop [\#5416](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5416) ([ProphetLamb](https://github.com/ProphetLamb))
- Wording on Sandstorm Visage mods [\#5425](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5425) ([QuickStick123](https://github.com/QuickStick123))
- Remove Legacy Crystallised Omniscience from the unique list as it no longer exists [\#5447](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5447) ([QuickStick123](https://github.com/QuickStick123))
- Damage multipliers to exerts also applying to triggered skills [\#5446](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5446) ([Paliak](https://github.com/Paliak))
- More than 100% reduced resistances causing negative res to turn positive [\#5458](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5458) ([QuickStick123](https://github.com/QuickStick123))
- Militant Faith mod using "Skill Cost" instead of "Mana Cost" [\#5460](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5460) ([Regisle](https://github.com/Regisle))
- Implicit mods on Kalandra's Touch not applying [\#5445](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5445) ([Paliak](https://github.com/Paliak))
- Singular element modes not working with phys as random element dropdown box [\#5465](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5465) ([QuickStick123](https://github.com/QuickStick123))
- Missing name on elemental damage Grand Spectrum variant [\#5481](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5481) ([deathbeam](https://github.com/deathbeam))
- Frenzy Charges and Onslaught only counting one stat instead of two for Wilma's Requital [\#5498](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5498) ([LocalIdentity](https://github.com/LocalIdentity))
- Level requirement for United in Dream [\#5497](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5497) ([LocalIdentity](https://github.com/LocalIdentity))
### Other changes
- Clarified instructions for adding EmmyLua to VSCode [\#5431](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5431) ([blahblahdrugs](https://github.com/blahblahdrugs))


## [v2.24.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.24.0) (2022/12/14)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.23.0...v2.24.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Update and add support for all new uniques [\#5279](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5279) ([QuickStick123](https://github.com/QuickStick123))
- Add price cap option to the PoB Trader [\#5280](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5280) ([Dullson](https://github.com/Dullson))
- Add support for Vaal Flicker Strike [\#5284](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5284) ([Nostrademous](https://github.com/Nostrademous))
- Add support for Critical Strike chance cap on new Winds of Fate Unique [\#5324](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5324) ([Lilylicious](https://github.com/Lilylicious))
- Add support for Explosive Trap DPS [\#5309](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5309) ([QuickStick123](https://github.com/QuickStick123))
- Add support for many new flask-specific mods [\#5281](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5281) ([QuickStick123](https://github.com/QuickStick123))
- Add support for new curse mods without increased effect [\#5308](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5308) ([QuickStick123](https://github.com/QuickStick123))
### Fixed Crashes
- Fix crash when using Hand of the Fervent with a life cost [\#5291](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5291) ([QuickStick123](https://github.com/QuickStick123))
- Fix crash related to base cost mod parsing and overhaul resource relating parsing to be more generic [\#5307](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5307) ([QuickStick123](https://github.com/QuickStick123))
### User Interface
- Hide character input in POESESSID input box for privacy reasons [\#5314](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5314) ([Nostrademous](https://github.com/Nostrademous))
- Fix spacing issue in portrait mode on the Items tab [\#5345](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5345) ([Wires77](https://github.com/Wires77))
### Accuracy Improvements
- Improve accuracy of mana cost calculations [\#5289](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5289) ([QuickStick123](https://github.com/QuickStick123))
- Update all unique flasks with 3.20 wording changes [\#5281](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5281) ([QuickStick123](https://github.com/QuickStick123))
- Update Corundum flask with "Cannot be Stunned" affix [\#5301](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5301) ([Nostrademous](https://github.com/Nostrademous))
- Update Fated End [\#5315](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5315) ([QuickStick123](https://github.com/QuickStick123))
- Fix Phantasmal Smite quality not working [\#5284](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5284) ([Nostrademous](https://github.com/Nostrademous))
- Fix Frozen Legion radius numbers [\#5298](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5298) ([Nostrademous](https://github.com/Nostrademous))
- Use trap cooldown for Mana cost per second [\#5294](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5294) ([Lilylicious](https://github.com/Lilylicious))
### Fixed Bugs
- PoB Trader did not list the correct league names [\#5280](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5280) ([Dullson](https://github.com/Dullson))
- PoB Trader had overlapping UI on the Query Options box [\#5280](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5280) ([Dullson](https://github.com/Dullson))
- PoB Trader wasn't generating a sufficient minimum weight for some builds [\#5340](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5340) ([Dolmur](https://github.com/Dolmur))
- PoB Trader did not work on Linux due to an issue with curl [\#5344](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5344) ([Turmfalke2](https://github.com/Turmfalke2))
- Private character importing when using your session ID [\#5343](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5343) ([Wires77](https://github.com/Wires77))
- FullDPS causing some skills to not work correctly with the node power colours on the tree [\#5317](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5317) ([QuickStick123](https://github.com/QuickStick123))
- Importing characters that used Barrage Support in skill links [\#5312](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5312) ([raylu](https://github.com/raylu))
- Area damage supports not working with Minion Instability [\#5303](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5303) ([Paliak](https://github.com/Paliak))


## [v2.23.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.23.0) (2022/12/09)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.22.1...v2.23.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Other changes
- Add initial and partial support for new skill gems [\#5276
](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5276
) ([LocalIdentity](https://github.com/LocalIdentity))
    * Vaal Blade Flurry is partially supported
    * Vaal Cleave is missing the Cleave buff
    * Frozen legion needs more work before it's completely accurate
- Updated old skill gems with 3.20 balance changes [\#5276
](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5276
) ([LocalIdentity](https://github.com/LocalIdentity))



## [v2.22.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.22.1) (2022/12/09)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.22.0...v2.22.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### User Interface
- Update 3.20 skill tree [\#5269
](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5269) ([LocalIdentity](https://github.com/LocalIdentity))
### Fixed Bugs
- Cost per second for totems and eldritch battery [\#5251](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5251) ([Lilylicious](https://github.com/Lilylicious))
- Incorrect warnings when using Eldritch Battery and remove support for per-second costs [\#5247](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5247) ([Paliak](https://github.com/Paliak))
- Viper Strike base Poison duration [\#5263](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5263) ([LocalIdentity](https://github.com/LocalIdentity))
- Ailments not applying correctly [\#5264](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5264) ([Lilylicious](https://github.com/Lilylicious))
- Hex Master not working with Impossible Escape [\#5267](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5267) ([LocalIdentity](https://github.com/LocalIdentity))
- Onslaught Effect nodes on skill tree not working [\#5270](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5270) ([LocalIdentity](https://github.com/LocalIdentity))



## [v2.22.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.22.0) (2022/12/09)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.21.1...v2.22.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Add 3.20 Tree and Timeless jewel nodes [\#5188](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5188) ([Regisle](https://github.com/Regisle))
- Add all revealed new Uniques from 3.20 [\#5185](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5185), [\#5235](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5235) ([QuickStick123](https://github.com/QuickStick123))
- Add build pricing and item optimization to Items Tab [\#3885](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3885), [\#5210](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5210), [\#5205](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5205), [\#5217](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5217), [\#5224](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5224) ([Dolmur](https://github.com/Dolmur), [Nostrademous](https://github.com/Nostrademous), [Dullson](https://github.com/Dullson))
- Add support for
	- Seismic / Lightning Spire Trap DPS [\#5212](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5212) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
	- Mod tooltips to display stat differences when hovering over mods in the item crafter [\#5203](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5203) ([QuickStick123](https://github.com/QuickStick123))
	- New default gem level functionality [\#4724](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4724) ([Lothrik](https://github.com/Lothrik))
	- Specific socket colour mods found on Dialla's Malefaction, Malachai's Artifice, Doomsower [\#4981](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4981) ([Paliak](https://github.com/Paliak))
	- Resource costs per second in sidebar and add breakdown to the calcs page [\#5199](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5199) ([Lilylicious](https://github.com/Lilylicious))
	- Uptime of skills with duration and cooldown [\#4914](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4914) ([QuickStick123](https://github.com/QuickStick123))
	- Importing build links out of google sheets [\#4899](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4899) ([JadedCricket](https://github.com/JadedCricket))
	- Boneshatter self damage breakdown [\#4734](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4734) ([Lilylicious](https://github.com/Lilylicious))
	- Boneshatter maximum sustainable Trauma stacks [\#5049](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5049) ([QuickStick123](https://github.com/QuickStick123))
	- Deadly Tarantula and Armour Cruncher Spectres [\#5216](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5216), [\#5201](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5201) ([fialhoFabio](https://github.com/fialhoFabio))
	- Enemy Block Chance [\#4648](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4648) ([Regisle](https://github.com/Regisle))
	- Automatically apply Energy Blade buff when skill is equipped [\#5016](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5016) ([QuickStick123](https://github.com/QuickStick123))
	- Anomalous Predator Support [\#5135](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5135) ([TPlant](https://github.com/PJacek))
	- Frostblink CDR from nearby enemy [\#4986](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4986) ([Nostrademous](https://github.com/Nostrademous))
	- Summon Reaper's Consume buff [\#3088](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3088) ([Wires77](https://github.com/Wires77))
	- Reservation scaling with stages for Blood Sacrament [\#4583](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4583) ([QuickStick123](https://github.com/QuickStick123))
	- Burning Ground from Essence of Hysteria [\#4825](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4825) ([Regisle](https://github.com/Regisle))
	- Cold Conduction Cluster Jewel notable [\#5021](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5021) ([Nostrademous](https://github.com/Nostrademous))
	- Low Tolerance Cluster Jewel notable [\#4792](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4792) ([Regisle](https://github.com/Regisle))
	- "Nearby Allies have Culling Strike" [\#4921](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4921) ([Sinured](https://github.com/Sinured))
	- "chance for flasks you use to not consume charges" [\#4766](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4766) ([Lothrik](https://github.com/Lothrik))
	- Soul Eater stack limit [\#5137](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5137) ([TPlant](https://github.com/PJacek))
	- Hex Master Keystone [\#5193](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5193) ([QuickStick123](https://github.com/QuickStick123))
	- "Your Blessing Skills are Disabled" from Essence Worm [\#5121](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5121) ([Paliak](https://github.com/Paliak))
	- "Quicksilver Flasks you Use also apply to nearby Allies" mod on Victario's Flight [\#5095](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5095) ([Paliak](https://github.com/Paliak))
	- Stormfire's Burning Damage mod [\#4950](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4950) ([QuickStick123](https://github.com/QuickStick123))
	- Kalandra's Touch unique [\#5120](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5120) ([Paliak](https://github.com/Paliak))
	- Reflected kalandra mods [\#5014](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5014) ([Paliak](https://github.com/Paliak))
	- Some more Eldritch boss mods [\#5227](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5227) ([QuickStick123](https://github.com/QuickStick123))
	- New curse mods [\#5197](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5197) ([QuickStick123](https://github.com/QuickStick123))
	- Glorious Madness poison chance mod [\#5168](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5168) ([Azperin](https://github.com/Azperin))
### User Interface
- Add warnings if skill cost exceeds currently available resource (Life/ES/Mana) [\#5019](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5019) ([Paliak](https://github.com/Paliak))
- Add button to filter Uniques: Any item, Obtainable, Unobtainable, Vendor Recipe, Upgraded, Boss Item [\#4920](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4920) ([QuickStick123](https://github.com/QuickStick123))
- Add button to go to privacy settings when an account you are trying to import is set to private [\#5171](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5171) ([raylu](https://github.com/raylu))
- Make socket group sort order persistent when switching or deleting gems groups [\#4804](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4804) ([Lothrik](https://github.com/Lothrik))
- Display max calculated fuses for Explosive Arrow on the calcs page [\#5209](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5209) ([dbronkalla06](https://github.com/dbronkalla06))
- Adjust sample Brittle effects in Brittle breakdown box [\#5136](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5136) ([TPlant](https://github.com/PJacek))
- Relabel "Total DPS" to "Hit DPS" to increase readability [\#5172](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5172) ([raylu](https://github.com/raylu))
- Re-order the leagues dropdown in the import menu to have the current temporary league at the top of the list [\#5015](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5015) ([Schroedi](https://github.com/Schroedi))
- Do not hide config options that are configured without source [\#4716](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4716) ([deathbeam](https://github.com/deathbeam))))
- Fix Barrage and Barrage Support ambiguity in gem list [\#5029](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5029) ([Paliak](https://github.com/Paliak))
- Fix Aura effect on Self not counting towards Aura effect breakdown [\#4977](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4977) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix incorrect Timeless Jewel ring colours when searching a node on the passive tree [\#5142](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5142) ([Wires77](https://github.com/Wires77))
- Fix breakdown of mana cost not showing in certain situations [\#5146](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5146) ([Wires77](https://github.com/Wires77))
- Fix Fanaticism tooltip [\#5103](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5103) ([MeDott29](https://github.com/MeDott29))
- Fix DoT Multi missing in Poison multiplier breakdown for Spells [\#5090](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5090) ([Wires77](https://github.com/Wires77))
- Fix inconsistent display of additional quality and gem levels in skill group tooltip [\#5181](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5181) ([Paliak](https://github.com/Paliak))
- Fix typo in config tab [\#5191](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5191) ([Nightblade](https://github.com/Nightblade))
- Fix Item Corruptor having empty space [\#5213](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5213) ([QuickStick123](https://github.com/QuickStick123))
### Accuracy Improvements
- Update existing uniques for 3.20 [\#5184](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5184) ([ifnjeff](https://github.com/ifnjeff))
- Remove curse effect reduction on bosses [\#5187](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5187) ([QuickStick123](https://github.com/QuickStick123))
- Improve the accuracy of Max Hit calculations [\#5196](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5196) ([Edvinas-Smita](https://github.com/Edvinas-Smita))
- Improve the accuracy of eHP calculations [\#4915](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4915) ([QuickStick123](https://github.com/QuickStick123))
- Generalise Regeneration Calculations adding full support for degens and breakdowns [\#5011](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5011) ([QuickStick123](https://github.com/QuickStick123))
- Update Brittle formula [\#5018](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5018) ([QuickStick123](https://github.com/QuickStick123))
- Apply shock effect to shocked ground [\#5038](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5038) ([Paliak](https://github.com/Paliak))
- Truncate resistances to better match in game values [\#5115](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5115) ([Paliak](https://github.com/Paliak))
- Adjust Delirium effect scaling to be more accurate [\#5176](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5176) ([Lilylicious](https://github.com/Lilylicious))
- Fix Bleed and Ignite critical strike proportions to be based on how many applications you can apply during the duration [\#4875](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4875) ([oljomo](https://github.com/oljomo))
- Fix totems not being affected by auras [\#4636](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4636) ([Paliak](https://github.com/Paliak))
- Fix avoidance calculations when using Elusive [\#4883](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4883) ([Regisle](https://github.com/Regisle))
- Fix missing elemental resist calculation [\#5134](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5134) ([TPlant](https://github.com/PJacek))
- Fix maximum shock double counting [\#5173](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5173) ([QuickStick123](https://github.com/QuickStick123))
- Fix conversion and charges being negative [\#5186](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5186) ([QuickStick123](https://github.com/QuickStick123))
- Fix Lucky Attack Damage incorrectly applying to Spells [\#5059](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5059) ([QuickStick123](https://github.com/QuickStick123))
- Fix Ailment mods from active skill gems not applying in some cases [\#5003](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5003) ([Paliak](https://github.com/Paliak))
- Fix Non-curse Hex skills being treated as Curse skills [\#5182](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5182) ([kolhell](https://github.com/kolhell))
- Fix several issues with skill costs [\#5009](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5009) ([QuickStick123](https://github.com/QuickStick123))

- Fix rare templates not getting implicit mod tags [\#5149](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5149) ([Wires77](https://github.com/Wires77))
- Fix global energy shield being mistaken for local [\#5119](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5119) ([QuickStick123](https://github.com/QuickStick123))
- Fix parsing for new wording on Aegis Aurora [\#5155](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5155) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Grand Spectrum not working correctly with Minions [\#4965](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4965) ([deathbeam](https://github.com/deathbeam))
- Update affix limit for corrupted abyss jewels [\#5100](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5100) ([Paliak](https://github.com/Paliak))
- Update wording differences on uniques [\#4952](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4952) ([QuickStick123](https://github.com/QuickStick123))
- Update "Grants" wording change on uniques [\#5238](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5238) ([QuickStick123](https://github.com/QuickStick123))
- Update Pledge of Hands and Atziri's Disfavour sources [\#5234](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5234) ([QuickStick123](https://github.com/QuickStick123))
- Update flask wording [\#5236](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5236) ([QuickStick123](https://github.com/QuickStick123))
- Update Vorana's March to be in sync with game mods [\#4979](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4979) ([LocalIdentity](https://github.com/LocalIdentity))
- Remove chance to be crit mod from Aul's Uprising [\#4989](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4989) ([Torchery](https://github.com/Torchery))

- Fix Anomalous Energy Blade Shock Chance [\#5139](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5139) ([QuickStick123](https://github.com/QuickStick123))
- Fix Energy Blade counting multiple times when used in FullDPS [\#4919](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4919) ([QuickStick123](https://github.com/QuickStick123))
- Fix Cyclone's area of effect not scaling with weapon range [\#5192](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5192) ([QuickStick123](https://github.com/QuickStick123))
- Fix Elemental Hit scaling area instead of radius [\#5225](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5225) ([QuickStick123](https://github.com/QuickStick123))
- Fix Absolution Spell Hit counting multiple times when used in FullDPS [\#4653](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4653) ([APXEOLOG](https://github.com/APXEOLOG))
- Fix Lightning Conduit and Galvanic Field scaling with area damage [\#4978](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4978) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Lightning Conduit's "More damage with hits" [\#5099](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5099) ([QuickStick123](https://github.com/QuickStick123))
- Fix Divergent Fist of War increasing Stun Threshold [\#5145](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5145) ([Wires77](https://github.com/Wires77))
- Fix Ice spear Crit chance enchant not applying to all projectiles skill part [\#5045](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5045) ([Paliak](https://github.com/Paliak))
### Fixed Bugs
- Crash for pvp when checking support gems [\#5036](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5036) ([Regisle](https://github.com/Regisle))
- Crash when generating fallback weights caused by missing source [\#5055](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5055) ([Paliak](https://github.com/Paliak))
- Crash on crafting certain quirky items [\#5204](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5204) ([Nostrademous](https://github.com/Nostrademous))
- Crash when clicking on Jewel implicit button [\#5211](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5211) ([QuickStick123](https://github.com/QuickStick123))
- Kalisa's Grace crit chance modifier not working [\#5124](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5124) ([michelrtm](https://github.com/michelrtm))
- Cluster Jewels not showing DPS stats in item crafter [\#5022](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5022) ([LocalIdentity](https://github.com/LocalIdentity))
- Count being nil for FullDPS when importing a build [\#5047](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5047) ([Paliak](https://github.com/Paliak))
- Non-curse part of non-curse aura skills [\#5039](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5039) ([Paliak](https://github.com/Paliak))
- Some modifiers visually missing from total ES calcs [\#5061](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5061) ([randomflyingtaco](https://github.com/randomflyingtaco))
- Passive count multipliers preview on nodes [\#4865](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4865) ([Lilylicious](https://github.com/Lilylicious))
- Influence modifiers not behaving correctly and rune daggers missing rune dagger tag [\#4975](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4975) ([QuickStick123](https://github.com/QuickStick123))
- Arcanist brand giving brand skill flag to gems breaking stuff [\#4966](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4966) ([QuickStick123](https://github.com/QuickStick123))
- DPS comparison not working correctly when using The Saviour and using overrides [\#4635](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4635) ([Paliak](https://github.com/Paliak))
- Parsing for some pobb.in build links [\#5078](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5078) ([Dullson](https://github.com/Dullson))
- Use Life/Energy Shield Regen Recovery for power builder [\#4945](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4945) ([deathbeam](https://github.com/deathbeam))
- Remove caps on ground degens [\#4934](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4934) ([Regisle](https://github.com/Regisle))
- Some stats with Bloodstorm conditionals applying globally [\#5046](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5046) ([QuickStick123](https://github.com/QuickStick123))
- Added Rage generation flag to Chains of Emancipation [\#5035](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5035) ([QuickStick123](https://github.com/QuickStick123))
- Thread of Hope allowing you to allocate ascendancy nodes [\#5067](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5067) ([LocalIdentity](https://github.com/LocalIdentity))
- Improve handling of unscalable mods and fix some mods from alternate qualities not applying [\#4906](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4906) ([Paliak](https://github.com/Paliak), [QuickStick123](https://github.com/QuickStick123))
- Support gems not adding their flags if they themselves require a flag added by a support gem lower in the support list [\#4886](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4886) ([Paliak](https://github.com/Paliak))
- Devotion not working with minion mods [\#5133](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5133) ([TPlant](https://github.com/PJacek))
- Untying chill from frozen [\#5189](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5189) ([kolhell](https://github.com/kolhell))
- "No reservation" mods affecting cost of Blessings [\#5159](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5159) ([Paliak](https://github.com/Paliak))
- Ice Nova interaction with Greater Spell Echo and Awakened Spell Echo when casting on Frostbolt [\#4733](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4733) ([Sinured](https://github.com/Sinured))
- Exposure not applying correctly when using Scorching Ray "Maximum Sustainable Stages" [\#5164](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5164) ([Paliak](https://github.com/Paliak))
- Shavronne's Revelation removing life recharge [\#5165](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5165) ([Paliak](https://github.com/Paliak))
- Correctly apply mod precision in item editor and fix Assassin's Mark scaling [\#5050](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5050) ([QuickStick123](https://github.com/QuickStick123))
- Stop support gems from using Minion types to determine compatibility with Minion attack skills [\#4628](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4628) ([Paliak](https://github.com/Paliak))
- Dagger mastery and radius jewels applying to Masteries [\#5089](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5089) ([Paliak](https://github.com/Paliak))
- Varunastra not working with Nightblade Support [\#5158](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5158) ([Paliak](https://github.com/Paliak))
- Update Brittle config description to new value and fix Scorch source [\#5062](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5062) ([deathbeam](https://github.com/deathbeam))
### Other changes
- Documentation - Add more tips to CONTRIBUTING.md [\#4611](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4611) ([Paliak](https://github.com/Paliak))
- Fix spelling/punctuation [\#4960](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4960), [\#5237](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5237), [\#5082](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5082), [\#5147](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5147) ([Nightblade](https://github.com/Nightblade))


## [v2.21.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.21.1) (2022/08/20)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.21.0...v2.21.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Fix crash related to Alchemists Mark [\#4931](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4931) ([deathbeam](https://github.com/deathbeam))



## [v2.21.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.21.0) (2022/08/20)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.20.2...v2.21.0)

## What's Changed
### Implemented Enhancements
- Add support for new 3.19 skills and mods [\#4925](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4925) ([Nostrademous](https://github.com/Nostrademous), [LocalIdentity](https://github.com/LocalIdentity))
  * Full support for all new skills
- Add initial support for Eldritch Implicits [\#4658](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4658) ([Regisle](https://github.com/Regisle))
- Add the ability to automatically calculate # of Explosive Arrow Fuses [\#4918](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4918) ([LocalIdentity](https://github.com/LocalIdentity))
- Add breakdowns for Burning and Caustic ground from ailments [\#4916](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4916) ([Regisle](https://github.com/Regisle))
- Add the Poised Prism and Elevore uniques [\#4846](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4846) ([QuickStick123](https://github.com/QuickStick123))
- Add new Grand Spectrum mods [\#4897](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4897) ([deathbeam](https://github.com/deathbeam))
### User Interface
- Fix PvP Hit Taken Colour [\#4860](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4860) ([Regisle](https://github.com/Regisle))
- Update Heartstopper config text [\#4859](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4859) ([Regisle](https://github.com/Regisle))
- Remove Main Hand background colour from global Ignite Dot Multi section [\#4922](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4922) ([TPlant](https://github.com/PJacek))
- Add Keystone names to Timeless jewel variants [\#4882](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4882) ([Regisle](https://github.com/Regisle))
### Accuracy Improvements
- Update Replica uniques [\#4901](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4901) ([QuickStick123](https://github.com/QuickStick123))
- Update Deidbell [\#4852](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4852) ([QuickStick123](https://github.com/QuickStick123))
- Update Ventor's Gamble and Soul Ripper [\#4894](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4894) ([Lothrik](https://github.com/Lothrik))
- Fix missing life on Demon Stitcher [\#4858](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4858) ([QuickStick123](https://github.com/QuickStick123))
### Fixed Bugs
- Fix crash when adding Timeless jewel to build from tree UI [\#4893](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4893) ([Lothrik](https://github.com/Lothrik))
- Fix certain spells not having correct DPS with Unleash Support [\#4881](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4881) ([Regisle](https://github.com/Regisle))
- Fix Timeless jewel node weight bugs [\#4844](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4844) ([Lothrik](https://github.com/Lothrik))
- Fix checkbox not updating when selecting Vaal skills [\#4903](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4903) ([Paliak](https://github.com/Paliak))
- Fix Rage regen issues [\#4880](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4880) ([Regisle](https://github.com/Regisle))
- Fix Gain on Kill not working for Attacks [\#4857](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4857) ([Regisle](https://github.com/Regisle))



## [v2.20.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.20.2) (2022/08/16)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.20.1...v2.20.2)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Reintroduce Show/Hide skill cost based upon whether it has a base cost [\#4838](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4838) ([QuickStick123](https://github.com/QuickStick123))
### Accuracy Improvements
- Use correct max shock in breakdown [\#4829](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4829) ([Lilylicious](https://github.com/Lilylicious))
### Fixed Bugs
- Fix timeless jewel socket index bug [\#4832](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4832) ([Lothrik](https://github.com/Lothrik))
- Fix missing unique sliders [\#4835](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4835) ([Lothrik](https://github.com/Lothrik))
- Filter out unused modifier line ranges [\#4836](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4836) ([Lothrik](https://github.com/Lothrik))

## [v2.20.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.20.1) (2022/08/16)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.20.0...v2.20.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Revert skill costs being hidden if you reduced the cost to 0 as it was causing an error ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Juggernaut "Armour applies to Elemental damage" node not working ([Lilylicious](https://github.com/Lilylicious))

## [v2.20.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.20.0) (2022/08/16)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.19.2...v2.20.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Update skill tree to 3.19 [\#4744](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4744) ([Regisle](https://github.com/Regisle))
- Add new uniques [\#4774](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4774), [\#4817](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4817) ([QuickStick123](https://github.com/QuickStick123), [LocalIdentity](https://github.com/LocalIdentity), [Wires77](https://github.com/Wires77))
- Timeless jewel search improvements [\#4622](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4622) ([Regisle](https://github.com/Regisle)), ([Lothrik](https://github.com/Lothrik))
  	- You can now auto generate weights for nodes based on skill DPS
  	- You can scroll on the horizontal scroll bars to change values (hold Ctrl/Shift to scroll slower/faster)
- Update a wide variety of unique items 
	- [\#4767](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4767), [\#4763](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4763), [\#4760](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4760), [\#4769](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4769), [\#4753](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4753), [\#4729](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4729) ([Sinured](https://github.com/Sinured))
	- [\#4747](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4747), [\#4751](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4751), [\#4754](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4754), [\#4748](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4748), [\#4757](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4757), [\#4775](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4775), [\#4783](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4783) ([QuickStick123](https://github.com/QuickStick123))
	- [\#4702](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4702), [\#4700](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4700), [\#4699](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4699), [\#4698](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4698) ([Lexy](https://github.com/learn2draw))
	- [\#4755](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4755) ([Nightblade](https://github.com/Nightblade))
	- [\#4745](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4745) ([Paliak](https://github.com/Paliak))
	- [\#4814](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4814) ([Wires77](https://github.com/Wires77))
	- [\#4602](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4602) ([Lothrik](https://github.com/Lothrik))
- Add support for
	- Damage over Time DPS cap [\#4649](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4649), [\#4808](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4808) ([deathbeam](https://github.com/deathbeam), [Regisle](https://github.com/Regisle), [LocalIdentity](https://github.com/LocalIdentity))
	- 3.19 Trickster ascendancy  [\#4749](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4749), [\#4782](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4782), [\#4749](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4749) ([Lilylicious](https://github.com/Lilylicious), [Regisle](https://github.com/Regisle))
	- Deal 10% less damage on Indomitable Resolve [\#4688](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4688) ([Regisle](https://github.com/Regisle))
	- armour applies to ele damage [\#4673](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4673) ([Regisle](https://github.com/Regisle))
	- Vorana's March mods [\#4613](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4613) ([LocalIdentity](https://github.com/LocalIdentity))
	- Non-critical strikes deal less damage [\#4701](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4701) ([Regisle](https://github.com/Regisle))
	- More Ailment effect modifiers [\#4707](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4707) ([Regisle](https://github.com/Regisle))
	- Used Life flask in the past 10 seconds [\#4687](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4687) ([Regisle](https://github.com/Regisle))
	- Debuff expiration rate [\#4703](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4703) ([Regisle](https://github.com/Regisle))
	- Basic recoup breakdown [\#4706](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4706) ([Regisle](https://github.com/Regisle))
	- Modifiers to enemy damage [\#4685](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4685) ([Regisle](https://github.com/Regisle))
	- PvP skill scaling [\#4664](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4664) ([Regisle](https://github.com/Regisle))
	- PvP hit taken [\#4718](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4718) ([Regisle](https://github.com/Regisle))
	- Non-Vaal gem modifiers [\#4711](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4711) ([Nostrademous](https://github.com/Nostrademous))
	- Debilitate debuff [\#4710](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4710) ([deathbeam](https://github.com/deathbeam))
	- Minions have Unholy Might [\#4780](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4780) ([QuickStick123](https://github.com/QuickStick123))
	- 3.19 Arrow Dancing Keystone [\#4779](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4779) ([QuickStick123](https://github.com/QuickStick123))
	- Counting Mastery type allocations [\#4746](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4746) ([Nostrademous](https://github.com/Nostrademous))
	- More triple damage mods [\#4727](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4727) ([Paliak](https://github.com/Paliak))
	- Kalandra inverted stats [\#4756](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4756) ([Nostrademous](https://github.com/Nostrademous))
	- Stacking max shock [\#4750](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4750) ([Lilylicious](https://github.com/Lilylicious))
	- Ryslatha Pantheon Life flask charge generation [\#4721](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4721) ([deathbeam](https://github.com/deathbeam))
	- Lightning Conduit's new Trigger flag [\#4802](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4802) ([Nostrademous](https://github.com/Nostrademous))
	- Enemy Overwhelm [\#4705](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4705) ([QuickStick123](https://github.com/QuickStick123))
	- Burning and Caustic ground and Flame Surge [\#4801](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4801) ([deathbeam](https://github.com/deathbeam))
	- Burning and caustic ground in total/combined DPS [\#4815](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4815) ([Regisle](https://github.com/Regisle))
	- Prevent burning and caustic ground from stacking [\#4820](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4820) ([Regisle](https://github.com/Regisle))
	- Parsing of Link skill mods [\#4816](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4816) ([QuickStick123](https://github.com/QuickStick123))
- Fix Incinerate gem tooltip [\#4681](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4681) ([Paliak](https://github.com/Paliak))
- Always use configured or base chill for bonechill and remove bonechill config [\#4453](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4453) ([deathbeam](https://github.com/deathbeam))
- Update ward recharge speed [\#4697](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4697) ([Lexy](https://github.com/learn2draw))
- Update Brittle to 3.19 values [\#4696](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4696) ([Lexy](https://github.com/learn2draw))
- Added Thrusting as a base sword subType [\#4720](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4720) ([Nostrademous](https://github.com/Nostrademous))
- Minion charges and ailments work like players [\#4694](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4694) ([Lilylicious](https://github.com/Lilylicious))
- Take into account weapon conditions for shock [\#4795](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4795) ([Lilylicious](https://github.com/Lilylicious))
- Properly support gain on kill [\#4704](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4704) ([Regisle](https://github.com/Regisle))
- Update Chainbreaker wording and display Rage Regeneration [\#4786](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4786) ([Sinured](https://github.com/Sinured))
### User Interface
- Display reservation efficiency as percentage with two decimal places instead of a full float multiplier [\#4518](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4518) ([Paliak](https://github.com/Paliak))
- Display effect of active gem variant when mousing over the "Variant" drop-down selector [\#4633](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4633) ([talkmill](https://github.com/talkmill))
- Change sidebar to show red numbers for unreserved life of 0 [\#4618](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4618) ([talkmill](https://github.com/talkmill))
### Accuracy Improvements
- General improvements to "Damaging Hits" section and armour breakdown [\#4637](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4637) ([QuickStick123](https://github.com/QuickStick123))
- Apply spell suppression to EHP calculations and add support for Instinct [\#4686](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4686) ([Regisle](https://github.com/Regisle))
- Improve stun avoid calcs [\#4715](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4715) ([Regisle](https://github.com/Regisle))
- Improve scaled modifier precision [\#4640](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4640) ([Lothrik](https://github.com/Lothrik))
- Restructure leech to apply cap later [\#4809](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4809) ([QuickStick123](https://github.com/QuickStick123))
### Fixed Bugs
- Blood offering stats not calculated #744 [\#4638](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4638) ([talkmill](https://github.com/talkmill))
- Node power sorting at infinite values [\#4617](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4617) ([Regisle](https://github.com/Regisle))
- Config tab being 1 change behind enemy level [\#4624](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4624) ([Regisle](https://github.com/Regisle))
- Bottom bar wrapping in the tree tab [\#4693](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4693) ([talkmill](https://github.com/talkmill))
- Sidebar always showing Culling DPS and Recoverable ES [\#4646](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4646) ([LocalIdentity](https://github.com/LocalIdentity))
- Evasion to armour conversion calculation not including "armour and evasion" base stats [\#4600](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4600) ([MrCoolTheCucumber](https://github.com/MrCoolTheCucumber))
- Trypanon crit chance calculations [\#4610](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4610) ([LocalIdentity](https://github.com/LocalIdentity))
- Total more multipliers not being round to nearest percent as done in game [\#4641](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4641) ([QuickStick123](https://github.com/QuickStick123))
- Evasion as Extra Armour with Iron Reflexes [\#4643](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4643) ([LocalIdentity](https://github.com/LocalIdentity))
- Buff stages on Scorching Ray, Frost Shield, and Sigil of Power [\#4645](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4645) ([Wires77](https://github.com/Wires77))
- Veiled mod pool on autogenerated unique weapons [\#4651](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4651) ([LocalIdentity](https://github.com/LocalIdentity))
- Bleed DPS when using multiple totems [\#4650](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4650) ([LocalIdentity](https://github.com/LocalIdentity))
- Alternate ailments not working with anomalous grace [\#4656](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4656) ([QuickStick123](https://github.com/QuickStick123))
- Various spelling errors [\#4690](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4690), [\#4712](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4712), [\#4773](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4773) ([Nightblade](https://github.com/Nightblade), [Regisle](https://github.com/Regisle))
- Imported items variable percentages [\#4735](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4735) ([Wires77](https://github.com/Wires77))
- Vaal Discipline not counting towards Aura count [\#4608](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4608) ([LocalIdentity](https://github.com/LocalIdentity))
- Enable skill tooltip visibility for non-vaal active skill gems [\#4606](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4606) ([Lothrik](https://github.com/Lothrik))
- Default level for pinnacles [\#4604](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4604) ([Lilylicious](https://github.com/Lilylicious))
- Prevent invalid character level values [\#4609](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4609) ([Lothrik](https://github.com/Lothrik))
- Catalysts visually not scaling certain mods [\#4603](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4603) ([QuickStick123](https://github.com/QuickStick123))
- Force rebuild to initialise boss presets and remove phys fallback [\#4615](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4615) ([Regisle](https://github.com/Regisle))
- Stop pretending Tawhoa is implemented [\#4732](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4732) ([Lilylicious](https://github.com/Lilylicious))
- Selected Mastery Tree Upconversion Error [\#4765](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4765) ([Nostrademous](https://github.com/Nostrademous))
- Set skillSet to nil instead of removing it from table and reordering it [\#4772](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4772) ([deathbeam](https://github.com/deathbeam))
- Build did not save on generating a build code [\#4623](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4623) ([talkmill](https://github.com/talkmill))
- Multistrike damage calculation with skills which have bow and melee Tag [\#4740](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4740) ([Sinured](https://github.com/Sinured))
- Guaranteed ailments were not using correct values [\#4790](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4790) ([Lilylicious](https://github.com/Lilylicious))
- Longshot affects all projectiles that hit [\#4709](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4709) ([Lilylicious](https://github.com/Lilylicious))
- Scorching Ray totem DoT was not stacking [\#4821](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4821) ([Regisle](https://github.com/Regisle))
- Tornado was using Cast rate instead of Hit rate [\#4826](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4826) ([Sinured](https://github.com/Sinured))
- Skill costs being hidden if you reduced the cost to 0 [\#4813](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4813) ([QuickStick123](https://github.com/QuickStick123))
### Preliminary changes
- These changes might be changed further once the official patch is out
- Lifetap & Blessing interaction [\#4752](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4752) ([Sinured](https://github.com/Sinured))


## [v2.19.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.19.2) (2022/07/15)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.19.1...v2.19.2)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### User Interface
- Fix certain controls not displaying tooltips on hover [\#4594](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4594) ([Lothrik](https://github.com/Lothrik))
- Adjust default item affix quality UI [\#4593](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4593) ([Lothrik](https://github.com/Lothrik))
### Fixed Bugs
- Fix anointed notables not being affected by Timeless jewels [\#4586](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4586) ([Lothrik](https://github.com/Lothrik))
- Fix "NaN" EHP error and crash when setting enemy level too high [\#4591](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4591) ([Lothrik](https://github.com/Lothrik))
- Fix crash when loading old skill tree with a Glorious Vanity jewel socketed [\#4587](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4587) ([Lothrik](https://github.com/Lothrik))
- Fix crash if Timeless jewel file is denied access or if changelog.txt doesn't exist [\#4588](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4588) ([Lothrik](https://github.com/Lothrik))
- Fix crash when comparing skill trees with masteries allocated [\#4590](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4590) ([Lothrik](https://github.com/Lothrik))



## [v2.19.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.19.1) (2022/07/13)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.19.0...v2.19.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Add support to search Timeless jewel node stats in the "Search for Node" dropdown list [\#4580](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4580) ([Regisle](https://github.com/Regisle))
### Fixed Bugs
- Fix crash when socketing a Glorious Vanity jewel in your tree [\#4577](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4577) ([Lothrik](https://github.com/Lothrik))
- Fix DoT skill DPS being 6% of actual value [\#4575](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4575) ([Nostrademous](https://github.com/Nostrademous))
- Fix Divine Flesh and Immortal Ambition keystones [\#4578](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4578) ([Lothrik](https://github.com/Lothrik))
- Fix Auras being disabled for skills in Full DPS [\#4581](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4581) ([QuickStick123](https://github.com/QuickStick123))



## [v2.19.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.19.0) (2022/07/12)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.18.1...v2.19.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Timeless Jewel implementation [\#4527](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4527) ([LocalIdentity](https://github.com/LocalIdentity), [Lothrik](https://github.com/Lothrik), [Nostrademous](https://github.com/Nostrademous), [Regisle](https://github.com/Regisle), [Wires77](https://github.com/Wires77))
- Add Default Item Affix Quality option [\#4520](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4520) ([Lothrik](https://github.com/Lothrik))
- Add support for skill sets (socket group sets) [\#4447](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4447) ([deathbeam](https://github.com/deathbeam))
- Add new configuration options for Boss Skill Presets [\#4436](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4436) ([Regisle](https://github.com/Regisle))
- Add support for brittle/sapped ground and alternate ailment boot implicits [\#4443](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4443) ([deathbeam](https://github.com/deathbeam))
- Update ailment threshold to current values [\#4435](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4435) ([deathbeam](https://github.com/deathbeam))
- Add self curse effect to Calcs tab [\#4537](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4537) ([QuickStick123](https://github.com/QuickStick123))
- Add display for totem resistances in skill type specific stats [\#4523](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4523) ([deathbeam](https://github.com/deathbeam))
- Add support for Unearth corpse calculation [\#4487](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4487) ([Nostrademous](https://github.com/Nostrademous))
- Add Pale Seraphim "Thunder Web" debuff [\#4490](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4490) ([Lothrik](https://github.com/Lothrik))
- Add full support for Supreme Ego [\#4524](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4524) ([QuickStick123](https://github.com/QuickStick123))
- Add support for "% of damage taken bypasses ward" [\#4549](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4549) ([deathbeam](https://github.com/deathbeam))
- Add support for "Magic Utility Flasks applied to you have increased effect" [\#4461](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4461) ([deathbeam](https://github.com/deathbeam))
- Add support for ailment immunity mod on timeless jewels [\#4552](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4552) ([Wires77](https://github.com/Wires77))
- Add support for "% increased cast speed if a minion has been killed recently" [\#4464](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4464) ([spawnie-no-oni](https://github.com/spawnie-no-oni))
- Add support for more Eldritch mods [\#4507](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4507) ([LocalIdentity](https://github.com/LocalIdentity))
### User Interface
- Fix labels having an incorrect font size and alignment for checkmark boxes. [\#4486](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4486) ([QuickStick123](https://github.com/QuickStick123))
- Fix typo in tree [\#4469](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4469) ([Ivniinvi](https://github.com/Ivniinvi))
- Fix unicode sanitization issues [\#4439](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4439) ([Wires77](https://github.com/Wires77))
- Move movement speed below resistances in the side-bar [\#4426](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4426) ([Nightblade](https://github.com/Nightblade))
- Fix overlapping tooltips, move bandit and pantheon options into the Config tab [\#4441](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4441) ([TPlant](https://github.com/PJacek))
- Restore enter functionality for Import tab [\#4448](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4448) ([pHiney](https://github.com/pHiney))
- Fix saving of section/subsection collapsing in calcs [\#4555](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4555) ([deathbeam](https://github.com/deathbeam))
- Add some missing alternate quality modifiers [\#4132](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4132) ([Nostrademous](https://github.com/Nostrademous))
### Accuracy Improvements
- Fix flat Reservation rounding [\#4471](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4471) ([Lothrik](https://github.com/Lothrik))
- Correctly handle 100% reduced reservation efficiency and greater [\#4514](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4514) ([QuickStick123](https://github.com/QuickStick123))
- Fix multi number mods scaling the wrong number with catalysts [\#4484](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4484) ([QuickStick123](https://github.com/QuickStick123))
- Stop Noxious Catalyst from scaling Icefang Orbit's chance to poison [\#4463](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4463) ([tansheron](https://github.com/tansheron))
- Fix elemental ailments defensive calculations [\#4440](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4440) ([TPlant](https://github.com/PJacek))
- Fix Vaal lightning strike projectiles not counting as projectiles [\#4531](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4531) ([Wires77](https://github.com/Wires77))
- Rename old dodge chance mods on watcher's eye [\#4478](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4478) ([Wires77](https://github.com/Wires77))
- Update "source" text of unique cluster jewels [\#4542](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4542) ([ctrpetersen](https://github.com/ctrpetersen))
- Update wording on Skyforth, Victario's Flight, Mindspiral, Mutewind Seal [\#4512](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4512) ([Lothrik](https://github.com/Lothrik))
- Update wording on Maw of Conquest, Thousand Teeth Temu [\#4519](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4519) ([Lothrik](https://github.com/Lothrik))
- Fix incorrect level requirement for Legacy of Fury [\#4510](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4510) ([Lexy](https://github.com/learn2draw))
- Fix Ming's Heart variant typo [\#4454](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4454) ([Regisle](https://github.com/Regisle))
- Fix Flask Duration to match in game values [\#4526](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4526) ([QuickStick123](https://github.com/QuickStick123))
- Refactor wither to apply strongest wither effect [\#4525](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4525) ([QuickStick123](https://github.com/QuickStick123))
### Fixed Bugs
- Fix Out of Memory crash in Items Tab [\#4530](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4530) ([Lothrik](https://github.com/Lothrik))
- Fix alternate quality dropdown options not changing on gem deletion [\#4532](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4532) ([Wires77](https://github.com/Wires77))
- Fix corrosion not being disabled when mod is not present [\#4505](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4505) ([QuickStick123](https://github.com/QuickStick123))
- Fix saving of changed placeholders [\#4548](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4548) ([deathbeam](https://github.com/deathbeam))
- Fix undo resetting active display group [\#4554](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4554) ([deathbeam](https://github.com/deathbeam))
- Fix socket group copy/paste [\#4452](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4452) ([deathbeam](https://github.com/deathbeam))
- Improve skill gem state persistence [\#4493](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4493) ([Lothrik](https://github.com/Lothrik))
- Fix Precise Technique to use max life instead of current life [\#4477](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4477) ([Dullson](https://github.com/Dullson))
- Fix Energy Shield Recharge mastery [\#4504](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4504) ([Lothrik](https://github.com/Lothrik))
- Fix warcry duration and cooldown calculations [\#4488](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4488) ([Lothrik](https://github.com/Lothrik))
- Fix a bug where if affected by a vaal aura you weren't considered affected by the regular aura [\#4492](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4492) ([QuickStick123](https://github.com/QuickStick123))
- Remove Phase Acrobatics from Impossible Escape [\#4479](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4479) ([Lothrik](https://github.com/Lothrik))
- Fix Paradoxica [\#4495](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4495) ([QuickStick123](https://github.com/QuickStick123))
- Fix ignite with cast on death [\#4496](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4496) ([QuickStick123](https://github.com/QuickStick123))
- Fix incorrect Cruelty effect scaling [\#4472](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4472) ([Lothrik](https://github.com/Lothrik))
- Fix Determination aura alternate quality mod [\#4502](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4502) ([Dullson](https://github.com/Dullson))
- Fix Smite area hit being classified as melee [\#4515](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4515) ([QuickStick123](https://github.com/QuickStick123))
- Fix Herald of Purity minions missing a duration [\#4547](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4547) ([Wires77](https://github.com/Wires77))
- Fix Chain Hook Radius per Rage [\#4491](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4491) ([Lothrik](https://github.com/Lothrik))
### Other changes
- Docs - Fix dead links and refactor to use relative links [\#4543](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4543) ([Paliak](https://github.com/Paliak))


## [v2.18.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.18.1) (2022/06/05)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.18.0...v2.18.1)

## What's Changed
### Fixed Bugs
- Fix crash related to Life gain on Block [\#4428](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4428) ([Regisle](https://github.com/Regisle))

## [v2.18.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.18.0) (2022/06/05)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.17.2...v2.18.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Add zoom support in the Notes tab (Use Ctrl +/- or Ctrl & mouse wheel) [\#4355](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4355) ([pfeigl](https://github.com/pfeigl))
- Add mouse shortcuts to skills tab [\#4373](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4373) ([Dullson](https://github.com/Dullson))
  * Set as active skill group in sidebar
  * Enable/disable skill group
  * Include/exclude in Full DPS
- Streamline importing of build codes [\#4398](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4398) ([deathbeam](https://github.com/deathbeam))
### User Interface
- Add a configuration option for showing tooltips for all slots [\#4292](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4292) ([deathbeam](https://github.com/deathbeam))
- Add average flask uptime estimate [\#4319](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4319) ([Lothrik](https://github.com/Lothrik))
- Add keyboard shortcut for Notes section "Ctrl+6" [\#4331](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4331) ([imsjp](https://github.com/imsjp))
- Improve breakdown for ignoring resistance [\#4354](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4354) ([Prismateria](https://github.com/Prismateria))
- Add Boss 'less curse effect' in resistance breakdown [\#4379](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4379) ([LocalIdentity](https://github.com/LocalIdentity))
- Split max hit display (and colourise it) in sidebar [\#4371](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4371) ([deathbeam](https://github.com/deathbeam))
- Do not overwrite all defaults when configuring enemy stats on configs page [\#4327](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4327) ([deathbeam](https://github.com/deathbeam))
- Properly sort items based on affected slot in tooltips [\#4291](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4291) ([deathbeam](https://github.com/deathbeam))
### New Calculations
- Add support for exposure from Eldritch implicits and Archdemon Crown [\#4395](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4395) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for weapon local Overwhelm mod [\#4415](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4415) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for self-damage breakdown for Forbidden Rite [\#4420](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4420) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for many helmet enchants [\#4419](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4419) ([LocalIdentity](https://github.com/LocalIdentity))
  * Animated Guardian, Energy Blades, Ensnaring Arrow, Flame Wall, Frost Shield, Herald of Agony, Hydrosphere, Plague Bearer, Purifying Flame, Wild Strike
### Accuracy Improvements
- Minor EHP improvements [\#4227](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4227) ([Regisle](https://github.com/Regisle))
- Fix Massive Thread of Hope outer radius [\#4404](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4404) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Exposure mastery stacking incorrectly [\#4396](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4396) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Painseeker disabling alt Ailments from Secrets of Suffering [\#4412](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4412) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Arrogance Support not working with blasphemy curses [\#4394](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4394) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Shaper of Winter + Storms not affecting Brittle + Sap [\#4416](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4416) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Summon Holy Relic's Boon Aura [\#234](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/234) ([kkienzle](https://github.com/kkienzle))
- Fix parsing for "chaos damage taken" [\#4383](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4383) ([Nightblade](https://github.com/Nightblade))
### Fixed Bugs
- Fix crash when loading build containing a newer tree [\#4386](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4386) ([Wires77](https://github.com/Wires77))
- Fix Viper Strike double counting Dual Wield Poison stacks [\#4406](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4406) ([Nostrademous](https://github.com/Nostrademous))
- Fix pobb.in match pattern if a "_" was at the start of the build code [\#4401](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4401) ([Dullson](https://github.com/Dullson))
- Fix an issue where the options headings sometimes appeared blank [\#4287](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4287) ([FWidm](https://github.com/FWidm))
- Fix Pantheon dropdown tooltip [\#4377](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4377) ([Wires77](https://github.com/Wires77))


## [v2.17.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.17.2) (2022/05/20)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.17.1...v2.17.2)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Fix bug when rendering jewel radius rings ([LocalIdentity](https://github.com/LocalIdentity))

## [v2.17.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.17.1) (2022/05/17)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.17.0...v2.17.1)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Fixed Bugs
- Fix bug when rendering Timeless jewel and Thread of Hope rings ([LocalIdentity](https://github.com/LocalIdentity))

## [v2.17.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.17.0) (2022/05/17)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.16.0...v2.17.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Update data from 3.18 files [\#4369](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4369) ([Nostrademous](https://github.com/Nostrademous), [LocalIdentity](https://github.com/LocalIdentity))
- Update skill tree to 3.18 ([LocalIdentity](https://github.com/LocalIdentity))
- Add new awakened exceptional skill gems from 3.18 [\#4369](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4369) ([Nostrademous](https://github.com/Nostrademous))
- Add new Sentinel uniques [\#4365](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4365) ([TPlant](https://github.com/PJacek), [LocalIdentity](https://github.com/LocalIdentity))
- Add support for Sublime Vision [\#4365](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4365) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Impossible Escape jewel [\#4350](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4350) ([disjunto](https://github.com/disjunto))
- Add support for new Thread of Hope radius [\#4348](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4348) ([Nostrademous](https://github.com/Nostrademous))
- Add support for poeskilltree.com passive tree import [\#4191](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4191) ([pHiney](https://github.com/pHiney))
### User Interface
- In item creator, treat flasks like other items with multiple tiers of mods [\#4307](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4307) ([benjaminysmall](https://github.com/benjaminysmall))
- Remove Ward regen from breakdown [\#4342](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4342) ([Lilylicious](https://github.com/Lilylicious))
### Accuracy Improvements
- Fix Vulnerability curse priority [\#4325](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4325) ([Lothrik](https://github.com/Lothrik))
- Fix Supreme Ego more Mana reservation of skills to only affect auras [\#4293](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4293) ([deathbeam](https://github.com/deathbeam))
- Fix Decay breakdown values [\#4326](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4326) ([Lothrik](https://github.com/Lothrik))
### New Calculations
- Add support for Divine Blessing + Totem Auras [\#4329](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4329) ([deathbeam](https://github.com/deathbeam), [LocalIdentity](https://github.com/LocalIdentity))
- Add support for reduced Mana cost of attacks [\#4288](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4288) ([deathbeam](https://github.com/deathbeam))
- Add support for Spellslinger reservation enchant [\#4338](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4338) ([Lothrik](https://github.com/Lothrik))
- Add support for "for Attack Damage" modifiers [\#4337](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4337) ([Lothrik](https://github.com/Lothrik))
- Add support for remaining Eldritch modifiers [\#4364](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4364) ([LocalIdentity](https://github.com/LocalIdentity))
### Fixed Bugs
- Fix crash on Energy Blade import [\#4330](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4330) ([pHiney](https://github.com/pHiney))


## [v2.16.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.16.0) (2022/03/15)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.15.1...v2.16.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Updated Exported Data to Patch 3.17.1 [\#4185](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4185) ([Nostrademous](https://github.com/Nostrademous))
- Add support for Anomalous Temporal Rift [\#4279](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4279) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for several alternate quality gems [\#4274](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4274) ([Wires77](https://github.com/Wires77))
### User Interface
- Corrected spelling of Effective Hit Pool description [\#4181](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4181) ([ForgottenHero](https://github.com/ForgottenHero))
- Show build name first in window title [\#4239](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4239) ([Lothrik](https://github.com/Lothrik))
- Update skill tree to 3.17.2 [\#4262](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4262) ([LocalIdentity](https://github.com/LocalIdentity))
- Move config tab columns vertically when screen width is too low [\#4226](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4226) ([Wires77](https://github.com/Wires77))
- Add support for showing which lines are supported on skills [\#4169](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4169) ([Wires77](https://github.com/Wires77))
### Accuracy Improvements
- Fix typo in Blackflame ring [\#4146](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4146) ([Nightblade](https://github.com/Nightblade))
- Fix missing catalyst on 'Mark of the Elder' ring [\#4188](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4188) ([Nostrademous](https://github.com/Nostrademous))
- Fix missing duration flag on Flame Surge [\#4232](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4232) ([Lothrik](https://github.com/Lothrik))
- Fix Bannerman notable applying all attack damage to non-banner auras [\#4175](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4175) ([Wires77](https://github.com/Wires77))
- Fix Dancing Duo Cyclone dealing twice as much damage as it should be [\#4249](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4249) ([Lexy](https://github.com/learn2draw))
- Fix blastchain mine not applying less damage to all gems [\#4247](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4247) ([Lilylicious](https://github.com/Lilylicious))
- Fix Kinetic Bolt and Earthquake not fully scaling with Spell Damage/Cast Speed [\#4151](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4151) ([mthjones](https://github.com/mthjones))
- Fix an issue where all skills socketed in Black Zenith would get the damage multiplier [\#4164](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4164) ([Wires77](https://github.com/Wires77))
- Fix Bow Projectile Speed conversion mastery applying to DoT damage [\#4148](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4148) ([Lilylicious](https://github.com/Lilylicious))
- Fix chilling areas not applying Bonechill [\#4161](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4161) ([TPlant](https://github.com/PJacek))
- Fix quality on Absolution applying to players [\#4211](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4211) ([Lilylicious](https://github.com/Lilylicious))
- Fix missing spell flag on triggered spells from Atziri's Rule [\#4236](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4236) ([Lothrik](https://github.com/Lothrik))
- Remove Royale mods from crafting dropdowns [\#4225](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4225) ([Wires77](https://github.com/Wires77))
- Fix Advanced Traps quality not increasing damage [\#4224](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4224) ([Lilylicious](https://github.com/Lilylicious))
- Fix an issue where Secrets of Suffering wasn't applying [\#4177](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4177) ([Wires77](https://github.com/Wires77))
- Fix Battlemage's Cry not applying spell damage to attacks [\#4170](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4170) ([Wires77](https://github.com/Wires77))
- Fix parsing of Soul of Abberath self Ignite duration [\#4276](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4276) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Challenger Charges affecting Cast Speed [\#4264](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4264) ([LocalIdentity](https://github.com/LocalIdentity))
- Apply global limit to Expansive Might notable [\#4255](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4255) ([Lothrik](https://github.com/Lothrik))
### Fixed Bugs
- Fix error when comparing passive tree skill nodes [\#4238](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4238) ([Lothrik](https://github.com/Lothrik))
- Fix two errors related to equipped items [\#4237](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4237) ([Lothrik](https://github.com/Lothrik))
- Fix crash caused by Mortal Conviction still appearing on some uniques [\#4231](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4231) ([Wires77](https://github.com/Wires77))
- Display session ID box when 401 error is encountered on Import [\#4187](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4187) ([Wires77](https://github.com/Wires77))
- Fix ensnare stacks not showing for Ensnaring Arrow [\#4160](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4160) ([Wires77](https://github.com/Wires77))
### Other changes
- Prevent saving default settings to XML [\#4189](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4189) ([Lothrik](https://github.com/Lothrik))

## [v2.15.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.15.1) (2022/02/13)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.15.0...v2.15.1)

## What's Changed

### Fixed Bugs
- Fix Forbidden Flame/Flesh not working with Scion [\#4142](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4142) ([Nostrademous](https://github.com/Nostrademous))


## [v2.15.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.15.0) (2022/02/12)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.14.0...v2.15.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements
- Add / updated all new league uniques [\#4098](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4098) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Delirium effect scaling [\#4134](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4134) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Elementalist's Primal Aegis [\#4112](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4112) ([Wires77](https://github.com/Wires77))
- Add support to show Life Recoverable when Life is reserved [\#4096](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4096) ([Regisle](https://github.com/Regisle))
- Add support for 2 new cluster jewel mods added in 3.17 [\#4128](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4128) ([LocalIdentity](https://github.com/LocalIdentity))

### User Interface
- Add colours to the sidebar, config page, and calcs page [\#4105](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4105) ([LocalIdentity](https://github.com/LocalIdentity))
- Add option to hide Warnings [\#4088](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4088) ([Nightblade](https://github.com/Nightblade))
- Add configuration option for IPv4/IPv6 connections [\#4059](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4059) ([Lothrik](https://github.com/Lothrik))
- Improved formatting for eHP calc sections [\#4103](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4103) ([Regisle](https://github.com/Regisle))

### New Calculations
- Add support for Holy Relic Nova trigger rate [\#4051](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4051) ([Solofme](https://github.com/Solofme))

### Accuracy Improvements
- Fix Rigwald's Curse mod parsing [\#4131](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4131) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix uniques that used old Blood Magic wording [\#4129](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4129) ([LocalIdentity](https://github.com/LocalIdentity))

### Fixed Bugs
- Fix crash when activating Energy Blade buff [\#4114](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4114) ([Nostrademous](https://github.com/Nostrademous))
- Fix Dancing Dervish not working ([LocalIdentity](https://github.com/LocalIdentity))
- Fix issue where General's Cry would set attack rate to 1 for certain skills [\#4126](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4126) ([Sour](https://github.com/Sour))
- Fix issue when importing Forbidden Flame/Flesh [\#4121](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4121) ([Nostrademous](https://github.com/Nostrademous))
- Fix for culling strike on mirages adding extra damage [\#4116](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4116) ([Nostrademous](https://github.com/Nostrademous))
- Fix an issue where degens were not working with Mind Over Matter [\#4095](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4095) ([Regisle](https://github.com/Regisle))
- Fix issue where certain modifiers weren't being converted properly (e.g. Battlemage) [\#4086](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4086) ([Wires77](https://github.com/Wires77))
- Fix an issue where the chance to inflict an ailment on a critical strike could be lower than on a non-crit for alternate ailments [\#4127](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4127) ([Wires77](https://github.com/Wires77))

### Misc
- Update display screenshots on GitHub [\#4136](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4136) ([Nightblade](https://github.com/Nightblade))


## [v2.14.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.14.0) (2022/02/04)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.13.0...v2.14.0)

<!-- Release notes generated using configuration in .github/release.yml at dev -->

## What's Changed
### Implemented Enhancements

- Add 3.17 skill tree [\#3972](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3972) ([dbjorge](https://github.com/dbjorge))
- Update uniques with changes from 3.17 patch notes [\#3974](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3974) ([ifnjeff](https://github.com/ifnjeff))
- Add support to enable stages for multi-part skills at a per-part level [\#3859](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3859) ([Nostrademous](https://github.com/Nostrademous))
- Add support to show stat difference on anointed nodes [\#3827](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3827) ([KillerMZE](https://github.com/KillerMZE))
- Add support for Bow Mastery and Arcing Shot Notable [\#3543](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3543) ([Peechey](https://github.com/Peechey))
- Add support for new bow mastery mods [\#3978](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3978) ([madinsane](https://github.com/madinsane))
- Add Support for Elusive Claw Mastery modifier [\#3992](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3992) ([Nostrademous](https://github.com/Nostrademous))
- Add "Cursed Enemies are Hindered" Mastery [\#3919](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3919) ([Lothrik](https://github.com/Lothrik))
- Add support for Energy Blade [\#3580](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3580) ([PJacek](https://github.com/PJacek))
- Add support for several spectres: Arena Master, Ruins Hellion (partial), Trial Windchaser, Aurid Synthete, Ancient Wraith, They of Tul, Ancient Suffering, Merveil's Retainer, Primal Crushclaw, and Primal Rhex Matriarch [\#3932](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3932) ([Lothrik](https://github.com/Lothrik))
- Add support for new Precision Technique Keystone [\#4004](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4004) ([Nostrademous](https://github.com/Nostrademous))
- Add support for new wording on War Bringer Keystone [\#3976](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3976) ([madinsane](https://github.com/madinsane))
- Add support for Master of Fear Notable [\#3803](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3803) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Adder's Touch Notable [\#4002](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4002) ([Nostrademous](https://github.com/Nostrademous))
- Add support for Champion's Inspirational Banner Life Regen [\#3742](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3742) ([mthjones](https://github.com/mthjones))
- Add support for Brand Attachment Range [\#3896](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3896) ([Lothrik](https://github.com/Lothrik))
- Add support for Lifetap's "20% increased Life Recovery from Flasks" modifier [\#3906](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3906) ([Lothrik](https://github.com/Lothrik))
- Add support for Anomalous Vitality [\#3910](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3910) ([Lothrik](https://github.com/Lothrik))
- Add support for Melding of the Flesh [\#3923](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3923) ([Lexy](https://github.com/learn2draw))
- Add support for Leadership Price's conflux mod [\#3271](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3271) ([PJacek](https://github.com/PJacek))
- Add support for new "for spell damage" tree mod [\#4055](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4055) ([Lothrik](https://github.com/Lothrik))
- Add support for Strength of Blood less damage taken [\#3983](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3983) ([deathbeam](https://github.com/deathbeam))
- Add support for Elemental Hit area component [\#3926](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3926) ([Lothrik](https://github.com/Lothrik))
- Add support for Cluster Jewel Corruptions [\#3848](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3848) ([randomflyingtaco](https://github.com/randomflyingtaco))
- Add Polaric Devastation ring [\#4001](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4001) ([Nostrademous](https://github.com/Nostrademous))
- Add race event uniques [\#3874](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3874) ([pHiney](https://github.com/pHiney))
- Add support for Black Zenith, The Gluttonous Tide, and Divine Inferno [\#4061](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4061) ([Wires77](https://github.com/Wires77))
- Add support for Crystallised Omniscience [\#3937](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3937) ([Lexy](https://github.com/learn2draw))
- Add support for Atziri's Rule [\#4039](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4039) ([Nostrademous](https://github.com/Nostrademous))
- Add support for Amanamu's Gaze, Kurgal's Gaze, and Tecrod's Gaze [\#4020](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4020) ([Lothrik](https://github.com/Lothrik))
- Add support for several veiled uniques: Paradoxica, Replica Paradoxica, Cane of Kulemak, and The Queen's Hunger [\#3985](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3985) ([Prismateria](https://github.com/Prismateria))
- Add support for Mageblood [\#3883](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3883) ([Nostrademous](https://github.com/Nostrademous))
- Add support for Forbidden Flesh and Flame [\#3975](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3975) ([Nostrademous](https://github.com/Nostrademous))
- Add support for Willowgift [\#3763](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3763) ([randomflyingtaco](https://github.com/randomflyingtaco))
- Add partial support for Fleshcrafter [\#3956](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3956) ([PJacek](https://github.com/PJacek))

### User Interface
- Add QoL improvements for import tab [\#3818](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3818), [\#4054](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4054) ([Dullson](https://github.com/Dullson), [Peechey](https://github.com/Peechey))
- Add pobb.in to import website list [\#3942](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3942) ([Dav1dde](https://github.com/Dav1dde))
- Add poe.ninja/pob to import website list [\#3732](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3732) ([rasmuskl](https://github.com/rasmuskl))
- Add support to import build codes from poe.ninja and pobb.in [\#4042](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4042) ([Wires77](https://github.com/Wires77))
- Add support to export a build to pobb.in [\#4017](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4017) ([Peechey](https://github.com/Peechey))
- Add Ctrl+I hotkey to import build code [\#3813](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3813) ([pHiney](https://github.com/pHiney))
- Add feature to remember your last used export site in settings [\#4053](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4053) ([Dav1dde](https://github.com/Dav1dde))
- Delete jewels, skills, and equipment by default on character import [\#3931](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3931) ([raylu](https://github.com/raylu))
- Remove trailing and leading spaces from the character name when importing [\#3950](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3950) ([pHiney](https://github.com/pHiney))
- Relabel character import "Done" button to "Close"  [\#3898](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3898) ([raylu](https://github.com/raylu))
- Add ability to search skills using multiple tags [\#3921](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3921) ([pHiney](https://github.com/pHiney))
- Add feature to match gem level to character level [\#3917](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3917) ([Lothrik](https://github.com/Lothrik))
- Add ability to show DPS for non-cooldown traps and mines [\#3907](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3907) ([Lothrik](https://github.com/Lothrik))
- Add 'Delete Unused' button on the items tab [\#3949](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3949), [\#4057](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4057) ([pHiney](https://github.com/pHiney), [Lothrik](https://github.com/Lothrik))
- Add E hotkey to edit equipped item [\#3876](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3876) ([pHiney](https://github.com/pHiney))
- Move delve mods to "Add modifier..." menu while crafting items [\#3213](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3213) ([Tom Clancy Is Dead](https://github.com/Voronoff))
- Add more explanation to non-damaging ailment breakdown [\#4012](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4012) ([Lilylicious](https://github.com/Lilylicious))
- Add support to maximum animated weapon from gem level instead of configuration [\#3935](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3935) ([Wires77](https://github.com/Wires77))
- Add config options for self-chill builds [\#3294](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3294) ([Lilylicious](https://github.com/Lilylicious))
- Update dropdowns to dynamically resize based on their content [\#3726](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3726) ([pHiney](https://github.com/pHiney))
- Add Armour and Evasion sorting to the tree and uniques tab [\#3697](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3697) ([Lexy](https://github.com/learn2draw))
- Add Mastery tooltip for an unallocated node when comparing trees [\#3840](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3840) ([pHiney](https://github.com/pHiney))
- Add improvements to multiple passive tree jewel socket management [\#3897](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3897) ([Lothrik](https://github.com/Lothrik))
- Update tree images to use the latest colours[\#4036](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4036) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Passive Tree Management Titles [\#3962](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3962) ([pHiney](https://github.com/pHiney))

### New Calculations
- Implement Effective HP and overhaul defence calculations to be more accurate [\#2390](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2390) ([Regisle](https://github.com/Regisle))
- Overhaul non-damaging elemental ailment calculations [\#3271](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3271) ([PJacek](https://github.com/PJacek))
- Overhaul Bleed/Ignite Ailment calculation to use weighted average [\#3927](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3927) ([Nostrademous](https://github.com/Nostrademous))
- Add support for ongoing costs of skills [\#3663](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3663) ([PJacek](https://github.com/PJacek))
- Add support for new mod conversion modifiers [\#3335](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3335) ([PJacek](https://github.com/PJacek))
- Add support to round Duration of Skills to server ticks [\#3864](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3864) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for triple Elemental Damage [\#3946](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3946) ([Nostrademous](https://github.com/Nostrademous))
- Add support for additional life recovery flask mods [\#3958](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3958) ([Peechey](https://github.com/Peechey))
- Add support for full Ball Lightning damage calculations [\#3940](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3940) ([MoldyDwarf](https://github.com/MoldyDwarf))
- Add support for Global buffs/debuffs from Spectres [\#3932](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3932) ([Lothrik](https://github.com/Lothrik))
- Add support for flask charge generation and uptime [\#3993](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3993) ([deathbeam](https://github.com/deathbeam))
- Add full support for curse priority [\#3930](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3930) ([Lothrik](https://github.com/Lothrik))

### Accuracy Improvements
- Add warnings when the build is impossible in-game [\#3836](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3836) ([KillerMZE](https://github.com/KillerMZE))
- Add feature to guess the main socket group when importing a character [\#3899](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3899) ([raylu](https://github.com/raylu))
- Add missing mods to Armour and Evasion breakdown [\#4011](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4011) ([LocalIdentity](https://github.com/LocalIdentity))
- Add missing Fate/Story of the Vaal modifiers [\#3918](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3918) ([Lothrik](https://github.com/Lothrik))
- Add missing Bone Offering quality effect [\#3860](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3860) ([Lothrik](https://github.com/Lothrik))
- Add cap to Explosive Arrow Bonus Explosion Radius [\#4032](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4032) ([Lothrik](https://github.com/Lothrik))
- Update Chaos Resistance roll on unique rings with 3.17 values [\#3986](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3986) ([facepalmgamer](https://github.com/facepalmgamer))
- Update ignite value from 125% to 90% due to 3.17 changes [\#4005](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4005) ([JustinmClapperton](https://github.com/JustinmClapperton))
- Update Crimson Storm changes [\#3990](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3990) ([lpolaright](https://github.com/lpolaright))
- Update Whispering Ice and its trigger conditions [\#4015](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4015) ([Nostrademous](https://github.com/Nostrademous))
- Update Kraityn's bandit rewards based on 3.16 values [\#3959](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3959) ([Prismateria](https://github.com/Prismateria))
- Update Kingmaker with 3.16 changes[\#3928](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3928) ([Wires77](https://github.com/Wires77))
- Update Blightwell and Solstice Vigil to 3.16.0 [\#3916](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3916) ([Lothrik](https://github.com/Lothrik))
- Update Saqawals Flock to 3.16 values [\#3707](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3707) ([Lexy](https://github.com/learn2draw))
- Update Survival Jewels to 3.16.0 [\#3799](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3799) ([Lothrik](https://github.com/Lothrik))
- Update skill cooldown to display in milliseconds [\#3865](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3865) ([LocalIdentity](https://github.com/LocalIdentity))
- Update Brass Dome to 3.16 values [\#3739](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3739), [\#3871](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3871) ([olop4444](https://github.com/olop4444), [Lilylicious](https://github.com/Lilylicious))
- Update wording for several "On Kill" modifiers [\#3987](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3987) ([facepalmgamer](https://github.com/facepalmgamer))
- Remove minion cast speed from Ancient Skull [\#4023](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4023) ([Lothrik](https://github.com/Lothrik))
- Improve damage calculation for General's Cry [\#3220](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3220) ([Helyos96](https://github.com/Helyos96))
- Fix Viper Strike Poison Stacks when Dual Wielding [\#3868](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3868) ([Nostrademous](https://github.com/Nostrademous))
- Fix Charged Dash DPS calculations [\#3125](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3125) ([VaticViolet](https://github.com/VaticViolet))
- Fix Divergent Blood Rage not applying life leech [\#3995](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3995) ([Prismateria](https://github.com/Prismateria))
- Fix Fortify parsing on Legacy items [\#3928](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3928) ([Wires77](https://github.com/Wires77))
- Fix incorrect modifiers on Survivor's Guilt [\#4047](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4047) ([Nostrademous](https://github.com/Nostrademous))
- Fix Two-Toned boots getting the wrong base type [\#3714](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3714) ([Wires77](https://github.com/Wires77))
- Fix skills from items incorrectly getting +1 level from Awakened gems [\#3960](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3960) ([Wires77](https://github.com/Wires77))
- Various fixes for Beacon of Madness boots [\#3741](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3741) ([mthjones](https://github.com/mthjones))
- Fix missing implicit on Sidhebreath [\#3911](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3911) ([Lothrik](https://github.com/Lothrik))
- Fix incorrect reservation on some legacy builds [\#3909](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3909) ([Lothrik](https://github.com/Lothrik))
- Fix The Admiral to use the correct "elemental damage taken" value  [\#3913](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3913) ([Lothrik](https://github.com/Lothrik))
- Fix Transcendent Flesh values not matching in game values when rounding [\#3904](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3904) ([Wires77](https://github.com/Wires77))
- Fix Phantasmal Sigil of Power spell damage buff not applying [\#3800](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3800) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix bleed damage against poisoned enemy mastery [\#3700](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3700) ([Peechey](https://github.com/Peechey))
- Fix rounding on gear base percentiles [\#3715](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3715) ([Wires77](https://github.com/Wires77))
- Fix Increased Wither Effect to not affect minions [\#3769](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3769) ([Nostrademous](https://github.com/Nostrademous))
- Fix Awakened Elemental Focus not granting +1 level to Elemental Gems [\#3770](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3770) ([Nostrademous](https://github.com/Nostrademous))
- Fix Enemy Physical Damage Reduction not being capped at 90% in all circumstances [\#3775](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3775), [\#4037](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4037) ([Nostrademous](https://github.com/Nostrademous), [madinsane](https://github.com/madinsane))
- Fix parsing for "chance to defend with X% armour" [\#3696](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3696) ([Nostrademous](https://github.com/Nostrademous))
- Fix Rage Support disabling Ancestral Totems buff [\#3798](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3798) ([Lothrik](https://github.com/Lothrik))
- Fix Elementalist exposure node not working with exposure mastery [\#3801](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3801) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Summon Raging Spirit to have 100% fire conversion [\#3808](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3808) ([Kayella](https://github.com/Kayella))
- Fix trigger rate for skills with overridden cooldowns [\#3832](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3832) ([Nostrademous](https://github.com/Nostrademous))
- Fix incorrect Elusive Buff effect from skills when using Withering Step [\#3814](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3814) ([Nostrademous](https://github.com/Nostrademous))
- Fix an issue where some extra stats were showing when copying from trade [\#3889](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3889) ([Nostrademous](https://github.com/Nostrademous))
- Fix an issue when copying magic Two-Toned Boots from trade [\#3891](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3891) ([Wires77](https://github.com/Wires77))
- Fix an issue where culling DPS wasn't factored in for Full DPS totals [\#3894](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3894) ([Nostrademous](https://github.com/Nostrademous))
- Fix triggering skill not properly selected when trigger support came from an item [\#3905](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3905) ([Nostrademous](https://github.com/Nostrademous))
- Fix issue where Soul of Solaris was not displaying the "Nearby Enemies" config option [\#3925](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3925) ([Lothrik](https://github.com/Lothrik))
- Fix issues when parsing Inspired Learning and Pure Talent [\#3914](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3914) ([Nostrademous](https://github.com/Nostrademous))
- Fix various errors when generating a Power Report [\#3938](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3938) ([Nostrademous](https://github.com/Nostrademous))
- Fix Battlemage not applying the correct conversion in some cases [\#3893](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3893) ([Wires77](https://github.com/Wires77))
- Fix issue where 'defend with % armour' mastery affected total armour value [\#4006](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4006) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix issue where Vaal Blade Vortex hit rate was too high [\#4030](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4030) ([Sakux323](https://github.com/Sakux323))
- Fix error when using culling on Mirage Archer, calculating full DPS [\#4066](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4066) ([Nostrademous](https://github.com/Nostrademous))
- Fix parsing for several Projectile Attack modifiers [\#3851](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3851) ([Lothrik](https://github.com/Lothrik))
- Fix parsing for Darkness Enthroned [\#3710](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3710) ([Wires77](https://github.com/Wires77))
- Fix parsing for Marauder's modifier on Pure Talent [\#3875](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3875) ([pHiney](https://github.com/pHiney))
- Fix parsing for "charges used" modifiers on flasks [\#3802](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3802) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix 'inflicted with this weapon' parsing [\#3776](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3776) ([Nostrademous](https://github.com/Nostrademous))

### Fixed Bugs
- Fix crash caused at certain zoom levels of the passive tree [\#3953](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3953) ([pHiney](https://github.com/pHiney))
- Fix crash with FullDPS and disabled socket groups [\#3766](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3766) ([Nostrademous](https://github.com/Nostrademous))
- Fix Poet's Pen dps calcs not working [\#3724](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3724) ([wrzoski](https://github.com/wrzoski))
- Fix error related to gem recommendations and Full DPS [\#3954](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3954) ([Nostrademous](https://github.com/Nostrademous))
- Fix infinite reservation error with Relic of the Pact [\#3952](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3952) ([Lothrik](https://github.com/Lothrik))
- Fix a bug where maximum Life could be negative [\#3908](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3908) ([Lothrik](https://github.com/Lothrik))
- Fix issue when saving a converted passive tree [\#3912](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3912) ([Lothrik](https://github.com/Lothrik))

### Misc
- Add FullDPS breakdown into XML Build Save file [\#4018](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/4018) ([Nostrademous](https://github.com/Nostrademous))


## [2.13.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.13.0) (2021/11/02)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.12.3...v2.13.0)

**Implemented enhancements:**

- Add Ravenous Misshapen Spectre [\#3687](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3687) ([LocalIdentity](https://github.com/LocalIdentity))
- Add Pale Seraphim Spectre [\#3686](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3686) ([LocalIdentity](https://github.com/LocalIdentity))
- Add Pale Angel Spectre [\#3639](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3639) ([Kayella](https://github.com/Kayella))
- Add Demon Harpy Spectre [\#3638](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3638) ([Kayella](https://github.com/Kayella))
- Add Demon Herder Spectre [\#3656](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3656) ([Kayella](https://github.com/Kayella))
- Add dynamically changing width for dropdown box when selecting tree [\#3676](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3676) ([pHiney](https://github.com/pHiney))
- Add support for gem level modifiers of socketed active skill gems [\#3658](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3658) ([etojuice](https://github.com/etojuice))
- Add support for "chance to Defend with x% of Armour" masteries [\#3667](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3667) ([Nostrademous](https://github.com/Nostrademous))

**Fixed bugs:**

- Fix crash when attempting to save build after character import [\#3654](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3654) ([Peechey](https://github.com/Peechey))
- Fix build list loading crash [\#3626](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3626) ([PJacek](https://github.com/PJacek))
- Fix Multistrike Support not applying its damage multiplier to Ailments [\#3685](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3685) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Multistrike Support not providing attack speed to gems with multiple skill parts [\#3684](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3684) ([LocalIdentity](https://github.com/LocalIdentity))
	- Molten Strike, Lightning Strike, Wild Strike and Frost Blades
- Fix Attack/Cast rate cap [\#3677](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3677) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Stationary setting box sometimes not showing up [\#3666](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3666) ([randomflyingtaco](https://github.com/randomflyingtaco))
- Fix eHP double dipping on damage taken modifiers [\#3695](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3695) ([Lothrik](https://github.com/Lothrik))
- Fix Small Curse Cluster Jewels rendering on the tree when socketed [\#3651](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3651) ([Peechey](https://github.com/Peechey))
- Fix Mines incorrectly counting towards "number of Auras affecting you" mastery [\#3693](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3693) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Spell Suppression mastery giving double Critical Strike chance [\#3678](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3678) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Voltaxic Burst's "number of Casts currently waiting" not adding damage [\#3691](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3691) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Flame Totem Consecrated Ground enchantment [\#3689](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3689) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix parsing for Curse on Hit rings [\#3680](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3680) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix parsing for mod on The Taming ring [\#3692](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3692) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix parsing for Impresence Mana Reservation mod [\#3679](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3679) ([LocalIdentity](https://github.com/LocalIdentity))

## [2.12.3](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.12.3) (2021/10/28)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.12.2...v2.12.3)

**Fixed bugs:**

- Fix crash when importing/opening builds ([LocalIdentity](https://github.com/LocalIdentity))

## [2.12.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.12.2) (2021/10/28)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.12.1...v2.12.2)

**Fixed bugs:**

- Fix crash when using Blood Magic Keystone ([LocalIdentity](https://github.com/LocalIdentity))

## [2.12.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.12.1) (2021/10/28)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.12.0...v2.12.1)

**Fixed bugs:**

- Fix several bugs relating to armour calculations on items ([Wires77](https://github.com/Wires77))

## [2.12.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.12.0) (2021/10/28)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.11.1...v2.12.0)

**Implemented enhancements:**

- Add support for Nightblade Dagger Mastery [\#3636](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3636) ([Dullson](https://github.com/mthjones))
- Add support for Sword Mastery for Offhand Accuracy [\#3498](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3498) ([Nostrademous](https://github.com/Nostrademous))
- Add support for +3 levels Critical support gem mastery [\#3566](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3566) ([Wires77](https://github.com/Wires77))
- Add support for variable ES bypass for Chaos Damage mastery [\#3509](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3509) ([Dullson](https://github.com/Dullson))
- Add support for Active Aura Multiplier and Active Herald/Aura mods [\#3353](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3353) ([Dullson](https://github.com/Dullson))
- Add support for "Enemies Ignited or Chilled by you have -5% to Elemental Resistances" [\#3615](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3615) ([Peechey](https://github.com/Peechey))
- Change Timeless Jewel passive nodes in dropdown selection menu to appear in alphabetical order [\#3551](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3551) ([etojuice](https://github.com/etojuice))
- Update passive tree ([LocalIdentity](https://github.com/LocalIdentity))
- Update Dodge breakdown on Calcs page [\#3535](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3535) ([etojuice](https://github.com/etojuice))
- Update Uniques that previously used Dodge [\#3630](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3630) ([LocalIdentity](https://github.com/LocalIdentity))
- Update The Squire, The Oppressor, Uul-Netol's Vow with ranges and modifiers [\#3591](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3591) ([Nostrademous](https://github.com/Nostrademous))

**Fixed bugs:**

- Fix importing passive tree data from player profiles [\#3600](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3600) ([Peechey](https://github.com/Peechey))
- Fix import/export of passive tree on the tree tab [\#3472](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3472) ([hdwatts](https://github.com/hdwatts))
- Fix scourged mods not importing properly [\#3603](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3603) ([Wires77](https://github.com/Wires77))
- Fix masteries persisting after resetting the tree [\#3556](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3556) ([etojuice](https://github.com/etojuice))
- Fix overcap display for Spell Block [\#3627](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3627) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix calculations for variable base armour values [\#3608](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3608) ([Wires77](https://github.com/Wires77))
- Fix Mana Efficiency rounding [\#3604](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3604) ([HPSource](https://github.com/HPSource))
- Fix bug on builds that had 100% reduced Reservation Efficiency and were using Arcane Cloak [\#3553](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3553) ([Peechey](https://github.com/Peechey))
- Fix rounding for attribute bonuses [\#3607](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3607) ([etojuice](https://github.com/etojuice))
- Fix Flask More/Less Duration applying globally instead of locally [\#3584](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3584) ([Peechey](https://github.com/Peechey))
- Fix new uniques to use exceptional gems [\#3541](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3541) ([Lexy](https://github.com/learn2draw))
- Fix Righteous Fire to use 3.16 life multiplier [\#3611](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3611) ([Lilylicious](https://github.com/Lilylicious))
- Fix Collateral Damage Jewel to affect Galvanic Arrow [\#3579](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3579) ([randomflyingtaco](https://github.com/randomflyingtaco))
- Fix Arcanist Brand not applying more damage with Hits [\#3622](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3622) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Awakened Elemental Focus not giving +1 to supported elemental gems [\#3629](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3629) ([randomflyingtaco](https://github.com/randomflyingtaco))
- Fix Nightblade Crit Multi not scaling with Elusive effect [\#3550](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3550) ([mthjones](https://github.com/mthjones))
- Fix Divergent Fortify not working [\#3623](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3623) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Awakened Cast on Critical Strike not applying cooldown recovery to skills [\#3624](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3624) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Explosive Arrow skill on Spectres [\#3621](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3621) ([LocalIdentity](https://github.com/LocalIdentity))

## [2.11.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.11.1) (2021/10/23)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.11.0...v2.11.1)

**Fixed bugs:**

- Fix mods when crafting Cluster Jewels + items [\#3575](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3575) ([Wires77](https://github.com/Wires77))
- Fix Storm + Armageddon Brand hit damage [\#3577](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3577) ([Lilylicious](https://github.com/Lilylicious))

## [2.11.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.11.0) (2021/10/22)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.10.0...v2.11.0)

**Implemented enhancements:**

- Improve mastery node effect selection UI [\#3476](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3476) ([Tom Clancy Is Dead](https://github.com/Voronoff))
- Update almost all existing gems with 3.16 changes [\#3570](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3570) ([LocalIdentity](https://github.com/LocalIdentity))
- Add the ability to click a label to check the associated checkbox [\#3549](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3549) ([ajryan](https://github.com/ajryan))
- Add support for Fortification [\#3540](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3540) ([Zpooks](https://github.com/Zpooks)) ([AlphaCheese](https://github.com/AlphaCheese))
- Add support for Poisonous Concoction [\#3510](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3510) ([Lexy](https://github.com/learn2draw))
- Improve build list loading speed [\#3500](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3500) ([PJacek](https://github.com/PJacek))
- Add Accuracy Bonus per Dexterity Mastery [\#3489](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3489) ([enizor](https://github.com/enizor))
- Update Consecrated Ground Life Regen % [\#3391](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3391) ([mthjones](https://github.com/mthjones))
- Add support for Mark of the Red Covenant ignite mod [\#3530](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3530) ([LocalIdentity](https://github.com/LocalIdentity))
- Add Scourge mods and base type values [\#3568](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3568) ([Wires77](https://github.com/Wires77))
- Remove attribute tag from "Reduced Attribute Requirements" mods [\#3528](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3528) ([randomflyingtaco](https://github.com/randomflyingtaco))
- Add support for "All Damage with Maces and Sceptres inflicts Chill" [\#3515](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3515) ([Peechey](https://github.com/Peechey))
- Add support for "Increased Melee Damage with Hits at Close Range" [\#3511](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3511) ([Dullson](https://github.com/Dullson))
- Add support for "Each Mine applies 2% increased Damage taken to Enemies near it, up to 10%" [\#3506](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3506) ([Lothrik](https://github.com/Lothrik))
- Add Defiance Banner to the Config tab [\#3505](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3505) ([uilman](https://github.com/uilman))
- Add support for the "not taken damage recently" clause [\#3504](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3504) ([Dullson](https://github.com/Dullson))
- Add support for "Non-Projectile Chaining Lightning Skills Chain +1 times" [\#3503](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3503) ([Dullson](https://github.com/Dullson))
- Add support for Surveillance notable [\#3501](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3501) ([Lothrik](https://github.com/Lothrik))
- Update Transcendence Keystone to 3.16 value [\#3477](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3477) ([enizor](https://github.com/enizor))
- Add support for 3.16 Elemental Equilibrium [\#3474](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3474) ([Lothrik](https://github.com/Lothrik))
- Add support for Gladiator Violent Retaliation and Ascendant Gladiator nodes [\#3465](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3465) ([Peechey](https://github.com/Peechey))
- Add support complex custom modifiers [\#3462](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3462) ([SaloEater](https://github.com/SaloEater))
- Add support for double damage mod on mace masteries [\#3457](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3457) ([uilman](https://github.com/uilman))
- Add support for recovering ES on spell block from Safeguard [\#3454](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3454) ([jppianta](https://github.com/jppianta))
- Add support for Life Regeneration Rate [\#3450](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3450) ([SaloEater](https://github.com/SaloEater))
- Add support for Bastion of Hope stun avoidance [\#3447](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3447) ([etojuice](https://github.com/etojuice))
- Add parsing for mods that work with multiple weapons [\#3446](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3446) ([SaloEater](https://github.com/SaloEater))
- Add parsing for new Storm Weaver Shocked/Frozen mod [\#3445](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3445) ([Quote_a](https://github.com/Quotae))
- Add support for "Increased Damage with Bleeding inflicted on Poisoned Enemies" [\#3438](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3438) ([monerofglory](https://github.com/monerofglory))
- Add labeling to chaos resistance to show when you have CI [\#3431](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3431) ([Lilylicious](https://github.com/Lilylicious))
- Add support for new mark movement speed mastery [\#3425](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3425) ([sida-wang](https://github.com/sida-wang))
- Add support for "Intimidate Enemies for 4 seconds on Block while holding a Shield" [\#3416](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3416) ([etojuice](https://github.com/etojuice))
- Add support for "Cannot be Ignited while on Low Life" [\#3415](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3415) ([etojuice](https://github.com/etojuice))
- Add support for "Increased Damage when using Bow and Totem" [\#3410](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3410) ([Peechey](https://github.com/Peechey))
- Add support for "Crush Enemies on Hit with Maces and Sceptres" [\#3408](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3408) ([Peechey](https://github.com/Peechey))
- Add support for "Auras from your Skills have x% increased Effect on you" [\#3407](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3407) ([etojuice](https://github.com/etojuice))
- Add support for "if you have detonated a mine recently" [\#3398](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3398) ([uilman](https://github.com/uilman))
- Add support for "minions attacks overwhelm X% physical damage reduction" [\#3398](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3398) ([uilman](https://github.com/uilman))
- Add support for 3.16 Wind Dancer [\#3295](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3295) ([Zpooks](https://github.com/Zpooks))
- Add support for "Dual Wielding does not inherently grant chance to Block Attack Damage" [\#3387](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3387) ([Peechey](https://github.com/Peechey))

**Fixed bugs:**

- Fix options appearing on the configs screen for old ascendancy nodes  [\#3496](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3496) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix DPS sorting of Awakened Gems [\#3466](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3466) ([Nostrademous](https://github.com/Nostrademous))
- Fix edited Legion jewel nodes not saving/loading properly [\#3423](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3423) ([Lothrik](https://github.com/Lothrik))
- Fix replacement of notable passives conquered by Eternal Empire [\#3552](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3552) ([etojuice](https://github.com/etojuice))
- Fix Cruelty capping at 50% instead of 40% [\#3495](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3495) ([jfarrell731](https://github.com/jfarrell731))
- Fix Elemental Ailment Duration on you applying to bleed and poison duration [\#3483](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3483) ([etojuice](https://github.com/etojuice))
- Fix issue where node next to mastery node would remain allocated after Thread of Hope was removed [\#3480](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3480) ([bit-skipper](https://github.com/bit-skipper))
- Fix estimated act putting you in the endgame too early [\#3470](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3470) ([magnusvmt](https://github.com/magnusvmt))
- Fix Solipsism removing the Intelligence bonus to mana [\#3455](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3455) ([SaloEater](https://github.com/SaloEater))
- Fix Reigning Veteran [\#3449](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3449) ([Peechey](https://github.com/Peechey))
- Fix visual bug causing node paths to appear broken [\#3405](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3405) ([summ1else](https://github.com/summ1else))
- Fix overcapped Resistances displaying decimal values [\#3393](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3393) ([monerofglory](https://github.com/monerofglory))
- Fix jewel data on converted trees [\#3441](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3441) ([bit-skipper](https://github.com/bit-skipper))
- Fix issue where the duration from Swift Affliction wasn't applying to ignites [\#3250](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3250) ([Zpooks](https://github.com/Zpooks))

## [2.10.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.10.0) (2021/10/19)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.9.0...v2.10.0)

**Implemented enhancements:**

- Add balance updates from 3.16.0 v3 tree [\#3414](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3414) ([Wires77](https://github.com/Wires77))
- Add support for mastery mod: Block Attack Damage if Not Blocked Recently [\#3387](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3387) ([Peechey](https://github.com/Peechey))
- Add support for mastery mod: Intelligence is added to Accuracy Rating with Wands [\#3341](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3341) ([sida-wang](https://github.com/sida-wang))

**Fixed bugs:**

- Fix spell suppression label in Calcs tab [\#3369](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3369) ([frodon1](https://github.com/frodon1))
- Fix crash when using Mistwall [\#3360](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3360) ([Tom Clancy Is Dead](https://github.com/Voronoff))
- Fix missing onslaught mods for Daresso's Defiance [\#3349](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3349) ([jfindley](https://github.com/jfindley))

## [2.9.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.9.0) (2021/10/18)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.8.0...v2.9.0)

**Implemented enhancements:**

- Add 3.16 tree and implement passive masteries [\#3292](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3292) ([ifnjeff](https://github.com/ifnjeff))
- Updated Multiple Uniques to 3.16.0 [\#3308](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3308) ([LordMotas](https://github.com/LordMotas)) [\#3231](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3231) ([Lexy](https://github.com/learn2draw))
- Add support for new mastery mods [\#3334](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3334) [\#3328](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3328) ([Peechey](https://github.com/Peechey)) [\#3333](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3333)  [\#3324](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3324) [\#3320](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3320) ([bit-skipper](https://github.com/bit-skipper)) [\#3331](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3331) [\#3325](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3325) ([Nostrademous](https://github.com/Nostrademous)) [\#3330](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3330) [\#3326](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3326) ([sida-wang](https://github.com/sida-wang)) [\#3327](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3327) ([monerofglory](https://github.com/monerofglory)) [\#3293](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3293) ([Lexy](https://github.com/learn2draw))
- Add new Scourge uniques  [\#3322](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3322) [\#3251](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3251) [\#3316](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3316) ([Nostrademous](https://github.com/Nostrademous))
- Add new Scourge Keystones [\#3321](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3321) ([Lexy](https://github.com/learn2draw))
- Add support for different jewel radii for different tree versions [\#3315](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3315) ([Wires77](https://github.com/Wires77))
- Add option for setting global default gem quality [\#3238](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3238) ([FWidm](https://github.com/FWidm))
- Add colour buttons for Notes tab [\#3233](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3233) ([pHiney](https://github.com/pHiney))
- Update Elusive to provide 15% chance to Avoid Damage from Hits, instead of it's old Dodge-related stats [\#3236](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3236) ([Lexy](https://github.com/learn2draw))
- Add support for legacy Snakepit [\#3249](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3249) ([Wires77](https://github.com/Wires77))
- Add Hyrri's Watch spectre [\#3312](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3312) ([Kayella](https://github.com/Kayella))
- Add support for new exposure mods [\#3319](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3319) ([PJacek](https://github.com/PJacek))
- Add support for opening related info on poewiki.net when pressing F1 on items/gems/passives [\#3291](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3291) ([BlueManiac](https://github.com/BlueManiac))
- Added support for Versatile Combatant keystone [\#3290](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3290) ([Zpooks](https://github.com/Zpooks))
- Add support for Iron Will keystone [\#3289](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3289) ([Lexy](https://github.com/learn2draw))
- Add support for spell suppression / magebane and Acrobatics [\#3288](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3288) ([Lexy](https://github.com/learn2draw))
- Add support for Four keystones and ailment duration [\#3287](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3287) ([Lilylicious](https://github.com/Lilylicious))
- Add support to disable quivers on unarmed characters [\#3286](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3286) ([madinsane](https://github.com/madinsane))
- Modified uniques items [\#3285](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3285) ([U-n-Own](https://github.com/U-n-Own))
- Scourge mod support [\#3278](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3278) , [\#3303](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3303), [\#3313](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3313) ([Wires77](https://github.com/Wires77), [Nostrademous](https://github.com/Nostrademous), [Morilli](https://github.com/Morilli))
- Updated blind with 3.16 changes [\#3277](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3277) ([Lexy](https://github.com/learn2draw))
- Add support for reservation efficiency uniques [\#3276](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3276) ([SaloEater](https://github.com/SaloEater))
- Updated armour calculations to 3.16 values [\#3275](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3275) ([madinsane](https://github.com/madinsane))
- Add option for setting global default level in options [\#3274](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3274) ([FWidm](https://github.com/FWidm))
- Add option to bypass cold snap CD [\#3270](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3270) ([Lilylicious](https://github.com/Lilylicious))
- Updated base ES recharge rate to 3.16 values [\#3269](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3269) ([borisbsv](https://github.com/borisbsv))
- Updated Skin of The Lords, Atziri's Acuity and Forbidden Shako [\#3267](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3267) ([Zuiia](https://github.com/Zuiia))
- Add new uniques with initial values for Scourge League [\#3265](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3265) ([Zuiia](https://github.com/Zuiia))
- Update uniques with scourge changes [\#3264](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3264) ([SaloEater](https://github.com/SaloEater))
- Add support for Consecrated Ground scaling [\#3261](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3261) ([Lilylicious](https://github.com/Lilylicious))
- Add minimum resistance cap [\#3260](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3260) ([ifnjeff](https://github.com/ifnjeff))
- Updated base ignite scaling to 3.16 values [\#3259](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3259) ([ifnjeff](https://github.com/ifnjeff))
- Add import of Pastebinp.com pastes [\#3258](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3258) ([MaxKruse](https://github.com/MaxKruse))
- Scourge unique changes [\#3256](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3256) ([Lexy](https://github.com/learn2draw))
- Update settings UI [\#3255](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3255) ([FWidm](https://github.com/FWidm))
- Adding support for reservation efficiency [\#3253](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3253) ([Wires77](https://github.com/Wires77))
- Update mod used by Touch of Anguish. [\#3223](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3223) ([nelchael](https://github.com/nelchael))
- Added text to the instructions on the item tab that explains how to clone items with copy paste. [\#3216](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3216) ([Tom Clancy Is Dead](https://github.com/Voronoff))
- Add support for Cruelty DoT multiplier [\#3207](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3207) ([Helyos96](https://github.com/Helyos96))
- Add support for Custom Modifiers text field in config [\#3192](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3192) ([deathbeam](https://github.com/deathbeam))
- Add support for Plague Bearer infecting/incubating and its alt quals [\#3191](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3191) ([deathbeam](https://github.com/deathbeam))
- Add support for flask enchants [\#3147](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3147) ([ifnjeff](https://github.com/ifnjeff))
- Add radius numbers for a number of skills [\#3177](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3177) ([LocalIdentity](https://github.com/LocalIdentity))

**Fixed bugs:**

- Fix bug where elemental penetration with attacks was applying to other damage types [\#3310](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3310) ([PJacek](https://github.com/PJacek))
- Fix strength's damage bonus double-dipping when using Iron Will [\#3304](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3304) ([PJacek](https://github.com/PJacek))
- Fix gem levels not being properly limited [\#3167](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3167) ([PJacek](https://github.com/PJacek))
- Fix Bane not gaining duration per curse applied [\#3160](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3160) ([PJacek](https://github.com/PJacek))  
- Fix incorrect art for Lethal Pride keystones [\#3248](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3248) ([Wires77](https://github.com/Wires77))
- Fix build files increasing in size over time [\#3229](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3229) ([Wires77](https://github.com/Wires77))
- Fix Weapon triggered skill parsing and mana cost [\#3187](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3187) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix window title not being updated after saving a build [\#3242](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3242) ([pHiney](https://github.com/pHiney))
- Fix Bitterdream to use Inspiration support instead of Reduced Mana support [\#3185](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3185) ([Typepluto](https://github.com/Typepluto))
- Change all instances of "Focussed" to "Focused" [\#3186](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3186) ([LocalIdentity](https://github.com/LocalIdentity))

## [2.8.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.8.0) (2021/08/09)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.7.0...v2.8.0)

**Implemented enhancements:**
- Add Leadership's Price unique amulet [\#3120](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3120) ([Torchery](https://github.com/Torchery))
- Group similar stats in sidebar for enhanced clarity [\#3121](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3121) ([Nightblade](https://github.com/Nightblade))

**Fixed bugs:**

- Fix Unleash crash with minion skills [\#3127](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3127) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix images for socketed Cluster Jewels [\#3116](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3116) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Slipstream tooltip [\#3117](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3117) ([Wires77](https://github.com/Wires77))




## [2.7.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.7.0) (2021/08/08)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.6.0...v2.7.0)

**Implemented Enhancements:**

- Add support for Unleash [\#2862](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2862) ([LocalIdentity](https://github.com/LocalIdentity)) ([scristall](https://github.com/scristall))
- Add Harvest and Heist enchantments to weapons and body armours [\#2914](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2914) ([ifnjeff](https://github.com/ifnjeff))
- Add new base types to rare template, update existing rare templates [\#3080](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3080) ([a3person](https://github.com/a3person))
- Add support for Banishing Blade and Pneumatic Dagger implicits [\#3113](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3113) ([LocalIdentity](https://github.com/LocalIdentity))
- Add sorting by Ward attribute [\#3076](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3076) ([TiagoGoddard](https://github.com/TiagoGoddard))
- Add support for Elusive effect [\#3061](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3061) ([Lexy](https://github.com/learn2draw))
- Add full support for Eye To Eye cluster jewel notable [\#3064](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3064) ([Nostrademous](https://github.com/Nostrademous))
- Add Cold Damage over Time mod from cluster jewels [\#3094](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3094) ([Lexy](https://github.com/learn2draw))
- Add radius to Explosive Concoction [\#3086](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3086) ([Wires77](https://github.com/Wires77))
- Add Usurper's Penance [\#3055](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3055) ([pundm](https://github.com/pundm))
- Update Ailment Threshold values [\#3049](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3049) ([LocalIdentity](https://github.com/LocalIdentity))

**Fixed bugs:**

- Fix crash when loading certain builds [\#3037](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3037) ([PJacek](https://github.com/PJacek))
- Fix error when main skill is not a minion skill but "Minion" is in FullDPS [\#3053](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3053) ([Nostrademous](https://github.com/Nostrademous))
- Fix minions getting Inspiration Charges [\#3060](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3060) ([Lexy](https://github.com/learn2draw))
- Fix Doryani's Prototype not applying to minions [\#3026](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3026) ([Wires77](https://github.com/Wires77))
- Fix parsing for new wording on Combat Focus jewels [\#3112](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3112) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Manabond not being affected by reduced mana cost nodes [\#3028](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3028) ([Wires77](https://github.com/Wires77))
- Fix Lifetap Support and Blood Magic not altering the cost of skills [\#3106](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3106) ([Wires77](https://github.com/Wires77)) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Bomb Specialist AoE mod [\#3087](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3087) ([Nostrademous](https://github.com/Nostrademous))
- Fix bug where timeless jewel keystones could be edited [\#3098](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3098) ([Wires77](https://github.com/Wires77))

## [2.6.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.6.0) (2021/07/27)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.5.0...v2.6.0)

**Implemented Enhancements:**

- Add new Expedition uniques [\#3012](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3012) ([Wires77](https://github.com/Wires77))
- Add Ward as new defensive stat [\#3012](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3012) ([Wires77](https://github.com/Wires77))
- Update Dendrobate with new gem name [\#3013](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3013) ([pundm](https://github.com/pundm))

**Fixed bugs:**

- Fix Voltaxic Burst enchantment [\#3016](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3016) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix last line of Notes tab being cut off [\#3024](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3024) ([Wires77](https://github.com/Wires77))

## [2.5.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.5.0) (2021/07/26)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.4.0...v2.5.0)

**Implemented enhancements:**

- Add full support for new 3.15 Skill Gems [\#2999](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2999) ([LocalIdentity](https://github.com/LocalIdentity)) ([ifnjeff](https://github.com/ifnjeff)) ([tcid](https://github.com/Voronoff)) 
	- Absolution
	- Behead Support
	- Boneshatter
	- Defiance Banner
	- Explosive Concoction
	- Eye of Winter
	- Forbidden Rite
	- Manabond
	- Rage Vortex
	- Shield Crush
	- Spectral Helix
	- Storm Rain
	- Summon Reaper
	- Voltaxic Burst
- Add partial support for new 3.15 Skill Gems
	- Ambush
	- Battlemage's Cry
	- Blade Trap
	- Earthbreaker Support
	- Focused Ballista Support
- Update enchantments with 3.15 changes [\#2999](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2999) ([LocalIdentity](https://github.com/LocalIdentity)) ([Nostrademous](https://github.com/Nostrademous))
- Update item mods to 3.15 stats [\#2999](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2999) ([LocalIdentity](https://github.com/LocalIdentity))
- Update minions with 3.15 changes [\#2999](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2999) ([LocalIdentity](https://github.com/LocalIdentity))
- Update Pantheons with 3.15 changes [\#2985](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2985) ([Nostrademous](https://github.com/Nostrademous))
- Add new item bases [\#2986](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2986) ([Wires77](https://github.com/Wires77))
- Add support for Timeless jewel edits to persist when updating to a new tree version [\#2957](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2957) ([Wires77](https://github.com/Wires77))
- Add documentation for colour codes to the Notes tab [\#2965](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2965) ([Wires77](https://github.com/Wires77))
- Update poison damage tooltip from 20% to 30% [\#2947](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2947) ([pundm](https://github.com/pundm))
  
**Fixed bugs:**

- Fix Mana Reservation Rounding [\#2989](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2989) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix skills turned into mines not having reservation [\#2983](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2983) ([PJacek](https://github.com/PJacek))
- Fix for downloading tree data if missing [\#2981](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2981) ([Wires77](https://github.com/Wires77))
- Fix triggered skills not showing the right mana cost [\#2955](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2955) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Hexproof to be unaffected by curses, not immune [\#2933](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2933) ([Wires77](https://github.com/Wires77))
- Fix level progress calculations [\#2932](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2932) ([ifnjeff](https://github.com/ifnjeff))
- Fix Anomalous Pride quality didn't increase "chance to bleed" [\#3008](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/3008) ([Typepluto](https://github.com/Typepluto))
- Fix Bladestorm to always bleeds in Blood Stance [\#2971](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2971) ([Wires77](https://github.com/Wires77))
- Fix Hollow Palm Technique parsing [\#2960](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2960) ([Helyos96](https://github.com/Helyos96))

## [2.4.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.4.0) (2021/07/21)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.3.0...v2.4.0)

**Implemented enhancements:**

- Add 3.15 passive skill tree [\#2910](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2910) ([ppoelzl](https://github.com/ppoelzl))
- Add level 20/21 gems from 3.15 patch notes [\#2919](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2919) ([LocalIdentity](https://github.com/LocalIdentity))
- Add 3.15 uniques [\#2911](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2911) ([Wires77](https://github.com/Wires77))
- Add 3.15 flask changes [\#2925](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2925) ([Helyos96](https://github.com/Helyos96))
- Update Evasion, Poison, and Consecrated Ground calculations to 3.15 values [\#2913](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2913) ([ifnjeff](https://github.com/ifnjeff))
- Update Alchemist's Genius to 3.15 value [\#2912](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2912) ([Wires77](https://github.com/Wires77))
- Update Gem tooltip generation [\#2796](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2796) ([PJacek](https://github.com/PJacek))
- Drastically accelerate searching for application updates (from 50s to 2s) [\#2791](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2791) ([ppoelzl](https://github.com/ppoelzl))
- Add 20 Quality gem DPS tooltip comparison [\#2800](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2800) ([7e11](https://github.com/7e11))
- Add weapon crit to mod breakdown[\#2901](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2901) ([PJacek](https://github.com/PJacek))
- Add space and newline before custom mods on Timeless Jewel nodes [\#2888](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2888) ([Nightblade](https://github.com/Nightblade))
- Add Trial Galecaller spectre [\#2751](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2751) ([Kayella](https://github.com/Kayella))
- Add support for Fishing Rods [\#2841](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2841) ([aletrop](https://github.com/aletrop))
- Add support for many Alternate Quality gems [\#2898](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2898) ([PJacek](https://github.com/PJacek))
- Add support for "Perfect Crime" and "Bomb Specialist" ascendancy nodes [\#2905](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2905) ([Nostrademous](https://github.com/Nostrademous))
- Add support for Chip Away brand cluster notable [\#2777](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2777) ([LocalIdentity](https://github.com/LocalIdentity))
- Add functionality for Blood Artist notable [\#2767](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2767) ([pundm](https://github.com/pundm)) ([Wires77](https://github.com/Wires77))
- Add skill parts for Smite [\#2918](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2918) ([Wires77](https://github.com/Wires77))
- Add support for Gore Shockwave skill [\#2775](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2775) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Divergent Close Combat [\#2788](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2788) ([Wires77](https://github.com/Wires77))
- Add support for Unnerve belt enchant [\#2922](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2922) ([Wires77](https://github.com/Wires77))
- Add support for Rathpith Globe and legacy Femur of the Saints [\#2799](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2799) ([Wires77](https://github.com/Wires77))
- Add support for Replica Siegebreaker burning ground [\#2820](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2820) ([ifnjeff](https://github.com/ifnjeff))
- Add support for Non-vaal Skill Damage during Soul Gain Prevention [\#2917](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2917) ([Wires77](https://github.com/Wires77))
- Add support for reworked Arborix mods [\#2776](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2776) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for Warcries have infinite power [\#2762](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2762) ([pundm](https://github.com/pundm))
- Add Trap and Mine speed essence mod [\#2760](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2760) ([pundm](https://github.com/pundm))
- Add parsing for Increased Chaos Damage Over Time Mod found on weapons \(\#2750\) [\#2902](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2902) ([Puddlestomper](https://github.com/Puddlestomper))
- Add support for Fiery Impact [\#2909](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2909) ([celuck](https://github.com/celuck))
- Add unique variant of Commandment of Inferno [\#2882](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2882) ([PJacek](https://github.com/PJacek))
- Add unique helmet The Fledgling [\#2873](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2873) ([ppoelzl](https://github.com/ppoelzl))
- Add missing Fire Burst radius [\#2837](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2837) ([quashtaki](https://github.com/quashtaki))
- Add missing Pride aura radius [\#2833](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2833) ([pundm](https://github.com/pundm))

**Fixed bugs:**

- Fix power report crash when loading builds [\#2785](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2785) ([Wires77](https://github.com/Wires77))
- Fix error when the power report is not initialised yet [\#2815](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2815) ([Nostrademous](https://github.com/Nostrademous))
- Fix Minion skill tooltips not working correctly [\#2778](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2778) ([Nostrademous](https://github.com/Nostrademous))
- Fix FullDPS comparison for Alternate Gem Qualities [\#2780](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2780) ([Nostrademous](https://github.com/Nostrademous))
- Fix FullDPS comparison of enabling/disabling flasks [\#2779](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2779) ([Nostrademous](https://github.com/Nostrademous))
- Fix Blood Offering appearing in gem list [\#2904](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2904) ([PJacek](https://github.com/PJacek))
- Fix multiple bugs with General's Cry Mirages [\#2770](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2770) ([Nostrademous](https://github.com/Nostrademous))
- Fix Disciple's cooldown to apply to all Sentinels [\#2916](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2916) ([Wires77](https://github.com/Wires77))
- Fix Triggered skill parsings [\#2795](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2795) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix support for Petrified Blood [\#2806](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2806) ([Wires77](https://github.com/Wires77))
- Fix Blood Stance not granting More Bleed damage [\#2789](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2789) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix maces/sceptres and thrusting/non-thrusting swords counting as different weapon types [\#2732](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2732) ([Wires77](https://github.com/Wires77))
- Fix interaction between Agnostic and Pious Path [\#2883](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2883) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix The Agnostic life recovery calculation [\#2825](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2825) ([roastpiece](https://github.com/roastpiece))
- Fix Anomalous Chain Hook [\#2889](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2889) ([PJacek](https://github.com/PJacek))
- Fix Divergent Stormbind quality has more AoE vs. Increased [\#2772](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2772) ([Wires77](https://github.com/Wires77))
- Fix Alternative Quality for Precision [\#2827](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2827) ([czarandy](https://github.com/czarandy))
- Fix Mana Reservation mods [\#2756](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2756) ([pundm](https://github.com/pundm))
- Fix "increased Impale Effect" of Dread Banner only applying to attacks [\#2878](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2878) ([Typepluto](https://github.com/Typepluto))
- Fix parsing for Sacrificial Garb implicit [\#2874](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2874) ([Wires77](https://github.com/Wires77))
- Fix Wildwrap Attack Speed mod [\#2790](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2790) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix wording on Eyes of the Greatwolf [\#2761](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2761) ([pundm](https://github.com/pundm))
- Fix wording on Ngamahu's Sign [\#2839](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2839) ([pundm](https://github.com/pundm))


## [2.3.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.3.0) (2021/04/23)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.2.1...v2.3.0)

- Add new 3.14 uniques (Nostrademous)
- Add new 3.14 bases and clean up base matching [\#2615](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2615) ([LocalIdentity](https://github.com/LocalIdentity))
- Update reservation rounding with 3.14 Changes (PJacek) [\#2644](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2644) ([PJacek](https://github.com/PJacek))
- Add parsing for many new unique mods [\#2630](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2630) ([PJacek](https://github.com/LocalIdentity))
- Add support for portrait display resolutions (Wires77) [\#2443](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2443) ([Wires77](https://github.com/Wires77))
- Add support for Blood Sacrament (from Relic of the Pact unique) (Nostrademous) [\#2583](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2583) ([Nostrademous](https://github.com/Nostrademous))
- More accurately simulate triggered attacks (Moneypouch) [\#2446](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2446) ([Nostrademous](https://github.com/Moneypouch))
- Split reservation into mana and life reservation mods (PJacek) [\#2587](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2587) ([PJacek](https://github.com/PJacek))
- Add Divine Flesh to be able to be parsed on items (Wires77) [\#2613](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2613) ([Wires77](https://github.com/Wires77))
- Change power report to only appear when selected (Wires77) [\#2443](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2443) ([Wires77](https://github.com/Wires77))

- Fix item parser to handle new copy/paste format (Wires77) [\#2603](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2603) ([Wires77](https://github.com/Wires77))
- Fix parsing and update uniques (pundm, Nostrademous) [\#2583](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2583) ([pundm](https://github.com/pundm), [Nostrademous](https://github.com/Nostrademous))
- Fix Punishment Curse not affecting DPS while an "Enemy is on Low Life" (Typepluto) [\#2638](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2638) ([Typepluto](https://github.com/Typepluto))
- Fix scaling for Vaal Righteous Fire (Wires77) [\#2645](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2645) ([Wires77](https://github.com/Wires77))
- Fix Mine Aura effect applying to DoTs from mines [\#2622](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2622) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Exsanguinate stacks applying to Poison and Ignite [\#2621](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2621) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix support for Prism Guardian (PJacek) [\#2586](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2586) ([PJacek](https://github.com/PJacek))
- Fix crash when searching in boxes with many symbols (Wires77) [\#2497](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2497) ([Wires77](https://github.com/Wires77))
- Fix crash when comparing bows with Mirage Archer for Ignite/Bleed (Nostrademous) [\#2629](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2629) ([Nostrademous](https://github.com/Nostrademous))
- Fix exporting of implicit tags (Nostrademous) [\#2608](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2608) ([Nostrademous](https://github.com/Nostrademous))
- Fix missing implicit on Disintegrator (pundm) [\#2591](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2591) ([pundm](https://github.com/pundm))

## [2.2.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.2.1) (2021/04/17)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.2.0...v2.2.1)

**Implemented enhancements:**

- Add support for Chainbreaker rage cost [\#2575](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2575) ([PJacek](https://github.com/PJacek))

**Fixed bugs:**

- Fix skill tags [\#2580](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2580) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Exsanguinate and Corrupting Fever stack damage [\#2579](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2579) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Blood Magic [\#2577](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2577) ([PJacek](https://github.com/PJacek))
- Fix crash related to fake minion skill costs [\#2574](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2574) ([PJacek](https://github.com/PJacek))

## [2.2.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.2.0) (2021/04/17)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.1.1...v2.2.0)

**Implemented enhancements:**

- Add support for new 3.14 Skill Gems [\#2557](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2557) ([Nostrademous](https://github.com/Nostrademous))
    - Corrupting Fever
    - Exsanguinate
    - Reap
    - Petrified Blood
    - Arrogance Support
    - Bloodthirst Support
    - Cruelty Support
    - Lifetap Support
- Update skills with 3.14 changes
- Update enchantments with 3.14 changes
- Update item mods to 3.14 stats
- Update minions with 3.14 changes
- Add new skills from 3.14 Uniques (Not Supported yet)
- Add support for Glimpse of Chaos [\#2547](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2547) ([PJacek](https://github.com/PJacek))
- Add support for new Skill Costs (Life / Mana / Rage) [\#2567](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2567) ([PJacek](https://github.com/PJacek))

**Fixed bugs:**

- Fix non-integer catalyst scaling issues [\#2544](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2544) ([Wires77](https://github.com/Wires77))
- Fix Victario's Influence using old mods[\#2562](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2562) ([pundm](https://github.com/pundm))
- Fix Tailwind not appearing on Passive Tree [\#2559](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2559) ([Helyos96](https://github.com/Helyos96))
- Fixes Bow DoT Skills double-dipping on nodes that grant a Dot & Hit [\#2554](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2554) ([Nostrademous](https://github.com/Nostrademous))

## [2.1.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.1.1) (2021/04/15)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.1.0...v2.1.1)

**Fixed bugs:**

- Fix Physical Aegis config option affecting the Innervate config option [\#2545](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2545) ([PJacek](https://github.com/PJacek))
- Fix Trap and Mines to use Throwing/Laying Speed for DPS calculations [\#2542](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2542) ([Nostrademous](https://github.com/Nostrademous))
- Fix Mirage Archer applying DoT stacks when they shouldn't [\#2539](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2539) ([Nostrademous](https://github.com/Nostrademous))
- Fix Minion Full DPS crash [\#2528](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2528) ([Nostrademous](https://github.com/Nostrademous))
- Fix Full DPS stat comparison for items [\#2528](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2528) ([Nostrademous](https://github.com/Nostrademous))
- Fix General's Cry to ignore speed for non-channeled skills [\#2460](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2460) ([Helyos96](https://github.com/Helyos96))

## [2.1.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.1.0) (2021/04/15)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.0.3...v2.1.0)

**Implemented enhancements:**

- Add support for the 3.14 Skill Tree [\#2513](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2513) ([LocalIdentity](https://github.com/LocalIdentity))
- Add support for count-scaling Active Skills from items [\#2496](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2496) ([Nostrademous](https://github.com/Nostrademous))
- Add support for Accelerating, Noxious, and Unstable catalysts [\#2471](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2471) ([Nostrademous](https://github.com/Nostrademous))
- Add support for Defiance [\#2504](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2504) ([Helyos96](https://github.com/Helyos96))
- Add support for leech mods rewordings [\#2510](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2510) ([Helyos96](https://github.com/Helyos96))
- Add support for Vaal Ground Slam having Exertions [\#2512](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2512) ([Nostrademous](https://github.com/Nostrademous))
- Add new Ultimatum uniques [\#2461](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2461) ([Wires77](https://github.com/Wires77))
- Implemented Tecrod's Gaze [\#2461](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2461) ([Wires77](https://github.com/Wires77))
- Update uniques from 3.14 patch notes [\#2509](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2509) ([pundm](https://github.com/pundm))
- Update Low Life/Mana threshold [\#2463](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2463) ([Nostrademous](https://github.com/Nostrademous))
- Add radius to Death Aura [\#2514](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2514) ([LocalIdentity](https://github.com/LocalIdentity))

**Fixed bugs:**

- Fix Wintertide brand not getting +1 to attached brand [\#2501](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2501) ([Wires77](https://github.com/Wires77))
- Fix DD and VD having their spell damage apply to corpse explosions [\#2498](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2498) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix some gems appearing in the gem list when they shouldn't have [\#2493](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2493) ([Wires77](https://github.com/Wires77))
- Fix physical damage reduction for bleed from going below zero [\#2481](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2481) ([Wires77](https://github.com/Wires77))
- Fix outdated modifier text on Abberath's Hooves [\#2474](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2474) ([pundm](https://github.com/pundm))
- Fix many crashes related to Generals Cry and The Saviour [\#2453](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2453) ([Nostrademous](https://github.com/Nostrademous))
- Fix Mirage Archer to be a component of the skill it supports now [\#2453](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2453) ([Nostrademous](https://github.com/Nostrademous))
- Fix crash related to Brands with Item-granted Active Skills [\#2450](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2450) ([Nostrademous](https://github.com/Nostrademous))
- Fix "Socketed Gems are supported by...v" mods for trigger skills (e.g. CwC) [\#2442](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2442) ([Nostrademous](https://github.com/Nostrademous))
- Fix incorrect application of Buff Effect [\#2391](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2391) ([PJacek](https://github.com/PJacek))

## [2.0.3](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.0.3) (2021/04/07)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.0.2...v2.0.3)

**Fixed bugs:**

- Fix ability to tab between inputs on the skills tab [\#2430](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2430) ([Wires77](https://github.com/Wires77))
- Fix stat comparison between tree specs [\#2428](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2428) ([Wires77](https://github.com/Wires77))
- Fix General's Cry and build load failures when using the same gem multiple times [\#2426](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2426) ([Nostrademous](https://github.com/Nostrademous))
- Fix reliance on a calculation mode for Mirage Archer [\#2432](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2432) ([Nostrademous](https://github.com/Nostrademous))
- Fix Saviour's Reflection Multi-part Skill behavior [\#2431](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2431) ([Nostrademous](https://github.com/Nostrademous))
- Fix export formatter missing '+' for some item implicits [\#2425](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2425) ([Wires77](https://github.com/Wires77))
- Fix crash with certain CoC triggered skills [\#2422](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2422) ([Helyos96](https://github.com/Helyos96))
- Fix impale damage not showing up in combined total damage  [\#2341](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2341) ([ALT-F-X](https://github.com/ALT-F-X))
## [2.0.2](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.0.2) (2021/04/05)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.0.1...v2.0.2)

- Fix looking at wrong location for saved user builds [abd8c12e](https://github.com/PathOfBuildingCommunity/PathOfBuilding-Launcher/commit/abd8c12ef23327c9605612cfc229c12bc5394f55) (https://github.com/dclamage)

## [2.0.1](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.0.1) (2021/04/05)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v2.0.0...v2.0.1)

**Fixed bugs:**

- Fix crash related to Arcanist Brand [\#2408](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2408) ([Wires77](https://github.com/Wires77))
- Fix crash related to triggered mana cost on skills from items without a level [\#2409](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2409) ([Wires77](https://github.com/Wires77))
- Fix crash when loading PoB from Unicode filepath [\#2413](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2413) ([Wires77](https://github.com/Wires77))

## [2.0.0](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v2.0.0) (2021/04/05)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v1.4.170.28...v2.0.0)

**Implemented enhancements:**

- Add support for many trigger-based skills and items [\#2294](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2294) ([Nostrademous](https://github.com/Nostrademous))
- Add support for General's Cry and Mirage Archer [\#2294](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2294) ([Nostrademous](https://github.com/Nostrademous))
- Add support for total DPS roll-up of multiple skills [\#2294](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2294) ([Nostrademous](https://github.com/Nostrademous))
- Add integer scaling for active skills via a "count" variable (multiple minions, mines, etc.) [\#2294](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2294) ([Nostrademous](https://github.com/Nostrademous))
- Add least effective allocated node setting to power report [\#2250](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2250) ([Wires77](https://github.com/Wires77))
- Add dynamic loading for passive skill tree versions, reducing memory allocation [\#2395](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2395) ([Nostrademous](https://github.com/Nostrademous))
- Add mana reservation breakdown [\#2392](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2392) ([Wires77](https://github.com/Wires77))
- Add ability to paste with right-click [\#2387](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2387) ([Wires77](https://github.com/Wires77))
- Add support for GGG's new API allowing us to populate Cluster Jewel nodes on character import [\#2381](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2381) ([Nostrademous](https://github.com/Nostrademous))
- Add full support for Doryani's Prototype's lightning resist mods [\#2336](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2336) ([andrewbelu](https://github.com/andrewbelu))
- Add handling for Doedre's Skin's ignore curse limit mod [\#2335](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2335) ([andrewbelu](https://github.com/andrewbelu))
- Add support for Blunderbore's shrine effect mods [\#2334](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2334) ([andrewbelu](https://github.com/andrewbelu))
- Add support for The Admiral's lowest resist mod [\#2333](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2333) ([andrewbelu](https://github.com/andrewbelu))
- Add support for Actum's crit modifier [\#2326](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2326) ([andrewbelu](https://github.com/andrewbelu))
- Add Culling DPS to sidebar if build includes a source for Culling [\#2313](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2313) ([Nostrademous](https://github.com/Nostrademous))
- Add support for The Dark Seer's Malediction debuff [\#2310](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2310) ([Helyos96](https://github.com/Helyos96))
- Add support for Precursor's Emblem [\#2304](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2304) ([Wires77](https://github.com/Wires77))
- Add new Enchantments and fix enchanting UI [\#2370](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2370) ([PJacek](https://github.com/PJacek))
- Add support for Flickershade Spectre chaos damage conversion [\#2352](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2352) ([Wires77](https://github.com/Wires77))
- Add more support for Intimidate and Unnerve [\#2332](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2332) ([andrewbelu](https://github.com/andrewbelu))
- Automatically generate Watcher's Eye mods [\#2305](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2305) ([Wires77](https://github.com/Wires77))
- Node power now accounts for total power along the path [\#2250](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2250) ([Wires77](https://github.com/Wires77))
- Inspiration charges now default to maximum [\#2340](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2340) ([Wires77](https://github.com/Wires77))
- Damage header in calcs tab now respects thousands separator preference [\#2329](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2329) ([mweber15](https://github.com/mweber15))
- Remove garbage collection calls to improve memory usage [\#2376](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2376) ([Wires77](https://github.com/Wires77))
**Fixed bugs:**

- Fix brand attachment limit for several skills [\#2386](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2386) ([Wires77](https://github.com/Wires77))
- Fix flask effect being incorrect in certain situations [\#2363](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2363) ([Wires77](https://github.com/Wires77))
- Fix: changed divergent nightblade from base crit to inc crit% [\#2358](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2358) ([pundm](https://github.com/pundm))
- Fix Fanaticism applying to attacks [\#2347](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2347) ([Wires77](https://github.com/Wires77))
- Fix wording on Poet's Pen [\#2337](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2337) ([Nostrademous](https://github.com/Nostrademous))
- Fix wording on Hyperboreus [\#2294](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2294) ([Nostrademous](https://github.com/Nostrademous))
- Fix wording on Kitava's Thirst [\#2294](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2294) ([Nostrademous](https://github.com/Nostrademous))
- Add more support for intimidate/unnerve [\#2332](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2332) ([andrewbelu](https://github.com/andrewbelu))
- Fix Voidshot Parsing [\#2331](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2331) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Divergent Ensnaring Arrow [\#2330](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2330) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Physical Damage Reduction able to go below zero [\#2325](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2325) ([andrewbelu](https://github.com/andrewbelu))
- Fix Anomalous Infused Channelling [\#2317](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2317) ([ALT-F-X](https://github.com/ALT-F-X))
- Fix: curses with two words weren't being parsed correctly [\#2375](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2375) ([Wires77](https://github.com/Wires77))

## [1.4.170.28](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v1.4.170.28) (2021/03/04)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v1.4.170.27...v1.4.170.28)

**Implemented enhancements:**

- Add support for Culling [\#2303](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2303) ([andrewbelu](https://github.com/andrewbelu))
- Add full support for Cast on Death support [\#2200](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2200) ([Nostrademous](https://github.com/Nostrademous))
- Add support for additional cooldown usages in Warcry uptime calculations [\#2296](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2296) ([andrewbelu](https://github.com/andrewbelu))
- Add support for "Enemies Taunted by your Warcries take x% increased Damage" [\#2225](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2225) ([Helyos96](https://github.com/Helyos96))
- Add character import options for Garena and Tencent realms [\#2243](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2243) ([Wires77](https://github.com/Wires77))

**Fixed bugs:**

- Fix crash when loading old build with cluster jewel notables added in a later patch [\#2299](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2299) ([Wires77](https://github.com/Wires77))
- Fix crash when the default gem level is zero [\#2298](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2298) ([Wires77](https://github.com/Wires77))
- Fix error caused by missing source of Affliction Charges  [\#2265](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2265) ([Wires77](https://github.com/Wires77))
- Fix Cast Rate for Self-Cast Skills that have Cooldown & Display DPS [\#2297](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2297) ([Nostrademous](https://github.com/Nostrademous))
- Fix DoT skills incorrectly considering Attack modifiers [\#2235](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2235) ([Nostrademous](https://github.com/Nostrademous))
- Fix Orb of Storms Activation Frequency not accounting for More multipliers to Cast Speed [\#2261](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2261) ([pundm](https://github.com/pundm))
- Fix eHP Calculation for Glancing Blows + new Block boots [\#2288](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2288) ([LocalIdentity](https://github.com/LocalIdentity))
- Fix Ballista limit with (Replica) Iron Commander equipped [\#2281](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2281) ([pundm](https://github.com/pundm))
- Fix Accuracy per Quality incorrectly being considered a local modifier [\#2242](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2242) ([Wires77](https://github.com/Wires77))
- Fix Hydrosphere damage conversion not being considered local [\#2279](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2279) ([PJacek](https://github.com/PJacek))
- Fix Anomalous Flesh and Stone applying twice with Iron Reflexes active [\#2237](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2237) ([Wires77](https://github.com/Wires77))
- Fix Alternate Quality Purifying Flame, Hypothermia, Physical to Lightning [\#2241](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2241) ([Wires77](https://github.com/Wires77))
- Fix Alternate Quality mod on Divergent Pride [\#2219](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2219) ([ALT-F-X](https://github.com/ALT-F-X))
- Fix Chain Hook not being considered an Area Skill [\#2249](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2249) ([pundm](https://github.com/pundm))
- Fix parsing of Enemy modifiers [\#2266](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2266) ([Wires77](https://github.com/Wires77))
- Fix Quality mod on Devouring Diadem [\#2256](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2256) ([Wires77](https://github.com/Wires77))
- Fix Yoke of Suffering equipment level requirements [\#2286](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2286) ([pundm](https://github.com/pundm))
- Fix typo in Doryani's Prototype [\#2231](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2231) ([Helyos96](https://github.com/Helyos96))
- Remove Crafting Bench options from items that cannot be crafted that way [\#2283](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2283) ([pundm](https://github.com/pundm))

### [1.4.170.27](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tree/v1.4.170.27) (2021/02/21)

[Full Changelog](https://github.com/PathOfBuildingCommunity/PathOfBuilding/compare/v1.4.170.26...v1.4.170.27)

**Implemented enhancements:**

- Add charge distance multiplier for Shield Charge [\#2198](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2198) ([Helyos96](https://github.com/Helyos96))
- Add group restrictions to crafted mods for crafted items [\#2174](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2174) ([Wires77](https://github.com/Wires77))
- Add skill tree comparison [\#2151](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2151) ([Ethrel](https://github.com/Ethrel))
- Add future support to load a build from commandline [\#2039](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2039) ([dclamage](https://github.com/dclamage))
- Add support for Assassin's Mistwalker elusive mod [\#2218](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2218) ([wjdeclan](https://github.com/wjdeclan))
- Add PoE matching search function [\#2210](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2210) ([Ethrel](https://github.com/Ethrel))
- Add customisation options for decimal and thousands separators [\#2207](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2207) ([Leftn](https://github.com/Leftn))
- Add support for Doedre's Skin curse pillar [\#2196](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2196) ([PJacek](https://github.com/PJacek))

**Fixed bugs:**

- Fix minimum charges not working for new belts [\#2171](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2171) ([Wires77](https://github.com/Wires77))
- Fix Inevitability to specify Rolling Magma [\#2205](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2205) ([PJacek](https://github.com/PJacek))
- Fix Cospri's Malice wording [\#2201](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2201) ([Nostrademous](https://github.com/Nostrademous))
- Fix Intimidate/Unnerve mods throwing an error [\#2199](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2199) ([Wires77](https://github.com/Wires77))
- Fix several issues with Doppelganger Guise [\#2191](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2191) ([Wires77](https://github.com/Wires77))
- Fix for Shockwave secondary trigger rate [\#2188](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2188) ([Nostrademous](https://github.com/Nostrademous))
- Fix Supreme Ego not working with non-skill Auras [\#2184](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2184) ([ALT-F-X](https://github.com/ALT-F-X))
- Fix Divergent Purity of Lightning [\#2180](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2180) ([ALT-F-X](https://github.com/ALT-F-X))
- Fix 'enemy is hexproof' Config Setting affecting marks [\#2179](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2179) ([Nostrademous](https://github.com/Nostrademous))
- Fix Attack Speed affecting Mine or Trap Supported attacks [\#2177](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2177) ([Nostrademous](https://github.com/Nostrademous))
- Fix Divergent Cobra Lash [\#2175](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2175) ([ALT-F-X](https://github.com/ALT-F-X))
- Fix Pure Talent looking at the wrong starting node for marauder [\#2169](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2169) ([Wires77](https://github.com/Wires77))
- Fix Ryslatha's Coil not applying to ailments [\#2168](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2168) ([Quote_a](https://github.com/Quotae))
- Fix Affliction Charges for Ailments [\#2158](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2158) ([Nostrademous](https://github.com/Nostrademous))
- Fix Femurs of the Saints [\#2153](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2153) ([Wires77](https://github.com/Wires77))
- Fix Phantasmal Summon Skeleton and archers for Vaal Summon Skeletons [\#2147](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2147) ([Wires77](https://github.com/Wires77))
- Fix Divergent Endurance Charge on Melee Stun not showing the right checkbox [\#2220](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2220) ([ALT-F-X](https://github.com/ALT-F-X))
- Fix quality for socketed gems applying to all gems [\#2209](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2209) ([Wires77](https://github.com/Wires77))
- Fix totem number configuration not showing with Searing Bond [\#2185](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2185) ([Wires77](https://github.com/Wires77))
- Fix crafted quality applying twice to imported gear [\#2172](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2172) ([Wires77](https://github.com/Wires77))
- Fix Pure Talent so it now plays nicely with timeless jewels [\#2170](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2170) ([Wires77](https://github.com/Wires77))
- Fix Death Aura not applying area modifiers [\#2162](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2162) ([ALT-F-X](https://github.com/ALT-F-X))
- Update wording on Rigwald's crest [\#2134](https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/2134) ([Wires77](https://github.com/Wires77))

### 1.4.170.26 - 2021/02/09
* Add control to set Vaal Timeless Jewel influenced passive skills to random mods (Wires77)
* Add all new uniques in game patch 3.13.0 (Nostrademous, ppoelzl)
* Add support for the following uniques:
  * Arn's Anguish
  * Doppelgänger
  * Graven's Secret
  * Olesya's Delight
* Add Flickershade Spectre (Kayella)
* Add support for "Cobra Lash Chains additional times" helmet enchantment (Puddlestomper)
* Add Belt Enchantments to Item Crafting from Harvest improved Offering to the Goddess Uber Lab runs. Not all modifiers parse yet, but most do (Nostrademous)
* Add Elevated Affixes to Item Crafting (Nostrademous)
* Add support for Blizzard Crown implicit (Nostrademous)
* Add support for Brutal, Affliction and Absorption Charge (damage recoup from Absorption Charges is not supported) conversion from Endurance, Frenzy, Power charges via Unique Belts (Nostrademous)
* Add support for 'On Scorched Ground' in Config Tab when using Legacy of Fury unique boots (Nostrademous)
* Add support and extraction of 'Thirst for Blood' unique ability from Jack, the Axe unique (Nostrademous, LocalIdentity)
* Add support for Doppleganger's insane/sane specification via Config Tab (Nostrademous)
* Add support for Goblinedge Power/Frenzy charge interaction (ppoelzl)
* Add limit cap to Replica Nebulis unique (Wires77)
* Add parsing support for Anomalous Minion Life (ALT-F-X)
* Updated Max Awakening Level for Sirus to scale to 9 achievable through Atlas Passives (Quote_a)
* Add support for Phantasmal Ancestral Protector (ALT-F-X)
* Add support for impale from spells (Wires77)
* Add support for Phantasmal Might from The Black Cane (Wires77)
* Add support for Shield Shatter on Shattershard (Wires77)
* Add support for automatic chill from Summon Skitterbots (Quote_a)
  
* Fix Timeless Jewel passives not accounting for past skill tree versions (Wires77)
* Fix Spectre stats scaling with Spectre level using incorrect values (zao)
* Fix mod ranges on Legacy of Fury (Nostrademous)
* Fix Endurance/Frenzy/Power charges missing for Minions (Wires77)
* Fix multiple crashes in the skills tab related to gem quality (Nostrademous, ALT-F-X)
* Corrected enforcement of Minion Skill level requirements (zao)
* Fix Enduring Cry's Life Regen calculation (tommysays)
* Fix Ancestral Cry's Armor increase calculation (tommysays)
* Fix Divergent Minion Damage to be an "Increase" instead of "More" as it should have been (Wires77)
* Fix accounting for Abyssal Jewels in Offhand Slots (zao)
* Updated Replica Alberon's Warpath chaos damage gain per strength to new value (RUSshy)
* Fix Flame Wall's secondary not being affected by Area Damage (Wires77)
* Fix Impale Support and Divergent Fortify application of Physical Damage Reduction (Wires77)
* Fix '+1 to Maximum Summon Ballista Totems' to not also increase the allowed count of Ancestral Totems (Wires77)
* Fix Disintegrator to include Block Attack Damage on Ritual variant (Wires77)
* Fix Offering to the Serpent unique gloves stat attributes (PJacek)
* Fix Cameria's Avarice unique mace to state "on Hit" rather than "on Kill" (ALT-F-X)
* Fix Phantasmal Smite quality bonus (ALT-F-X)
* Updated many Configuration Tab tooltips to display updated values (zao)
### 1.4.170.25 - 2021/01/16
* Fix Trinity Support
* Fix Hrimnor's Resolve
### 1.4.170.24 - 2021/01/16
* Fix Rupture calculations
### 1.4.170.23 - 2021/01/16
* Add support for Trinity Support and Hydrosphere
* Update gems with 3.13 changes
* Add new 3.13 base types
* Add support for "Projectiles deal #% increased Damage for each Enemy Pierced"
* Add Block Chance and Spell Block Chance to the passive skill tree heatmap
* Fix multiple application crashes related to skill gem selection
* Fix Fanaticism and Convergence persisting after deallocating nodes
* Fix parsing error with Pure Talent
* Fix item versions of Disintegrator
* Fix item versions of Doryani's Fist
### 1.4.170.22 - 2021/01/14
* Add support for Hierophant's reworked Conviction of Power Notable
* Add support for Hand of the Fervent's unique mechanic
* Add support for "Physical Damage taken from Hits"
* Update Disintegrator and Martyr of Innocence
* Fix Shaper of Flames/Winter/Storms more effect not being accounted for in left-hand side calculation
* Fix parsing of Deadeye's Rupture Notable
* Fix parsing of Inquisitor's Instruments of Virtue and Righteous Providence Notables
* Fix effective hit points calculations when you take 100% of damage as a different type of damage
* Fix errors occurring when hovering over gem tooltips
* Fix damage taken on block calcs breakdown
* Fix mod on Follow-Through Medium Cluster Jewel
* Fix usage limit on Hazardous Research
* Fix build files growing exponentially if there is a colon at the start of an item's name
### 1.4.170.21 - 2021/01/13
* Add 3.13 passive skill tree
* Changes to Ascendancies:
  * Add support for Deadeye's Gale Force mechanic
  * Add support for Deadeye's Rupture mechanic
  * Add support for Elementalist's Heart of Destruction Notable
  * Add support for Elementalist's Mastermind of Discord Notable
  * Add support for Elementalist's Shaper Notables
  * Add support for Inquisitor's reworked Notables
* Add support for Battlemage mechanic
* Add support for Blackflame's unique mechanics
* Add support for all basic aegises
* Add various improvements to the accuracy of maximum hit and EHP calcs
* Add option to show all Alternate Quality skill gems in the skill gem selection dropdown
* Add stat comparisons to Alternate Quality skill gems on hover
* Add support for various new mods
* Add all known new uniques
* Update Far Shot to new scale
* Fix Elemental Equilibrium applying twice if you have Malachai's Artifice equipped
* Fix stat differences between Cluster Jewel Notables not showing up
* Fix Large Cluster Jewels not importing correctly in some cases
* Fix Alternate Quality skill gems staying at their default Quality on copy/paste
* Fix Anomalous Flesh and Stone Alternate Quality effect
* Fix base type mods that were inadvertently removed
* Fix craftable flask mods having disappeared
* Fix crafting tags showing up on multiline mods
* Fix skill gem tooltip not showing when hovering over the skill gem selection dropdown
* Fix error where skill gem controls were selectable before a skill gem was set
* Fix Dark Pact radius
* Fix mod on Unending Hunger
### 1.4.170.20 - 2020/12/19
* Fix program not launching on Linux
### 1.4.170.19 - 2020/12/19
* Guard skills rework:
    * You can only have one Guard skill active at a time now
    * Vaal Molten Shell automatically disables all other Guard skills
    * Guard skills scale with Buff Effect
    * EHP calculations take Guard skills into account
* Multi-stage skills rework:
    * Add skill stages box to the sidebar and calcs tab
    * Remove existing skill stages config options and pre-defined stages
    * Enable Penance Brand to automatically use the "Activations per Brand" number
    * Fix Winter Orb damage calculations
* Add support for skills granted by passive tree nodes
* Add separate Rune Dagger, Warstaff and Convoking Wand base types
* Add full support for Weapon and Armour Quality modifiers
* Add tooltips to skill gem selection drop-down
* Add support for Immortal Ambition
* Add support for Supreme Decadence
* Add support for Scorch mod on Rolling Flames
* Add quality mods to Zealotry and Anger
* Add enchantment mod for Sigil of Power
* Add new Keystones to Skin of The Lords
* Add support for non-vaal skill related modifiers
* Fix interaction of Guard skills with MoM, Low Life, and other mechanics
* Fix item bases on Beacon of Madness
* Fix Cold damage applying Freeze twice
* Fix Arcanist Brand using the main skill's Brand limit
* Fix Dominating Blow quality not applying to Minions
* Fix Storm Burst not applying an additional tick
* Fix non-Curse Aura Effect applying to Curse Auras
* Fix disabling alternative Ailments when using Elemental Focus
* Fix attribute requirements for some skill gems
* Fix anointed Notables not showing as allocated on the skill tree
* Fix skill gem quality not rounding towards zero in case of negative stats
* Fix "nil" being displayed in DoT breakdowns
* Fix parsing of decimal values on items
* Fix item variants on Watcher's Eye
* Fix item variants on The Peregrine
* Fix item text sanitisation
* Fix an issue with item base names containing whitespace
### 1.4.170.18 - 2020/11/22
 * Fix error on updating with the 1.4.170.17 patch
### 1.4.170.17 - 2020/11/22
 * Remove support for loading builds from before game version 3.0.0
### 1.4.170.16 - 2020/10/18
 * Fix error on updating with the 1.4.170.15 patch
### 1.4.170.15 - 2020/10/18
 * Add performance improvements where PoB will no longer use excess CPU when in the background
 * Add distance and Cluster Notable sorting to the Power Report
 * Add eHP sorting to the tree and uniques tab
 * Add note showing which elemental resistance Hexblast is using for its Chaos damage
 * Add support for Storm Burst damage scaling with orb duration
 * Add support for Infernal Blow Debuff DPS
 * Add support for Death Wish on the Maw of Mischief unique
 * Add support for Combat Rhythm Cluster Notable
 * Add support for Divergent Rallying Cry
 * Add support for Might and Influence jewel
 * Add support for Replica Malachai's Artifice
 * Add support for Replica Wings of Entropy
 * Add support for alternate quality Purity of Elements
 * Add Contaminate skill from Sporeguard
 * Add support for Ailment Mode to calculate non-damaging ailments
 * Add support for SOCKS5 Host Name Mode Proxy
 * Update uniques with 3.12 changes
 * Update Crackling Lance enchantment
 * Fix alt quality gems not saving properly
 * Fix crash when you socket a Thread of Hope into a Cluster Jewel socket
 * Fix support for mod translation with Spiritual Aid and Spiritual Command notables
 * Fix Flame Wall added damage not working with Minions
 * Fix Mjolner and Cospri's Malice supports not applying correctly
 * Fix Doom calculations for builds with multiple curses
 * Fix Perforate more AoE in Sand Stance
 * Fix wording on Agnerod staves
 * Fix Divergent Blind Support Crit Chance calculation
 * Fix Curse mods on the tree not applying correctly
 * Fix Phantasmal Static Strike
 * Fix Vulnerability not displaying chance to bleed in breakdowns
 * Fix Bladestorm "Are you in a Bloodstorm?" buff applying as a global buff
 * Fix some mods on the tree not working with ailments
 * Fix Hexblast interaction with increased/reduced resistance modifiers
 * Fix Shockwave Support having DPS numbers when it should only show average hit
 * Fix catalyst tags on Emberwake
 * Fix Mystic Bulwark notable
 * Fix display of Poison DPS for average hit skills
 * Fix support for Phantasmal Earthquake
 * Fix Vaal Impurities
 * Fix Rage generation on Warlords Mark
 * Fix skill radius for Ball Lightning
 * Fix Siphoning charge limit for items with dual influence
 * Fix Curses not applying from Minions
 * Fix some comparison tooltip errors
 * Fix bug with Catalysts and Malachai's Artifice
 * Fix parsing of Voidforge
 * Fix error where accuracy could appear to be below 0
 * Fix support for Vaal Impurity resistances
 * Fixes Minion display stats for when they have DoT Components
 * Fix Fungal ground not applying to Minions
 * Fix alternate qualities on some gems not displaying correctly
### 1.4.170.14 - 2020/10/01
 * Add distance and Cluster Notable sorting to the Power Report
 * Add support for Death Wish on the Maw of Mischief unique
 * Add Combat Rhythm Cluster Notable
 * Fix Doom calculations for multiple curse builds
 * Fix Perforate more AoE in Sand Stance
 * Fix wording on Agnerod's staves
 * Fix Divergent Blind Crit Chance calculation
### 1.4.170.13 - 2020/09/30
 * Add Flame Wall Projectile added damage buff
 * Add Ashblessed Warden Spectre
 * Add parsing for new Golem mods lines on Uniques
 * Add support for Zealotry alternate quality
 * Add support for Lingering Blades with Animate Weapon
 * Add support for new Curse/Mark on Hit mods
 * Fix crash related to Divergent Maim
 * Fix crash related to Phantasmal Raise Zombie
 * Fix Hexblast not taking into account elemental penetration
 * Fix implementation of the Iron Mass unique
 * Fix second mod on Growing Agony not appearing
 * Fix Power Report being cut off from the UI at certain resolutions
 * Fix Fortify Support alternate quality
 * Fix Projectile count calculations
 * Fix Mana Cost calculations
 * Fix Timeless Jewel saving
 * Fix Lucky Damage applying to all elements
 * Fix Animate Weapon more Attack Speed from gem
 * Fix mods on Cloud Retch Spectre
 * Fix parsing for some tooltips
 * Fix Cremation Hit Time override
 * Fix Catalysts not working in the item crafter
### 1.4.170.12 - 2020/09/28
 * Add support for Timeless jewels and their mods
	* Timeless jewels will now convert Keystones on the tree
	* You can change the mods on nodes by right-clicking and selecting which stat you want
 * Add full support for exposure on gear and the tree
 * Add Power Report on the tree tab to show a table of the best nodes for your build
 * Add full support for 3.12 gems
	* Hexblast
	* Blazing Salvo
	* Void Sphere
	* Crackling Lance
	* Frost Shield
	* Splitting Steel
	* Sigil of Power
	* Flame Wall
	* Impending Doom Support
	* Pinpoint Support
 * Rework gems from 3.12 Changes
	* Firestorm
	* Assassin's Mark
	* Poacher's Mark
	* Sniper's Mark
	* Warlord's Mark
	* Lancing Steel
	* Shattering Steel
	* Glacial Cascade
	* Discharge
	* Punishment
	* Vitality
 * Add support for the majority of the alternate quality gems
 * Add config option for phys gained as random element mods
 * Add Syndicate Operative Spectre
 * Add Primal Crushclaw Spectre
 * Add Frost Auto Scout Spectre
 * Add Artless Assassin Spectre
 * Add Cloud Retch Spectre
 * Add enchantments for new 3.12 skills
 * Add oil recipes for new 3.12 tree nodes
 * Add in all 3.12 uniques
 * Add support for a majority of new uniques
 * Add better support to show the combined DoT damage for some builds
 * Add support for Triple Damage
 * Fix curse effect breakdown not working for Mark and Hex skills
 * Fix Supreme Ego incorrectly scaling some skills
 * Fix display of alternate quality gems
 * Fix import of alternate quality gems
 * Fix error where viewport would not scroll horizontally
 * Fix showing node power for top node if the skill doesn't do damage
 * Fix Intensity being capped at a maximum of 3
 * Fix Pinpoint Support incorrectly scaling ailment damage
 * Fix Predator Support not showing up on the configs page
 * Fix Glancing Blows not using the correct block effect value for eHP calculations
 * Fix tooltips for several skills (Warcries, Penance Brand etc.)
### 1.4.170.11 - 2020/09/19
 * Fix issue where many skills tags were incorrect which caused supports and other mechanics to stop working
### 1.4.170.10 - 2020/09/19
 * Add partial support for new 3.12 gems and enchantments
 * Update gems with 3.12 changes
 * Add new 3.12 bases
 * Add partial support for alternate quality gems
### 1.4.170.9 - 2020/09/17
 * Add better breakdown for duration mods on gems
 * Fix crash related to new Keystones and old trees
 * Fix support for Iron Grip Notable
 * Fix support for new ailment scaling nodes
 * Fix support for new cooldown recovery wording on nodes
### 1.4.170.8 - 2020/09/16
 * Add support for 3.12 Tree
 * Add proper support for Carrion Golem
 * Add support for Ancient Waystone unique
 * Add support for +1 gems on Awakened Blasphemy
 * Add configurable charges for Minions
 * Add support to generate mods for Skin of the Lords
 * Add Redemption Knight spectre
 * Add Baranite Preacher spectre
 * Add Templar Tactician spectre
 * Add Scinteel Synthete spectre
 * Add support for Non-Channelling Mana cost
 * Fix crash when trying to add support gems to any spell while having "Gain no inherent bonuses from Attributes"
 * Fix crash related to Minion Critical Strike Chance
 * Fix mods on several uniques
 * Fix current Shock note not showing in Shock effect breakdown for attack builds
 * Fix Second Wind CDR numbers
 * Fix stats on Enhanced Vaal Fallen, Baranite Thaumaturge, Baranite Sister
 * Fix Life regen not showing in the sidebar
 * Fix top node power calculations
### 1.4.170.7 - 2020/07/22
 * Fix crash related to the Siegebreaker belt
 * Fix crash related to Dancing Dervish/Duo
 * Fix Seismic Cry having incorrect calculations
 * Fix Fist of War not using the proper Ailment multiplier
 * Fix Chaos DoT Multiplier not showing up in Poison DoT Multi breakdown
### 1.4.170.6 - 2020/07/22
 * Add breakdown for Warcries and Fist of War
 * Add calculation mode to select "Max hit" for Warcries
 * Add count for the max number of Brand activations
 * Add support for Slipstream from Harbinger of Time
 * Add support for Burning Arrows Fire DoT Debuff
 * Add support for alternate quality mod implicits
 * Add support for Fevered Mind, Fortress Covenant and Quickening Covenant
 * Add support for Emperors Vigilance
 * Add support for Siegebreaker
 * Add support for Brewed for Potency, Chilling Presence, Forbidden Words, Lead by Example, Pure Agony
     and Disciples Cluster Notables
 * Add output for DoT multiplier for Ailments
 * Add Attack/Cast speed to the Node/Item Power sorting list
 * Add override to simulate lucky hits on a character ("Your damage with Hits is Lucky")
 * Change Ignite Calc Mode to Ailment Calc Mode
 * Update mods on Impresence
 * Fix Pressure Points Notable not working
 * Fix Pride not working when importing an old build
 * Fix imported influence items not working with the item crafter
 * Fix Anoint-only nodes appearing in the "Top Node" power list
 * Fix Wither not showing up for Eternal Suffering Cluster Notables
 * Fix Eye of Malice not affecting Ignite damage
 * Fix Minions being supported by Cast while Channelling or Arcanist Brand
 * Fix the effects of Consecrated and Profane Ground to now work with Minions
 * Fix damage scaling on Explosive Arrow
 * Fix Evasion calculations
### 1.4.170.5 - 2020/07/15
 * Fix crash related to Vessel of Vinktar and flask effect
 * Fix Rallying Cry not showing the proper configuration option to select number of nearby Allies
 * Fix Saqawals Nest not scaling Aspect of the Avian properly on Allies
 * Fix Ascendancy nodes showing up on the nearby strong nodes in the heatmap
 * Fix crash related to opening old builds with a different tree version
### 1.4.170.4 - 2020/07/15
 * Fix bug where importing builds would change the boss configuration to be empty
### 1.4.170.3 - 2020/07/15
 * Add support for 3.11 Warcries and Exerted Attacks
  * Warcry-related Exerted Attack Effect is calculated based on:
    Average Damage of Exerted Attacks * Exerted Buff Scaling * Expected Uptime of Exerted Attacks.
    Expected Uptime is based on number of Exerted Attacks contrasted with Attack Speed and impacted
    by Warcry Cooldown Speed and Cast Time
  * Full support:
    * Ancestral Cry
    * Enduring Cry
    * Infernal Cry
    * Intimidating Cry
    * Rallying Cry
    * Seismic Cry
  * Not yet implemented:
    * General's Cry
 * Add full support for Arcanist Brand
 * Add proper support for Cast while Channelling
 * Add new Harvest uniques
 * Add upgraded Harbinger uniques
 * Add support to show Notable power calculation in a tooltip when crafting Cluster jewels
 * Add AoE numbers for 56 skills
 * Add full support for Bonechill (automatically applies for guaranteed sources of Chill)
 * Add support to automatically Shock enemies with guaranteed sources of Shock
 * Add in-depth breakdowns of Shock and Chill thresholds
 * Add Scale of Esh Spectre
 * Add full support for Agnostic, Eternal Youth and Imbalanced Guard Keystones
 * Add partial support for Supreme Ego Keystone
 * Add support for increased Effect of Arcane Surge
 * Add support for Awakened Curse on Hit +1 Curse mod
 * Add support for Rattling Bellow, Warning Call, Cry Wolf and Pressure Points Cluster Notables
 * Add support for Warcry Power calculation with Configuration based override support
 * Add support for reworked Berserker War Bringer Ascendancy node
 * Add support for "each time you've Warcried Recently"
 * Add support for "If you've changed Stance Recently"
 * Add support for added Physical Damage from Spectral Wolves
 * Add support for Herald of Ash Overkill DoT
 * Add support for Vaal Molten Shell/Molten Shell reflect damage
 * Add support for Rigwald's Command Rage DoT multiplier mod
 * Add support for faster Damaging Ailments mod on Malevolence Watcher's Eye
 * Add support for Emberwake's +1 Ignite mod
 * Add support for Wintertide Brand gem quality
 * Add support for Charged Mines Support gem quality
 * Add support for Blind on the player
 * Add support to hide items in the unique list by stat and level requirements
 * Add support to highlight nodes by per-point and best node
 * Add the ability to change the eHP calculation mode between spell, attack and more
 * Add a breakdown on Evasion for Melee and Projectile Attacks
 * Move Pride's effect drop-down to the "Configuration" page
 * Show boss ailment threshold in Chill and Shock breakdown (Sirus, Shaper, Uber Atziri)
 * Change jewel tooltips to now scroll horizontally across the screen when having many jewel sockets
 * Update Pantheon mods to the changes from 3.11
 * Update Cluster jewels to include new jewel socket enchantments
 * Fix Orb of Storms to use a Hit Rate value instead of Cast Speed
 * Fix Rage not working correctly in some cases
 * Fix Wither not applying properly in many cases
 * Fix Unnerve applying to DoT Spell skills
 * Fix Unbound Ailments Support not working with new Ailments
 * Fix parsing for mods that modified the duration of Aspect of the Cat/Avian
 * Fix support for Bannerman and Revelry
 * Fix Vaal Molten Shell more Armour Buff
 * Fix Baranite Thaumaturge default skill by removing "attack" tag
 * Fix Cluster nodes on the tree with broken tooltips
 * Fix bug where Shock was applying twice on Minion skills
 * Fix bug where skills that reserved Mana would benefit from negative Life/Mana Reservation
 * Fix bug where removable crafts remained after editing an item
 * Fix crash on deleting the number for default gem level/quality on the skills tab
### 1.4.170.2 - 2020/06/23
 * Add Baranite Sister Spectre
 * Add 20 fuse cap to Explosive Arrow
 * Fix Corpse Pact node attack speed cap
 * Fix some Cluster jewel notables not appearing on the tree
 * Fix unique staves using the Judgement Staff base
### 1.4.170.1 - 2020/06/22
 * Add all new gems from 3.11
   * Full support:
     * Earthshatter
     * Arcanist Brand
     * Penance Brand
     * Wintertide Brand
     * Fist of War Support
     * Urgent Orders Support
     * Swiftbrand Support
   * Partial support:
     * Ancestral Cry
     * Generals Cry
     * Intimidating Cry
     * Seismic Cry
 * Update gems with 3.11 changes
 * Update uniques with 3.11 changes
 * Add basic support for Warcry power
 * Add large breakdown for character defences
   * Shows detailed breakdowns for defences
   * Includes effective hit points against hits and DoTs for each element
   * And much more
 * Add UI for anointing amulets
 * Add dropdown to select dps field for sorting support gems
 * Add prefix/suffix tag for crafting options
 * Add support for Scorch, Brittle, and Sap
 * Add parsing for Tailwind mod on Hunter influenced boots
 * Add support for Supreme Ostentation Keystone
 * Add support for Glancing Blows Keystone
 * Add support for new Rage nodes and Chainbreaker's two regen related mods 
 * Add support for "as though dealing more damage" for Shock, Chill, and Freeze
 * Add support for Overshock and Voltaxic Rift max shock mod
 * Add support for stance nodes on the tree
 * Add support for two-handed Impale nodes on the tree
 * Add support for Attack Critical Strike multiplier while Dual Wielding
 * Add Mortal Conviction to Skin of the Lords
 * Add 75% cap for buff expiration speed
 * Add support for Daresso's Courage block mod
 * Add support for Liege of the Primordial golem elemental immunity
 * Add support for Arcane Blessing ailment immunity
 * Add total for "reduced Extra Damage from Critical Strikes" on the calcs page
 * Add support for cooldowns rounding to the nearest server tick
 * Add hard caps to attack, cast, trap throwing and mine throwing speeds
 * Add better support for Soul Tether unique belt
 * Update Area of Effect calculations showing breakpoints for skills
 * Clamp skill gem options to make comparing gems more consistent
 * Fix incorrect enemy armour calculations
 * Fix importing bug with 2-line implicit Cluster jewels
 * Fix crash related to Cluster jewel Keystones on the calcs page
 * Fix bug where the node power calculator would sometimes break when using Impale
 * Fix Consecrated Path not applying more damage to close targets
 * Fix Herald dependent mods applying while unbuffed
 * Fix parsing for bleed infliction/immunity mods
 * Fix several typos on uniques
 * Fix Talisman tier parsing
 * Fix Hybrid flasks not counting as Life/Mana flasks
 * Fix for Berserk quality attack damage not applying properly
 * Fix for Dying Sun not changing "increased" to "reduced" properly
 * Fix faster bleeding mods not being displayed
 * Fix 20 quality Awakened Generosity not increasing supported auras level
 * Fix Snipe stages applying incorrectly to the Snipe skill
 * Fix Stormbind damage per improvement
 * Fix Elusive calculations not applying properly
 * Fix node search not updating when switching Cluster jewels
 * Fix tooltip for Feeding Frenzy
 * Fix bug for brand nodes on the tree
 * Fix support for corpse pact
 * Fix poison node on the tree for spell skills applying to cold DoTs
 * Fix parsing for the new Purposeful Harbinger mod
 * Fix calculation of crab barriers
 * Remove 20% more physical damage while dual wielding
### 1.4.169.3 - 2020/06/17
 * Add 3.11 passive skill tree
 * Add support for Indigo oils
 * Add support for reworded brand mods
 * Add support for Overwhelm
### 1.4.169.2 - 2020/04/20
 * Change the 'Damage Avoidance' subsection to be collapsed by default
 * Fix parsing on Assailum helmet
### 1.4.169.1 - 2020/04/20
 * Add support for Catalysts on items crafted in PoB or Uniques in the item list
 * Add support for enemy armour and physical damage reduction calculations for hits and Impales
	* Added Sirus to boss list as he has a 100% more armour multiplier
 * Add support for dual influence item crafting
 * Add support for Snipe on the Assailum unique helmet
 * Add support for Split Personality unique jewel
 * Add 2 new Spectre types
    * Redemption Sentry
    * Baranite Thaumaturge
 * Add "Are you Channelling?" checkbox to support new cluster notables
 * Add support for Violent Retaliation, Vicious Skewering and Rapid Infusion
 * Add support for Life/ES/Mana Gain on Block
 * Add support for more damage avoidance calculations
 * Add option to select number of overlapping pods for Toxic Rain
 * Add support for breakdown of DoT more multipliers and aura effect
 * Add build name in title bar of PoB window and config to turn this off
 * Add attributes to the Node/Item Power sorting list
 * Add support for mods based on "UsingLifeFlask" and "UsingManaFlask"
 * Improve support for ignite duration breakdown
 * Update XP to take into account higher possible mob levels
 * Update mine throwing time from 0.25s to 0.3s
 * Fix Hungry Loop crash when socketed with Barrage Support
 * Fix crash when hovering over the stat breakdown for stats that came from Cluster jewel Keystones
 * Fix crash related to ticking the Lightning Golem aura
 * Fix crash when sorting the unique item list
 * Fix crash caused by Elusive stack overflow
 * Fix item and gem importer to work properly with Barrage Support and some Cluster jewels
 * Fix Fractal Thoughts mods not applying correctly
 * Fix Mask of the Tribunal mana reservation mod not working
 * Fix Vaal Timeless jewel to disable stats on nodes in its radius
 * Fix wording on Blue and Green Nightmare jewels
 * Fix Doomfletch and Doomfletch Prism
 * Fix bug where crafted and custom modifiers disappeared from custom items when prefix or suffixes were changed
 * Fix Master of Metal not applying correctly and being limited to 9 stacks
 * Fix Impale stacks not being adjustable
 * Fix tooltip issue when hovering over some Cluster jewel notables
 * Fix mod on Fortress Covenant
 * Fix Perquil's Toe not working properly
 * Fix support for Juggernaut's "cannot be slowed below base speed" mod
 * Fix rendering of Medium Cluster jewels with 3 notables
 * Fix Thread of Hope not importing correctly
 * Fix Replenishing Presence not stacking correctly
 * Fix Purposeful Harbinger incorrectly scaling some skills
### 1.4.167.2 - 2020/03/24
 * Fix crash related to Oni-Goroshi
 * Fix crash related to number of brands attached to enemy
 * Fix parsing for One With Nothing Cluster Jewel
 * Fix increased effect of small passive skills applying to notables
### 1.4.167.1 - 2020/03/23
 * Update uniques with changes from 3.10
 * Add support for Arcane Cloak, Spellslinger, and Archmage Support
 * Add the unique cluster jewels
 * Add support for more Notables (life as extra armour, heralds, life regen)
 * Add support for calculations from forking projectiles
 * Add parsing for minion abyss jewel mods
 * Add radius for Stormbind
 * Small passives in Large and Medium Cluster Jewel wheels now have the correct node artwork
 * Fix Minion Instability
 * Fix crash when socketing a threshold jewel into a Cluster Jewel socket
 * Fix crash occurring when opening old builds that used the checkbox for "Are you Stationary"
 * Fix parsing for guard skill cooldown on tree
 * Fix the Darkscorn and weapon mod for more damage with ailments, which was also applying to attacks
 * Fix Hierophant's Sign of Purpose mod only applying "enemies take increased damage" to brand skills
 * Fix small Cluster Jewels allowing 2 notables
 * Fix ordering of notables in Cluster Jewel wheels
 * Fix node location popups not correctly centring on the node in 3.10 passive trees
 * Fix nodes allocated through Intuitive Leap and Thread of Hope not remaining allocated after loading the build
 * Disabled attribute Cluster Jewel types
### 1.4.162.2 - 2020/03/15
 * Fix opening build crash
### 1.4.162.1 - 2020/03/15
 * Add support for Cluster Jewels on the tree
 * Add support for many of the new Notables from Cluster Jewels
 * Add new 3.10 skill gems and skill gem balance tweaks
	* Full support for Kinetic Bolt, Stormbind Bladeblast and Second Wind
	* Arcane Cloak, Spellslinger and Archmage Support are not supported properly for DPS calculations
 * Add new 3.10 uniques
 * Add back oils to tree, now with a picture of the oil on the notable
 * Add Paradoxica to unique selection menu
 * Add support for "if you have Stunned an Enemy Recently"
 * Add support for active brand limit and Sign of Purpose
 * Add conditional more multiplier of Groundslam for nearby enemies
 * Add support for mana spent recently mods
 * Add support for Unencumbered from the Hollow Palm Keystone
 * Add Perforate DPS calculations in Blood Stance
 * Update elusive values to 3.10
 * Update temple jewels to their 3.10 variants
 * Fix Rigwald's Curse with 3.10 passive tree nodes
 * Fix typo in Ascendant Deadeye/Longshot notable
 * Fix parsing of mods applied to spell skills
 * Fix Slayer Impact node calculation
 * Fix parsing of warcry cooldown override on Al Dhih
 * Fix Ballista placement speed
 * Consolidate resistances into single line in sidebar
### 1.4.159.1 - 2020/03/12
 * Fixed weapon ailment modifiers not correctly applying
 * Fixed some Two Handed Weapon modifiers incorrectly applying to One Handed Weapons instead
### 1.4.158.1 - 2020/03/12
 * Add 3.10 passive skill tree
### 1.4.157.7 - 2020/02/29
 * Fix crash related to hovering over Bone Armour in the skills tab
### 1.4.157.6 - 2020/02/26
 * Revert fix for Rage as it breaks other skills
### 1.4.157.5 - 2020/02/25
 * Add full search capability to all dropdown lists
 * Items copied into PoB now retain their quality if above 20%
 * Add support for Infernal Legion with Skitterbots
 * Add support for shotgunning with Shattering Steel
 * Add support for the timed buff granted by Chieftain's "Ngamahu, Flame's Advance" notable
 * Add support for a mod on Chieftain's "Valako, Storm's Embrace" notable
 * Add support for a mod on Chieftain's "Tasalio, Cleansing Water" notable
 * Add support for a mod on Berserker's "War Bringer" notable
 * Add support for a mod on Assassin's "Opportunistic" notable
 * Add support for "per minion" modifiers on Necromancer's Bone Barrier notable
 * Add Energy Shield to the sidebar for minion skills
 * Add support for "Enemies Frozen by you take X% increased Damage" mod on Taryn's Shiver
 * Add support for "if you've stopped taking Damage Over Time Recently" pantheon mod
 * Add support for Fire DoT Multiplier on Awakened Burning Damage, Burning Arrow and Vaal Burning Arrow
 * Add support for Shockwave Support's quality stats
 * Add Pride to list of auras on Aul's Uprising
 * Change resistance colours in the sidebar
 * Update text on some uniques
 * Fix Sporeguard Fungal Ground mod parsing
 * Fix a bug where the source name of skills for ailments could be incorrect
 * Fix chill calculations when using Elemental Focus
 * Fix Rage Support and other sources of Rage not granting Movement Speed
 * Fix "Socketed Skill Gems get a X% Mana Multiplier" modifier not working on skills which reserve mana
 * Fix chance to deal Double Damage on Paradoxica and Frostbreath
 * Fix default gem level for gems with a max level below 20
 * Fix Close Combat weapon checks
 * Fix Sanctuary node not being able to be anointed
 * Fix Nightblade weapon checks
 * Fix Elusive mod persisting if the checkbox was ticked and the source to generate Elusive was taken away
 * Fix incorrect calculations of Active Totem Limit
 * Fix many configuration options that didn't work for minion granted effects
    * Blade count for spectres' Blade Vortex
    * Spectres' curses
    * Ursa's Rallying Cry
    * Holy Relic's Aura
    * Lightning Golem's Aura
 * Fix Ensnaring Arrow's damage debuff incorrectly stacking 3 times
 * Fix incorrect calculation of auras and curses granted by minions
### 1.4.157.4 - 2020/02/11
 * Add support for increased Effect of Arcane Surge
 * Add support for Brand Attachment range
 * Add support for Awakened Spell Echo's chance to deal Double Damage on final repeat
 * Fix support for Crimson Dance
 * Update wording on Staves
 * Corrected many uniques that wrongly got legacy variants and updated wordings
### 1.4.157.3 - 2020/02/10
 * Fix scrolling on dropdown boxes
 * Fix CombinedDPS showing up on all skills
### 1.4.157.2 - 2020/02/10
 * Add support for the Barrage Support skill gem
 * Add support for Ensnaring Arrow
 * Add support for Thread of Hope
 * Add support for Crimson Dance and amount of bleeds on enemy
 * Partial support for Timeless jewels
    * Brutal Restraint (Maraketh) and Lethal Pride (Karui) now provide stats when allocating small nodes on the tree
    * Elegant Hubris (Eternal) now negates all stats gained from nodes in its radius other than keystones
 * Add support for Void Shot granted by the Voidfletcher unique quiver
 * Add support for in-game jewel radius sprites
 * Add parsing for -res and increased phys damage delve helmet mods
 * Add support for "against Chilled or Frozen Enemies" mod
 * Add breakdown for Curse Effect for Curse Skills
 * Add breakdown for Aura Effect for Aura Skills
 * Add breakdown for "Base from Armours" row for ES/Armour/Evasion
 * Add colours to the resistances' label on the side bar
 * Add Ctrl-Right and Ctrl-Left to text fields (skip words)
 * Add list of recently imported accounts to the Import/Export Build tab
 * Add parsing for Elusive mod on boots
 * Add support for "Ignites you inflict deal Damage faster" mod
 * Add support for "Fortify Buffs you create instead grant 30% more Evasion Rating" mod
 * Add missing "increased Flask Charges gained" mod to Nomad unique belt
 * Add support for Fungal Ground from Sporeguard unique body armour
 * Add Bone Armour and Mirage Warriors to skill pool
 * Add 15 fuses to Explosive Arrow drop-down list
 * Cap max elemental resistance at 90
 * Fix mods for many old jewels
 * Fix Spreading Rot jewel
 * Fix Chin Sol's mods
 * Fix quality mods on Awakened Swift Affliction and Awakened Unbound Ailments
 * Fix Arctic Breath's cold dot not being modified by area damage mods
 * Fix Transfiguration of Mind interaction bug with Crown of Eyes
 * Fix parsing for travel skill mods
### 1.4.157.1 - 2019/12/21
 * Added a new unique item, The Savior
 * Added the ability to show only non-Awakened supports (or only Awakened supports!); the option can be found in the
   Skills tab under the socket group list
 * Added sources of increased maximum resistances to now show up in the resistance breakdown window
 * Add unique changes from 3.7
 * Fix issue where gem levels would get reset on loading or importing a build
 * Implicits on items that are copied from in-game are now correctly handled. Additionally, the ability of the program 
   to determine if modifiers on copied items are enchantments, implicits or explicits has been greatly improved, 
   and should almost always be correct; also, applying enchantments to items with implicits will now work correctly.
 * Fix + gem level mods on new influence amulets to now work properly
 * Fix Fractal Thoughts increased dex mod to now work properly
 * Fix support for old Red Nightmare mod wording
 * Fix ailment calculation crash

### 1.4.155.1 - 2019/12/16
 * Added the following new gems:
    * Artillery Ballista
	* Ensnaring Arrow
	* Shrapnel Ballista
	* Arrow Nova
	* Barrage (does not give accurate damage numbers)
	* Greater Volley
	* The 35 new Awakened support gems
 * Applied the skill reworks and balance changes for 3.9.0
 * Updated item bases, mods, and enchantments for 3.9.0
 * Added new influence bases to crafting window
 * Fix all Oils on tree to have correct values
 * Add more detailed breakdown for shock and chill
 
### 1.4.153.2 - 2019/12/14
 * Re-add Oils to tree
 * Add support for Ghost Shrouds
 * Add support for increased Ancestor Totem buff effect
 * Add support for Ritual of Awakening Hierophant node
 * Add support for 3 mods on Watchers Eye
 * Add Impale damage to Combined DPS sort option
 * Update Boss resistance values to 3.9 levels
 * Add Bleed DPS to sorting option
 * Add new spectres to the spectre library
	* Kraityn's Sentry, Chrome-infused Chimeral, Vaal Slayer, Primeval Hunter, Archer Statue, Crazed Driver
 * Add new spectre skills to library
	* Blast Rain, Elemental Hit Fire, Barrage, Ice Shot, Unearth, Tornado Shot, Flame Surge
 * Fix mod support for Chains of Command
 * Add Astral Projector Unique Ring (3.9 preview)
 * Fix rage granting damage to unarmed attacks
 * Fix UI on passive tree being too large for some resolutions
 * Fix node power not respecting your colour choice for highlighting
 * Add area tag to Perforate
 * Fix uniques with duplicate mods
 * Re-add Death's Harp back in
 * Update Snakepit Unique Ring

### 1.4.153.1 - 2019/12/12
 * Add 3.9 Passive Tree
 * Add 3.9 Unique Changes
 * Add support for Ryslatha's Coil
 * Add support for Perquil's Toe
 * Add support for Vaal Arc Lucky Buff
 * Add support for Chain of Command's mods
 * Add support for Warcried recently
 * Fix Minion DPS sorting bug for Uniques and tree
 * Fix Toxic Rain/Rain of Arrows pierce bug
 * Fix radius calculation for Jewels 
 * Fix Impale calculations for certain skills
      * Barrage, Blade Flurry, Blast Rain, Double Strike, Lacerate, Scourge Arrow,
  	    Cleave, Dual Strike, Riposte, Viper Strike, Static Strike
 * Counter-attack skills now show proper damage for each hit instead of DPS when using Impale
 * Update many uniques that had incorrect wordings

### 1.4.152.8 - 2019/12/09
 * Add Support for Greater Spell Echo
 * Widen manage passives trees drop down box
 * Rampage now appears as a box on the configs page
 * Show Impale DPS in sidebar for minions
 * Add The Ivory Tower Body armour (3.9 preview)
 * Add Mistwall Buckler Shield (3.9 preview)
 * Add support for Manastorm's lightning damage buff
 * Add support for Arborix and its mods
 * Add support for Augyre and its mods 
 * Add support for Vulconus and its mods
 * Add support for new Coated Shrapnel mod
 * Add support for Inquisitors increased damage on consecrated ground Sanctuary node
 * Add support for Golem Commanders increased damage node
 * Add increased area rampage mod support on Sinvicta's Mettle
 * Add proper support for Champions' Master of Metal node (set the number of impales for this to work)
 * Add Carrion golem to list of golems that work with primordial harmony
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
 * Fix minion resistance on Raise Spectre gem
 * Fix Bones of Ullr mod
 * Fix Perandus Signet mod
 * Fix Red Nightmare block chance
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
 * Add counterattack double damage bonus from Gladiator's Painforged node
 * Implement parsing for all of Slayer's nodes
 * Add support for Assassin's Mistwalker node and Ascendants  node for Assassin
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
	* Bestial Snake
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
 * Uniques in the unique database now show their source (if drop-limited) and upgrades (e.g. Prophecy/Blessing/Vial)
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
 * Aura/buff/curse skills can now be enabled/disabled in the Skills tab independently of the skill gem itself
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
 * Fixed a rare issue in which nodes in Ascendant could be unallocated without properly removing dependent nodes

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
 * Modifiers to Action Speed (e.g. Tailwind) now correctly affect Trap Throwing Speed, Mine Laying Speed, and Totem Placement speed
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
 * Updated the modifier rolls on Panquetzaliztli
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
   * Panquetzaliztli
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
 * Fixed error that occurred when changing some items to Shaper or Elder

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
 * Item modifiers that interact with socket colours are now supported (e.g. Prismatic Eclipse)

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
	* Beltimber Blade
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
    * Most should be fully or almost fully functional, with the exception of Mirage Archer
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
 * An explanatory message is now shown in the sidebar if the main skill is disabled (e.g. if no compatible weapon is equipped)
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
 * The link created when exporting the passive tree now opens in the 2.6.2 version of the official passive tree viewer

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
 * Fixed an issue where the effect of the Conflux Buff option would persist after Shaper of Desolation is deallocated

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
 * Fixed error that occurred when trying to copy an item set

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
 * Damage multipliers for skill parts (e.g. Flameblast stages) should now correctly apply to Decay

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
 * Damage multipliers for skill parts (e.g. Flameblast stages) should now correctly apply to Damaging Ailments
 * Added damage from buffs (e.g. Heralds, Anger) should now correctly apply to Damaging Ailments
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
 * Consolidated the program's various list controls; their appearance and behaviour should be largely unchanged,
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
   used in-game on the character sheet, but it can be overridden using a new option in the Configuration tab
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
 * Corrected The Aylardex's variants
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
	* Summon Spectral Wolf (from The Scourge)
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
*  For skills with a known hit rate (i.e. skills that show DPS instead of Average Damage), the combined rate of recovery from Leech and Gain on Hit is displayed in the sidebar
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
 * Added and updated many new uniques (shout-out to chuanhsing for the list on PoEDB)
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
 * The skill gem search field can now search by gem tag (e.g. 'support' or 'aura')
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
   * Standard Boss is equivalent to the old boss setting (30/30/30/15 resists, -60% curse effect)
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
   and red if the cost is increased (i.e. the reverse of the behaviour for other stats)
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
 * Corrected the ranges of the crit multiplier modifiers on the jewel templates
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
 * Support gem compatibility is now determined using the same data the game itself uses, and should now be 100% accurate

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
	      * If you've previously added an item by copying it from in-game, the character import will still add it,
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
 * Added support for skill DPS multipliers; currently only Lightning Tendrils uses it (it has a 4x multiplier)
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
