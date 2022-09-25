dofile_once("GUSGUI_PATHclass.lua")
-- Gui element parent class that is inherited by all elements
-- All elements define a GetBaseElementSize method, which gets the raw size of the gui element without margins, borders and etc using the Gui API functions
-- Elements that manage other child elements implement a GetManagedXY function, which allows children to get x, y relative to parent position and config
-- and a Draw method, which draws the element using the Gui API
local GuiElement = class(function(Element, config)
    if config.id == nil then error("GUI: Invalid construction of element (id is required)") end
    Element.id = config.id
    config.id = nil;
    Element.config = {}
    Element._rawconfig = config
    Element.gui = nil
    Element.allowChildren = false
    setmetatable(Element.config, {
        __index = function(t, k)
            return Element._rawconfig[k]
        end,
        __newindex = function(t, k, v)
            Element._rawconfig[k] = v
        end
    })
    Element.children = {}
    Element.rootNode = false
end)


function GuiElement:ResolveValue(a) 
    if type(a) ~= "table" then return a end
    if a._type == "state" and type(a.value) == "string" then return self.gui.GetState(a) end
    if a._type == "global" and type(a.value) == "string" then return GlobalsGetValue(a.value) end
    return a
end 

function GuiElement:GetDepthInTree() 
    local at = self
    local d = 0
    while true do
        d = d + 1
        if (at.parent == nil) then return d end
        at = at.parent
    end
end

function GuiElement:AddChild(child)
    if not self.allowChildren then error("GUI: " .. self.type .. " cannot have child element") end
    local function testID(i)
        for k = 1, #self.gui.ids do
            if (self.gui.ids[k] == i) then
                return false
            end
        end
        return true
    end
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
            for i, a in ipairs(self.gui.ids) do
                if a ~= v.id then table.insert(newids, a) end
            end
            self.gui.ids = newids
            break
        end
    end
end

function GuiElement:GetElementSize()
    local baseW, baseH = self:GetBaseElementSize()
    local borderSize = 0
    if self.config.drawBorder then
        borderSize = 2
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

function GuiElement:RenderBorder(x, y, w, h)
      local width = math.max((self.config.overrideWidth or 0) - 2, w + self.config.padding.left + self.config.padding.right)
      local height = math.max((self.config.overrideHeight or 0) - 2, h + self.config.padding.top + self.config.padding.bottom)
      GuiZSetForNextWidget(self.gui.guiobj, self.z + 1)
      GuiImageNinePiece(self.gui.guiobj, self.gui.nextID(), x + 1, y + 1, width, height, 1, "GUSGUI_PATHborder.png")
end

function GuiElement:RenderBackground(x, y, w, h)
    local border = (self:ResolveValue(self.config.drawBorder) and 2 or 0)
    local width = math.max((self.config.overrideWidth or 0) - border, w + self.config.padding.left + self.config.padding.right) - 1
    local height = math.max((self.config.overrideHeight or 0) - border, h + self.config.padding.top + self.config.padding.bottom) - 1
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 3)
    GuiImageNinePiece(self.gui.guiobj, self.gui.nextID(), x + (border/2), y + (border/2), width, height, 1, "GUSGUI_PATHbg.png")
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