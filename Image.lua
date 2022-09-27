local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local Image = class(GuiElement, function(o, config)
    GuiElement.init(o, config)
    o.type = "Image"
    o.allowsChildren = false
    o.scaleX = config.scaleX or 1
    o.scaleY = config.scaleY or 1 
    if config.path == nil then
        error("GUI: Invalid construction of Image element (path paramater is required)", 2)
    end
    o.path = config.path
end)

function Image:GetBaseElementSize()
    local w, h = GuiGetImageDimensions(self.gui.guiobj, self.path)
    return w * self.scaleX, h * self.scaleY  
end

function Image:Draw()
    self.imageID = self.imageID or self.gui.nextID()
    self.maskID = self.maskID or self.gui.nextID()
    self.z = self:GetDepthInTree() * -100
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
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x + border, y + border, elementSize.width - border - border, elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if hovered and self.config.onHover then self.config.onHover(self) end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    if self.config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiImage(self.gui.guiobj, self.imageID, x + elementSize.offsetX + paddingLeft + border, y + elementSize.offsetY + paddingTop + border, self.path, 1, self.scaleX, self.scaleY)
end

return Image