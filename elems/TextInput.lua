--- @module "GuiElement"
local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")
local TextInputConf = {maxLength = {
    default = 50,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            return o
        end
    end
}, width = {
    default = 25,
    fromString = function(o)
        return tonumber(o)
    end,
    validate = function(o)
        if type(o) == "number" then
            return o
        end
    end
}, onEdit = {
    required = true,
    fromString = function (s, funcs)
        if funcs[s] then return funcs[s] end
        error("GUSGUI: Unknown function name" .. s)
        end,
    canHover = false,
    validate = function(o)
        if type(o) == "function" then
            return o
        end
        return nil, "Invalid value for onEdit on element \"%s\""
    end
}}
--- @class TextInput: GuiElement
--- @field hoverMaskID number
--- @field maskID number
--- @field inputID number
--- @operator call: TextInput
local TextInput = class(GuiElement, function(o, config)
    config = config or {}
    GuiElement.init(o, config, TextInputConf)
    o.type = "TextInput"
    o.allowsChildren = false
end)

function TextInput:GetBaseElementSize()
    return math.max(25, self._config.width), 11
end
function TextInput:Draw(x, y)
    self.value = self.value or " "
    self.inputID = self.inputID or self.gui.nextID()
    self.hoverMaskID = self.hoverMaskID self.gui.nextID()
    self.maskID = self.maskID or self.gui.nextID()
    local elementSize = self:GetElementSize()
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x, y, elementSize.paddingW,
    elementSize.paddingH, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if hovered then
        if self._config.onHover then
            self._config.onHover(self, self.gui.state)
        end
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    local n = GuiTextInput(self.gui.guiobj, self.inputID, x + elementSize.offsetX + self._config.padding.left,
        y + elementSize.offsetY + self._config.padding.top, self.value, self._config.width,
        self._config.maxLength, " 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
    if self.value ~= n then
        self.value = n
        self._config.onEdit(self, self.gui.state)
    end
    if hovered then self.useHoverConfigForNextFrame = true 
    else self.useHoverConfigForNextFrame = false end
end

TextInput.extConf = TextInputConf
return TextInput