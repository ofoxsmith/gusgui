-- Gui main table
local Gui = {}
Gui.__metatable = "";
function Gui:New(data)
    local o = {}
    o.paused = false
    o.queueDestroy = false;
    o.renderLoopRunning = false
    o.guiobj = GuiCreate()
    o.elements = setmetatable({}, {
        __index = function(t, k) return self:_GetElement(k) end,
        __newindex = function(t, k, v)
            self._SetElement(k, v)
        end
    })
    setmetatable(o, self)
    self.__index = self
    function o:New()
        return nil
    end
    o:StartRender()
    return o
end

function Gui:_GetElement(k)
    local data = self.guiTree[k]
    if (data == nil) then return nil end
    return data
end

function Gui:_SetElement(k, v)
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
            for k=1, #self.elements do local v = self.elements[k];
                v:Render(self.guiobj)
            end
        end
        self.renderLoopRunning = false;
        if self.queueDestroy == true then 
            GuiDestroy(self.guiobj)
            self.elements = nil
        end
    end
end 

function Gui:Destroy()
    self.queueDestroy = true;
    return nil
end

function CreateGUI(data, config) 
    return Gui:New({
        data = data,
        config = config
    })
end

return CreateGUI;
