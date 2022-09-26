local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local TabContainer = class(GuiElement, function(o, config)
    GuiElement.init(o, config)
    o.type = "TabContainer"
    o.allowsChildren = true
    o.childrenResolved = false
    if (config.children == nil or config.children == {}) then 
        error(string.format("GUI: TabContainer \"%s\" must have at least one child", o.id))
    end
    config.children = config.children
    for _, v in ipairs(config.children) do
        if v.name == nil then
            error("GUI: Children of TabContainer must have a name", 2)
        end
    end
    o._rawchildren = config.children
end)

function TabContainer:GetBaseElementSize()
    local totalW = 0
    local totalH = 0
    for i = 1, #self.children do
        local child = self.children[i]
        local size = child:GetElementSize()
        local w =
            math.max(size.width + child.config.margin.left + child.config.margin.right, child.config.overrideWidth)
        local h = math.max(size.height + child.config.margin.top + child.config.margin.bottom,
            child.config.overrideHeight)
        totalW = math.max(totalW, w)
        totalH = math.max(totalH, h)
    end
    return totalW, (totalH + 10)
end

function TabContainer:GetManagedXY(elem)
    return self.baseX + elem.config.margin.left,
        self.baseY + elem.config.margin.top
end

function TabContainer:Draw()
    self.currentTab = self.currentTab or self.children[1].name
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

end

return TabContainer
