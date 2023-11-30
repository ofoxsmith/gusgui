--- @module "GuiElement"
local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")
local SliderConf = {min = {
    default = 0,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            return o
        end
    end
}, max = {
    default = 100,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            return o
        end
    end
}, width = {
    default = 25,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            return o
        end
    end
}, defaultValue = {
    default = 1,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            return o
        end
    end
}, onChange = {
    required = true,
    fromString = function (s, funcs)
        if funcs[s] then return funcs[s] end
        error("GUSGUI: Unknown function name" .. s)
        end,
    validate = function(o)
        if type(o) == "function" then
            return o
        end
        return nil, "Invalid value for onChange on element \"%s\""
    end
}}
--- @class Slider: GuiElement
--- @field maskID number
--- @field renderID number
--- @operator call: Slider
local Slider = class(GuiElement, function(o, config)
    config = config or {}
    GuiElement.init(o, config, SliderConf)
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
        self._config.onChange(self, self.gui.state)
    end
    if hovered then
        if self._config.onHover then
            self._config.onHover(self, self.gui.state)
        end
        self.useHoverConfigForNextFrame = true
    else self.useHoverConfigForNextFrame = false end
end

Slider.extConf = SliderConf
return Slider