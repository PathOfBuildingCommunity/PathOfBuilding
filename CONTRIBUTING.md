# Contributing to Path of Building

## Reporting bugs

#### Before creating an issue:
* Check that the bug hasn't been reported in an existing issue. View similar issues on the left of the submit button.
* Make sure you are running the latest version of the program. Click "Check for Update" in the bottom left corner.
* If you've found an issue with offence or defence calculations, make sure you check the breakdown for that calculation in the Calcs tab to see how it is being performed, as this may help you find the cause.

#### When creating an issue:
* Please provide detailed instructions on how to reproduce the bug, if possible.
* Provide the build share code to a build that is affected by the bug, if possible. In the "Import/Export Build" tab, click "Generate", then "Share with Pastebin" and add the link to your post.

## Requesting features
Feature requests are always welcome. Note that not all requests will receive an immediate response.

#### Before submitting a feature request:
* Check that the feature hasn't already been requested. Look at all issues with titles that might be related to the feature.
* Make sure you are running the latest version of the program, as the feature may already have been added. Click "Check for Update" in the bottom left corner.

#### When submitting a feature request:
* Be specific! The more details, the better.
* Small requests are fine, even if it's just adding support for a minor modifier on a rarely-used unique.

## Contributing code

#### Before submitting a pull request:
* Familiarise yourself with the code base [here](docs/rundown.md) to get you started.
* There is a [Discord](https://discordapp.com/) server for **active development** on the fork and members are happy to answer your questions there.
  If you are interested in joining, send a private message to any of **Cinnabarit#1341**, **LocalIdentity#9871**, **Yamin#5575** and we'll send you an invitation.

#### When submitting a pull request:
* **Pull requests must be made against the 'dev' branch**, as all changes to the code are staged there before merging to 'master'.
* Make sure that the changes have been thoroughly tested!
* Make sure not to commit `./Data/ModCache.lua`. This is a very large, automatically generated file that is updated in the repository for releases only.
* There are many more files in the `./Data` directory that are automatically generated. To change these, instead change the scripts in the `./Export` directory.

#### Setting up a development install
Note: This tutorial assumes that you are already familiar with Git and basic command line tools.

The easiest way to make and test changes is by setting up a development install, in which the program runs directly from a local copy of the repository:

1. Clone the repository using this command:

       git clone -b dev https://github.com/PathOfBuildingCommunity/PathOfBuilding.git
2. Create a shortcut to the 'Path of Building.exe' in your main installation of the program.
3. Add the path to `./Launch.lua` as an argument to the shortcut. You should end up with something like: `"C:\%APPDATA%\Path of Building Community\Path of Building.exe" "C:\PathOfBuilding\Launch.lua"`.

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

Note that automatic updates are disabled in Dev Mode, so you must update manually.

#### Keeping your fork up to date

Note: This tutorial assumes that you are already familiar with Git and basic command line tools.

Note: If you've configured a remote already, you can skip ahead to step 3.

1. Add a new remote repository and name it `upstream`.

       git remote add upstream https://github.com/PathOfBuildingCommunity/PathOfBuilding.git
2. Verify that adding the remote worked.

       git remote -v
3. Fetch all branches and their commits from upstream.

       git fetch upstream
4. Check out your local `dev` branch if you haven't already.

       git checkout dev
5. Merge all changes from `upstream/dev` into your local `dev` branch.

       git rebase upstream/dev
6. Push your updated branch to GitHub.

       git push -f origin dev

#### Setting up a development environment

Note: This tutorial assumes that you are already familiar with the development tool of your choice.

If you want to use a text editor, [Visual Studio Code](https://code.visualstudio.com/) is recommended.
If you want to use an IDE instead, [PyCharm Community](https://www.jetbrains.com/pycharm/) or [IntelliJ Idea Community](https://www.jetbrains.com/idea/) are recommended.
They are all free and open source and support [EmmyLua](https://github.com/EmmyLua), a Lua plugin that comes with a language server, debugger and many pleasant features. It is recommended to use it over the built-in Lua plugins.

##### Visual Studio Code

1. Create a new 'Debug Configuration' of type 'EmmyLua New Debug'
2. Open the Visual Studio Code extensions folder. On Windows, this defaults to `%USERPROFILE%/.vscode/extensions`.
3. Find the sub-folder that contains `emmy_core.dll`. You should find both x86 and x64; pick x86. For example, `C:/Users/someuser/.vscode/extensions/tangzx.emmylua-0.3.28/debugger/emmy/windows/x86`.
4. Paste the following code snippet directly below `function launch:OnInit()` in `./Launch.lua`:
  ```lua
-- This is the path to emmy_core.dll. The ?.dll at the end is intentional.
package.cpath = package.cpath .. ';C:/Users/someuser/.vscode/extensions/tangzx.emmylua-0.3.28/debugger/emmy/windows/x86/?.dll'
local dbg = require('emmy_core')
-- This port must match the Visual Studio Code configuration. Default is 9966.
dbg.tcpListen('localhost', 9966)
-- Uncomment the next line if you want Path of Building to block until the debugger is attached
--dbg.waitIDE()
  ```
5. Start Path of Building Community
6. Attach the debugger

##### PyCharm Community / IntelliJ Idea Community

1. Create a new 'Debug Configuration' of type 'Emmy Debugger(NEW)'.
2. Select 'x86' version.
3. Select if you want the program to block (checkbox) until you attached the debugger (useful if you have to debug the startup process).
4. Copy the generated code snippet directly below `function launch:OnInit()` in `./Launch.lua`.
5. Start Path of Building Community
6. Attach the debugger

#### Exporting GGPK Data from Path of Exile

Note: This tutorial assumes that you are already familiar with the GGPK and its structure. [poe-tool-dev/ggpk.discussion](https://github.com/poe-tool-dev/ggpk.discussion/wiki)
is a good starting point.

The `./Data` folder contains generated files which are created using the scripts in the `./Export/Scripts` folder based on Path of Exile game data. 
If you change any logic/configuration in `./Export`, you will need to regenerate the appropriate `./Data` files. You can do so by running the `./Export` scripts using the `.dat` viewer at `./Export/Launch.lua`:

1. Obtain a copy of an OOZ extractor and copy it into `./Export/ggpk/`.
2. Create a shortcut to `Path of Building.exe` with the path to `./Export/Launch.lua` as first argument. You should end up with something like: `"C:\%APPDATA%\Path of Building Community\Path of Building.exe" "C:\PathOfBuilding\Export\Launch.lua"`.
3. Run the shortcut, and the GGPK data viewer UI will appear. If you get an error, be sure you're using the latest release of Path of Building Community.
4. Paste the path to `Content.ggpk` (or, for Steam users, `C:\Program Files (x86)\Steam\steamapps\common\Path of Exile`) into the text box in the top left, and hit `Enter` to read the GGPK. If successful, you will see a list of the data tables in the GGPK file. Note: This will not work on the GGPK from the torrent file released before league launches, as it contains no `./Data` section.
5. Click `Scripts >>` to show the list of available export scripts. Double-clicking a script will run it, and the box to the right will show any output from the script.
6. If you run into any errors, update the code in `./Export` as necessary and try again.
