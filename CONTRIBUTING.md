# Contributing to Path of Building

## Reporting bugs

#### Before creating an issue:
* Check that the bug hasn't been reported in an existing issue.
* Make sure you are running the latest version of the program; click "Check for Update" at the bottom left corner.
* If you've found an issue with offence or defence calculations, make sure you check the breakdown for that calculation in the Calcs tab to see how it is being performed, as this may help you find the cause.

#### When creating an issue:
* Please provide detailed instructions on how to reproduce the bug, if possible.
* If the issue affects a specific build, please provide the build share code: In the Import/Export Build tab, click "Generate", then "Share with Pastebin" and add the link to your post.

## Requesting features
Feature requests are always welcome. Note that not all requests will recieve an immediate response.

#### Before submitting a feature request:
* Check that the feature hasn't already been requested; look at all issues with titles that might be related to the feature.
* Make sure you are running the latest version of the program, as the feature may already have been added; click "Check for Update" at the bottom left corner.

#### When submitting a feature request:
* Be specific! The more details, the better.
* Small requests are fine, even if it's just adding support for a minor modifier on a rarely-used unique.

## Contributing code

#### When submitting a pull request:
* **Pull requests must be made against the 'dev' branch**, as all changes to the code are staged there before merging to 'master'.
* Make sure that the changes have been thoroughly tested!

#### Setting up a development install

The easiest way to make and test changes is by setting up a development install, in which the program runs directly from a local copy of the repository:
1. Clone or download the repository; make sure you grab the dev branch. If you have [Git](https://git-scm.com/) installed, you can use this command: `git clone -b dev https://github.com/Openarl/PathOfBuilding.git`.
2. Copy the 'TreeData' folder from your main installation into the repository; if you used the .exe to install then it will be in "%ProgramData%\Path of Building".
3. Create a shortcut to the 'Path of Building.exe' in your main installation of the program.
4. Add the path and filename of the repository's 'Launch.lua' as an argument to the shortcut; you should end up with something like: `"C:\Program Files (x86)\Path of Building\Path of Building.exe" "C:\Path of Building\Launch.lua"`.

You can now use the shortcut to run the program from the repository. Running the program in this manner automatically enables 'Dev Mode', which has some handy debugging feature:
* `F5` restarts the program in-place (this is what usually happens when an update is applied).
* Holding `Alt` adds additional debugging information to tooltips:
  * Items and passives show all internal modifiers that they are granting.
  * Stats that aren't parsed correctly will show any unrecognised parts of the stat description.
  * Passives also show node ID and node power values.
  * Conditional options in the Configuration tab show the list of dependant modifiers.
* While in the Tree tab, holding `Alt` also highlights nodes that have unrecognised modifiers.

Note that the updates system is disabled in Dev Mode, so you must update manually.
