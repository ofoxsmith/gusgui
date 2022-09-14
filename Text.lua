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
    o.value = value
end)

function Text:Interp(s)
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
    local parsedText = self:Interp(self.value)
    local lines = splitString(parsedText, "\\n")
    local lineCount = #lines
    local elementSize = self:GetElementSize()
    local heightForEachLine = (elementSize.baseH - (self.config.padding.top + self.config.padding.bottom)) / lineCount
    local x = self.config.margin.left
    local y = self.config.margin.top
    local z = getDepthInTree(self) * 10
    local border = (self.config.drawBorder and self.config.borderSize or 0)
    local alignX, alignY = self:GetOverridenWidthAndHeightAlignment()
    for lineNum, line in ipairs(lines) do
        GuiZSetForNextWidget(self.gui.guiobj, z)
        if self.config.colour then
            GuiColorSetForNextWidget(self.gui.guiobj, self.config.colour[1]/255, self.config.colour[2]/255, self.config.colour[3]/255)
        end
        GuiText(self.gui.guiobj, x + alignX + border + self.config.padding.let, y + alignY + border + self.style.padding.top + ((lineNum-1) * heightForEachLine), line) 
    end
end

return Text
