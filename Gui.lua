local GuiElement = dofile("GuiElement.lua")
-- Gui main table
local Gui = {}

function getIdCounter()
    local id = 1 
    return function() id = id + 1 return id end
end

function Gui:New(data, state)
    local o = {}
    o.paused = true
    o.queueDestroy = false
    o.nextID = getIdCounter()
    o.renderLoopRunning = false
    o.guiobj = GuiCreate()
    o.tree = {}
    o._state = state or {}
    o._cstate = o._state
    setmetatable(o, self)
    self.__index = self
    function o:New()
        return nil
    end
    for k=1, #data do self:AddElement(self.tree[k]) end
    o:StartRender()
    return o
end

function Gui:GetState(s)
    local init = nil
    local s = {}
    local item = {}
    for i in string.gmatch(s, "[^/]+") do 
        if not init then init = i
        else table.insert(s, i) end 
    end
    item = self.state[init]
    for k=1, #self.tree do local v = self.tree[k]
        item = item[v];
    end
    return item
end
function Gui:UpdateState(k, v)
    self.state[k] = v
end

function Gui:StateValue(s)
    return {
        _type = "state",
        value = s,
    }
end

function Gui:RemoveState(k) 
    self.state[k] = nil
end

function Gui:AddElement(data)
    if data["is_a"] and data:is_a(GuiElement) then 
        data.gui = self
        table.insert(self.tree, data)
    else 
        error("bad argument #1 to AddElement (GuiElement object expected, got invalid value)", 2)
    end
end

function Gui:GetElement(id)
    for k=1, #self.tree do local v = self.tree[k]
        if v.id == id then return v 
        else  
            local search = searchTree(v, id)
            if search ~= nil then return search end
        end
    end
    return nil
end

function searchTree(element, id)
    for k=1, #element.children do local v = element.children[k]
        if v.id == id then return v
        else
            local search = searchTree(v, id)
            if search ~= nil then return search end
        end
    end
    return nil
end

function Gui:PauseRender()
    self.paused = true
end

function Gui:StartRender()
    self.paused = false
    if (self.renderLoopRunning == false) then 
        self.renderLoopRunning = true
        while not self.paused do
            o._cstate = o._state
            GuiStartFrame(self.guiobj)
            for k=1, #self.tree do local v = self.tree[k]
                v:Render(self.guiobj)
            end
        end
        self.renderLoopRunning = false
        if self.queueDestroy == true then 
            GuiDestroy(self.guiobj)
            self.elements = nil
        end
    end
end 

function Gui:Destroy()
    self.queueDestroy = true
    return nil
end

function CreateGUI(data, config) 
    return Gui:New(data)
end

return CreateGUI