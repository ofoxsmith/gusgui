local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local Button = class(GuiElement, function(o, config)
    GuiElement.init(o, config, {{
        name = "onClick",
        validate = function(o)
            if o == nil then
                return false, nil, "GUI: Invalid value for onClick on element \"%s\" (onClick is required)"
            end
            if type(o) == "function" then
                return true, nil, nil
            end
            return false, nil, "GUI: Invalid value for onHover on element \"%s\""
        end
    }, {
        name = "text",
        validate = function(o)
            if o == nil then
                return false, nil, "GUI: Invalid value for text on element \"%s\" (text is required)"
            end
            if type(o) == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if type(o) == "string" then
                return true, nil, nil
            end
            return false, nil, "GUI: Invalid value for text on element \"%s\""
        end
    }})
    o.allowsChildren = false
    o.type = "Button"
end)

function Button:Interp(s)
    if (type(s) ~= "string") then
        return error("bad argument #1 to Interp (string expected, got " .. type(s) .. ")", 2)
    end
    return (s:gsub('($%b{})', function(w)
        w = string.sub(w, 3, -2)
        return self.gui:GetState(w)
    end))
end

function Button:GetBaseElementSize()
    return GuiGetTextDimensions(self.gui.guiobj, self:Interp(self._config.text))
end

function Button:Draw()
    if self._config.hidden then
        return
    end
    self.maskID = self.maskID or self.gui.nextID()
    self.buttonID = self.buttonID or self.gui.nextID()
    self.z = self:GetDepthInTree() * -100
    local parsedText = self:Interp(self._config.text)
    local elementSize = self:GetElementSize()
    local paddingLeft = self._config.padding.left
    local paddingTop = self._config.padding.top
    local x = self._config.margin.left
    local y = self._config.margin.top
    local c = self._config.colour
    local border = (self._config.drawBorder and 1 or 0)
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    if border > 0 then
        self:RenderBorder(x, y, elementSize.baseW, elementSize.baseH)
    end
    if self._config.drawBackground then
        self:RenderBackground(x, y, elementSize.baseW, elementSize.baseH)
    end
    -- Draw an invisible image to act as the button
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.buttonID, x + border, y + border, elementSize.width - border - border,
        elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if clicked then
        self._config.onClick(self)
    end
    if hovered then
        GuiZSetForNextWidget(self.gui.guiobj, self.z - 3)
        if self._config.onHover then
            self._config.onHover(self)
        end
        GuiImage(self.gui.guiobj, self.maskID, x + border, y + border, "data/debug/whitebox.png", 0,
            (elementSize.width - border - border) / 20, (elementSize.height - border - border) / 20)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    if self._config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiText(self.gui.guiobj, x + elementSize.offsetX + border + paddingLeft,
        y + elementSize.offsetY + border + paddingTop, parsedText)
end

return Button
