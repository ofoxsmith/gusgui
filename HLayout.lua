local GuiElement = dofile_once("[[GUSGUI_PATH]]GuiElement.lua")
dofile_once("[[GUSGUI_PATH]]class.lua")

local HLayout = class(GuiElement, function(o, id, align, config)
    GuiElement.init(o, id, config)
    o.type = "HLayout"
    o.align = align or 0
end)

function HLayout:GetBaseElementSize()
    
end

function HLayout:GetManagedXY()

end

function HLayout:Draw()
    
end

return HLayout