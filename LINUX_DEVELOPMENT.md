# Contribute to Path of Building on Linux

Only tested with the following setup. Your mileage may vary:

1. Ubuntu 18.04
2. Lutris
3. Visual Studio Code
3. EmmyLua VSCode plugin (Optional)

# Installation

Perform the following steps in order:

## Install tools

1. Install Lutris: https://lutris.net/
2. Install either VSCode or VSCodium: https://code.visualstudio.com/ or https://github.com/VSCodium/vscodium
3. Install the EmmyLua plugin (Optional if you want debugging)

## Download Path of Building

1. Download path of building release (newest `.zip` file) from here: https://github.com/Openarl/PathOfBuilding/releases
2. Extract the zip to a folder (eg. `/home/your_username/pob`)

## Configuring Path of Building to use the fork

In the folder you extracted path of building to, edit the `manifest.xml` file and change the line with `part="program"` to point to the PathOfBuildingCommunity repository.

eg:

`<Source part="program" url="https://raw.githubusercontent.com/Openarl/PathOfBuilding/{branch}/" />`

becomes:

`<Source part="program" url="https://raw.githubusercontent.com/PathOfBuildingCommunity/PathOfBuilding/{branch}/" />`

## Clone your fork

Clone your path of building fork somewhere (eg. `/home/your_username/workspace/PathOfBuilding` )

## Configuring Lutris

1. Install Lutris
2. Click the "+" -> Add Game
3. Name the game "Path of Building Dev"
4. Select "Wine" as the Runner
5. Go to "Game options" tab
6. Set Executable to the "Path of Building.exe" in the release folder you extracted: `/home/your_username/pob/Path of Building.exe`

7. Set Arguments to point to the `Launch.lua` file in your fork, with the _important change_ of prefixing with `z:` eg: `z:/home/your_username/workspace/PathOfBuilding/Launch.lua` 

8. You're done! Hit Save.


## Updating Launch.lua to use a emmylua debugger (optional)

in `Launch.lua`, you'll need to update the beginning of the `OnInit()` method to allow the debugger to connect:

if you use the default emmylua extension to insert the debugger code on linux, you'll get something similar to the following:

```lua
package.cpath = package.cpath .. ";/home/your_username/.vscode-oss/extensions/tangzx.emmylua-0.3.28/debugger/emmy/linux/emmy_core.so"
local dbg = require("emmy_core")
dbg.tcpListen("localhost", 9966)
```

This won't work in Wine, since we really need to use the windows version. Change the first line as follows (replace `your_username` with whatever is appropriate on your system):

```lua
package.cpath = package.cpath .. ";z:/home/your_username/.vscode-oss/extensions/tangzx.emmylua-0.3.28/debugger/emmy/windows/x86/?.dll"
local dbg = require("emmy_core")
dbg.tcpListen("localhost", 9966)
```

This will allow Path of Building in wine to connect to our linux development environment!

You'll now have access to the EmmyLua debugger functionality in your editor.