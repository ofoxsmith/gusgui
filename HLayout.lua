local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local HLayout = class(GuiElement, function(o, config)
    GuiElement.init(o, config)
    o.type = "HLayout"
    o.allowsChildren = true
    o.childrenResolved = false
    o._rawchildren = config.children or {}
end)

function HLayout:GetBaseElementSize()
    local totalW = 0
    local totalH = 0
    local c = self.type ~= "HLayoutForEach" and self.children or self._
    for i = 1, #c do
        local child = c[i]
        local size = child:GetElementSize()
        local w = math.max(size.width + child._config.margin.left + child._config.margin.right, child._config.overrideWidth)
        local h = math.max(size.height + child._config.margin.top + child._config.margin.bottom, child._config.overrideHeight)
        totalW = totalW + w
        totalH = totalH > size.height and totalH or h
    end
    return totalW, totalH
end

function HLayout:GetManagedXY(elem)
    self.nextX = self.nextX or self.baseX + self._config.padding.left + (self._config.drawBorder and 2 or 0)
    self.nextY = self.nextY or self.baseY + self._config.padding.top + (self._config.drawBorder and 2 or 0)
    local elemsize = elem:GetElementSize()
    local x = self.nextX + elem._config.margin.left
    local y = self.nextY + elem._config.margin.top
    self.nextX = self.nextX + elemsize.width + elem._config.margin.left + elem._config.margin.right
    return x, y
end

function HLayout:Draw()
    if self._config.hidden then return end
    self.nextX = nil
    self.nextY = nil
    local elementSize = self:GetElementSize()
    local border = (self._config.drawBorder and 1 or 0)
    self.z = self:GetDepthInTree() * -100
    local x = self._config.margin.left
    local y = self._config.margin.top
    local size = self:GetElementSize()
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    self.baseX = x
    self.baseY = y
    if self._config.drawBorder then
        self:RenderBorder(x, y, size.baseW, size.baseH)
    end
    if self._config.drawBackground then 
        self:RenderBackground(x, y, size.baseW, size.baseH)
    end
    self.maskID = self.maskID or self.gui.nextID()
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x + border, y + border, elementSize.width - border - border, elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if hovered and self._config.onHover then self._config.onHover(self) end
    local c = self.type ~= "HLayoutForEach" and self.children or self._
    for i = 1, #c do
        c[i]:Draw()
    end
end

return HLayout
