return {
    --- @param path string
    --- @return nil
    init = function(path)
        path = path:gsub("/$", "") .. "/"
        local files = {
            "class.lua",
            "Gui.lua",
            "GuiElement.lua",
            "elems/Button.lua",
            "elems/Text.lua",
            "elems/Image.lua",
            "elems/ImageButton.lua",
            "elems/HLayout.lua",
            "elems/HLayoutForEach.lua",
            "elems/VLayout.lua",
            "elems/VLayoutForEach.lua",
            "elems/Slider.lua",
            "elems/TextInput.lua",
            "elems/ProgressBar.lua",
            "elems/Checkbox.lua",
        }
        for i, v in ipairs(files) do 
            local m = ModTextFileGetContent(path .. v)
            m = m:gsub("GUSGUI_PATH", path)
            ModTextFileSetContent(path .. v, m)
        end
    end
}