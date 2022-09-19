dofile_once("[[GUSGUI_PATH]]class.lua")
-- Gui element parent class that is inherited by all elements
-- All elements define a GetBaseElementSize method, which gets the raw size of the gui element without margins, borders and etc using the Gui API functions
-- Elements that manage other child elements implement a GetManagedXY function, which allows children to get x, y relative to parent position and config
-- and a Draw method, which draws the element using the Gui API
local GuiElement = class(function(Element, id, config)
    config = config or {}
    Element.config = {}
    Element.config.drawBorder = config.drawBorder or false
    Element.config.borderSize = config.borderSize or 1
    Element.config.overrideWidth = config.overrideWidth or false
    Element.config.overrideHeight = config.overrideHeight or false
    Element.config.verticalAlign = config.verticalAlign or 0
    Element.config.horizontalAlign = config.horizontalAlign or 0
    Element.config.margin = config.margin or {
        top = 0,
        right = 0,
        bottom = 0,
        left = 0
    }
    Element.config.padding = config.padding or {
        top = 0,
        right = 0,
        bottom = 0,
        left = 0
    }
    Element.gui = nil
    Element.allowChildren = false
    if id == nil then error("GUI: Invalid construction of element (id is required)") end
    Element.id = id
    Element._rawconfig = {}
    setmetatable(Element.config, {
        __index = function(t, k)
            return Element._rawconfig[k]
        end,
        __newindex = function(t, k, v)

        end
    })
    Element.children = {}
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
    child.parent = self
    if child["is_a"] and child["Draw"] and child["GetBaseElementSize"] then
        child.gui = self.gui
        if not testID(data.id) then
            error("GUI: Element ID value must be unique (\"" .. child.id .. "\" is a duplicate)")
        end
        table.insert(self.gui.ids, child.id)
        table.insert(self.children, child)
    else
        error("bad argument #1 to AddChild (GuiElement object expected, got invalid value)", 2)
    end
end

function GuiElement:RemoveChild(childName)
    if child == nil then
        error("bad argument #1 to RemoveChild (string expected, got no value)", 2)
    end
    for i, v in ipairs(self.children) do
        if (v.name == childName) then
            table.remove(self.children, i)
            local newids = {}
            for i, a in ipairs(self.ids) do
                if a ~= v.id then table.insert(newids, a) end
            end
            self.ids = newids
            break
        end
    end
end

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
        width = (math.max(self.config.overrideWidth or 0, width)),
        height = (math.max(self.config.overrideHeight or 0, height)),
        offsetX = (self.config.horizontalAlign) * (math.max(self.config.overrideWidth or 0, width) - width),
        offsetY = (self.config.verticalAlign) * (math.max(self.config.overrideHeight or 0, height) - height)
    }
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