local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local VLayout = class(GuiElement, function(o, config)
    GuiElement.init(o, config)
    o.type = "VLayout"
    o.allowsChildren = true
    o.childrenResolved = false
    o._rawchildren = config.children or {}
    o.align = config.align or 0
end)

function VLayout:GetBaseElementSize()
    local totalW = 0
    local totalH = 0
    for i = 1, #self.children do
        local child = self.children[i]
        local size = child:GetElementSize()
        local w = math.max(size.width + child.config.margin.left + child.config.margin.right, child.config.overrideWidth)
        local h = math.max(size.height + child.config.margin.top + child.config.margin.bottom, child.config.overrideHeight)
        totalW = math.max(totalW, w)
        totalH = totalH + h
    end
    return totalW, totalH
end

function VLayout:GetManagedXY(elem)
    self.nextX = self.nextX or self.baseX + self.config.padding.left + (self.config.drawBorder and 2 or 0)
    self.nextY = self.nextY or self.baseY + self.config.padding.top + (self.config.drawBorder and 2 or 0)
    local elemsize = elem:GetElementSize()
    local x = self.nextX + elem.config.margin.left
    local y = self.nextY + elem.config.margin.top
    self.nextY = self.nextY + elemsize.height + elem.config.margin.top + elem.config.margin.bottom
    return x, y
end

function VLayout:Draw()
    self.nextX = nil
    self.nextY = nil
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
    for i = 1, #self.children do
        self.children[i]:Draw()
    end
end

return VLayout
