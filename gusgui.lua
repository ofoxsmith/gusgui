return {
    init = function(path)
        path = path:gsub("/$", "") .. "/"
        local files = {
            "Button.lua",
            "class.lua",
            "Gui.lua",
            "GuiElement.lua",
            "Text.lua",
            "HLayout.lua"
        }
        for i, v in ipairs(files) do 
            local m = ModTextFileGetContent(path .. v)
            m = m:gsub("GUSGUI_PATH", path)
            ModTextFileSetContent(path .. v, m)
        end
    end
}