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

Updating data from the GGPK uses the PoB exporter (see CONTRIBUTING.md#exporting-ggpk-data-from-path-of-exile), followed by some manual tweaks that haven't been fixed in a script, yet.

Steps:
1. Run each script in the Exporter in order
2. Revert the following changes similar to the linked examples:
    - [Fix stats on Rigwald's Pack](https://github.com/PathOfBuildingCommunity/PathOfBuilding/commit/85912cc8631bf55f999f8dfbda5fa6510252518c#diff-72415c450079cf8e5de1f00680f4918fd78e43aea4ed78dc5906d5ccf6fb66fb)
    - Make sure "of the Underground" mods don't apply to you as well as nearby enemies in [ModItem.lua](src/Data/ModItem.lua)
    - [Make sure the description of a keystone isn't removed](src/Data/LegionPassives.lua#L3911-L3915)

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
