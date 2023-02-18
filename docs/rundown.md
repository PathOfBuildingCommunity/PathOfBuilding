# Path of Building Community Fork Codebase Rundown

## Layout
* ### Assets
    * **game_ui_small.png**
        Overlay on top of range_guide.png.
    * **range_guide.png**
        Area of effect scale in Calcs view.
    * **ring.png**
        Ring overlay on hovering over jewel sockets in Tree view.
    * **ShadedInnerRing.png**
        Ring overlay for radius jewels.
    * **ShadedInnerRingFlipped.png**
        Ring overlay for Thread of Hope.
    * **ShadedOuterRing.png**
        Ring overlay for radius jewels.
    * **ShadedOuterRingFlipped.png**
        Ring overlay for Thread of Hope.
    * **small_ring.png**
        Highlighting of matching nodes in Tree view search results.
* ### Classes
    * **BuildControlList.lua**
    * **ButtonControl.lua**
    * **CalcBreakdownControl.lua**
    * **CalcSectionControl.lua**
    * **CalcsTab.lua**
    * **CheckBoxControl.lua**
    * **ConfigTab.lua**
    * **Control.lua**
    * **ControlHost.lua**
    * **DropDownControl.lua**
    * **EditControl.lua**
    * **FolderListControl.lua**
    * **GemSelectControl.lua**
    * **ImportTab.lua**
    * **Item.lua**
    * **ItemDBControl.lua**
    * **ItemListControl.lua**
    * **ItemSetListControl.lua**
    * **ItemSlotControl.lua**
    * **ItemsTab.lua**
    * **LabelControl.lua**
    * **ListControl.lua**
    * **MinionListControl.lua**
    * **ModDB.lua**
    * **ModList.lua**
    * **ModStore.lua**
    * **NotableDBControl.lua**
    * **NotesTab.lua**
    * **PassiveSpec.lua**
    * **PassiveSpecListControl.lua**
    * **PassiveTree.lua**
    * **PassiveTreeView.lua**
    * **PathControl.lua**
    * **PopupDialog.lua**
    * **PowerReportListControl.lua**
    * **ScrollBarControl.lua**
    * **SearchHost.lua**
    * **SectionControl.lua**
    * **SharedItemListControl.lua**
    * **SharedItemSetListControl.lua**
    * **SkillListControl.lua**
    * **SkillsTab.lua**
    * **SliderControl.lua**
    * **TextListControl.lua**
    * **Tooltip.lua**
    * **TooltipHost.lua**
    * **TreeTab.lua**
    * **UndoHandler.lua**
* ### Data
    * **Global.lua**
        Contains mappings of colour codes, mod flags and keywords. Also contains an enumeration of skill types used in the `ActiveSkills.dat` and `GrantedEffects.dat` game files to hardcode specific interactions. This has to be reverse engineered from the GGPK and not all flags are fully understood yet.
    * **New.lua**
        Newly announced uniques live here until their mod ranges are known.
* ### Export
    The export system warrants its own in-depth document.
