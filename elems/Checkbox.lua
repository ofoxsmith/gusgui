local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local Checkbox = class(GuiElement, function(o, config)
    GuiElement.init(o, config, {{
        name = "defaultValue",
        validate = function(o)
            if o == nil then
                return false, nil, "GUI: Invalid value for defaultValue on element \"%s\" (defaultValue is required)"
            end
            if type(o) == "boolean" then
                return true, nil, nil
            end
            return false, nil, "GUI: Invalid value for defaultValue on element \"%s\""
        end
    }, {
        name = "onToggle",
        validate = function(o)
            if o == nil then
                return false, nil, "GUI: Invalid value for onToggle on element \"%s\" (onToggle is required)"
            end
            if type(o) == "function" then
                return true, nil, nil
            end
            return false, nil, "GUI: Invalid value for onToggle on element \"%s\""
        end
    }, {
        name = "style",
        validate = function(o)
            if o == nil then
                return true, "image", nil
            end
            if type(o) == "string" and o == "image" or o == "text" then
                return true, nil, nil
            end
            return false, nil, "GUI: Invalid value for style on element \"%s\""
        end
    }})
    o._rawconfig.hover = o._rawconfig.hover or {}
    o._rawconfig.hover.colour = o._rawconfig.hover.colour or {240,230,140}
    o.type = "Checkbox"
    o.allowsChildren = false
    o.value = o._config.defaultValue
end)

function Checkbox:GetBaseElementSize()
    if self._config.style == "text" then
        local t = "[" .. (self.value and "*" or " ") .. "]"
        local w, h = GuiGetTextDimensions(self.gui.guiobj, t)
        return w, h
    else
        return 9, 9
    end
end

function Checkbox:Draw(x, y)
    self.maskID = self.maskID or self.gui.nextID()
    self.imageID = self.imageID or self.gui.nextID()
    local elementSize = self:GetElementSize()
    local c = self._config.colour
    if self._config.style == "text" then
        GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
        GuiImageNinePiece(self.gui.guiobj, self.maskID, x, y, elementSize.paddingW,
        elementSize.paddingH, 0, "data/ui_gfx/decorations/9piece0_gray.png")
        local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
        if clicked then
            GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", self.gui.screenWorldX, self.gui.screenWorldY)
            self.value = not self.value
            self._config.onToggle(self, self.gui.state)
        end    
        if hovered then
            GuiZSetForNextWidget(self.gui.guiobj, self.z + 3)
            GuiImage(self.gui.guiobj, self.hoverMaskID, x, y, "data/debug/whitebox.png", 0,
                (elementSize.paddingW) / 20, (elementSize.paddingH) / 20)    
            if self._config.onHover then
                self._config.onHover(self, self.gui.state)
            end
        end
        GuiZSetForNextWidget(self.gui.guiobj, self.z)
        if self._config.colour then
            GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
        end
        GuiText(self.gui.guiobj, x + elementSize.offsetX + self._config.padding.left,
            y + elementSize.offsetY + self._config.padding.top, "[" .. (self.value and "*" or " ") .. "]")
        if hovered then
            self.useHoverConfigForNextFrame = true
        else
            self.useHoverConfigForNextFrame = false
        end
    else
        GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
        GuiImageNinePiece(self.gui.guiobj, self.maskID, x, y, elementSize.paddingW,
        elementSize.paddingH, 0, "data/ui_gfx/decorations/9piece0_gray.png")
        local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
        if clicked then
            GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", self.gui.screenWorldX, self.gui.screenWorldY)
            self.value = not self.value
            self._config.onToggle(self, self.gui.state)
        end
        if hovered then
            if self._config.onHover then
                self._config.onHover(self, self.gui.state)
            end
        end
        GuiZSetForNextWidget(self.gui.guiobj, self.z)
        local path = nil
        if self.value == true then 
            path = "GUSGUI_PATHcheckbox_t.png"
        else 
            path = "GUSGUI_PATHcheckbox_f.png"
        end
        GuiImage(self.gui.guiobj, self.imageID, x + elementSize.offsetX + self._config.padding.left,
            y + elementSize.offsetY + self._config.padding.top, path, 1, 1, 1)
        if hovered then
            self.useHoverConfigForNextFrame = true
        else
            self.useHoverConfigForNextFrame = false
        end
    end
end

return Checkbox
