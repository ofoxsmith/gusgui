# GUSGUI
A GUI framework for Noita, with properties and behaviors somewhat similar to HTML and CSS, and with rendering like the [CSS box model](https://www.geeksforgeeks.org/css-box-model/). GUSGUI was inspired by [EZGUI](https://github.com/TheHorscht/EZGUI), another similar GUI library that was not finished. 

## Installation
Download the [latest release](https://github.com/ofoxsmith/gusgui/releases), and extract it into your mod folder. 
Updating must be done manually by downloading the newest release.

At the top of `init.lua`, call the initialisation function:
```lua
dofile_once("mods/YOUR-MOD-ID/PATH-TO-GUSGUI/gusgui.lua").init("mods/YOUR-MOD-ID/PATH-TO-GUSGUI")

local gusgui = dofile_once("mods/YOUR-MOD-ID/PATH-TO-GUSGUI/Gui.lua")
local Gui = gusgui.Create()
```

## Documentation

Documentation is on the [Github wiki](https://github.com/ofoxsmith/gusgui/wiki).
