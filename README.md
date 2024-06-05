# **ARCHIVED**
Archived -  I would recommend using the inbuilt GUI functions, or the [ImGUI library](https://github.com/dextercd/Noita-Dear-ImGui) for unsafe mods. Feel free to copy some of the layouting code and logic for use with the inbuilt API, a lot of the logic is useful for using the standard gui functions.

## GUSGUI
A GUI framework for Noita, with properties and behaviors somewhat similar to HTML and CSS, and with rendering like the [CSS box model](https://www.geeksforgeeks.org/css-box-model/). GUSGUI was inspired by [EZGUI](https://github.com/TheHorscht/EZGUI), another similar GUI library that was not finished. 

### Installation
Download the [latest release](https://github.com/ofoxsmith/gusgui/releases), and extract it into your mod folder. 
Updating must be done manually by downloading the newest release.

```lua
local gusgui = dofile_once("mods/YOUR-MOD-ID/PATH-TO-GUSGUI/Gui.lua").gusgui("PATH-TO-GUSGUI")
local Gui = gusgui.Create()
```

### Documentation

Documentation is on the [Github wiki](https://github.com/ofoxsmith/gusgui/wiki).
