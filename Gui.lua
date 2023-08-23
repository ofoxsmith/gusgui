dofile_once("GUSGUI_PATHclass.lua")
dofile_once("GUSGUI_PATHGuiElement.lua")
--- @return function
local function getIdCounter()
    local id = 1
    --- @return number
    return function()
        id = id + 1
        return id
    end
end

local GuiElements = {}
do
    ---@module "Text"
    local Text = dofile_once("GUSGUI_PATHelems/Text.lua")
    ---@module "Button"
    local Button = dofile_once("GUSGUI_PATHelems/Button.lua")
    ---@module "Image"
    local Image = dofile_once("GUSGUI_PATHelems/Image.lua")
    ---@module "ImageButton"
    local ImageButton = dofile_once("GUSGUI_PATHelems/ImageButton.lua")
    ---@module "HLayout"
    local HLayout = dofile_once("GUSGUI_PATHelems/HLayout.lua")
    ---@module "HLayoutForEach"
    local HLayoutForEach = dofile_once("GUSGUI_PATHelems/HLayoutForEach.lua")
    ---@module "VLayoutForEach"
    local VLayoutForEach = dofile_once("GUSGUI_PATHelems/VLayoutForEach.lua")
    ---@module "VLayout"
    local VLayout = dofile_once("GUSGUI_PATHelems/VLayout.lua")
    ---@module "Slider"
    local Slider = dofile_once("GUSGUI_PATHelems/Slider.lua")
    ---@module "TextInput"
    local TextInput = dofile_once("GUSGUI_PATHelems/TextInput.lua")
    ---@module "ProgressBar"
    local ProgressBar = dofile_once("GUSGUI_PATHelems/ProgressBar.lua")
    ---@module "Checkbox"
    local Checkbox = dofile_once("GUSGUI_PATHelems/Checkbox.lua")
    GuiElements = {
        Text = Text,
        Button = Button,
        Image = Image,
        ImageButton = ImageButton,
        HLayout = HLayout,
        HLayoutForEach = HLayoutForEach,
        VLayout = VLayout,
        VLayoutForEach = VLayoutForEach,
        Slider = Slider,
        TextInput = TextInput,
        ProgressBar = ProgressBar,
        Checkbox = Checkbox,
    }
end



--- @class Gui
--- @field classOverrides table
--- @field guiobj userdata
--- @field state table
--- @field enableLogging boolean
--- @field baseX integer
--- @field baseY integer
--- @field tree GuiElement[]
--- @operator call: Gui
local Gui = class(function(newGUI, config)
    config = config or {}
    config.state = config.state or {}
    config.gui = config.gui or GuiCreate()
    config.enableLogging = config.enableLogging or false
    config.baseX = config.baseX or 0
    config.baseY = config.baseY or 0
    newGUI.ids = {}
    newGUI.nextID = getIdCounter()
    newGUI.stateID = getIdCounter()
    newGUI.guiobj = config.gui
    newGUI.tree = {}
    newGUI.cachedData = {}
    newGUI.enableLogging = config.enableLogging
    newGUI.baseX = config.baseX
    newGUI.baseY = config.baseY
    newGUI.state = config.state
    newGUI._state = {}
    newGUI.classOverrides = {}
    newGUI.screenW, newGUI.screenH = GuiGetScreenDimensions(newGUI.guiobj)
    newGUI.screenW, newGUI.screenH = math.floor(newGUI.screenW), math.floor(newGUI.screenH)
end)

--- @param s string
--- @return any
function Gui:GetState(s)
    local values = {}
    for i in s:gmatch("[^/]+") do
        table.insert(values, i)
    end
    local item
    for i = 1, #values do
        local k = values[i]
        if i == 1 then
            item = self._state[k]
        else
            item = item[k]
        end
    end
    return item
end

