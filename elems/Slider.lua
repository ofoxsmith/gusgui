--- @module "GuiElement"
local GuiElement = dofile_once(GUSGUI_FILEPATH("GuiElement.lua"))
dofile_once(GUSGUI_FILEPATH("class.lua"))
--- @class Slider: GuiElement
--- @field maskID number
--- @field renderID number
--- @operator call: Slider
local Slider = class(GuiElement, function(o, config)
    config = config or {}
    config._type = "Slider"
    GuiElement.init(o, config)

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

return Slider