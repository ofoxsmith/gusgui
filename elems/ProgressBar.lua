--- @module "GuiElement"
local GuiElement = dofile_once(GUSGUI_FILEPATH("GuiElement.lua"))
dofile_once(GUSGUI_FILEPATH("class.lua"))
--- @class ProgressBar: GuiElement
--- @field barID number
--- @field sbgID number
--- @operator call: ProgressBar
local ProgressBar = class(GuiElement, function(o, config)
    config = config or {}
    config._type = "ProgressBar"
    GuiElement.init(o, config)
    o.allowsChildren = false
end)

function ProgressBar:GetBaseElementSize()
    return math.max(10, self._config.width) + 2, math.max(2, self._config.height) + 2
end

function ProgressBar:Draw(x, y)
    self.sbgID = self.sbgID or self.gui.nextID()
    self.barID = self.barID or self.gui.nextID()
    local elementSize = self:GetElementSize()
    local barPath
    if self._config.customBarColourPath ~= nil then
        barPath = self._config.customBarColourPath
    else 
        barPath = GUSGUI_FILEPATH("pbar_" .. self._config.barColour .. ".png")
    end
    local value = self._config.value
    if value < 0 or value > 100 then 
        local s = 'Error while drawing ProgressBar "%s" - value %s was not between 0 and 100'
        return self.gui:Log(0, s:format(self.id or "NO ELEMENT ID", tostring(value)))
    end
    GuiImageNinePiece(self.gui.guiobj, self.barID, x + elementSize.offsetX + self._config.padding.left,
        y + elementSize.offsetY + self._config.padding.top, self._config.width * (value * 0.01),
        math.max(2, self._config.height), 1, barPath)
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 2)
    GuiImageNinePiece(self.gui.guiobj, self.sbgID, x + elementSize.offsetX + self._config.padding.left,
        y + elementSize.offsetY + self._config.padding.top, math.max(15, self._config.width),
        math.max(2, self._config.height), 1, GUSGUI_FILEPATH("img/pbarbg.png"))
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if hovered then
        if self._config.onHover then
            self._config.onHover(self, self.gui.state)
        end
        self.useHoverConfigForNextFrame = true
    else
        self.useHoverConfigForNextFrame = false
    end
end

return ProgressBar