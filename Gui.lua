dofile_once("GUSGUI_PATHclass.lua")
dofile_once("GUSGUI_PATHGuiElement.lua")
function getIdCounter()
    local id = 1
    return function()
        id = id + 1
        return id
    end
end

local Gui = class(function(newGUI, state)
    data = data or {}
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

function Gui:RegisterConfigForClass(classname, config)
    local configobj = {}
    for k, v in pairs(config) do
        local validator = baseValidator[k]
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

function Gui:GetElementsByClass(className)
    local elems = {}
    function searchTreeForClass(elem)
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

function searchTree(element, id)
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
        v:Render(self.guiobj)
    end
end

function Gui:Destroy()
    self.destroyed = true
    self.tree = nil
    self.state = nil
    self._state = nil
    GuiDestroy(self.guiobj)
    return
end

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

function CreateGUI(data, state)
    return Gui(data, state)
end

function Gui:StateValue(s)
    local o = {
        _type = "state",
        value = s
    }
    return o
end

function Gui:ScreenWidth()
    local o = {
        _type = "screenw",
        value = ""
    }
    return o
end

function Gui:ScreenHeight()
    local o = {
        _type = "screenh",
        value = ""
    }
    return o
end

function Gui:GlobalValue(s)
    local o = {
        _type = "global",
        value = s,
    }
    return o
end

function Gui:StateAdd(a, b)
    return {
        _type = "add",
        value = {
            a = a,
            b = b
        }
    }
end

function Gui:StateSubtract(a, b)
    return {
        _type = "subtract",
        value = {
            a = a,
            b = b
        }
    }
end

function Gui:StateMultiply(a, b)
    return {
        _type = "multiply",
        value = {
            a = a,
            b = b
        }
    }
end

function Gui:StateDivide(a, b)
    return {
        _type = "divide",
        value = {
            a = a,
            b = b
        }
    }
end

function Gui:ParentWidth(type)
    if type == "inner" then
        return {
            _type = "p_innerW",
            value = ""
        }
    elseif type == "total" then
        return {
            _type = "p_totalW",
            value = ""
        }
    end
end

function Gui:ParentHeight(type)
    if type == "inner" then
        return {
            _type = "p_innerH",
            value = ""
        }
    elseif type == "total" then
        return {
            _type = "p_totalH",
            value = ""
        }
    end
end

function Gui:ElemWidth(type)
    if type == "inner" then
        return {
            _type = "innerW",
            value = ""
        }
    elseif type == "total" then
        return {
            _type = "totalW",
            value = ""
        }
    end
end

function Gui:ElemHeight(type)
    if type == "inner" then
        return {
            _type = "innerH",
            value = ""
        }
    elseif type == "total" then
        return {
            _type = "totalH",
            value = ""
        }
    end
end

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
-- local DraggableElement = dofile_once("GUSGUI_PATHelems/DraggableElement.lua")
return {
    Create = CreateGUI,
    Elements = {
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
        Checkbox = Checkbox
        -- DraggableElement = DraggableElement
    }
}
