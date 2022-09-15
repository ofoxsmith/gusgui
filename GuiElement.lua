dofile("class.lua")
-- Gui element parent class that is inherited by all elements
-- All elements define a GetBaseElementSize method, which gets the raw size of the gui element without margins, borders and etc using the Gui API functions
-- Elements that manage other child elements implement a GetManagedXY function, which allows children to get x, y relative to parent position and config
-- and a Draw method, which draws the element using the Gui API
local baseElementConfig = {
    drawBorder = false,
    overrideWidth = false,
    overrideHeight = false,
    -- number between 0 and 1, with 0 being top, 0.5 being centre and 1 being bottom
    verticalAlign = 0,
    -- number between 0 and 1, with 0 being left, 0.5 being centre and 1 being right
    horizontalAlign = 0,
    borderSize = 1,
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
    }
}

local GuiElement = class(function(Element, id, config)
    Element.gui = nil
    Element.allowChildren = false
    if id == nil then error("GUI: Invalid construction of element (id is required)") end
    Element.id = id
    Element._rawconfig = {}
    Element.config = config or baseElementConfig
    setmetatable(Element.config, {
        __index = function(t, k)
            return self._rawconfig[k]
        end,
        __newindex = function(t, k, v)

        end
    })
    Element.children = {}
    Element.parent = {}
    Element.rootNode = false
end)


function GuiElement:ResolveValue(a) 
    if type(a) ~= "table" then return a end
    if a._type ~= "state" or type(a.value) ~= "string" then return a end 
    return self.gui.GetState(a)
end 

local function getDepthInTree(node) 
    local at = node
    local d = 0
    while true do
        d = d + 1
        if (at.parent == nil) then return d end
        at = at.parent
    end
end

function GuiElement:AddChild(child)
    if not self.allowChildren then error("GUI: " .. self.type .. " cannot have child element") end
    if child == nil then
        error("bad argument #1 to AddChild (GuiElement object expected, got invalid value)", 2)
    end
    child.parent = self
    table.insert(self.children, child)
end

function GuiElement:RemoveChild(childName)
    if child == nil then
        error("bad argument #1 to RemoveChild (string expected, got no value)", 2)
    end
    for i, v in ipairs(self.children) do
        if (v.name == childName) then
            table.remove(self.children, i)
            break
        end
    end
end

-- Get the element size with padding and border included (no margins)
function GuiElement:GetElementSize()
    local baseW, baseH = self:GetBaseElementSize()
    local borderSize = 0
    if self.config.drawBorder then
        borderSize = self.config.borderSize * 2
    end
    local width = baseW + self.config.padding.left + self.config.padding.right + borderSize
    local height = baseH + self.config.padding.top + self.config.padding.bottom + borderSize
    return {
        baseW = baseW,
        baseH = baseH,
        width = width,
        height = height
    }
end

-- If overrideWidth or overrideHeight have been set, calculate any size offset (if any) using the provided alignment value 
function GuiElement:GetOverridenWidthAndHeightAlignment()
    local size = self:GetElementSize()
    return (self.config.horizontalAlign) * (math.max(self.config.overrideWidth or 0, size.width) - size.width),
        (self.config.verticalAlign) * (math.max(self.config.overrideHeight or 0, size.height) - size.height)
end

function GuiElement:Remove()
    for i, v in ipairs(self.parent.children) do
        if (v.name == self.name) then
            table.remove(self.parent.children, i)
            break
        end
    end
end

return GuiElement