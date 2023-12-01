dofile_once("GUSGUI_PATHclass.lua")
-- Gui element parent class that is inherited by all elements   
-- All elements define a GetBaseElementSize method, which gets the raw size of the gui element without margins, borders and etc using the Gui API functions   
-- Elements that manage other child elements implement a GetManagedXY function, which allows children to get x, y relative to parent position and config   
-- and a Draw method, which draws the element using the Gui API   
--- @class GuiElement
--- @field init function
--- @field is_a function
--- @field _config table
--- @field _rawconfig table
--- @field Draw function
--- @field type string
--- @field id string
--- @field class string
--- @field uid number|nil
--- @field extendedValidator table
--- @field allowsChildren boolean|nil
--- @field GetBaseElementSize function
--- @field gui Gui|nil
--- @field _rawchildren GuiElement[]
--- @field bgID number
--- @field parent HLayout|VLayout|VLayoutForEach|HLayoutForEach|nil
--- @field borderID number
--- @field maskID number
--- @field children GuiElement[]
--- @field z number
--- @operator call: GuiElement
local GuiElement = class(function(Element, config, extended)
    config = config or {}
    extended = extended or {}
    Element.id = config.id
    Element.uid = GetNextUID()
    config.id = nil;
    Element.class = config.class or ""
    config.class = nil
    Element.name = config.name or nil
    Element.config = {}
    Element._rawconfig = {}
    Element._hoverconfig = config.hover or {}
    Element.useHoverConfigForNextFrame = false
    Element._rawchildren = {}
    Element._config = {}
    Element.extendedValidator = extended
    for k, _ in pairs(BaseValidator) do
        Element:ApplyConfig(k, config[k])
    end
    for k, _ in pairs(Element.extendedValidator) do
        Element:ApplyConfig(k, config[k])
    end
    Element.gui = nil
    setmetatable(Element._config, {
        __index = function(t, k)
            local value = nil
            if Element.useHoverConfigForNextFrame == true then
                value = Element._hoverconfig[k]
                if value == nil then
                    value = Element._rawconfig[k]
                else
                    value = {value = value}
                end
            else
                value = Element._rawconfig[k]
            end
            if Element.class ~= "" and value.isDF then
                for cls in Element.class:gmatch("[a-z0-9A-Z_-]+") do
                    if Element.useHoverConfigForNextFrame and Element.gui.classOverrides[cls].hover[k] then
                        value = {value = Element.gui.classOverrides[cls].hover[k]}
                    end
                    if value.isDF and Element.gui.classOverrides[cls] then
                        value = Element.gui.classOverrides[cls][k]
                    end
                end
                if value == nil then
                    value = Element._rawconfig[k]
                end
            end
            if value == nil then
                local s = "%s was nil (_rawconfig[%s] {%s, %s}) on element %s %s %s %s"
                local e = Element._rawconfig[k] or {}
                Element.gui:Log(0, s:format(k, k, e.isDF, e.value, Element.uid, Element.type, Element.id or "NO ID", Element.class))
                return;
            end
            if k == "margin" or k == "padding" then
                return {
                    top = Element:ResolveValue(value.value.top, k),
                    left = Element:ResolveValue(value.value.left, k),
                    bottom = Element:ResolveValue(value.value.bottom, k),
                    right = Element:ResolveValue(value.value.right, k)
                }
            end
            if k == "colour" then
                if value.value ~= nil then
                    return {Element:ResolveValue(value.value[1], k), Element:ResolveValue(value.value[2], k),
                            Element:ResolveValue(value.value[3], k)}
                end
            end
            local resolvedValue = Element:ResolveValue(value.value, k)
            if type(resolvedValue) == "table" and resolvedValue._type ~= nil and resolvedValue.value ~= nil then
                local s = "Element:ResolveValue failed to get value (%s, %s) on element %s %s %s %s"
                Element.gui:Log(0, s:format(resolvedValue._type, resolvedValue.value, Element.uid, Element.type, Element.id or "NO ID", Element.class))
            end
            return resolvedValue
        end,
        __newindex = function()
            error("_config is readonly", 2)
        end
    })
    setmetatable(Element.config, {
        __index = function(t, k)
            return Element._rawconfig[k]
        end,
        __newindex = function(t, k, v)
            Element:ApplyConfig(k, v)
        end
    })
    Element.children = {}
    Element.rootNode = false
end)

