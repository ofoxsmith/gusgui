local Gui = {}

function Gui:new(data, defaults)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

local function createGui(data, defaults) 
    return Gui:new(data, defaults)
end

return createGui;