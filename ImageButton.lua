local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local ImageButton = class(GuiElement, function(o, config)
    GuiElement.init(o, config)
    o.type = "ImageButton"
    o.scaleX = config.scaleX or 1
    o.scaleY = config.scaleY or 1 
    if config.path == nil then
        error("GUI: Invalid construction of ImageButton element (path paramater is required)", 2)
    end
    if config.onClick == nil then
        error("GUI: Invalid construction of ImageButton element (onClick paramater is required)", 2)
    end
    o.path = config.path
    o.onClick = config.onClick
end)

function ImageButton:GetBaseElementSize()
    local w, h = GuiGetImageDimensions(self.gui.guiobj, self:ResolveValue(self.path))
    return w * self.scaleX, h * self.scaleY  
end

function ImageButton:Draw()
    self.z = self:GetDepthInTree() * -100
    local elementSize = self:GetElementSize()
    local paddingLeft = self:ResolveValue(self.config.padding.left)
    local paddingTop = self:ResolveValue(self.config.padding.top)
    local x = self:ResolveValue(self.config.margin.left)
    local y = self:ResolveValue(self.config.margin.top)
    local c = self:ResolveValue(self.config.colour)
    local border = (self:ResolveValue(self.config.drawBorder) and 1 or 0)
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    if border > 0 then
        self:RenderBorder(x, y, elementSize.baseW, elementSize.baseH)
    end
    if self:ResolveValue(self.config.drawBackground) then 
        self:RenderBackground(x, y, elementSize.baseW, elementSize.baseH)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.gui.nextID(), x + border, y + border, elementSize.width - border - border, elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if clicked then
        self.onClick(self)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    if self.config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiImage(self.gui.guiobj, self.gui.nextID(), x + elementSize.offsetX + paddingLeft + border, y + elementSize.offsetY + paddingTop + border, self.path, 1, self.scaleX, self.scaleY)
end

return ImageButton