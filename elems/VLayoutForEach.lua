local VLayout = dofile_once("GUSGUI_PATHelems/VLayout.lua")
dofile_once("GUSGUI_PATHclass.lua")

local VLayoutForEach = class(VLayout, function(o, config)
    VLayout.init(o, config, {{
        name = "type",
        validate = function(o)
            if o == nil then
                return false, nil, "GUI: Invalid value for type on element \"%s\" (type paramater is required)"
            elseif type(o) == "string" and (o == "foreach" or o == "executeNTimes") then
                return true, nil, nil
            else
                return false, nil,
                    "GUI: Invalid value for type on element \"%s\" (type paramater must be \"foreach\" or \"executeNTimes\")"
            end
        end
    }, {
        name = "func",
        validate = function(o)
            if o == nil then
                return false, nil, "GUI: Invalid value for func on element \"%s\" (func paramater is required)"
            elseif type(o) == "function" then
                return true, nil, nil
            else
                return false, nil, "GUI: Invalid value for func on element \"%s\""
            end
        end
    }, {
        name = "stateVal",
        validate = function(o)
            if config.type == "num" then
                return true, nil, nil
            elseif type(o) == "string" then
                return true, nil, nil
            else
                return false, nil, "GUI: Invalid value for stateVal on element \"%s\""
            end
        end
    }, {
        name = "calculateEveryNFrames",
        validate = function(o)
            if o == nil then
                return true, 1, nil
            elseif type(o) == "number" and (o >= 1 or o == -1) then
                return true, nil, nil
            else
                return false, nil, "GUI: Invalid value for calculateEveryNFrames on element \"%s\""
            end
        end

    }, {
        name = "numTimes",
        validate = function(o)
            if config.type == "foreach" then
                return true, nil, nil
            elseif type(o) == "number" and o >= 1 then
                return true, nil, nil
            else
                return false, nil, "GUI: Invalid value for numTimes on element \"%s\""
            end
        end

    }})
    o.type = "VLayoutForEach"
    o.hasInit = false
    o.allowsChildren = false
end)

function VLayoutForEach:CreateElements()
    if ((self.gui.framenum % self._config.calculateEveryNFrames) ~= 0) and self.hasInit == true then
        return
    end
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
        local data = (self.gui:GetState(self.stateVal))
        for i = 1, #data do
            local c = self._config.func(data[i])
            c.gui = self.gui
            c.parent = self
            table.insert(elems, c)
        end
        self.children = elems
    end
end
return VLayoutForEach
