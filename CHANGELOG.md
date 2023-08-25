# Changelog
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
