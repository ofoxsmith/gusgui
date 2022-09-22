return {
    init = function(path)
        path = string.gsub(path, "/$", "") .. "/"
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
            m = string.gsub("[[GUSGUI_PATH]]", path)
            ModTextFileSetConent(path .. v, m)
        end
    end
}