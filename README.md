# GUSGUI
A GUI framework for Noita, with properties and behaviors somewhat similar to HTML and CSS, and with rendering like the [CSS box model](https://www.geeksforgeeks.org/css-box-model/). GUSGUI was inspired by [EZGUI](https://github.com/TheHorscht/EZGUI), another similar GUI library that was not finished. 

## Installation

### Using Git:

Add gusgui as a submodule, where INSTALL_PATH is where gusgui should be installed (e.g. lib/gusgui):
```console
git submodule add https://github.com/ofoxsmith/gusgui.git INSTALL_PATH
```
When cloning your mod's repo from Github, submodules do not automatically install. To install them, run: 
```console
git submodule init
git submodule update
```
To update gusgui to the latest version, run:
```console
git submodule update --remote --merge
```

At the top of `init.lua`, call the initialisation function:
```lua
dofile_once("mods/YOUR-MOD-ID/PATH-TO-GUSGUI/gusgui.lua").init("mods/YOUR-MOD-ID/PATH-TO-GUSGUI")
```

### Without Git:

Download the [latest release](https://github.com/ofoxsmith/gusgui/releases), and extract it into your mod folder. 
Updating must be done manually by downloading the newest release.

At the top of `init.lua`, call the initialisation function:
```lua
dofile_once("mods/YOUR-MOD-ID/PATH-TO-GUSGUI/gusgui.lua").init("mods/YOUR-MOD-ID/PATH-TO-GUSGUI")
```

## Documentation

Documentation is on the [Github wiki](https://github.com/ofoxsmith/gusgui/wiki).
