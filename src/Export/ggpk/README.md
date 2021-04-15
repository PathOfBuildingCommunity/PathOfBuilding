# Using `bun_extract_file.exe`

GGPK_OR_STEAM_DIR is the fully qualified path of where your Content.ggpk is located
Example: "C:\Program Files (x86)\Grinding Gear Games\Path of Exile\Content.ggpk"

## Options
Extract a file list of all files in the GGPK
`bun_extract_file list-files GGPK_OR_STEAM_DIR`
**EXAMPLE**: `.\bun_extract_file.exe list-files "C:\Program Files (x86)\Grinding Gear Games\Path of Exile\Content.ggpk" > file_list.log`

Extract a list of specific files from the GGPK
`bun_extract_file extract-files GGPK_OR_STEAM_DIR OUTPUT_DIR [FILE_PATHS...]`

Extract a regex-based list of files from the GGPK
`bun_extract_file extract-files [--regex] GGPK_OR_STEAM_DIR OUTPUT_DIR [FILE_PATHS...]`
If `--regex` is given, all input lines or command line list are treated as C++ <regex> regexes which are roughly ECMAScript.
**EXAMPLE**: `.\bun_extract_file.exe extract-files --regex "C:\Program Files (x86)\Grinding Gear Games\Path of Exile\Content.ggpk" . "^Data/\w+\.dat$"`
This should dump all the English .dat files