---@param str string
---@return State
function Gui:StateStringToTable(str)
    local StateTypes = {
        Value = Gui.StateValue,
        Add = Gui.StateAdd,
        Subtract = Gui.StateSubtract,
        Divide = Gui.StateDivide,
        Multiply = Gui.StateMultiply,
        Global = Gui.StateGlobal
    }    
    ---@type string[]
    local vals = {}
    if str:find("State[a-zA-Z]+") == 1 then
        while true do
            local c = false
            str = str:gsub("%([a-zA-Z0-9,%% ]+%)", function (s)
                c = true
                ---@cast s string
                table.insert(vals, s:sub(1, -1))
                return "%%" .. #vals
            end)
            if c == false then break end
        end
    end
    ---@param a string
    ---@return State
    local function resolve(a)
        local type = a:match("State([a-zA-Z]+)")
        if StateTypes[type] == nil then error(("GUSGUI: Failed to read state value string")) end
        local val = vals[tonumber(a:match("([0-9]+)"))]
        if type == "Add" or type == "Subtract" or type == "Divide" or type == "Multiply" then
            local val1 = val:match("^[^,]+")
            local val2 = val:match("[^,]+$")
            local res1, res2
            if val1:match("State([a-zA-Z]+)") then
                res1 = resolve(val1)
            end
            if val2:match("State([a-zA-Z]+)") then
                res2 = resolve(val2)
            end
            if tonumber(val1) ~= nil then res1 = tonumber(val1) end
            if tonumber(val2) ~= nil then res2 = tonumber(val2) end
            if res1 == nil or res2 == nil then error("GUSGUI: Failed to parse param to State" .. type) end
            return StateTypes[type](self, res1, res2)
        end
        if type == "Global" or type == "Value" then
            return StateTypes[type](self, val)
        end
        error("GUSGUI: Unknown state type in state string")
    end
    return resolve(str)
end

--- @param data GuiElement
--- @return GuiElement data The element added.
function Gui:AddElement(data)
    if data["is_a"] and data["Draw"] and data["GetBaseElementSize"] then
        if data.type ~= "HLayout" and data.type ~= "HLayoutForEach" and data.type ~= "VLayout" and data.type ~=
            "VLayoutForEach" then
            error("GUSGUI: Gui root nodes must be a Layout element.", 2)
        end
        table.insert(self.tree, data)
        data:OnEnterTree(nil, true, self)
        return data
    else
        error("bad argument #1 to AddElement (GuiElement object expected, got invalid value)", 2)
    end
end

--- @param classname string
---@param config table
function Gui:RegisterConfigForClass(classname, config)
    local configobj = {}
    for k, v in pairs(config) do
        local validator = BaseValidator[k]
        local t = type(v)
        if t == "table" and v["_type"] ~= nil and v["value"] then
            configobj[k] = {
                value = v,
                isDF = false
            }
        end
        if v == nil then
            configobj[k] = {
                value = validator.default,
                isDF = true
            }
        end
        local newValue, err = validator.validate(v)
        if type(err) == "string" then
            error(err:format(classname .. " CLASS CONFIG"))
        end
        configobj[k] = {
            value = newValue,
            isDF = false
        }
    end
    self.classOverrides[classname] = configobj
end

local function searchTree(element, id)
    for k = 1, #element.children do
        local v = element.children[k]
        if id and v.id == id then
            return v
        else
            local search = searchTree(v, id)
            if search ~= nil then
                return search
            end
        end
    end
    return nil
end

--- @param id string
--- @return GuiElement|nil
function Gui:GetElementById(id)
    for k = 1, #self.tree do
        local v = self.tree[k]
        if v.id == id then
            return v
        else
            local search = searchTree(v, id)
            if search ~= nil then
                return search
            end
        end
    end
    return nil
end

--- @param className string
--- @return GuiElement[]
function Gui:GetElementsByClass(className)
    local elems = {}
    local function searchTreeForClass(elem)
        if elem.class:find(className) then
            table.insert(elems, elem)
        end
        for i = 1, #elem.children do
            searchTreeForClass(elem.children[i])
        end
    end

    for i = 1, #self.tree do
        local root = self.tree[i]
        searchTreeForClass(root)
    end
    return elems
end

---@param message string
function Gui:Log(message)
    if self.enableLogging then
        print(message)
    end
end

function Gui:Render()
    if (self.destroyed == true) then
        return
    end
    self.cachedData = {}
    self._state = self.state
    self.framenum = GameGetFrameNum()
    self.screenW, self.screenH = GuiGetScreenDimensions(self.guiobj)
    self.screenW, self.screenH = math.floor(self.screenW), math.floor(self.screenH)
    self.screenWorldX, self.screenWorldY = GameGetCameraBounds()
    GuiStartFrame(self.guiobj)
    self:Log(("GUSGUI: Starting to render frame %s"):format(self.framenum))
    for k = 1, #self.tree do
        local v = self.tree[k]
        v:Render()
    end
    self:Log(("GUSGUI: Finished rendering frame %s"):format(self.framenum))
