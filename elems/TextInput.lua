local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")
local TextInput = class(GuiElement, function(o, config)
    GuiElement.init(o, config, {{
        name = "maxLength",
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then
                return true, 50, nil
            end
            local t = type(o)
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "number" then
                return true, nil, nil
            end
        end
    }, {
        name = "width",
        fromString = function(o)
            return tonumber(o)
        end,
        validate = function(o)
            if o == nil then
                return true, 25, nil
            end
            local t = type(o)
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "number" then
                return true, nil, nil
            end
        end
    }, {
        name = "onEdit",
        canHover = false,
        validate = function(o)
            if o == nil then
                return false, nil, "GUI: Invalid value for TextInput element \"%s\" (onEdit paramater is required)"
            end
            if type(o) == "function" then
                return true, nil, nil
            end
            return false, nil, "GUI: Invalid value for onEdit on element \"%s\""
        end
    }})
    o.type = "TextInput"
    o.allowsChildren = false
end)

function TextInput:GetBaseElementSize()
    return math.max(25, self._config.width), 10
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
            self._config.onHover(self)
        end
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    local n = GuiTextInput(self.gui.guiobj, self.inputID, x + elementSize.offsetX + self._config.padding.left,
        y + elementSize.offsetY + self._config.padding.top, self.value, self._config.width,
        self._config.maxLength, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
    if self.value ~= n then
        self.value = n
        self.onEdit(self)
    end
    if hovered then self.useHoverConfigForNextFrame = true 
    else self.useHoverConfigForNextFrame = false end
end

return TextInput
