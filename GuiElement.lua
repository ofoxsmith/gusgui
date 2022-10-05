dofile_once("GUSGUI_PATHclass.lua")
-- Gui element parent class that is inherited by all elements
-- All elements define a GetBaseElementSize method, which gets the raw size of the gui element without margins, borders and etc using the Gui API functions
-- Elements that manage other child elements implement a GetManagedXY function, which allows children to get x, y relative to parent position and config
-- and a Draw method, which draws the element using the Gui API
local GuiElement = class(function(Element, config, extended)
    extended = extended or {}
    Element.id = config.id
    Element.uid = GetNextUID()
    config.id = nil;
    Element.name = config.name or nil
    Element.config = {}
    Element._rawconfig = {}
    Element.useHoverConfigForNextFrame = false
    Element._rawchildren = {}
    Element._config = {}
    Element.validator = {}
    for _ = 1, #baseValidator do
        Element.validator[_] = baseValidator[_]
    end
    for _, v in ipairs(extended) do
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
            error(err:format(Element.id or "NO ELEMENT ID"), 4)
        end
    end
    Element.gui = nil
    setmetatable(Element._config, {
        __index = function(t, k)
            local value = nil
            if Element.useHoverConfigForNextFrame then 
                value = Element._rawconfig.hover[k] or Element._rawconfig[k]
            else value = Element._rawconfig[k] end
            return Element:ResolveValue(value, k)
        end,
        __newindex = function(t, k, v)
            error("_config is readonly")
        end
    })
    setmetatable(Element.config, {
        __index = function(t, k)
            return Element._rawconfig[k]
        end,
        __newindex = function(t, k, v)
            for _ = 1, #Element.validator do
                if (Element.validator[_].name == k) then
                    local valid, nv, err = Element.validator[_].validate(v, Element.validator)
                    if valid and (nv ~= nil) then
                        Element._rawconfig[k] = nv
                    elseif valid then
                        Element._rawconfig[k] = v
                    elseif err then
                        error(err:format(Element.id or "NO ELEMENT ID"), 2)
                    end
                    break
                end
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
            for _ = 1, #self.validator do
                if (self.validator[_].name == k) then
                    t = self.validator[_].fromString
                end
            end
            return t and t(self.gui.cachedValues[a.id]) or self.gui.cachedValues[a.id]
        end
        return self.gui:GetState(a.value)
    end
    return a
end

function GuiElement:GetMouseData()
    local component = EntityGetComponent(EntityGetWithTag("player_unit")[1], "ControlsComponent")[1]
    local mx, my = ComponentGetValue2(component, "mMousePosition")
    local screen_w, screen_h = GuiGetScreenDimensions(g)
    local cx, cy = GameGetCameraPos()
    local vx = MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")
    local vy = MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y")
    local gmx = ((mx - cx) * screen_w / vx + screen_w / 2)
    local gmy = ((my - cy) * screen_h / vy + screen_h / 2)
    return gmx, gmy, ComponentGetValue2(component, "mButtonDownFire")
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
    child:OnEnterTree(self, false)
end

function GuiElement:RemoveChild(childID)
    if childID == nil then
        error("bad argument #1 to RemoveChild (string expected, got no value)", 2)
    end
    for i, v in ipairs(self.children) do
        if (v.id == childID) then
            v:OnExitTree()
            break
        end
    end
end

local _uid_ = 1
function GetNextUID()
    _uid_ = _uid_ + 1
    return _uid_     
end

function GuiElement:GetElementSize()
    local iW, iH = self:GetBaseElementSize()
    local baseW = math.max(self._config.overrideWidth, iW)
    local baseH = math.max(self._config.overrideHeight, iH)
    local borderSize = 0
    if self._config.drawBorder then
        borderSize = 6
    end
    local width = baseW + self._config.padding.left + self._config.padding.right + borderSize
    local height = baseH + self._config.padding.top + self._config.padding.bottom + borderSize
    return {
        baseW = baseW,
        baseH = baseH,
        width = width,
        height = height,
        offsetX = self._config.horizontalAlign * (baseW - iW),
        offsetY = self._config.verticalAlign * (baseH - iH)
    }
end

function GuiElement:RenderBorder(x, y, w, h)
    self.borderID = self.borderID or self.gui.nextID()
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 1)
    GuiImageNinePiece(self.gui.guiobj, self.borderID, x, y, w + self._config.padding.left + self._config.padding.right+2, h + self._config.padding.top + self._config.padding.bottom+2, 1, "GUSGUI_PATHborder.png")
end

function GuiElement:RenderBackground(x, y, w, h)
    self.bgID = self.bgID or self.gui.nextID()
    local b = self._config.drawBorder and 0 or 2
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 3)
    GuiImageNinePiece(self.gui.guiobj, self.bgID, x+1, y+1, w + self._config.padding.left + self._config.padding.right-b, h + self._config.padding.top + self._config.padding.bottom-b, 1,
        "GUSGUI_PATHbg.png")
end

function GuiElement:Remove()
    self:OnExitTree()
end

function GuiElement:OnEnterTree(parent, isroot, gui)
    if isroot then 
        self.gui = gui
        if self.id then
            if self.gui.ids[self.id] then
                self.parent = nil
                error("GUI: Element ID value must be unique (\"" .. self.id .. "\" is a duplicate)")
            end
            self.gui.ids[self.id] = true
        end
        for i=1, #self._rawchildren do
            self._rawchildren[i]:OnEnterTree(self)
        end    
        return    
    end 
    self.parent = parent
    self.gui = parent.gui
    if self.id then
        if self.gui.ids[self.id] then
            self.parent = nil
            error("GUI: Element ID value must be unique (\"" .. self.id .. "\" is a duplicate)")
        end
        self.gui.ids[self.id] = true
    end
    for i=1, #self._rawchildren do
        self._rawchildren[i]:OnEnterTree(self)
    end
    self._rawchildren = nil
    table.insert(parent.children, self)
end

function GuiElement:OnExitTree()
    for i = 1, #self.children do
        local c = self.children[i]
        c:OnExitTree()
    end
    for i, v in ipairs(self.parent.children) do
        if (v.uid == self.uid) then
            table.remove(self.parent.children, i)
            break
        end
    end
    self.parent = nil
    self.children = nil
    if self.id then
        self.gui.ids[self.id] = nil
    end
    self.gui = nil
end


function GuiElement:PropagateInteractableBounds(x, y, w, h)
    if not self.parent then return end
    self.parent:PropagateInteractableBounds(x, y, w, h)
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
            if not (type(o[1]) == "number" or (type(o[1]) == "table" and o[1]["value"] ~= nil and o[1]["_type"] ~= nil) and
                type(o[2]) == "number" or (type(o[2]) == "table" and o[2]["value"] ~= nil and o[2]["_type"] ~= nil) and
                type(o[3]) == "number" or (type(o[3]) == "table" and o[3]["value"] ~= nil and o[3]["_type"] ~= nil)) then
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
        if type(o) == "function" then
            return true, nil, nil
        end
        return false, nil, "GUI: Invalid value for onHover on element \"%s\""
    end
}, {
    name = "hover",
    validate = function(o, s)
        if o == nil then
            return true, {}, nil
        end
        function findSchema(n)
            for i=1, #s do
                local v = s[i]
                if v.name == n then return v end 
            end
        end
        local t = {}
        for k, v in pairs(o) do
            local f = findSchema(k)
            if (f.canHover == nil) then
                local valid, nv, err = f.validate(v, s)
                if valid then
                    t[k] = nv or v
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
