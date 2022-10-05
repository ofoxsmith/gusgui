return {
    init = function(path)
        path = path:gsub("/$", "") .. "/"
        local files = {
            "elems/Button.lua",
            "class.lua",
            "Gui.lua",
            "GuiElement.lua",
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
            "elems/DraggableElement.lua"
        }
        for i, v in ipairs(files) do 
            local m = ModTextFileGetContent(path .. v)
            m = m:gsub("GUSGUI_PATH", path)
            ModTextFileSetContent(path .. v, m)
        end
    end
}