dofile_once("GUSGUI_PATHclass.lua")
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
    newGUI.activeStates = {}
    newGUI.nextID = getIdCounter()
    newGUI.stateID = getIdCounter()
    newGUI.guiobj = GuiCreate()
    newGUI.tree = {}
    newGUI.cachedValues = {}
    newGUI.state = state
    newGUI._state = {}
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
            error("GUI: Cannot access property of non-table value in state", 2)
        end
        item = item[v];
    end
    return item
end

function Gui:AddElement(data)
    if data["is_a"] and data["Draw"] and data["GetBaseElementSize"] then
        data.gui = self
        if data.id and self.ids[data.id] then
            error("GUI: Element ID value must be unique (\"" .. data.id .. "\" is a duplicate)", 2)
        end
        if data.id then self.ids[data.id] = true end 
        for k = 1, #data._rawchildren do
            data:AddChild(data._rawchildren[k])
        end
        data.childrenResolved = true
        table.insert(self.tree, data)
    else
        error("bad argument #1 to AddElement (GuiElement object expected, got invalid value)", 2)
    end
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
    self._state = self.state
    self.framenum = GameGetFrameNum()
    if (self.destroyed == true) then return end
    for _=1, #self.activeStates do local v = self.activeStates[_] 
        if v._type == "global" then 
            self.cachedValues[v.id] = GlobalsGetValue(v.value)
        end
    end
    GuiStartFrame(self.guiobj)
    for k = 1, #self.tree do
        local v = self.tree[k]
        v:Draw(self.guiobj)
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

function CreateGUI(data, state)
    return Gui(data, state)
end

function Gui:StateValue(s)
    local o = {
        _type = "state",
        value = s,
    }
    return o
end

function Gui:GlobalValue(s)
    local i = self.stateID()
    local o = {
        _type = "global",
        value = s,
        id = i
    }
    table.insert(self.activeStates, o)
    return o
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
        TextInput = TextInput
    },
}
