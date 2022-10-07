local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local VLayout = class(GuiElement, function(o, config)
    GuiElement.init(o, config)
    o.type = "VLayout"
    o.allowsChildren = true
    o.childrenResolved = false
    o._rawchildren = config.children or {}
end)

function VLayout:GetBaseElementSize()
    if self.type == "VLayoutForEach" then 
        self:CreateElements()
    end 
    local totalW = 0
    local totalH = 0
    for i = 1, #self.children do
        local child = self.children[i]
        local size = child:GetElementSize()
        local w = math.max(size.width + child._config.margin.left + child._config.margin.right)
        local h = math.max(size.height + child._config.margin.top + child._config.margin.bottom)
        totalW = math.max(totalW, w)
        totalH = totalH + h
    end
    return totalW, totalH
end

function VLayout:GetManagedXY(elem)
    local elemsize = elem:GetElementSize()
    local offsets = self:GetElementSize()
    self.nextX = self.nextX or (self.baseX + self._config.padding.left + offsets.offsetX)
    self.nextY = self.nextY or (self.baseY + self._config.padding.top + offsets.offsetY)
    local x = self.nextX + elem._config.margin.left
    local y = self.nextY + elem._config.margin.top
    self.nextY = self.nextY + elemsize.height + elem._config.margin.top + elem._config.margin.bottom
    if elem._config.drawBorder then 
        x = x + 2
        y = y + 2
    end
    return x, y
end

function VLayout:Draw(x, y)
    self.nextX = nil
    self.nextY = nil
    local size = self:GetElementSize()
    self.baseX = x
    self.baseY = y
    local elementSize = self:GetElementSize()
    self.maskID = self.maskID or self.gui.nextID()
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x, y, elementSize.paddingW,
    elementSize.paddingH, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    for i = 1, #self.children do
        self.children[i]:Render()
    end
    if hovered then
        if self._config.onHover then
            self._config.onHover(self, self.gui.state)
        end
        self.useHoverConfigForNextFrame = true
    else self.useHoverConfigForNextFrame = false end 
end

return VLayout
