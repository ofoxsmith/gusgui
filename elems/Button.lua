local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local Button = class(GuiElement, function(o, config)
    GuiElement.init(o, config, {{
        name = "onClick",
        validate = function(o)
            if o == nil then
                return false, nil, "GUSGUI: Invalid value for onClick on element \"%s\" (onClick is required)"
            end
            if type(o) == "function" then
                return true, nil, nil
            end
            return false, nil, "GUSGUI: Invalid value for onClick on element \"%s\""
        end
    }, {
        name = "text",
        validate = function(o)
            if o == nil then
                return false, nil, "GUSGUI: Invalid value for text on element \"%s\" (text is required)"
            end
            if type(o) == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if type(o) == "string" then
                return true, nil, nil
            end
            return false, nil, "GUSGUI: Invalid value for text on element \"%s\""
        end
    }})
    o.allowsChildren = false
    o.type = "Button"
end)

function Button:GetBaseElementSize()
    return GuiGetTextDimensions(self.gui.guiobj, self:Interp(self._config.text))
end

function Button:Draw(x, y)
    self.maskID = self.maskID or self.gui.nextID()
    self.buttonID = self.buttonID or self.gui.nextID()
    local parsedText = self:Interp(self._config.text)
    local elementSize = self:GetElementSize()
    local c = self._config.colour
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.buttonID, x, y, elementSize.paddingW,
    elementSize.paddingH, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if clicked then
        self._config.onClick(self, self.gui.state)
        GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", self.gui.screenWorldX, self.gui.screenWorldY)
    end
    if hovered then
        GuiZSetForNextWidget(self.gui.guiobj, self.z + 3)
        if self._config.onHover then
            self._config.onHover(self, self.gui.state)
        end
        GuiImage(self.gui.guiobj, self.maskID, x, y, "data/debug/whitebox.png", 0,
            (elementSize.paddingW) / 20, (elementSize.paddingH) / 20)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    if self._config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiText(self.gui.guiobj, x + elementSize.offsetX + self._config.padding.left,
        y + elementSize.offsetY + self._config.padding.top, parsedText)
    if hovered then
        self.useHoverConfigForNextFrame = true
    else
        self.useHoverConfigForNextFrame = false
    end

end

return Button
