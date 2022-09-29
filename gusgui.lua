return {
    init = function(path)
        path = path:gsub("/$", "") .. "/"
        local files = {
            "Button.lua",
            "class.lua",
            "Gui.lua",
            "GuiElement.lua",
            "Text.lua",
            "HLayout.lua",
            "Image.lua",
            "ImageButton.lua",
            "HLayout.lua",
            "HLayoutForEach.lua",
            "VLayout.lua",
            "VLayoutForEach.lua",
            "Slider.lua",
            "TextInput.lua",
        }
        for i, v in ipairs(files) do 
            local m = ModTextFileGetContent(path .. v)
            m = m:gsub("GUSGUI_PATH", path)
            ModTextFileSetContent(path .. v, m)
        end
    end
}