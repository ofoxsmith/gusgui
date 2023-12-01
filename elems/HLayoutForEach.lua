--- @module "HLayout"
local HLayout = dofile_once("GUSGUI_PATHelems/HLayout.lua")
dofile_once("GUSGUI_PATHclass.lua")
local HLayoutForEachConf = {type = {
    required = true,
    fromString = function (s)
        return s
    end,
    validate = function(o)
        if o == nil then
            return nil, "Invalid value for type on element \"%s\" (type paramater is required)"
        elseif type(o) == "string" and (o == "foreach" or o == "executeNTimes") then
            return o
        else
            return nil,
                "Invalid value for type on element \"%s\" (type paramater must be \"foreach\" or \"executeNTimes\")"
        end
    end
}, func = {
    required = true,
    fromString = function (s, funcs)
        if funcs[s] then return funcs[s] end
        error("GUSGUI: Unknown function name" .. s)
    end,    
    validate = function(o)
        if type(o) == "function" then
            return o
        else
            return nil, "Invalid value for func on element \"%s\""
        end
    end
}, stateVal = {
    required = false,
    fromString = function (s)
        return s
    end,
    validate = function(o)
        if type(o) == "string" then
            return o
        else
            return nil, "Invalid value for stateVal on element \"%s\""
        end
    end
}, calculateEveryNFrames = {
    default = 1,
    required = false,
    fromString = function (s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" and (o >= 1 or o == -1) then
            return o
        else
            return nil, "Invalid value for calculateEveryNFrames on element \"%s\""
        end
    end

}, numTimes = {
    required = false,
    fromString = function (s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" and o >= 1 then
            return o
        else
            return nil, "Invalid value for numTimes on element \"%s\""
        end
    end

}}
--- @class HLayoutForEach: HLayout
--- @field lastUpdate number|nil
--- @operator call: HLayoutForEach
local HLayoutForEach = class(HLayout, function(o, config)
    config = config or {}
    HLayout.init(o, config, HLayoutForEachConf)
    o.type = "HLayoutForEach"
    o.hasInit = false
    o.allowsChildren = false
    o.lastUpdate = 0
end)

function HLayoutForEach:CreateElements()
    self.children = {}
    if self._config.type == "executeNTimes" then
        local elems = {}
        for i=1, self._config.numTimes do
            local c = self._config.func(i)
            c.gui = self.gui
            c.parent = self
            table.insert(elems, c)
        end
        self.children = elems
    else
        local elems = {}
        local data = (self.gui:GetState(self._config.stateVal))
        for i = 1, #data do
            local c = self._config.func(data[i])
            c:OnEnterTree(self, false)
        end
    end
    self.lastUpdate = self.gui.framenum
end

HLayoutForEach.extConf = HLayoutForEachConf
return HLayoutForEach
