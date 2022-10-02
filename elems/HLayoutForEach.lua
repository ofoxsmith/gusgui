local HLayout = dofile_once("GUSGUI_PATHelems/HLayout.lua")
dofile_once("GUSGUI_PATHclass.lua")

local HLayoutForEach = class(HLayout, function(o, config)
    GuiElement.init(o, config)
    o.stateVal = (type(config.stateVal) == "string") and config.stateVal or error("GUI: Invalid value for stateVal on element \"%s\"")
    o.func = (type(config.func) == "function") and config.func or error("GUI: Invalid value for func on element \"%s\"")
    o.type = "HLayoutForEach"
    o.allowsChildren = false
    o.children = {}
    setmetatable(o._, {
        __index = function(t, k)
            local elems = {}
            local data = (o.gui:GetState(o.stateVal))
            for i=1, #data do 
                table.insert(elems, o.func(data[i]))
            end
            return elems
        end
    })
end)

return HLayoutForEach
