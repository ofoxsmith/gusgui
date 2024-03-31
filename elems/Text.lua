local function splitString(s, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(s, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(s, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(s, delimiter, from)
    end
    table.insert(result, string.sub(s, from))
    return result
end

--- @module "GuiElement"
local GuiElement = dofile_once(GUSGUI_FILEPATH("GuiElement.lua"))
dofile_once(GUSGUI_FILEPATH("class.lua"))
--- @class Text: GuiElement
--- @field maskID number
--- @field hoverMaskID number
--- @operator call: Text
local Text = class(GuiElement, function(o, config)
    config = config or {}
    config._type = "Text"
    GuiElement.init(o, config)
    o.allowsChildren = false
end)

function Text:GetBaseElementSize()
    local lines = splitString(self:Interp(self._config.text), "\n")
    local w, h = 0, 0
    for _, value in ipairs(lines) do
        local lw, lh = GuiGetTextDimensions(self.gui.guiobj, value)
        w = math.max(w, lw);
        h = h + lh
    end
    return w, h
end

function Text:Draw(x, y)
    self.maskID = self.maskID or self.gui.nextID()
    self.hoverMaskID = self.hoverMaskID or self.gui.nextID()
    local value = self:Interp(self._config.text)
    if value == "" then
        self.gui:Log(2, ("Rendering an empty text element with id %s"):format(self.id or "NO ELEMENT ID"))
    end
    local lines = splitString(value, "\n")
    local elementSize = self:GetElementSize()
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 1)
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x, y, elementSize.paddingW,
        elementSize.paddingH, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if hovered then
        if self._config.onHover then
            self._config.onHover(self, self.gui.state)
        end
        GuiZSetForNextWidget(self.gui.guiobj, self.z + 3)
        GuiImage(self.gui.guiobj, self.hoverMaskID, x, y, "data/debug/whitebox.png", 0,
            (elementSize.paddingW) / 20, (elementSize.paddingH) / 20)
    end
    if self._config.colour then
        local c = self._config.colour
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    local rx = x + elementSize.offsetX + self._config.padding.left;
    local ry = y + elementSize.offsetY + self._config.padding.top;
    for _=1, #lines do
        local v = lines[_]
        GuiText(self.gui.guiobj, rx, ry, v)
        local _, lh = GuiGetTextDimensions(self.gui.guiobj, v)
        ry = ry + lh
    end
    if hovered then self.useHoverConfigForNextFrame = true
    else self.useHoverConfigForNextFrame = false end
end

return Text
