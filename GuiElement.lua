-- Gui element metatable
local GuiElement = {};
function GuiElement:New()
    local o = {}
    setmetatable(o, self)
    self.__index = self
end
return GuiElement