--- @param s string
--- @return string
function GuiElement:Interp(s)
    if type(s) ~= "string" then
        self.gui:Log(2, ("Found a non-string value where a string is usually expected on element with id %s, is this intentional?"):format(self.id or "NO ELEMENT ID"))
        s = tostring(s)
    end
    return (s:gsub('($%b{})', function(w)
        w = w:sub(3, -2)
        local v = self.gui:GetState(w)
        local ty = type(v)
        if (ty == "table" or ty == "function" or ty == "thread" or ty == "userdata") then
            self.gui:Log(0, ("Failed to interpolate string %s: Cannot convert value %s into string, %s was a %s"):format(s, w, w, ty))
        end
        return tostring(v)
    end))
end

function GuiElement:ApplyConfig(k, v)
    local validator = self.extendedValidator[k] or BaseValidator[k]
    local t = type(v)
    if t == "table" and v["_type"] ~= nil and v["value"] then
        self._rawconfig[k] = {
            value = v,
            isDF = false
        }
        return
    end
    if v == nil and validator.required == true then
        local s = "Invalid value for %s on element \"%s\" (%s is required)"
        self.gui:Log(0, (s:format(k, self.id or "NO ELEMENT ID", k)))
        return
    elseif v == nil then
        self._rawconfig[k] = {
            value = validator.default,
            isDF = true
        }
        return
    end
    local newValue, err = validator.validate(v)
    if type(err) == "string" then
        self.gui:Log(0, err:format(self.id))
    end
    self._rawconfig[k] = {
        value = newValue,
        isDF = false
    }

end

function GuiElement:ResolveValue(a, k)
    if type(a) ~= "table" or a._type == nil or a.value == nil then
        return a
    end
    if a._type == "p_innerW" then
        local x = self.parent:GetElementSize()
        return x.baseW
    end
    if a._type == "p_totalW" then
        local x = self.parent:GetElementSize()
        return x.width
    end
    if a._type == "p_innerH" then
        local x = self.parent:GetElementSize()
        return x.baseH
    end
    if a._type == "p_totalH" then
        local x = self.parent:GetElementSize()
        return x.height
    end
    if a._type == "innerW" then
        local x = self:GetElementSize()
        return x.baseW
    end
    if a._type == "totalW" then
        local x = self:GetElementSize()
        return x.width
    end
    if a._type == "innerH" then
        local x = self:GetElementSize()
        return x.baseH
    end
    if a._type == "totalH" then
        local x = self:GetElementSize()
        return x.height
    end
    if a._type == "add" or a._type == "subtract" or a._type == "multiply" or a._type == "divide" then
        local op1 = self:ResolveValue(a.value.a, k)
        local op2 = self:ResolveValue(a.value.b, k)
        if a._type == "add" then
            return op1 + op2
        end
        if a._type == "subtract" then
            return op1 - op2
        end
        if a._type == "multiply" then
            return op1 * op2
        end
        if a._type == "divide" then
            return op1 / op2
        end
    end
    if a._type == "state" then
        local v = self.gui:GetState(a.value)
        if v == nil then
            self.gui:Log(1, ("Attempting to read from the state value %s, but it is nil. Is this intentional?"):format(a.value))
            return nil
        end
        return v
    end
    if a._type == "screenw" then
        return self.gui.screenW
    end
    if a._type == "screenh" then
        return self.gui.screenH
    end
    if a._type == "global" then
        local t = BaseValidator[k] or self.extendedValidator[k]
        return t.fromString(GlobalsGetValue(a.value))
    end
    return a
end

--- @return number
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

--- @param child GuiElement
--- @return GuiElement child The child added
function GuiElement:AddChild(child)
    if not self.allowsChildren then
        self.gui:Log(0, self.type .. " cannot have child element")
    end
    ---@cast self HLayout|HLayoutForEach|VLayout|VLayoutForEach
    child:OnEnterTree(self, false)
    return child
end

--- @param childID string
--- @return GuiElement self Returns self
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
    return self
end

--- @return GuiElement self Returns self
function GuiElement:RemoveAllChildren()
    for i, v in ipairs(self.children) do
        v:OnExitTree()
    end
    return self
end

local _uid_ = 1
--- @return number
function GetNextUID()
    _uid_ = _uid_ + 1
    return _uid_
end

function GuiElement:Render()
    if self._config.hidden then
        return
    end
    if not self._config.visible then
        self.parent:GetManagedXY(self)
        return
    end
    if self._config.onBeforeRender then
        self._config.onBeforeRender(self, self.gui.state)
    end
    local x, y = self._config.margin.left, self._config.margin.top
    if self.parent == nil then
        x, y = self.gui:GetRootElemXY(self)
    end
    self.z = (self._config.overrideZ ~= nil and (1000000 - self._config.overrideZ) or
                 (1000000 - self:GetDepthInTree() * 10))
    local size = self:GetElementSize()
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    if self._config.drawBorder then
        self:RenderBorder(x, y, size.paddingW, size.paddingH)
    end
    if self._config.drawBackground then
        self:RenderBackground(x, y, size.paddingW, size.paddingH)
    end
    self:Draw(x, y)
    if self._config.onAfterRender then
        self._config.onAfterRender(self, self.gui.state)
    end
