local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local ProgressBar = class(GuiElement, function(o, config)
    GuiElement.init(o, config, {{
        name = "width",
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then
                return true, 50, nil
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
        name = "value",
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then
                return true, 100, nil
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
        name = "barColour",
        validate = function(o)
            local t = type(o)
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "string" and o == "green" or o == "blue" or o == "yellow" or o == "white" then
                return true, nil, nil
            end
            return true, "green", nil
        end
    }})
    o.type = "ProgressBar"
    o.allowsChildren = false
end)

function ProgressBar:GetBaseElementSize()
    return math.max(15, self._config.width), 6
end

function ProgressBar:Draw(x, y)
    self.sbgID = self.sbgID or self.gui.nextID()
    self.barID = self.barID or self.gui.nextID()
    local elementSize = self:GetElementSize()
    local c = self._config.colour
    GuiZSetForNextWidget(self.gui.guiobj, self.z + 1)
    GuiImageNinePiece(self.gui.guiobj, self.barID, x + elementSize.offsetX + self._config.padding.left, y + elementSize.offsetY + self._config.padding.top, 
    self._config.width * (self._config.value * 0.01), 7, 1, "GUSGUI_PATHpbar_" .. self._config.barColour .. ".png")
    GuiImageNinePiece(self.gui.guiobj, self.sbgID, x + elementSize.offsetX + self._config.padding.left, y + elementSize.offsetY + self._config.padding.top, 
    math.max(15, self._config.width), 7, 0.8, "GUSGUI_PATHpbarbg.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if hovered then
        if self._config.onHover then
            self._config.onHover(self)
        end
        self.useHoverConfigForNextFrame = true
    else self.useHoverConfigForNextFrame = false end
end

return ProgressBar