* ### Modules
    * **Build.lua**
        Contains controls for everything on the build screen:
        top: "back", "save", "save as", skill points, level, class, ascendancy
        left: the buttons for the different tabs, bandits, pantheon, main skill, stat overview.
        Loads build, initialises all tab components, loads corresponding sections from the build file, builds calculation tab output.
        Contains functions to load/save build and input handling, popups for build version migration, saving, spectre library.
        Contains functions to add totem/minion stats to the sidebar, refreshing and building the statlist.
        Contains functions for attribute requirements in tooltips and comparison of tooltips.
        Contains additional file loading/saving logic.
    * **BuildList.lua**
        Contains the build selection screen that only has basic UI elements not exclusive to this screen. Filesystem manipulation, searching for XML build files in the build path and sorting the resulting list can be found here.
    * **CalcActiveSkill.lua**
    * **CalcBreakdown.lua**
    * **CalcDefence.lua**
    * **CalcOffence.lua**
    * **CalcPerform.lua**
    * **Calcs.lua**
        Loads other calcs modules.
        Contains printer for console debugging output, calculators for changes to nodes, items, gems, etc and builds stats for sidebar _and_ calcs tab (one function).
    * **CalcSections.lua**
    * **CalcSetup.lua**
        Most of the code here revolves around the mod databases of player and enemy actors. Adds all mods that the two share with each other, as well as all modifiers that are specific to one actor type. Stuff like the base stats of characters, bandits and pantheons get applied here. Builds the list of nodes on the skill tree as well as the mod list for each node, including all mods added, removed or changed by radius jewels, and adds it to the calculation environment. Tracks attribute requirements, finds skills granted by items, checks jewel sockets, radius jewel and abyss jewels, adds flasks. Has special handling for Necromantic Aegis and Dancing Dervish. Counts number of corrupted/Shaper/Elder/etc. items. Processes extra skills granted by items and removes socket groups that no longer have matching items. Gets weapon data, adds granted passives and merges mods of allocated passives. Sets main skill group, builds list of active skills including support gems. Sets the main skill to the default attack if none is selected.
    * **CalcTools.lua**
        Calculates mod values and tally up increased/more modifiers, validates gems and skill types, checks if support gems can apply to active gems, determines gem type and attribute requirements, builds stat table for skill.
    * **Common.lua**
        Contains various utilities such as a class library, character encoding converters, MurmurHash non-cryptographic hash function used in the GGPK file, type casts used for working with the GGPK file, JSON-to-Lua converter, utilities for manipulating and printing tables, functions for comparison, rounding, formatting and file manipulation
    * **ConfigOptions.lua**
        Contains specifications of the various configuration options for buffs, conditions, map mods and more.
    * **Data.lua**
        Contains skill types, item types. Duplicates some mod creation/processing logic.
        Holds common mappings such as jewel radius, monster exp multiplier, weapon and base info.
        Loads uniques and all bases, skills, stat descriptions, item mods, enchantments, essences, pantheons, skills, gems, minions and builds list of item bases, loads rare items template. There are extra checks to load either the 3.0 or the 2.6 versions, if applicable.
    * **ItemTools.lua**
        Calculate the range of mods on items, replace non-ascii characters in item text and colour mod lines.
    * **Main.lua**
        Loads game version, common, data, mod/item/calc/pantheon..tools.
        There are two modes of the program: the build list and the build itself.
        Sets build paths, loads mod caches, trees, rare and unique items.
        Rebuilds mod caches if in dev mode.
        Draws non-mode-dependent UI controls.
    * **ModParser.lua**
        Parses all mods on items, skills, pantheon to generate the `ModCache`.
        Warrants its own in-depth document.
    * **ModTools.lua**
        Functions to create mods, and format values, flags, tags.
        Also loads the `ModCache` generated by the `ModParser`s.
    * **PantheonTools.lua**
        Parser for pantheon mods used during `CalcSetup`.
    * **StatDescriber.lua**
* ### TreeData
* **.gitattributes**
    See <https://www.git-scm.com/docs/gitattributes>.
* **.gitignore**
    See <https://www.git-scm.com/docs/gitignore>.
* **CHANGELOG.md**
    Patch notes written in Markdown.
* **changelog.txt**
    Patch notes written in plain text.
* **CONTRIBUTING.md**
    Contribution guides.
* **GameVersions.lua**
    Contains global variables to identify and convert outdated builds. Also contains global table of passive skill tree versions used to upgrade to newer skill tree versions.
* **HeadlessWrapper.lua**
    Provides stubs for PoB's graphics host and its environment. Can be used to run PoB from the command line. You would still need to implement at least `Deflate()` and `Inflate()` to import/export builds. Useful for automated testing.
* **Launch.lua**
    Updates on first start, discerns whether PoB is running in dev mode, initialises renderer, loads `Main` module, has callbacks for exiting the program, advancing frames, registering key presses, launching non-blocking subscripts, updating, notification and error prompts.
* **LaunchInstall.lua**
    Downloads and installs the auto-updater on finishing program installation.
* **LICENSE.md**
    MIT licence
* **manifest.xml**
    Contains file name : SHA-1 hash pairings used to determine which files to update.
* **README.md**
    Project overview
* **runtime-win32.zip**
    Contains PoB executable, update executable, compiled libraries `libcurl` (HTTPS requests), `lcurl` (libcurl bindings for Lua), `lua51` (LuaJIT 5.1), `lzip` (DEFLATE), `SimpleGraphic` (custom 2D graphics host), Lua libraries for Base64, JSON, SHA-1, XML, and fonts.
* **tree-2_6.zip**
* **tree-3_6.zip**
* **tree-3_7.zip**
* **tree-3_8.zip**
* **tree-3_9.zip**
* **tree-3_10.zip**
* **tree-3_11.zip**
* **tree-3_12.zip**
* **update_manifest.py**
    Generates SHA-1 hashes for files in `manifest.xml`.
    New files have to be manually added to `manifest.xml` to be processed.
* **UpdateApply.lua**
    Consumes and applies table of update instructions. Updating the runtime itself is done from a separate host environment.
* **UpdateCheck.lua**
    Compares local and remote manifests to determine which files need to be updated, downloads these files and `changelog.txt`, rebuilds `manifest.xml` and builds table of update instructions.
