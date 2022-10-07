local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local Slider = class(GuiElement, function(o, config)
    GuiElement.init(o, config, {{
        name = "min",
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then
                return true, 1, nil
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
        name = "max",
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then
                return true, 1, nil
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
        name = "width",
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then
                return true, 25, nil
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
        name = "defaultValue",
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then
                return true, 1, nil
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
        name = "onChange",
        validate = function(o)
            if o == nil then
                return false, nil, "GUI: Invalid value for onChange on element \"%s\" (onChange is required)"
            end
            if type(o) == "function" then
                return true, nil, nil
            end
            return false, nil, "GUI: Invalid value for onChange on element \"%s\""
        end
    }})
    o.type = "Slider"
    o.allowsChildren = false
    o.value = o._config.defaultValue
end)

function Slider:GetBaseElementSize()
    return math.max(25, self._config.width), 8.3
end

function Slider:Draw(x, y)
    self.renderID = self.renderID or self.gui.nextID()
    self.maskID = self.maskID or self.gui.nextID()
    local elementSize = self:GetElementSize()
    local c = self._config.colour
    local old = self.value
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x, y, elementSize.paddingW,
    elementSize.paddingH, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    local nv = GuiSlider(self.gui.guiobj, self.renderID, x + elementSize.offsetX + self._config.padding.left - 2,
        y + elementSize.offsetY + self._config.padding.top, "", self.value, self._config.min, self._config.max,
        self._config.defaultValue, 1, " ", math.max(25, self._config.width))
    self.value = math.floor(nv)
    if nv ~= old then
        self._config.onChange(self)
    end
    if hovered then
        if self._config.onHover then
            self._config.onHover(self)
        end
        self.useHoverConfigForNextFrame = true
    else self.useHoverConfigForNextFrame = false end
end

return Slider
