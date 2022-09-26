dofile_once("GUSGUI_PATHclass.lua")
function getIdCounter()
    local id = 1
    return function()
        id = id + 1
        return id
    end
end

local Gui = class(function(newGUI, data, state)
    data = data or {}
    state = state or {}
    newGUI.ids = {}
    newGUI.nextID = getIdCounter()
    newGUI.guiobj = GuiCreate()
    newGUI.tree = {}
    newGUI.state = state
    newGUI._cstate = {}
    for k = 1, #data do
        self:AddElement(self.tree[k])
    end
end)

function Gui:GetState(s)
    s = s or ""
    local init = nil
    local a = {}
    local item = {}
    for i in string.gmatch(s, "[^/]+") do
        if not init then
            init = i
        else
            table.insert(a, i)
        end
    end
    item = init and self._cstate[init] or self._cstate
    for k, v in pairs(a) do
        if (type(item) ~= "table") then
            error("GUI: Cannot access property of non-table value in state", 2)
        end
        item = item[v];
    end
    return item
end

function Gui:AddElement(data)
    local function testID(i)
        for k = 1, #self.ids do
            if (self.ids[k] == i) then
                return false
            end
        end
        return true
    end
    if data["is_a"] and data["Draw"] and data["GetBaseElementSize"] then
        data.gui = self
        if not testID(data.id) then
            error("GUI: Element ID value must be unique (\"" .. data.id .. "\" is a duplicate)", 2)
        end
        for k = 1, #data._rawchildren do
            data:AddChild(data._rawchildren[k])
        end
        data.childrenResolved = true
        table.insert(self.ids, data.id)
        table.insert(self.tree, data)
    else
        error("bad argument #1 to AddElement (GuiElement object expected, got invalid value)", 2)
    end
end

function Gui:GetElement(id)
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

function Gui:Render()
    if (self.destroyed == true) then return end
    self._cstate = self.state
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
    GuiDestroy(self.guiobj)
    return
end

function CreateGUI(data, state)
    return Gui(data, state)
end

function StateValue(s)
    return {
        _type = "state",
        value = s
    }
end

function GlobalValue(s)
    return {
        _type = "global",
        value = s
    }
end

local Text = dofile_once("GUSGUI_PATHText.lua")
local Button = dofile_once("GUSGUI_PATHButton.lua")
local Image = dofile_once("GUSGUI_PATHImage.lua")
local ImageButton = dofile_once("GUSGUI_PATHImageButton.lua")
local HLayout = dofile_once("GUSGUI_PATHHLayout.lua")
local VLayout = dofile_once("GUSGUI_PATHVLayout.lua")
local Slider = dofile_once("GUSGUI_PATHSlider.lua")
return {
    Create = CreateGUI,
    Elements = {
        Text = Text,
        Button = Button,
        Image = Image,
        ImageButton = ImageButton,
        HLayout = HLayout,
        VLayout = VLayout,
        Slider = Slider
    },
    State = StateValue,
    Global = GlobalValue
}
