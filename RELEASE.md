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
    * `mastery-active-effect-3.png`
    * `mastery-active-selected-3.png`
    * `mastery-connected-3.png`
    * `mastery-disabled-3.png`
    * `skills-3.jpg`
    * `skills-disabled-3.jpg`.
5. Run `./fix_ascendancy_positions.py`.
6. Open `./src/GameVersions.lua` and update `treeVersionList` and `treeVersions`
   according to the file's format. This is important, otherwise the JSON data converter
   won't trigger.
7. Restart Path of Building Community. This should result in a new file `tree.lua`.
8. Remove `data.json` from the new directory. Do not commit this file.

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
