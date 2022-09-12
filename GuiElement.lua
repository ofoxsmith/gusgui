-- Gui element parent class
-- inherited by all elements 
local GuiElement = {};

function GuiElement:AddChild(child)
    child.parent = self
    table.insert(self.children, child)
end

function GuiElement:GetZ()
    return getDepthInTree() * 100
end 
function GuiElement:New()
    local Element = {}
    Element._z = 0;
    Element.style = {};
    Element.children = {};
    Element.parent = {};
    Element.rootNode = false;
    setmetatable(Element, self)
    self.__index = self
    return Element
end
return GuiElement
