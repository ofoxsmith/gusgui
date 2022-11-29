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
    local Text = dofile_once("GUSGUI_PATHelems/Text.lua")
    local Button = dofile_once("GUSGUI_PATHelems/Button.lua")
    local Image = dofile_once("GUSGUI_PATHelems/Image.lua")
    local ImageButton = dofile_once("GUSGUI_PATHelems/ImageButton.lua")
    local HLayout = dofile_once("GUSGUI_PATHelems/HLayout.lua")
    local HLayoutForEach = dofile_once("GUSGUI_PATHelems/HLayoutForEach.lua")
    local VLayoutForEach = dofile_once("GUSGUI_PATHelems/VLayoutForEach.lua")
    local VLayout = dofile_once("GUSGUI_PATHelems/VLayout.lua")
    local Slider = dofile_once("GUSGUI_PATHelems/Slider.lua")
    local TextInput = dofile_once("GUSGUI_PATHelems/TextInput.lua")
    local ProgressBar = dofile_once("GUSGUI_PATHelems/ProgressBar.lua")
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
--- @field guiobj unknown
--- @field state table
--- @field tree GuiElement[]
--- @operator call: Gui
local Gui = class(function(newGUI, state)
    state = state or {}
    newGUI.ids = {}
    newGUI.nextID = getIdCounter()
    newGUI.stateID = getIdCounter()
    newGUI.guiobj = GuiCreate()
    newGUI.tree = {}
    newGUI.cachedData = {}
    newGUI.state = state
    newGUI._state = {}
    newGUI.classOverrides = {}
    newGUI.screenW, newGUI.screenH = GuiGetScreenDimensions(newGUI.guiobj)
    newGUI.screenW, newGUI.screenH = math.floor(newGUI.screenW), math.floor(newGUI.screenH)
end)

--- @param s string
--- @return any
function Gui:GetState(s)
    local init = nil
    local a = {}
    local item = {}
    for i in s:gmatch("[^/]+") do
        if not init then
            init = i
        else
            table.insert(a, i)
        end
    end
    item = init and self._state[init] or self._state
    for k, v in pairs(a) do
        if (type(item) ~= "table") then
            error("GUSGUI: Cannot access property of non-table value in state", 2)
        end
        item = item[v];
    end
    return item
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
        if validator.allowsState == true then
            if t == "table" and v["_type"] ~= nil and v["value"] then
                configobj[k] = {
                    value = v,
                    isDF = false
                }
            end
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
        for i = 1, elem.children do
            searchTreeForClass(elem.children[i])
        end
    end

    for i = 1, #self.tree do
        local root = self.tree[i]
        searchTreeForClass(root)
    end
    return elems
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
    for k = 1, #self.tree do
        local v = self.tree[k]
        v:Render()
    end
end

--- @param elem GuiElement
--- @return number x, number y
function Gui:GetRootElemXY(elem)
    local x, y = 0, 0
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

--- @param state table
--- @return Gui
--- @nodiscard
function CreateGUI(state)
    return Gui(state)
end

--- @param filename string
--- @param state table
--- @return Gui
--- @nodiscard
function CreateGUIFromXML(filename, state)
    if not ModTextFileGetContent then
        error("GUSGUI: Loading GUI XML files can only be done in init.lua", 2)
    end
    local nxml = dofile_once("GUSGUI_PATH/nxml.lua")
    local gui = Gui(state)
    local xml = nxml.parse(ModTextFileGetContent(filename))
    ---@param elem any
    ---@param parent GuiElement
    local function parseTree(elem, parent)
        for element in elem:each_child() do
            if GuiElements[element.name] == nil then
                error(("GUSGUI: Failed to parse xml file %s (Element with name %s does not exist."):format(filename, element.name))
            end
            local addTo = parent:AddChild(GuiElements[element.name]())
            parseTree(element, addTo)
        end
    end
    for element in xml:each_child() do
        if GuiElements[element.name] == nil then
            error(("GUSGUI: Failed to parse xml file %s (Element with name %s does not exist."):format(filename, element.name))
        end
        local addTo = gui:AddElement(GuiElements[element.name]())
        parseTree(element, addTo)
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
function Gui:GlobalValue(s)
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
    Elements = GuiElements
}
