local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

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

local Text = class(GuiElement, function(o, config)
    GuiElement.init(o, config, extendedValid)
    o.type = "Text"
    o.allowsChildren = false
    if config.value == nil then
        error("GUI: Invalid construction of Text element (value paramater is required)", 2)
    end
    o.value = config.value
end)

function Text:Interp(s)
    if (type(s) ~= "string") then
        return error("bad argument #1 to Interp (string expected, got " .. type(s) .. ")", 2)
    end
    return (s:gsub('($%b{})', function(w)
        w = string.sub(w, 3, -2)
        return self.gui:GetState(w)
    end))
end
function Text:GetBaseElementSize()
    local w, h = GuiGetTextDimensions(self.gui.guiobj, self:Interp(self._config.value))
    return w, h
end

function Text:Draw()
    self.maskID = self.maskID or self.gui.nextID()
    self.hoverMaskID = self.hoverMaskID or self.gui.nextID()
    self.z = self:GetDepthInTree() * -100
    local parsedText = self:Interp(self._config.value)
    local elementSize = self:GetElementSize()
    local paddingLeft = self._config.padding.left
    local paddingTop = self._config.padding.top
    local x = self._config.margin.left
    local y = self._config.margin.top
    local c = self._config.colour
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    local border = (self._config.drawBorder and 1 or 0)
    if border > 0 then
        self:RenderBorder(x, y, elementSize.baseW, elementSize.baseH)
    end
    if self._config.drawBackground then 
        self:RenderBackground(x, y, elementSize.baseW, elementSize.baseH)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x + border, y + border, elementSize.width - border - border, elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if hovered then
        if self._config.onHover then self._config.onHover(self) end
        GuiZSetForNextWidget(self.gui.guiobj, self.z - 3)
        GuiImage(self.gui.guiobj, self.hoverMaskID, x + border, y + border, "data/debug/whitebox.png", 0, (elementSize.width - border - border) / 20, (elementSize.height - border - border) / 20)    
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    if self._config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiText(self.gui.guiobj, x + elementSize.offsetX + border + paddingLeft,
        y + elementSize.offsetY + border + paddingTop, parsedText)
end

extendedValid = {
    {
        name = "value",
        validate = function(o)
            if o == nil then
                return false, nil,  "GUI: Invalid value for value on element \"%s\" (value is required)"
            end
            if type(o) == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if type(o) == "string" then return true, nil, nil end
            return false, nil, "GUI: Invalid value for value on element \"%s\""
        end    
    },
}


return Text
