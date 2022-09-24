local function validate(applyTo, id, s, elem, o)
    if o then
        local typeof = type(elem)
        if (typeof == "nil" and s.default == nil) or (typeof ~= s.type and typeof ~= "nil" and type(s.type) ~= "table") then
            if type(s.type == "table") then error("GUI: Invalid value for " .. s.name .. " on element \"" .. id .."\"", 2)            end
            error("GUI: Invalid value for " .. s.name .. " on element \"" .. id .."\" (" .. s.type .. " expected, got " .. typeof .. ")", 2)
        end
        if (typeof == "nil") then
            elem = s.default
        end
        if typeof == "table" then
            for k, v in pairs(s.type) do
                if (type(elem[k]) ~= v) then
                    error("GUI: Invalid table value for " .. s.name .. " on element \"" .. id .."\"", 2)
                end
            end
        end
        applyTo[s.name] = elem
        return true
    end
    for _, v in ipairs(s) do
        local value = elem[v.name]
        local typeof = type(value)
        if (typeof == "nil" and v.default == nil) or (typeof ~= v.type and typeof ~= "nil" and type(v.type) ~= "table") then
            if type(v.type == "table") then error("GUI: Invalid value for " .. v.name .. " on element \"" .. id .."\"", 2)            end
            error("GUI: Invalid value for " .. v.name .. " on element \"" .. id .."\" (" .. v.type .. " expected, got " .. typeof .. ")", 2)
        end
        if (typeof == "nil") then
            value = v.default
        end
        if typeof == "table" then
            for k, t in pairs(v.type) do
                if (type(value[k]) ~= t) then
                    error("GUI: Invalid table value for " .. v.name .. " on element \"" .. id .."\"", 2)
                end
            end
        end
        applyTo[v.name] = value
    end
    return true
end
return validate