end

--- @param elem GuiElement
--- @return number x, number y
function Gui:GetRootElemXY(elem)
    local x, y = self.baseX, self.baseY
    local elemSize = elem:GetElementSize()
    if elem._config.margin.right ~= 0 then
        x = (self.screenW - elemSize.width) - elem._config.margin.right
    end
    if elem._config.margin.left ~= 0 then
        x = elem._config.margin.left
    end
    if elem._config.margin.top ~= 0 then
        y = elem._config.margin.top
    end
    if elem._config.margin.bottom ~= 0 then
        y = (self.screenH - elemSize.height) - elem._config.margin.bottom
    end
    return x, y
end

function Gui:Destroy()
    self.destroyed = true
    self.tree = nil
    self.state = nil
    self._state = nil
    GuiDestroy(self.guiobj)
end

--- @return number, number, boolean
function Gui:GetMouseData()
    local component = EntityGetComponent(EntityGetWithTag("player_unit")[1], "ControlsComponent")[1]
    local mx, my = ComponentGetValue2(component, "mMousePosition")
    local screen_w, screen_h = GuiGetScreenDimensions(self.guiobj)
    local cx, cy = GameGetCameraPos()
    local vx = MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")
    local vy = MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y")
    local gmx = ((mx - cx) * screen_w / vx + screen_w / 2)
    local gmy = ((my - cy) * screen_h / vy + screen_h / 2)
    return math.floor(gmx), math.floor(gmy), ComponentGetValue2(component, "mButtonDownLeftClick")
end

--- @param config table
--- @return Gui
--- @nodiscard
function CreateGUI(config)
    return Gui(config)
end

--- @param filename string
--- @param funcs table?
--- @param config table?
--- @return Gui
--- @nodiscard
function CreateGUIFromXML(filename, funcs, config)
    funcs = funcs or {}
    config = config or {}
    local function throwErr(err)
        error(("GUSGUI XML: Parsing %s failed:"):format(filename) .. err, 3)
    end

    if not ModTextFileGetContent then
        throwErr("Loading GUI XML files can only be done when ModTextFileGetContent is available")
    end

    local gui = Gui(config)
    local StyleElem
    local data
    do
        local xml2lua = dofile("GUSGUI_PATHxml2lua.lua")
        local dom = xml2lua.getTree():new()
        local parser = xml2lua.parser(dom)
        parser:parse(ModTextFileGetContent(filename))
        data = dom.root._children
    end

    --Main parsing function
    ---@param elem table
    ---@param parent GuiElement?
    local function parseElementAndChildren(elem, parent)
        if GuiElements[elem._name] == nil then
            throwErr("Unrecognised element type: \"" .. elem._name .. "\". Make sure that types use the correct case.")
        end
        ---@type GuiElement
        local newElement = GuiElements[elem._name]()
        
        --Read config options and apply them to new element
        for k, v in pairs(elem._attr) do
            ---@cast k string
            ---@cast v unknown
            local convert = BaseValidator[k] or newElement.extendedValidator[k]
            if convert == nil then
                if k:match("^hover-") then
                    local value
                    if v:find("State([a-zA-Z]+)") then
                        value = gui:StateStringToTable(v)
                    else 
                        ---@diagnostic disable-next-line: need-check-nil
                        value = convert.fromString(v, funcs)
                    end
                    newElement._config.hover = newElement._config.hover or {}
                    newElement._config.hover[k:gsub("hover-", "")] = value
                else 
                    throwErr("Unrecognised inline config name: \"" .. k .. "\".")
                end
            end
            local value
            if v:find("State([a-zA-Z]+)") then
                value = gui:StateStringToTable(v)
            else 
                ---@diagnostic disable-next-line: need-check-nil
                value = convert.fromString(v, funcs)
            end
            newElement:ApplyConfig(k, value)
        end

        --If element contains a text body, read it
        if #(elem._children) == 1 and elem._children[1]._type == "TEXT" then
            if elem._name == "Text" then
                local v = elem._text
                local value
                if v:find("State([a-zA-Z]+)") then
                    value = gui:StateStringToTable(v)
                else 
                    ---@diagnostic disable-next-line: need-check-nil
                    value = newElement.extendedValidator["value"].fromString(v)
                end
                newElement:ApplyConfig("value", value)
            end
            if elem._name == "Button" then
                local v = elem._text
                local value
                if v:find("State([a-zA-Z]+)") then
                    value = gui:StateStringToTable(v)
                else 
                    ---@diagnostic disable-next-line: need-check-nil
                    value = newElement.extendedValidator["text"].fromString(v)
                end
                newElement:ApplyConfig("text", value)
            end
            if elem._name == "Image" then
                local v = elem._text
                local value
                if v:find("State([a-zA-Z]+)") then
                    value = gui:StateStringToTable(v)
                else 
                    ---@diagnostic disable-next-line: need-check-nil
                    value = newElement.extendedValidator["src"].fromString(v)
                end
                newElement:ApplyConfig("src", value)
            end
            if elem._name == "ImageButton" then
                local v = elem._text
                local value
                if v:find("State([a-zA-Z]+)") then
                    value = gui:StateStringToTable(v)
                else 
                    ---@diagnostic disable-next-line: need-check-nil
                    value = newElement.extendedValidator["ImageButton"].fromString(v)
                end
                newElement:ApplyConfig("ImageButton", value)
            end
        end

        --Parse all children
        for index, value in ipairs(elem._children) do
            parseElementAndChildren(value, newElement)
        end

        ---Add element to gui tree
        if not parent then
            gui:AddElement(newElement)
        else 
            parent:AddChild(newElement)
        end
    end
    
    --Main parsing loop
    for _, value in ipairs(data) do
        if value._name == "Style" then
            if StyleElem ~= nil then
                throwErr("Only one style element is allowed - combine styles into one tag or convert to inline config")
            end
            StyleElem = value
        else
            parseElementAndChildren(value)
        end
    end

    return gui
