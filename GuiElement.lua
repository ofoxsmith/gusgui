-- Gui element parent class
-- inherited by all elements 
local GuiElement = {};
GuiElement._z = 0;
GuiElement.style = {}
GuiElement.children = {}
GuiElement.parent = {}
function GuiElement:AddChild(child)
    child.parent = self
    table.insert(self.children, child)
end

function GuiElement:GetZ()
    local at = self
    local z = 0
    while true do
        z = z - 1000
        if at.parent == nil then return z end
        at = at.parent
    end 
end 
function GuiElement:New()
    local o = {}
    setmetatable(o, self)
    self.__index = self
end
return GuiElement
