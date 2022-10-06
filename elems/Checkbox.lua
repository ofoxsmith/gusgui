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
end)

function Checkbox:GetBaseElementSize()
    self.value = self.value or self._config.defaultValue
    if self._config.style == "text" then
        local t = "[" .. (self.value and "*" or " ") .. "]"
        local w, h = GuiGetTextDimensions(self.gui.guiobj, t)
        return w, h
    else
        return 9, 9
    end
end

function Checkbox:Draw()
    if self._config.hidden then
        return
    end
    self.value = self.value or self._config.defaultValue
    self.maskID = self.maskID or self.gui.nextID()
    self.imageID = self.imageID or self.gui.nextID()
    self.z = self:GetDepthInTree() * -100
    local elementSize = self:GetElementSize()
    local paddingLeft = self._config.padding.left
    local paddingTop = self._config.padding.top
    local x = self._config.margin.left
    local y = self._config.margin.top
    local c = self._config.colour
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    local border = (self._config.drawBorder and 1 or 0)
    if border > 0 then
        self:RenderBorder(x, y, elementSize.baseW, elementSize.baseH)
    end
    if self._config.drawBackground then
        self:RenderBackground(x, y, elementSize.baseW, elementSize.baseH)
    end
    if self._config.style == "text" then
        GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
        GuiImageNinePiece(self.gui.guiobj, self.maskID, x + border, y + border, elementSize.width - border - border,
            elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
        local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
        if clicked then
            local posX, posY = EntityGetTransform(EntityGetWithTag("player_unit")[1])
            GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", posX, posY)
            self.value = not self.value
            self._config.onToggle(self)
        end    
        if hovered then
            if self._config.onHover then
                self._config.onHover(self)
            end
            GuiZSetForNextWidget(self.gui.guiobj, self.z - 3)
            GuiImage(self.gui.guiobj, self.hoverMaskID, x + border, y + border, "data/debug/whitebox.png", 0,
                (elementSize.width - border - border) / 20, (elementSize.height - border - border) / 20)
        end
        GuiZSetForNextWidget(self.gui.guiobj, self.z)
        if self._config.colour then
            GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
        end
        GuiText(self.gui.guiobj, x + elementSize.offsetX + border + paddingLeft,
            y + elementSize.offsetY + border + paddingTop, "[" .. (self.value and "*" or " ") .. "]")
        if hovered then
            self.useHoverConfigForNextFrame = true
        else
            self.useHoverConfigForNextFrame = false
        end
    else
        GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
        GuiImageNinePiece(self.gui.guiobj, self.maskID, x + border, y + border, elementSize.width - border - border,
            elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
        local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
        if clicked then
            local posX, posY = EntityGetTransform(EntityGetWithTag("player_unit")[1])
            GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", posX, posY)
            self.value = not self.value
            self._config.onToggle(self)
        end
        if hovered then
            if self._config.onHover then
                self._config.onHover(self)
            end
        end
        GuiZSetForNextWidget(self.gui.guiobj, self.z)
        local path = nil
        if self.value then 
            path = "GUSGUI_PATHcheckbox_t.png"
        else 
            path = "GUSGUI_PATHcheckbox_f.png"
        end
        GuiImage(self.gui.guiobj, self.imageID, x + elementSize.offsetX + border + paddingLeft,
            y + elementSize.offsetY + border + paddingTop, path, 1, 1, 1)
        if hovered then
            self.useHoverConfigForNextFrame = true
        else
            self.useHoverConfigForNextFrame = false
        end
    end
end

return Checkbox