end

--- @class elemSize
--- @field baseW number
--- @field baseH number
--- @field width number
--- @field height number
--- @field paddingW number
--- @field paddingH number
--- @field offsetX number
--- @field offsetY number
--- @return elemSize
function GuiElement:GetElementSize()
    local iW, iH = self:GetBaseElementSize()
    local baseW = math.max(self._config.overrideWidth, iW)
    local baseH = math.max(self._config.overrideHeight, iH)
    local borderSize = 0
    if self._config.drawBorder then
        borderSize = 4
    end
    local offsetX = (baseW - iW) * self._config.horizontalAlign
    local offsetY = (baseH - iH) * self._config.verticalAlign
    local width = baseW + self._config.padding.left + self._config.padding.right + borderSize
    local height = baseH + self._config.padding.top + self._config.padding.bottom + borderSize
    if self._config.hidden then
        return {
            baseW = 0,
            baseH = 0,
            width = 0,
            height = 0,
            paddingW = 0,
            paddingH = 0,
            offsetX = 0,
            offsetY = 0
        }
    end
    return {
        baseW = baseW,
        baseH = baseH,
        width = width,
        height = height,
        paddingW = baseW + self._config.padding.left + self._config.padding.right,
        paddingH = baseH + self._config.padding.top + self._config.padding.bottom,
        offsetX = math.floor(offsetX),
        offsetY = math.floor(offsetY)
    }
end

function GuiElement:RenderBorder(x, y, w, h)
    self.borderID = self.borderID or self.gui.nextID()
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 1)
    GuiImageNinePiece(self.gui.guiobj, self.borderID, x, y, w, h, 1, "GUSGUI_PATHborder.png")
end

function GuiElement:RenderBackground(x, y, w, h)
    self.bgID = self.bgID or self.gui.nextID()
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 1)
    GuiImageNinePiece(self.gui.guiobj, self.bgID, x, y, w, h, 1, "GUSGUI_PATHbg.png")
end

function GuiElement:Remove()
    self:OnExitTree()
end

--- @param parent HLayout|VLayout|HLayoutForEach|VLayoutForEach|nil
--- @param isroot boolean|nil
--- @param gui Gui|nil
function GuiElement:OnEnterTree(parent, isroot, gui)
    if isroot or parent == nil then
        self.gui = gui
        if self.id then
            if self.gui.ids[self.id] then
                self.parent = nil
                self.gui:Log(0, "Element ID value must be unique (\"" .. self.id .. "\" is a duplicate)")
            end
            self.gui.ids[self.id] = true
        end
        for i = 1, #self._rawchildren do
            if not self.allowsChildren then
                self.gui:Log(0, self.type .. " cannot have child element")
            end
            ---@cast self HLayout|HLayoutForEach|VLayout|VLayoutForEach
            self._rawchildren[i]:OnEnterTree(self)
        end
        return
    end
    self.parent = parent
    self.gui = parent.gui
    if self.id then
        if self.gui.ids[self.id] then
            self.parent = nil
            self.gui:Log(0, "Element ID value must be unique (\"" .. self.id .. "\" is a duplicate)")
        end
        self.gui.ids[self.id] = true
    end
    for i = 1, #self._rawchildren do
        if not self.allowsChildren then
            self.gui:Log(0, self.type .. " cannot have child element")
        end
        ---@cast self HLayout|HLayoutForEach|VLayout|VLayoutForEach
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
    if not self.parent then
        return
    end
    self.parent:PropagateInteractableBounds(x, y, w, h)
end

