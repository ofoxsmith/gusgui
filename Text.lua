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
    GuiElement.init(o, config)
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
    local w, h = GuiGetTextDimensions(self.gui.guiobj, self:Interp(self.value))
    return w, h
end

function Text:Draw()
    self.z = self:GetDepthInTree() * -100
    local parsedText = self:Interp(self.value)
    local elementSize = self:GetElementSize()
    local paddingLeft = self.config.padding.left
    local paddingTop = self.config.padding.top
    local x = self.config.margin.left
    local y = self.config.margin.top
    local c = self.config.colour
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    GamePrint(tostring(x) .. " " .. tostring(y))
    local border = (self.config.drawBorder and 1 or 0)
    if border > 0 then
        self:RenderBorder(x, y, elementSize.baseW, elementSize.baseH)
    end
    if self.config.drawBackground then 
        self:RenderBackground(x, y, elementSize.baseW, elementSize.baseH)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.gui.nextID(), x + border, y + border, elementSize.width - border - border, elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if hovered then 
        GuiZSetForNextWidget(self.gui.guiobj, self.z - 3)
        GuiImage(self.gui.guiobj, self.gui.nextID(), x + border, y + border, "data/debug/whitebox.png", 0, (elementSize.width - border - border) / 20, (elementSize.height - border - border) / 20)    
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    if self.config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiText(self.gui.guiobj, x + elementSize.offsetX + border + paddingLeft,
        y + elementSize.offsetY + border + paddingTop, parsedText)
end

return Text
