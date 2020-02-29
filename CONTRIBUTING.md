# Contributing to Path of Building

## Reporting bugs

#### Before creating an issue:
* Check that the bug hasn't been reported in an existing issue. View similar issues on the left of the submit button.
* Make sure you are running the latest version of the program; click "Check for Update" at the bottom left corner.
* If you've found an issue with offence or defence calculations, make sure you check the breakdown for that calculation in the Calcs tab to see how it is being performed, as this may help you find the cause.

#### When creating an issue:
* Please provide detailed instructions on how to reproduce the bug, if possible.
* Provide the build share code to a build that is affected by the bug, if possible. In the "Import/Export Build" tab, click "Generate", then "Share with Pastebin" and add the link to your post.

## Requesting features
Feature requests are always welcome. Note that not all requests will receive an immediate response.

#### Before submitting a feature request:
* Check that the feature hasn't already been requested; look at all issues with titles that might be related to the feature.
* Make sure you are running the latest version of the program, as the feature may already have been added; click "Check for Update" at the bottom left corner.

#### When submitting a feature request:
* Be specific! The more details, the better.
* Small requests are fine, even if it's just adding support for a minor modifier on a rarely-used unique.

## Contributing code

#### Before submitting a pull request:
* There is a [Discord](https://discordapp.com/) server for **active development** on the fork and members are happy to answer your questions there.
  If you are interested in joining, send a private message to any of `Cinnabarit#1341`, `LocalIdentity#9871`, `nick_#8198` and we'll send you an invite.

#### When submitting a pull request:
* **Pull requests must be made against the 'dev' branch**, as all changes to the code are staged there before merging to 'master'.
* Make sure that the changes have been thoroughly tested!
* Make sure not to commit `./Data/2_6/ModCache.lua` or `./Data/3_0/ModCache.lua`. These are very large, automatically generated files that are updated in the repository for releases only.
* There are many more files in the `./Data` directory that are automatically generated. To change these, instead change the scripts in the `./Export` directory.

#### Setting up a development install

The easiest way to make and test changes is by setting up a development install, in which the program runs directly from a local copy of the repository:
1. Install [Git](https://git-scm.com/)
2. Open Git Bash
3. `cd` into the directory you want to clone the repository to, for example:

       cd ~ && mkdir GitHub && cd GitHub
4. Clone the repository using this command:

       git clone -b dev https://github.com/PathOfBuildingCommunity/PathOfBuilding.git
5. Create a shortcut to the 'Path of Building.exe' in your main installation of the program.
6. Add the path to `./Launch.lua` as an argument to the shortcut. You should end up with something like: `"C:\Program Files (x86)\Path of Building\Path of Building.exe" "C:\Path of Building\Launch.lua"`.

You can now use the shortcut to run the program from the repository. Running the program in this manner automatically enables 'Dev Mode', which has some handy debugging feature:
* `F5` restarts the program in-place (this is what usually happens when an update is applied).
* `Ctrl` + `~` toggles the console (Note that this does not work with all keyboard layouts. US layout is a safe bet though).
* `ConPrintf()` can be used to output to the console. Search for "===" in the project files if you want to get rid of the default debugging strings.
* Holding `Alt` adds additional debugging information to tooltips:
  * Items and passives show all internal modifiers that they are granting.
  * Stats that aren't parsed correctly will show any unrecognised parts of the stat description.
  * Passives also show node ID and node power values.
  * Conditional options in the Configuration tab show the list of dependent modifiers.
* While in the Tree tab, holding `Alt` also highlights nodes that have unrecognised modifiers.
* Holding `Ctrl` while launching the program will rebuild the mod cache.

Note that the updates system is disabled in Dev Mode, so you must update manually.

#### Keeping your fork up to date

Note: If you've configured a remote already, you can skip ahead to step 6. To remove an old remote, run

       git remote remove upstream
1. Open Git Bash.
2. `cd` into the repository directory.
3. Check your current remote repositories.

       git remote -v
4. Add a new remote repository and name it `upstream`.

       git remote add upstream https://github.com/PathOfBuildingCommunity/PathOfBuilding
5. Verify that adding the remote worked by running the last command again.

       git remote -v
6. Fetch all branches and their commits from upstream.

       git fetch upstream
7. Check out your local `dev` branch if you haven't already.

       git checkout dev
8. Merge all changes from `upstream/dev` into your local `dev` branch.

       git rebase upstream/dev
9. Push your updated branch to GitHub.

       git push -f origin dev

#### Setting up a development environment

If you want to use a text editor, [Visual Studio Code](https://code.visualstudio.com/) is recommended.
If you want to use an IDE instead, [PyCharm Community](https://www.jetbrains.com/pycharm/) or [IntelliJ Idea Community](https://www.jetbrains.com/idea/) are recommended.
They are all free and open source and support [EmmyLua](https://github.com/EmmyLua), a Lua plugin that comes with a language server, debugger and many pleasant features. It is recommended to use it over the built-in Lua plugins.

To setup a debugger for PoB on an IDE with EmmyLua:
* Create a new 'Debug Configuration' of type 'Emmy Debugger(NEW)'.
* Select 'x86' version.
* Select if you want the program to block (checkbox) until you attached the debugger (useful if you have to debug the startup process).
* Copy the generated code snippet directly below `function launch:OnInit()` in `./Launch.lua`.
* Start PoB and attach debugger.

#### Exporting Data from a GGPK file

The repository also contains the system used to export data from the game's Content.ggpk file. This can be found in the Export folder. The data is exported using the scripts in `./Export/Scripts`, which are run from within the `.dat` viewer.

How to export data from a GGPK file:

1. Create a shortcut to `Path of Building.exe` with the path to `./Export/Launch.lua` as first argument. You should end up with something like: `"C:\Program Files (x86)\Path of Building\Path of Building.exe" "C:\Path of Building\Export\Launch.lua"`.
2. Run the shortcut, and the GGPK data viewer UI will appear. If you get an error, be sure you're using the latest release of Path of Building.
3. Paste the path to `Content.ggpk` into the text box in the top left, and hit `Enter` to read the GGPK. If successful, you will see a list of the data tables in the GGPK file. Note: This will not work on the GGPK from the torrent file released before league launches, as it contains no `./Data` section.
4. Click `Scripts >>` to show the list of available export scripts. Double-clicking a script will run it, and the box to the right will show any output from the script.
5. If you run into any errors, update the code in `./Export` as necessary and try again.
