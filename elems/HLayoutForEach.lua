local HLayout = dofile_once("GUSGUI_PATHelems/HLayout.lua")
dofile_once("GUSGUI_PATHclass.lua")

local HLayoutForEach = class(HLayout, function(o, config)
    HLayout.init(o, config)
    o.stateVal = (type(config.stateVal) == "string") and config.stateVal or error("GUI: Invalid value for stateVal on element \"%s\"")
    o.func = (type(config.func) == "function") and config.func or error("GUI: Invalid value for func on element \"%s\"")
    o.type = "HLayoutForEach"
    o.allowsChildren = false
end)

return HLayoutForEach