end

--- @class State
--- @field _type string
--- @field value any

--- @param s string
--- @return State
function Gui:StateValue(s)
    local o = {
        _type = "state",
        value = s
    }
    return o
end

--- @return State
function Gui:ScreenWidth()
    local o = {
        _type = "screenw",
        value = ""
    }
    return o
end

--- @return State
function Gui:ScreenHeight()
    local o = {
        _type = "screenh",
        value = ""
    }
    return o
end

--- @param s string
--- @return State
function Gui:StateGlobal(s)
    local o = {
        _type = "global",
        value = s,
    }
    return o
end

--- @param a State|number
--- @param b State|number
--- @return State
function Gui:StateAdd(a, b)
    return {
        _type = "add",
        value = {
            a = a,
            b = b
        }
    }
end

--- @param a State|number
--- @param b State|number
--- @return State
function Gui:StateSubtract(a, b)
    return {
        _type = "subtract",
        value = {
            a = a,
            b = b
        }
    }
end

--- @param a State|number
--- @param b State|number
--- @return State
function Gui:StateMultiply(a, b)
    return {
        _type = "multiply",
        value = {
            a = a,
            b = b
        }
    }
end

--- @param a State|number
--- @param b State|number
--- @return State
function Gui:StateDivide(a, b)
    return {
        _type = "divide",
        value = {
            a = a,
            b = b
        }
    }
end

--- @param type "inner"|"total"
--- @return State
function Gui:ParentWidth(type)
    if type == "inner" then
        return {
            _type = "p_innerW",
            value = ""
        }
    else
        return {
            _type = "p_totalW",
            value = ""
        }
    end
end

--- @param type "inner"|"total"
--- @return State
function Gui:ParentHeight(type)
    if type == "inner" then
        return {
            _type = "p_innerH",
            value = ""
        }
    else
        return {
            _type = "p_totalH",
            value = ""
        }
    end
end

--- @param type "inner"|"total"
--- @return State
function Gui:ElemWidth(type)
    if type == "inner" then
        return {
            _type = "innerW",
            value = ""
        }
    else
        return {
            _type = "totalW",
            value = ""
        }
    end
end

--- @param type "inner"|"total"
--- @return State
function Gui:ElemHeight(type)
    if type == "inner" then
        return {
            _type = "innerH",
            value = ""
        }
    else
        return {
            _type = "totalH",
            value = ""
        }
    end
end

return {
    Create = CreateGUI,
    CreateGUIFromXML = CreateGUIFromXML,
    Elements = GuiElements
}
