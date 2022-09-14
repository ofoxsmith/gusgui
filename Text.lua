local ElementParent = dofile("GuiElement.lua")
dofile("class.lua")

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


local Text = class(ElementParent, function(o, value, config)
    ElementParent.init(o, config)
    if value == nil then 
        error("GUI: Invalid construction of Text element (value paramater is required)", 2)
    end
    o.value = value
end)

function Text:Interp(s)
    if (type(s) ~= "string") then return 
        error("bad argument #1 to Interp (string expected, got " .. type(s) .. ")", 2)
    end
    return (s:gsub('($%b{})', function(w) w = string.sub(w, 3, -2) 
        return self.gui:GetState(w)
    end))
end
function Text:GetBaseElementSize()
    local allLines = splitString(self.value, "\\n")
    local totalWidth = 0
    local totalHeight = 0
    for i, v in ipairs(allLines) do
        local w, h = GuiGetTextDimensions(self.gui.guiobj, v)
        totalHeight = totalHeight + h;
        totalWidth = (totalWidth > w and totalWidth or w)
    end
    return totalWidth, totalHeight
end

function Text:Draw()
    local parsedText = self:Interp(self:ResolveValue(self.value))
    local lines = splitString(parsedText, "\\n")
    local lineCount = #lines
    local elementSize = self:GetElementSize()
    local paddingLeft = self:ResolveValue(self.config.padding.left)
    local paddingBottom = self:ResolveValue(self.config.padding.bottom)
    local paddingTop = self:ResolveValue(self.config.padding.top)
    local paddingBottom = self:ResolveValue(self.config.padding.bottom)
    local heightForEachLine = (elementSize.baseH - (paddingTop + paddingBottom)) / lineCount
    local x = self:ResolveValue(self.config.margin.left)
    local y = self:ResolveValue(self.config.margin.top)
    local c = self:ResolveValue(self.config.colour)
    local z = getDepthInTree(self) * 10
    local border = (self:ResolveValue(self.config.drawBorder) and self:ResolveValue(self.config.borderSize) or 0)
    local alignX, alignY = self:GetOverridenWidthAndHeightAlignment()
    for lineNum, line in ipairs(lines) do
        GuiZSetForNextWidget(self.gui.guiobj, z)
        if self.config.colour then
            GuiColorSetForNextWidget(self.gui.guiobj, c[1]/255, c[2]/255, c[3]/255)
        end
        GuiText(self.gui.guiobj, x + alignX + border + paddingLeft, y + alignY + border + paddingTop + ((lineNum-1) * heightForEachLine), line) 
    end
end

return Text
