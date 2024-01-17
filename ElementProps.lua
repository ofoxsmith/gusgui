local function splitString(s, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(s, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(s, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(s, delimiter, from)
    end
    table.insert(result, string.sub(s, from))
    return result
end

local function isStateTbl(v)
    return type(v) == "table" and v["_type"] ~= nil and v["value"] ~= nil
end

local function toNum(string, _)
    return tonumber(string)
end

---@class ElementProperty
---@field default any
---@field fromString function
---@field type string,
---@field validate function,
---@field parser function

local BaseElementProperties = {
    drawBorder = {
        default = false,
        fromString = function(b)
            return b == "true"
        end,
        type = "boolean"
    },
    drawBackground = {
        default = false,
        fromString = function(b)
            return b == "true"
        end,
        type = "boolean"
    },
    overrideWidth = {
        default = 0,
        fromString = toNum,
        type = "number",
        validate = function(o) return (o > 0), "overrideWidth > 0" end
    },
    overrideHeight = {
        default = 0,
        fromString = toNum,
        type = "number",
        validate = function(o) return (o > 0), "overrideHeight > 0" end
    },
    verticalAlign = {
        default = 0,
        fromString = toNum,
        type = "number",
        validate = function(o) return (0 <= o and o <= 1), "0 <= verticalAlign <= 1" end
    },
    horizontalAlign = {
        default = 0,
        fromString = toNum,
        type = "number",
        validate = function(o) return (0 <= o and o <= 1), "0 <= horizontalAlign <= 1" end
    },
    margin = {
        default = {
            top = 0,
            bottom = 0,
            left = 0,
            right = 0
        },
        fromString = function(s)
            if (toNum(s)) then
                local o = toNum(s)
                return {
                    top = o,
                    bottom = o,
                    left = o,
                    right = o
                }
            end
            local v = splitString(s, ",")
            return { top = toNum(v[1]), left = toNum(v[2]), bottom = toNum(v[3]), right = toNum(v[4]) }
        end,
        parser = function(o)
            local t = type(o)
            if t == 'number' then
                return {
                    top = o,
                    bottom = o,
                    left = o,
                    right = o
                }
            end
            if t == "table" then
                local m = {
                    top = o["top"] or o[1],
                    bottom = o["bottom"] or o[2],
                    left = o["left"] or o[3],
                    right = o["right"] or o[4]
                }
                for key, value in pairs(m) do
                    if type(value) ~= "number" and not isStateTbl(value) then return nil, (key .. " has invalid value") end
                    m[key] = value
                end
                return m;
            end
        end
    },
    padding = {
        default = {
            top = 0,
            bottom = 0,
            left = 0,
            right = 0
        },
        fromString = function(s)
            if (toNum(s)) then
                local o = toNum(s)
                return {
                    top = o,
                    bottom = o,
                    left = o,
                    right = o
                }
            end
            local v = splitString(s, ",")
            return { top = toNum(v[1]), left = toNum(v[2]), bottom = toNum(v[3]), right = toNum(v[4]) }
        end,
        parser = function(o)
            local t = type(o)
            if t == 'number' then
                return {
                    top = o,
                    bottom = o,
                    left = o,
                    right = o
                }
            end
            if t == "table" then
                local m = {
                    top = o["top"] or o[1],
                    bottom = o["bottom"] or o[2],
                    left = o["left"] or o[3],
                    right = o["right"] or o[4]
                }
                for key, value in pairs(m) do
                    if type(value) ~= "number" and not isStateTbl(value) then return nil, (key .. " has invalid value") end
                    m[key] = value
                end
                return m;
            end
        end
    },
    colour = {
        default = nil,
        fromString = function(s)
            local v = splitString(s, ",")
            return { toNum(v[1]), toNum(v[2]), toNum(v[3]) }
        end,
        parser = function(o)
            if type(o) == "table" then
                for i = 1, 3, 1 do
                    if type(o[i]) ~= "number" and not isStateTbl(o[i]) then
                        return nil, "invalid value " .. i
                    end
                end
                return o
            end
            return nil, "not table"
        end
    },
    hidden = {
        default = false,
        fromString = function(b)
            return b == "true"
        end,
        type = "boolean"
    },
    visible = {
        default = true,
        fromString = function(b)
            return b == "true"
        end,
        type = "boolean"
    },
    overrideZ = {
        default = nil,
        fromString = toNum,
        type = "number"
    },
    onHover = {
        default = nil,
        fromString = function(s, funcs)
            if funcs[s] then return funcs[s] end
            return nil
        end,
        type = "function"
    },
    onBeforeRender = {
        default = nil,
        fromString = function(s, funcs)
            if funcs[s] then return funcs[s] end
            return nil
        end,
        type = "function"
    },
    onAfterRender = {
        default = nil,
        fromString = function(s, funcs)
            if funcs[s] then return funcs[s] end
            return nil
        end,
        type = "function"
    },
}

local ButtonElementProperties = {
    onClick = {
        required = true,
        fromString = function(s, funcs)
            if funcs[s] then return funcs[s] end
            return nil
        end,
        type = "function"
    },
    text = {
        required = true,
        fromString = function(s)
            return s
        end,
        type = "string"
    }
}

local TextElementProperties = {
    text = {
        required = true,
        fromString = function(s)
            return s
        end,
        type = "string"
    }
}

local CheckboxElementProperties = {
    defaultValue = {
        required = true,
        fromString = function(s)
            return s == "true"
        end,
        type = "boolean"
    },
    onToggle = {
        required = true,
        fromString = function(s, funcs)
            if funcs[s] then return funcs[s] end
            return nil
        end,
        type = "function"
    },
    style = {
        default = "image",
        fromString = function(s)
            return s
        end,
        type = "string",
        validate = function(o) return (o == "image" or o == "text"), "style must be 'image' or 'text'" end
    }
}

local HLayoutElementProperties = {
    alignChildren = {
        default = 0,
        fromString = toNum,
        type = "number",
        validate = function(o) return (0 <= o and o <= 1), "0 <= alignChildren <= 1" end
    },
}

local VLayoutElementProperties = {
    alignChildren = {
        default = 0,
        fromString = toNum,
        type = "number",
        validate = function(o) return (0 <= o and o <= 1), "0 <= alignChildren <= 1" end
    },
}


local ImageElementProperties = {
    scaleX = {
        default = 1,
        fromString = toNum,
        type = "number",
        validate = function(o) return o > 0, "scaleX must be > 0" end
    },
    scaleY = {
        default = 1,
        fromString = toNum,
        type = "number",
        validate = function(o) return o > 0, "scaleY must be > 0" end
    },
    src = {
        required = true,
        fromString = function(s)
            return s
        end,
        type = "string"
    }
}


local ImageButtonElementProperties = {
    scaleX = {
        default = 1,
        fromString = toNum,
        type = "number",
        validate = function(o) return o > 0, "scaleX must be > 0" end
    },
    scaleY = {
        default = 1,
        fromString = toNum,
        type = "number",
        validate = function(o) return o > 0, "scaleY must be > 0" end
    },
    src = {
        required = true,
        fromString = function(s)
            return s
        end,
        type = "string"
    },
    onClick = {
        required = true,
        fromString = function(s, funcs)
            if funcs[s] then return funcs[s] end
            return nil
        end,
        type = "function"
    },
}

local ProgressBarElementProperties = {
    width = {
        default = 50,
        fromString = toNum,
        type = "number"
    },
    height = {
        default = 10,
        fromString = toNum,
        type = "number"
    },
    value = {
        default = 100,
        fromString = toNum,
        type = "number"
    },
    barColour = {
        default = "green",
        fromString = function(s)
            return s
        end,
        type = "string",
        validate = function(o)
            if o == "green" or o == "blue" or o == "yellow" or o == "white" then return true end
            return false, "barColour must be green, blue, yellow, or white"
        end
    },
    customBarColourPath = {
        default = nil,
        fromString = function(s)
            return s
        end,
        type = "string"
    }
}

local SliderElementProperties = {
    min = {
        default = 0,
        fromString = toNum,
        type = "number"
    },
    max = {
        default = 100,
        fromString = toNum,
        type = "number"
    },
    width = {
        default = 25,
        fromString = toNum,
        type = "number"
    },
    defaultValue = {
        default = 1,
        fromString = toNum,
        type = "number"
    },
    onChange = {
        required = true,
        fromString = function(s, funcs)
            if funcs[s] then return funcs[s] end
            return nil
        end,
        type = "function"
    }
}

local TextInputElementProperties = {
    maxLength = {
        default = 50,
        fromString = toNum,
        type = "number"
    },
    width = {
        default = 25,
        fromString = toNum,
        type = "number"
    },
    onEdit = {
        required = true,
        fromString = function(s, funcs)
            if funcs[s] then return funcs[s] end
            return nil
        end,
        type = "function"
    }
}

local Elements = {
    Text = TextElementProperties,
    Button = ButtonElementProperties,
    Image = ImageElementProperties,
    ImageButton = ImageButtonElementProperties,
    HLayout = HLayoutElementProperties,
    VLayout = VLayoutElementProperties,
    Slider = SliderElementProperties,
    TextInput = TextInputElementProperties,
    ProgressBar = ProgressBarElementProperties,
    Checkbox = CheckboxElementProperties,
}

for key, value in pairs(BaseElementProperties) do
    for k, _ in pairs(Elements) do
        Elements[k][key] = value
    end
end

Elements.BaseElement = BaseElementProperties

local all = {}
for key, value in pairs(Elements) do
    for k, v in pairs(value) do
        all[k] = v
    end
end
Elements.AllProperties = all

return Elements