dofile_once("GUSGUI_PATHclass.lua")
-- Gui element parent class that is inherited by all elements
-- All elements define a GetBaseElementSize method, which gets the raw size of the gui element without margins, borders and etc using the Gui API functions
-- Elements that manage other child elements implement a GetManagedXY function, which allows children to get x, y relative to parent position and config
-- and a Draw method, which draws the element using the Gui API
local GuiElement = class(function(Element, config)
    if config.id == nil then
        error("GUI: Invalid construction of element (id is required)")
    end
    Element.id = config.id
    config.id = nil;
    Element.name = config.name or nil
    Element.config = {}
    Element._rawconfig = {}
    Element._rawchildren = {}
    for k = 1, #Element.baseValidator do
        local v = Element.baseValidator[k]
        local valid, nv, err = v.validate(config[v.name])
        if valid and (nv ~= nil) then
            Element._rawconfig[v.name] = nv
        elseif valid then
            Element._rawconfig[v.name] = config[v.name]
        elseif err then
            error(err:format(Element.id), 4)
        end
    end
    Element.gui = nil
    setmetatable(Element.config, {
        __index = function(t, k)
            return Element:ResolveValue(Element._rawconfig[k])
        end,
        __newindex = function(t, k, v)
            local valid, nv, err = self.baseValidator[k].validate(v)
            if valid and (nv ~= nil) then
                Element._rawconfig[v.name] = nv
            elseif valid then
                Element._rawconfig[v.name] = v
            elseif err then
                error(err:format(Element.id), 2)
            end
        end
    })
    Element.children = {}
    Element.rootNode = false
end)

function GuiElement:ResolveValue(a, t)
    if type(a) ~= "table" then
        return a
    end
    if a._type == "state" and type(a.value) == "string" then
        return self.gui.GetState(a)
    end
    if a._type == "global" and type(a.value) == "string" then
        local v = GlobalsGetValue(a.value)
        if t == "number" then
            return tonumber(v)
        end
        if t == "boolean" then
            return (v == "true") and true or false
        end
        return v
    end
    return a
end

function GuiElement:GetDepthInTree()
    local at = self
    local d = 0
    while true do
        d = d + 1
        if (at.parent == nil) then
            return d
        end
        at = at.parent
    end
end

function GuiElement:AddChild(child)
    if not self.allowsChildren then
        error("GUI: " .. self.type .. " cannot have child element")
    end
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
        if not testID(child.id) then
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
                if a ~= v.id then
                    table.insert(newids, a)
                end
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
        borderSize = 4
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
    self.borderID = self.borderID or self.gui.nextID()
    local width = math.max((self.config.overrideWidth or 0), w + self.config.padding.left + self.config.padding.right)
    local height = math.max((self.config.overrideHeight or 0), h + self.config.padding.top + self.config.padding.bottom)
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 1)
    GuiImageNinePiece(self.gui.guiobj, self.borderID, x + 1, y + 1, width, height, 1, "GUSGUI_PATHborder.png")
end

function GuiElement:RenderBackground(x, y, w, h)
    self.bgID = self.bgID or self.gui.nextID()
    local border = (self.config.drawBorder and 2 or 0)
    local width = math.max((self.config.overrideWidth or 0), w + self.config.padding.left + self.config.padding.right)
    local height = math.max((self.config.overrideHeight or 0), h + self.config.padding.top + self.config.padding.bottom)
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 3)
    GuiImageNinePiece(self.gui.guiobj, self.bgID, x + border, y + border, width - border, height - border, 1,
        "GUSGUI_PATHbg.png")
end

function GuiElement:Remove()
    for i, v in ipairs(self.parent.children) do
        if (v.name == self.name) then
            table.remove(self.parent.children, i)
            break
        end
    end
end

