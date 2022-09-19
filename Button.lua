local GuiElement = dofile_once("[[GUSGUI_PATH]]GuiElement.lua")
dofile_once("[[GUSGUI_PATH]]class.lua")

local Button = class(GuiElement, function(o, id, text, onClick, config)
    GuiElement.init(o, id, config)
    o.type = "Button"
    if onClick == nil then
        error("GUI: Invalid construction of Button element (onClick paramater is required)", 2)
    end
    if text == nil then
        error("GUI: Invalid construction of Button element (text paramater is required)", 2)
    end
    o.onClick = onClick
    o.text = text
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
    local allLines = splitString(self.value, "\\n")
    local totalWidth = 0
    local totalHeight = 0
    for i, v in ipairs(allLines) do
        local w, h = GuiGetTextDimensions(self.gui.guiobj, v)
        totalHeight = totalHeight + h;
        totalWidth = (totalWidth > w and totalWidth or w)
    end
    return totalWidth, totalHeight
end

function Button:Draw()
    local parsedText = self:Interp(self:ResolveValue(self.value))
    local elementSize = self:GetElementSize()
    local paddingLeft = self:ResolveValue(self.config.padding.left)
    local paddingBottom = self:ResolveValue(self.config.padding.bottom)
    local paddingTop = self:ResolveValue(self.config.padding.top)
    local paddingBottom = self:ResolveValue(self.config.padding.bottom)
    local x = self:ResolveValue(self.config.margin.left)
    local y = self:ResolveValue(self.config.margin.top)
    local c = self:ResolveValue(self.config.colour)
    local z = getDepthInTree(self) * 10
    local border = (self:ResolveValue(self.config.drawBorder) and self:ResolveValue(self.config.borderSize) or 0)
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    GuiZSetForNextWidget(self.guiobj, z + 3)
    -- Draw an invisible image to act as the button
    GuiImageNinePiece(self.guiobj, self.gui.nextID(), x + border, y + border, elementSize.width - border - border,
        elementSize.height - border - border, 0)
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.guiobj)
    if clicked or right_clicked then
        self.onClick(self, right_clicked)
    end
    GuiZSetForNextWidget(self.gui.guiobj, z)
    if self.config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiText(self.gui.guiobj, x + elementSize.offsetX + border + paddingLeft, y + elementSize.offsetY + border + paddingTop, parsedText)

end

