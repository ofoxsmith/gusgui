local GuiElement = dofile("GuiElement.lua")
-- Gui main table
local Gui = {}
Gui.__metatable = ""
function Gui:New(data)
    local o = {}
    o.paused = true
    o.queueDestroy = false
    o.renderLoopRunning = false
    o.guiobj = GuiCreate()
    o.tree = {}
    setmetatable(o, self)
    self.__index = self
    function o:New()
        return nil
    end
    o:StartRender()
    return o
end

function Gui:AddElement(data)
    if data["is_a"] and data:is_a(GuiElement) then 
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
    return Gui:New({
        data = data,
        config = config
    })
end

return CreateGUI