function clone(t)
    local new = {};
    for k,v in pairs(t) do new[k] = v end;
    return new;
end

function freeze(t)
    return setmetatable(t, {
        __newindex = function()
            
        end
    })
end

function validateTableSchema(t, s)
    local check = {};
    for k, v in pairs(t) do
        check[k] = type(v);
    end
    for k, v in pairs(check) do
        if (v == nil or v ~= s[k]) then return false end;
        if (s[k] == "table") then
            local test = validateTableSchema(t[k], s[k]);
            if (test == false) then return false end;
        end
    end
    return true;
end