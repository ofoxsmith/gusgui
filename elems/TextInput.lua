--- @module "GuiElement"
local GuiElement = dofile_once(GUSGUI_FILEPATH("GuiElement.lua"))
dofile_once(GUSGUI_FILEPATH("class.lua"))
--- @class TextInput: GuiElement
--- @field hoverMaskID number
--- @field maskID number
--- @field inputID number
--- @operator call: TextInput
local TextInput = class(GuiElement, function(o, config)
    config = config or {}
    config._type = "TextInput"
    GuiElement.init(o, config)
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

return TextInput