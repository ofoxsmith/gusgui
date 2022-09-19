local GuiElement = dofile_once("[[GUSGUI_PATH]]GuiElement.lua")
dofile_once("[[GUSGUI_PATH]]class.lua")

local HLayout = class(GuiElement, function(o, id, align, config)
    GuiElement.init(o, id, config)
    o.type = "HLayout"
    o.align = align or 0
end)

function HLayout:GetBaseElementSize()
    local totalW = 0
    local totalH = 0
    for i = 1, #self.children do local child = self.children[i]
        local size = child:GetElementSize()
        size.width = math.max(size.width + child.config.margin.left + child.config.margin.right, child.config.overrideWidth or 0)
        size.height = math.max(size.height + child.config.margin.top + child.config.margin.bottom, child.config.overrideHeight or 0)
        totalW = totalW + size.width
        totalH = totalH > size.height and totalH or size.height 
    end
    return totalW, totalH
end

function HLayout:GetManagedXY()

end

function HLayout:Draw()
    
end

return HLayout