local function splitString(s, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(s, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(s, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(s, delimiter, from)
    end
    table.insert(result, string.sub(s, from))
    return result
end

BaseValidator = {
    drawBorder = {
    default = false,
    fromString = function(s)
        return s == "true"
    end,
    validate = function(o)
        if type(o) == "boolean" then
            return o
        end
        return nil, "Invalid value for drawBorder on element \"%s\""
    end
}, drawBackground = {
    default = false,
    fromString = function(s)
        return s == "true"
    end,
    validate = function(o)
        if type(o) == "boolean" then
            return o
        end
        return nil, "Invalid value for drawBorder on element \"%s\""
    end
}, overrideWidth = {
    default = 0,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            if o <= 0 then
                return nil, "Invalid value for overrideWidth on element \"%s\" (must be greater than 0)"
            end
            return o
        end
        return nil, "Invalid value for overrideWidth on element \"%s\""
    end
}, overrideHeight = {
    default = 0,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            if o <= 0 then
                return nil, "Invalid value for overrideHeight on element \"%s\" (must be greater than 0)"
            end
            return o
        end
        return nil, "Invalid value for overrideHeight on element \"%s\""
    end
}, verticalAlign = {
    default = 0,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            if not (0 <= o and o <= 1) then
                return nil, "Invalid value for verticalAlign on element \"%s\" (value must be between 0-1)"
            end
            return o
        end
        return nil, "Invalid value for verticalAlign on element \"%s\""
    end
}, horizontalAlign = {
    default = 0,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            if not (0 <= o and o <= 1) then
                return nil, "Invalid value for horizontalAlign on element \"%s\" (value must be between 0-1)"
            end
            return o
        end
        return nil, "Invalid value for horizontalAlign on element \"%s\""
    end
}, margin = {
    default = {
        top = 0,
        bottom = 0,
        left = 0,
        right = 0
    },
    fromString = function (s)
        local v = splitString(s, ",")
        return { top = tonumber(v[1]), left = tonumber(v[2]), bottom = tonumber(v[3]), right = tonumber(v[4]) }
    end,
    validate = function(o)
        local t = type(o)
        if t == "number" then
            return {
                top = o,
                bottom = o,
                left = o,
                right = o
            }
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
                    return nil, "Invalid value for margin " .. v .. " on element \"%s\""
                end
            end
            return m;
        end
        return nil, "Invalid value for margin on element \"%s\""
    end
}, padding = {
    default = {
        top = 0,
        bottom = 0,
        left = 0,
        right = 0
    },
    fromString = function (s)
        local v = splitString(s, ",")
        return { top = tonumber(v[1]), left = tonumber(v[2]), bottom = tonumber(v[3]), right = tonumber(v[4]) }
    end,
    validate = function(o)
        local t = type(o)
        if t == "number" then
            return {
                top = o,
                bottom = o,
                left = o,
                right = o
            }
        elseif t == "table" then
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
                    return nil, "Invalid value for padding " .. v .. " on element \"%s\""
                end
            end
            return m;
        else
        return nil, "Invalid value for padding on element \"%s\""
        end
    end
}, colour = {
    default = nil,
    fromString = function (s)
        local v = splitString(s, ",")
        return {tonumber(v[1]), tonumber(v[2]), tonumber(v[3])}
    end,
    validate = function(o)
        if type(o) == "table" then
            if not (type(o[1]) == "number" or (type(o[1]) == "table" and o[1]["value"] ~= nil and o[1]["_type"] ~= nil) and
                type(o[2]) == "number" or (type(o[2]) == "table" and o[2]["value"] ~= nil and o[2]["_type"] ~= nil) and
                type(o[3]) == "number" or (type(o[3]) == "table" and o[3]["value"] ~= nil and o[3]["_type"] ~= nil)) then
                return nil, "Invalid value for colour on element \"%s\""
            end
            return o
        end
        return nil, "Invalid value for colour on element \"%s\""
    end
}, onHover = {
    default = nil,
    fromString = function (s, funcs)
        if funcs[s] then return funcs[s] end
        error("GUSGUI: Unknown function name" .. s)
    end,
    validate = function(o)
        if type(o) == "function" then
            return o
        end
        return nil, "Invalid value for onHover on element \"%s\""
    end
}, hidden = {
    default = false,
    fromString = function(s)
        return s == "true"
    end,
    validate = function(o)
        if type(o) == "boolean" then
            return o
        end
        return nil, "Invalid value for hidden on element \"%s\""
    end
}, visible = {
    default = true,
    fromString = function(s)
        return s == "true"
    end,
    validate = function(o)
        if type(o) == "boolean" then
            return o
        end
        return nil, "Invalid value for visible on element \"%s\""
    end
 }, overrideZ = {
    default = nil,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        local t = type(o)
        if t == "number" then
            return o
        end
        return nil, "Invalid value for overrideZ on element \"%s\""
    end
}, onBeforeRender = {
    default = nil,
    fromString = function (s, funcs)
        if funcs[s] then return funcs[s] end
        error("GUSGUI: Unknown function name" .. s)
    end,
    validate = function(o)
        local t = type(o)
        if t == "function" then
            return o
        end
        return nil, "Invalid value for onBeforeRender on element \"%s\""
    end
}, onAfterRender = {
    default = nil,
    fromString = function (s, funcs)
        if funcs[s] then return funcs[s] end
        error("GUSGUI: Unknown function name" .. s)
    end,
    validate = function(o)
        local t = type(o)
        if t == "function" then
            return o
        end
        return nil, "Invalid value for onAfterRender on element \"%s\""
    end
}}

--- @return GuiElement
return GuiElement
