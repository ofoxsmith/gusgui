local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local Image = class(GuiElement, function(o, config)
    GuiElement.init(o, config, {{
        name = "scaleX",
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then
                return true, 1, nil, true
            end
            local t = type(o)
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "number" then
                return true, nil, nil
            end
        end
    }, {
        name = "scaleY",
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then
                return true, 1, nil, true
            end
            local t = type(o)
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "number" then
                return true, nil, nil
            end
        end
    }, {
        name = "src",
        fromString = function(s)
            return s
        end,
        validate = function(o)
            if o == nil then
                return false, nil, "GUI: Invalid value for src on element \"%s\" (src paramater is required)"
            end
            local t = type(o)
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "string" then
                return true, nil, nil
            end
        end
    }})
    o.type = "Image"
    o.allowsChildren = false
end)

function Image:GetBaseElementSize()
    local w, h = GuiGetImageDimensions(self.gui.guiobj, self._config.src)
    return w * self._config.scaleX, h * self._config.scaleY
end

function Image:Draw(x, y)
    self.imageID = self.imageID or self.gui.nextID()
    self.maskID = self.maskID or self.gui.nextID()
    local elementSize = self:GetElementSize()
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x, y, elementSize.paddingW,
    elementSize.paddingH, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if hovered and self._config.onHover then
        self._config.onHover(self, self.gui.state)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    if self._config.colour then
        local c = self._config.colour
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiImage(self.gui.guiobj, self.imageID, x + elementSize.offsetX + self._config.padding.left,
        y + elementSize.offsetY + self._config.padding.top, self._config.src, 1, self._config.scaleX, self._config.scaleY)
    if hovered then
        self.useHoverConfigForNextFrame = true
    else
        self.useHoverConfigForNextFrame = false
    end
end

return Image
