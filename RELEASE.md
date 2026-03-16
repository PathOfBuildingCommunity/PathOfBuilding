# How to release Path of Building Community

## Prerequisites

## Choosing a new version number

Path of Building Community follows [Semantic Versioning](https://semver.org/).

## General Application updates

Releases are done via GitHub actions in order to simplify release note generation.

Steps:
1. First, update any GGPK files and tree files needed in the dev branch.  This will minimize what you have to update later.
2. [Navigate to the "Release new version" action](https://github.com/PathOfBuildingCommunity/PathOfBuilding/actions/workflows/release.yml)
3. Click "Run workflow" on the right, and fill in the values
    - Run the workflow from the 'dev' branch
    - Fill in the [most recent tag](https://github.com/PathOfBuildingCommunity/PathOfBuilding/tags)
    - Choose a new version number (see above)
4. This will run and create a new branch and PR so you can review the changes, making tweaks to any of the release notes that don't make sense
5. If you changed any files after the PR was created, you'll have to update [the manifest file](manifest.xml)
    - Run `python3 update_manifest.py --in-place` from the root directory of PoB
6. Create a tag for the new release either by creating a release on GitHub, or running (for example) `git tag v2.4.0; git push --tags`
7. Merge the PR into `master`.  PoB will take a few minutes before it can find the update

## GGPK Data updates

Updating data from the GGPK uses the PoB exporter (see CONTRIBUTING.md#exporting-ggpk-data-from-path-of-exile).  Run each script in order, then check the differences in data to make sure nothing is missing that is expected.

## Skill tree updates

Skill tree updates require JSON data, usually released by GGG a few days before a new
league starts, in forum posts like
[this one](https://www.pathofexile.com/forum/view-thread/3147480).
The JSON data and required skill tree assets should come in a `.zip` archive.

Steps:
1. Download the `.zip` archive.
2. Create a new directory in `./src/TreeData` with the following schema:
    `<major_league_version>_<minor_league_version>`. For alternate or ruthless trees, add the suffixing as appropriate.
    For 3.14, the correct directory name would be `3_14`.
    For 3.25 Ruthless 'alternate' tree, the correct directory name would be `3_25_ruthless_alternate`.
3. Copy the following file from the `.zip` archive root to the new directory:
   * `data.json`.
   Note for Ruthless for example, the exported data from GGG will be `ruthless.json`, and this file should be copied into the new directory and renamed to `data.json` for the following steps to pick it up.
4. Copy the following files from the `assets` subdirectory in the `.zip` archive to the
    new directory:
    * `mastery-active-effect-3.png`
    * `mastery-active-selected-3.png`
    * `mastery-connected-3.png`
    * `mastery-disabled-3.png`
    * `skills-3.jpg`
    * `skills-disabled-3.jpg`.
5. Run `./fix_ascendancy_positions.py`.
6. Open `./src/GameVersions.lua` and update `treeVersionList`, `treeVersions`, and `poePlannerVersions`.  The latter can be found via https://cdn.poeplanner.com/json/versions.json
   according to the file's format. This is important, otherwise the JSON data converter
   won't trigger.
7. Restart Path of Building Community. This should result in a new file `tree.lua`.
8. Remove `data.json` and `sprites.json` from the new directories. Do not commit these files.

## Timeless Jewel updates

The Timeless jewels determine what effect they have on a node based on the "Look up Tables" in \src\Data\TimelessJewelData
The LuTs for the Timeless jewels come from https://github.com/Regisle/TimelessJewelData
More information can be found there.

The LuTs PoB uses are slightly different due to historical reasons, and so they can be generated using the generator from there.


-------------------------------------------------------------------------------------------------------
Steps to Generate Timeless Jewel LuTs for PoB:
1. Clone repo from https://github.com/Regisle/TimelessJewelData/tree/Generator
2. Open DatafileGenerator.sln in Visual Studio
3. Grab new data.json tree file
4. Grab new AlternatePassiveAdditions.json and AlternatePassiveSkills.json from https://snosme.github.io/poe-dat-viewer/ and clicking on 'Export data' in the top right
5. Run following commands in the Visual Studio command prompt order, adjusting for file location
	dotnet run --project DataFileGenerator
	E:\PoB Dev Work\TimelessJewelData\AlternatePassiveAdditions.json
	E:\PoB Dev Work\TimelessJewelData\AlternatePassiveSkills.json
	E:\PoB Dev Work\GGG Skill Tree\data.json
	E:\PoB Dev Work\PathOfBuildingCommunity\src\Data\TimelessJewelData
6. Choose Compressed
7. Replace updated Files in \src\Data\TimelessJewelData

Alt tab out and back in to make right click paste work
------------------------------------------------------------------------------------------------------- 

If updated this way making a PR to https://github.com/Regisle/TimelessJewelData with the files in the format it uses is appreciated.
To do this follow steps 1-5 the same and choose the other option for step 6.


## Installer creation

Path of Building Community offers both installable and standalone releases. They're
built with automation scripts found in the repository described below.

Prerequisites:
- Have Git 2.21.0+ installed and `git` in your `PATH`.
  Verify by running `git --version`.
- Have NSIS 3.07+ installed and `makensis` in your `PATH`.
  Verify by running `makensis /version`.
  You may have to add this manually after installation.
- Have Python 3.7+ installed and `python` in your `PATH`.
  Verify by running `python --version`.
- NB: You don't have to create a virtual environment, as you don't need to install any
  third-party libraries.

Installation:
- Clone this repository to a directory of your choice:

      git clone https://github.com/PathOfBuildingCommunity/PathOfBuildingInstaller.git
- Please note that you might not have access to this repository if you're not a Path of
  Building Community maintainer.
  
Usage:

      python make_release.py
- To change the output folder or repository URL, simply edit the script file.
- Created installers can be found in the `./Dist` directory.
- NB: Output like the following can be safely ignored. This is due to NSIS complaining
about including an empty directory.

      AppData\Local\Temp\tmp5fo1ha19\Update -> no files found. (NSIS/Setup.nsi:158)
