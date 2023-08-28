# Changelog
## 1.0.0 - 2023-08-28
### Added
- Add xml2lua library to allow for GUIs to be written in XML files
    - Add ability to create GUIs based on an XML Tree
    - Add ability to configure GUIs with mock CSS
    - Add gusgui.CreateGUIFromXML(filename, funcs, guiOptions) function
- Add visible property and change how hidden property works
    - Setting visible to false makes a GUI element invisible, while still taking up the space it would normally render at on screen
    - Setting hidden to true makes a GUI element pretend it does not exist in the GUI tree
### Fixed
- Hover detection not working and triggering randomly
- Rendering callbacks being called on hidden elements
- Init function trying and failing to access a previously removed GUSGUI file
## 0.3.0 - 2023-03-01
### Added
- Changed the gui constructor to have more options:
- Added the ability to use a pre-existing gui object
- Added a basic logging function that shows possible problems in a gui
- Added the ability to specify the x and y that the gui begins rendering from
### Fixed
- Bug causing state values to always be nil
## 0.2.1/0.2.2 - 2023-02-28
### Fixed
- Text elements attempting to perform string interpolation on non-string values
## 0.2.0 - 2022-12-30
### Added
- Ability to style and edit config for GUI elements using CSS-based schema
### Fixed
- Invalid Regex patterns in multiple files.
## 0.1.1 - 2022-11-29
### Added
- Ability to split text in Text elements into multiple lines.
## Initial release 0.1.0 - 2022-10-24
### Added
- Button element.
- Checkbox element.
- Layout elements.
- LayoutForEach elements.
- Image element.
- ImageButton element.
- ProgressBar element.
- Checkbox element.
- Slider element.
- Text element.
- TextInput element.
- Gui class.
- GuiElement class (only used internally).
- Images and assets used for gui elements.
