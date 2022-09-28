local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local HLayout = class(GuiElement, function(o, config)
    GuiElement.init(o, config)
    o.type = "HLayout"
    o.allowsChildren = true
    o.childrenResolved = false
    o._rawchildren = config.children or {}
    o.align = config.align or 0
end)

function HLayout:GetBaseElementSize()
    local totalW = 0
    local totalH = 0
    for i = 1, #self.children do
        local child = self.children[i]
        local size = child:GetElementSize()
        local w = math.max(size.width + child.config.margin.left + child.config.margin.right, child.config.overrideWidth)
        local h = math.max(size.height + child.config.margin.top + child.config.margin.bottom, child.config.overrideHeight)
        totalW = totalW + w
        totalH = totalH > size.height and totalH or h
    end
    return totalW, totalH
end

function HLayout:GetManagedXY(elem)
    self.nextX = self.nextX or self.baseX + self.config.padding.left + (self.config.drawBorder and 2 or 0)
    self.nextY = self.nextY or self.baseY + self.config.padding.top + (self.config.drawBorder and 2 or 0)
    local elemsize = elem:GetElementSize()
    local x = self.nextX + elem.config.margin.left
    local y = self.nextY + elem.config.margin.top
    self.nextX = self.nextX + elemsize.width + elem.config.margin.left + elem.config.margin.right
    return x, y
end

function HLayout:Draw()
    self.nextX = nil
    self.nextY = nil
    local elementSize = self:GetElementSize()
    local border = (self.config.drawBorder and 1 or 0)
    self.z = self:GetDepthInTree() * -100
    local x = self.config.margin.left
    local y = self.config.margin.top
    local size = self:GetElementSize()
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    self.baseX = x
    self.baseY = y
    if self.config.drawBorder then
        self:RenderBorder(x, y, size.baseW, size.baseH)
    end
    if self.config.drawBackground then 
        self:RenderBackground(x, y, size.baseW, size.baseH)
    end
    self.maskID = self.maskID or self.gui.nextID()
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x + border, y + border, elementSize.width - border - border, elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if hovered and self.config.onHover then self.config.onHover(self) end
    for i = 1, #self.children do
        self.children[i]:Draw()
    end
end

return HLayout
