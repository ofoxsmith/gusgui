local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local Button = class(GuiElement, function(o, config)
    GuiElement.init(o, config)
    o.allowsChildren = false
    o.type = "Button"
    if config.onClick == nil then
        error("GUI: Invalid construction of Button element (onClick paramater is required)", 2)
    end
    if config.text == nil then
        error("GUI: Invalid construction of Button element (text paramater is required)", 2)
    end
    o.onClick = config.onClick
    o.text = config.text
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
    return GuiGetTextDimensions(self.gui.guiobj, self:Interp(self.text))
end

function Button:Draw()
    self.maskID = self.maskID or self.gui.nextID()
    self.buttonID = self.buttonID or self.gui.nextID()
    self.z = self:GetDepthInTree() * -100
    local parsedText = self:Interp(self.text)
    local elementSize = self:GetElementSize()
    local paddingLeft = self.config.padding.left
    local paddingTop = self.config.padding.top
    local x = self.config.margin.left
    local y = self.config.margin.top
    local c = self.config.colour
    local border = (self.config.drawBorder and 1 or 0)
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    if border > 0 then
        self:RenderBorder(x, y, elementSize.baseW, elementSize.baseH)
    end
    if self.config.drawBackground then 
        self:RenderBackground(x, y, elementSize.baseW, elementSize.baseH)
    end
    -- Draw an invisible image to act as the button
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.buttonID, x + border, y + border, elementSize.width - border - border, elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if clicked then
        self.onClick(self)
    end
    if hovered then 
        GuiZSetForNextWidget(self.gui.guiobj, self.z - 3)
        if self.config.onHover then self.config.onHover(self) end
        GuiImage(self.gui.guiobj, self.maskID, x + border, y + border, "data/debug/whitebox.png", 0, (elementSize.width - border - border) / 20, (elementSize.height - border - border) / 20)    
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    if self.config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiText(self.gui.guiobj, x + elementSize.offsetX + border + paddingLeft, y + elementSize.offsetY + border + paddingTop, parsedText)
end

return Button