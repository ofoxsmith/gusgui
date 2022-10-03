dofile_once("GUSGUI_PATHclass.lua")
-- Gui element parent class that is inherited by all elements
-- All elements define a GetBaseElementSize method, which gets the raw size of the gui element without margins, borders and etc using the Gui API functions
-- Elements that manage other child elements implement a GetManagedXY function, which allows children to get x, y relative to parent position and config
-- and a Draw method, which draws the element using the Gui API
local GuiElement = class(function(Element, config, extended)
    extended = extended or {}
    Element.id = config.id
    config.id = nil;
    Element.name = config.name or nil
    Element.config = {}
    Element._rawconfig = {}
    Element.useHoverConfigForNextFrame = false
    Element._rawchildren = {}
    Element._config = {}
    Element.validator = {}
    for _=1,#baseValidator do Element.validator[_] = baseValidator[_] end
    for _,v in ipairs(extended) do 
        table.insert(Element.validator, v)
    end
    for k = 1, #Element.validator do
        local v = Element.validator[k]
        local valid, nv, err = v.validate(config[v.name], Element.validator)
        if valid and (nv ~= nil) then
            Element._rawconfig[v.name] = nv
        elseif valid then
            Element._rawconfig[v.name] = config[v.name]
        elseif err then
            for _,v in ipairs(baseValidator) do 
                print(v.name)
            end        
            error(err:format(Element.id or "NO ELEMENT ID"), 4)
        end
    end
    Element.gui = nil
    setmetatable(Element._config, {
        __index = function(t, k)
            local value = (Element.useHoverConfigForNextFrame == true and Element._rawconfig.hover[k] or nil) or Element._rawconfig[k]
            if Element.useHoverConfigForNextFrame == true then 
                return Element:ResolveValue(value, k)
            end
            return Element:ResolveValue(value, k)
        end,
        __newindex = function(t, k, v) error("_config is readonly") end
    })
    setmetatable(Element.config, {
        __index = function(t, k)
            return Element._rawconfig[k]
        end,
        __newindex = function(t, k, v)
            local valid, nv, err = self.validator[k].validate(v, self.validator)
            if valid and (nv ~= nil) then
                Element._rawconfig[v.name] = nv
            elseif valid then
                Element._rawconfig[v.name] = v
            elseif err then
                error(err:format(Element.id or "NO ELEMENT ID"), 2)
            end
        end
    })
    Element.children = {}
    Element.rootNode = false
end)

function GuiElement:Interp(s)
    if (type(s) ~= "string") then
        return error("bad argument #1 to Interp (string expected, got " .. type(s) .. ")", 2)
    end
    return (s:gsub('($%b{})', function(w)
        w = string.sub(w, 3, -2)
        return self.gui:GetState(w)
    end))
end

function GuiElement:ResolveValue(a, k)
    if type(a) ~= "table" then
        return a
    end
    if (a._type == "state" or a._type == "global") and type(a.value) == "string" then
        if a._type == "global" then
            local t = nil
            for _=1, #self.validator do
                GamePrint(tostring(self.validator[_].name == k))
                if (self.validator[_].name == k ) then t = self.validator[_].fromString end
            end
            return t and t(self.gui.cachedValues[a.id]) or self.gui.cachedValues[a.id]
        end
        return self.gui:GetState(a.value)
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
    child.parent = self
    if child["is_a"] and child["Draw"] and child["GetBaseElementSize"] then
        child.gui = self.gui
        if child.id then 
            if self.gui.ids[child.id] then
                error("GUI: Element ID value must be unique (\"" .. child.id .. "\" is a duplicate)")
            end
            self.gui.ids[child.id] = true
        end
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
            if v.id then self.gui.ids[v.id] = nil end
            break
        end
    end
end

