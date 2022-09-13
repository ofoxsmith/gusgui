dofile("utils.lua")
-- Gui element parent table that is inherited by all elements
-- All elements define a GetBaseElementSize method, which gets the raw size of the gui element without margins, borders and etc using the Gui API functions
-- and a Draw method, which draws the element using the Gui API
local GuiElement = {};
local baseElementConfig = {
    drawBorder = false,
    borderSize = 1,
    colour = {255, 255, 255},
    margin = {
        top = 0,
        right = 0,
        bottom = 0,
        left = 0
    },
    padding = {
        top = 0,
        right = 0,
        bottom = 0,
        left = 0
    },
}

function GuiElement:AddChild(child)
    if child == nil then return error("bad argument #1 to AddChild (GuiElement object expected, got invalid value)", 2) end 
    child.parent = self
    table.insert(self.children, child)
end

function GuiElement:RemoveChild(childname)
    if child == nil then return error("bad argument #1 to RemoveChild (string expected, got no value)", 2) end 
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

function GuiElement:New(gui)
    local Element = {}
    Element.__metatable = "";
    Element.gui = gui
    Element.z = getDepthInTree() * 10;
    Element._rawconfig = {};
    Element.config = {};
    setmetatable(Element.config, {
        __index = function(t, k) return self._rawconfig[k] end,
        __newindex = function(t, k, v)
            
        end
    })
    Element.children = {};
    Element.parent = {};
    Element.rootNode = false;
    setmetatable(Element, self)
    self.__index = self
    return Element
end
return GuiElement
