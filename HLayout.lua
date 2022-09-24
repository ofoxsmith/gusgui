local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local HLayout = class(GuiElement, function(o, id, align, config)
    GuiElement.init(o, id, config)
    o.type = "HLayout"
    o.align = align or 0
    o.height = 0
    o.width = 0
end)

function HLayout:GetBaseElementSize()
    local totalW = 0
    local totalH = 0
    for i = 1, #self.children do
        local child = self.children[i]
        local size = child:GetElementSize()
        size.width = math.max(size.width + child.config.margin.left + child.config.margin.right,
            child.config.overrideWidth or 0)
        size.height = math.max(size.height + child.config.margin.top + child.config.margin.bottom,
            child.config.overrideHeight or 0)
        totalW = totalW + size.width
        totalH = totalH > size.height and totalH or size.height
    end
    return totalW, totalH
end

function HLayout:GetManagedXY(elem)
    self.nextX = self.nextX or 0
    self.nextY = self.nextY or 0
    local x = self.nextX + self.config.padding.left
    local y = self.nextY + self.config.padding.top
    local h = elem:GetElementSize().height
    local setPos = (self.align * self.height) - h * self.align
    setPos = math.max(elem.config.margin.top, setPos)
    setPos = setPos - math.max(0, elem.config.margin.bottom - (self.height - (setPos + h)))
    y = y + setPos
    x = x + elem.config.margin.left
    local s = elem:GetElementSize()
    return x, y, s
end

function HLayout:Draw()
    local x = self.config.margin.left
    local y = self.config.margin.top
    local elementSize = self:GetElementSize()
    if self.parent then
        x, y = self.parent:GetManagedXY()
    end
    self.width = elementSize.width
    self.height = elementSize.height
    self.nextX = x + elementSize.offsetX + (self.config.drawBorder and 1 or 0)
    self.nextY = y + elementSize.offsetY + (self.config.drawBorder and 1 or 0)
    for i = 1, #self.children do
        local child = self.children[i]
        local size = child:GetElementSize()
        child:Draw()
        self.nextX = self.nextX + math.max((child.config.overrideWidth or 0), size.width + child.config.margin.left + child.config.margin.right)
    end
end

return HLayout
