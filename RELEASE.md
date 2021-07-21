# How to release Path of Building Community

## Prerequisites

## Choosing a new version number

Path of Building Community follows [Semantic Versioning](https://semver.org/).

## General Application updates

## GGPK Data updates

## Skill tree updates

Skill tree updates require JSON data, usually released by GGG a few days before a new
league starts, in forum posts like
[this one](https://www.pathofexile.com/forum/view-thread/3147480).
The JSON data and required skill tree assets should come in a `.zip` archive.

Steps:
1. Download the `.zip` archive.
2. Create a new directory in `./src/TreeData` with the following schema:
    `<major_league_version>_<minor_league_version>`.
    For 3.14, the correct directory name would be `3_14`.
3. Copy the following file from the `.zip` archive root to the new directory:
   * `data.json`.
4. Copy the following files from the `assets` subdirectory in the `.zip` archive to the
    new directory:
    * `groups-3.png`
    * `skills-3.jpg`
    * `skills-disabled-3.jpg`.
5. Copy `./fix_ascendancy_positions.py` to the new directory and run it. This should
   result in a new file `data_fixed.json`. Remove `data.json` and rename
   `data_fixed.json` to `data.json`. Remove the copied `fix_ascendancy_positions.py`.
6. Open `.src/GameVersions.lua` and update `treeVersionList` and `treeVersions`
   according to the file's format. This is important, otherwise the JSON data converter
   won't trigger.
7. Restart Path of Building Community. This should result in a new file `tree.lua`.
8. Remove `data.json` from the new directory. Do not commit this file.
