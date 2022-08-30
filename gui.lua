-- dofile_once("<path>utils.lua")
function GuiCreate() return 0 end
function GuiDestroy(n) return 0 end
local Gui = {}
Gui.__metatable = "";
function Gui:New(data, baseStyle, config)
    local o = {}
    o.paused = true
    o.guiobj = GuiCreate()
    o.elements = setmetatable({}, {
        __index = function(t, k) return self:_GetElement(k) end,
        __newindex = function(t, k, v)
            self._SetElement(k, v)
        end
    })
    o.baseStyle = baseStyle or {}
    o.config = config or {}
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

local g = Gui:New({}, {}, {})
print(g.elements.a)
return createGui;
