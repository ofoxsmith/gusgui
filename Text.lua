local ElementParent = dofile("GuiElement.lua")
dofile("class.lua")
local Text = class(ElementParent, function (o) 
    ElementParent.init(o)
end)

return Text