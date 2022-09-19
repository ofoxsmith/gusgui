local Gui = {}

function getIdCounter()
    local id = 1
    return function()
        id = id + 1
        return id
    end
end

function Gui:New(data, state)
    data = data or {}
    local o = {}
    o.queueDestroy = false
    o.ids = {}
    o.nextID = getIdCounter()
    o.guiobj = GuiCreate()
    o.tree = {}
    o.state = state or {}
    o._cstate = o._state
    setmetatable(o, self)
    self.__index = self
    function o:New()
        return nil
    end
    for k = 1, #data do
        self:AddElement(self.tree[k])
    end
    return o
end

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
    item = init and self.state[init] or self.state
    for k, v in pairs(a) do
        if (type(item) ~= "table") then
            error("GUI: Cannot access property of non-table value in state", 2)
        end
        item = item[v];
    end
    return item
end

function Gui:StateValue(s)
    return {
        _type = "state",
        value = s
    }
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
            error("GUI: Element ID value must be unique (\"" .. data.id .. "\" is a duplicate)")
        end
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
    self.paused = false
    self._cstate = self._state
    GuiStartFrame(self.guiobj)
    for k = 1, #self.tree do
        local v = self.tree[k]
        v:Draw(self.guiobj)
    end
end

function Gui:Destroy()
    GuiDestroy(self.guiobj)
    self.elements = nil
    return
end

function CreateGUI(data, state)
    return Gui:New(data, state)
end

local Text = dofile_once("[[GUSGUI_PATH]]Text.lua")

return {
    Create = CreateGUI,
    Text = Text
}
