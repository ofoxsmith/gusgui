local function init(path)
    path = path:gsub("/$", "") .. "/";
    local files = {"gui.lua, utils.lua"};
    for i,v in ipairs(files) do
        ModTextFileSetContent(path .. v, ModTextFileGetContent(path .. v):gsub("<path>", v))
    end
    return createGui;
end
return {
    init = init
}