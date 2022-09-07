-- Gui main table
local Gui = {}
Gui.__metatable = "";
function Gui:New(data)
    local o = {}
    o.paused = false
    o.guiobj = GuiCreate()
    o.elements = setmetatable({}, {
        __index = function(t, k) return self:_GetElement(k) end,
        __newindex = function(t, k, v)
            self._SetElement(k, v)
        end
    })
    o.config = data.config or {}
    o.guiTree = {};
    setmetatable(o, self)
    self.__index = self
    function o:New()
        return
    end
    return o
end

function Gui:_GetElement(k)
    local data = self.guiTree[k]
    if (data == nil) then return nil end
    return data
end

function Gui:_SetElement(k, v)
end

function Gui:Destroy()
    GuiDestroy(self.guiobj)
    self.guiobj = nil;
    self.gui = nil;
end

function CreateGUI(data, config) 
    return Gui:New({
        data = data,
        config = config
    })
end

return CreateGUI;
