-- Gui element parent class
-- inherited by all elements
dofile("utils.lua")
local GuiElement = {};

function GuiElement:AddChild(child)
    child.parent = self
    table.insert(self.children, child)
end

function GuiElement:RemoveChild(childname)
    for i, v in ipairs(self.children) do 
        if (v.name == childname) then 
            table.remove(self.children, i);
            break;
        end 
    end
end

function GuiElement:Remove()
    for i, v in ipairs(self.parent.children) do 
        if (v.name == self.name) then 
            table.remove(self.parent.children, i);
            break;
        end 
    end
end

function GuiElement:New()
    local Element = {}
    Element.__metatable = ""
    Element._z = getDepthInTree() * 10;
    Element._rawstyle = {};
    Element.style = {};
    Element.children = {};
    Element.parent = {};
    Element.rootNode = false;
    setmetatable(Element, self)
    self.__index = self
    return Element
end
return GuiElement