function GuiElement:GetElementSize()
    local baseW, baseH = self:GetBaseElementSize()
    local borderSize = 0
    if self._config.drawBorder then
        borderSize = 4
    end
    local width = baseW + self._config.padding.left + self._config.padding.right + borderSize
    local height = baseH + self._config.padding.top + self._config.padding.bottom + borderSize
    return {
        baseW = baseW,
        baseH = baseH,
        width = (math.max(self._config.overrideWidth or 0, width)),
        height = (math.max(self._config.overrideHeight or 0, height)),
        offsetX = (self._config.horizontalAlign) * (math.max(self._config.overrideWidth or 0, width) - width),
        offsetY = (self._config.verticalAlign) * (math.max(self._config.overrideHeight or 0, height) - height)
    }
end

function GuiElement:RenderBorder(x, y, w, h)
    self.borderID = self.borderID or self.gui.nextID()
    local width = math.max((self._config.overrideWidth or 0), w + self._config.padding.left + self._config.padding.right)
    local height = math.max((self._config.overrideHeight or 0), h + self._config.padding.top + self._config.padding.bottom)
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 1)
    GuiImageNinePiece(self.gui.guiobj, self.borderID, x + 1, y + 1, width, height, 1, "GUSGUI_PATHborder.png")
end

function GuiElement:RenderBackground(x, y, w, h)
    self.bgID = self.bgID or self.gui.nextID()
    local border = (self._config.drawBorder and 2 or 0)
    local width = math.max((self._config.overrideWidth or 0), w + self._config.padding.left + self._config.padding.right)
    local height = math.max((self._config.overrideHeight or 0), h + self._config.padding.top + self._config.padding.bottom)
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 3)
    GuiImageNinePiece(self.gui.guiobj, self.bgID, x + border, y + border, width - border, height - border, 1,
        "GUSGUI_PATHbg.png")
end

function GuiElement:Remove()
    if self.id then self.gui.ids[self.id] = nil end
    for i, v in ipairs(self.parent.children) do
        if (v.name == self.name) then
            table.remove(self.parent.children, i)
            break
        end
    end
end

baseValidator = {{
    name = "drawBorder",
    fromString = function(s) 
        return s == "true"
    end,
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, false, nil
        end
        if t == "table" and o["_type"] ~= nil and o["value"] then
            return true, nil, nil
        end
        if t == "boolean" then
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for drawBorder on element \"%s\""
    end
}, {
    name = "drawBackground",
    fromString = function(s) 
        return s == "true"
    end,
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, false, nil
        end
        if t == "table" and o["_type"] ~= nil and o["value"] then
            return true, nil, nil
        end
        if t == "boolean" then
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for drawBackground on element \"%s\""
    end
}, {
    name = "overrideWidth",
    fromString = function(s) 
        return tonumber(s)
    end,
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, 0, nil
        end
        if t == "table" and o["_type"] ~= nil and o["value"] then
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
    fromString = function(s) 
        return tonumber(s)
    end,
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, 0, nil
        end
        if t == "table" and o["_type"] ~= nil and o["value"] then
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
    fromString = function(s) 
        return tonumber(s)
    end,
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, 0, nil
        end
        if t == "table" and o["_type"] ~= nil and o["value"] then
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
    fromString = function(s) 
        return tonumber(s)
    end,
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, 0, nil
        end
        if t == "table" and o["_type"] ~= nil and o["value"] then
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
}, {
    name = "onHover",
    validate = function(o)
        if o == nil then
            return true, nil, nil
        end
        if type(o) == "function" then return true, nil, nil end
        return false, nil, "GUI: Invalid value for onHover on element \"%s\""
    end
}, {
    name = "hover",
    validate = function(o, self)
        if o == nil then return true, {}, nil end
        local t = {}
        for k, v in pairs(o) do
            if (self[k].canHover ~= false) then 
                local valid, nv, err = self[k].validate(v, self)
                if valid then 
                    o[k] = nv or v
                end    
            end
        end
        return true, t, nil
    end
}, {
    name = "hidden",
    fromString = function(s) 
        return s == "true"
    end,
    validate = function(o)
        local t = type(o)
        if o == nil then
            return true, false, nil
        end
        if t == "table" and o["_type"] ~= nil and o["value"] then
            return true, nil, nil
        end
        if t == "boolean" then
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for hidden on element \"%s\""
    end
}}

return GuiElement
