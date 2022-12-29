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

---@param elem string
---@param key string
---@param value string
---@param conf table
---@param funcs table
return function(elem, key, value, conf, funcs)
    local applyTo;
    if value:find("^State%(") ~= nil then
        conf[key] = {_type = "state", value = value:gsub('^State%("', ""):gsub('%)$"', "")}
    elseif value:find("^Global%(") ~= nil then
        conf[key] = {_type = "state", value = value:gsub('^Global%("', ""):gsub('%)$"', "")}
    else
        if key:find("^hover%-") ~= nil then
            applyTo = conf.hover
            key = key:gsub("^hover-", "")
        end
        if elem:find("Layout") ~= nil then
            if key == "alignChildren" then
                applyTo[key] = tonumber(value)
            end
        end
        if elem:find("Button") ~= nil then
            if key == "onClick" then
                applyTo[key] = tonumber(value)
            end
        end
        if elem:find("LayoutForEach") ~= nil then
            if key == "type" or key == "stateVal" then
                applyTo[key] = value
            end
            if key == "numTimes" or key == "calculateEveryNFrames" then
                applyTo[key] = tonumber(value)
            end
            if key == "func" then
                applyTo[key] = funcs[value]
            end
        end
        if elem:find("Image") then
            if key == "src" then
                applyTo[key] = value
            end
            if key == "scaleX" or key == "scaleY" then
                applyTo[key] = tonumber(value)
            end
        end
        if elem == "Checkbox" then
            if key == "defaultValue" then
                applyTo[key] = value == "true"
            end
            if key == "style" then
                applyTo[key] = value
            end
            if key == "onToggle" then
                applyTo[key] = funcs[value]
            end
        end
        if elem == "ProgressBar" then
            if key == "width" or key == "height" or key == "value" then
                applyTo[key] = tonumber(value)
            end
            if key == "customBarColourPath" or key == "barColour" then
                applyTo[key] = value
            end
        end
        if elem == "Slider" then
            if key == "min" or key == "max" or key == "width" or key == "defaultValue" then
                applyTo[key] = tonumber(value)
            end
            if key == "onChange" then
                applyTo[key] = funcs[value]
            end
        end
        if elem == "TextInput" then
            if "width" or key == "maxLength" then
                applyTo[key] = tonumber(value)
            end
            if key == "onEdit" then
                applyTo[key] = funcs[value]
            end
        end
        if key == "id" or key == "class" or key == "name" then
            applyTo[key] = value
        end
        if key == "drawBorder" or key == "drawBackground" or key == "hidden" then
            applyTo[key] = value == "true"
        end
        if key == "alignChildren" or key == "numTimes" or key == "calculateEveryNFrames" or
            key == "overrideWidth" or
            key == "overrideHeight" or key == "horizontalAlign" or key == "verticalAlign" or key == "overrideZ" then
            applyTo[key] = tonumber(value)
        end
        if key == "colour" then
            local v = splitString(value, ",")
            applyTo[key] = { tonumber(v[1]), tonumber(v[2]), tonumber(v[3]) }
        end
        if key == "onHover" then
            applyTo[key] = funcs[value]
        end
        if key == "margin" or key == "padding" then
            local v = splitString(value, ",")
            applyTo[key] = { top = tonumber(v[1]), left = tonumber(v[2]), bottom = tonumber(v[3]), right = tonumber(v[4]) }
        end
        if key:find("^padding-") then
            applyTo.padding = applyTo.padding or {}
            applyTo.padding[key:sub(8)] = tonumber(value)
        end
        if key:find("^margin-") then
            applyTo.padding = applyTo.padding or {}
            applyTo.padding[key:sub(8)] = tonumber(value)
        end
    end
end
