local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local TextInput = class(GuiElement, function(o, config)
    GuiElement.init(o, config)
    o.type = "TextInput"
    o.allowsChildren = false
    o.maxLength = config.maxLength or 50
    o.width = config.width or 25
    if config.onEdit == nil then
        error("GUI: Invalid construction of TextInput element (onEdit paramater is required)", 2)
    end
    self.onEdit = config.onEdit
end)

function TextInput:GetBaseElementSize() return math.max(25, self.width - (self._config.drawBorder and 4 or 0)), 10 end
function TextInput:Draw()
    self.value = self.value or " "
    self.inputID = self.inputID or self.gui.nextID()
    self.maskID = self.maskID or self.gui.nextID()
    self.z = self:GetDepthInTree() * -100
    local elementSize = self:GetElementSize()
    local paddingLeft = self._config.padding.left
    local paddingTop = self._config.padding.top
    local x = self._config.margin.left
    local y = self._config.margin.top
    local c = self._config.colour
    local border = (self._config.drawBorder and 1 or 0)
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    if border > 0 then
        self:RenderBorder(x, y, elementSize.baseW, elementSize.baseH)
    end
    if self._config.drawBackground then
        self:RenderBackground(x, y, elementSize.baseW, elementSize.baseH)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self:GetDepthInTree() * -100)
    local n = GuiTextInput(self.gui.guiobj, self.inputID, x + elementSize.offsetX + border + self._config.padding.left,
        y + elementSize.offsetY + border + self._config.padding.top, self.value, self.width, self.maxLength,
        "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
    if self.value ~= n then
        self.value = n
        self.onEdit(self)
    end
end

return TextInput