GuiElement.baseValidator = {{
    name = "drawBorder",
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, false, nil
        end
        if t == "table" and t["_type"] ~= nil and t["value"] then
            return true, nil, nil
        end
        if t == "boolean" then
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for drawBorder on element \"%s\""
    end
}, {
    name = "drawBackground",
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, false, nil
        end
        if t == "table" and t["_type"] ~= nil and t["value"] then
            return true, nil, nil
        end
        if t == "boolean" then
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for drawBackground on element \"%s\""
    end
}, {
    name = "overrideWidth",
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, 0, nil
        end
        if t == "table" and t["_type"] ~= nil and t["value"] then
            return true, nil, nil
        end
        if t == "number" then
            if o <= 0 then
                return false, nil, "GUI: Invalid value for overrideWidth on element \"%s\" (must be greater than 0)"
            end
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for overrideWidth on element \"%s\""
    end
}, {
    name = "overrideHeight",
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, 0, nil
        end
        if t == "table" and t["_type"] ~= nil and t["value"] then
            return true, nil, nil
        end
        if t == "number" then
            if o <= 0 then
                return false, nil, "GUI: Invalid value for overrideHeight on element \"%s\" (must be greater than 0)"
            end
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for overrideHeight on element \"%s\""
    end
}, {
    name = "verticalAlign",
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, 0, nil
        end
        if t == "table" and t["_type"] ~= nil and t["value"] then
            return true, nil, nil
        end
        if t == "number" then
            if not (0 <= o and o <= 1) then
                return false, nil,
                    "GUI: Invalid value for verticalAlign on element \"%s\" (value did not match 0 ≤ value ≤ 1)"
            end
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for verticalAlign on element \"%s\""
    end
}, {
    name = "horizontalAlign",
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, 0, nil
        end
        if t == "table" and t["_type"] ~= nil and t["value"] then
            return true, nil, nil
        end
        if t == "number" then
            if not (0 <= o and o <= 1) then
                return false, nil,
                    "GUI: Invalid value for horizontalAlign on element \"%s\" (value did not match 0 ≤ value ≤ 1)"
            end
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for horizontalAlign on element \"%s\""
    end
}, {
    name = "margin",
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, {
                top = 0,
                bottom = 0,
                left = 0,
                right = 0
            }, nil
        end
        if t == "number" then
            return true, {
                top = o,
                bottom = o,
                left = o,
                right = o
            }, nil
        end
        if t == "table" then
            local m = {
                top = o["top"],
                bottom = o["bottom"],
                left = o["left"],
                right = o["right"]
            }
            for _, v in ipairs({"top", "bottom", "left", "right"}) do
                local ty = type(m[v])
                if ty == "nil" then
                    m[v] = 0
                elseif ty == "number" then
                elseif ty == "table" and m[v] ~= nil and m[v] ~= nil then
                else
                    return false, nil, "GUI: Invalid value for margin " .. v .. " on element \"%s\""
                end
            end
            return true, m, nil;
        end
        return false, nil, "GUI: Invalid value for margin on element \"%s\""
    end
}, {
    name = "padding",
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, {
                top = 0,
                bottom = 0,
                left = 0,
                right = 0
            }, nil
        end
        if t == "number" then
            return true, {
                top = o,
                bottom = o,
                left = o,
                right = o
            }, nil
        end
        if t == "table" then
            local m = {
                top = o["top"],
                bottom = o["bottom"],
                left = o["left"],
                right = o["right"]
            }
            for _, v in ipairs({"top", "bottom", "left", "right"}) do
                local ty = type(m[v])
                if ty == "nil" then
                    m[v] = 0
                elseif ty == "number" then
                elseif ty == "table" and m[v] ~= nil and m[v] ~= nil then
                else
                    return false, nil, "GUI: Invalid value for padding " .. v .. " on element \"%s\""
                end
            end
            return true, m, nil;
        end
        return false, nil, "GUI: Invalid value for padding on element \"%s\""
    end
}, {
    name = "colour",
    validate = function(o)
        if o == nil then
            return true, nil, nil
        end
        if type(o) == "table" then
            if not (type(o.r) == "number" or (type(o.r) == "table" and o.r["value"] ~= nil and o.r["_type"] ~= nil) and
                type(o.g) == "number" or (type(o.g) == "table" and o.g["value"] ~= nil and o.g["_type"] ~= nil) and
                type(o.b) == "number" or (type(o.b) == "table" and o.b["value"] ~= nil and o.b["_type"] ~= nil)) then
                return false, nil, "GUI: Invalid value for colour on element \"%s\""
            end
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for colour on element \"%s\""
    end
}}

return GuiElement
