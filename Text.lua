local GuiElement = dofile_once("[[GUSGUI_PATH]]GuiElement.lua")
dofile_once("[[GUSGUI_PATH]]class.lua")

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

local Text = class(GuiElement, function(o, id, value, config)
    GuiElement.init(o, id, config)
    o.type = "Text"
    if value == nil then
        error("GUI: Invalid construction of Text element (value paramater is required)", 2)
    end
    o.value = value
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
    local w, h = GuiGetTextDimensions(self.gui.guiobj, self:ResolveValue(self.value))
    return w, h
end

function Text:Draw()
    local parsedText = self:Interp(self:ResolveValue(self.value))
    local elementSize = self:GetElementSize()
    local paddingLeft = self:ResolveValue(self.config.padding.left)
    local paddingTop = self:ResolveValue(self.config.padding.top)
    local x = self:ResolveValue(self.config.margin.left)
    local y = self:ResolveValue(self.config.margin.top)
    local c = self:ResolveValue(self.config.colour)
    local z = getDepthInTree(self) * 10
    if self.parent then
        x, y = self.parent:GetManagedXY()
    end
    local border = (self:ResolveValue(self.config.drawBorder) and self:ResolveValue(self.config.borderSize) or 0)
    GuiZSetForNextWidget(self.gui.guiobj, z)
    if self.config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiText(self.gui.guiobj, x + elementSize.offsetX + border + paddingLeft,
        y + elementSize.offsetY + border + paddingTop, parsedText)
end

return Text
